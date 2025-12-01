import SwiftUI

/// Idle state view - the starting point of the app
struct IdleView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon/Logo
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Mayyiz")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Share and analyze your content")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        appViewModel.onPickImage()
                    }) {
                        Label("Pick Image", systemImage: "photo.on.rectangle.angled")
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
                    
                    NavigationLink(destination: ShareExtensionTestView()) {
                        Label("Test Share Extension", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        appViewModel.goToDashboard()
                    }) {
                        Label("View Dashboard", systemImage: "square.grid.2x2")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Info
                Text("Share content from other apps to analyze")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("Mayyiz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    IdleView()
        .environmentObject(AppViewModel())
}
