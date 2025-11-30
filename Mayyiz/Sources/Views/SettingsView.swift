import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showExportSheet = false
    @State private var exportUrl: URL?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Appearance & Language
                Section(header: Text("Appearance & Language")) {
                    Picker("Language", selection: $viewModel.appLanguage) {
                        Text("English").tag("en")
                        Text("العربية").tag("ar")
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Numerals", selection: $viewModel.numberFormat) {
                        Text("123").tag("western")
                        Text("١٢٣").tag("arabic")
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Privacy & Security
                Section(header: Text("Privacy & Security")) {
                    Toggle("Redact Sensitive Info By Default", isOn: $viewModel.redactByDefault)
                    Toggle("Active URL Scan (urlscan.io)", isOn: $viewModel.activeUrlScan)
                        .onChange(of: viewModel.activeUrlScan) { newValue in
                            if newValue {
                                // In real app, show warning/consent dialog here
                            }
                        }
                }
                
                // MARK: - Analysis
                Section(header: Text("Analysis")) {
                    Toggle("Cloud OCR Fallback", isOn: $viewModel.cloudOCRFallback)
                }
                
                // MARK: - Data Management
                Section(header: Text("Data Management")) {
                    Button(action: {
                        if let url = viewModel.exportData() {
                            exportUrl = url
                            showExportSheet = true
                        }
                    }) {
                        Label("Export Data (JSON)", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // MARK: - Account
                Section(header: Text("Account")) {
                    if viewModel.isAnonymous {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Anonymous User")
                                    .font(.headline)
                                Text("Upgrade to sync across devices")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Upgrade") {
                                viewModel.upgradeAccount()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        HStack {
                            Text("Phone")
                            Spacer()
                            Text(viewModel.phoneNumber ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            // Simulate RTL based on language selection
            .environment(\.layoutDirection, viewModel.appLanguage == "ar" ? .rightToLeft : .leftToRight)
            .sheet(isPresented: $showExportSheet) {
                if let url = exportUrl {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete All Data?"),
                    message: Text("This action cannot be undone. All your analysis history will be permanently removed."),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.deleteData()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// MARK: - Helper Views

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
