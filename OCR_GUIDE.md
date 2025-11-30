# OCR Service Implementation Guide

## Overview

The OCR Service provides comprehensive text recognition for Arabic and English text using Apple's Vision framework with advanced text normalization capabilities.

## Features

✅ **Vision Framework Integration**
- Uses `VNRecognizeTextRequest` with `.accurate` recognition level
- Supports Arabic (`ar`) and English (`en`) languages
- Language correction enabled

✅ **Arabic Text Normalization**
- Removes diacritics (harakat/tashkeel)
- Removes tatweel (kashida/elongation)
- Normalizes Alef variations
- Normalizes Teh Marbuta to Heh

✅ **Number Normalization**
- Converts between Arabic-Indic (٠-٩) and Latin (0-9) numerals
- Supports Eastern Arabic-Indic (Persian/Urdu) numerals (۰-۹)
- Consistent number format across text

✅ **Advanced Features**
- Bounding box detection for each text region
- Per-region confidence scores
- Overall confidence calculation
- Language detection
- Batch processing support

## Components

### 1. OCRResult

**Location**: `Mayyiz/Sources/OCR/OCRResult.swift`

```swift
struct OCRResult: Equatable, Codable {
    let text: String                    // Normalized recognized text
    let boxes: [CGRect]                 // Bounding boxes (normalized 0-1)
    let confidence: Double              // Overall confidence (0.0-1.0)
    let regionConfidences: [Double]     // Per-region confidence
    let detectedLanguages: [String]     // Detected language codes
}
```

**Methods**:
```swift
// Check confidence threshold
result.meetsConfidenceThreshold(0.8)

// Get text regions with boxes
let regions = result.textRegions
// Returns: [(text: String, box: CGRect, confidence: Double)]
```

### 2. OCRService

**Location**: `Mayyiz/Sources/OCR/OCRService.swift`

Main service class for performing OCR.

**Initialization**:
```swift
let ocrService = OCRService(
    recognitionLevel: .accurate,        // .fast or .accurate
    languages: ["ar", "en"],            // Supported languages
    normalizeNumbers: true,             // Enable number normalization
    numbersToArabic: false              // false = Latin, true = Arabic-Indic
)
```

**Methods**:
```swift
// Recognize text in UIImage
let result = try await ocrService.recognizeText(in: image)

// Recognize text in CGImage
let result = try await ocrService.recognizeText(in: cgImage)

// Recognize text in Data
let result = try await ocrService.recognizeText(in: imageData)

// Batch processing
let results = try await ocrService.recognizeText(in: images)
```

### 3. TextNormalizer

**Location**: `Mayyiz/Sources/OCR/TextNormalizer.swift`

Utility for text normalization.

**Methods**:
```swift
// Normalize Arabic text (remove diacritics, tatweel, etc.)
let normalized = TextNormalizer.normalizeArabic(text)

// Normalize numbers
let latinNumbers = TextNormalizer.normalizeNumbers(text, toArabic: false)
let arabicNumbers = TextNormalizer.normalizeNumbers(text, toArabic: true)

// Full normalization
let normalized = TextNormalizer.normalize(text, numbersToArabic: false)

// Language detection
let hasArabic = TextNormalizer.containsArabic(text)
let hasEnglish = TextNormalizer.containsEnglish(text)
let languages = TextNormalizer.detectLanguages(text)
```

## Usage Examples

### Example 1: Basic OCR

```swift
import UIKit

@MainActor
func performOCR(on image: UIImage) async {
    let ocrService = OCRService()
    
    do {
        let result = try await ocrService.recognizeText(in: image)
        
        print("Recognized text: \(result.text)")
        print("Confidence: \(result.confidence)")
        print("Languages: \(result.detectedLanguages)")
        
    } catch {
        print("OCR failed: \(error)")
    }
}
```

### Example 2: OCR with Confidence Threshold

```swift
@MainActor
func performOCRWithThreshold(on image: UIImage) async {
    let ocrService = OCRService()
    let minimumConfidence = 0.7
    
    do {
        let result = try await ocrService.recognizeText(in: image)
        
        if result.meetsConfidenceThreshold(minimumConfidence) {
            print("High confidence result: \(result.text)")
        } else {
            print("Low confidence (\(result.confidence)): \(result.text)")
            print("Please try with a clearer image")
        }
        
    } catch {
        print("OCR failed: \(error)")
    }
}
```

### Example 3: Process Multiple Images

```swift
@MainActor
func processMultipleImages(_ images: [UIImage]) async {
    let ocrService = OCRService()
    
    do {
        let results = try await ocrService.recognizeText(in: images)
        
        for (index, result) in results.enumerated() {
            print("Image \(index + 1):")
            print("  Text: \(result.text)")
            print("  Confidence: \(result.confidence)")
            print("  Languages: \(result.detectedLanguages)")
        }
        
    } catch {
        print("Batch OCR failed: \(error)")
    }
}
```

### Example 4: Extract Text Regions with Bounding Boxes

```swift
@MainActor
func extractTextRegions(from image: UIImage) async {
    let ocrService = OCRService()
    
    do {
        let result = try await ocrService.recognizeText(in: image)
        
        for region in result.textRegions {
            print("Text: \(region.text)")
            print("Box: \(region.box)")
            print("Confidence: \(region.confidence)")
            print("---")
        }
        
    } catch {
        print("OCR failed: \(error)")
    }
}
```

### Example 5: Arabic Text with Number Normalization

```swift
@MainActor
func processArabicText(image: UIImage) async {
    // Configure for Arabic with Latin numbers
    let ocrService = OCRService(
        recognitionLevel: .accurate,
        languages: ["ar", "en"],
        normalizeNumbers: true,
        numbersToArabic: false  // Convert to Latin numbers
    )
    
    do {
        let result = try await ocrService.recognizeText(in: image)
        
        print("Normalized text: \(result.text)")
        // Arabic text will be normalized (no diacritics, no tatweel)
        // Numbers will be in Latin format (0-9)
        
    } catch {
        print("OCR failed: \(error)")
    }
}
```

### Example 6: Integration with AnalysisService

```swift
@MainActor
class AnalysisService {
    private let ocrService = OCRService()
    
    func analyzeImage(_ image: UIImage) async throws -> AnalysisResult {
        // Perform OCR
        let ocrResult = try await ocrService.recognizeText(in: image)
        
        // Build findings
        var findings: [String] = []
        
        if !ocrResult.text.isEmpty {
            findings.append("Text detected: \(ocrResult.text.prefix(50))...")
        }
        
        if ocrResult.detectedLanguages.contains("ar") {
            findings.append("Arabic text detected")
        }
        
        if ocrResult.detectedLanguages.contains("en") {
            findings.append("English text detected")
        }
        
        findings.append("Text regions: \(ocrResult.boxes.count)")
        
        // Create analysis result
        return AnalysisResult(
            shareId: UUID().uuidString,
            findings: findings,
            confidence: ocrResult.confidence,
            metadata: [
                "textLength": "\(ocrResult.text.count)",
                "regions": "\(ocrResult.boxes.count)",
                "languages": ocrResult.detectedLanguages.joined(separator: ", ")
            ]
        )
    }
}
```

## Text Normalization Examples

### Arabic Diacritics Removal

```swift
let textWithDiacritics = "مَرْحَبًا بِكُمْ"
let normalized = TextNormalizer.normalizeArabic(textWithDiacritics)
// Result: "مرحبا بكم"
```

### Tatweel Removal

```swift
let textWithTatweel = "الـــــسلام عليـــكم"
let normalized = TextNormalizer.normalizeArabic(textWithTatweel)
// Result: "السلام عليكم"
```

### Alef Normalization

```swift
let text = "أحمد إبراهيم آمال"
let normalized = TextNormalizer.normalizeArabic(text)
// Result: "احمد ابراهيم امال"
```

### Number Conversion

```swift
// Arabic to Latin
let arabicNumbers = "الرقم ١٢٣٤٥"
let latin = TextNormalizer.normalizeNumbers(arabicNumbers, toArabic: false)
// Result: "الرقم 12345"

// Latin to Arabic
let latinNumbers = "الرقم 12345"
let arabic = TextNormalizer.normalizeNumbers(latinNumbers, toArabic: true)
// Result: "الرقم ١٢٣٤٥"
```

## Error Handling

```swift
do {
    let result = try await ocrService.recognizeText(in: image)
    // Process result
    
} catch OCRError.invalidImage {
    print("Invalid image format")
    
} catch OCRError.noTextFound {
    print("No text found in image")
    
} catch OCRError.recognitionFailed(let error) {
    print("Recognition failed: \(error)")
    
} catch {
    print("Unexpected error: \(error)")
}
```

## Testing

### Run Unit Tests

```bash
# Run all OCR tests
⌘ + U

# Or from command line
xcodebuild test -scheme Mayyiz -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

**TextNormalizerTests** (25+ tests):
- ✅ Diacritics removal
- ✅ Tatweel removal
- ✅ Alef normalization
- ✅ Number conversion (Arabic ↔ Latin)
- ✅ Language detection
- ✅ Edge cases

**OCRServiceTests** (20+ tests):
- ✅ English text recognition
- ✅ Arabic text recognition
- ✅ Mixed language recognition
- ✅ Number normalization
- ✅ Confidence thresholds
- ✅ Bounding boxes
- ✅ Batch processing
- ✅ Error handling

## Performance Considerations

### Recognition Level

```swift
// Fast - Lower accuracy, faster processing
let fastOCR = OCRService(recognitionLevel: .fast)

// Accurate - Higher accuracy, slower processing (recommended)
let accurateOCR = OCRService(recognitionLevel: .accurate)
```

### Batch Processing

```swift
// Process images sequentially
let results = try await ocrService.recognizeText(in: images)

// For large batches, consider processing in chunks
let chunkSize = 10
for chunk in images.chunked(into: chunkSize) {
    let results = try await ocrService.recognizeText(in: chunk)
    // Process results
}
```

### Image Preprocessing

For better OCR results:
- Use high-resolution images
- Ensure good contrast
- Avoid skewed or rotated text
- Remove noise/artifacts
- Ensure adequate lighting

## Integration with AppState

```swift
// In AnalysisService
func analyze(content: SharedContent) async throws -> AnalysisResult {
    var findings: [String] = []
    var confidence = 0.0
    
    // Process images with OCR
    if !content.imagePaths.isEmpty {
        let ocrService = OCRService()
        
        for imagePath in content.imagePaths {
            let data = try SharedContainer.readData(from: imagePath)
            let ocrResult = try await ocrService.recognizeText(in: data)
            
            if !ocrResult.text.isEmpty {
                findings.append("OCR: \(ocrResult.text)")
                confidence = max(confidence, ocrResult.confidence)
            }
        }
    }
    
    return AnalysisResult(
        shareId: content.id,
        findings: findings,
        confidence: confidence
    )
}
```

## Best Practices

### 1. Always Use Async/Await

```swift
// ✅ Good
Task {
    let result = try await ocrService.recognizeText(in: image)
}

// ❌ Bad - blocking main thread
let result = try ocrService.recognizeText(in: image) // Won't compile
```

### 2. Handle Errors Gracefully

```swift
// ✅ Good
do {
    let result = try await ocrService.recognizeText(in: image)
    if result.meetsConfidenceThreshold(0.7) {
        // Use result
    } else {
        // Show warning about low confidence
    }
} catch {
    // Show error to user
}
```

### 3. Validate Confidence

```swift
// ✅ Good
if result.confidence > 0.8 {
    // High confidence - use result
} else if result.confidence > 0.5 {
    // Medium confidence - show warning
} else {
    // Low confidence - ask user to retry
}
```

### 4. Use Appropriate Number Format

```swift
// For Arabic documents
let ocrService = OCRService(numbersToArabic: true)

// For English/mixed documents
let ocrService = OCRService(numbersToArabic: false)
```

## Troubleshooting

### Issue: No Text Recognized

**Solutions**:
- Check image quality
- Ensure text is clear and readable
- Try with `.accurate` recognition level
- Verify correct languages are specified

### Issue: Low Confidence

**Solutions**:
- Use higher resolution images
- Improve image contrast
- Remove noise/artifacts
- Ensure text is not skewed

### Issue: Incorrect Language Detection

**Solutions**:
- Specify exact languages needed
- Use TextNormalizer to verify language content
- Check that fonts support the language

### Issue: Numbers Not Normalized

**Solutions**:
- Ensure `normalizeNumbers: true`
- Verify `numbersToArabic` setting
- Check TextNormalizer directly

## Summary

The OCR Service provides:

✅ **Accurate text recognition** with Vision framework  
✅ **Arabic & English support** with language detection  
✅ **Advanced normalization** (diacritics, tatweel, numbers)  
✅ **Bounding box detection** for text regions  
✅ **Confidence scoring** for quality assessment  
✅ **Batch processing** for multiple images  
✅ **Comprehensive testing** with 45+ unit tests  
✅ **Production-ready** error handling  

Ready to integrate into your analysis pipeline! 🚀
