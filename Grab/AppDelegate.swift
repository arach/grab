import Cocoa
import SwiftUI
import os.log

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

class AppDelegate: NSObject, NSApplicationDelegate, HotkeyManagerDelegate {
    var statusItem: NSStatusItem?
    var captureManager: CaptureManager!
    var hotkeyManager: HotkeyManager!
    var capturePanel: CaptureWindow?
    var previewWindow: CapturePreviewWindow?
    // var clipboardPreviewWindow: ClipboardPreviewWindow? // REMOVED - Quick Paste feature disabled
    var clipboardHistoryWindow: ClipboardHistoryWindow?
    var nanoPastebinWindow: NanoPastebinWindow?
    
    // Modern macOS logging
    let logger = Logger(subsystem: "com.grab.macos", category: "main")
    
    // Clipboard history management
    var clipboardHistoryManager = ClipboardHistoryManager()
    
    // Pasteboard monitoring
    var pasteboardTimer: Timer?
    var lastPasteboardContent: String = ""
    var lastPasteboardChangeCount: Int = 0
    var lastChangeTime: Date = Date()
    var recentChanges: [Date] = []
    
    // Advanced filtering for multi-step clipboard operations
    var pendingChanges: [Date: NSPasteboard.PasteboardType] = [:]
    var lastImageTime: Date?
    var lastTextTime: Date?
    
    // Feedback prevention
    var isInternalCopy = false
    var internalCopyContent: String = ""
    
    // Check if we're running in a proper app bundle
    private var isRunningInAppBundle: Bool {
        return Bundle.main.bundleIdentifier != nil
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up crash detection and logging
        setupCrashLogging()
        
        // Log startup with modern macOS logging
        logger.info("🚀 Grab app startup - PID: \(getpid(), privacy: .public)")
        logger.info("📦 Bundle: \(Bundle.main.bundleIdentifier ?? "none", privacy: .public)")
        let memoryStats = getMemoryStats()
        logger.info("💾 Available memory: \(self.formatMemory(memoryStats.available), privacy: .public)")
        
        // Also log to file for crash investigation
        let startupLog = """
        🚀 === GRAB APP STARTUP ===
        📅 Startup time: \(Date())
        📦 Process ID: \(getpid())
        📦 Running in app bundle: \(isRunningInAppBundle)
        📦 Bundle ID: \(Bundle.main.bundleIdentifier ?? "none")
        💾 Available memory: \(formatMemory(memoryStats.available))
        🔄 Previous session may have ended unexpectedly if no shutdown log exists
        ===============================
        """
        print(startupLog)
        writeCrashLog(startupLog + "\n")
        
        // Make this a proper menu bar app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        print("🔧 Initializing managers...")
        captureManager = CaptureManager()
        print("✅ CaptureManager initialized")
        
        hotkeyManager = HotkeyManager(captureManager: captureManager)
        hotkeyManager.delegate = self
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
        
        // TEST: Add menu item for Nano Pastebin
        let nanoPastebinItem = NSMenuItem(title: "TEST: Show Nano Pastebin", action: #selector(showNanoPastebinFromMenu), keyEquivalent: "")
        nanoPastebinItem.target = self
        menu.addItem(nanoPastebinItem)
        
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
        logger.info("🔍 Opening clipboard history window")
        writeCrashLog("🔍 Opening clipboard history at \(Date())\n")
        
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
    
    // MARK: - Nano Pastebin
    
    private var nanoPastebinInvocationCount = 0
    
    func showNanoPastebin() {
        nanoPastebinInvocationCount += 1
        logger.info("🎯 showNanoPastebin called - invocation #\(self.nanoPastebinInvocationCount, privacy: .public)")
        
        // Log thread and execution context
        logger.info("🎯 Current thread: \(Thread.current, privacy: .public)")
        logger.info("🎯 Is main thread: \(Thread.isMainThread, privacy: .public)")
        
        // Check if we're already on main thread
        if Thread.isMainThread {
            logger.info("🎯 Already on main thread, calling directly")
            showNanoPastebinInternal()
        } else {
            logger.info("🎯 Not on main thread, dispatching to main")
            DispatchQueue.main.async { [weak self] in
                self?.showNanoPastebinInternal()
            }
        }
    }
    
    private func showNanoPastebinInternal() {
        logger.info("🎯 showNanoPastebinInternal called - invocation #\(self.nanoPastebinInvocationCount)")
        
        // Reuse the same window instance if possible
        if let existingWindow = self.nanoPastebinWindow {
            logger.info("🎯 Reusing existing window")
            // Just show it again with new items
            existingWindow.showNearCursor(with: getSmartClipboardItems())
        } else {
            logger.info("🎯 Creating new NanoPastebinWindow")
            // Create the window only once
            let window = NanoPastebinWindow()
            self.nanoPastebinWindow = window
            
            logger.info("🎯 Showing NanoPastebinWindow")
            window.showNearCursor(with: getSmartClipboardItems())
        }
        
        logger.info("🎯 showNanoPastebinInternal completed")
    }
    
    private enum ClipboardCategory: String, CaseIterable {
        case image, log, prompt, code, url
        case other
    }

    private func categorize(_ item: ClipboardItem) -> ClipboardCategory {
        switch item.contentType.lowercased() {
        case "image": return .image
        case "log": return .log
        case "prompt": return .prompt
        case "code": return .code
        case "url": return .url
        default: return .other
        }
    }

    private func getSmartClipboardItems() -> [ClipboardItem] {
        let allItems = clipboardHistoryManager.items
        logger.info("📋 Total clipboard items: \(allItems.count, privacy: .public)")
        
        // Take the most recent 25 items to process
        let recentItems = Array(allItems.prefix(25))
        logger.info("🔍 Processing \(recentItems.count) recent items for Nano Pastebin")
        
        // Return the recent items - NanoPastebinView will handle categorization and limiting
        return recentItems
    }
    
    @objc func showNanoPastebinFromMenu() {
        logger.info("🎯 showNanoPastebinFromMenu called - testing menu trigger")
        showNanoPastebin()
    }
    
    @objc func showDebugClipboardPreview() {
        // Get current clipboard content or use sample data
        let pasteboard = NSPasteboard.general
        
        if getImageFromPasteboard() != nil {
            // Show image preview
            // showClipboardPreview(content: "Debug Image Preview", contentType: "image", imageData: imageData) // Quick Paste removed
        } else if let content = pasteboard.string(forType: .string), !content.isEmpty {
            // Show text content preview
            _ = determineContentType(content: content)
            // showClipboardPreview(content: content, contentType: contentType, imageData: nil) // Quick Paste removed
        } else {
            // Show sample preview
            _ = "This is a debug preview of the clipboard overlay. You can see how it looks and behaves without waiting for actual clipboard changes."
            // showClipboardPreview(content: sampleContent, contentType: "text", imageData: nil) // Quick Paste removed
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
        • Current usage: \(formatStorageSize(storageInfo.totalSize)) / 100MB
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
        • Files persist until 100MB limit reached (oldest items removed first)
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
        logGracefulShutdown()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logGracefulShutdown()
    }
    
    private func logGracefulShutdown() {
        let shutdownLog = """
        🔄 === GRACEFUL SHUTDOWN ===
        📅 Shutdown time: \(Date())
        📦 Process ID: \(getpid())
        💾 Final memory usage: \(formatMemory(getMemoryUsage()))
        📋 Final clipboard items: \(clipboardHistoryManager.items.count)
        ✅ App terminated normally
        =============================
        """
        print(shutdownLog)
        writeCrashLog(shutdownLog + "\n")
    }
    
    // MARK: - Crash Logging and Health Monitoring
    
    private func setupCrashLogging() {
        // Set up minimal signal handlers for crash detection
        // Note: Signal handlers must be extremely simple to avoid re-entrancy issues
        signal(SIGABRT, { signal in
            write(STDERR_FILENO, "💥 CRASH: SIGABRT\n", 16)
            exit(signal)
        })
        
        signal(SIGSEGV, { signal in
            write(STDERR_FILENO, "💥 CRASH: SIGSEGV\n", 17)
            exit(signal)
        })
        
        signal(SIGILL, { signal in
            write(STDERR_FILENO, "💥 CRASH: SIGILL\n", 16)
            exit(signal)
        })
        
        signal(SIGFPE, { signal in
            write(STDERR_FILENO, "💥 CRASH: SIGFPE\n", 16)
            exit(signal)
        })
        
        signal(SIGBUS, { signal in
            write(STDERR_FILENO, "💥 CRASH: SIGBUS\n", 16)
            exit(signal)
        })
        
        // Set up exception handler (this is safer than signal handlers)
        NSSetUncaughtExceptionHandler { exception in
            let crashLog = "💥 UNCAUGHT EXCEPTION: \(exception)\n💥 Reason: \(exception.reason ?? "Unknown")\n💥 Time: \(Date())\n"
            // Use simple print instead of complex logging in exception handler
            print(crashLog)
            fflush(stdout)
        }
        
        print("🛡️ Crash logging initialized")
        logger.info("🛡️ Crash detection enabled")
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
        
        let memoryUsage = getMemoryUsage()
        let memoryStats = getMemoryStats()
        let clipboardItems = clipboardHistoryManager.items.count
        
        // Determine health status and heart emoji based on system state
        let (healthEmoji, healthDescription) = getHealthStatus(appMemory: memoryUsage, availableMemory: memoryStats.available)
        
        // Compact one-line health log with detailed memory info and personality
        logger.info("\(healthEmoji) Health check [\(timestamp, privacy: .public)]: PID \(getpid(), privacy: .public) | App: \(self.formatMemory(memoryUsage), privacy: .public) | Memory - Free: \(self.formatMemory(memoryStats.free), privacy: .public), Available: \(self.formatMemory(memoryStats.available), privacy: .public) (Inactive: \(self.formatMemory(memoryStats.inactive), privacy: .public), Purgeable: \(self.formatMemory(memoryStats.purgeable), privacy: .public)) | Clipboard: \(clipboardItems, privacy: .public) items | Timer: \(self.pasteboardTimer != nil ? "active" : "inactive", privacy: .public) | Status: \(healthDescription, privacy: .public)")
        
        let healthLog = "\(healthEmoji) Health check [\(timestamp)]: PID \(getpid()) | App: \(formatMemory(memoryUsage)) | Memory - Free: \(formatMemory(memoryStats.free)), Available: \(formatMemory(memoryStats.available)) (Inactive: \(formatMemory(memoryStats.inactive)), Purgeable: \(formatMemory(memoryStats.purgeable))) | Clipboard: \(clipboardItems) items | Timer: \(self.pasteboardTimer != nil ? "active" : "inactive") | Status: \(healthDescription)\n"
        
        print(healthLog)
        writeCrashLog(healthLog)
        
        // Check for potential memory pressure
        if memoryUsage > 200 {
            let warning = "⚠️ HIGH MEMORY USAGE: \(formatMemory(memoryUsage)) (might trigger system termination)\n"
            logger.error("⚠️ HIGH MEMORY USAGE: \(self.formatMemory(memoryUsage), privacy: .public)")
            print(warning)
            writeCrashLog(warning)
        }
        
        // Use realistic available memory threshold (1GB instead of 500MB)
        if memoryStats.available < 1000 {
            let warning = "⚠️ LOW SYSTEM MEMORY: \(formatMemory(memoryStats.available)) available (Free: \(formatMemory(memoryStats.free)), system under pressure)\n"
            logger.error("⚠️ LOW SYSTEM MEMORY: \(self.formatMemory(memoryStats.available), privacy: .public) available")
            print(warning)
            writeCrashLog(warning)
        }
        
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
        if self.pasteboardTimer == nil {
            let warning = "⚠️ WARNING: Pasteboard timer is nil!\n"
            print(warning)
            writeCrashLog(warning)
        }
    }
    
    private func formatMemory(_ mb: Int) -> String {
        if mb >= 1000 {
            let gb = Double(mb) / 1024.0
            return String(format: "%.1fGB", gb)
        } else {
            return "\(mb)MB"
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
    
    private func getMemoryStats() -> (free: Int, available: Int, inactive: Int, purgeable: Int) {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let pageSize = Int64(vm_kernel_page_size)
            let freeMemory = Int64(info.free_count) * pageSize / (1024 * 1024)
            let inactiveMemory = Int64(info.inactive_count) * pageSize / (1024 * 1024)
            let purgeableMemory = Int64(info.purgeable_count) * pageSize / (1024 * 1024)
            let availableMemory = freeMemory + inactiveMemory + purgeableMemory
            
            return (
                free: Int(freeMemory),
                available: Int(availableMemory),
                inactive: Int(inactiveMemory),
                purgeable: Int(purgeableMemory)
            )
        } else {
            return (free: 0, available: 0, inactive: 0, purgeable: 0)
        }
    }
    
    private func getHealthStatus(appMemory: Int, availableMemory: Int) -> (emoji: String, description: String) {
        // Health levels based on app memory and system available memory
        let isAppHealthy = appMemory <= 100
        let isSystemHealthy = availableMemory >= 3000  // 3GB+
        let isSystemModerate = availableMemory >= 1500 // 1.5GB+
        let isSystemLow = availableMemory >= 1000      // 1GB+
        
        switch (isAppHealthy, isSystemHealthy, isSystemModerate, isSystemLow) {
        case (true, true, _, _):
            return ("💚", "Super healthy")
        case (true, false, true, _):
            return ("💛", "Healthy")
        case (true, false, false, true):
            return ("🧡", "Modestly healthy")
        case (true, false, false, false):
            return ("❤️", "Oh shit - low memory")
        case (false, true, _, _):
            return ("💜", "App heavy but system ok")
        case (false, false, true, _):
            return ("🧡", "App heavy, system tight")
        case (false, false, false, true):
            return ("❤️", "App heavy, memory pressure")
        default:
            return ("💔", "Oh shit - everything's stressed")
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
            
            // Add a longer delay for multi-step operations (like Wispr Flow)
            // This allows the app to complete its full clipboard workflow
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                
                // Ensure app is still running before processing
                guard NSApp.isRunning else {
                    self.logger.info("⚠️ Skipping clipboard processing - app is terminating")
                    return
                }
                
                // Check if there have been subsequent changes (indicating multi-step operation)
                let finalChangeCount = pasteboard.changeCount
                if finalChangeCount != currentChangeCount {
                    // There were more changes - process the final state instead
                    self.processStableClipboardContent(pasteboard: pasteboard)
                } else {
                    // No further changes - process this stable content
                    self.processStableClipboardContent(pasteboard: pasteboard)
                }
            }
        }
    }
    
    private func processStableClipboardContent(pasteboard: NSPasteboard) {
        let currentTime = Date()
        
        // PRIORITY ORDER: Text > File > Image
        // This handles apps like Wispr Flow that put both text and images on clipboard
        
        if let currentContent = pasteboard.string(forType: .string),
           !currentContent.isEmpty && 
           shouldShowPreviewForContent(currentContent) &&
           currentContent != lastPasteboardContent {
            
            // Skip if this is our own internal copy operation
            if isInternalCopy && currentContent == internalCopyContent {
                print("📋 Skipping internal copy operation")
                return
            }
            
            // Text content is highest priority - this is usually the final result
            lastPasteboardContent = currentContent
            lastTextTime = currentTime
            
            print("📋 New text content detected: \(String(currentContent.prefix(50)))...")
            
            let contentType = determineContentType(content: currentContent)
            
            // Add to clipboard history
            clipboardHistoryManager.addItem(content: currentContent, contentType: contentType, imageData: nil)
            
            // Show brief preview - DISABLED per user request
            // showClipboardPreview(content: currentContent, contentType: contentType, imageData: nil)
            
            // Also send to Tauri app if running
            sendClipboardContentToTauri(content: currentContent)
            
        } else if let fileURL = getFileURLFromPasteboard() {
            // File content (second priority)
            let fileName = fileURL.lastPathComponent
            print("📋 New file copied to clipboard: \(fileName)")
            clipboardHistoryManager.addItem(content: fileName, contentType: "file", imageData: nil)
            // showClipboardPreview(content: fileName, contentType: "file", imageData: nil)
            
        } else if let imageData = getImageFromPasteboard() {
            // Image content (lowest priority - often intermediate in workflows)
            lastImageTime = currentTime
            
            // Only process images if no recent text was processed
            if let lastText = lastTextTime, currentTime.timeIntervalSince(lastText) < 3.0 {
                print("📋 Skipping image - recent text content takes priority")
                return
            }
            
            print("📋 New image copied to clipboard")
            clipboardHistoryManager.addItem(content: "Image (\(formatBytes(imageData.count)))", contentType: "image", imageData: imageData)
            // showClipboardPreview(content: "Image", contentType: "image", imageData: imageData)
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
            logger.debug("📋 Skipping similar content (similarity: \(similarity, privacy: .public))")
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
        // Bounds checking to prevent crashes
        guard !str1.isEmpty || !str2.isEmpty else { return 1.0 }
        
        let maxLength = max(str1.count, str2.count)
        if maxLength == 0 { return 1.0 }
        
        // For very long strings, use a simpler comparison to avoid performance issues
        if maxLength > 1000 {
            return str1 == str2 ? 1.0 : 0.0
        }
        
        let distance = levenshteinDistance(str1, str2)
        return 1.0 - Double(distance) / Double(maxLength)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        // Early returns for edge cases
        if str1.isEmpty { return str2.count }
        if str2.isEmpty { return str1.count }
        if str1 == str2 { return 0 }
        
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        let str1Count = str1Array.count
        let str2Count = str2Array.count
        
        // Bounds checking
        guard str1Count > 0, str2Count > 0 else { return max(str1Count, str2Count) }
        
        // Use single array instead of 2D matrix for better memory efficiency
        var previousRow = Array(0...str2Count)
        var currentRow = Array(repeating: 0, count: str2Count + 1)
        
        for i in 1...str1Count {
            currentRow[0] = i
            
            for j in 1...str2Count {
                let cost = str1Array[i-1] == str2Array[j-1] ? 0 : 1
                currentRow[j] = min(
                    previousRow[j] + 1,      // deletion
                    currentRow[j-1] + 1,     // insertion  
                    previousRow[j-1] + cost  // substitution
                )
            }
            
            // Swap rows
            (previousRow, currentRow) = (currentRow, previousRow)
        }
        
        return previousRow[str2Count]
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
    
    // REMOVED - Quick Paste feature disabled
    /*
    private func showClipboardPreview(content: String, contentType: String, imageData: Data?) {
        // This feature has been disabled
    }
    */
    
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
        
        // Check if it looks like a log file
        if isLogContent(content) {
            return "log"
        }
        
        // Check if it looks like a prompt for LLMs
        if isPromptContent(content) {
            return "prompt"
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
    
    private func isLogContent(_ content: String) -> Bool {
        let lines = content.split(separator: "\n")
        guard lines.count >= 2 else { return false }
        
        // Check for common log patterns
        let logPatterns = [
            // Timestamp patterns
            "\\d{4}-\\d{2}-\\d{2}[T ]\\d{2}:\\d{2}:\\d{2}", // ISO timestamps
            "\\d{2}:\\d{2}:\\d{2}", // Time only
            "\\[\\d{2}:\\d{2}:\\d{2}\\]", // Bracketed time
            
            // Log level patterns
            "\\b(ERROR|WARN|INFO|DEBUG|TRACE|FATAL)\\b",
            "\\b(error|warn|info|debug|trace|fatal)\\b",
            "\\[\\w+\\]", // Bracketed levels
            
            // Stack trace patterns
            "\\s+at\\s+\\w+", // Java-style stack traces
            "\\s+in\\s+\\w+", // Swift/other stack traces
            "Traceback", // Python tracebacks
            
            // System log patterns
            "kernel:", "launchd:", "com\\.", // macOS system logs
            "\\w+\\[\\d+\\]:", // Process[PID]:
            
            // Application log patterns
            "💚|💛|🧡|❤️|💜|💔", // Our own health emojis
            "🚀|📦|💾|🔄|⚠️|❌", // Our startup/error emojis
        ]
        
        var logIndicators = 0
        for line in lines.prefix(5) { // Check first 5 lines
            let lineStr = String(line)
            for pattern in logPatterns {
                if lineStr.range(of: pattern, options: .regularExpression) != nil {
                    logIndicators += 1
                    break
                }
            }
        }
        
        // Consider it a log if at least 40% of checked lines have log patterns
        return Double(logIndicators) / Double(min(lines.count, 5)) >= 0.4
    }
    
    private func isPromptContent(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmed.split(separator: " ").count
        
        // Check for prompt characteristics
        let promptIndicators = [
            // Question patterns
            trimmed.contains("?"),
            trimmed.hasPrefix("How"),
            trimmed.hasPrefix("What"),
            trimmed.hasPrefix("Why"),
            trimmed.hasPrefix("When"),
            trimmed.hasPrefix("Where"),
            trimmed.hasPrefix("Can you"),
            trimmed.hasPrefix("Could you"),
            trimmed.hasPrefix("Please"),
            
            // AI/LLM specific patterns
            trimmed.contains("explain"),
            trimmed.contains("implement"),
            trimmed.contains("help me"),
            trimmed.contains("show me"),
            trimmed.contains("create"),
            trimmed.contains("build"),
            trimmed.contains("fix"),
            trimmed.contains("debug"),
            
            // Instruction patterns
            trimmed.lowercased().contains("step by step"),
            trimmed.lowercased().contains("detailed"),
            trimmed.lowercased().contains("example"),
            
            // Length indicators (prompts are usually longer than simple text)
            wordCount >= 10 && wordCount <= 200, // Sweet spot for prompts
            trimmed.count >= 50 && trimmed.count <= 1000, // Character length
        ]
        
        let indicators = promptIndicators.filter { $0 }.count
        
        // Consider it a prompt if it has multiple prompt characteristics
        return indicators >= 3
    }
    
    // MARK: - Safe Clipboard Operations
    
    func copyToClipboardSafely(_ content: String) {
        // Flag that this is an internal copy to prevent feedback loop
        isInternalCopy = true
        internalCopyContent = content
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        // Reset the flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isInternalCopy = false
            self?.internalCopyContent = ""
        }
        
        logger.debug("📋 Internal copy: \(content.prefix(30), privacy: .public)...")
    }
    
    deinit {
        pasteboardTimer?.invalidate()
    }
}

// MARK: - NSWindowDelegate
// TEMPORARILY DISABLED to debug crash
/*
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Clear reference to nano pastebin window when it closes
        if window === nanoPastebinWindow {
            logger.info("🎯 Nano pastebin window closing, clearing reference")
            nanoPastebinWindow = nil
        }
    }
}
*/
