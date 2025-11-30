import Foundation

/// Normalizes Arabic and mixed-language text
struct TextNormalizer {
    
    // MARK: - Arabic Normalization
    
    /// Normalize Arabic text by removing diacritics and tatweel
    static func normalizeArabic(_ text: String) -> String {
        var normalized = text
        
        // Remove Arabic diacritics (tashkeel)
        normalized = removeDiacritics(normalized)
        
        // Remove tatweel (kashida) - Arabic elongation character
        normalized = removeTatweel(normalized)
        
        // Normalize Arabic letters
        normalized = normalizeArabicLetters(normalized)
        
        return normalized
    }
    
    /// Remove Arabic diacritics (harakat/tashkeel)
    private static func removeDiacritics(_ text: String) -> String {
        // Arabic diacritics Unicode range: U+064B to U+065F
        let diacritics: [Character] = [
            "\u{064B}", // Fathatan
            "\u{064C}", // Dammatan
            "\u{064D}", // Kasratan
            "\u{064E}", // Fatha
            "\u{064F}", // Damma
            "\u{0650}", // Kasra
            "\u{0651}", // Shadda
            "\u{0652}", // Sukun
            "\u{0653}", // Maddah
            "\u{0654}", // Hamza above
            "\u{0655}", // Hamza below
            "\u{0656}", // Subscript alef
            "\u{0657}", // Inverted damma
            "\u{0658}", // Mark noon ghunna
            "\u{0659}", // Zwarakay
            "\u{065A}", // Vowel sign small v above
            "\u{065B}", // Vowel sign inverted small v above
            "\u{065C}", // Vowel sign dot below
            "\u{065D}", // Reversed damma
            "\u{065E}", // Fatha with two dots
            "\u{065F}", // Wavy hamza below
            "\u{0670}"  // Superscript alef
        ]
        
        var result = text
        for diacritic in diacritics {
            result = result.replacingOccurrences(of: String(diacritic), with: "")
        }
        return result
    }
    
    /// Remove tatweel (kashida) - Arabic elongation character
    private static func removeTatweel(_ text: String) -> String {
        return text.replacingOccurrences(of: "\u{0640}", with: "")
    }
    
    /// Normalize Arabic letter variations
    private static func normalizeArabicLetters(_ text: String) -> String {
        var normalized = text
        
        // Normalize Alef variations to standard Alef
        let alefVariations: [(String, String)] = [
            ("\u{0622}", "\u{0627}"), // Alef with madda above → Alef
            ("\u{0623}", "\u{0627}"), // Alef with hamza above → Alef
            ("\u{0625}", "\u{0627}"), // Alef with hamza below → Alef
            ("\u{0671}", "\u{0627}")  // Alef wasla → Alef
        ]
        
        for (variant, standard) in alefVariations {
            normalized = normalized.replacingOccurrences(of: variant, with: standard)
        }
        
        // Normalize Teh Marbuta to Heh
        normalized = normalized.replacingOccurrences(of: "\u{0629}", with: "\u{0647}")
        
        return normalized
    }
    
    // MARK: - Number Normalization
    
    /// Normalize Franco-Arabic numbers to Arabic or Latin consistently
    static func normalizeNumbers(_ text: String, toArabic: Bool = true) -> String {
        if toArabic {
            return convertToArabicNumbers(text)
        } else {
            return convertToLatinNumbers(text)
        }
    }
    
    /// Convert all numbers to Arabic-Indic numerals (٠-٩)
    private static func convertToArabicNumbers(_ text: String) -> String {
        let latinToArabic: [Character: Character] = [
            "0": "٠", "1": "١", "2": "٢", "3": "٣", "4": "٤",
            "5": "٥", "6": "٦", "7": "٧", "8": "٨", "9": "٩"
        ]
        
        var result = ""
        for char in text {
            if let arabicDigit = latinToArabic[char] {
                result.append(arabicDigit)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    /// Convert all numbers to Latin numerals (0-9)
    private static func convertToLatinNumbers(_ text: String) -> String {
        let arabicToLatin: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
        ]
        
        // Also handle Eastern Arabic-Indic (Persian/Urdu) numerals
        let easternArabicToLatin: [Character: Character] = [
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"
        ]
        
        var result = ""
        for char in text {
            if let latinDigit = arabicToLatin[char] {
                result.append(latinDigit)
            } else if let latinDigit = easternArabicToLatin[char] {
                result.append(latinDigit)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    // MARK: - Full Normalization
    
    /// Normalize text with all transformations
    static func normalize(_ text: String, numbersToArabic: Bool = false) -> String {
        var normalized = text
        
        // Normalize Arabic text
        normalized = normalizeArabic(normalized)
        
        // Normalize numbers
        normalized = normalizeNumbers(normalized, toArabic: numbersToArabic)
        
        // Trim whitespace
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Normalize multiple spaces to single space
        normalized = normalized.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        return normalized
    }
    
    // MARK: - Language Detection Helpers
    
    /// Check if text contains Arabic characters
    static func containsArabic(_ text: String) -> Bool {
        let arabicRange = "\u{0600}"..."\u{06FF}"
        return text.unicodeScalars.contains { arabicRange.contains(String($0)) }
    }
    
    /// Check if text contains English characters
    static func containsEnglish(_ text: String) -> Bool {
        let englishRange = "a"..."z"
        let uppercaseRange = "A"..."Z"
        return text.unicodeScalars.contains {
            let char = String($0).lowercased()
            return englishRange.contains(char) || uppercaseRange.contains(String($0))
        }
    }
    
    /// Detect languages in text
    static func detectLanguages(_ text: String) -> [String] {
        var languages: [String] = []
        
        if containsArabic(text) {
            languages.append("ar")
        }
        
        if containsEnglish(text) {
            languages.append("en")
        }
        
        return languages
    }
}
