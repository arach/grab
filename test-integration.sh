#!/bin/bash

# Grab Integration Test Script
# Tests the integration between the Swift Grab app and Tauri viewer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🧪 Grab Integration Test"
echo "======================="
echo ""

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

# Check prerequisites
log_info "Checking prerequisites..."

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    log_error "Swift not found. Please install Xcode Command Line Tools."
    exit 1
fi

# Check if pnpm is available
if command -v pnpm &> /dev/null; then
    PACKAGE_MANAGER="pnpm"
elif command -v npm &> /dev/null; then
    PACKAGE_MANAGER="npm"
else
    log_error "Neither pnpm nor npm found. Please install Node.js first."
    exit 1
fi

# Check if Rust is available
if ! command -v rustc &> /dev/null; then
    log_error "Rust not found. Please install Rust first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

log_success "Prerequisites check passed"
echo ""

# Build Swift app
log_info "Building Swift Grab app..."
make clean
make build

if [ ! -f ".build/release/Grab" ]; then
    log_error "Swift build failed - executable not found"
    exit 1
fi

log_success "Swift app built successfully"
echo ""

# Build Tauri app
log_info "Building Tauri viewer app..."
cd grab-actions

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    log_info "Installing Node.js dependencies..."
    $PACKAGE_MANAGER install
fi

# Build Tauri app
log_info "Building Tauri app..."
$PACKAGE_MANAGER tauri build

if [ ! -d "src-tauri/target/release/bundle/macos/Grab Actions.app" ]; then
    log_error "Tauri build failed - app bundle not found"
    exit 1
fi

log_success "Tauri app built successfully"
cd ..
echo ""

# Test the integration
log_info "Starting integration test..."

# Start the Swift app in background
log_info "Starting Swift Grab app in background..."
.build/release/Grab &
SWIFT_PID=$!

# Give it a moment to start
sleep 2

# Check if the app is running
if ! kill -0 $SWIFT_PID 2>/dev/null; then
    log_error "Swift app failed to start"
    exit 1
fi

log_success "Swift app started (PID: $SWIFT_PID)"

# Function to cleanup
cleanup() {
    log_info "Cleaning up..."
    if kill -0 $SWIFT_PID 2>/dev/null; then
        log_info "Stopping Swift app..."
        kill $SWIFT_PID
        wait $SWIFT_PID 2>/dev/null || true
    fi
    log_success "Cleanup completed"
}

# Set trap to cleanup on exit
trap cleanup EXIT

echo ""
log_info "Manual Testing Instructions:"
echo "=============================="
echo ""
echo "1. Take a screenshot using the Grab app (Cmd+Shift+4 or menu bar)"
echo "2. The screenshot should be saved and a notification should appear"
echo "3. Check the ~/Library/Application Support/Grab/captures directory"
echo "4. Note the capture ID from the filename (e.g., 'capture_12345.png')"
echo ""
echo "5. Test the Tauri viewer by running:"
echo "   cd grab-actions"
echo "   $PACKAGE_MANAGER tauri dev"
echo ""
echo "6. In the Tauri app, you should see the captured screenshot"
echo "7. Test the command line argument by running:"
echo "   open './grab-actions/src-tauri/target/release/bundle/macos/Grab Actions.app' --args --capture-id=CAPTURE_ID"
echo ""

# Check if captures directory exists
CAPTURES_DIR="$HOME/Library/Application Support/Grab/captures"
if [ -d "$CAPTURES_DIR" ]; then
    log_success "Captures directory exists: $CAPTURES_DIR"
    
    # List recent captures
    RECENT_CAPTURES=$(find "$CAPTURES_DIR" -name "*.png" -mtime -1 | head -5)
    if [ -n "$RECENT_CAPTURES" ]; then
        log_info "Recent captures found:"
        echo "$RECENT_CAPTURES" | while read -r capture; do
            basename=$(basename "$capture" .png)
            capture_id=${basename#capture_}
            echo "  📸 $capture (ID: $capture_id)"
        done
        echo ""
        
        # Get the most recent capture
        LATEST_CAPTURE=$(find "$CAPTURES_DIR" -name "*.png" -mtime -1 | head -1)
        if [ -n "$LATEST_CAPTURE" ]; then
            LATEST_ID=$(basename "$LATEST_CAPTURE" .png | sed 's/capture_//')
            echo "🔗 Test command line argument with latest capture:"
            echo "   open './grab-actions/src-tauri/target/release/bundle/macos/Grab Actions.app' --args --capture-id=$LATEST_ID"
            echo ""
        fi
    else
        log_warning "No recent captures found. Take a screenshot to test the integration."
    fi
else
    log_warning "Captures directory doesn't exist yet. Take a screenshot to create it."
fi

echo ""
log_info "Integration test setup complete!"
echo ""
echo "Next steps:"
echo "1. Take a screenshot using the Grab app"
echo "2. Start the Tauri viewer: cd grab-actions && $PACKAGE_MANAGER tauri dev"
echo "3. Test the command line argument functionality"
echo ""
echo "Press any key to continue or Ctrl+C to exit..."
read -n 1 -s

log_info "Test completed successfully!"