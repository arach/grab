#!/bin/bash

# Quick release script for Grab
# Builds and creates a ZIP file ready for GitHub release

set -e

VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0")}"

echo "🚀 Building Grab v${VERSION}..."

# Build unified app
make unified

# Create release directory
mkdir -p release

# Create ZIP
echo "📦 Creating ZIP archive..."
zip -r -y "release/Grab-${VERSION}.zip" Grab.app

# Generate checksum
cd release
shasum -a 256 "Grab-${VERSION}.zip" > "Grab-${VERSION}.zip.sha256"
cd ..

echo "✅ Done! Release file: release/Grab-${VERSION}.zip"
echo ""
echo "To upload to GitHub:"
echo "  gh release upload v${VERSION} release/Grab-${VERSION}.zip"