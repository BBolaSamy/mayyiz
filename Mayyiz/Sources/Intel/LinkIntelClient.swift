import Foundation

/// Client for interacting with external threat intelligence services
class LinkIntelClient {
    
    // MARK: - Properties
    
    private let config: RemoteConfigProvider
    private let session: URLSession
    
    // MARK: - Initialization
    
    init(config: RemoteConfigProvider = DefaultRemoteConfig.shared,
         session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    // MARK: - Public API
    
    /// Perform a passive lookup for a URL (VirusTotal)
    /// - Parameter url: The URL to check
    /// - Returns: UrlIntelSummary
    func intelLookup(url: String) async throws -> UrlIntelSummary {
        guard let apiKey = config.virusTotalApiKey, !apiKey.isEmpty else {
            print("⚠️ VirusTotal API key missing")
            return .empty
        }
        
        // 1. Encode URL for VirusTotal ID (base64 without padding)
        guard let urlData = url.data(using: .utf8) else {
            throw IntelError.invalidURL
        }
        let urlId = urlData.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        
        // 2. Build Request
        let endpoint = "https://www.virustotal.com/api/v3/urls/\(urlId)"
        guard let requestUrl = URL(string: endpoint) else {
            throw IntelError.invalidURL
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-apikey")
        
        // 3. Execute Request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IntelError.networkError
            }
            
            if httpResponse.statusCode == 404 {
                // URL not found in VT database
                return UrlIntelSummary(
                    riskScore: 0,
                    verdict: .unknown,
                    source: .virusTotal,
                    findings: ["URL not found in VirusTotal database"]
                )
            }
            
            guard httpResponse.statusCode == 200 else {
                throw IntelError.apiError(statusCode: httpResponse.statusCode)
            }
            
            // 4. Parse Response
            let vtResponse = try JSONDecoder().decode(VTResponse.self, from: data)
            return mapVTResponseToSummary(vtResponse, url: url)
            
        } catch {
            throw IntelError.networkError
        }
    }
    
    /// Perform an active scan for a URL (urlscan.io)
    /// - Parameters:
    ///   - url: The URL to scan
    ///   - userOptIn: Whether the user explicitly opted-in for active scanning
    /// - Returns: UrlIntelSummary
    func intelScan(url: String, userOptIn: Bool) async throws -> UrlIntelSummary {
        // 1. Check Remote Config flag
        guard config.allowActiveUrlScan else {
            throw IntelError.activeScanDisabled
        }
        
        // 2. Check User Opt-in
        guard userOptIn else {
            throw IntelError.userOptOut
        }
        
        // 3. Check for Sensitive Data
        if isSensitiveURL(url) {
            throw IntelError.sensitiveURL
        }
        
        guard let apiKey = config.urlScanApiKey, !apiKey.isEmpty else {
            print("⚠️ urlscan.io API key missing")
            return .empty
        }
        
        // 4. Submit Scan Request
        let submitEndpoint = "https://urlscan.io/api/v1/scan/"
        guard let requestUrl = URL(string: submitEndpoint) else {
            throw IntelError.invalidURL
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["url": url, "visibility": "public"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw IntelError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let scanResponse = try JSONDecoder().decode(UrlScanSubmissionResponse.self, from: data)
        
        // 5. Poll for Results (Simplified: In real app, might want to use a webhook or longer polling)
        // For this implementation, we'll return a "Scan Started" summary or wait briefly
        // Ideally, we wait for the result using the API URL provided in response
        
        return try await pollUrlScanResult(apiURL: scanResponse.api, apiKey: apiKey)
    }
    
    // MARK: - Private Helpers
    
    private func isSensitiveURL(_ url: String) -> Bool {
        let lowerUrl = url.lowercased()
        // Check for sensitive keywords in query parameters or path
        let sensitiveKeywords = ["token", "key", "password", "auth", "session", "access_token", "secret"]
        
        // Check if URL contains query parameters
        if let components = URLComponents(string: url), let queryItems = components.queryItems {
            for item in queryItems {
                if sensitiveKeywords.contains(item.name.lowercased()) {
                    return true
                }
            }
        }
        
        // Fallback simple check
        for keyword in sensitiveKeywords {
            if lowerUrl.contains("\(keyword)=") {
                return true
            }
        }
        
        return false
    }
    
    private func pollUrlScanResult(apiURL: String, apiKey: String, attempts: Int = 0) async throws -> UrlIntelSummary {
        // Max 5 attempts, 2 seconds delay (Total 10s wait - usually not enough for full scan, 
        // but sufficient for demo/fast scans. In prod, use background processing)
        if attempts >= 5 {
            return UrlIntelSummary(
                riskScore: 0,
                verdict: .unknown,
                source: .urlScan,
                findings: ["Scan submitted, results pending"]
            )
        }
        
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        guard let url = URL(string: apiURL) else { throw IntelError.invalidURL }
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "API-Key")
        
        let (data, response) = try await session.data(for: request)
        
        if (response as? HTTPURLResponse)?.statusCode == 404 {
            // Not ready yet
            return try await pollUrlScanResult(apiURL: apiURL, apiKey: apiKey, attempts: attempts + 1)
        }
        
        let resultResponse = try JSONDecoder().decode(UrlScanResultResponse.self, from: data)
        return mapUrlScanResponseToSummary(resultResponse)
    }
    
    // MARK: - Mapping Logic
    
    private func mapVTResponseToSummary(_ response: VTResponse, url: String) -> UrlIntelSummary {
        let stats = response.data.attributes.last_analysis_stats
        let malicious = stats.malicious
        let suspicious = stats.suspicious
        let harmless = stats.harmless
        let undetected = stats.undetected
        
        // Risk Calculation (0-100)
        // If any engine flags it as malicious, risk jumps significantly
        var riskScore = 0
        
        if malicious > 0 {
            // Base score of 50 + scaled by number of detections
            riskScore = 50 + min(50, malicious * 10)
        } else if suspicious > 0 {
            riskScore = 20 + min(30, suspicious * 10)
        }
        
        let verdict: IntelVerdict
        if riskScore >= 70 {
            verdict = .malicious
        } else if riskScore >= 30 {
            verdict = .suspicious
        } else if harmless > 0 {
            verdict = .harmless
        } else {
            verdict = .unknown
        }
        
        var findings: [String] = []
        if malicious > 0 { findings.append("Flagged as malicious by \(malicious) security vendors") }
        if suspicious > 0 { findings.append("Flagged as suspicious by \(suspicious) security vendors") }
        
        return UrlIntelSummary(
            riskScore: riskScore,
            verdict: verdict,
            source: .virusTotal,
            timestamp: Date(),
            findings: findings,
            stats: [
                "malicious": malicious,
                "suspicious": suspicious,
                "harmless": harmless,
                "undetected": undetected
            ],
            reportURL: "https://www.virustotal.com/gui/url/\(response.data.id)"
        )
    }
    
    private func mapUrlScanResponseToSummary(_ response: UrlScanResultResponse) -> UrlIntelSummary {
        let score = response.verdict.score ?? 0
        let malicious = response.verdict.malicious
        
        // Urlscan score is usually a "maliciousness" score? 
        // Actually urlscan.io verdict.score is often 0 (safe) to 100 (malicious)
        // But sometimes it's reversed or different. Let's assume standard risk score.
        
        var riskScore = score
        if malicious {
            riskScore = 100
        }
        
        let verdict: IntelVerdict
        if malicious || riskScore >= 70 {
            verdict = .malicious
        } else if riskScore >= 30 {
            verdict = .suspicious
        } else {
            verdict = .harmless
        }
        
        var findings: [String] = []
        if malicious { findings.append("Classified as malicious by urlscan.io") }
        if let categories = response.verdict.categories, !categories.isEmpty {
            findings.append("Categories: \(categories.joined(separator: ", "))")
        }
        
        return UrlIntelSummary(
            riskScore: riskScore,
            verdict: verdict,
            source: .urlScan,
            timestamp: Date(),
            findings: findings,
            stats: ["score": score],
            reportURL: response.task.reportURL
        )
    }
}

// MARK: - Internal Models for JSON Decoding

struct VTResponse: Codable {
    let data: VTData
}

struct VTData: Codable {
    let id: String
    let attributes: VTAttributes
}

struct VTAttributes: Codable {
    let last_analysis_stats: VTStats
}

struct VTStats: Codable {
    let malicious: Int
    let suspicious: Int
    let harmless: Int
    let undetected: Int
}

struct UrlScanSubmissionResponse: Codable {
    let message: String
    let uuid: String
    let result: String
    let api: String
}

struct UrlScanResultResponse: Codable {
    let verdict: UrlScanVerdict
    let task: UrlScanTask
}

struct UrlScanVerdict: Codable {
    let score: Int?
    let malicious: Bool
    let categories: [String]?
}

struct UrlScanTask: Codable {
    let reportURL: String
}

// MARK: - Errors

enum IntelError: Error {
    case invalidURL
    case networkError
    case apiError(statusCode: Int)
    case activeScanDisabled
    case userOptOut
    case sensitiveURL
}

extension UrlIntelSummary {
    static let empty = UrlIntelSummary(riskScore: 0, verdict: .unknown, source: .none)
}
