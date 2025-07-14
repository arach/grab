#!/bin/bash

# Kill any existing Grab process
killall Grab 2>/dev/null

# Small delay to ensure clean shutdown
sleep 0.5

# Run the release build
echo "🚀 Starting Grab with Command Center..."
.build/release/Grab