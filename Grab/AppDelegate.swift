import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var captureManager: CaptureManager!
    var hotkeyManager: HotkeyManager!
    
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
        
        let captureWindowItem = NSMenuItem(title: "Capture Window", action: #selector(captureWindow), keyEquivalent: "w")
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
    
    @objc func captureScreen() {
        captureManager.captureScreen()
    }
    
    @objc func captureWindow() {
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
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}