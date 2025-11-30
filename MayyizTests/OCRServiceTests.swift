import XCTest
import Vision
@testable import Mayyiz

/// Unit tests for OCRService
final class OCRServiceTests: XCTestCase {
    
    var ocrService: OCRService!
    
    override func setUp() async throws {
        await MainActor.run {
            ocrService = OCRService(
                recognitionLevel: .accurate,
                languages: ["ar", "en"],
                normalizeNumbers: true,
                numbersToArabic: false
            )
        }
    }
    
    override func tearDown() {
        ocrService = nil
    }
    
    // MARK: - Image Creation Helpers
    
    /// Create a test image with text
    func createTestImage(text: String, fontSize: CGFloat = 40) -> UIImage {
        let size = CGSize(width: 800, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Black text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.black
            ]
            
            let textSize = (text as NSString).size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Basic OCR Tests
    
    func testRecognizeEnglishText() async throws {
        let testText = "Hello World"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize text")
        XCTAssertTrue(result.text.contains("Hello"), "Should contain 'Hello'")
        XCTAssertTrue(result.text.contains("World"), "Should contain 'World'")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence > 0")
    }
    
    func testRecognizeArabicText() async throws {
        let testText = "مرحبا بكم"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize Arabic text")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence > 0")
        XCTAssertTrue(result.detectedLanguages.contains("ar"), "Should detect Arabic language")
    }
    
    func testRecognizeMixedArabicEnglish() async throws {
        let testText = "Hello مرحبا"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize mixed text")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence > 0")
        
        // Should detect both languages
        XCTAssertTrue(
            result.detectedLanguages.contains("ar") || result.detectedLanguages.contains("en"),
            "Should detect at least one language"
        )
    }
    
    // MARK: - Number Normalization Tests
    
    func testRecognizeAndNormalizeNumbers() async throws {
        let testText = "Price 12345"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize text with numbers")
        XCTAssertTrue(result.text.contains("12345") || result.text.contains("١٢٣٤٥"), 
                     "Should contain numbers")
    }
    
    func testNormalizeNumbersToLatin() async throws {
        await MainActor.run {
            ocrService = OCRService(
                recognitionLevel: .accurate,
                languages: ["ar", "en"],
                normalizeNumbers: true,
                numbersToArabic: false
            )
        }
        
        let testText = "123"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        // Numbers should be in Latin format
        XCTAssertTrue(result.text.contains("123"), "Should normalize to Latin numbers")
    }
    
    // MARK: - Confidence Threshold Tests
    
    func testConfidenceThreshold() async throws {
        let testText = "Clear Text"
        let image = createTestImage(text: testText, fontSize: 60)
        
        let result = try await ocrService.recognizeText(in: image)
        
        // Test different thresholds
        XCTAssertTrue(result.meetsConfidenceThreshold(0.0), "Should meet 0% threshold")
        
        // High quality text should have good confidence
        if result.confidence > 0.5 {
            XCTAssertTrue(result.meetsConfidenceThreshold(0.5), "Should meet 50% threshold")
        }
    }
    
    func testLowConfidenceText() async throws {
        // Create a very small, hard-to-read image
        let testText = "Tiny"
        let image = createTestImage(text: testText, fontSize: 8)
        
        let result = try await ocrService.recognizeText(in: image)
        
        // May have lower confidence due to small size
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0, "Confidence should be >= 0")
        XCTAssertLessThanOrEqual(result.confidence, 1.0, "Confidence should be <= 1")
    }
    
    // MARK: - Bounding Box Tests
    
    func testBoundingBoxes() async throws {
        let testText = "Test"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.boxes.isEmpty, "Should have bounding boxes")
        
        // Check that boxes are valid
        for box in result.boxes {
            XCTAssertGreaterThanOrEqual(box.width, 0, "Box width should be >= 0")
            XCTAssertGreaterThanOrEqual(box.height, 0, "Box height should be >= 0")
            XCTAssertGreaterThanOrEqual(box.origin.x, 0, "Box x should be >= 0")
            XCTAssertGreaterThanOrEqual(box.origin.y, 0, "Box y should be >= 0")
            XCTAssertLessThanOrEqual(box.origin.x + box.width, 1.0, "Box should be within bounds")
            XCTAssertLessThanOrEqual(box.origin.y + box.height, 1.0, "Box should be within bounds")
        }
    }
    
    func testRegionConfidences() async throws {
        let testText = "Multiple Words Here"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.regionConfidences.isEmpty, "Should have region confidences")
        
        // All confidences should be between 0 and 1
        for confidence in result.regionConfidences {
            XCTAssertGreaterThanOrEqual(confidence, 0.0, "Confidence should be >= 0")
            XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should be <= 1")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidImage() async {
        // Create an invalid image (1x1 transparent)
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let invalidImage = renderer.image { _ in }
        
        do {
            _ = try await ocrService.recognizeText(in: invalidImage)
            // May or may not throw - Vision is resilient
        } catch {
            // Expected for some invalid images
            XCTAssertTrue(error is OCRError, "Should throw OCRError")
        }
    }
    
    func testEmptyImage() async {
        // Create a blank white image
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let blankImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        do {
            let result = try await ocrService.recognizeText(in: blankImage)
            // Should return empty or very low confidence
            XCTAssertTrue(result.text.isEmpty || result.confidence < 0.3, 
                         "Blank image should have no text or low confidence")
        } catch OCRError.noTextFound {
            // This is also acceptable
            XCTAssertTrue(true, "No text found is expected for blank image")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchProcessing() async throws {
        let images = [
            createTestImage(text: "First"),
            createTestImage(text: "Second"),
            createTestImage(text: "Third")
        ]
        
        let results = try await ocrService.recognizeText(in: images)
        
        XCTAssertEqual(results.count, 3, "Should process all images")
        
        for result in results {
            XCTAssertFalse(result.text.isEmpty, "Each result should have text")
            XCTAssertGreaterThan(result.confidence, 0.0, "Each result should have confidence")
        }
    }
    
    // MARK: - Mixed Language Samples Tests
    
    func testMixedArabicEnglishSample1() async throws {
        let testText = "Welcome مرحبا 2024"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize mixed text")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence")
        
        // Should normalize numbers to Latin
        XCTAssertTrue(result.text.contains("2024"), "Should contain normalized numbers")
    }
    
    func testMixedArabicEnglishSample2() async throws {
        let testText = "Email: test@example.com الايميل"
        let image = createTestImage(text: testText, fontSize: 30)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize email and Arabic")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence")
    }
    
    func testArabicWithDiacritics() async throws {
        let testText = "مَرْحَبًا"
        let image = createTestImage(text: testText)
        
        let result = try await ocrService.recognizeText(in: image)
        
        XCTAssertFalse(result.text.isEmpty, "Should recognize Arabic with diacritics")
        // Diacritics should be removed by normalization
        XCTAssertFalse(result.text.contains("\u{064B}"), "Should remove diacritics")
    }
    
    // MARK: - Language Support Tests
    
    func testSupportedLanguages() {
        let supported = OCRService.getAllSupportedLanguages()
        
        XCTAssertTrue(supported.contains("ar"), "Should support Arabic")
        XCTAssertTrue(supported.contains("en"), "Should support English")
    }
    
    func testIsLanguageSupported() {
        XCTAssertTrue(OCRService.isLanguageSupported("ar"), "Arabic should be supported")
        XCTAssertTrue(OCRService.isLanguageSupported("en"), "English should be supported")
        XCTAssertFalse(OCRService.isLanguageSupported("fr"), "French should not be supported")
    }
    
    // MARK: - OCRResult Tests
    
    func testOCRResultEquality() {
        let result1 = OCRResult(text: "Test", boxes: [], confidence: 0.9)
        let result2 = OCRResult(text: "Test", boxes: [], confidence: 0.9)
        let result3 = OCRResult(text: "Different", boxes: [], confidence: 0.9)
        
        XCTAssertEqual(result1, result2, "Identical results should be equal")
        XCTAssertNotEqual(result1, result3, "Different results should not be equal")
    }
    
    func testOCRResultCodable() throws {
        let original = OCRResult(
            text: "Test Text",
            boxes: [CGRect(x: 0, y: 0, width: 100, height: 50)],
            confidence: 0.95,
            regionConfidences: [0.95],
            detectedLanguages: ["en"]
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OCRResult.self, from: data)
        
        XCTAssertEqual(decoded.text, original.text, "Text should match")
        XCTAssertEqual(decoded.confidence, original.confidence, "Confidence should match")
        XCTAssertEqual(decoded.boxes.count, original.boxes.count, "Boxes count should match")
        XCTAssertEqual(decoded.detectedLanguages, original.detectedLanguages, "Languages should match")
    }
    
    func testTextRegions() {
        let result = OCRResult(
            text: "Line 1\nLine 2\nLine 3",
            boxes: [
                CGRect(x: 0, y: 0, width: 100, height: 20),
                CGRect(x: 0, y: 25, width: 100, height: 20),
                CGRect(x: 0, y: 50, width: 100, height: 20)
            ],
            confidence: 0.9,
            regionConfidences: [0.9, 0.85, 0.95]
        )
        
        let regions = result.textRegions
        
        XCTAssertEqual(regions.count, 3, "Should have 3 regions")
        XCTAssertEqual(regions[0].text, "Line 1", "First region should be 'Line 1'")
        XCTAssertEqual(regions[1].text, "Line 2", "Second region should be 'Line 2'")
        XCTAssertEqual(regions[2].text, "Line 3", "Third region should be 'Line 3'")
    }
}
