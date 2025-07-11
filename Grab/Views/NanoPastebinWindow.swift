import Cocoa
import SwiftUI

class NanoPastebinWindow: NSWindow {
    static weak var shared: NanoPastebinWindow?
    private var dismissTimer: Timer?
    
    init() {
        print("🎯 NanoPastebinWindow init called")
        print("🎯 About to call super.init")
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 360),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        NanoPastebinWindow.shared = self
        print("🎯 super.init completed")
        
        setupWindow()
        print("🎯 NanoPastebinWindow init completed")
    }
    
    private func setupWindow() {
        // Remove window title and chrome
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 400, height: 160)
        maxSize = NSSize(width: 1200, height: 600)
        // Start positioned off-screen, will be positioned when shown
        setFrame(NSRect(x: -1000, y: -1000, width: 900, height: 360), display: false)
        isMovableByWindowBackground = true
    }
    
    func showNearCursor(with items: [ClipboardItem]) {
        print("🎯 showNearCursor called with \(items.count) items")
        
        // Get current mouse position
        let mouseLocation = NSEvent.mouseLocation
        print("🎯 Mouse location: \(mouseLocation)")
        
        // Position window near cursor but ensure it stays on screen
        let windowFrame = calculateOptimalPosition(mouseLocation: mouseLocation)
        print("🎯 Window frame: \(windowFrame)")
        
        // Create the nano pastebin view
        print("🎯 Creating NanoPastebinView")
        let nanoPastebinView = NanoPastebinView(
            items: items,
            onDismiss: { [weak self] in
                print("🎯 onDismiss callback triggered")
                self?.hideWithAnimation()
            },
            onCopy: { [weak self] content in
                print("🎯 onCopy callback triggered")
                self?.copyToClipboard(content)
            }
        )
        
        let hostingView = NSHostingView(rootView: nanoPastebinView)
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = true
        contentView = hostingView
        
        // Cancel any existing timer
        dismissTimer?.invalidate()
        
        // Position and show window
        setFrame(windowFrame, display: false)
        
        // Make sure window is visible if it was hidden
        if !isVisible {
            showWithAnimation()
        } else {
            // Window is already visible, just make it key
            makeKeyAndOrderFront(nil)
        }
        
        // Set up auto-dismiss timer
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Only hide if still visible and countdown is active
            if self.isVisible {
                self.hideWithAnimation()
            }
        }
        
        // Listen for cancel auto-dismiss notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cancelAutoDismiss),
            name: Notification.Name("CancelNanoPastebinAutoDismiss"),
            object: nil
        )
    }
    
    private func calculateOptimalPosition(mouseLocation: NSPoint) -> NSRect {
        // Get the screen containing the mouse
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
            // Fallback if we can't find the screen
            return NSRect(x: mouseLocation.x, y: mouseLocation.y - 125, width: 600, height: 250)
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // Calculate offsets
        let horizontalOffset: CGFloat = 15
        
        // Determine position based on available space
        var windowX = mouseLocation.x + horizontalOffset
        var windowY = mouseLocation.y - 125 // Center vertically at cursor (height/2)
        
        // Check if window would go off the right edge
        if windowX + 600 > screenFrame.maxX - 20 {
            // Position to the left of cursor instead
            windowX = mouseLocation.x - 600 - horizontalOffset
        }
        
        // Check if window would go below bottom edge
        if windowY < screenFrame.minY + 20 {
            // Adjust to stay on screen
            windowY = screenFrame.minY + 20
        }
        
        // Check if window would go above top edge
        if windowY + 250 > visibleFrame.maxY - 20 {
            // Adjust to stay on screen
            windowY = visibleFrame.maxY - 250 - 20
        }
        
        // Ensure window stays within screen bounds
        windowX = max(20, min(windowX, screenFrame.maxX - 600 - 20))
        windowY = max(screenFrame.minY + 20, min(windowY, visibleFrame.maxY - 250 - 20))
        
        // Log position for debugging
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.logger.info("🎯 Nano pastebin positioned at cursor: (\(windowX, privacy: .public), \(windowY, privacy: .public)) from mouse: (\(mouseLocation.x, privacy: .public), \(mouseLocation.y, privacy: .public))")
        }
        
        return NSRect(x: windowX, y: windowY, width: 600, height: 250)
    }
    
    private func showWithAnimation() {
        // For regular windows, just show normally with a fade
        alphaValue = 0.0
        makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }
    }
    
    private func hideWithAnimation() {
        // Cancel timer first
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // DON'T clear the AppDelegate reference - we want to reuse this window
        
        // Animate out then hide (not close)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            // Just hide the window, don't close it
            self.orderOut(nil)
            // Reset alpha for next show
            self.alphaValue = 1.0
        })
    }
    
    private func copyToClipboard(_ content: String) {
        // Use the safe copy method from AppDelegate to prevent feedback loops
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.copyToClipboardSafely(content)
        } else {
            // Fallback to direct clipboard access
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
        }
        
        // Hide after copying
        hideWithAnimation()
    }
    
    // Allow window to become key and main for proper interaction
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    @objc private func cancelAutoDismiss() {
        // Cancel timer permanently - no more auto-dismiss
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
    
    override func mouseDown(with event: NSEvent) {
        // Cancel auto-dismiss permanently on interaction
        cancelAutoDismiss()
    }
    
    override func keyDown(with event: NSEvent) {
        // Cancel auto-dismiss on any key press
        cancelAutoDismiss()
        
        // Check for Escape key
        if event.keyCode == 53 { // 53 is the key code for Escape
            print("🎯 Escape key pressed - dismissing window")
            hideWithAnimation()
        } 
        // Check for number keys 1-9
        else if let char = event.characters, 
                let number = Int(char),
                number >= 1 && number <= 9 {
            print("🎯 Number key \(number) pressed")
            
            // Post notification with the number
            NotificationCenter.default.post(
                name: Notification.Name("NanoPastebinNumberPressed"),
                object: nil,
                userInfo: ["number": number]
            )
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func close() {
        print("🎯 NanoPastebinWindow close() called - hiding instead of closing")
        
        // Instead of fully closing, just hide the window
        hideWithAnimation()
    }
    
    deinit {
        print("🎯 NanoPastebinWindow deinit called")
        // Final cleanup just in case
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}