//
//  MayyizApp.swift
//  Mayyiz
//
//  Created by Bola Samy on 09/11/2025.
//

import SwiftUI

// Note: Uncomment these imports after adding Firebase packages
 import FirebaseCore
 import FirebaseAuth
 import FirebaseFirestore

@main
struct MayyizApp: App {
    
    // MARK: - App Delegate
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - State
    
    @StateObject private var appViewModel = AppViewModel()
    
    // MARK: - Initialization
    
    init() {
        // Firebase is now configured in AppDelegate
        print("🚀 Mayyiz App Initialized")
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    // MARK: - URL Handling
    
    /// Handle incoming URL schemes (mayyiz://)
    private func handleIncomingURL(_ url: URL) {
        print("📱 Received URL: \(url.absoluteString)")
        
        // Parse the URL using URLHandler
        guard let route = URLHandler.parse(url) else {
            print("⚠️ Failed to parse URL: \(url)")
            return
        }
        
        print("✅ Parsed route: \(route.description)")
        
        // Route to appropriate action
        Task { @MainActor in
            switch route {
            case .share(let id):
                // Handle share handoff from Share Extension
                appViewModel.onShareHandoff(id: id)
                
            case .shareWithoutId:
                // Handle share without ID - check for pending share
                handleLegacyShare()
                
            case .profile(let userId):
                print("� Navigate to profile: \(userId)")
                // TODO: Navigate to profile view
                
            case .dashboard:
                appViewModel.goToDashboard()
                
            case .settings:
                print("⚙️ Navigate to settings")
                // TODO: Navigate to settings
                
            default:
                print("⚠️ Unhandled route: \(route.description)")
            }
        }
    }
    
    /// Handle legacy share format (without ID in URL)
    private func handleLegacyShare() {
        // Check for pending share in SharedContainer
        if let sharedData: [String: Any] = SharedContainer.readFromDefaults(forKey: "pendingShare") {
            print("📥 Found legacy shared data")
            
            // Create a SharedContent object from the legacy data
            let shareId = UUID().uuidString
            var imagePaths: [String] = []
            
            if let images = sharedData["images"] as? [String] {
                imagePaths = images
            }
            
            let content = SharedContent(
                id: shareId,
                text: sharedData["text"] as? String,
                url: sharedData["url"] as? String,
                imagePaths: imagePaths
            )
            
            // Save in new format
            SharedContainer.saveToDefaults(content, forKey: "share_\(shareId)")
            
            // Clean up legacy data
            SharedContainer.removeFromDefaults(forKey: "pendingShare")
            
            // Trigger share handoff
            Task { @MainActor in
                appViewModel.onShareHandoff(id: shareId)
            }
        } else {
            print("⚠️ No pending share data found")
        }
    }
}

// MARK: - Root View

/// Root view that switches based on app state
struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        Group {
            switch appViewModel.state {
            case .idle:
                IdleView()
                
            case .preview(let shareId):
                PreviewView(shareId: shareId)
                
            case .analyzing(let shareId):
                AnalyzingView(shareId: shareId)
                
            case .result(let shareId, let result):
                ResultView(shareId: shareId, result: result, viewModel: appViewModel)
                
            case .dashboard:
                DashboardView()
            }
        }
        .animation(.easeInOut, value: appViewModel.state)
    }
}
