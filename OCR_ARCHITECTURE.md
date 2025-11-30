# OCR Service Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      OCR Service                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ OCRService   │  │TextNormalizer│  │  OCRResult   │    │
│  │              │  │              │  │              │    │
│  │ • Vision API │  │ • Arabic     │  │ • Text       │    │
│  │ • Accurate   │  │ • Numbers    │  │ • Boxes      │    │
│  │ • AR/EN      │  │ • Languages  │  │ • Confidence │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## OCR Processing Flow

```
Input Image
    │
    ▼
┌─────────────────────────┐
│  VNRecognizeTextRequest │
│                         │
│  • recognitionLevel:    │
│    .accurate            │
│  • languages:           │
│    ["ar", "en"]         │
│  • usesLanguageCorrection│
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Vision Framework       │
│  Processing             │
│                         │
│  • Text detection       │
│  • Character recognition│
│  • Bounding boxes       │
│  • Confidence scores    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Raw Observations       │
│                         │
│  [VNRecognizedText      │
│   Observation]          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Text Normalization     │
│                         │
│  • Remove diacritics    │
│  • Remove tatweel       │
│  • Normalize letters    │
│  • Normalize numbers    │
│  • Detect languages     │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  OCRResult              │
│                         │
│  • text: String         │
│  • boxes: [CGRect]      │
│  • confidence: Double   │
│  • languages: [String]  │
└─────────────────────────┘
```

## Text Normalization Pipeline

```
Input: "مَرْحَبًـــا ١٢٣"
    │
    ▼
┌─────────────────────────┐
│  Remove Diacritics      │
│  مَرْحَبًا → مرحبا      │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Remove Tatweel         │
│  مرحبـــا → مرحبا       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Normalize Letters      │
│  أ إ آ → ا              │
│  ة → ه                  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Normalize Numbers      │
│  ١٢٣ → 123              │
│  (or 123 → ١٢٣)         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Trim & Clean           │
│  • Remove extra spaces  │
│  • Trim whitespace      │
└────────┬────────────────┘
         │
         ▼
Output: "مرحبا 123"
```

## Number Normalization

```
┌─────────────────────────────────────────────────┐
│           Number Normalization                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  Latin (0-9)                                   │
│      ↕                                          │
│  Arabic-Indic (٠-٩)                            │
│      ↕                                          │
│  Eastern Arabic (۰-۹)                          │
│                                                 │
│  All normalize to chosen format:               │
│  • toArabic: false → 0-9                       │
│  • toArabic: true  → ٠-٩                       │
│                                                 │
└─────────────────────────────────────────────────┘

Examples:
  Input: "123 ١٢٣ ۱۲۳"
  
  toArabic: false → "123 123 123"
  toArabic: true  → "١٢٣ ١٢٣ ١٢٣"
```

## Arabic Diacritics

```
┌─────────────────────────────────────────────────┐
│         Arabic Diacritics (Removed)             │
├─────────────────────────────────────────────────┤
│                                                 │
│  Fathatan  (ً)  U+064B                         │
│  Dammatan  (ٌ)  U+064C                         │
│  Kasratan  (ٍ)  U+064D                         │
│  Fatha     (َ)  U+064E                         │
│  Damma     (ُ)  U+064F                         │
│  Kasra     (ِ)  U+0650                         │
│  Shadda    (ّ)  U+0651                         │
│  Sukun     (ْ)  U+0652                         │
│  Tatweel   (ـ)  U+0640                         │
│  ... and more                                   │
│                                                 │
│  Example:                                       │
│  مَرْحَبًا → مرحبا                              │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Letter Normalization

```
┌─────────────────────────────────────────────────┐
│         Arabic Letter Normalization             │
├─────────────────────────────────────────────────┤
│                                                 │
│  Alef Variations → Standard Alef (ا)           │
│  ┌──────────────────────────────────┐          │
│  │ أ  Alef with hamza above         │          │
│  │ إ  Alef with hamza below         │          │
│  │ آ  Alef with madda above         │          │
│  │ ٱ  Alef wasla                    │          │
│  └──────────────────────────────────┘          │
│                    ↓                            │
│                   ا                             │
│                                                 │
│  Teh Marbuta (ة) → Heh (ه)                     │
│                                                 │
│  Example:                                       │
│  أحمد إبراهيم آمال → احمد ابراهيم امال         │
│  مدرسة → مدرسه                                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Language Detection

```
┌─────────────────────────────────────────────────┐
│           Language Detection                    │
├─────────────────────────────────────────────────┤
│                                                 │
│  Arabic Detection                               │
│  ┌──────────────────────────────────┐          │
│  │ Unicode Range: U+0600 - U+06FF   │          │
│  │ Includes: Arabic letters         │          │
│  └──────────────────────────────────┘          │
│                                                 │
│  English Detection                              │
│  ┌──────────────────────────────────┐          │
│  │ Range: a-z, A-Z                  │          │
│  │ Includes: Latin letters          │          │
│  └──────────────────────────────────┘          │
│                                                 │
│  Mixed Text Example:                            │
│  "Hello مرحبا 123"                              │
│  → Languages: ["en", "ar"]                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Bounding Boxes

```
┌─────────────────────────────────────────────────┐
│              Bounding Boxes                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  Image (normalized coordinates 0.0 - 1.0)       │
│  ┌─────────────────────────────────────┐       │
│  │                                     │       │
│  │  ┌──────────┐                       │       │
│  │  │ Text 1   │ ← Box 1               │       │
│  │  └──────────┘                       │       │
│  │                                     │       │
│  │         ┌──────────┐                │       │
│  │         │ Text 2   │ ← Box 2        │       │
│  │         └──────────┘                │       │
│  │                                     │       │
│  │  ┌──────────┐                       │       │
│  │  │ Text 3   │ ← Box 3               │       │
│  │  └──────────┘                       │       │
│  │                                     │       │
│  └─────────────────────────────────────┘       │
│                                                 │
│  Each box: CGRect(x, y, width, height)         │
│  Coordinates: 0.0 (bottom-left) to 1.0         │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Confidence Scoring

```
┌─────────────────────────────────────────────────┐
│            Confidence Scoring                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  Per-Region Confidence                          │
│  ┌──────────────────────────────────┐          │
│  │ Region 1: 0.95 (95%)             │          │
│  │ Region 2: 0.87 (87%)             │          │
│  │ Region 3: 0.92 (92%)             │          │
│  └──────────────────────────────────┘          │
│                    ↓                            │
│          Average Confidence                     │
│          (0.95 + 0.87 + 0.92) / 3              │
│                  = 0.91                         │
│                                                 │
│  Confidence Levels:                             │
│  ┌──────────────────────────────────┐          │
│  │ 0.8 - 1.0  High (Excellent)      │          │
│  │ 0.5 - 0.8  Medium (Good)         │          │
│  │ 0.0 - 0.5  Low (Poor)            │          │
│  └──────────────────────────────────┘          │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Integration with Analysis Pipeline

```
┌─────────────────────────────────────────────────┐
│         Analysis Pipeline Integration           │
├─────────────────────────────────────────────────┤
│                                                 │
│  SharedContent                                  │
│  ┌──────────────────────────────────┐          │
│  │ • id                             │          │
│  │ • imagePaths: [String]           │          │
│  └────────┬─────────────────────────┘          │
│           │                                     │
│           ▼                                     │
│  ┌──────────────────────────────────┐          │
│  │ Load images from SharedContainer │          │
│  └────────┬─────────────────────────┘          │
│           │                                     │
│           ▼                                     │
│  ┌──────────────────────────────────┐          │
│  │ OCRService.recognizeText()       │          │
│  └────────┬─────────────────────────┘          │
│           │                                     │
│           ▼                                     │
│  ┌──────────────────────────────────┐          │
│  │ OCRResult                        │          │
│  │ • text                           │          │
│  │ • confidence                     │          │
│  │ • boxes                          │          │
│  └────────┬─────────────────────────┘          │
│           │                                     │
│           ▼                                     │
│  ┌──────────────────────────────────┐          │
│  │ AnalysisResult                   │          │
│  │ • findings: ["OCR: ..."]         │          │
│  │ • confidence: 0.91               │          │
│  │ • metadata: {...}                │          │
│  └──────────────────────────────────┘          │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Testing Architecture

```
┌─────────────────────────────────────────────────┐
│              Testing Structure                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  TextNormalizerTests (25+ tests)                │
│  ┌──────────────────────────────────┐          │
│  │ • Diacritics removal             │          │
│  │ • Tatweel removal                │          │
│  │ • Letter normalization           │          │
│  │ • Number conversion              │          │
│  │ • Language detection             │          │
│  │ • Edge cases                     │          │
│  └──────────────────────────────────┘          │
│                                                 │
│  OCRServiceTests (20+ tests)                    │
│  ┌──────────────────────────────────┐          │
│  │ • English recognition            │          │
│  │ • Arabic recognition             │          │
│  │ • Mixed language                 │          │
│  │ • Number normalization           │          │
│  │ • Confidence thresholds          │          │
│  │ • Bounding boxes                 │          │
│  │ • Batch processing               │          │
│  │ • Error handling                 │          │
│  └──────────────────────────────────┘          │
│                                                 │
│  Total: 45+ Unit Tests                          │
│  Coverage: Comprehensive                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Performance Characteristics

```
┌─────────────────────────────────────────────────┐
│            Performance Profile                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  Recognition Speed                              │
│  ┌──────────────────────────────────┐          │
│  │ Fast Mode:    ~0.5-1s per image  │          │
│  │ Accurate:     ~1-2s per image    │          │
│  └──────────────────────────────────┘          │
│                                                 │
│  Memory Usage                                   │
│  ┌──────────────────────────────────┐          │
│  │ Efficient Vision framework       │          │
│  │ Automatic cleanup                │          │
│  │ Suitable for production          │          │
│  └──────────────────────────────────┘          │
│                                                 │
│  Accuracy                                       │
│  ┌──────────────────────────────────┐          │
│  │ Clear text:    90-95%            │          │
│  │ Good quality:  80-90%            │          │
│  │ Poor quality:  60-80%            │          │
│  └──────────────────────────────────┘          │
│                                                 │
└─────────────────────────────────────────────────┘
```
