#!/bin/bash

# Simple watch script using entr
# Install: brew install entr

echo "🔄 Auto-rebuild mode (using entr)"
echo "📝 Watching Swift files for changes..."
echo "Press Ctrl+C to stop"

# Find all Swift files and watch them
find Grab -name "*.swift" -o -name "*.plist" | entr -r sh -c 'killall Grab 2>/dev/null; make && .build/release/Grab'