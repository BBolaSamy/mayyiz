import XCTest
@testable import Mayyiz

class LinkIntelClientTests: XCTestCase {
    
    var client: LinkIntelClient!
    var mockConfig: MockRemoteConfig!
    
    override func setUp() {
        super.setUp()
        mockConfig = MockRemoteConfig()
        client = LinkIntelClient(config: mockConfig)
    }
    
    func testSensitiveURLDetection() async {
        mockConfig.allowActiveUrlScan = true
        mockConfig.urlScanApiKey = "test-key"
        
        let sensitiveUrl = "https://example.com?token=12345secret"
        
        do {
            _ = try await client.intelScan(url: sensitiveUrl, userOptIn: true)
            XCTFail("Should have thrown sensitiveURL error")
        } catch IntelError.sensitiveURL {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testActiveScanDisabled() async {
        mockConfig.allowActiveUrlScan = false
        
        do {
            _ = try await client.intelScan(url: "https://example.com", userOptIn: true)
            XCTFail("Should have thrown activeScanDisabled error")
        } catch IntelError.activeScanDisabled {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserOptOut() async {
        mockConfig.allowActiveUrlScan = true
        
        do {
            _ = try await client.intelScan(url: "https://example.com", userOptIn: false)
            XCTFail("Should have thrown userOptOut error")
        } catch IntelError.userOptOut {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

class MockRemoteConfig: RemoteConfigProvider {
    var allowActiveUrlScan: Bool = false
    var virusTotalApiKey: String? = "mock-vt-key"
    var urlScanApiKey: String? = "mock-urlscan-key"
}
