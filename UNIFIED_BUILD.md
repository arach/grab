# Unified Grab.app Build System

This document explains the unified app bundle structure for Grab.app that combines both the Swift menu bar app and the Tauri viewer app into a single distributable bundle.

## Architecture

```
Grab.app/
├── Contents/
│   ├── Info.plist                    # App metadata and permissions
│   ├── MacOS/
│   │   └── Grab                      # Swift binary (main executable)
│   └── Resources/
│       └── Grab Actions.app/         # Embedded Tauri app
│           ├── Contents/
│           │   ├── Info.plist
│           │   ├── MacOS/
│           │   │   └── Grab Actions  # Tauri binary
│           │   └── Resources/
│           └── ...
```

## How It Works

1. **Main App**: The Swift binary (`Grab`) is the main executable that runs when the user launches `Grab.app`
2. **Menu Bar Interface**: The Swift app creates a menu bar icon and handles system-level screenshot capture
3. **Embedded Viewer**: The Tauri app (`Grab Actions.app`) is embedded in the Resources folder
4. **Dynamic Launch**: When the user clicks "Open Grab Viewer", the Swift app launches the embedded Tauri app

## Build Commands

### Quick Build
```bash
make unified
```

### Detailed Build with Script
```bash
./build-unified.sh
```

### Build Options
```bash
./build-unified.sh --help                # Show all options
./build-unified.sh --clean-only          # Only clean, don't build
./build-unified.sh --no-clean           # Skip cleaning step
./build-unified.sh --swift-only         # Only build Swift binary
./build-unified.sh --tauri-only         # Only build Tauri app
```

### Installation
```bash
make install-unified                     # Install to /Applications
```

### Clean Up
```bash
make clean-unified                       # Remove all build artifacts
```

## Benefits

1. **Single Distribution**: One `.app` bundle instead of two separate apps
2. **No External Dependencies**: Tauri app is always available, embedded in the bundle
3. **Simplified Installation**: Users install one app, get both components
4. **Version Synchronization**: Both components are built together, ensuring compatibility
5. **Cleaner Applications Folder**: Only one app icon in Applications

## Development Workflow

### For Swift Development
```bash
# Quick development cycle for Swift changes
swift build && .build/debug/Grab
```

### For Tauri Development
```bash
# Quick development cycle for Tauri changes
cd grab-actions && pnpm tauri dev
```

### For Unified Testing
```bash
# Full unified build and test
./build-unified.sh
open Grab.app
```

## Fallback Strategy

The Swift app uses a prioritized search strategy for finding the Tauri app:

1. **Embedded app** (highest priority): `Contents/Resources/Grab Actions.app`
2. **Development builds**: Local `grab-actions/src-tauri/target/` directories
3. **System installations**: `/Applications/Grab Actions.app`

This ensures the app works in both development and production environments.

## File Structure Changes

### Before (Two Separate Apps)
```
/Applications/
├── Grab.app                     # Swift menu bar app
└── Grab Actions.app            # Tauri viewer app
```

### After (Unified App)
```
/Applications/
└── Grab.app                    # Unified app containing both components
    └── Contents/Resources/
        └── Grab Actions.app    # Embedded Tauri viewer
```

## Troubleshooting

### Build Issues
- Ensure both `swift` and `pnpm` are installed
- Check that `grab-actions` directory exists and has proper Tauri setup
- Run `./build-unified.sh --clean-only` to reset build state

### Runtime Issues
- The Swift app will show detailed logs about Tauri app discovery
- Check Console.app for Grab-related log messages
- Verify embedded app exists: `ls -la Grab.app/Contents/Resources/`

### Performance
- The unified bundle is larger than individual apps
- First launch may be slightly slower due to embedded app detection
- Subsequent launches use cached paths for faster startup