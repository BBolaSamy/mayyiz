import SwiftUI

/// Analyzing state view - shows progress while analyzing
struct AnalyzingView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let shareId: String
    
    @State private var animationAmount = 0.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Animated Icon
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(animationAmount))
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Analyzing Content")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This may take a few moments...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Spacer()
                
                // Info
                VStack(spacing: 8) {
                    Text("Share ID: \(shareId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Analyzing")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationAmount = 360
            }
        }
    }
}

#Preview {
    AnalyzingView(shareId: "test-123")
        .environmentObject(AppViewModel())
}
