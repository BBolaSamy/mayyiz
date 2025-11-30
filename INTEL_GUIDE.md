# Link Intelligence Client Guide

## Overview

The Link Intelligence Client (`LinkIntelClient`) provides threat intelligence for URLs using external services (VirusTotal and urlscan.io). It supports both passive lookups and active scanning, with built-in safeguards for user privacy and data sensitivity.

## Features

✅ **Passive Lookup (VirusTotal)**
- Checks existing reports without submitting new scans
- Fast and privacy-preserving
- Aggregates results from 70+ security vendors

✅ **Active Scan (urlscan.io)**
- Submits URL for real-time analysis
- Captures screenshots and DOM data
- Requires user opt-in
- Controlled by Remote Config

✅ **Unified Risk Scoring**
- Normalizes scores from different providers to a 0-100 scale
- Consistent verdict (Malicious, Suspicious, Harmless)

✅ **Safety & Privacy**
- **Sensitive URL Detection**: Automatically blocks URLs with PII (tokens, passwords, sessions)
- **Remote Config Control**: Feature flag to enable/disable active scanning globally
- **User Opt-in**: Explicit consent required for active scans

## Components

### 1. UrlIntelSummary

**Location**: `Mayyiz/Sources/Intel/UrlIntelModels.swift`

```swift
struct UrlIntelSummary {
    let riskScore: Int          // 0-100
    let verdict: IntelVerdict   // .malicious, .suspicious, .harmless
    let source: IntelSource     // .virusTotal, .urlScan
    let findings: [String]      // Human-readable findings
    let reportURL: String?      // Link to full report
}
```

### 2. LinkIntelClient

**Location**: `Mayyiz/Sources/Intel/LinkIntelClient.swift`

**Initialization**:
```swift
let client = LinkIntelClient()
// Uses DefaultRemoteConfig by default
```

## Usage Examples

### Example 1: Passive Lookup (Safe Default)

```swift
let client = LinkIntelClient()

do {
    let summary = try await client.intelLookup(url: "https://example.com")
    
    if summary.isHighRisk {
        print("⚠️ Risk detected: \(summary.riskScore)/100")
        print("Findings: \(summary.findings)")
    } else {
        print("✅ URL appears safe")
    }
} catch {
    print("Lookup failed: \(error)")
}
```

### Example 2: Active Scan (With Safeguards)

```swift
let client = LinkIntelClient()

// 1. Check if active scanning is allowed globally
if DefaultRemoteConfig.shared.allowActiveUrlScan {
    
    // 2. Ask user for permission
    let userOptIn = await askUserForPermission()
    
    if userOptIn {
        do {
            // 3. Perform scan
            let summary = try await client.intelScan(
                url: "https://suspicious-link.com", 
                userOptIn: true
            )
            print("Scan result: \(summary.verdict)")
            
        } catch IntelError.sensitiveURL {
            print("🚫 Scan blocked: URL contains sensitive data")
        } catch {
            print("Scan failed: \(error)")
        }
    }
}
```

## Configuration

### API Keys
The client expects API keys to be available via `RemoteConfigProvider`.
- `VT_API_KEY`: VirusTotal API Key
- `URLSCAN_API_KEY`: urlscan.io API Key

### Remote Config
The `allowActiveUrlScan` flag controls whether active scanning is permitted app-wide. This allows you to disable the feature remotely if issues arise.

## Risk Calculation

### VirusTotal
- **Malicious > 0**: Risk Score = 50 + (detections * 10) [Capped at 100]
- **Suspicious > 0**: Risk Score = 20 + (detections * 10) [Capped at 50]
- **Clean**: Risk Score = 0

### urlscan.io
- **Malicious Verdict**: Risk Score = 100
- **Otherwise**: Uses the raw score (0-100) provided by the API

## Testing

Run unit tests to verify safeguards:
```bash
xcodebuild test -scheme Mayyiz -only-testing:MayyizTests/LinkIntelClientTests
```

**Test Coverage**:
- ✅ Sensitive URL detection (tokens, secrets)
- ✅ Remote Config flag respect
- ✅ User opt-in enforcement
