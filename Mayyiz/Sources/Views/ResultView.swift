import SwiftUI

struct ResultView: View {
    let shareId: String
    let result: AnalysisResult
    @ObservedObject var viewModel: AppViewModel
    
    @State private var selectedRedFlag: String?
    @State private var showImagePreview: Bool = false
    @State private var showLinkDetails: UrlIntelData?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Risk Header
                RiskHeaderView(score: result.riskScore)
                
                // Red Flags Chips
                if !result.redFlags.isEmpty {
                    RedFlagsSection(
                        flags: result.redFlags,
                        selectedFlag: $selectedRedFlag
                    )
                }
                
                // Image Preview with Overlay
                if let imageUrl = result.imageUrl, 
                   let image = UIImage(contentsOfFile: SharedContainer.fileURL(for: imageUrl)?.path ?? "") {
                    
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .onTapGesture {
                                showImagePreview = true
                            }
                        
                        // Placeholder for overlay boxes
                        // In a real implementation, we would map red flags to specific bounding boxes
                        if selectedRedFlag != nil {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 100, height: 40) // Dummy frame
                                .background(Color.red.opacity(0.1))
                                .position(x: 150, y: 100) // Dummy position
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                
                // Links List
                if !result.urlIntel.isEmpty {
                    LinksSection(
                        urls: result.urlIntel,
                        onPreview: { _ in showImagePreview = true },
                        onDetails: { data in showLinkDetails = data }
                    )
                }
                
                // Findings/Summary
                if !result.findings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Summary")
                            .font(.headline)
                        
                        ForEach(result.findings, id: \.self) { finding in
                            HStack(alignment: .top) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text(finding)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                Button(action: {
                    viewModel.onFinish()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Analysis Result")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showLinkDetails) { data in
            LinkDetailsView(data: data)
        }
        .sheet(isPresented: $showImagePreview) {
            if let imageUrl = result.imageUrl,
               let image = UIImage(contentsOfFile: SharedContainer.fileURL(for: imageUrl)?.path ?? "") {
                ImagePreviewView(image: image)
            }
        }
    }
}

// MARK: - Subviews

struct RiskHeaderView: View {
    let score: Int
    
    var riskLevel: (String, Color) {
        switch score {
        case 0..<30: return ("Low Risk", .green)
        case 30..<70: return ("Medium Risk", .orange)
        default: return ("High Risk", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(riskLevel.1, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(score)%")
                        .font(.system(size: 32, weight: .bold))
                    Text(riskLevel.0)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(riskLevel.1)
                }
            }
        }
        .padding(.top)
    }
}

struct RedFlagsSection: View {
    let flags: [String]
    @Binding var selectedFlag: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Red Flags")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(flags, id: \.self) { flag in
                        RedFlagChip(
                            text: flag.replacingOccurrences(of: "_", with: " ").capitalized,
                            isSelected: selectedFlag == flag,
                            action: {
                                if selectedFlag == flag {
                                    selectedFlag = nil
                                } else {
                                    selectedFlag = flag
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RedFlagChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.red : Color.red.opacity(0.1))
            .foregroundColor(isSelected ? .white : .red)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.red, lineWidth: 1)
            )
        }
    }
}

struct LinksSection: View {
    let urls: [UrlIntelData]
    let onPreview: (UrlIntelData) -> Void
    let onDetails: (UrlIntelData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Links")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(urls, id: \.url) { data in
                LinkRow(data: data, onPreview: onPreview, onDetails: onDetails)
            }
        }
    }
}

struct LinkRow: View {
    let data: UrlIntelData
    let onPreview: (UrlIntelData) -> Void
    let onDetails: (UrlIntelData) -> Void
    
    var riskColor: Color {
        switch data.verdict.lowercased() {
        case "malicious": return .red
        case "suspicious": return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.gray)
                
                if let finalUrl = data.finalUrl, finalUrl != data.url {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.url)
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(finalUrl)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .lineLimit(1)
                    .truncationMode(.middle)
                } else {
                    Text(data.url)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                Text(data.verdict.capitalized)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(riskColor.opacity(0.1))
                    .foregroundColor(riskColor)
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Source: \(data.source)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Preview") {
                    onPreview(data)
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Text("•")
                    .foregroundColor(.gray)
                
                Button("Details") {
                    onDetails(data)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Modals

struct LinkDetailsView: View {
    let data: UrlIntelData
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("URL Information")) {
                    DetailRow(label: "URL", value: data.url)
                    DetailRow(label: "Verdict", value: data.verdict.capitalized)
                    DetailRow(label: "Risk Score", value: "\(data.riskScore)/100")
                    DetailRow(label: "Source", value: data.source)
                }
                
                Section(header: Text("Redirect Chain")) {
                    Text("No redirects detected")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Link Details")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width)
                        .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("Image Preview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Extension to make UrlIntelData Identifiable for sheets
extension UrlIntelData: Identifiable {
    public var id: String { url }
}
