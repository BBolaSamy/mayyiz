import XCTest
@testable import Mayyiz

/// Unit tests for TextNormalizer
final class TextNormalizerTests: XCTestCase {
    
    // MARK: - Arabic Diacritics Removal Tests
    
    func testRemoveDiacritics() {
        // Text with diacritics
        let textWithDiacritics = "مَرْحَبًا بِكُمْ"
        let expected = "مرحبا بكم"
        
        let normalized = TextNormalizer.normalizeArabic(textWithDiacritics)
        XCTAssertEqual(normalized, expected, "Should remove all Arabic diacritics")
    }
    
    func testRemoveTatweel() {
        // Text with tatweel (kashida)
        let textWithTatweel = "الـــــسلام عليـــكم"
        let expected = "السلام عليكم"
        
        let normalized = TextNormalizer.normalizeArabic(textWithTatweel)
        XCTAssertEqual(normalized, expected, "Should remove tatweel characters")
    }
    
    func testRemoveDiacriticsAndTatweel() {
        // Text with both diacritics and tatweel
        let text = "مَرْحَبًـــا بِكُـــمْ"
        let expected = "مرحبا بكم"
        
        let normalized = TextNormalizer.normalizeArabic(text)
        XCTAssertEqual(normalized, expected, "Should remove both diacritics and tatweel")
    }
    
    func testNormalizeAlefVariations() {
        // Different Alef forms
        let text = "أحمد إبراهيم آمال"
        let expected = "احمد ابراهيم امال"
        
        let normalized = TextNormalizer.normalizeArabic(text)
        XCTAssertEqual(normalized, expected, "Should normalize all Alef variations")
    }
    
    func testNormalizeTehMarbuta() {
        // Teh Marbuta to Heh
        let text = "مدرسة جامعة"
        let expected = "مدرسه جامعه"
        
        let normalized = TextNormalizer.normalizeArabic(text)
        XCTAssertEqual(normalized, expected, "Should normalize Teh Marbuta to Heh")
    }
    
    // MARK: - Number Normalization Tests
    
    func testConvertLatinToArabicNumbers() {
        let text = "الرقم 12345 والتاريخ 2024"
        let expected = "الرقم ١٢٣٤٥ والتاريخ ٢٠٢٤"
        
        let normalized = TextNormalizer.normalizeNumbers(text, toArabic: true)
        XCTAssertEqual(normalized, expected, "Should convert Latin numbers to Arabic-Indic")
    }
    
    func testConvertArabicToLatinNumbers() {
        let text = "الرقم ١٢٣٤٥ والتاريخ ٢٠٢٤"
        let expected = "الرقم 12345 والتاريخ 2024"
        
        let normalized = TextNormalizer.normalizeNumbers(text, toArabic: false)
        XCTAssertEqual(normalized, expected, "Should convert Arabic-Indic numbers to Latin")
    }
    
    func testConvertEasternArabicToLatinNumbers() {
        // Persian/Urdu numerals
        let text = "الرقم ۱۲۳۴۵"
        let expected = "الرقم 12345"
        
        let normalized = TextNormalizer.normalizeNumbers(text, toArabic: false)
        XCTAssertEqual(normalized, expected, "Should convert Eastern Arabic-Indic numbers to Latin")
    }
    
    func testMixedNumbers() {
        let text = "رقم ١٢٣ و 456 و ۷۸۹"
        let expected = "رقم 123 و 456 و 789"
        
        let normalized = TextNormalizer.normalizeNumbers(text, toArabic: false)
        XCTAssertEqual(normalized, expected, "Should normalize all number formats to Latin")
    }
    
    // MARK: - Full Normalization Tests
    
    func testFullNormalization() {
        let text = "  مَرْحَبًـــا   بِكُمْ  ١٢٣  "
        let expected = "مرحبا بكم 123"
        
        let normalized = TextNormalizer.normalize(text, numbersToArabic: false)
        XCTAssertEqual(normalized, expected, "Should apply all normalizations and trim whitespace")
    }
    
    func testFullNormalizationWithArabicNumbers() {
        let text = "  مَرْحَبًـــا   بِكُمْ  123  "
        let expected = "مرحبا بكم ١٢٣"
        
        let normalized = TextNormalizer.normalize(text, numbersToArabic: true)
        XCTAssertEqual(normalized, expected, "Should normalize to Arabic numbers")
    }
    
    func testNormalizeMultipleSpaces() {
        let text = "مرحبا    بكم     في    البرنامج"
        let expected = "مرحبا بكم في البرنامج"
        
        let normalized = TextNormalizer.normalize(text)
        XCTAssertEqual(normalized, expected, "Should normalize multiple spaces to single space")
    }
    
    // MARK: - Language Detection Tests
    
    func testDetectArabic() {
        let arabicText = "مرحبا بكم"
        XCTAssertTrue(TextNormalizer.containsArabic(arabicText), "Should detect Arabic text")
        
        let englishText = "Hello World"
        XCTAssertFalse(TextNormalizer.containsArabic(englishText), "Should not detect Arabic in English text")
    }
    
    func testDetectEnglish() {
        let englishText = "Hello World"
        XCTAssertTrue(TextNormalizer.containsEnglish(englishText), "Should detect English text")
        
        let arabicText = "مرحبا بكم"
        XCTAssertFalse(TextNormalizer.containsEnglish(arabicText), "Should not detect English in Arabic text")
    }
    
    func testDetectMixedLanguages() {
        let mixedText = "مرحبا Hello بكم World"
        
        XCTAssertTrue(TextNormalizer.containsArabic(mixedText), "Should detect Arabic in mixed text")
        XCTAssertTrue(TextNormalizer.containsEnglish(mixedText), "Should detect English in mixed text")
        
        let languages = TextNormalizer.detectLanguages(mixedText)
        XCTAssertTrue(languages.contains("ar"), "Should detect Arabic language")
        XCTAssertTrue(languages.contains("en"), "Should detect English language")
        XCTAssertEqual(languages.count, 2, "Should detect exactly 2 languages")
    }
    
    func testDetectOnlyArabic() {
        let arabicText = "مرحبا بكم في البرنامج"
        let languages = TextNormalizer.detectLanguages(arabicText)
        
        XCTAssertEqual(languages, ["ar"], "Should detect only Arabic")
    }
    
    func testDetectOnlyEnglish() {
        let englishText = "Hello World Welcome"
        let languages = TextNormalizer.detectLanguages(englishText)
        
        XCTAssertEqual(languages, ["en"], "Should detect only English")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyString() {
        let empty = ""
        let normalized = TextNormalizer.normalize(empty)
        XCTAssertEqual(normalized, "", "Should handle empty string")
    }
    
    func testOnlyWhitespace() {
        let whitespace = "   \n\t   "
        let normalized = TextNormalizer.normalize(whitespace)
        XCTAssertEqual(normalized, "", "Should trim whitespace-only string to empty")
    }
    
    func testOnlyNumbers() {
        let numbers = "12345"
        let normalized = TextNormalizer.normalize(numbers, numbersToArabic: true)
        XCTAssertEqual(normalized, "١٢٣٤٥", "Should normalize numbers")
    }
    
    func testSpecialCharacters() {
        let text = "مرحبا! Hello? 123."
        let normalized = TextNormalizer.normalize(text, numbersToArabic: false)
        XCTAssertTrue(normalized.contains("!"), "Should preserve punctuation")
        XCTAssertTrue(normalized.contains("?"), "Should preserve question mark")
        XCTAssertTrue(normalized.contains("."), "Should preserve period")
    }
}
