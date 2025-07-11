import Cocoa
import SwiftUI

class ClipboardPreviewWindow: NSWindow {
    private var dismissTimer: Timer?
    private var onClickCallback: (() -> Void)?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Window configuration
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        hasShadow = false
        
        // Don't activate the app when showing
        hidesOnDeactivate = false
        
        // Position in top-right corner
        positionWindow()
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowWidth = frame.width
        let windowHeight = frame.height
        
        // Position in top-right corner with some padding
        let x = screenFrame.maxX - windowWidth - 20
        let y = screenFrame.maxY - windowHeight - 20
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func showPreview(content: String, contentType: String, imageData: Data?, onClick: @escaping () -> Void) {
        // Cancel any existing timer
        dismissTimer?.invalidate()
        
        // Store the callback
        onClickCallback = onClick
        
        // Adjust window size based on content
        let windowHeight: CGFloat
        if imageData != nil {
            windowHeight = 240 // Larger for images
        } else if content.count > 200 {
            windowHeight = 220 // Larger for long text
        } else {
            windowHeight = 180 // Smaller for short text
        }
        setContentSize(NSSize(width: 400, height: windowHeight))
        
        // Reposition after resize
        positionWindow()
        
        // Create the SwiftUI view
        let previewView = ClipboardPreviewView(
            content: content,
            contentType: contentType,
            imageData: imageData,
            onDismiss: { [weak self] in
                self?.fadeOutAndClose()
            },
            onClick: { [weak self] in
                self?.dismissTimer?.invalidate()
                self?.fadeOutAndClose()
                onClick()
            }
        )
        
        contentView = NSHostingView(rootView: previewView)
        
        // Show the window
        makeKeyAndOrderFront(nil)
        
        // Auto-dismiss after 5 seconds (increased for more content)
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.fadeOutAndClose()
        }
    }
    
    private func fadeOutAndClose() {
        dismissTimer?.invalidate()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1.0
        })
    }
}