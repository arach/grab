import Cocoa
import SwiftUI

class ClipboardHistoryWindow: BaseWindow {
    private let historyManager: ClipboardHistoryManager
    private let windowFrameName = "ClipboardHistoryWindow"
    
    // Shadow state management
    private var isShadowed = false
    private var fullSizeFrame: NSRect = .zero
    private var titleBarHeight: CGFloat = 28 // Standard macOS title bar height
    
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
        hasShadow = true // Enable shadow for better visual depth
        isReleasedWhenClosed = false // Prevent deallocation when closed
        
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
        
        // Set up frame autosave for position persistence
        setFrameAutosaveName(windowFrameName)
        
        // Position window: use saved position if available, otherwise use ergonomic default
        if !setFrameUsingName(windowFrameName) {
            // No saved position - use ergonomic positioning near preview area
            positionNearPreviewArea()
        }
        
        // Enable automatic frame saving when user moves/resizes
        isRestorable = true
        
        // Add custom title bar click handling
        setupTitleBarInteraction()
    }
    
    private func setupTitleBarInteraction() {
        // Create a custom title bar view to capture clicks
        if let titleBarView = standardWindowButton(.closeButton)?.superview {
            // Add gesture recognizers for title bar interaction
            let doubleClickGesture = NSClickGestureRecognizer(target: self, action: #selector(titleBarDoubleClicked))
            doubleClickGesture.numberOfClicksRequired = 2
            doubleClickGesture.buttonMask = 1 // Left mouse button
            titleBarView.addGestureRecognizer(doubleClickGesture)
            
            // Add middle click gesture
            let middleClickGesture = NSClickGestureRecognizer(target: self, action: #selector(titleBarMiddleClicked))
            middleClickGesture.numberOfClicksRequired = 1
            middleClickGesture.buttonMask = 4 // Middle mouse button
            titleBarView.addGestureRecognizer(middleClickGesture)
        }
    }
    
    @objc private func titleBarDoubleClicked() {
        toggleShadowMode()
    }
    
    @objc private func titleBarMiddleClicked() {
        toggleShadowMode()
    }
    
    private func toggleShadowMode() {
        if isShadowed {
            unshadowWindow()
        } else {
            shadowWindow()
        }
    }
    
    private func shadowWindow() {
        guard !isShadowed else { return }
        
        // Store the current full frame
        fullSizeFrame = frame
        
        // Calculate new shadowed frame (only title bar height)
        let shadowedFrame = NSRect(
            x: frame.origin.x,
            y: frame.origin.y + frame.height - titleBarHeight,
            width: frame.width,
            height: titleBarHeight
        )
        
        // Animate to shadowed state
        isShadowed = true
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(shadowedFrame, display: true)
        }
        
        // Hide content view when shadowed
        contentView?.isHidden = true
    }
    
    private func unshadowWindow() {
        guard isShadowed else { return }
        
        // Show content view before expanding
        contentView?.isHidden = false
        
        // Animate back to full size
        isShadowed = false
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(fullSizeFrame, display: true)
        }
    }
    
    private func positionNearPreviewArea() {
        // Use the same positioning logic as ClipboardPreviewWindow for ergonomic flow
        guard let screen = NSScreen.main else { 
            center()
            return 
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY
        let isMenuBarVisible = menuBarHeight > 0
        
        // Try to get the status bar button position first
        if let statusBarRect = getStatusBarRect() {
            // Position near the status bar, similar to preview window but offset for larger size
            let systemTrayWidth: CGFloat = 200
            let safeRightMargin = systemTrayWidth + 20
            
            // Position to the left of the preview area to avoid overlap
            let previewX = statusBarRect.minX - (340 / 2) + (statusBarRect.width / 2) // Preview window X
            let windowX = previewX - frame.width - 20 // Offset left of preview area
            let safeX = max(40, min(windowX, screenFrame.maxX - frame.width - safeRightMargin))
            
            // Position below menu bar with same logic as preview
            let menuBarBottom = screenFrame.maxY - menuBarHeight
            let tightGap: CGFloat = isMenuBarVisible ? 2 : 10
            let desiredY = isMenuBarVisible ? 
                menuBarBottom - frame.height - tightGap :
                screenFrame.maxY - frame.height - tightGap
            
            let minSafetyMargin: CGFloat = 5
            let maxAllowedY = visibleFrame.maxY - frame.height - minSafetyMargin
            let minAllowedY = visibleFrame.minY + minSafetyMargin
            
            let finalWindowY = min(desiredY, maxAllowedY)
            let safeWindowY = max(finalWindowY, minAllowedY)
            
            let windowFrame = NSRect(
                x: safeX,
                y: safeWindowY,
                width: frame.width,
                height: frame.height
            )
            setFrame(windowFrame, display: true)
        } else {
            // Fallback: position in upper right area where preview would be
            let systemTrayWidth: CGFloat = 200
            let safeRightMargin = systemTrayWidth + 20
            let windowX = screenFrame.maxX - frame.width - safeRightMargin - 360 // Offset left of preview area
            
            let menuBarBottom = screenFrame.maxY - menuBarHeight
            let tightGap: CGFloat = isMenuBarVisible ? 2 : 10
            let windowY = isMenuBarVisible ? 
                menuBarBottom - frame.height - tightGap :
                screenFrame.maxY - frame.height - tightGap
            
            let windowFrame = NSRect(
                x: max(40, windowX),
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
    
    func resetToDefaultPosition() {
        // Reset to ergonomic positioning and clear saved frame
        UserDefaults.standard.removeObject(forKey: "NSWindow Frame \(windowFrameName)")
        positionNearPreviewArea()
        saveFrame(usingName: windowFrameName)
    }
    
    func showHistory() {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showHistory()
            }
            return
        }
        
        // If shadowed, unshadow first
        if isShadowed {
            unshadowWindow()
        }
        // Show window with animation
        showWithAnimation()
    }
    
    func hideHistory() {
        // If shadowed, restore to full size before hiding
        if isShadowed {
            isShadowed = false
            contentView?.isHidden = false
        }
        // Hide window with animation
        hideWithAnimation()
    }
    
    private func showWithAnimation() {
        alphaValue = 0.0
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
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
        // Handle 'S' key for shadow toggle (Cmd+S)
        if event.keyCode == 1 && event.modifierFlags.contains(.command) { // 'S' key with Cmd
            toggleShadowMode()
            return
        }
        
        // Let BaseWindow handle ESC key
        super.keyDown(with: event)
    }
}