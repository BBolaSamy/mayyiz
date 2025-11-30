# Share Extension Testing Guide

## � Prerequisites

Before testing, ensure:
- ✅ Both **Mayyiz** and **MayyizShareExtension** targets build successfully
- ✅ App Group is configured: `group.com.mayyiz.shared`
- ✅ URL scheme is configured: `mayyiz://`
- ✅ Share Extension is enabled in the scheme

## 🧪 Testing Steps

### Step 1: Build and Run the Main App

1. **Select the Mayyiz scheme** in Xcode
2. **Select a simulator** (e.g., iPhone 15)
3. **Build and Run** (⌘+R)
4. Verify the app launches successfully
5. **Keep the app running** or send it to background

### Step 2: Test Share Extension with Safari

1. **Open Safari** on the same simulator
2. **Navigate to any website** (e.g., https://www.apple.com)
3. **Tap the Share button** (square with arrow pointing up)
4. **Scroll down** in the share sheet
5. **Look for "Mayyiz"** in the list of apps
   - If you don't see it, tap "Edit Actions" and enable it

### Step 3: Share to Mayyiz

1. **Tap on "Mayyiz"** in the share sheet
2. You should see the **Share Extension UI** with:
   - Title: "Share to Mayyiz"
   - Subtitle: "Preparing content for analysis..."
   - Cancel and Share buttons
3. **Tap "Share"**
4. The extension should:
   - Save the URL to App Group
   - Open the main Mayyiz app
   - Pass the share ID via `mayyiz://share?id=...`

### Step 4: Verify in Main App

1. The **Mayyiz app should open** automatically
2. You should see the **PreviewView** with the shared URL
3. The URL should be displayed correctly

## 📸 Testing with Screenshots

### Option 1: Share from Photos App

1. **Open Photos app** on simulator
2. **Take a screenshot**: 
   - Press **⌘+S** (or use Device menu → Screenshot)
3. **Open the screenshot** in Photos
4. **Tap Share button**
5. **Select "Mayyiz"**
6. Verify the image is shared

### Option 2: Share from Safari (Screenshot)

1. **Open Safari**
2. **Take a full-page screenshot**:
   - Tap Share → "Save to Photos"
3. **Open Photos app**
4. **Share the screenshot** to Mayyiz

## 🔍 Debugging

### Check App Group Files

Run this in Terminal to see what's being saved:

```bash
# Find the App Group container
xcrun simctl get_app_container booted group.com.mayyiz.shared

# List files in the container
ls -la "$(xcrun simctl get_app_container booted group.com.mayyiz.shared)/shared/"
```

### Check Console Logs

In Xcode:
1. **Open Console** (⌘+Shift+Y)
2. **Filter by "Mayyiz"**
3. Look for these log messages:
   - `✅ Saved image: shared/<id>.jpg`
   - `✅ Saved shared content with ID: <id>`
   - `🔗 Opening main app with URL: mayyiz://share?id=<id>`
   - `🔗 Share handoff received: <id>`

## ✅ Success Criteria

The Share Extension is working if:

1. ✅ Share Extension appears in the share sheet
2. ✅ Extension UI displays correctly
3. ✅ Files are saved to App Group (`shared/<id>.jpg`, `shared/<id>.json`)
4. ✅ Main app opens automatically
5. ✅ PreviewView shows the shared content
6. ✅ No crashes or errors in console

## 🐛 Common Issues

### Issue 1: Share Extension Not Appearing

**Solution:**
1. Check that Share Extension target is included in the scheme
2. Verify `Info.plist` has correct activation rules
3. Clean build folder (⌘+Shift+K) and rebuild

### Issue 2: App Group Not Working

**Solution:**
1. Verify App Group ID: `group.com.mayyiz.shared`
2. Check both entitlements files
3. Ensure both targets have the same App Group

### Issue 3: Main App Doesn't Open

**Solution:**
1. Verify URL scheme in `Info.plist`: `mayyiz`
2. Check `URLHandler` is parsing correctly
3. Verify `onOpenURL` handler in `MayyizApp.swift`

### Issue 4: Files Not Found

**Solution:**
1. Check file paths use `shared/` prefix
2. Verify `SharedContainer.writeData` creates directories
3. Check file permissions

## 📊 Expected File Structure

After sharing, the App Group should contain:

```
group.com.mayyiz.shared/
└── shared/
    ├── <shareId>.jpg          # Image (if shared)
    └── <shareId>.json         # Metadata
```

## 🎯 Next Steps After Verification

Once the Share Extension works:

1. ✅ Test with different content types (images, URLs, text)
2. ✅ Test the analysis flow (Preview → Analyze → Result)
3. ✅ Verify OCR on shared images
4. ✅ Test heuristics on shared URLs
5. ✅ Check Firebase integration (if configured)

---

## 📝 Quick Test Checklist

- [ ] Main app builds and runs
- [ ] Share Extension builds and runs
- [ ] Share Extension appears in Safari share sheet
- [ ] Can share URL from Safari
- [ ] Main app opens with shared URL
- [ ] Can share screenshot from Photos
- [ ] Main app opens with shared image
- [ ] Files are saved to App Group
- [ ] No console errors
- [ ] Preview displays content correctly

---

**Need help?** Check the console logs and verify the file paths in the App Group container.
