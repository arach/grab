#!/bin/bash

# Resume the auto-reload watch system

PAUSE_FILE=".watch-pause"
BUILD_FLAG=".watch-build-on-resume"

if [ ! -f "$PAUSE_FILE" ]; then
    echo "▶️  Watch is not paused"
else
    rm -f "$PAUSE_FILE"
    
    # Create a flag to trigger rebuild
    touch "$BUILD_FLAG"
    
    echo "▶️  Watch resumed - auto-reload enabled"
    echo "🔨 Triggering rebuild..."
    
    # Touch a Swift file to trigger rebuild
    touch Grab/AppDelegate.swift
    
    # Clean up flag after a moment
    (sleep 2 && rm -f "$BUILD_FLAG") &
fi