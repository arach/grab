#!/bin/bash

# Simple script to build a clean Grab.app

set -e

echo "🧹 Cleaning previous build..."
rm -rf Grab.app

echo "🚀 Building Grab.app..."
make unified

echo "✅ Done! Grab.app is ready."
ls -lah Grab.app