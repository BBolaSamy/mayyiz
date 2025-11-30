import Foundation

/// Represents the current state of the application flow
enum AppState: Equatable {
    case idle
    case preview(shareId: String)
    case analyzing(shareId: String)
    case result(shareId: String, analysisResult: AnalysisResult)
    case dashboard
    
    var isProcessing: Bool {
        if case .analyzing = self {
            return true
        }
        return false
    }
    
    var currentShareId: String? {
        switch self {
        case .preview(let id), .analyzing(let id), .result(let id, _):
            return id
        case .idle, .dashboard:
            return nil
        }
    }
}

/// Result of image analysis
struct AnalysisResult: Equatable, Codable {
    let shareId: String
    let timestamp: Date
    let imageUrl: String?
    let findings: [String]
    let confidence: Double
    let metadata: [String: String]
    
    // New fields for richer UI
    let riskScore: Int
    let redFlags: [String]
    let urlIntel: [UrlIntelData]
    
    init(shareId: String, 
         timestamp: Date = Date(),
         imageUrl: String? = nil,
         findings: [String] = [],
         confidence: Double = 0.0,
         metadata: [String: String] = [:],
         riskScore: Int = 0,
         redFlags: [String] = [],
         urlIntel: [UrlIntelData] = []) {
        self.shareId = shareId
        self.timestamp = timestamp
        self.imageUrl = imageUrl
        self.findings = findings
        self.confidence = confidence
        self.metadata = metadata
        self.riskScore = riskScore
        self.redFlags = redFlags
        self.urlIntel = urlIntel
    }
}

/// Shared data structure for content passed from Share Extension
struct SharedContent: Codable, Equatable {
    let id: String
    let timestamp: Date
    let text: String?
    let url: String?
    let imagePaths: [String]
    
    init(id: String = UUID().uuidString,
         timestamp: Date = Date(),
         text: String? = nil,
         url: String? = nil,
         imagePaths: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.url = url
        self.imagePaths = imagePaths
    }
}
