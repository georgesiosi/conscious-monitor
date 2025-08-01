#!/bin/bash

# ConsciousMonitor DMG Creator Script
# This script creates a distributable DMG file for ConsciousMonitor

# Configuration
APP_NAME="ConsciousMonitor"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"
SOURCE_APP_PATH=""  # Will be set based on finding the app

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 ConsciousMonitor DMG Creator"
echo "=========================="

# Function to find the exported app
find_app() {
    # Common locations to check
    local locations=(
        "$HOME/Desktop/${APP_NAME}.app"
        "$HOME/Downloads/${APP_NAME}.app"
        "./dist/${APP_NAME}.app"
        "./${APP_NAME}.app"
        "./build/Release/${APP_NAME}.app"
        "./DerivedData/*/Build/Products/Release/${APP_NAME}.app"
    )
    
    for loc in "${locations[@]}"; do
        if [ -d "$loc" ]; then
            SOURCE_APP_PATH="$loc"
            return 0
        fi
    done
    
    # If not found, ask user
    echo -e "${YELLOW}Could not find ${APP_NAME}.app automatically.${NC}"
    echo "Please enter the full path to your exported ${APP_NAME}.app:"
    read -r user_path
    
    if [ -d "$user_path" ]; then
        SOURCE_APP_PATH="$user_path"
        return 0
    else
        echo -e "${RED}Error: App not found at specified path${NC}"
        return 1
    fi
}

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}create-dmg is not installed. Installing via Homebrew...${NC}"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Error: Homebrew is not installed.${NC}"
        echo "Please install Homebrew first: https://brew.sh"
        exit 1
    fi
    
    brew install create-dmg
fi

# Find the app
echo "🔍 Looking for ${APP_NAME}.app..."
if ! find_app; then
    exit 1
fi

echo -e "${GREEN}✓ Found app at: ${SOURCE_APP_PATH}${NC}"

# Create dist directory if it doesn't exist
mkdir -p dist

# Remove old DMG if it exists
if [ -f "dist/${DMG_NAME}" ]; then
    echo "🗑  Removing old DMG..."
    rm -f "dist/${DMG_NAME}"
fi

# Create temporary directory for DMG contents
echo "📦 Creating DMG..."

# Check if app has an icon
ICON_PATH="${SOURCE_APP_PATH}/Contents/Resources/AppIcon.icns"
if [ ! -f "$ICON_PATH" ]; then
    echo -e "${YELLOW}Warning: AppIcon.icns not found. DMG will use default icon.${NC}"
    ICON_PATH=""
fi

# Create DMG with or without custom icon
if [ -n "$ICON_PATH" ]; then
    create-dmg \
        --volname "${VOLUME_NAME}" \
        --volicon "${ICON_PATH}" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 150 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 150 \
        --no-internet-enable \
        "dist/${DMG_NAME}" \
        "${SOURCE_APP_PATH}"
else
    create-dmg \
        --volname "${VOLUME_NAME}" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 150 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 150 \
        --no-internet-enable \
        "dist/${DMG_NAME}" \
        "${SOURCE_APP_PATH}"
fi

# Check if DMG was created successfully
if [ -f "dist/${DMG_NAME}" ]; then
    echo -e "${GREEN}✅ DMG created successfully!${NC}"
    echo -e "${GREEN}📍 Location: $(pwd)/dist/${DMG_NAME}${NC}"
    
    # Get file size
    SIZE=$(du -h "dist/${DMG_NAME}" | cut -f1)
    echo -e "${GREEN}📏 Size: ${SIZE}${NC}"
    
    echo ""
    echo "🎉 Next steps:"
    echo "1. Test the DMG by double-clicking it"
    echo "2. Upload to GitHub Releases or your distribution platform"
    echo "3. Share the download link with users"
else
    echo -e "${RED}❌ Error: DMG creation failed${NC}"
    exit 1
fi
