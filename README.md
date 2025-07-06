# Grab

A lightweight macOS menu bar app for capturing screenshots and managing clipboard content.

## Features

- **Screenshot Capture**: Capture full screen, windows, or selections
- **Clipboard Management**: Save clipboard content (text, images, URLs) to files
- **Menu Bar Integration**: Clean menu bar interface with "-‿¬" icon
- **Hotkey Support**: Global keyboard shortcuts for quick access
- **Automatic Organization**: Saves captures to `~/Library/Application Support/Grab/captures/`
- **Capture History**: Tracks all captures with metadata and timestamps

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd grab
   ```

2. Build the app:
   ```bash
   make build
   ```

3. Run the app:
   ```bash
   make run
   ```

### Swift Package Manager

You can also build directly using Swift Package Manager:

```bash
swift build -c release
```

## Usage

### Menu Bar

Click the "-‿¬" icon in the menu bar to access:

- **Capture Screen** (⌘⇧S): Capture the entire screen
- **Capture Window** (⌘⇧W): Capture a specific window
- **Capture Selection** (⌘⇧A): Capture a selected area
- **Save Clipboard** (⌘⇧C): Save current clipboard content
- **Open Captures Folder**: Open the folder containing all captures
- **Quit Grab**: Exit the application

### Hotkeys

- **⌘⇧S**: Capture full screen
- **⌘⇧W**: Capture window
- **⌘⇧A**: Capture selection
- **⌘⇧C**: Save clipboard content

### Capture Storage

All captures are saved to:
```
~/Library/Application Support/Grab/captures/
```

Files are named with timestamps and organized by capture type:
- `screen_2024-01-15_14-30-25.png`
- `window_2024-01-15_14-31-10.png`
- `selection_2024-01-15_14-32-45.png`
- `clipboard_2024-01-15_14-33-20.txt`

## Permissions

Grab requires the following macOS permissions:

- **Screen Recording**: To capture screenshots
- **Accessibility**: For global hotkeys
- **Files and Folders**: To save captures

Grant these permissions in System Preferences → Security & Privacy → Privacy.

## Development

### Project Structure

```
Grab/
├── GrabApp.swift           # Main app entry point
├── AppDelegate.swift       # Menu bar and app lifecycle
├── Models/
│   └── Capture.swift       # Data models for captures
├── Managers/
│   ├── CaptureManager.swift # Screenshot and clipboard handling
│   └── HotkeyManager.swift  # Global hotkey management
└── Utilities/
    └── Extensions.swift     # Helper extensions
```

### Build Commands

```bash
# Build the app
make build

# Run the app
make run

# Build for release
make release

# Clean build artifacts
make clean
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Troubleshooting

### App doesn't capture screenshots
- Ensure Screen Recording permission is granted in System Preferences
- Check that the app has Accessibility permission for hotkeys

### Hotkeys not working
- Grant Accessibility permission in System Preferences → Security & Privacy → Privacy → Accessibility
- Restart the app after granting permissions

### Captures not saving
- Check that the app has permission to access the Application Support folder
- Verify disk space is available

## Version History

- **1.0.0**: Initial release
  - Screenshot capture (screen, window, selection)
  - Clipboard management
  - Menu bar integration
  - Global hotkeys
  - Automatic file organization