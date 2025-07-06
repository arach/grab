import Cocoa
import SwiftUI

class CaptureWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        self.isMovableByWindowBackground = true
        
        // Set up the SwiftUI content view
        let captureView = CaptureView()
        let hostingView = NSHostingView(rootView: captureView)
        self.contentView = hostingView
        
        // Position window at center of screen
        self.center()
        
        // Make sure it can receive events
        self.acceptsMouseMovedEvents = true
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    func showCapturePanel() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideCapturePanel() {
        self.orderOut(nil)
    }
}