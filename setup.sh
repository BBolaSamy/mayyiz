#!/bin/bash

# Mayyiz Xcode Workspace Quick Setup Script
# This script helps automate some of the setup tasks

set -e

echo "🚀 Mayyiz Workspace Setup Helper"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Mayyiz.xcworkspace/contents.xcworkspacedata" ]; then
    echo "❌ Error: Please run this script from the Mayyiz project root directory"
    exit 1
fi

echo -e "${BLUE}Step 1: Verifying workspace structure...${NC}"
if [ -d "Mayyiz.xcworkspace" ]; then
    echo "✅ Workspace exists"
else
    echo "❌ Workspace not found"
    exit 1
fi

if [ -d "Mayyiz" ]; then
    echo "✅ Main app folder exists"
else
    echo "❌ Main app folder not found"
    exit 1
fi

if [ -d "MayyizShareExtension" ]; then
    echo "✅ Share Extension folder exists"
else
    echo "❌ Share Extension folder not found"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Verifying configuration files...${NC}"

files=(
    "Mayyiz/Info.plist"
    "Mayyiz/Mayyiz.entitlements"
    "MayyizShareExtension/Info.plist"
    "MayyizShareExtension/MayyizShareExtension.entitlements"
    "Mayyiz/Sources/SharedContainer.swift"
    "MayyizShareExtension/Sources/ShareViewController.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file not found"
    fi
done

echo ""
echo -e "${BLUE}Step 3: Project Configuration Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Main App Target:"
echo "   - Name: Mayyiz"
echo "   - Bundle ID: com.mayyiz.app"
echo "   - iOS Deployment: 16.0+"
echo "   - URL Scheme: mayyiz://"
echo ""
echo "🔗 Share Extension Target:"
echo "   - Name: MayyizShareExtension"
echo "   - Bundle ID: com.mayyiz.app.share"
echo "   - iOS Deployment: 16.0+"
echo ""
echo "🔐 App Group:"
echo "   - Identifier: group.com.mayyiz.shared"
echo "   - Used by: Both targets"
echo ""
echo "📦 Firebase Packages (to be added):"
echo "   - FirebaseAuth"
echo "   - FirebaseFirestore"
echo "   - FirebaseFunctions"
echo "   - FirebaseStorage"
echo "   - FirebaseRemoteConfig"
echo "   - FirebaseCrashlytics"
echo "   - FirebaseAppCheck"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}⚠️  Manual Steps Required in Xcode:${NC}"
echo ""
echo "1. Open the workspace:"
echo "   ${GREEN}open Mayyiz.xcworkspace${NC}"
echo ""
echo "2. Configure targets (see SETUP_GUIDE.md for details):"
echo "   - Set bundle identifiers"
echo "   - Enable App Groups capability"
echo "   - Add entitlements files"
echo "   - Create Share Extension target"
echo ""
echo "3. Add Firebase packages:"
echo "   - URL: https://github.com/firebase/firebase-ios-sdk"
echo "   - Select required products"
echo ""
echo "4. Add GoogleService-Info.plist from Firebase Console"
echo ""
echo "5. Build and test!"
echo ""
echo -e "${BLUE}📖 For detailed instructions, see: SETUP_GUIDE.md${NC}"
echo ""

# Ask if user wants to open workspace
read -p "Would you like to open the workspace now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening workspace..."
    open Mayyiz.xcworkspace
fi

echo ""
echo "✨ Setup helper complete!"
