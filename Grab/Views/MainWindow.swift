import Cocoa
import SwiftUI

class MainWindow: NSWindow {
    init(clipboardHistory: ClipboardHistoryManager, captureManager: CaptureManager) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.setFrameAutosaveName("GrabMainWindow")
        self.minSize = NSSize(width: 900, height: 700)
        
        // Terminal aesthetic
        self.backgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
        self.isOpaque = true
        
        // Create the SwiftUI view
        let mainView = MainWindowView(
            clipboardHistory: clipboardHistory,
            captureManager: captureManager
        )
        
        // Set the content view
        self.contentView = NSHostingView(rootView: mainView)
        
        // Center window
        self.center()
        
        // Make window appear on all spaces
        self.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        
        // Set window level
        self.level = .normal
        
        // Enable automatic window restoration
        self.isRestorable = true
    }
    
    override func close() {
        // Instead of closing, just hide the window
        self.orderOut(nil)
    }
}