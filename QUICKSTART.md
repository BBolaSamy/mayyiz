# Mayyiz - Quick Start Guide

Welcome to Mayyiz! This guide will get you up and running quickly.

## 🚀 Quick Start (5 minutes)

### 1. Run Setup Verification
```bash
./setup.sh
```

This will verify all files are in place and open the workspace.

### 2. Configure in Xcode

#### Main App Target
1. Select **Mayyiz** project → **Mayyiz** target
2. **General** tab:
   - Bundle Identifier: `com.mayyiz.app`
   - iOS Deployment Target: `16.0`
3. **Signing & Capabilities** tab:
   - Add **App Groups** capability
   - Enable: `group.com.mayyiz.shared`
4. **Build Settings** tab:
   - Search: "Code Signing Entitlements"
   - Set: `Mayyiz/Mayyiz.entitlements`
   - Search: "Info.plist File"
   - Set: `Mayyiz/Info.plist`

#### Add Share Extension Target
1. File → New → Target
2. iOS → Share Extension
3. Product Name: `MayyizShareExtension`
4. Click Finish → Activate

5. **Delete** auto-generated files (we have better ones):
   - ShareViewController.swift
   - Info.plist

6. **Add our files**:
   - Drag `MayyizShareExtension/Sources/ShareViewController.swift` to target
   - Drag `MayyizShareExtension/Info.plist` to target

7. Configure **MayyizShareExtension** target:
   - Bundle ID: `com.mayyiz.app.share`
   - iOS Deployment: `16.0`
   - Add **App Groups**: `group.com.mayyiz.shared`
   - Entitlements: `MayyizShareExtension/MayyizShareExtension.entitlements`

#### Add SharedContainer to Both Targets
1. Select `Mayyiz/Sources/SharedContainer.swift`
2. File Inspector → Target Membership:
   - ✅ Mayyiz
   - ✅ MayyizShareExtension

### 3. Add Firebase

1. Project → Package Dependencies → **+**
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Add Package
4. Select for **Mayyiz** target:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFunctions
   - FirebaseStorage
   - FirebaseRemoteConfig
   - FirebaseCrashlytics
   - FirebaseAppCheck

5. In `MayyizApp.swift`:
   - Uncomment Firebase imports
   - Uncomment `FirebaseApp.configure()`

### 4. Add Firebase Config

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project or select existing
3. Add iOS app: `com.mayyiz.app`
4. Download `GoogleService-Info.plist`
5. Drag to Xcode → Mayyiz folder
6. Ensure it's added to **Mayyiz** target only

### 5. Build & Test

```bash
# Build
⌘ + B

# Run
⌘ + R
```

#### Test App Groups
1. Tap "Test Shared Container" button
2. Should see ✅ All tests passed!

#### Test Share Extension
1. Open Safari
2. Navigate to any website
3. Tap Share button
4. Find "Mayyiz" in share sheet
5. Share → Should open main app

#### Test URL Scheme
```bash
# With simulator running:
xcrun simctl openurl booted "mayyiz://test"
```

## 📁 Project Structure

```
Mayyiz/
├── Mayyiz.xcworkspace          ← Open this!
├── Mayyiz/
│   ├── Sources/
│   │   └── SharedContainer.swift
│   ├── MayyizApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── Mayyiz.entitlements
└── MayyizShareExtension/
    ├── Sources/
    │   └── ShareViewController.swift
    ├── Info.plist
    └── MayyizShareExtension.entitlements
```

## ✅ Verification Checklist

- [ ] Workspace opens without errors
- [ ] Main app bundle ID: `com.mayyiz.app`
- [ ] Share extension bundle ID: `com.mayyiz.app.share`
- [ ] Both targets have App Groups enabled
- [ ] Firebase packages added
- [ ] GoogleService-Info.plist in project
- [ ] App builds successfully
- [ ] Shared Container test passes
- [ ] Share extension appears in share sheet
- [ ] URL scheme opens app

## 🎯 What You Get

### Main App
- ✅ SwiftUI app structure
- ✅ Firebase integration ready
- ✅ URL scheme handling (`mayyiz://`)
- ✅ App Groups configured
- ✅ SharedContainer helper
- ✅ Test UI for verification

### Share Extension
- ✅ Accepts text, URLs, images, videos
- ✅ Saves to shared container
- ✅ Opens main app with data
- ✅ Clean, modern UI

### Shared Features
- ✅ File I/O in shared container
- ✅ Shared UserDefaults
- ✅ Codable object storage
- ✅ Error handling

## 🔧 Common Issues

### "Container not accessible"
→ App Groups not enabled. Check Signing & Capabilities.

### Share Extension not showing
→ Rebuild and reinstall app completely.

### Firebase not initializing
→ Check GoogleService-Info.plist is in Mayyiz target.

### URL scheme not working
→ Verify Info.plist has CFBundleURLTypes.

## 📚 Documentation

- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Detailed instructions
- [README.md](./README.md) - Complete reference

## 🚀 Next Steps

1. Customize the UI in `ContentView.swift`
2. Implement authentication with Firebase
3. Add your app features
4. Configure Firebase services (Firestore, Storage, etc.)
5. Build something amazing! 🎉

## 💡 Tips

- Always open `Mayyiz.xcworkspace`, not `.xcodeproj`
- Test on device for full share extension functionality
- Use SharedContainer for all cross-target data sharing
- Check console logs for URL scheme debugging

## 🆘 Need Help?

1. Check [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed steps
2. Review [README.md](./README.md) for configuration reference
3. Verify all checklist items above

---

**Ready to build?** Open the workspace and start coding! 🚀

```bash
open Mayyiz.xcworkspace
```
