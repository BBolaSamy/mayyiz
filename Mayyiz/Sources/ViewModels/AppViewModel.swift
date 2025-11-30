import Foundation
import SwiftUI
import Combine

/// Main view model managing application state and actions
@MainActor
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: AppState = .idle
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let analysisService: AnalysisService
    
    // MARK: - Initialization
    
    init(analysisService: AnalysisService = AnalysisService()) {
        self.analysisService = analysisService
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe state changes for logging/analytics
        $state
            .sink { newState in
                print("📱 AppState changed to: \(newState)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Actions
    
    /// Handle share handoff from Share Extension
    /// - Parameter id: The share ID to load and preview
    func onShareHandoff(id: String) {
        print("🔗 Share handoff received: \(id)")
        
        // Load shared content from SharedContainer
        do {
            let sharedContent = try loadSharedContent(id: id)
            
            // Transition to preview state
            state = .preview(shareId: id)
            
            // Store the content for later use
            saveCurrentContent(sharedContent)
            
        } catch {
            print("❌ Error loading shared content: \(error)")
            errorMessage = "Failed to load shared content: \(error.localizedDescription)"
            state = .idle
        }
    }
    
    /// Handle image picker action
    func onPickImage() {
        print("📸 Pick image action triggered")
        
        // Generate a new share ID for locally picked image
        let shareId = UUID().uuidString
        
        // Transition to preview state
        // The actual image will be set by the image picker callback
        state = .preview(shareId: shareId)
    }
    
    /// Start analysis of current content
    func onAnalyze() {
        guard let shareId = state.currentShareId else {
            print("⚠️ No share ID available for analysis")
            errorMessage = "No content to analyze"
            return
        }
        
        print("🔍 Starting analysis for: \(shareId)")
        
        // Transition to analyzing state
        state = .analyzing(shareId: shareId)
        isLoading = true
        
        // Perform analysis
        Task {
            do {
                let result = try await performAnalysis(shareId: shareId)
                
                // Transition to result state
                state = .result(shareId: shareId, analysisResult: result)
                isLoading = false
                
            } catch {
                print("❌ Analysis failed: \(error)")
                errorMessage = "Analysis failed: \(error.localizedDescription)"
                state = .preview(shareId: shareId)
                isLoading = false
            }
        }
    }
    
    /// Finish current flow and return to dashboard
    func onFinish() {
        print("✅ Finishing current flow")
        
        // Clean up current content if needed
        if let shareId = state.currentShareId {
            cleanupSharedContent(shareId: shareId)
        }
        
        // Transition to dashboard
        state = .dashboard
        errorMessage = nil
        isLoading = false
    }
    
    /// Reset to idle state
    func reset() {
        print("🔄 Resetting to idle state")
        state = .idle
        errorMessage = nil
        isLoading = false
    }
    
    /// Navigate to dashboard
    func goToDashboard() {
        print("📊 Navigating to dashboard")
        state = .dashboard
    }
    
    // MARK: - Private Helpers
    
    private func loadSharedContent(id: String) throws -> SharedContent {
        // Try to load from SharedContainer
        let key = "share_\(id)"
        
        if let data: SharedContent = SharedContainer.readFromDefaults(forKey: key) {
            return data
        }
        
        // Fallback: try to load from file
        do {
            let content = try SharedContainer.loadCodable(SharedContent.self, from: "shared/\(id).json")
            return content
        } catch {
            // If not found, create a placeholder
            print("⚠️ Shared content not found, creating placeholder")
            return SharedContent(id: id)
        }
    }
    
    private func saveCurrentContent(_ content: SharedContent) {
        let key = "share_\(content.id)"
        SharedContainer.saveToDefaults(content, forKey: key)
    }
    
    private func performAnalysis(shareId: String) async throws -> AnalysisResult {
        // Log start
        AnalyticsService.shared.logEvent(.scanStarted, parameters: ["share_id": shareId])
        
        // Load the shared content
        let content = try loadSharedContent(id: shareId)
        
        // Perform analysis using the service
        let result = try await analysisService.analyze(content: content)
        
        // Log completion
        AnalyticsService.shared.logEvent(.scanCompleted, parameters: [
            "risk_score": result.riskScore,
            "confidence": result.confidence
        ])
        
        // Log flagged if high risk
        if result.riskScore >= 70 {
            AnalyticsService.shared.logEvent(.scanFlagged, parameters: [
                "risk_score": result.riskScore,
                "flags_count": result.redFlags.count
            ])
        }
        
        // Check confidence and log non-fatal if low
        if result.confidence < 0.5 {
            AnalyticsService.shared.recordError(
                AnalysisError.lowConfidence(score: result.confidence),
                userInfo: ["share_id": shareId]
            )
        }
        
        // Save result for later retrieval
        try SharedContainer.saveCodable(result, to: "result_\(shareId).json")
        
        // Simulate report sent (saved to backend)
        // In real app, this would be after CaseRepository.save()
        AnalyticsService.shared.logEvent(.reportSent, parameters: ["share_id": shareId])
        
        return result
    }
    
    private func cleanupSharedContent(shareId: String) {
        // Remove from UserDefaults
        SharedContainer.removeFromDefaults(forKey: "share_\(shareId)")
        
        // Remove files
        try? SharedContainer.deleteFile("shared/\(shareId).json")
        
        // Keep results for dashboard access
        // try? SharedContainer.deleteFile("result_\(shareId).json")
    }
}

// MARK: - Analysis Service

/// Service responsible for analyzing shared content
class AnalysisService {
    
    func analyze(content: SharedContent) async throws -> AnalysisResult {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        var findings: [String] = []
        var metadata: [String: String] = [:]
        
        // Analyze text if available
        if let text = content.text {
            findings.append("Text content detected: \(text.prefix(50))...")
            metadata["textLength"] = "\(text.count)"
        }
        
        // Analyze URL if available
        if let url = content.url {
            findings.append("URL detected: \(url)")
            metadata["url"] = url
        }
        
        // Analyze images if available
        if !content.imagePaths.isEmpty {
            findings.append("Images detected: \(content.imagePaths.count)")
            metadata["imageCount"] = "\(content.imagePaths.count)"
            
            // Load and analyze each image
            for (index, imagePath) in content.imagePaths.enumerated() {
                if SharedContainer.fileExists(imagePath) {
                    findings.append("Image \(index + 1): \(imagePath)")
                    metadata["image_\(index)"] = imagePath
                }
            }
        }
        
        // Calculate confidence based on available data
        let confidence = calculateConfidence(content: content, findings: findings)
        
        // Mock risk score for demo
        let riskScore = Int.random(in: 0...100)
        
        return AnalysisResult(
            shareId: content.id,
            timestamp: Date(),
            imageUrl: content.imagePaths.first,
            findings: findings,
            confidence: confidence,
            metadata: metadata,
            riskScore: riskScore,
            redFlags: riskScore > 50 ? ["mock_flag_1", "mock_flag_2"] : [],
            urlIntel: []
        )
    }
    
    private func calculateConfidence(content: SharedContent, findings: [String]) -> Double {
        var score = 0.0
        
        if content.text != nil { score += 0.3 }
        if content.url != nil { score += 0.2 }
        if !content.imagePaths.isEmpty { score += 0.5 }
        
        return min(score, 1.0)
    }
}
