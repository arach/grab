# Makefile for Grab macOS Menu Bar App

APP_NAME = Grab
SWIFT_BUILD_FLAGS = -c release
BUILD_PATH = .build/release
INSTALL_PATH = /Applications

.PHONY: build run clean release install uninstall help bundle app dev

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
	# Check for universal binary first, fallback to regular build path
	if [ -f .build/apple/Products/Release/$(APP_NAME) ]; then \
		cp .build/apple/Products/Release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	else \
		cp $(BUILD_PATH)/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/; \
	fi
	cp Grab/Resources/Info.plist $(APP_NAME).app/Contents/Info.plist
	@echo "App bundle created: $(APP_NAME).app"

# Create app bundle (alias for bundle)
app: bundle

# Development mode - smart incremental build and run with console output
dev:
	@echo "🔍 Checking for changes..."
	@# Check if we need to rebuild by comparing source files to binary
	@if [ ! -f $(APP_NAME).app/Contents/MacOS/$(APP_NAME) ] || \
	   [ -n "$$(find Grab -name '*.swift' -newer $(APP_NAME).app/Contents/MacOS/$(APP_NAME) 2>/dev/null)" ]; then \
		echo "🔨 Changes detected, rebuilding..."; \
		$(MAKE) app; \
	else \
		echo "✅ No changes detected, using existing build"; \
	fi
	@echo "🚀 Launching Grab in development mode..."
	@echo "📋 Console output will appear below:"
	@echo "-----------------------------------"
	@$(APP_NAME).app/Contents/MacOS/$(APP_NAME)

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









# Help
help:
	@echo "Available targets:"
	@echo "  build       - Build the application"
	@echo "  run         - Build and run the application"
	@echo "  release     - Build optimized release version"
	@echo "  clean       - Clean build artifacts"
	@echo "  bundle      - Create app bundle"
	@echo "  app         - Create app bundle (alias for bundle)"
	@echo "  dev         - Build and run with console output"
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