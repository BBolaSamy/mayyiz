# Mayyiz Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mayyiz Workspace                        │
└─────────────────────────────────────────────────────────────────┘
                                 │
                ┌────────────────┴────────────────┐
                │                                 │
        ┌───────▼────────┐              ┌────────▼─────────┐
        │  Mayyiz App    │              │ Share Extension  │
        │ (Main Target)  │              │    (Target)      │
        └───────┬────────┘              └────────┬─────────┘
                │                                 │
                │         App Group Container     │
                │    group.com.mayyiz.shared     │
                └────────────┬────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ SharedContainer │
                    │     Helper      │
                    └─────────────────┘
```

## Data Flow: Share Extension → Main App

```
┌──────────────┐
│  User shares │
│   content    │
│  from Safari │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│              Share Extension Activated                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │        ShareViewController.swift                │  │
│  │                                                 │  │
│  │  1. Extract content (text/URL/images)          │  │
│  │  2. Save to SharedContainer                    │  │
│  │  3. Open main app via mayyiz://share           │  │
│  └─────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │   App Group     │
              │   Container     │
              │                 │
              │  pendingShare   │
              │  {              │
              │   text: "..."   │
              │   url: "..."    │
              │   images: [...]  │
              │  }              │
              └────────┬────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                Main App Activated                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │           MayyizApp.swift                       │  │
│  │                                                 │  │
│  │  1. Receive mayyiz://share URL                 │  │
│  │  2. Read from SharedContainer                  │  │
│  │  3. Process shared content                     │  │
│  │  4. Clean up shared data                       │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Component Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        Mayyiz App                              │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ MayyizApp    │  │ ContentView  │  │ Other Views  │        │
│  │              │  │              │  │              │        │
│  │ • Firebase   │  │ • Test UI    │  │ • Features   │        │
│  │ • URL Handle │  │ • SharedTest │  │ • Screens    │        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                 │                  │                │
│         └─────────────────┼──────────────────┘                │
│                           │                                   │
│                  ┌────────▼────────┐                          │
│                  │ SharedContainer │                          │
│                  │                 │                          │
│                  │ • File I/O      │                          │
│                  │ • UserDefaults  │                          │
│                  │ • Codable       │                          │
│                  └────────┬────────┘                          │
│                           │                                   │
└───────────────────────────┼───────────────────────────────────┘
                            │
                            │ App Group
                            │ group.com.mayyiz.shared
                            │
┌───────────────────────────┼───────────────────────────────────┐
│                           │                                   │
│                  ┌────────▼────────┐                          │
│                  │ SharedContainer │                          │
│                  │   (Same File)   │                          │
│                  └────────┬────────┘                          │
│                           │                                   │
│         ┌─────────────────┴─────────────────┐                │
│         │                                   │                │
│  ┌──────▼───────┐                           │                │
│  │ShareView     │                           │                │
│  │Controller    │                           │                │
│  │              │                           │                │
│  │ • Extract    │                           │                │
│  │ • Save       │                           │                │
│  │ • Open App   │                           │                │
│  └──────────────┘                           │                │
│                                             │                │
│                    Share Extension          │                │
└─────────────────────────────────────────────┴────────────────┘
```

## Firebase Integration

```
┌────────────────────────────────────────────────────────────────┐
│                        Mayyiz App                              │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐                                             │
│  │ MayyizApp    │                                             │
│  │              │                                             │
│  │ Firebase     │                                             │
│  │ .configure() │                                             │
│  └──────┬───────┘                                             │
│         │                                                     │
│         ├─────────────┬─────────────┬─────────────┐          │
│         │             │             │             │          │
│    ┌────▼────┐  ┌────▼────┐  ┌────▼────┐  ┌────▼────┐      │
│    │  Auth   │  │Firestore│  │ Storage │  │Functions│      │
│    └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
│                                                              │
│    ┌─────────┐  ┌─────────┐  ┌─────────┐                   │
│    │ Remote  │  │Crashly  │  │  App    │                   │
│    │ Config  │  │ tics    │  │ Check   │                   │
│    └─────────┘  └─────────┘  └─────────┘                   │
│                                                              │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────┐
                    │  Firebase Cloud  │
                    │                  │
                    │ • Authentication │
                    │ • Database       │
                    │ • Storage        │
                    │ • Functions      │
                    │ • Config         │
                    │ • Analytics      │
                    └──────────────────┘
```

## URL Scheme Routing

```
External App / System
        │
        │ mayyiz://share
        │ mayyiz://profile/123
        │ mayyiz://...
        ▼
┌───────────────────────────────────────┐
│      MayyizApp.swift                  │
│                                       │
│  .onOpenURL { url in                 │
│    handleIncomingURL(url)            │
│  }                                   │
└───────────┬───────────────────────────┘
            │
            ▼
    ┌───────────────┐
    │ URL Router    │
    │               │
    │ switch url    │
    └───┬───────────┘
        │
        ├─── "share" ────────► Handle shared content
        │                      from Share Extension
        │
        ├─── "profile" ──────► Navigate to profile
        │
        ├─── "settings" ─────► Open settings
        │
        └─── default ────────► Handle other URLs
```

## SharedContainer API

```
┌─────────────────────────────────────────────────────────┐
│                   SharedContainer                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Static Properties:                                     │
│  • appGroupIdentifier: String                          │
│  • containerURL: URL?                                  │
│  • sharedDefaults: UserDefaults?                       │
│                                                         │
│  File Operations:                                       │
│  • fileURL(for:) -> URL?                               │
│  • writeData(_:to:) throws                             │
│  • readData(from:) throws -> Data                      │
│  • deleteFile(_:) throws                               │
│  • fileExists(_:) -> Bool                              │
│  • listFiles() throws -> [String]                      │
│                                                         │
│  UserDefaults:                                          │
│  • saveToDefaults(_:forKey:)                           │
│  • readFromDefaults(forKey:) -> T?                     │
│  • removeFromDefaults(forKey:)                         │
│                                                         │
│  Codable Support:                                       │
│  • saveCodable(_:to:) throws                           │
│  • loadCodable(_:from:) throws -> T                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────┐
              │   File Manager    │
              │                   │
              │ App Group Storage │
              │ group.com.mayyiz  │
              │     .shared       │
              └───────────────────┘
```

## Build & Deployment Flow

```
Developer
    │
    ▼
┌─────────────────┐
│  Xcode IDE      │
│                 │
│  • Edit Code    │
│  • Build (⌘+B)  │
│  • Run (⌘+R)    │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────────┐
│         Build System                 │
│                                      │
│  1. Compile Swift files              │
│  2. Link Firebase frameworks         │
│  3. Process entitlements             │
│  4. Sign with provisioning profile   │
│  5. Package app + extension          │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│         Mayyiz.app                   │
│                                      │
│  ├─── Mayyiz (main executable)      │
│  ├─── Frameworks/                   │
│  │    ├─── Firebase...              │
│  │    └─── ...                      │
│  ├─── PlugIns/                      │
│  │    └─── MayyizShareExtension     │
│  ├─── GoogleService-Info.plist      │
│  └─── Assets                        │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│    iOS Device / Simulator            │
│                                      │
│  • Install app                       │
│  • Register URL scheme               │
│  • Enable share extension            │
│  • Configure App Groups              │
└──────────────────────────────────────┘
```

## Security & Entitlements

```
┌────────────────────────────────────────────────────────┐
│                  App Entitlements                      │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Mayyiz.entitlements:                                 │
│  ┌──────────────────────────────────────────────┐    │
│  │ • App Groups                                 │    │
│  │   - group.com.mayyiz.shared                  │    │
│  │ • Push Notifications                         │    │
│  │   - aps-environment: development             │    │
│  └──────────────────────────────────────────────┘    │
│                                                        │
│  MayyizShareExtension.entitlements:                   │
│  ┌──────────────────────────────────────────────┐    │
│  │ • App Groups                                 │    │
│  │   - group.com.mayyiz.shared                  │    │
│  └──────────────────────────────────────────────┘    │
│                                                        │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────┐
              │   iOS Sandbox     │
              │                   │
              │ Shared Container  │
              │ Access Granted    │
              └───────────────────┘
```

## Legend

```
┌─────────┐
│  Box    │  = Component / Module
└─────────┘

    │
    ▼        = Data / Control Flow

────────────  = Connection / Relationship

• Bullet     = Feature / Capability
```
