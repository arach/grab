#!/bin/bash

# Fast development mode inspired by Next.js
# Uses incremental builds and smart caching

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
APP_NAME="Grab"
BUILD_DIR=".build/release"
CACHE_DIR=".build/cache"
PID_FILE=".grab.pid"
LAST_BUILD_FILE="$CACHE_DIR/last_build"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Fast kill function
kill_app() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill -TERM "$PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    killall "$APP_NAME" 2>/dev/null || true
}

# Check if rebuild needed (similar to Next.js's incremental compilation)
needs_rebuild() {
    if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
        return 0
    fi
    
    if [ ! -f "$LAST_BUILD_FILE" ]; then
        return 0
    fi
    
    # Find files modified after last build
    local changed_files=$(find Grab -name "*.swift" -newer "$LAST_BUILD_FILE" 2>/dev/null | head -1)
    
    if [ -n "$changed_files" ]; then
        return 0
    fi
    
    return 1
}

# Smart incremental build
incremental_build() {
    local start_time=$(date +%s)
    
    echo -e "${CYAN}⚡ Fast Refresh${NC} - Compiling..."
    
    # Only rebuild if needed
    if needs_rebuild; then
        if swift build -c release >/tmp/grab_build.log 2>&1; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            touch "$LAST_BUILD_FILE"
            echo -e "${GREEN}✓ Compiled successfully${NC} in ${BOLD}${duration}s${NC}"
            return 0
        else
            echo -e "${RED}✗ Compilation failed${NC}"
            echo -e "${DIM}$(tail -20 /tmp/grab_build.log)${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Using cached build${NC} ${DIM}(no changes detected)${NC}"
        return 0
    fi
}

# Hot reload
hot_reload() {
    kill_app
    
    if [ -f "$BUILD_DIR/$APP_NAME" ]; then
        "$BUILD_DIR/$APP_NAME" &
        echo $! > "$PID_FILE"
        echo -e "${GREEN}✓ Ready${NC} - started ${BOLD}$APP_NAME${NC} (pid: $(cat $PID_FILE))"
    fi
}

# File change handler
on_change() {
    local file=$1
    local relative_file=${file#$PWD/}
    
    echo -e "\n${CYAN}⚡ Fast Refresh${NC} - ${DIM}$relative_file${NC} changed"
    
    if incremental_build; then
        hot_reload
    fi
}

# Cleanup
cleanup() {
    echo -e "\n${YELLOW}○ Stopping...${NC}"
    kill_app
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

# Header
clear
echo -e "${CYAN}   ▲ Grab Dev Server${NC}"
echo -e "  ${DIM}- Fast Refresh enabled${NC}"
echo -e "  ${DIM}- Watching for file changes${NC}"
echo -e "  ${DIM}- Press Ctrl+C to stop${NC}\n"

# Initial build and start
if incremental_build; then
    hot_reload
fi

# Watch for changes (using fswatch for performance)
if command -v fswatch &> /dev/null; then
    fswatch -o \
        --event Created --event Updated --event Renamed \
        --exclude '\.build' \
        --exclude '\.git' \
        --include '\.swift$' \
        Grab/ | while read change; do
        
        # Get the actual changed file
        changed_file=$(fswatch -1 --format '%p' \
            --exclude '\.build' \
            --exclude '\.git' \
            --include '\.swift$' \
            Grab/ 2>/dev/null | head -1)
        
        on_change "$changed_file"
    done
else
    echo -e "${RED}✗ Error:${NC} fswatch not found"
    echo -e "  Install with: ${CYAN}brew install fswatch${NC}"
    exit 1
fi