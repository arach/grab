import Cocoa
import SwiftUI

class ClipboardPreviewWindow: NSWindow {
    private var dismissTimer: Timer?
    private var statusBarRect: CGRect?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Make window floating and non-activating
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        
        // Window properties are set via overridden methods below
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Position window near menu bar
        positionNearMenuBar()
    }
    
    private func positionNearMenuBar() {
        // Get the menu bar height and screen bounds
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY
        
        // Detect if menu bar is auto-hiding (when visible frame equals screen frame)
        let isMenuBarVisible = menuBarHeight > 0
        let isMenuBarAutoHiding = !isMenuBarVisible
        
        // Try to get the status bar button position first
        if let statusBarRect = getStatusBarRect() {
            self.statusBarRect = statusBarRect
            
            // Position window near the status bar, avoiding the system tray area
            let systemTrayWidth: CGFloat = 200 // Tighter margin for system tray area
            let safeRightMargin = systemTrayWidth + 20 // Reduced margin for tighter fit
            
            // Try to center under status bar, but stay in safe area
            let idealX = statusBarRect.minX - (frame.width / 2) + (statusBarRect.width / 2)
            let maxSafeX = screenFrame.maxX - frame.width - safeRightMargin
            let windowX = min(idealX, maxSafeX)
            
            // Position based on menu bar visibility
            let menuBarBottom = screenFrame.maxY - menuBarHeight
            let tightGap: CGFloat = isMenuBarVisible ? 2 : 10 // Tight when menu bar visible, more gap when auto-hiding
            let desiredY = isMenuBarVisible ? 
                menuBarBottom - frame.height - tightGap : // Below menu bar when visible
                screenFrame.maxY - frame.height - tightGap // Top of screen when auto-hiding
            
            // Minimal safety margin - just enough to ensure it's not clipped
            let minSafetyMargin: CGFloat = 5
            let maxAllowedY = visibleFrame.maxY - frame.height - minSafetyMargin
            let minAllowedY = visibleFrame.minY + minSafetyMargin
            
            // Use desired position if safe, otherwise use closest safe position
            let finalWindowY = min(desiredY, maxAllowedY)
            let safeWindowY = max(finalWindowY, minAllowedY)
            
            let windowFrame = NSRect(
                x: max(20, windowX), // Reduced left margin for tighter fit
                y: safeWindowY,
                width: frame.width,
                height: frame.height
            )
            setFrame(windowFrame, display: true)
        } else {
            // Fallback: consistent position in safe area
            let systemTrayWidth: CGFloat = 200
            let safeRightMargin = systemTrayWidth + 20
            let windowX = screenFrame.maxX - frame.width - safeRightMargin
            
            // Position below menu bar, consistent with status bar positioning
            let menuBarBottom = screenFrame.maxY - menuBarHeight
            let tightGap: CGFloat = isMenuBarVisible ? 2 : 10
            let windowY = isMenuBarVisible ? 
                menuBarBottom - frame.height - tightGap : // Below menu bar when visible
                screenFrame.maxY - frame.height - tightGap // Top of screen when auto-hiding
            
            let windowFrame = NSRect(
                x: max(20, windowX),
                y: windowY,
                width: frame.width,
                height: frame.height
            )
            setFrame(windowFrame, display: true)
        }
    }
    
    private func getStatusBarRect() -> CGRect? {
        // Try to get the status bar button position
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusItem = appDelegate.statusItem,
           let statusButton = statusItem.button {
            return statusButton.window?.convertToScreen(statusButton.bounds)
        }
        return nil
    }
    
    func showPreview(content: String, contentType: String, imageData: Data? = nil, onOpenHistory: @escaping () -> Void = {}) {
        // Convert string contentType to enum
        let clipboardContentType: ClipboardContentType = {
            switch contentType.lowercased() {
            case "url": return .url
            case "code": return .code
            case "image": return .image
            case "file": return .file
            default: return .text
            }
        }()
        
        // Create and set the preview view
        let previewView = ClipboardPreviewView(
            content: content,
            contentType: clipboardContentType,
            imageData: imageData,
            onDismiss: { [weak self] in
                self?.hideWithAnimation()
            },
            onOpenHistory: { [weak self] in
                self?.hideWithAnimation()
                onOpenHistory()
            }
        )
        
        contentView = NSHostingView(rootView: previewView)
        
        // Cancel any existing timer
        dismissTimer?.invalidate()
        
        // Show window with animation
        showWithAnimation()
        
        // Set up auto-dismiss timer (8 seconds - longer to read content)
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.hideWithAnimation()
        }
    }
    
    private func showWithAnimation() {
        // Start with window slightly offset and transparent for subtle entrance
        let finalFrame = frame
        let startFrame = NSRect(
            x: finalFrame.minX + 10,
            y: finalFrame.minY + 5,
            width: finalFrame.width,
            height: finalFrame.height
        )
        
        setFrame(startFrame, display: false)
        alphaValue = 0.0
        orderFront(nil)
        
        // Subtle fade-in animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            animator().setFrame(finalFrame, display: true)
            animator().alphaValue = 0.95 // Slightly transparent for glass effect
        }
    }
    
    private func hideWithAnimation() {
        // Cancel timer
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        // Animate out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            animator().alphaValue = 0.0
            
            // Slide up slightly
            let currentFrame = frame
            let endFrame = NSRect(
                x: currentFrame.minX,
                y: currentFrame.minY + 10,
                width: currentFrame.width,
                height: currentFrame.height
            )
            animator().setFrame(endFrame, display: true)
        }) { [weak self] in
            self?.orderOut(nil)
        }
    }
    
    // Override to prevent window from becoming key or main
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func mouseDown(with event: NSEvent) {
        // Allow clicking to keep window alive
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        // Set up a new timer for 10 seconds after interaction
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.hideWithAnimation()
        }
    }
}