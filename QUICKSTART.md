# Grab - Quick Start Guide

A macOS screenshot and clipboard manager with integrated viewer application.

## 🚀 Quick Setup

### Prerequisites

- **macOS**: 10.15 or later
- **Xcode Command Line Tools**: `xcode-select --install`
- **Node.js**: 16+ (with pnpm preferred)
- **Rust**: Latest stable version
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

### Build Both Applications

```bash
# Clone and enter the repository
git clone <repo-url>
cd grab

# Run the automated test script (builds both apps)
chmod +x test-integration.sh
./test-integration.sh
```

**Or build manually:**

```bash
# Build Swift Grab app
make build

# Build Tauri viewer
cd grab-actions
pnpm install
pnpm tauri build
```

## 🧪 Testing the Integration

### Automated Test

```bash
./test-integration.sh
```

This script will:
1. Build both applications
2. Start the Swift app in background  
3. Provide testing instructions
4. Clean up processes when done

### Manual Testing

1. **Start the Grab app**:
   ```bash
   make run
   # Or: .build/release/Grab
   ```

2. **Take a screenshot**:
   - Use `Cmd+Shift+4` or click the menu bar icon
   - Screenshots saved to `~/Library/Application Support/Grab/captures/`

3. **Start the viewer**:
   ```bash
   cd grab-actions
   pnpm tauri dev
   ```

4. **Test deep linking**:
   ```bash
   # Replace CAPTURE_ID with actual ID from filename
   open 'grab-actions://capture/CAPTURE_ID'
   ```

## 📁 Project Structure

```
grab/
├── Grab/                    # Swift macOS app
│   ├── GrabApp.swift       # Main app entry point
│   ├── AppDelegate.swift   # App delegate
│   └── Managers/           # Core functionality
├── grab-actions/           # Tauri viewer app
│   ├── src/                # React frontend
│   └── src-tauri/          # Rust backend
├── Makefile               # Swift build commands
└── test-integration.sh    # Integration test script
```

## 🔧 Development Commands

### Swift App (Grab)
```bash
make build          # Build release version
make run            # Build and run
make debug          # Build debug version
make clean          # Clean build artifacts
make bundle         # Create .app bundle
make install        # Install to /Applications
```

### Tauri Viewer (grab-actions)
```bash
cd grab-actions
pnpm dev            # Start web dev server
pnpm tauri dev      # Start Tauri development
pnpm tauri build    # Build production app
pnpm typecheck      # Run TypeScript checks
pnpm lint           # Run ESLint
```

## 🐛 Common Issues

### Swift App Won't Start
- **Issue**: Permission denied or app crashes
- **Solution**: 
  ```bash
  # Check if built properly
  ls -la .build/release/Grab
  
  # Try debug build
  make debug
  .build/debug/Grab
  ```

### Tauri Build Fails
- **Issue**: Rust compilation errors
- **Solution**:
  ```bash
  # Update Rust
  rustup update
  
  # Clear cache and rebuild
  cd grab-actions
  rm -rf node_modules src-tauri/target
  pnpm install
  pnpm tauri build
  ```

### Deep Links Not Working
- **Issue**: URL scheme not registered
- **Solution**:
  ```bash
  # Check if app is built
  ls -la grab-actions/src-tauri/target/release/
  
  # Register the app (development)
  cd grab-actions
  pnpm tauri dev
  ```

### No Screenshots Appearing
- **Issue**: Captures directory not found
- **Solution**:
  ```bash
  # Check permissions
  ls -la ~/Library/Application\ Support/Grab/
  
  # Create directory if missing
  mkdir -p ~/Library/Application\ Support/Grab/captures
  ```

### Package Manager Issues
- **Issue**: pnpm not found
- **Solution**:
  ```bash
  # Install pnpm
  npm install -g pnpm
  
  # Or use npm instead
  npm install
  npm run tauri dev
  ```

## 🔄 Development Workflow

1. **Make changes** to Swift or Tauri code
2. **Build** the affected app:
   ```bash
   make build              # Swift
   # or
   cd grab-actions && pnpm tauri build  # Tauri
   ```
3. **Test** using the integration script:
   ```bash
   ./test-integration.sh
   ```
4. **Commit** changes with gitmoji:
   ```bash
   git add .
   git commit -m "✨ Add new feature"
   ```

## 📂 Data Storage

- **Screenshots**: `~/Library/Application Support/Grab/captures/`
- **App Settings**: `~/Library/Application Support/Grab/settings.json`
- **Logs**: `~/Library/Application Support/Grab/logs/`

## 🚨 Troubleshooting

### Reset Everything
```bash
# Clean Swift build
make clean

# Clean Tauri build
cd grab-actions
rm -rf node_modules src-tauri/target dist
pnpm install

# Clear app data
rm -rf ~/Library/Application\ Support/Grab/
```

### Check Logs
```bash
# Swift app logs (if implemented)
tail -f ~/Library/Application\ Support/Grab/logs/app.log

# Tauri dev logs
cd grab-actions
pnpm tauri dev --verbose
```

## 📞 Support

- **Issues**: Create an issue in the repository
- **Development**: Check `ARCHITECTURE.md` for detailed technical info
- **Building**: Use `make help` and `pnpm run` for available commands

---

**Next Steps**: After successful testing, consider:
1. Adding the apps to your `/Applications` folder
2. Setting up auto-launch for the Grab app
3. Customizing hotkeys and settings
4. Contributing improvements back to the project