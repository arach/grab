# Makefile for Grab macOS Menu Bar App

APP_NAME = Grab
SWIFT_BUILD_FLAGS = -c release
BUILD_PATH = .build/release
INSTALL_PATH = /Applications

.PHONY: build run clean release install uninstall help bundle app unified unified-dev unified-quick clean-unified watch-dev

# Default target
all: build

# Build the application
build:
	@echo "Building $(APP_NAME)..."
	swift build $(SWIFT_BUILD_FLAGS)
	@echo "Build completed!"

# Run the application
run: build
	@echo "Running $(APP_NAME)..."
	$(BUILD_PATH)/$(APP_NAME)

# Build for release (optimized)
release:
	@echo "Building $(APP_NAME) for release..."
	swift build -c release --arch arm64 --arch x86_64
	@echo "Release build completed!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	@echo "Clean completed!"

# Create app bundle (for distribution)
bundle: release
	@echo "Creating app bundle..."
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/
	cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	@echo "App bundle created: $(APP_NAME).app"

# Create app bundle (alias for bundle)
app: bundle

# Install to Applications folder
install: bundle
	@echo "Installing $(APP_NAME) to $(INSTALL_PATH)..."
	sudo cp -R $(APP_NAME).app $(INSTALL_PATH)/
	@echo "Installation completed!"

# Uninstall from Applications folder
uninstall:
	@echo "Uninstalling $(APP_NAME)..."
	sudo rm -rf $(INSTALL_PATH)/$(APP_NAME).app
	@echo "Uninstallation completed!"

# Debug build
debug:
	@echo "Building $(APP_NAME) in debug mode..."
	swift build
	@echo "Debug build completed!"

# Run tests
test:
	@echo "Running tests..."
	swift test
	@echo "Tests completed!"

# Format code
format:
	@echo "Formatting Swift code..."
	swift-format -i -r Grab/
	@echo "Code formatting completed!"

# Lint code
lint:
	@echo "Linting Swift code..."
	swiftlint lint
	@echo "Linting completed!"

# Generate Xcode project
xcode:
	@echo "Generating Xcode project..."
	swift package generate-xcodeproj
	@echo "Xcode project generated!"

# Check dependencies
deps:
	@echo "Checking dependencies..."
	swift package show-dependencies
	@echo "Dependencies check completed!"

# Update dependencies
update:
	@echo "Updating dependencies..."
	swift package update
	@echo "Dependencies updated!"

# Package info
info:
	@echo "Package Information:"
	@echo "  Name: $(APP_NAME)"
	@echo "  Build Path: $(BUILD_PATH)"
	@echo "  Install Path: $(INSTALL_PATH)"
	@echo "  Swift Version: $(shell swift --version | head -n1)"

# Build unified app bundle with embedded Tauri app (full clean build)
unified: clean-unified
	@$(MAKE) unified-quick

# Quick unified build (no clean, incremental)
unified-quick:
	@echo "🏗️  Building unified Grab.app with embedded Tauri app..."
	
	# Build Swift app
	@echo "📦 Building Swift binary..."
	swift build -c release --arch arm64 --arch x86_64
	
	# Build Tauri app
	@echo "🦀 Building Tauri app..."
	cd grab-actions && pnpm install && pnpm tauri build
	
	# Create unified app bundle structure
	@echo "🔧 Creating unified app bundle..."
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	
	# Copy Swift binary as main executable
	# Check for universal binary first, fallback to regular build path
	if [ -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		cp .build/apple/Products/Release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	else \
		cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	fi
	
	# Copy Tauri app into Resources
	cp -R grab-actions/src-tauri/target/release/bundle/macos/Grab\ Actions.app $(APP_NAME).app/Contents/Resources/
	
	# Copy and update Info.plist
	cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	
	@echo "✅ Unified app bundle created: $(APP_NAME).app"
	@echo "   📍 Swift binary: $(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	@echo "   📍 Tauri app: $(APP_NAME).app/Contents/Resources/Grab Actions.app"

# Development unified build (debug Tauri, incremental)
unified-dev:
	@echo "🏗️  Building unified Grab.app (development mode)..."
	
	# Build Swift app
	@echo "📦 Building Swift binary..."
	swift build -c release --arch arm64 --arch x86_64
	
	# Build Tauri app in debug mode (faster)
	@echo "🦀 Building Tauri app (debug mode)..."
	cd grab-actions && pnpm install && pnpm tauri:build-dev
	
	# Create unified app bundle structure
	@echo "🔧 Creating unified app bundle..."
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	
	# Copy Swift binary as main executable
	# Check for universal binary first, fallback to regular build path
	if [ -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		cp .build/apple/Products/Release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	else \
		cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	fi
	
	# Copy Tauri debug app into Resources
	cp -R grab-actions/src-tauri/target/debug/bundle/macos/Grab\ Actions.app $(APP_NAME).app/Contents/Resources/
	
	# Copy and update Info.plist
	cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	
	@echo "✅ Development unified app bundle created: $(APP_NAME).app"
	@echo "   📍 Swift binary: $(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	@echo "   📍 Tauri app (debug): $(APP_NAME).app/Contents/Resources/Grab Actions.app"
	@echo "🚀 Launching app..."
	open $(APP_NAME).app

# Development unified build with console logs
unified-dev-logs:
	@echo "🏗️  Building unified Grab.app (development mode with logs)..."
	
	# Build Swift app
	@echo "📦 Building Swift binary..."
	swift build -c release --arch arm64 --arch x86_64
	
	# Build Tauri app in debug mode (faster)
	@echo "🦀 Building Tauri app (debug mode)..."
	cd grab-actions && pnpm install && pnpm tauri:build-dev
	
	# Create unified app bundle structure
	@echo "🔧 Creating unified app bundle..."
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	
	# Copy Swift binary as main executable
	# Check for universal binary first, fallback to regular build path
	if [ -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		cp .build/apple/Products/Release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	else \
		cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	fi
	
	# Copy Tauri debug app into Resources
	cp -R grab-actions/src-tauri/target/debug/bundle/macos/Grab\ Actions.app $(APP_NAME).app/Contents/Resources/
	
	# Copy and update Info.plist
	cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	
	@echo "✅ Development unified app bundle created: $(APP_NAME).app"
	@echo "   📍 Swift binary: $(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	@echo "   📍 Tauri app (debug): $(APP_NAME).app/Contents/Resources/Grab Actions.app"
	@echo "🚀 Launching app with console logs..."
	$(APP_NAME).app/Contents/MacOS/$(APP_NAME)

# Incremental build - only rebuild what changed
unified-inc:
	@echo "⚡ Incremental unified build..."
	
	# Only rebuild Swift if source files changed
	@if [ Grab/ -nt .build/apple/Products/Release/$(APP_NAME) ] 2>/dev/null || [ ! -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		echo "📦 Rebuilding Swift binary..."; \
		swift build -c release --arch arm64 --arch x86_64; \
	else \
		echo "📦 Swift binary up to date"; \
	fi
	
	# Only rebuild Tauri if source files changed
	@if [ grab-actions/src/ -nt grab-actions/src-tauri/target/release/bundle/macos/Grab\ Actions.app ] 2>/dev/null || [ ! -d "grab-actions/src-tauri/target/release/bundle/macos/Grab Actions.app" ]; then \
		echo "🦀 Rebuilding Tauri app..."; \
		cd grab-actions && pnpm install && pnpm tauri build; \
	else \
		echo "🦀 Tauri app up to date"; \
	fi
	
	# Always refresh the app bundle
	@$(MAKE) bundle-only
	@echo "🚀 Launching app..."
	open $(APP_NAME).app

# Just bundle existing builds without rebuilding
bundle-only:
	@echo "📦 Bundling existing builds..."
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	
	# Copy Swift binary
	if [ -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		cp .build/apple/Products/Release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	else \
		cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	fi
	
	# Copy Tauri app (prefer release, fallback to debug)
	if [ -d "grab-actions/src-tauri/target/release/bundle/macos/Grab Actions.app" ]; then \
		cp -R grab-actions/src-tauri/target/release/bundle/macos/Grab\ Actions.app $(APP_NAME).app/Contents/Resources/; \
	else \
		cp -R grab-actions/src-tauri/target/debug/bundle/macos/Grab\ Actions.app $(APP_NAME).app/Contents/Resources/; \
	fi
	
	# Copy Info.plist
	cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	
	@echo "✅ App bundle updated: $(APP_NAME).app"

# Clean unified build artifacts
clean-unified:
	@echo "🧹 Cleaning unified build artifacts..."
	rm -rf $(APP_NAME).app
	rm -rf grab-actions/src-tauri/target
	rm -rf grab-actions/dist
	swift package clean
	rm -rf .build

# Install unified app
install-unified: unified
	@echo "📲 Installing unified $(APP_NAME) to $(INSTALL_PATH)..."
	sudo cp -R $(APP_NAME).app $(INSTALL_PATH)/
	@echo "✅ Unified installation completed!"

# Watch mode for development - auto recompile and restart on file changes
watch-dev:
	@echo "🔄 Starting watch mode for development..."
	@echo "   Watching for changes in Grab/ and grab-actions/src/"
	@echo "   Press Ctrl+C to stop watching"
	@echo ""
	@while true; do \
		$(MAKE) watch-dev-cycle; \
		echo ""; \
		echo "🔄 Waiting for file changes... (Press Ctrl+C to stop)"; \
		echo "   Watching: Grab/ and grab-actions/src/"; \
		fswatch -1 -r Grab/ grab-actions/src/ 2>/dev/null || { \
			echo ""; \
			echo "⚠️  fswatch not found. Installing via Homebrew..."; \
			brew install fswatch; \
			echo "✅ fswatch installed. Restarting watch mode..."; \
			fswatch -1 -r Grab/ grab-actions/src/; \
		}; \
		echo ""; \
		echo "📝 File change detected! Rebuilding and restarting..."; \
		pkill -f "$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true; \
		sleep 1; \
	done

# Internal target for watch mode cycle
watch-dev-cycle:
	@echo "🏗️  Building unified Grab.app (watch mode)..."
	
	# Build Swift app
	@echo "📦 Building Swift binary..."
	@swift build -c release --arch arm64 --arch x86_64 || { \
		echo "❌ Swift build failed"; \
		exit 1; \
	}
	
	# Build Tauri app in debug mode (faster)
	@echo "🦀 Building Tauri app (debug mode)..."
	@cd grab-actions && pnpm install --silent && pnpm tauri:build-dev || { \
		echo "❌ Tauri build failed"; \
		exit 1; \
	}
	
	# Create unified app bundle structure
	@echo "🔧 Creating unified app bundle..."
	@mkdir -p $(APP_NAME).app/Contents/MacOS
	@mkdir -p $(APP_NAME).app/Contents/Resources
	
	# Copy Swift binary as main executable
	@if [ -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		cp .build/apple/Products/Release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	else \
		cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	fi
	
	# Copy Tauri debug app into Resources
	@cp -R grab-actions/src-tauri/target/debug/bundle/macos/Grab\ Actions.app $(APP_NAME).app/Contents/Resources/
	
	# Copy and update Info.plist
	@cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	
	@echo "✅ Development unified app bundle created: $(APP_NAME).app"
	@echo "🚀 Launching app with logs..."
	@echo "   📍 Swift binary: $(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	@echo "   📍 Tauri app (debug): $(APP_NAME).app/Contents/Resources/Grab Actions.app"
	@echo ""
	@$(APP_NAME).app/Contents/MacOS/$(APP_NAME) &

# Help
help:
	@echo "Available targets:"
	@echo "  build       - Build the application"
	@echo "  run         - Build and run the application"
	@echo "  release     - Build optimized release version"
	@echo "  clean       - Clean build artifacts"
	@echo "  bundle      - Create app bundle"
	@echo "  app         - Create app bundle (alias for bundle)"
	@echo "  unified     - Build unified app with embedded Tauri app (full clean)"
	@echo "  unified-dev - Build unified app (debug Tauri, faster)"
	@echo "  unified-dev-logs - Build unified app with console logs visible"
	@echo "  watch-dev   - Watch mode: auto recompile and restart on file changes"
	@echo "  unified-inc - Incremental build (only rebuild what changed)"
	@echo "  bundle-only - Just bundle existing builds without rebuilding"
	@echo "  clean-unified - Clean unified build artifacts"
	@echo "  install-unified - Install unified app to Applications"
	@echo "  install     - Install to Applications folder"
	@echo "  uninstall   - Remove from Applications folder"
	@echo "  debug       - Build in debug mode"
	@echo "  test        - Run tests"
	@echo "  format      - Format Swift code"
	@echo "  lint        - Lint Swift code"
	@echo "  xcode       - Generate Xcode project"
	@echo "  deps        - Show dependencies"
	@echo "  update      - Update dependencies"
	@echo "  info        - Show package information"
	@echo "  help        - Show this help message"