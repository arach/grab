import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var captureManager: CaptureManager!
    var hotkeyManager: HotkeyManager!
    var capturePanel: CaptureWindow?
    
    // Check if we're running in a proper app bundle
    private var isRunningInAppBundle: Bool {
        return Bundle.main.bundleIdentifier != nil
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make this a proper menu bar app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Debug print to show bundle status
        print("🚀 Grab app started successfully")
        print("📦 Running in app bundle: \(isRunningInAppBundle)")
        if let bundleId = Bundle.main.bundleIdentifier {
            print("📦 Bundle identifier: \(bundleId)")
        } else {
            print("📦 No bundle identifier found - running in development mode")
        }
        
        captureManager = CaptureManager()
        hotkeyManager = HotkeyManager(captureManager: captureManager)
        
        setupMenuBarIcon()
        setupHotkeys()
        setupCaptureWindow()
        
        print("📱 Menu bar icon and hotkeys configured")
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
        
        let openViewerItem = NSMenuItem(title: "Open Grab Viewer", action: #selector(openGrabViewer), keyEquivalent: "v")
        openViewerItem.target = self
        menu.addItem(openViewerItem)
        
        let openFolderItem = NSMenuItem(title: "Open Captures Folder", action: #selector(openCapturesFolder), keyEquivalent: "o")
        openFolderItem.target = self
        menu.addItem(openFolderItem)
        
        menu.addItem(NSMenuItem.separator())
        
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
    
    @objc func showCapturePanel() {
        capturePanel?.showCapturePanel()
    }
    
    @objc func hideCapturePanel() {
        capturePanel?.hideCapturePanel()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
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
}