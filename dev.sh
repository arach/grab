#!/bin/bash

# Development script with auto-reload for Grab app
# Requires: fswatch (brew install fswatch)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# PID file for the running app
PID_FILE=".grab.pid"
PAUSE_FILE=".watch-pause"

# Function to kill the running app
kill_app() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo -e "${YELLOW}🛑 Stopping Grab (PID: $PID)...${NC}"
            kill "$PID" 2>/dev/null || true
            # Also kill by name as backup
            killall Grab 2>/dev/null || true
            sleep 0.5
        fi
        rm -f "$PID_FILE"
    else
        # Kill any running instances
        killall Grab 2>/dev/null || true
    fi
}

# Function to build the app
build_app() {
    echo -e "${BLUE}🔨 Building Grab...${NC}"
    if make build; then
        echo -e "${GREEN}✅ Build successful!${NC}"
        return 0
    else
        echo -e "${RED}❌ Build failed!${NC}"
        return 1
    fi
}

# Function to start the app
start_app() {
    kill_app
    echo -e "${GREEN}🚀 Starting Grab...${NC}"
    .build/release/Grab &
    echo $! > "$PID_FILE"
    echo -e "${GREEN}✅ Grab started (PID: $(cat $PID_FILE))${NC}"
}

# Function to handle file changes
on_change() {
    # Check if paused
    if [ -f "$PAUSE_FILE" ]; then
        echo -e "${CYAN}⏸️  Auto-reload paused. Changes detected but not rebuilding.${NC}"
        return
    fi
    
    echo -e "${YELLOW}📝 Detected changes, rebuilding...${NC}"
    if build_app; then
        start_app
    fi
}

# Cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    kill_app
    rm -f "$PID_FILE" "$PAUSE_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

# Initial build and start
echo -e "${BLUE}🚀 Starting development mode...${NC}"
if build_app; then
    start_app
else
    echo -e "${RED}❌ Initial build failed. Please fix errors and save a file to retry.${NC}"
fi

# Watch for changes
echo -e "${BLUE}👀 Watching for changes...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo -e "${CYAN}Tip: Create '.watch-pause' file to pause auto-reload${NC}\n"

# Watch Swift files and rebuild on changes
fswatch -o \
    --exclude '\.build' \
    --exclude '\.git' \
    --exclude '\.DS_Store' \
    --include '\.swift$' \
    --include 'Info\.plist$' \
    Grab/ | while read change; do
    on_change
done