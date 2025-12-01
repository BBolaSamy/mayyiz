# 🧪 Share Extension + OCR Testing Guide

## ✅ What's New

I've added a **Test Share Extension** feature directly in the app that lets you:
1. Select a screenshot from your photo library
2. Share it through the iOS Share Sheet
3. Test the Share Extension
4. Verify OCR extracts text correctly
5. See the heuristics analysis results

## 🚀 How to Test (Step-by-Step)

### Step 1: Prepare Test Image

I've generated a test screenshot for you with Arabic and English phishing text. 

**Save this test image to your simulator:**
1. Drag the generated image (`test_screenshot_arabic.png`) to the simulator
2. Or take a screenshot of any text-containing image

**The test image contains:**
- Arabic text: "عاجل من بنك الراجحي" (Urgent from Al Rajhi Bank)
- Arabic text: "تم إيقاف حسابك مؤقتاً" (Your account has been suspended)
- Arabic text: "أدخل رمز التحقق: 123456" (Enter verification code)
- English text: "URGENT: Your account has been suspended"
- URL: "bit.ly/verify123"
- Urgency phrase: "Final warning - expires in 24 hours"

This will trigger multiple red flags in the heuristics analysis!

### Step 2: Run the App

1. **Open Xcode**
2. **Select "Mayyiz" scheme**
3. **Run on simulator** (⌘+R)
4. **Wait for app to launch**

### Step 3: Access Test View

1. On the **IdleView**, you'll see a new button:
   ```
   🟢 Test Share Extension
   ```
2. **Tap this button**
3. You'll see the **Share Extension Test View**

### Step 4: Select Screenshot

1. **Tap "Select Screenshot"**
2. **Choose the test image** from Photos
3. The image will display in the preview

### Step 5: Share Through Extension

1. **Tap "Share to Mayyiz Extension"**
2. The **iOS Share Sheet** will appear
3. **Scroll and find "Mayyiz"** in the list
4. **Tap "Mayyiz"**
5. The **Share Extension UI** will appear:
   ```
   Share to Mayyiz
   Preparing content for analysis...
   [Cancel]  [Share]
   ```
6. **Tap "Share"**

### Step 6: Verify the Flow

The following should happen automatically:

1. ✅ **Share Extension saves files**:
   - `shared/<id>.jpg` (the image)
   - `shared/<id>.json` (metadata)

2. ✅ **Main app opens** via `mayyiz://share?id=<id>`

3. ✅ **PreviewView displays** the shared image

4. ✅ **Tap "Analyze"** button

5. ✅ **OCR runs** on the image:
   - Extracts Arabic text
   - Extracts English text
   - Normalizes the text

6. ✅ **Heuristics analyzes** the text:
   - Detects Arabic urgency: "عاجل"
   - Detects Arabic bank: "بنك الراجحي"
   - Detects Arabic OTP: "رمز التحقق"
   - Detects English urgency: "URGENT"
   - Detects shortlink: "bit.ly"
   - Calculates risk score

7. ✅ **ResultView shows**:
   - Risk Score: ~80-90/100 (High Risk)
   - Red Flags:
     - arabicUrgency
     - arabicBankImpersonation
     - arabicOTP
     - urgencyPhrase
     - shortlink
   - Detected Links with intel
   - Analysis summary

## 📊 Expected Results

### Console Output

You should see logs like:

```
📸 Pick image action triggered
✅ Saved image: shared/<uuid>.jpg
✅ Saved shared content with ID: <uuid>
🔗 Opening main app with URL: mayyiz://share?id=<uuid>
📱 Received URL: mayyiz://share?id=<uuid>
🔗 Share handoff received: <uuid>
🔍 Starting analysis for: <uuid>
📊 Analytics Event: scan_started
Processing 1 images...
OCR extracted text from image
🚩 Arabic urgency detected
🚩 Arabic bank impersonation detected
⚠️ High risk patterns detected in text
⛔️ Malicious URL detected: bit.ly/verify123
📊 Analytics Event: scan_completed - risk_score: 85
📊 Analytics Event: scan_flagged
```

### ResultView Display

**Risk Header:**
- Circular progress: 85%
- Label: "High Risk" (red)

**Red Flags:**
- arabicUrgency
- arabicBankImpersonation  
- arabicOTP
- urgencyPhrase
- shortlink

**Detected Links:**
- URL: bit.ly/verify123
- Risk: High
- Verdict: Suspicious
- Source: VirusTotal (if API configured)

**Analysis Summary:**
- "OCR extracted text from image"
- "🚩 Arabic urgency detected"
- "🚩 Arabic bank impersonation detected"
- "⚠️ High risk patterns detected"

## 🎯 What to Verify

### ✅ Share Extension
- [ ] Appears in share sheet
- [ ] UI displays correctly
- [ ] Saves files to App Group
- [ ] Opens main app with correct URL

### ✅ OCR Service
- [ ] Recognizes Arabic text
- [ ] Recognizes English text
- [ ] Normalizes text correctly
- [ ] Extracts numbers (123456)

### ✅ Heuristics Service
- [ ] Detects Arabic urgency phrases
- [ ] Detects Arabic bank names
- [ ] Detects Arabic OTP requests
- [ ] Detects English urgency
- [ ] Detects shortlinks
- [ ] Calculates correct risk score

### ✅ Link Intelligence
- [ ] Extracts URLs from text
- [ ] Flags shortlinks
- [ ] Shows risk verdict

### ✅ UI Flow
- [ ] PreviewView shows image
- [ ] AnalyzingView shows progress
- [ ] ResultView displays all data
- [ ] Red flag chips are interactive
- [ ] "Done" button returns to dashboard

## 📸 Screenshots to Capture

Please take screenshots of:

1. **Test View** - showing the selected image
2. **Share Sheet** - showing "Mayyiz" option
3. **Share Extension UI** - the custom UI
4. **PreviewView** - showing the shared image
5. **ResultView** - showing the risk score and red flags
6. **Console logs** - showing the analysis flow

## 🐛 Troubleshooting

### OCR not extracting text?
- Check console for OCR errors
- Verify image quality is good
- Ensure text is clear and readable

### Heuristics not detecting patterns?
- Check that OCR extracted text correctly
- Verify the text contains the expected phrases
- Look for normalization issues

### Share Extension not appearing?
- Rebuild both targets
- Restart simulator
- Check entitlements configuration

## 🎉 Success!

If you see:
- ✅ High risk score (70-100)
- ✅ Multiple red flags detected
- ✅ URLs extracted and analyzed
- ✅ OCR text displayed in findings

Then **everything is working perfectly!** 🚀

---

**Ready to test!** Follow the steps and share your results.
