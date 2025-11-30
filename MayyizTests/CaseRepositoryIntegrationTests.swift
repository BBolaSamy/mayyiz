import XCTest
import FirebaseFirestore
@testable import Mayyiz

final class CaseRepositoryIntegrationTests: XCTestCase {
    
    var repository: CaseRepository!
    var userId: String!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Configure Firestore to use the emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        repository = CaseRepository()
        userId = "test_user_\(UUID().uuidString)"
    }
    
    override func tearDown() async throws {
        // Cleanup if necessary (emulator data is transient usually, but good practice)
        repository = nil
        try await super.tearDown()
    }
    
    func testSaveCaseAndIncrementCounters() async throws {
        // Given
        let casePayload = CasePayload(
            id: nil,
            createdAt: Date(),
            country: "SA",
            channel: "sms",
            ocr: "Test OCR Text",
            extracted: ExtractedData(
                urls: ["https://example.com"],
                senderHash: "abc123hash",
                subjectHash: nil,
                numberOfSections: 2
            ),
            result: AnalysisResultData(
                riskScore: 75,
                summary: "High risk detected",
                redFlags: ["urgency_phrase", "shortlink"],
                urlIntel: [
                    UrlIntelData(
                        url: "https://example.com",
                        riskScore: 50,
                        verdict: "suspicious",
                        source: "VirusTotal"
                    )
                ],
                telemetry: ["device": "iPhone 15"]
            )
        )
        
        // When
        try await repository.save(userId: userId, casePayload: casePayload)
        
        // Then
        
        // 1. Verify Case Saved
        let cases = try await repository.fetchCases(userId: userId)
        XCTAssertEqual(cases.count, 1)
        let savedCase = cases.first!
        XCTAssertEqual(savedCase.country, "SA")
        XCTAssertEqual(savedCase.result.riskScore, 75)
        XCTAssertEqual(savedCase.extracted.urls.first, "https://example.com")
        
        // 2. Verify Counters Incremented
        let counters = try await repository.fetchCounters(userId: userId)
        XCTAssertNotNil(counters)
        XCTAssertEqual(counters?.totalCases, 1)
        XCTAssertEqual(counters?.highRiskCases, 1) // Should be 1 because riskScore 75 >= 70
    }
    
    func testCounterIncrementMultipleCases() async throws {
        // Given
        let highRiskCase = CasePayload(
            id: nil, createdAt: Date(), country: "US", channel: "email", ocr: nil,
            extracted: ExtractedData(urls: [], senderHash: nil, subjectHash: nil, numberOfSections: 0),
            result: AnalysisResultData(riskScore: 80, summary: "", redFlags: [], urlIntel: [], telemetry: [:])
        )
        
        let lowRiskCase = CasePayload(
            id: nil, createdAt: Date(), country: "US", channel: "email", ocr: nil,
            extracted: ExtractedData(urls: [], senderHash: nil, subjectHash: nil, numberOfSections: 0),
            result: AnalysisResultData(riskScore: 20, summary: "", redFlags: [], urlIntel: [], telemetry: [:])
        )
        
        // When
        try await repository.save(userId: userId, casePayload: highRiskCase)
        try await repository.save(userId: userId, casePayload: lowRiskCase)
        try await repository.save(userId: userId, casePayload: highRiskCase)
        
        // Then
        let counters = try await repository.fetchCounters(userId: userId)
        XCTAssertEqual(counters?.totalCases, 3)
        XCTAssertEqual(counters?.highRiskCases, 2)
    }
}
