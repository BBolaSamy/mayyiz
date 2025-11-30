import SwiftUI

/// Dashboard state view - shows history and overview
struct DashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var recentResults: [AnalysisResult] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Dashboard")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your analysis history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Stats
                    statsSection
                    
                    // Recent Results
                    recentResultsSection
                    
                    Spacer(minLength: 20)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            appViewModel.onPickImage()
                        }) {
                            Label("New Analysis", systemImage: "plus.circle.fill")
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
                            Text("Back to Home")
                                .font(.headline)
                                .foregroundColor(.blue)
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
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadRecentResults()
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total",
                value: "\(recentResults.count)",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            StatCard(
                title: "Avg Score",
                value: averageConfidence,
                icon: "star.fill",
                color: .green
            )
            
            StatCard(
                title: "Recent",
                value: recentCount,
                icon: "clock.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Analyses", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .padding(.horizontal)
            
            if recentResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No analyses yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Start by picking an image or sharing content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentResults.prefix(10), id: \.shareId) { result in
                        ResultCard(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var averageConfidence: String {
        guard !recentResults.isEmpty else { return "0%" }
        let avg = recentResults.map { $0.confidence }.reduce(0, +) / Double(recentResults.count)
        return "\(Int(avg * 100))%"
    }
    
    private var recentCount: String {
        let recent = recentResults.filter { result in
            Calendar.current.isDateInToday(result.timestamp)
        }
        return "\(recent.count)"
    }
    
    private func loadRecentResults() {
        // Load all result files from SharedContainer
        do {
            let files = try SharedContainer.listFiles()
            let resultFiles = files.filter { $0.hasPrefix("result_") && $0.hasSuffix(".json") }
            
            var results: [AnalysisResult] = []
            for file in resultFiles {
                do {
                    let result = try SharedContainer.loadCodable(AnalysisResult.self, from: file)
                    results.append(result)
                } catch {
                    print("❌ Error loading result file \(file): \(error)")
                }
            }
            
            // Sort by timestamp, most recent first
            recentResults = results.sorted { $0.timestamp > $1.timestamp }
            
        } catch {
            print("❌ Error loading results: \(error)")
            recentResults = []
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ResultCard: View {
    let result: AnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(result.timestamp))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(result.findings.count) findings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text("\(Int(result.confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(result.shareId.prefix(8) + "...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppViewModel())
}
