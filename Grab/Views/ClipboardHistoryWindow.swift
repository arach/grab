import Cocoa
import SwiftUI

class ClipboardHistoryWindow: NSWindow {
    private let historyManager: ClipboardHistoryManager
    
    init(historyManager: ClipboardHistoryManager) {
        self.historyManager = historyManager
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Make window floating with completely transparent background
        level = .floating
        isOpaque = false
        backgroundColor = NSColor.clear // Fully transparent window background
        hasShadow = false // Let SwiftUI handle shadows for the content
        
        // Modern window appearance
        titlebarAppearsTransparent = true
        titleVisibility = .visible
        title = "Paste Bin"
        
        // Style the title bar to match our dark theme
        standardWindowButton(.closeButton)?.superview?.superview?.setValue(NSColor.black.withAlphaComponent(0.8), forKey: "backgroundColor")
        
        // Set minimum and maximum size constraints
        minSize = NSSize(width: 400, height: 450)
        maxSize = NSSize(width: 900, height: 1200)
        
        // Window properties
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set content view without custom close button
        let historyView = ClipboardHistoryView(historyManager: historyManager)
        contentView = NSHostingView(rootView: historyView)
        
        // Position window
        center()
    }
    
    func showHistory() {
        // Show window with animation
        showWithAnimation()
    }
    
    func hideHistory() {
        // Hide window with animation
        hideWithAnimation()
    }
    
    private func showWithAnimation() {
        alphaValue = 0.0
        orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }
    }
    
    private func hideWithAnimation() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0.0
        }) { [weak self] in
            self?.orderOut(nil)
        }
    }
    
    // Override to prevent window from becoming key or main
    override var canBecomeKey: Bool {
        return true // Allow this window to become key for text input
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle Escape key to close window
        if event.keyCode == 53 { // Escape key
            hideHistory()
            return
        }
        
        super.keyDown(with: event)
    }
}