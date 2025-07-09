#!/bin/bash

# Build script for unified Grab.app bundle
# This script creates a single app bundle containing both the Swift binary and Tauri app

set -e

APP_NAME="Grab"
SWIFT_BINARY_NAME="Grab"
TAURI_APP_NAME="Grab Actions"
BUILD_DIR=".build"
DIST_DIR="dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v swift &> /dev/null; then
        log_error "Swift is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v pnpm &> /dev/null; then
        log_error "pnpm is not installed or not in PATH"
        exit 1
    fi
    
    if [ ! -d "grab-actions" ]; then
        log_error "grab-actions directory not found"
        exit 1
    fi
    
    if [ ! -f "grab-actions/src-tauri/Cargo.toml" ]; then
        log_error "Tauri project not found in grab-actions/src-tauri/"
        exit 1
    fi
    
    log_success "All dependencies found"
}

# Function to clean previous builds
clean_builds() {
    log_info "Cleaning previous builds..."
    
    # Remove existing app bundle
    if [ -d "${APP_NAME}.app" ]; then
        rm -rf "${APP_NAME}.app"
        log_success "Removed existing ${APP_NAME}.app"
    fi
    
    # Clean Swift build
    swift package clean
    rm -rf .build
    
    # Clean Tauri build
    cd grab-actions
    if [ -d "src-tauri/target" ]; then
        rm -rf src-tauri/target
        log_success "Cleaned Tauri build artifacts"
    fi
    
    if [ -d "dist" ]; then
        rm -rf dist
        log_success "Cleaned Tauri dist"
    fi
    cd ..
    
    log_success "Clean completed"
}

# Function to build Swift binary
build_swift() {
    log_info "Building Swift binary..."
    
    # Build for both architectures
    swift build -c release --arch arm64 --arch x86_64
    
    if [ ! -f ".build/release/${SWIFT_BINARY_NAME}" ]; then
        log_error "Swift build failed - binary not found"
        exit 1
    fi
    
    log_success "Swift binary built successfully"
}

# Function to build Tauri app
build_tauri() {
    log_info "Building Tauri app..."
    
    cd grab-actions
    
    # Install dependencies
    log_info "Installing Node.js dependencies..."
    pnpm install
    
    # Build Tauri app
    log_info "Building Tauri bundle..."
    pnpm tauri build
    
    # Check if build was successful
    if [ ! -d "src-tauri/target/release/bundle/macos/${TAURI_APP_NAME}.app" ]; then
        log_error "Tauri build failed - app bundle not found"
        cd ..
        exit 1
    fi
    
    cd ..
    log_success "Tauri app built successfully"
}

# Function to create unified app bundle
create_unified_bundle() {
    log_info "Creating unified app bundle..."
    
    # Create app bundle structure
    mkdir -p "${APP_NAME}.app/Contents/MacOS"
    mkdir -p "${APP_NAME}.app/Contents/Resources"
    
    # Copy Swift binary as main executable
    cp ".build/release/${SWIFT_BINARY_NAME}" "${APP_NAME}.app/Contents/MacOS/"
    log_success "Copied Swift binary to app bundle"
    
    # Copy Tauri app into Resources
    cp -R "grab-actions/src-tauri/target/release/bundle/macos/${TAURI_APP_NAME}.app" "${APP_NAME}.app/Contents/Resources/"
    log_success "Embedded Tauri app in Resources folder"
    
    # Copy Info.plist
    if [ -f "Grab/Resources/Info.plist" ]; then
        cp "Grab/Resources/Info.plist" "${APP_NAME}.app/Contents/Info.plist"
        log_success "Copied Info.plist"
    else
        log_warning "Info.plist not found at Grab/Resources/Info.plist"
    fi
    
    # Make the main binary executable
    chmod +x "${APP_NAME}.app/Contents/MacOS/${SWIFT_BINARY_NAME}"
    
    log_success "Unified app bundle created: ${APP_NAME}.app"
}

# Function to verify the bundle
verify_bundle() {
    log_info "Verifying unified app bundle..."
    
    # Check main executable
    if [ ! -f "${APP_NAME}.app/Contents/MacOS/${SWIFT_BINARY_NAME}" ]; then
        log_error "Main executable missing"
        return 1
    fi
    
    # Check embedded Tauri app
    if [ ! -d "${APP_NAME}.app/Contents/Resources/${TAURI_APP_NAME}.app" ]; then
        log_error "Embedded Tauri app missing"
        return 1
    fi
    
    # Check if Tauri app has proper structure
    if [ ! -f "${APP_NAME}.app/Contents/Resources/${TAURI_APP_NAME}.app/Contents/MacOS/${TAURI_APP_NAME}" ]; then
        log_error "Embedded Tauri app executable missing"
        return 1
    fi
    
    log_success "Bundle verification passed"
    
    # Print bundle information
    echo ""
    log_info "Bundle structure:"
    echo "📁 ${APP_NAME}.app/"
    echo "  📁 Contents/"
    echo "    📁 MacOS/"
    echo "      📄 ${SWIFT_BINARY_NAME} (main executable)"
    echo "    📁 Resources/"
    echo "      📁 ${TAURI_APP_NAME}.app/ (embedded Tauri app)"
    echo "    📄 Info.plist"
    echo ""
    
    # Show bundle size
    BUNDLE_SIZE=$(du -sh "${APP_NAME}.app" | cut -f1)
    log_info "Bundle size: ${BUNDLE_SIZE}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --clean-only    Only clean builds, don't build"
    echo "  --no-clean      Skip cleaning step"
    echo "  --swift-only    Only build Swift binary"
    echo "  --tauri-only    Only build Tauri app"
    echo "  --help          Show this help message"
    echo ""
    echo "This script builds a unified Grab.app bundle containing both:"
    echo "  • Swift binary as the main executable"
    echo "  • Tauri app embedded in Resources folder"
}

# Main build process
main() {
    local clean_only=false
    local no_clean=false
    local swift_only=false
    local tauri_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean-only)
                clean_only=true
                shift
                ;;
            --no-clean)
                no_clean=true
                shift
                ;;
            --swift-only)
                swift_only=true
                shift
                ;;
            --tauri-only)
                tauri_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo ""
    log_info "🏗️  Building unified Grab.app bundle"
    echo ""
    
    check_dependencies
    
    if [ "$no_clean" = false ]; then
        clean_builds
    fi
    
    if [ "$clean_only" = true ]; then
        log_success "Clean completed. Exiting."
        exit 0
    fi
    
    if [ "$tauri_only" = false ]; then
        build_swift
    fi
    
    if [ "$swift_only" = false ]; then
        build_tauri
    fi
    
    if [ "$swift_only" = false ] && [ "$tauri_only" = false ]; then
        create_unified_bundle
        verify_bundle
        
        echo ""
        log_success "🎉 Unified build completed!"
        log_info "You can now run: open ${APP_NAME}.app"
        log_info "Or install with: make install-unified"
    fi
}

# Run main function with all arguments
main "$@"