# Grab - Unified Architecture

## Overview

Grab is a unified screenshot and clipboard management application that combines:
- **Swift Menu Bar App**: Native capture engine and system integration
- **Tauri Viewer App**: Modern web-based interface for viewing and managing captures

This architecture provides the best of both worlds: native macOS performance for capturing with a modern, cross-platform interface for management.

## Core Components

### 1. Swift Menu Bar App (Primary)
- **Purpose**: Screen capture, clipboard monitoring, system integration
- **Location**: `Grab/` directory
- **Responsibilities**:
  - Menu bar presence and quick actions
  - Screen capture via native macOS APIs
  - Clipboard monitoring and history
  - File system management (saving captures)
  - Launching and communicating with Tauri viewer

### 2. Tauri Viewer App (Secondary)
- **Purpose**: Rich UI for viewing, organizing, and managing captures
- **Location**: `grab-viewer/` directory
- **Responsibilities**:
  - Gallery view of all captures
  - Search and filtering capabilities
  - Metadata editing and tagging
  - Export and sharing options
  - Advanced viewing features (zoom, annotations)

## Communication Architecture

### Data Flow
```
Swift App → File System → Tauri App
    ↓           ↑           ↓
Menu Bar    Captures/   Web Interface
Actions     Directory   Management
```

### IPC Mechanisms

#### 1. File System Bridge (Primary)
- **Shared Directory**: `~/Library/Application Support/Grab/captures/`
- **Data Format**: JSON metadata + image files
- **Communication**: File system watching on both sides
- **Benefits**: Decoupled, reliable, persistent

#### 2. URL Scheme Communication
- **Swift → Tauri**: Launch with capture ID parameter
- **Format**: `grab-viewer://capture/{id}`
- **Use Case**: Direct navigation to specific captures

#### 3. Optional WebSocket (Future)
- **Purpose**: Real-time updates and live preview
- **Implementation**: Local WebSocket server in Swift app
- **Benefits**: Instant synchronization, live clipboard updates

## Launch Flow

### Initial Launch
1. User starts Swift menu bar app
2. App initializes capture directory structure
3. Menu bar icon appears with basic actions

### Viewer Launch
1. User clicks "Open Grab Viewer" in menu
2. Swift app checks if Tauri app is already running
3. If not running: Launch Tauri app with latest capture ID
4. If running: Bring to front and navigate to latest capture
5. Tauri app loads and displays capture gallery

### Capture Flow
1. User triggers capture (hotkey/menu)
2. Swift app captures screen/clipboard
3. Saves to shared directory with metadata
4. If Tauri app is open: File watcher triggers UI update
5. If Tauri app is closed: Next launch will show new captures

## Data Contracts

### Capture Metadata Format
```json
{
  "id": "uuid-v4",
  "timestamp": "2024-01-01T00:00:00Z",
  "type": "screenshot" | "clipboard",
  "filename": "capture-id.png",
  "thumbnail": "capture-id-thumb.png",
  "metadata": {
    "dimensions": {"width": 1920, "height": 1080},
    "fileSize": 1024000,
    "app": "Safari",
    "windowTitle": "GitHub",
    "tags": ["work", "development"]
  },
  "clipboard": {
    "text": "optional clipboard text",
    "html": "optional HTML content",
    "rtf": "optional RTF content"
  }
}
```

### Directory Structure
```
~/Library/Application Support/Grab/
├── captures/
│   ├── metadata.json          # Index of all captures
│   ├── 2024-01-01/
│   │   ├── capture-uuid.png
│   │   ├── capture-uuid.json
│   │   └── capture-uuid-thumb.png
│   └── 2024-01-02/
│       └── ...
├── config/
│   ├── swift-config.json      # Swift app settings
│   └── tauri-config.json      # Tauri app settings
└── logs/
    ├── swift-app.log
    └── tauri-app.log
```

## Distribution Strategy

### Development
- **Swift App**: Xcode project, direct build and run
- **Tauri App**: `pnpm tauri dev` for development
- **Integration**: Both apps watch same directory structure

### Production Distribution

#### Option 1: Separate Apps (Recommended)
- **Swift App**: Distributed via Mac App Store or direct download
- **Tauri App**: Bundled with Swift app or separate download
- **Benefits**: Easier updates, user choice, smaller initial download

#### Option 2: Bundled Distribution
- **Package**: Single DMG containing both apps
- **Installer**: Custom installer that sets up both apps
- **Benefits**: Single installation, guaranteed compatibility

#### Option 3: Swift App with Embedded Tauri
- **Structure**: Tauri app bundled inside Swift app bundle
- **Launch**: Swift app launches embedded Tauri executable
- **Benefits**: True single-app experience, simplified distribution

## Security Considerations

### Permissions
- **Swift App**: Screen recording, accessibility (for clipboard)
- **Tauri App**: File system access (captures directory only)
- **Communication**: Local file system only, no network required

### Privacy
- **Data**: All captures stored locally
- **Sharing**: Explicit user action required
- **Metadata**: No telemetry or analytics by default

## Performance Optimizations

### Swift App
- Background capture processing
- Efficient clipboard monitoring
- Minimal memory footprint for menu bar presence

### Tauri App
- Lazy loading of large image galleries
- Thumbnail generation and caching
- Virtual scrolling for large lists
- Image optimization for web display

## Future Enhancements

### Phase 1 (Current)
- Basic capture and viewing functionality
- File system communication
- Simple gallery interface

### Phase 2
- Real-time WebSocket communication
- Advanced search and filtering
- Tagging and organization features

### Phase 3
- Cloud sync integration
- Advanced editing capabilities
- Team sharing features
- API for third-party integrations

## Development Guidelines

### Swift App Development
- Use SwiftUI for modern UI components
- Implement proper background task handling
- Follow Apple's Human Interface Guidelines
- Use structured logging for debugging

### Tauri App Development
- React + TypeScript for frontend
- TailwindCSS for styling
- Use Tauri's secure IPC for file operations
- Implement proper error handling and loading states

### Integration Testing
- Test file system communication under load
- Verify capture metadata consistency
- Test launch flows and error scenarios
- Performance testing with large capture libraries