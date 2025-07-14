#!/bin/bash

# Pause the auto-reload watch system

PAUSE_FILE=".watch-pause"

if [ -f "$PAUSE_FILE" ]; then
    echo "⏸️  Watch is already paused"
else
    touch "$PAUSE_FILE"
    echo "⏸️  Watch paused - auto-reload disabled"
    echo "Run './watch-resume.sh' or 'make watch-resume' to resume"
fi