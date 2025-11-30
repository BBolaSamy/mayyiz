import Foundation
import FirebaseFirestore

/// Main payload for a saved case
struct CasePayload: Codable, Identifiable {
    @DocumentID var id: String?
    let createdAt: Date
    let country: String
    let channel: String
    let ocr: String?
    let extracted: ExtractedData
    let result: AnalysisResultData
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case country
        case channel
        case ocr
        case extracted
        case result
    }
}

struct ExtractedData: Codable {
    let urls: [String]
    let senderHash: String?
    let subjectHash: String?
    let numberOfSections: Int
}

struct AnalysisResultData: Codable {
    let riskScore: Int
    let summary: String
    let redFlags: [String] // Storing raw values of RedFlag enum
    let urlIntel: [UrlIntelData]
    let telemetry: [String: String]
}

struct UrlIntelData: Codable, Equatable {
    let url: String
    let finalUrl: String? // Added for redirect chain
    let riskScore: Int
    let verdict: String
    let source: String
}

/// Counters for user statistics
struct UserCounters: Codable {
    let totalCases: Int
    let highRiskCases: Int
    let lastActive: Date
}
