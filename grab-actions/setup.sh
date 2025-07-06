#!/bin/bash

# Grab Viewer Setup Script
# This script helps you install dependencies and run the Grab viewer application

set -e

echo "🔧 Grab Viewer Setup"
echo "===================="

# Check if pnpm is installed
if command -v pnpm &> /dev/null; then
    echo "✅ pnpm found"
    PACKAGE_MANAGER="pnpm"
elif command -v npm &> /dev/null; then
    echo "⚠️  pnpm not found, using npm"
    PACKAGE_MANAGER="npm"
else
    echo "❌ Neither pnpm nor npm found. Please install Node.js first."
    exit 1
fi

# Check if Rust is installed (required for Tauri)
if command -v rustc &> /dev/null; then
    echo "✅ Rust found"
else
    echo "❌ Rust not found. Please install Rust first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
$PACKAGE_MANAGER install

# Check if tauri-cli is available
if ! command -v cargo tauri &> /dev/null; then
    echo "🔧 Installing Tauri CLI..."
    cargo install tauri-cli
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Available commands:"
echo "  $PACKAGE_MANAGER dev           - Start development server"
echo "  $PACKAGE_MANAGER build         - Build for production"
echo "  $PACKAGE_MANAGER tauri dev     - Start Tauri development"
echo "  $PACKAGE_MANAGER tauri build   - Build Tauri app"
echo "  $PACKAGE_MANAGER typecheck     - Run TypeScript checks"
echo "  $PACKAGE_MANAGER lint          - Run ESLint"
echo ""

# Ask if user wants to start development
read -p "Would you like to start the development server now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting development server..."
    $PACKAGE_MANAGER tauri dev
fi