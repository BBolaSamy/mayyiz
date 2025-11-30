# 📱 Share Extension - Ready to Test!

## ✅ What's Been Implemented

Your Share Extension is **fully implemented** and ready to test. Here's what's in place:

### 1. Share Extension (`MayyizShareExtension`)
- ✅ Accepts images and URLs
- ✅ Saves to App Group: `group.com.mayyiz.shared`
- ✅ File structure: `shared/<id>.jpg` and `shared/<id>.json`
- ✅ Opens main app via: `mayyiz://share?id=<id>`
- ✅ Clean UI with Cancel/Share buttons

### 2. Main App Integration
- ✅ URL scheme handler: `mayyiz://`
- ✅ `URLHandler` parses share URLs
- ✅ `AppViewModel.onShareHandoff()` loads shared content
- ✅ `PreviewView` displays shared content
- ✅ `SharedContainer` manages App Group files

### 3. Configuration Files
- ✅ `Info.plist` - URL scheme configured
- ✅ `Mayyiz.entitlements` - App Group enabled
- ✅ `MayyizShareExtension.entitlements` - App Group enabled
- ✅ `MayyizShareExtension/Info.plist` - Activation rules set

## 🧪 How to Test (Step-by-Step)

### Step 1: Build and Run Main App

1. **Open Xcode**
2. **Select "Mayyiz" scheme** (not MayyizShareExtension)
3. **Select iPhone 15 simulator** (or any iOS 16+ simulator)
4. **Press ⌘+R** to build and run
5. **Wait for app to launch** - you should see the IdleView
6. **Send app to background** (⌘+Shift+H or swipe up)

### Step 2: Test with Safari (URL Sharing)

1. **Open Safari** on the simulator
2. **Go to any website** (e.g., https://www.apple.com)
3. **Tap the Share button** (square with up arrow at bottom)
4. **Scroll down** in the share sheet
5. **Look for "Mayyiz"** icon/name
   - If not visible, tap "Edit Actions" and enable it
6. **Tap "Mayyiz"**
7. **You should see**:
   ```
   Share to Mayyiz
   Preparing content for analysis...
   [Cancel]  [Share]
   ```
8. **Tap "Share"**
9. **Main app should open** and show PreviewView with the URL

### Step 3: Test with Screenshot (Image Sharing)

1. **Take a screenshot** on simulator:
   - Press **⌘+S** (or Device → Screenshot)
2. **Screenshot appears** in bottom-left corner
3. **Tap the screenshot thumbnail**
4. **Tap Share button**
5. **Select "Mayyiz"**
6. **Tap "Share"**
7. **Main app should open** with the image in PreviewView

### Step 4: Verify Files Were Saved

Run this in Terminal:

```bash
# Run the test script
./test_share_extension.sh
```

Or manually check:

```bash
# Find App Group container
xcrun simctl get_app_container booted group.com.mayyiz.shared

# List shared files
ls -la "$(xcrun simctl get_app_container booted group.com.mayyiz.shared)/shared/"
```

You should see files like:
- `<uuid>.jpg` (if you shared an image)
- `<uuid>.json` (metadata)

## 📊 Expected Console Output

When sharing, you should see these logs in Xcode console:

**In Share Extension:**
```
✅ Saved image: shared/<id>.jpg
✅ Saved shared content with ID: <id>
🔗 Opening main app with URL: mayyiz://share?id=<id>
✅ Successfully opened main app
```

**In Main App:**
```
📱 Received URL: mayyiz://share?id=<id>
✅ Parsed route: Share with ID: <id>
🔗 Share handoff received: <id>
📱 AppState changed to: preview(shareId: "<id>")
```

## 🐛 Troubleshooting

### Problem: "Mayyiz" doesn't appear in share sheet

**Solution:**
1. Make sure **both** Mayyiz and MayyizShareExtension built successfully
2. Check that Share Extension target is included in the scheme
3. Try restarting the simulator
4. Clean build folder (⌘+Shift+K) and rebuild

### Problem: Main app doesn't open after tapping "Share"

**Solution:**
1. Verify URL scheme in `Mayyiz/Info.plist`: `mayyiz`
2. Check `onOpenURL` handler in `MayyizApp.swift`
3. Look for errors in console about URL handling

### Problem: PreviewView shows "No content"

**Solution:**
1. Check that files were saved to App Group
2. Verify `SharedContainer.loadCodable()` is working
3. Check console for file read errors

## 📸 Screenshot Upload Instructions

To share your test results:

1. **Take screenshots** during testing:
   - Share Extension UI
   - Main app PreviewView
   - Console logs

2. **Share them** by:
   - Dragging from simulator to desktop
   - Or using ⌘+S to save

3. **Upload** the screenshots showing:
   - ✅ Share Extension appearing in share sheet
   - ✅ Share Extension UI
   - ✅ Main app opening with shared content
   - ✅ Console logs showing successful handoff

## ✨ What Happens Next

After you share content:

1. **PreviewView** displays the content
2. **Tap "Analyze"** button
3. **AnalyzingView** shows progress
4. **ResultView** shows analysis results with:
   - Risk score
   - Red flags
   - URL intelligence
   - Findings

## 🎯 Success Checklist

- [ ] Main app builds and runs
- [ ] Share Extension appears in Safari share sheet
- [ ] Can share URL from Safari
- [ ] Main app opens automatically
- [ ] PreviewView shows the shared URL
- [ ] Can share screenshot
- [ ] Main app opens with the image
- [ ] Files saved to `shared/` directory
- [ ] Console shows successful logs
- [ ] No crashes or errors

---

**Ready to test!** Follow the steps above and share screenshots of the results. 🚀
