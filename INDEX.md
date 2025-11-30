# Mayyiz Project - Documentation Index

Welcome to the Mayyiz iOS app project! This index will help you find the right documentation for your needs.

## 🚀 Getting Started

**New to this project?** Start here:

1. **[QUICKSTART.md](./QUICKSTART.md)** ⭐ **START HERE**
   - 5-minute setup guide
   - Step-by-step instructions
   - Verification checklist
   - Perfect for first-time setup

2. **[setup.sh](./setup.sh)** 🔧
   - Automated verification script
   - Run: `./setup.sh`
   - Checks all files and configuration
   - Opens workspace when ready

## 📚 Detailed Documentation

### Setup & Configuration

- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** 📖
  - Complete step-by-step instructions
  - Xcode configuration details
  - Firebase setup
  - Testing procedures
  - Troubleshooting tips

- **[SUMMARY.md](./SUMMARY.md)** 📋
  - What has been created
  - Complete file structure
  - Configuration summary
  - Verification checklist
  - Quick commands reference

### Reference & Architecture

- **[README.md](./README.md)** 📘
  - Project structure
  - Target configuration
  - Firebase setup
  - App Groups usage
  - URL schemes
  - Development workflow
  - Common issues & solutions

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** 🏗️
  - System architecture diagrams
  - Data flow visualization
  - Component relationships
  - Firebase integration
  - URL routing
  - Security & entitlements

## 📁 Project Files

### Workspace & Project
```
Mayyiz.xcworkspace/          ← Open this in Xcode
Mayyiz.xcodeproj/            ← Project file
```

### Main App (Mayyiz)
```
Mayyiz/
├── Sources/
│   └── SharedContainer.swift    ← App Groups helper
├── MayyizApp.swift              ← App entry point
├── ContentView.swift            ← Main UI with tests
├── Info.plist                   ← URL scheme config
└── Mayyiz.entitlements          ← App Groups entitlement
```

### Share Extension
```
MayyizShareExtension/
├── Sources/
│   └── ShareViewController.swift  ← Extension UI
├── Info.plist                     ← Extension config
└── MayyizShareExtension.entitlements
```

### Documentation
```
QUICKSTART.md        ← Start here!
SETUP_GUIDE.md       ← Detailed setup
README.md            ← Reference
SUMMARY.md           ← What's included
ARCHITECTURE.md      ← System design
INDEX.md             ← This file
```

### Tools
```
setup.sh             ← Verification script
.gitignore           ← Git exclusions
```

## 🎯 Quick Navigation by Task

### I want to...

#### Set up the project for the first time
→ [QUICKSTART.md](./QUICKSTART.md)

#### Understand what was created
→ [SUMMARY.md](./SUMMARY.md)

#### Configure Xcode settings
→ [SETUP_GUIDE.md](./SETUP_GUIDE.md)

#### Learn about the architecture
→ [ARCHITECTURE.md](./ARCHITECTURE.md)

#### Find configuration details
→ [README.md](./README.md)

#### Verify my setup
→ Run `./setup.sh`

#### Add Firebase
→ [SETUP_GUIDE.md](./SETUP_GUIDE.md#step-4-add-firebase-spm-dependencies)

#### Test App Groups
→ [QUICKSTART.md](./QUICKSTART.md#test-app-groups)

#### Configure Share Extension
→ [SETUP_GUIDE.md](./SETUP_GUIDE.md#step-3-add-share-extension-target)

#### Understand URL schemes
→ [README.md](./README.md#url-schemes)

#### Use SharedContainer
→ [README.md](./README.md#app-groups)

#### Troubleshoot issues
→ [README.md](./README.md#common-issues)

## 📊 Documentation Overview

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **OCR_SUMMARY.md** | Vision-based text recognition with Arabic support | Understanding OCR service |
| **HEURISTICS_SUMMARY.md** | Phishing and scam pattern detection | Understanding heuristics service |
| **INTEL_SUMMARY.md** | External threat intelligence integration | Understanding link intelligence |
| **APPSTATE_GUIDE.md** | Detailed guide on the app's state machine | Understanding app state management |
| **QUICKSTART.md** | Fast setup guide | First time setup |
| **SETUP_GUIDE.md** | Detailed instructions | Need step-by-step help |
| **README.md** | Complete reference | Looking up specific info |
| **SUMMARY.md** | Project overview | Want to see what's included |
| **ARCHITECTURE.md** | System design | Understanding structure |
| **INDEX.md** | Navigation | Finding right documentation |

## 🔍 Key Topics

### Configuration
- [Bundle Identifiers](./README.md#target-configuration)
- [App Groups](./README.md#app-groups)
- [Entitlements](./ARCHITECTURE.md#security--entitlements)
- [URL Schemes](./README.md#url-schemes)

### Development
- [Project Structure](./README.md#project-structure)
- [Build & Test](./QUICKSTART.md#5-build--test)
- [Firebase Setup](./SETUP_GUIDE.md#step-4-add-firebase-spm-dependencies)
- [Share Extension](./SETUP_GUIDE.md#step-3-add-share-extension-target)

### Code
- [SharedContainer API](./ARCHITECTURE.md#sharedcontainer-api)
- [URL Handling](./ARCHITECTURE.md#url-scheme-routing)
- [Data Flow](./ARCHITECTURE.md#data-flow-share-extension--main-app)

## 🛠️ Common Tasks

### First Time Setup
```bash
# 1. Verify files
./setup.sh

# 2. Open workspace
open Mayyiz.xcworkspace

# 3. Follow QUICKSTART.md
```

### Building
```bash
# In Xcode: ⌘+B
# Or from terminal:
xcodebuild -workspace Mayyiz.xcworkspace \
           -scheme Mayyiz \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           build
```

### Testing
```bash
# Run app: ⌘+R in Xcode

# Test URL scheme:
xcrun simctl openurl booted "mayyiz://test"

# Test share:
# Use Safari/Photos share sheet
```

## 📞 Support

### Having Issues?

1.  **Check the verification checklist**: [SUMMARY.md](./SUMMARY.md#verification-checklist)
2.  **Run setup script**: `./setup.sh`
3.  **Review common issues**: [README.md](./README.md#common-issues)
4.  **Check detailed guide**: [SETUP_GUIDE.md](./SETUP_GUIDE.md)

### Documentation Not Clear?

All documentation is in Markdown format and can be edited. Feel free to improve it!

## 📝 Project Specifications

-   **iOS Deployment Target**: 16.0+
-   **Language**: Swift 5.0
-   **UI Framework**: SwiftUI
-   **Architecture**: MVVM (ready to implement)
-   **Dependencies**: Firebase (via SPM)
-   **Capabilities**: App Groups, Push Notifications
-   **Extensions**: Share Extension

## 🎓 Learning Resources

### Core Services
- [**OCR Service Guide**](OCR_GUIDE.md): Implementation and usage of OCR
- [**Heuristics Guide**](HEURISTICS_GUIDE.md): Pattern matching and risk assessment
- [**Link Intel Guide**](INTEL_GUIDE.md): VirusTotal and urlscan.io integration

### App State Management
- [**App State Guide**](APPSTATE_GUIDE.md): State machine and lifecycle management

### Apple Documentation
- [App Groups](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Share Extension](https://developer.apple.com/documentation/uikit/share_extension)
- [URL Schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)

### Firebase Documentation
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firebase Auth](https://firebase.google.com/docs/auth/ios/start)
- [Firestore](https://firebase.google.com/docs/firestore/quickstart)

## 🗺️ Project Roadmap

### ✅ Phase 1: Setup (Complete)
- Workspace configuration
- Share Extension structure
- App Groups setup
- Firebase integration prepared
- Documentation created

### 🔄 Phase 2: Configuration (In Progress)
- Complete Xcode target setup
- Add Firebase packages
- Configure provisioning
- Test all features

### 📋 Phase 3: Development (Next)
- Implement authentication
- Build core features
- Design UI/UX
- Integrate Firebase services

### 🚀 Phase 4: Deployment (Future)
- App Store preparation
- Beta testing
- Release

## 📂 File Tree

```
Mayyiz/
├── 📄 Documentation
│   ├── INDEX.md              ← You are here
│   ├── QUICKSTART.md         ← Start here
│   ├── SETUP_GUIDE.md        ← Detailed setup
│   ├── README.md             ← Reference
│   ├── SUMMARY.md            ← Overview
│   └── ARCHITECTURE.md       ← Design
│
├── 🔧 Tools
│   ├── setup.sh              ← Verification
│   └── .gitignore            ← Git config
│
├── 📦 Workspace
│   ├── Mayyiz.xcworkspace/   ← Open this
│   └── Mayyiz.xcodeproj/     ← Project
│
├── 📱 Main App
│   └── Mayyiz/
│       ├── Sources/
│       │   └── SharedContainer.swift
│       ├── MayyizApp.swift
│       ├── ContentView.swift
│       ├── Info.plist
│       └── Mayyiz.entitlements
│
├── 🔗 Share Extension
│   └── MayyizShareExtension/
│       ├── Sources/
│       │   └── ShareViewController.swift
│       ├── Info.plist
│       └── MayyizShareExtension.entitlements
│
└── 🧪 Tests
    ├── MayyizTests/
    └── MayyizUITests/
```

## 🎯 Next Steps

1. ✅ Read this index (you're doing it!)
2. 📖 Open [QUICKSTART.md](./QUICKSTART.md)
3. 🔧 Run `./setup.sh`
4. 💻 Open `Mayyiz.xcworkspace`
5. ⚙️ Follow configuration steps
6. 🚀 Start building!

---

**Welcome to Mayyiz!** 🎉

Ready to start? → [QUICKSTART.md](./QUICKSTART.md)

Need help? → [SETUP_GUIDE.md](./SETUP_GUIDE.md)

Want details? → [README.md](./README.md)
