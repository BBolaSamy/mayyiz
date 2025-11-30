#!/bin/bash

# Share Extension Test Helper Script
# This script helps verify the Share Extension setup

echo "🧪 Mayyiz Share Extension Test Helper"
echo "======================================"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must run on macOS"
    exit 1
fi

# Get the simulator ID
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 15" | grep "Booted" | awk -F'[()]' '{print $2}' | head -1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "⚠️  No booted iPhone 15 simulator found"
    echo "Please start a simulator first"
    exit 1
fi

echo "✅ Found booted simulator: $SIMULATOR_ID"
echo ""

# Check App Group container
echo "📁 Checking App Group container..."
APP_GROUP_PATH=$(xcrun simctl get_app_container "$SIMULATOR_ID" group.com.mayyiz.shared 2>/dev/null)

if [ -z "$APP_GROUP_PATH" ]; then
    echo "⚠️  App Group container not found"
    echo "Make sure the app has been run at least once"
else
    echo "✅ App Group path: $APP_GROUP_PATH"
    echo ""
    
    # Check shared directory
    SHARED_DIR="$APP_GROUP_PATH/shared"
    if [ -d "$SHARED_DIR" ]; then
        echo "📂 Contents of shared/ directory:"
        ls -lh "$SHARED_DIR" 2>/dev/null || echo "   (empty)"
    else
        echo "⚠️  shared/ directory doesn't exist yet"
    fi
fi

echo ""
echo "🎯 Testing Instructions:"
echo "========================"
echo ""
echo "1. Make sure Mayyiz app is running on the simulator"
echo "2. Open Safari on the simulator"
echo "3. Navigate to any website"
echo "4. Tap the Share button"
echo "5. Look for 'Mayyiz' in the share sheet"
echo "6. Tap 'Mayyiz' to test the extension"
echo ""
echo "Expected behavior:"
echo "  ✓ Share Extension UI appears"
echo "  ✓ Tap 'Share' button"
echo "  ✓ Main app opens automatically"
echo "  ✓ PreviewView shows the shared content"
echo ""
echo "To monitor logs, run:"
echo "  xcrun simctl spawn booted log stream --predicate 'processImagePath contains \"Mayyiz\"'"
echo ""
