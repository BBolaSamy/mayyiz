# Heuristics Service Implementation Guide

## Overview

The Heuristics Service provides preliminary risk assessment for phishing and scam detection through pattern matching, URL analysis, and content heuristics. It analyzes text and URLs to identify suspicious patterns without requiring external API calls.

## Features

✅ **URL Analysis**
- Extract URLs from text
- Detect shortlink services (bit.ly, tinyurl, etc.)
- Identify risky top-level domains (.tk, .xyz, etc.)
- Detect homoglyph domains (look-alike characters)
- Flag IP addresses and unusual ports
- Check for HTTPS usage

✅ **Arabic Pattern Detection**
- Urgency phrases (عاجل, فوري, سريع)
- Penalty threats (غرامة, إيقاف, إغلاق)
- OTP/code requests (رمز التحقق, كود)
- Bank impersonation (بنك الراجحي, حساب بنكي)

✅ **English Pattern Detection**
- Urgency language (urgent, act now, limited time)
- Penalty threats (suspended, blocked, fine)
- OTP requests (verification code, OTP)
- Password requests
- Account suspension threats

✅ **Risk Assessment**
- Preliminary risk score (0-100)
- Red flag categorization
- Severity-based scoring
- Risk level classification

✅ **Channel Detection**
- SMS/Text message
- Email
- WhatsApp
- Social media
- Unknown

## Components

### 1. RedFlag Enum

**Location**: `Mayyiz/Sources/Heuristics/HeuristicsResult.swift`

```swift
enum RedFlag: String, Codable {
    // URL-based
    case shortlink
    case homoglyphDomain
    case riskyTLD
    case ipAddress
    case excessiveSubdomains
    case noHTTPS
    
    // Content-based
    case urgencyPhrase
    case penaltyThreat
    case otpRequest
    case bankImpersonation
    case passwordRequest
    case accountSuspension
    
    // Arabic-specific
    case arabicUrgency
    case arabicPenalty
    case arabicOTP
    case arabicBankImpersonation
}
```

**Severity Levels**:
- **30 points**: Homoglyph, bank impersonation, OTP/password requests
- **20 points**: Risky TLD, urgency, penalty threats
- **15 points**: Shortlinks, suspicious URLs
- **10 points**: IP address, excessive subdomains
- **5 points**: Unusual port

### 2. HeuristicsResult

**Location**: `Mayyiz/Sources/Heuristics/HeuristicsResult.swift`

```swift
struct HeuristicsResult: Codable {
    let riskScore: Int              // 0-100
    let redFlags: [RedFlag]
    let channel: CommunicationChannel
    let extractedURLs: [String]
    let shortlinks: [String]
    let homoglyphDomains: [String]
    let metadata: [String: String]
}
```

**Properties**:
```swift
result.riskLevel        // "Low", "Medium", "High", "Critical"
result.isHighRisk       // true if riskScore >= 50
```

### 3. HeuristicsService

**Location**: `Mayyiz/Sources/Heuristics/HeuristicsService.swift`

Main service class for heuristics analysis.

**Usage**:
```swift
let service = HeuristicsService()
let result = service.analyze(text: message, url: optionalURL)
```

## Usage Examples

### Example 1: Basic Analysis

```swift
let service = HeuristicsService()

let text = """
عاجل من بنك الراجحي
يرجى تحديث بياناتك على الرابط:
https://bit.ly/update
"""

let result = service.analyze(text: text)

print("Risk Score: \(result.riskScore)")
print("Risk Level: \(result.riskLevel)")
print("Red Flags: \(result.redFlags.count)")
print("Channel: \(result.channel.description)")

if result.isHighRisk {
    print("⚠️ HIGH RISK DETECTED!")
}
```

### Example 2: Check Specific Red Flags

```swift
let result = service.analyze(text: message)

// Check for specific threats
if result.redFlags.contains(.arabicBankImpersonation) {
    print("🏦 Bank impersonation detected")
}

if result.redFlags.contains(.shortlink) {
    print("🔗 Shortlink detected: \(result.shortlinks)")
}

if result.redFlags.contains(.arabicOTP) {
    print("🔐 OTP request detected")
}
```

### Example 3: Display Red Flags to User

```swift
let result = service.analyze(text: message)

print("Security Analysis:")
print("Risk Level: \(result.riskLevel) (\(result.riskScore)/100)")
print("\nDetected Issues:")

for flag in result.redFlags {
    print("• \(flag.description) [Severity: \(flag.severity)]")
}

if !result.shortlinks.isEmpty {
    print("\nShortlinks found:")
    for link in result.shortlinks {
        print("  - \(link)")
    }
}
```

### Example 4: Integration with Analysis Pipeline

```swift
class AnalysisService {
    private let heuristicsService = HeuristicsService()
    private let ocrService = OCRService()
    
    func analyze(content: SharedContent) async throws -> AnalysisResult {
        var findings: [String] = []
        var totalConfidence = 0.0
        var metadata: [String: String] = [:]
        
        // Analyze text content
        if let text = content.text {
            let heuristics = heuristicsService.analyze(text: text)
            
            findings.append("Risk Score: \(heuristics.riskScore)/100")
            findings.append("Risk Level: \(heuristics.riskLevel)")
            
            for flag in heuristics.redFlags {
                findings.append("⚠️ \(flag.description)")
            }
            
            metadata["riskScore"] = "\(heuristics.riskScore)"
            metadata["flagCount"] = "\(heuristics.redFlags.count)"
            metadata["channel"] = heuristics.channel.rawValue
            
            // Risk score affects confidence (inverse relationship)
            totalConfidence = 1.0 - (Double(heuristics.riskScore) / 100.0)
        }
        
        // Analyze images with OCR
        for imagePath in content.imagePaths {
            let data = try SharedContainer.readData(from: imagePath)
            let ocrResult = try await ocrService.recognizeText(in: data)
            
            if !ocrResult.text.isEmpty {
                // Analyze OCR text with heuristics
                let heuristics = heuristicsService.analyze(text: ocrResult.text)
                
                findings.append("OCR Text: \(ocrResult.text)")
                findings.append("OCR Risk: \(heuristics.riskScore)/100")
                
                for flag in heuristics.redFlags {
                    findings.append("⚠️ \(flag.description)")
                }
                
                totalConfidence = max(totalConfidence, ocrResult.confidence)
            }
        }
        
        return AnalysisResult(
            shareId: content.id,
            findings: findings,
            confidence: totalConfidence,
            metadata: metadata
        )
    }
}
```

### Example 5: URL-Only Analysis

```swift
let service = HeuristicsService()

let url = "https://bit.ly/bank-verify"
let result = service.analyze(text: "", url: url)

if result.redFlags.contains(.shortlink) {
    print("⚠️ Shortlink detected - URL may be hiding destination")
}
```

## Pattern Detection

### Shortlink Domains

Detects 50+ shortlink services including:
- bit.ly, tinyurl.com, goo.gl
- t.co, ow.ly, buff.ly
- is.gd, v.gd, tr.im
- And many more...

### Risky TLDs

Flags suspicious top-level domains:
- Free TLDs: .tk, .ml, .ga, .cf, .gq
- Suspicious: .xyz, .top, .club, .work
- Scam-prone: .loan, .win, .bid, .racing
- And more...

### Arabic Urgency Phrases

```
عاجل - Urgent
فوري - Immediate
سريع - Quick
الآن - Now
حالا - Right now
آخر فرصة - Last chance
ينتهي اليوم - Ends today
لفترة محدودة - Limited time
```

### Arabic Penalty Phrases

```
سيتم إيقاف - Will be suspended
سيتم إغلاق - Will be closed
غرامة - Fine
عقوبة - Penalty
إجراء قانوني - Legal action
تحذير نهائي - Final warning
```

### Arabic OTP Phrases

```
رمز التحقق - Verification code
كود التفعيل - Activation code
الرمز السري - Secret code
كلمة المرور - Password
رمز الأمان - Security code
```

### Arabic Bank Phrases

```
بنك الراجحي - Al Rajhi Bank
البنك الأهلي - Al Ahli Bank
حسابك البنكي - Your bank account
بطاقتك الائتمانية - Your credit card
التحويل البنكي - Bank transfer
```

## Risk Scoring

### Risk Levels

```
0-19:   Low Risk      ✅
20-49:  Medium Risk   ⚠️
50-79:  High Risk     🚨
80-100: Critical Risk ⛔
```

### Score Calculation

Risk score = Sum of all red flag severities (capped at 100)

Example:
```
Shortlink (15) + 
Arabic Urgency (20) + 
Arabic Bank Impersonation (30) + 
Arabic OTP (15) = 80 (Critical)
```

## Channel Detection

### Detection Logic

**SMS**:
- Short text (< 160 characters)
- No complex formatting
- No line breaks

**Email**:
- Contains @ symbol
- Contains "email" keyword
- Contains بريد (Arabic for email)

**WhatsApp**:
- Contains "whatsapp" or "واتساب"

**Social Media**:
- URLs contain facebook, twitter, instagram, tiktok

**Unknown**:
- Doesn't match other patterns

## Homoglyph Detection

Detects look-alike characters from different scripts:

```
Latin 'a' vs Cyrillic 'а'
Latin 'e' vs Cyrillic 'е'
Latin 'o' vs Cyrillic 'о' vs Greek 'ο'
Latin 'p' vs Cyrillic 'р'
Latin 'c' vs Cyrillic 'с'
```

Example:
```
google.com (legitimate)
gооgle.com (Cyrillic о - phishing!)
```

## Testing

### Run Unit Tests

```bash
# Run all heuristics tests
⌘ + U

# Or from command line
xcodebuild test -scheme Mayyiz \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MayyizTests/HeuristicsServiceTests
```

### Test Coverage

**HeuristicsServiceTests** (50+ tests):
- ✅ URL extraction
- ✅ Shortlink detection
- ✅ Risky TLD detection
- ✅ Homoglyph detection
- ✅ IP address detection
- ✅ HTTPS checking
- ✅ Arabic urgency patterns
- ✅ Arabic penalty patterns
- ✅ Arabic OTP patterns
- ✅ Arabic bank impersonation
- ✅ English patterns
- ✅ Mixed language detection
- ✅ Risk score calculation
- ✅ Channel detection
- ✅ Real-world phishing examples
- ✅ Edge cases

## Real-World Examples

### Example 1: Arabic Bank Phishing

```swift
let text = """
عاجل من بنك الراجحي
تم إيقاف حسابك مؤقتاً
للتفعيل أدخل رمز التحقق على الرابط:
https://bit.ly/alrajhi-verify
"""

let result = service.analyze(text: text)
// Risk Score: 80+ (Critical)
// Flags: arabicUrgency, arabicBankImpersonation, arabicOTP, shortlink
```

### Example 2: English Account Suspension

```swift
let text = """
URGENT: Your account will be suspended in 24 hours!
Verify your identity now: http://verify-account.tk
Enter your password and OTP code.
"""

let result = service.analyze(text: text)
// Risk Score: 75+ (High)
// Flags: urgencyPhrase, accountSuspension, riskyTLD, passwordRequest, otpRequest, noHTTPS
```

### Example 3: Legitimate Message

```swift
let text = """
Hello,
Thank you for your purchase.
Your order will arrive in 3-5 business days.
Track your order at https://amazon.com/orders
"""

let result = service.analyze(text: text)
// Risk Score: 0-10 (Low)
// Flags: None or minimal
```

## Best Practices

### 1. Combine with Other Analysis

```swift
// ✅ Good - Use heuristics as part of comprehensive analysis
let heuristics = heuristicsService.analyze(text: text)
let ocr = try await ocrService.recognizeText(in: image)
let ai = try await aiService.analyze(text: ocr.text)

let finalRisk = max(heuristics.riskScore, aiRiskScore)
```

### 2. Don't Rely Solely on Heuristics

```swift
// ⚠️ Heuristics are preliminary - use for initial screening
if heuristics.riskScore > 50 {
    // Trigger deeper analysis
    let aiAnalysis = try await performDeepAnalysis()
}
```

### 3. Explain Flags to Users

```swift
// ✅ Good - Show why something is flagged
for flag in result.redFlags {
    showWarning(flag.description)
}

// ❌ Bad - Just show risk score
showRiskScore(result.riskScore)
```

### 4. Update Patterns Regularly

```swift
// Keep patterns updated with new threats
// Consider loading patterns from remote config
```

## Limitations

### What Heuristics CAN Do

✅ Quick preliminary assessment  
✅ Pattern-based detection  
✅ No external API calls needed  
✅ Works offline  
✅ Fast execution  

### What Heuristics CANNOT Do

❌ Verify actual URL destinations  
❌ Detect sophisticated attacks  
❌ Understand context  
❌ Adapt to new patterns automatically  
❌ Replace AI/ML analysis  

## Integration Points

### With OCR Service

```swift
// Analyze OCR text for phishing patterns
let ocrResult = try await ocrService.recognizeText(in: image)
let heuristics = heuristicsService.analyze(text: ocrResult.text)
```

### With AI Service

```swift
// Use heuristics for initial screening
let heuristics = heuristicsService.analyze(text: text)

if heuristics.riskScore > 30 {
    // High enough risk - send to AI for deeper analysis
    let aiResult = try await aiService.analyze(text: text)
}
```

### With AppState

```swift
// In AnalysisService
func analyze(content: SharedContent) async throws -> AnalysisResult {
    let heuristics = heuristicsService.analyze(
        text: content.text ?? "",
        url: content.url
    )
    
    return AnalysisResult(
        shareId: content.id,
        findings: heuristics.redFlags.map { $0.description },
        confidence: 1.0 - (Double(heuristics.riskScore) / 100.0)
    )
}
```

## Summary

The Heuristics Service provides:

✅ **Fast preliminary risk assessment** (0-100 score)  
✅ **URL analysis** (shortlinks, risky TLDs, homoglyphs)  
✅ **Arabic pattern detection** (urgency, penalties, OTP, banks)  
✅ **English pattern detection** (urgency, threats, credentials)  
✅ **Channel detection** (SMS, email, WhatsApp, social)  
✅ **50+ unit tests** with real-world examples  
✅ **No external dependencies** - works offline  
✅ **Production-ready** error handling  

Perfect for initial screening before deeper AI analysis! 🚀
