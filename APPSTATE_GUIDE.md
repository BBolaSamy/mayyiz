# AppState Implementation Guide

## Overview

The Mayyiz app implements a comprehensive state management system with five distinct states:

1. **Idle** - Starting point, user can pick images or view dashboard
2. **Preview** - Shows shared content before analysis
3. **Analyzing** - Processing content with visual feedback
4. **Result** - Displays analysis results
5. **Dashboard** - Shows history and statistics

## Architecture

### State Flow Diagram

```
┌─────────┐
│  Idle   │ ◄─────────────────────────┐
└────┬────┘                           │
     │                                │
     │ onPickImage()                  │ reset()
     │ onShareHandoff(id)             │
     │                                │
     ▼                                │
┌──────────┐                          │
│ Preview  │                          │
└────┬─────┘                          │
     │                                │
     │ onAnalyze()                    │
     │                                │
     ▼                                │
┌───────────┐                         │
│ Analyzing │                         │
└─────┬─────┘                         │
      │                               │
      │ (automatic)                   │
      │                               │
      ▼                               │
┌─────────┐                           │
│ Result  │                           │
└────┬────┘                           │
     │                                │
     │ onFinish()                     │
     │                                │
     ▼                                │
┌───────────┐                         │
│ Dashboard │ ────────────────────────┘
└───────────┘
```

## Components

### 1. AppState (Enum)

**Location**: `Mayyiz/Sources/Models/AppState.swift`

Defines all possible app states:

```swift
enum AppState: Equatable {
    case idle
    case preview(shareId: String)
    case analyzing(shareId: String)
    case result(shareId: String, analysisResult: AnalysisResult)
    case dashboard
}
```

**Properties**:
- `isProcessing: Bool` - True when analyzing
- `currentShareId: String?` - Current share ID if available

### 2. AppViewModel

**Location**: `Mayyiz/Sources/ViewModels/AppViewModel.swift`

Main view model managing state transitions and business logic.

**Published Properties**:
```swift
@Published private(set) var state: AppState = .idle
@Published var errorMessage: String?
@Published var isLoading: Bool = false
```

**Actions**:

#### `onShareHandoff(id: String)`
- **Purpose**: Handle share from Share Extension
- **Flow**: 
  1. Load shared content from SharedContainer
  2. Transition to `.preview(shareId: id)`
  3. Store content for later use

```swift
appViewModel.onShareHandoff(id: "abc123")
```

#### `onPickImage()`
- **Purpose**: Start image picker flow
- **Flow**:
  1. Generate new share ID
  2. Transition to `.preview(shareId: newId)`
  3. Wait for image picker callback

```swift
appViewModel.onPickImage()
```

#### `onAnalyze()`
- **Purpose**: Start content analysis
- **Flow**:
  1. Transition to `.analyzing(shareId: id)`
  2. Call AnalysisService
  3. On success: transition to `.result`
  4. On error: return to `.preview` with error message

```swift
appViewModel.onAnalyze()
```

#### `onFinish()`
- **Purpose**: Complete current flow
- **Flow**:
  1. Clean up shared content
  2. Transition to `.dashboard`
  3. Reset error state

```swift
appViewModel.onFinish()
```

### 3. URLHandler

**Location**: `Mayyiz/Sources/Utilities/URLHandler.swift`

Parses and routes URL schemes.

**Supported URLs**:

```swift
// Share with ID (new format)
mayyiz://share?id=abc123

// Share without ID (legacy)
mayyiz://share

// Dashboard
mayyiz://dashboard

// Profile
mayyiz://profile/user123
mayyiz://profile?id=user123

// Settings
mayyiz://settings
```

**Usage**:

```swift
// Parse URL
if let route = URLHandler.parse(url) {
    switch route {
    case .share(let id):
        appViewModel.onShareHandoff(id: id)
    case .dashboard:
        appViewModel.goToDashboard()
    // ...
    }
}

// Build URL
let url = URLHandler.buildShareURL(shareId: "abc123")
// Result: mayyiz://share?id=abc123
```

### 4. Views

Each state has a dedicated view:

#### IdleView
- **Location**: `Mayyiz/Sources/Views/IdleView.swift`
- **Features**:
  - Pick image button
  - Go to dashboard button
  - App branding

#### PreviewView
- **Location**: `Mayyiz/Sources/Views/PreviewView.swift`
- **Features**:
  - Display shared text
  - Display shared URLs
  - Image gallery
  - Metadata display
  - Analyze button
  - Cancel button

#### AnalyzingView
- **Location**: `Mayyiz/Sources/Views/AnalyzingView.swift`
- **Features**:
  - Animated progress indicator
  - Status message
  - Share ID display

#### ResultView
- **Location**: `Mayyiz/Sources/Views/ResultView.swift`
- **Features**:
  - Confidence score (circular progress)
  - Findings list
  - Metadata display
  - Go to dashboard button
  - Start new analysis button

#### DashboardView
- **Location**: `Mayyiz/Sources/Views/DashboardView.swift`
- **Features**:
  - Statistics cards (total, avg score, recent)
  - Recent analyses list
  - New analysis button
  - Back to home button

## Data Models

### SharedContent

**Location**: `Mayyiz/Sources/Models/AppState.swift`

```swift
struct SharedContent: Codable, Equatable {
    let id: String
    let timestamp: Date
    let text: String?
    let url: String?
    let imagePaths: [String]
}
```

**Storage**:
- UserDefaults: `share_{id}`
- File: `{id}.json`

### AnalysisResult

**Location**: `Mayyiz/Sources/Models/AppState.swift`

```swift
struct AnalysisResult: Equatable, Codable {
    let shareId: String
    let timestamp: Date
    let imageUrl: String?
    let findings: [String]
    let confidence: Double
    let metadata: [String: String]
}
```

**Storage**:
- File: `result_{id}.json`

## URL Scheme Integration

### Share Extension Flow

1. **User shares content** from another app
2. **ShareViewController** extracts content:
   ```swift
   let shareId = UUID().uuidString
   let content = SharedContent(id: shareId, ...)
   ```

3. **Save to SharedContainer**:
   ```swift
   SharedContainer.saveToDefaults(content, forKey: "share_\(shareId)")
   SharedContainer.saveCodable(content, to: "\(shareId).json")
   ```

4. **Build and open URL**:
   ```swift
   let url = URLHandler.buildShareURL(shareId: shareId)
   // mayyiz://share?id=abc123
   application.open(url)
   ```

5. **Main app receives URL**:
   ```swift
   .onOpenURL { url in
       handleIncomingURL(url)
   }
   ```

6. **Parse and route**:
   ```swift
   if let route = URLHandler.parse(url) {
       case .share(let id):
           appViewModel.onShareHandoff(id: id)
   }
   ```

7. **Load and display**:
   ```swift
   // PreviewView loads content
   let content = SharedContainer.readFromDefaults(forKey: "share_\(id)")
   ```

## Usage Examples

### Example 1: Handle Share from Extension

```swift
// In MayyizApp.swift
.onOpenURL { url in
    if let route = URLHandler.parse(url) {
        switch route {
        case .share(let id):
            appViewModel.onShareHandoff(id: id)
        default:
            break
        }
    }
}
```

### Example 2: Manual Image Analysis

```swift
// In IdleView
Button("Pick Image") {
    appViewModel.onPickImage()
}

// After image is picked (in image picker callback)
let shareId = appViewModel.state.currentShareId
let content = SharedContent(id: shareId, imagePaths: [imagePath])
SharedContainer.saveToDefaults(content, forKey: "share_\(shareId)")
```

### Example 3: View Analysis Results

```swift
// In ResultView
if case .result(let shareId, let result) = appViewModel.state {
    Text("Confidence: \(Int(result.confidence * 100))%")
    ForEach(result.findings, id: \.self) { finding in
        Text(finding)
    }
}
```

### Example 4: Navigate Programmatically

```swift
// From anywhere with access to appViewModel
appViewModel.goToDashboard()
appViewModel.reset() // Back to idle
appViewModel.onPickImage() // Start new analysis
```

## Testing

### Test URL Schemes

```bash
# Test share with ID
xcrun simctl openurl booted "mayyiz://share?id=test123"

# Test dashboard
xcrun simctl openurl booted "mayyiz://dashboard"

# Test legacy share
xcrun simctl openurl booted "mayyiz://share"
```

### Test State Transitions

```swift
// In a test or preview
let viewModel = AppViewModel()

// Test share handoff
viewModel.onShareHandoff(id: "test123")
assert(viewModel.state == .preview(shareId: "test123"))

// Test analysis
viewModel.onAnalyze()
// Wait for completion
assert(case .result = viewModel.state)

// Test finish
viewModel.onFinish()
assert(viewModel.state == .dashboard)
```

### Test Data Persistence

```swift
// Create test content
let content = SharedContent(
    id: "test123",
    text: "Test text",
    url: "https://example.com",
    imagePaths: []
)

// Save
SharedContainer.saveToDefaults(content, forKey: "share_test123")

// Load
let loaded: SharedContent? = SharedContainer.readFromDefaults(forKey: "share_test123")
assert(loaded == content)

// Clean up
SharedContainer.removeFromDefaults(forKey: "share_test123")
```

## Error Handling

### AppViewModel Error States

```swift
// Error during share handoff
catch {
    errorMessage = "Failed to load shared content"
    state = .idle
}

// Error during analysis
catch {
    errorMessage = "Analysis failed"
    state = .preview(shareId: shareId)
    isLoading = false
}
```

### Display Errors in Views

```swift
// In any view
@EnvironmentObject var appViewModel: AppViewModel

if let error = appViewModel.errorMessage {
    Text(error)
        .foregroundColor(.red)
}
```

## Best Practices

### 1. Always Use ShareId

```swift
// ✅ Good
let shareId = UUID().uuidString
let content = SharedContent(id: shareId, ...)

// ❌ Bad
let content = SharedContent(id: "", ...) // Empty ID
```

### 2. Clean Up After Use

```swift
// ✅ Good
func onFinish() {
    if let shareId = state.currentShareId {
        cleanupSharedContent(shareId: shareId)
    }
    state = .dashboard
}

// ❌ Bad - leaves data in SharedContainer
func onFinish() {
    state = .dashboard
}
```

### 3. Handle Legacy Format

```swift
// Support both new and old formats
if let route = URLHandler.parse(url) {
    switch route {
    case .share(let id):
        // New format with ID
        appViewModel.onShareHandoff(id: id)
    case .shareWithoutId:
        // Legacy format without ID
        handleLegacyShare()
    }
}
```

### 4. Use Environment Object

```swift
// ✅ Good - single source of truth
@EnvironmentObject var appViewModel: AppViewModel

// ❌ Bad - creates new instance
@StateObject var appViewModel = AppViewModel()
```

## Debugging

### Enable Logging

All state transitions are logged:

```
🚀 Mayyiz App Initialized
📱 Received URL: mayyiz://share?id=abc123
✅ Parsed route: Share with ID: abc123
🔗 Share handoff received: abc123
📱 AppState changed to: preview(shareId: "abc123")
🔍 Starting analysis for: abc123
📱 AppState changed to: analyzing(shareId: "abc123")
📱 AppState changed to: result(shareId: "abc123", ...)
✅ Finishing current flow
📱 AppState changed to: dashboard
```

### Check SharedContainer

```swift
// List all files
let files = try? SharedContainer.listFiles()
print("Files in container: \(files ?? [])")

// Check specific content
if let content: SharedContent = SharedContainer.readFromDefaults(forKey: "share_abc123") {
    print("Content: \(content)")
}
```

## Future Enhancements

1. **Image Picker Integration**: Add UIImagePicker for `onPickImage()`
2. **Camera Support**: Direct camera capture
3. **Multiple Images**: Support analyzing multiple images at once
4. **Offline Support**: Queue analyses when offline
5. **Push Notifications**: Notify when analysis completes
6. **Deep Linking**: Support more URL schemes
7. **State Persistence**: Save/restore app state on launch

## Summary

The AppState system provides:

✅ Clear state management with 5 distinct states  
✅ Well-defined actions: `onShareHandoff`, `onPickImage`, `onAnalyze`, `onFinish`  
✅ URL scheme parsing with `mayyiz://share?id=...`  
✅ Seamless Share Extension integration  
✅ Comprehensive error handling  
✅ Clean data persistence  
✅ Smooth UI transitions  
✅ Dashboard with history  

All components are modular, testable, and ready for production use.
