#!/bin/bash

# Grab Release Build Script
# This script builds and packages Grab for distribution

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Grab"
VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0")}"
BUILD_DIR="build"
RELEASE_DIR="release"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

echo -e "${GREEN}🚀 Building ${APP_NAME} v${VERSION} for release${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}" "${RELEASE_DIR}"
mkdir -p "${BUILD_DIR}" "${RELEASE_DIR}"

# Build the unified app
echo -e "${YELLOW}🏗️  Building unified app...${NC}"
make unified

# Copy app to build directory
echo -e "${YELLOW}📦 Preparing app for distribution...${NC}"
cp -R "${APP_NAME}.app" "${BUILD_DIR}/"

# Code signing (optional - uncomment if you have a Developer ID)
# echo -e "${YELLOW}🔏 Code signing...${NC}"
# codesign --force --deep --sign "Developer ID Application: Your Name (TEAMID)" "${BUILD_DIR}/${APP_NAME}.app"
# codesign --verify --deep --strict "${BUILD_DIR}/${APP_NAME}.app"

# Create ZIP archive
echo -e "${YELLOW}🗜️  Creating ZIP archive...${NC}"
cd "${BUILD_DIR}"
zip -r -y "../${RELEASE_DIR}/${ZIP_NAME}" "${APP_NAME}.app"
cd ..

# Create DMG (optional - requires create-dmg)
if command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}💿 Creating DMG...${NC}"
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${APP_NAME}.app/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 175 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 425 190 \
        "${RELEASE_DIR}/${DMG_NAME}" \
        "${BUILD_DIR}/${APP_NAME}.app"
else
    echo -e "${YELLOW}⚠️  create-dmg not found. Install with: brew install create-dmg${NC}"
    echo -e "${YELLOW}   Skipping DMG creation...${NC}"
fi

# Generate checksums
echo -e "${YELLOW}🔐 Generating checksums...${NC}"
cd "${RELEASE_DIR}"
shasum -a 256 "${ZIP_NAME}" > "${ZIP_NAME}.sha256"
if [ -f "${DMG_NAME}" ]; then
    shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256"
fi
cd ..

# Create release notes
echo -e "${YELLOW}📝 Generating release notes...${NC}"
cat > "${RELEASE_DIR}/RELEASE_NOTES.md" << EOF
# ${APP_NAME} v${VERSION}

## Installation

### From ZIP:
1. Download \`${ZIP_NAME}\`
2. Unzip the archive
3. Drag ${APP_NAME}.app to your Applications folder
4. Right-click and select "Open" the first time (macOS Gatekeeper)

### From DMG (if available):
1. Download \`${DMG_NAME}\`
2. Open the DMG
3. Drag ${APP_NAME}.app to the Applications folder
4. Eject the DMG

## Checksums
\`\`\`
$(cat "${RELEASE_DIR}/${ZIP_NAME}.sha256" 2>/dev/null || echo "N/A")
$(cat "${RELEASE_DIR}/${DMG_NAME}.sha256" 2>/dev/null || echo "N/A")
\`\`\`

## System Requirements
- macOS 11.0 or later
- Apple Silicon or Intel processor

---
Built on $(date)
EOF

# Summary
echo -e "${GREEN}✅ Release build completed!${NC}"
echo -e "${GREEN}📁 Release artifacts in: ${RELEASE_DIR}/${NC}"
echo ""
echo "Files created:"
ls -lh "${RELEASE_DIR}/"
echo ""
echo -e "${GREEN}🎉 Ready to upload to GitHub Releases!${NC}"
echo ""
echo "To upload to GitHub:"
echo "  gh release upload v${VERSION} ${RELEASE_DIR}/${ZIP_NAME}"
if [ -f "${RELEASE_DIR}/${DMG_NAME}" ]; then
    echo "  gh release upload v${VERSION} ${RELEASE_DIR}/${DMG_NAME}"
fi