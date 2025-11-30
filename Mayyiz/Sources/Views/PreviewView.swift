import SwiftUI

/// Preview state view - shows shared content before analysis
struct PreviewView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let shareId: String
    
    @State private var sharedContent: SharedContent?
    @State private var loadedImages: [UIImage] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Preview Content")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Review before analyzing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Content Preview
                    if let content = sharedContent {
                        contentPreviewSection(content)
                    } else {
                        ProgressView("Loading content...")
                            .padding()
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            appViewModel.onAnalyze()
                        }) {
                            Label("Analyze Content", systemImage: "wand.and.stars")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            appViewModel.reset()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadContent()
        }
    }
    
    @ViewBuilder
    private func contentPreviewSection(_ content: SharedContent) -> some View {
        VStack(spacing: 16) {
            // Text Content
            if let text = content.text {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Text", systemImage: "text.alignleft")
                        .font(.headline)
                    
                    Text(text)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            // URL Content
            if let urlString = content.url {
                VStack(alignment: .leading, spacing: 8) {
                    Label("URL", systemImage: "link")
                        .font(.headline)
                    
                    Text(urlString)
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            // Images
            if !loadedImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Images (\(loadedImages.count))", systemImage: "photo.stack")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                Label("Details", systemImage: "info.circle")
                    .font(.headline)
                
                VStack(spacing: 4) {
                    InfoRow(label: "Share ID", value: content.id)
                    InfoRow(label: "Timestamp", value: formatDate(content.timestamp))
                    InfoRow(label: "Images", value: "\(content.imagePaths.count)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
    
    private func loadContent() {
        // Load shared content
        let key = "share_\(shareId)"
        if let content: SharedContent = SharedContainer.readFromDefaults(forKey: key) {
            sharedContent = content
            loadImages(from: content.imagePaths)
        } else {
            // Try loading from file
            do {
                let content = try SharedContainer.loadCodable(SharedContent.self, from: "\(shareId).json")
                sharedContent = content
                loadImages(from: content.imagePaths)
            } catch {
                print("❌ Error loading content: \(error)")
                sharedContent = SharedContent(id: shareId)
            }
        }
    }
    
    private func loadImages(from paths: [String]) {
        loadedImages = []
        for path in paths {
            do {
                let data = try SharedContainer.readData(from: path)
                if let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            } catch {
                print("❌ Error loading image \(path): \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    PreviewView(shareId: "test-123")
        .environmentObject(AppViewModel())
}
