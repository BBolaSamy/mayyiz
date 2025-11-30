import SwiftUI
import Combine

/// View model for managing app settings
class SettingsViewModel: ObservableObject {
    
    // MARK: - App Preferences (AppStorage)
    
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @AppStorage("numberFormat") var numberFormat: String = "western" // western (123) or arabic (١٢٣)
    @AppStorage("redactByDefault") var redactByDefault: Bool = true
    @AppStorage("cloudOCRFallback") var cloudOCRFallback: Bool = true
    @AppStorage("activeUrlScan") var activeUrlScan: Bool = false
    
    // MARK: - Account State
    
    @Published var isAnonymous: Bool = true
    @Published var phoneNumber: String? = nil
    
    // MARK: - Actions
    
    func exportData() -> URL? {
        // Simulate export - in real app, gather all data from CaseRepository
        let fileName = "mayyiz_export_\(Date().timeIntervalSince1970).json"
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let dummyData = ["export_date": Date().description, "cases_count": "10"]
        
        do {
            let data = try JSONEncoder().encode(dummyData)
            try data.write(to: tempUrl)
            return tempUrl
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    func deleteData() {
        // Simulate data deletion
        print("🗑️ Deleting all user data...")
        // In real app: CaseRepository.deleteAll()
    }
    
    func upgradeAccount() {
        // Simulate upgrade flow
        print("🚀 Upgrading account...")
        // In real app: Trigger Firebase Auth flow
    }
}
