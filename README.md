# Mayyiz Project Configuration

## Project Structure

```
Mayyiz/
├── Mayyiz.xcworkspace/          # Main workspace
├── Mayyiz.xcodeproj/            # Xcode project
├── Mayyiz/                      # Main app target
│   ├── Sources/
│   │   └── SharedContainer.swift
│   ├── Assets.xcassets/
│   ├── MayyizApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── Mayyiz.entitlements
├── MayyizShareExtension/        # Share Extension target
│   ├── Sources/
│   │   └── ShareViewController.swift
│   ├── Info.plist
│   └── MayyizShareExtension.entitlements
├── MayyizTests/                 # Unit tests
├── MayyizUITests/               # UI tests
├── SETUP_GUIDE.md              # Detailed setup instructions
└── setup.sh                     # Setup verification script
```

## Target Configuration

### Mayyiz (Main App)
- **Bundle ID**: `com.mayyiz.app`
- **Platform**: iOS 16.0+
- **Capabilities**:
  - App Groups: `group.com.mayyiz.shared`
  - Push Notifications
- **URL Schemes**: `mayyiz://`
- **Entitlements**: `Mayyiz/Mayyiz.entitlements`
- **Info.plist**: `Mayyiz/Info.plist`

### MayyizShareExtension
- **Bundle ID**: `com.mayyiz.app.share`
- **Platform**: iOS 16.0+
- **Type**: Share Extension
- **Capabilities**:
  - App Groups: `group.com.mayyiz.shared`
- **Entitlements**: `MayyizShareExtension/MayyizShareExtension.entitlements`
- **Info.plist**: `MayyizShareExtension/Info.plist`
- **Accepts**: Text, URLs, Images, Videos

## Firebase Configuration

### Required Packages
All packages from: `https://github.com/firebase/firebase-ios-sdk`

1. **FirebaseAuth** - User authentication
2. **FirebaseFirestore** - Cloud database
3. **FirebaseFunctions** - Cloud functions
4. **FirebaseStorage** - File storage
5. **FirebaseRemoteConfig** - Remote configuration
6. **FirebaseCrashlytics** - Crash reporting
7. **FirebaseAppCheck** - App attestation

### Setup Steps
1. Create Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add iOS app with bundle ID: `com.mayyiz.app`
3. Download `GoogleService-Info.plist`
4. Add to Xcode project (Mayyiz target only)
5. Uncomment Firebase imports in `MayyizApp.swift`
6. Uncomment `FirebaseApp.configure()` in app initializer

## App Groups

### Identifier
`group.com.mayyiz.shared`

### Purpose
Enables data sharing between:
- Main app (Mayyiz)
- Share Extension (MayyizShareExtension)

### Usage
Use the `SharedContainer` helper class:

```swift
// Write data
try SharedContainer.writeData(data, to: "filename.txt")

// Read data
let data = try SharedContainer.readData(from: "filename.txt")

// UserDefaults
SharedContainer.saveToDefaults(value, forKey: "key")
let value: String? = SharedContainer.readFromDefaults(forKey: "key")

// Codable objects
try SharedContainer.saveCodable(object, to: "data.json")
let object = try SharedContainer.loadCodable(MyType.self, from: "data.json")
```

## URL Schemes

### Scheme
`mayyiz://`

### Supported URLs

#### Share Handler
- **URL**: `mayyiz://share`
- **Purpose**: Opened by Share Extension after sharing content
- **Handler**: `MayyizApp.handleIncomingURL(_:)`
- **Data Source**: Shared UserDefaults key `pendingShare`

#### Custom Deep Links
Add more URL handlers in `handleIncomingURL(_:)`:

```swift
// Example: mayyiz://profile/123
if url.host == "profile", let userId = url.pathComponents.last {
    // Navigate to profile
}
```

## Share Extension Flow

1. **User shares content** from another app
2. **Share Extension launches** (ShareViewController)
3. **Content extracted** (text, URLs, images)
4. **Data saved** to shared container via SharedContainer
5. **Main app opened** via `mayyiz://share` URL
6. **Main app processes** shared data
7. **Data cleaned up** from shared container

## Development Workflow

### Building
```bash
# Open workspace
open Mayyiz.xcworkspace

# Build from command line
xcodebuild -workspace Mayyiz.xcworkspace \
           -scheme Mayyiz \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           build
```

### Testing URL Schemes
```bash
# Test URL scheme (simulator must be running)
xcrun simctl openurl booted "mayyiz://share"
xcrun simctl openurl booted "mayyiz://test"
```

### Testing Share Extension
1. Run app on simulator
2. Open Safari/Photos/Notes
3. Select content to share
4. Tap Share button
5. Find "Mayyiz" in share sheet
6. Share and verify

### Testing App Groups
Add test button to ContentView:

```swift
Button("Test Shared Container") {
    do {
        try SharedContainer.writeData("Test".data(using: .utf8)!, to: "test.txt")
        let data = try SharedContainer.readData(from: "test.txt")
        print("✅ Success: \(String(data: data, encoding: .utf8) ?? "")")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

## Signing & Provisioning

### Development
- Team: Set in Xcode project settings
- Signing: Automatic
- Provisioning Profile: Xcode Managed

### Production
1. Create App ID: `com.mayyiz.app`
2. Create App ID: `com.mayyiz.app.share`
3. Enable App Groups capability for both
4. Create App Group: `group.com.mayyiz.shared`
5. Create provisioning profiles
6. Configure in Xcode

## Common Issues

### Share Extension not appearing
- Check bundle ID: `com.mayyiz.app.share`
- Verify Info.plist activation rules
- Rebuild and reinstall app

### App Groups not working
- Verify both targets have capability enabled
- Check identifier matches exactly: `group.com.mayyiz.shared`
- Check entitlements files are linked in Build Settings

### URL scheme not working
- Verify Info.plist has CFBundleURLTypes
- Check scheme is lowercase: `mayyiz`
- Ensure app is installed on device/simulator

### Firebase not initializing
- Check GoogleService-Info.plist is in project
- Verify it's added to Mayyiz target (not extension)
- Uncomment Firebase imports and configure() call

## Next Steps

1. ✅ Complete Xcode configuration (see SETUP_GUIDE.md)
2. ✅ Add Firebase packages
3. ✅ Download and add GoogleService-Info.plist
4. ✅ Test all functionality
5. 🚀 Start building your app features!

## Resources

- [Setup Guide](./SETUP_GUIDE.md) - Detailed step-by-step instructions
- [Firebase iOS Docs](https://firebase.google.com/docs/ios/setup)
- [App Groups Guide](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Share Extension Guide](https://developer.apple.com/documentation/uikit/share_extension)
