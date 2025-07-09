import Cocoa
import SwiftUI

// Global crash logging function (needed for signal handlers)
func writeCrashLog(_ message: String) {
    do {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let grabDir = appSupport.appendingPathComponent("Grab")
        try FileManager.default.createDirectory(at: grabDir, withIntermediateDirectories: true, attributes: nil)
        
        let logFile = grabDir.appendingPathComponent("crash_log.txt")
        let logData = message.data(using: .utf8)!
        
        if FileManager.default.fileExists(atPath: logFile.path) {
            // Append to existing file
            if let fileHandle = FileHandle(forWritingAtPath: logFile.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logData)
                fileHandle.closeFile()
            }
        } else {
            // Create new file
            try logData.write(to: logFile)
        }
    } catch {
        print("❌ Failed to write crash log: \(error)")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var captureManager: CaptureManager!
    var hotkeyManager: HotkeyManager!
    var capturePanel: CaptureWindow?
    var previewWindow: CapturePreviewWindow?
    var clipboardPreviewWindow: ClipboardPreviewWindow?
    var clipboardHistoryWindow: ClipboardHistoryWindow?
    
    // Clipboard history management
    var clipboardHistoryManager = ClipboardHistoryManager()
    
    // Pasteboard monitoring
    var pasteboardTimer: Timer?
    var lastPasteboardContent: String = ""
    var lastPasteboardChangeCount: Int = 0
    var lastChangeTime: Date = Date()
    var recentChanges: [Date] = []
    
    // Check if we're running in a proper app bundle
    private var isRunningInAppBundle: Bool {
        return Bundle.main.bundleIdentifier != nil
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up crash detection and logging
        setupCrashLogging()
        
        // Make this a proper menu bar app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Debug print to show bundle status
        print("🚀 Grab app started successfully")
        print("📦 Running in app bundle: \(isRunningInAppBundle)")
        print("📦 Process ID: \(getpid())")
        if let bundleId = Bundle.main.bundleIdentifier {
            print("📦 Bundle identifier: \(bundleId)")
        } else {
            print("📦 No bundle identifier found - running in development mode")
        }
        
        print("🔧 Initializing managers...")
        captureManager = CaptureManager()
        print("✅ CaptureManager initialized")
        
        hotkeyManager = HotkeyManager(captureManager: captureManager)
        print("✅ HotkeyManager initialized")
        
        print("🔧 Setting up UI components...")
        setupMenuBarIcon()
        setupHotkeys()
        setupCaptureWindow()
        setupPasteboardMonitoring()
        
        print("📱 Menu bar icon and hotkeys configured")
        
        // Start periodic health check
        startPeriodicHealthCheck()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when last window closes (menu bar app behavior)
        return false
    }
    
    private func setupMenuBarIcon() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        
        // Set up the menu bar button
        guard let button = statusItem.button else {
            print("⚠️ Status item has no button")
            return
        }
        
        button.title = "-‿¬"
        button.font = NSFont.systemFont(ofSize: 16)
        button.toolTip = isRunningInAppBundle ? "Grab - Screenshot & Clipboard Manager" : "Grab (Development Mode)"
        
        // Create menu
        let menu = NSMenu()
        
        // Add menu items with proper target setting
        let captureScreenItem = NSMenuItem(title: "Capture Screen", action: #selector(captureScreen), keyEquivalent: "s")
        captureScreenItem.target = self
        menu.addItem(captureScreenItem)
        
        let captureWindowItem = NSMenuItem(title: "Capture Window", action: #selector(captureActiveWindow), keyEquivalent: "w")
        captureWindowItem.target = self
        menu.addItem(captureWindowItem)
        
        let captureSelectionItem = NSMenuItem(title: "Capture Selection", action: #selector(captureSelection), keyEquivalent: "a")
        captureSelectionItem.target = self
        menu.addItem(captureSelectionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let saveClipboardItem = NSMenuItem(title: "Save Clipboard", action: #selector(saveClipboard), keyEquivalent: "c")
        saveClipboardItem.target = self
        menu.addItem(saveClipboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let showCapturePanel = NSMenuItem(title: "Show Capture Panel", action: #selector(showCapturePanel), keyEquivalent: "p")
        showCapturePanel.target = self
        menu.addItem(showCapturePanel)
        
        menu.addItem(NSMenuItem.separator())
        
        let showClipboardHistoryItem = NSMenuItem(title: "Show Paste Bin", action: #selector(showClipboardHistory), keyEquivalent: "b")
        showClipboardHistoryItem.target = self
        menu.addItem(showClipboardHistoryItem)
        
        let resetPositionItem = NSMenuItem(title: "Reset Paste Bin Position", action: #selector(resetPasteBinPosition), keyEquivalent: "")
        resetPositionItem.target = self
        menu.addItem(resetPositionItem)
        
        // Debug item to show clipboard preview
        let showPreviewItem = NSMenuItem(title: "Show Clipboard Preview (Debug)", action: #selector(showDebugClipboardPreview), keyEquivalent: "d")
        showPreviewItem.target = self
        menu.addItem(showPreviewItem)
        
        let openViewerItem = NSMenuItem(title: "Open Grab Viewer", action: #selector(openGrabViewer), keyEquivalent: "v")
        openViewerItem.target = self
        menu.addItem(openViewerItem)
        
        let openFolderItem = NSMenuItem(title: "Open Captures Folder", action: #selector(openCapturesFolder), keyEquivalent: "o")
        openFolderItem.target = self
        menu.addItem(openFolderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Storage info
        menu.addItem(NSMenuItem.separator())
        
        let storageItem = NSMenuItem(title: "Storage & Privacy Info", action: #selector(showStorageInfo), keyEquivalent: "")
        storageItem.target = self
        menu.addItem(storageItem)
        
        let quitItem = NSMenuItem(title: "Quit Grab", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        print("📱 Menu bar icon created successfully")
    }
    
    private func setupHotkeys() {
        guard hotkeyManager != nil else {
            print("⚠️ HotkeyManager not initialized")
            return
        }
        
        hotkeyManager.registerHotkeys()
        print("⌨️ Hotkeys registered successfully")
    }
    
    private func setupCaptureWindow() {
        capturePanel = CaptureWindow()
        print("🪟 Capture window initialized")
    }
    
    @objc func captureScreen() {
        captureManager.captureScreen()
    }
    
    @objc func captureActiveWindow() {
        captureManager.captureWindow()
    }
    
    @objc func captureSelection() {
        captureManager.captureSelection()
    }
    
    @objc func saveClipboard() {
        captureManager.saveClipboard()
    }
    
    @objc func openCapturesFolder() {
        captureManager.openCapturesFolder()
    }
    
    @objc func openGrabViewer() {
        launchTauriViewer()
    }
    
    @objc func showClipboardHistory() {
        if clipboardHistoryWindow == nil {
            clipboardHistoryWindow = ClipboardHistoryWindow(historyManager: clipboardHistoryManager)
        }
        clipboardHistoryWindow?.showHistory()
    }
    
    @objc func resetPasteBinPosition() {
        if clipboardHistoryWindow == nil {
            clipboardHistoryWindow = ClipboardHistoryWindow(historyManager: clipboardHistoryManager)
        }
        clipboardHistoryWindow?.resetToDefaultPosition()
    }
    
    @objc func showDebugClipboardPreview() {
        // Get current clipboard content or use sample data
        let pasteboard = NSPasteboard.general
        
        if let imageData = getImageFromPasteboard() {
            // Show image preview
            showClipboardPreview(content: "Debug Image Preview", contentType: "image", imageData: imageData)
        } else if let content = pasteboard.string(forType: .string), !content.isEmpty {
            // Show text content preview
            let contentType = determineContentType(content: content)
            showClipboardPreview(content: content, contentType: contentType, imageData: nil)
        } else {
            // Show sample preview
            let sampleContent = "This is a debug preview of the clipboard overlay. You can see how it looks and behaves without waiting for actual clipboard changes."
            showClipboardPreview(content: sampleContent, contentType: "text", imageData: nil)
        }
    }
    
    @objc func showCapturePanel() {
        capturePanel?.showCapturePanel()
    }
    
    @objc func hideCapturePanel() {
        capturePanel?.hideCapturePanel()
    }
    
    @objc func showStorageInfo() {
        let storageInfo = ClipboardHistoryManager.getStorageInfo()
        let storageDir = ClipboardHistoryManager.getClipboardDirectory()
        
        let message = """
        Grab maintains a separate clipboard history replica for enhanced functionality.
        
        📊 Storage Information:
        • Location: ~/Library/Application Support/Grab/clipboard_history/
        • Current usage: \(formatStorageSize(storageInfo.totalSize))
        • Files stored: \(storageInfo.itemCount)
        • Items in history: \(clipboardHistoryManager.items.count)
        
        🔒 Privacy Notes:
        • This is a LOCAL copy of your clipboard history
        • No data is sent to external servers
        • Files are organized by type (images/, text/, urls/, etc.)
        • Your system clipboard remains unchanged
        • Clear history anytime to remove stored data
        
        ⚠️ Data Sensitivity:
        • Clipboard may contain sensitive information
        • Review history regularly and clear when needed
        • Files persist until manually cleared or app limit reached
        """
        
        let alert = NSAlert()
        alert.messageText = "Grab Clipboard Storage"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Storage Folder")
        alert.addButton(withTitle: "Clear All History")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            // Open storage folder
            NSWorkspace.shared.open(storageDir)
        case .alertSecondButtonReturn:
            // Clear history with confirmation
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Clear All Clipboard History?"
            confirmAlert.informativeText = "This will permanently delete all stored clipboard items and files. This action cannot be undone."
            confirmAlert.alertStyle = .warning
            confirmAlert.addButton(withTitle: "Clear All")
            confirmAlert.addButton(withTitle: "Cancel")
            
            if confirmAlert.runModal() == .alertFirstButtonReturn {
                clipboardHistoryManager.clearHistory()
            }
        default:
            break
        }
    }
    
    private func formatStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    @objc func quitApp() {
        print("🔄 Application terminating gracefully...")
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Crash Logging and Health Monitoring
    
    private func setupCrashLogging() {
        // Set up signal handlers for crash detection
        signal(SIGABRT, { signal in
            let crashLog = "💥 CRASH DETECTED: SIGABRT (signal \(signal))\n💥 Stack trace: \(Thread.callStackSymbols)\n💥 Time: \(Date())\n"
            writeCrashLog(crashLog)
            print(crashLog)
            fflush(stdout)
            exit(1)
        })
        
        signal(SIGSEGV, { signal in
            let crashLog = "💥 CRASH DETECTED: SIGSEGV (signal \(signal))\n💥 Stack trace: \(Thread.callStackSymbols)\n💥 Time: \(Date())\n"
            writeCrashLog(crashLog)
            print(crashLog)
            fflush(stdout)
            exit(1)
        })
        
        signal(SIGILL, { signal in
            let crashLog = "💥 CRASH DETECTED: SIGILL (signal \(signal))\n💥 Stack trace: \(Thread.callStackSymbols)\n💥 Time: \(Date())\n"
            writeCrashLog(crashLog)
            print(crashLog)
            fflush(stdout)
            exit(1)
        })
        
        signal(SIGFPE, { signal in
            let crashLog = "💥 CRASH DETECTED: SIGFPE (signal \(signal))\n💥 Stack trace: \(Thread.callStackSymbols)\n💥 Time: \(Date())\n"
            writeCrashLog(crashLog)
            print(crashLog)
            fflush(stdout)
            exit(1)
        })
        
        signal(SIGBUS, { signal in
            let crashLog = "💥 CRASH DETECTED: SIGBUS (signal \(signal))\n💥 Stack trace: \(Thread.callStackSymbols)\n💥 Time: \(Date())\n"
            writeCrashLog(crashLog)
            print(crashLog)
            fflush(stdout)
            exit(1)
        })
        
        // Set up exception handler
        NSSetUncaughtExceptionHandler { exception in
            let crashLog = "💥 UNCAUGHT EXCEPTION: \(exception)\n💥 Reason: \(exception.reason ?? "Unknown")\n💥 Stack trace: \(exception.callStackSymbols)\n💥 Time: \(Date())\n"
            writeCrashLog(crashLog)
            print(crashLog)
            fflush(stdout)
        }
        
        print("🛡️ Crash logging initialized")
        writeCrashLog("📝 Crash logging initialized at \(Date())\n")
    }
    
    private func startPeriodicHealthCheck() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.logHealthStatus()
        }
    }
    
    private func logHealthStatus() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        let healthLog = "💓 Health check [\(timestamp)]: App running normally\n💓 Memory usage: \(self.getMemoryUsage()) MB\n💓 Clipboard items: \(self.clipboardHistoryManager.items.count)\n"
        
        print(healthLog)
        writeCrashLog(healthLog)
        
        // Check if critical components are still alive
        if self.statusItem == nil {
            let warning = "⚠️ WARNING: Status item is nil!\n"
            print(warning)
            writeCrashLog(warning)
        }
        if self.captureManager == nil {
            let warning = "⚠️ WARNING: Capture manager is nil!\n"
            print(warning)
            writeCrashLog(warning)
        }
        if self.hotkeyManager == nil {
            let warning = "⚠️ WARNING: Hotkey manager is nil!\n"
            print(warning)
            writeCrashLog(warning)
        }
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / 1024 / 1024
        } else {
            return 0
        }
    }
    
    // MARK: - Capture Preview
    
    func showCapturePreview(for capture: Capture) {
        // Create preview window if it doesn't exist
        if previewWindow == nil {
            previewWindow = CapturePreviewWindow()
        }
        
        // Show the preview
        previewWindow?.showPreview(for: capture)
    }
    
    // MARK: - Tauri Viewer Integration
    
    private func launchTauriViewer() {
        let tauriAppName = "grab-actions"
        let latestCaptureId = getLatestCaptureId()
        
        if isTauriAppRunning(appName: tauriAppName) {
            print("🔄 Tauri viewer already running, bringing to front")
            bringTauriAppToFront(appName: tauriAppName, captureId: latestCaptureId)
        } else {
            print("🚀 Launching Tauri viewer")
            launchTauriApp(captureId: latestCaptureId)
        }
    }
    
    private func isTauriAppRunning(appName: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { app in
            app.localizedName?.lowercased().contains(appName.lowercased()) == true ||
            app.bundleIdentifier?.lowercased().contains(appName.lowercased()) == true
        }
    }
    
    private func bringTauriAppToFront(appName: String, captureId: String?) {
        let runningApps = NSWorkspace.shared.runningApplications
        
        if let tauriApp = runningApps.first(where: { app in
            app.localizedName?.lowercased().contains(appName.lowercased()) == true ||
            app.bundleIdentifier?.lowercased().contains(appName.lowercased()) == true
        }) {
            tauriApp.activate(options: .activateAllWindows)
            
            if let captureId = captureId {
                launchTauriAppWithCaptureId(captureId: captureId)
            }
        }
    }
    
    private func launchTauriApp(captureId: String?) {
        let tauriAppPath = findTauriAppPath()
        
        guard let _ = tauriAppPath else {
            print("⚠️ Could not find Tauri app. Please ensure grab-actions is built and available.")
            showTauriAppNotFoundAlert()
            return
        }
        
        if let captureId = captureId {
            launchTauriAppWithCaptureId(captureId: captureId)
        } else {
            launchTauriAppWithoutCaptureId()
        }
    }
    
    private func findTauriAppPath() -> String? {
        // Priority order: embedded app first, then development builds, then system installs
        let possiblePaths = [
            // 1. EMBEDDED TAURI APP (highest priority - unified app bundle)
            Bundle.main.path(forResource: "Grab Actions", ofType: "app"),
            Bundle.main.resourcePath?.appending("/Grab Actions.app"),
            
            // 2. Development build paths (from grab directory)
            "../grab-actions/src-tauri/target/debug/grab-actions.app",
            "./grab-actions/src-tauri/target/debug/grab-actions.app",
            // Development build paths (from grab-actions directory)
            "./src-tauri/target/debug/grab-actions.app",
            "../src-tauri/target/debug/grab-actions.app",
            
            // 3. Release build paths (from grab directory)
            "../grab-actions/src-tauri/target/release/grab-actions.app",
            "./grab-actions/src-tauri/target/release/grab-actions.app",
            // Release build paths (from grab-actions directory)
            "./src-tauri/target/release/grab-actions.app",
            "../src-tauri/target/release/grab-actions.app",
            
            // 4. Bundled Tauri app paths
            "../grab-actions/src-tauri/target/release/bundle/macos/Grab Actions.app",
            "./grab-actions/src-tauri/target/release/bundle/macos/Grab Actions.app",
            "../grab-actions/src-tauri/target/debug/bundle/macos/Grab Actions.app",
            "./grab-actions/src-tauri/target/debug/bundle/macos/Grab Actions.app",
            
            // 5. Legacy bundled paths
            Bundle.main.path(forResource: "grab-actions", ofType: "app"),
            
            // 6. System Applications (lowest priority)
            "/Applications/Grab Actions.app",
            "/Applications/grab-actions.app"
        ]
        
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                let isEmbedded = path.contains(Bundle.main.bundlePath)
                let pathType = isEmbedded ? "📦 EMBEDDED" : "🔍 EXTERNAL"
                print("✅ Found Tauri app at: \(path) (\(pathType))")
                return path
            }
        }
        
        print("⚠️ No Tauri app found in any of the expected locations")
        print("🔍 Searched in bundle: \(Bundle.main.bundlePath)")
        print("🔍 Bundle resources: \(Bundle.main.resourcePath ?? "none")")
        return nil
    }
    
    private func getLatestCaptureId() -> String? {
        let capturesPath = getCapturesDirectory()
        let metadataPath = capturesPath.appendingPathComponent("metadata.json")
        
        guard FileManager.default.fileExists(atPath: metadataPath.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: metadataPath)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let captures = json["captures"] as? [[String: Any]],
               let latestCapture = captures.first,
               let captureId = latestCapture["id"] as? String {
                return captureId
            }
        } catch {
            print("⚠️ Failed to read metadata: \(error)")
        }
        
        return nil
    }
    
    private func getCapturesDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Grab/captures")
    }
    
    private func launchTauriAppWithCaptureId(captureId: String) {
        let tauriAppPath = findTauriAppPath()
        
        guard let appPath = tauriAppPath else {
            print("⚠️ Could not find Tauri app. Please ensure grab-actions is built and available.")
            showTauriAppNotFoundAlert()
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [appPath, "--args", "--capture-id=\(captureId)"]
        
        do {
            try task.run()
            print("✅ Tauri app launched successfully with capture ID: \(captureId)")
        } catch {
            print("❌ Failed to launch Tauri app: \(error)")
            showTauriAppLaunchError(error: error)
        }
    }
    
    private func launchTauriAppWithoutCaptureId() {
        let tauriAppPath = findTauriAppPath()
        
        guard let appPath = tauriAppPath else {
            print("⚠️ Could not find Tauri app. Please ensure grab-actions is built and available.")
            showTauriAppNotFoundAlert()
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [appPath]
        
        do {
            try task.run()
            print("✅ Tauri app launched successfully")
        } catch {
            print("❌ Failed to launch Tauri app: \(error)")
            showTauriAppLaunchError(error: error)
        }
    }
    
    private func showTauriAppNotFoundAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Grab Viewer Not Found"
            alert.informativeText = "The Grab Viewer app could not be found. Please ensure it's built and available in the expected location."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    private func showTauriAppLaunchError(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Failed to Launch Grab Viewer"
            alert.informativeText = "An error occurred while trying to launch the Grab Viewer: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // MARK: - Pasteboard Monitoring
    
    private func setupPasteboardMonitoring() {
        let pasteboard = NSPasteboard.general
        lastPasteboardChangeCount = pasteboard.changeCount
        lastPasteboardContent = pasteboard.string(forType: .string) ?? ""
        
        // Monitor pasteboard every 500ms
        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        
        print("📋 Pasteboard monitoring started")
    }
    
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Check if pasteboard content changed
        if currentChangeCount != lastPasteboardChangeCount {
            lastPasteboardChangeCount = currentChangeCount
            let currentTime = Date()
            
            // Track recent changes for filtering
            recentChanges.append(currentTime)
            // Keep only changes from last 2 seconds
            recentChanges = recentChanges.filter { currentTime.timeIntervalSince($0) < 2.0 }
            
            // Filter out rapid changes that likely indicate selections
            let timeSinceLastChange = currentTime.timeIntervalSince(lastChangeTime)
            lastChangeTime = currentTime
            
            // Skip if this looks like a selection (too many rapid changes)
            if recentChanges.count > 3 || timeSinceLastChange < 0.3 {
                print("📋 Skipping rapid change (likely selection)")
                return
            }
            
            // Add a delay to ensure content is stable (actual copy vs selection)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                
                // Verify the change count is still the same (content is stable)
                if pasteboard.changeCount == currentChangeCount {
                    self.processStableClipboardContent(pasteboard: pasteboard)
                }
            }
        }
    }
    
    private func processStableClipboardContent(pasteboard: NSPasteboard) {
        // Check for different content types
        if let imageData = getImageFromPasteboard() {
            // Image content
            print("📋 New image copied to clipboard")
            clipboardHistoryManager.addItem(content: "Image (\(formatBytes(imageData.count)))", contentType: "image", imageData: imageData)
            showClipboardPreview(content: "Image", contentType: "image", imageData: imageData)
        } else if let fileURL = getFileURLFromPasteboard() {
            // File content
            let fileName = fileURL.lastPathComponent
            print("📋 New file copied to clipboard: \(fileName)")
            clipboardHistoryManager.addItem(content: fileName, contentType: "file", imageData: nil)
            showClipboardPreview(content: fileName, contentType: "file", imageData: nil)
        } else if let currentContent = pasteboard.string(forType: .string) {
            // Text content - only show if significantly different and not just a selection
            if currentContent != lastPasteboardContent && 
               !currentContent.isEmpty && 
               shouldShowPreviewForContent(currentContent) {
                lastPasteboardContent = currentContent
                
                print("📋 New pasteboard content detected: \(String(currentContent.prefix(50)))...")
                
                let contentType = determineContentType(content: currentContent)
                
                // Add to clipboard history
                clipboardHistoryManager.addItem(content: currentContent, contentType: contentType, imageData: nil)
                
                // Show brief preview
                showClipboardPreview(content: currentContent, contentType: contentType, imageData: nil)
                
                // Also send to Tauri app if running
                sendClipboardContentToTauri(content: currentContent)
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func shouldShowPreviewForContent(_ content: String) -> Bool {
        // Filter out very short selections (likely just selections, not copies)
        if content.count < 15 {
            return false
        }
        
        // Filter out single words or short phrases (likely selections)
        if !content.contains(" ") && !content.contains("\n") && content.count < 150 {
            return false
        }
        
        // Filter out short phrases without meaningful content
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        if wordCount < 5 && content.count < 100 {
            return false
        }
        
        // Filter out content that looks like partial selections
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContent.count < 10 {
            return false
        }
        
        // Filter out content that's very similar to previous (avoid duplicates)
        let similarity = stringSimilarity(content, lastPasteboardContent)
        if similarity > 0.7 {
            return false
        }
        
        // Additional heuristics for copy vs selection
        // URLs are more likely to be deliberately copied
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return content.count > 20 // Reasonable URL length
        }
        
        // Code snippets are more likely to be deliberately copied
        if content.contains("{") || content.contains("}") || content.contains("function") || content.contains("class") {
            return content.count > 30
        }
        
        // Longer content is more likely to be deliberate
        if content.count > 100 {
            return true
        }
        
        // Multi-line content is more likely to be deliberate
        if content.components(separatedBy: .newlines).count > 2 {
            return true
        }
        
        return false
    }
    
    private func stringSimilarity(_ str1: String, _ str2: String) -> Double {
        let maxLength = max(str1.count, str2.count)
        if maxLength == 0 { return 1.0 }
        
        let distance = levenshteinDistance(str1, str2)
        return 1.0 - Double(distance) / Double(maxLength)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        let str1Count = str1Array.count
        let str2Count = str2Array.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: str2Count + 1), count: str1Count + 1)
        
        for i in 0...str1Count {
            matrix[i][0] = i
        }
        
        for j in 0...str2Count {
            matrix[0][j] = j
        }
        
        for i in 1...str1Count {
            for j in 1...str2Count {
                let cost = str1Array[i-1] == str2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[str1Count][str2Count]
    }
    
    private func getImageFromPasteboard() -> Data? {
        let pasteboard = NSPasteboard.general
        
        // Check for different image types
        if let imageData = pasteboard.data(forType: .png) {
            return imageData
        } else if let imageData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")) {
            return imageData
        } else if let imageData = pasteboard.data(forType: .tiff) {
            return imageData
        }
        
        return nil
    }
    
    private func getFileURLFromPasteboard() -> URL? {
        let pasteboard = NSPasteboard.general
        
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let fileURL = fileURLs.first {
            return fileURL
        }
        
        return nil
    }
    
    private func showClipboardPreview(content: String, contentType: String, imageData: Data?) {
        // Create clipboard preview window if it doesn't exist
        if clipboardPreviewWindow == nil {
            clipboardPreviewWindow = ClipboardPreviewWindow()
        }
        
        // Show the preview with callback to open history
        clipboardPreviewWindow?.showPreview(
            content: content,
            contentType: contentType,
            imageData: imageData,
            onOpenHistory: { [weak self] in
                self?.showClipboardHistory()
            }
        )
    }
    
    private func sendClipboardContentToTauri(content: String) {
        guard isTauriAppRunning(appName: "grab-actions") else {
            print("📋 Tauri app not running, skipping clipboard event")
            return
        }
        
        // Create a JSON payload for the clipboard content
        let clipboardData: [String: Any] = [
            "content": content,
            "timestamp": Date().timeIntervalSince1970,
            "type": determineContentType(content: content)
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: clipboardData)
            
            // Write clipboard event to a shared file that Tauri can monitor
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let grabDir = appSupport.appendingPathComponent("Grab")
            let clipboardEventFile = grabDir.appendingPathComponent("clipboard_event.json")
            
            // Ensure the directory exists
            try FileManager.default.createDirectory(at: grabDir, withIntermediateDirectories: true, attributes: nil)
            
            // Write the clipboard event
            try jsonData.write(to: clipboardEventFile)
            
            print("📋 Clipboard event written to: \(clipboardEventFile.path)")
            
        } catch {
            print("📋 Failed to write clipboard event: \(error)")
        }
    }
    
    private func determineContentType(content: String) -> String {
        // Check if it's a URL
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return "url"
        }
        
        // Check if it looks like code (contains brackets, semicolons, and newlines)
        if content.contains("{") && content.contains("}") && content.contains("\n") {
            return "code"
        }
        
        if content.contains("[") && content.contains("]") && content.contains("\n") {
            return "code"
        }
        
        // Default to text
        return "text"
    }
    
    deinit {
        pasteboardTimer?.invalidate()
    }
}