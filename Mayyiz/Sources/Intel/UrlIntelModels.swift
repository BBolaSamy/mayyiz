import Foundation

/// Summary of threat intelligence for a URL
struct UrlIntelSummary: Codable, Equatable {
    /// Unified risk score (0-100)
    let riskScore: Int
    
    /// Verdict from the analysis
    let verdict: IntelVerdict
    
    /// Source of the intelligence
    let source: IntelSource
    
    /// Timestamp of the analysis
    let timestamp: Date
    
    /// Specific findings
    let findings: [String]
    
    /// Raw stats (e.g. malicious count)
    let stats: [String: Int]
    
    /// URL to the full report
    let reportURL: String?
    
    init(riskScore: Int,
         verdict: IntelVerdict,
         source: IntelSource,
         timestamp: Date = Date(),
         findings: [String] = [],
         stats: [String: Int] = [:],
         reportURL: String? = nil) {
        self.riskScore = min(100, max(0, riskScore))
        self.verdict = verdict
        self.source = source
        self.timestamp = timestamp
        self.findings = findings
        self.stats = stats
        self.reportURL = reportURL
    }
    
    var isHighRisk: Bool {
        return riskScore >= 70
    }
}

enum IntelVerdict: String, Codable {
    case malicious
    case suspicious
    case harmless
    case unknown
}

enum IntelSource: String, Codable {
    case virusTotal = "VirusTotal"
    case urlScan = "urlscan.io"
    case cache = "Local Cache"
    case none = "None"
}

/// Protocol for fetching remote configuration
protocol RemoteConfigProvider {
    var allowActiveUrlScan: Bool { get }
    var virusTotalApiKey: String? { get }
    var urlScanApiKey: String? { get }
}

/// Default implementation using local settings (to be replaced/extended with Firebase)
class DefaultRemoteConfig: RemoteConfigProvider {
    static let shared = DefaultRemoteConfig()
    
    var allowActiveUrlScan: Bool {
        // In a real app, fetch from Firebase Remote Config
        // For now, return true for testing purposes
        return UserDefaults.standard.bool(forKey: "allowActiveUrlScan")
    }
    
    var virusTotalApiKey: String? {
        // Retrieve from secure storage or config
        return ProcessInfo.processInfo.environment["VT_API_KEY"]
    }
    
    var urlScanApiKey: String? {
        // Retrieve from secure storage or config
        return ProcessInfo.processInfo.environment["URLSCAN_API_KEY"]
    }
}
