import Cocoa
import SwiftUI

class CapturePreviewWindow: NSWindow {
    private var dismissTimer: Timer?
    private var statusBarRect: CGRect?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 100),
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
        
        // Set window properties
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Position window near menu bar
        positionNearMenuBar()
    }
    
    private func positionNearMenuBar() {
        // Get the menu bar height and screen bounds
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        
        // Try to get the status bar button position
        if let statusBarRect = getStatusBarRect() {
            self.statusBarRect = statusBarRect
            
            // Position window below and slightly to the right of the status bar icon
            let windowX = statusBarRect.minX - (frame.width / 2) + (statusBarRect.width / 2)
            let windowY = statusBarRect.minY - frame.height - 8
            
            let windowFrame = NSRect(
                x: max(10, min(windowX, screenFrame.maxX - frame.width - 10)),
                y: windowY,
                width: frame.width,
                height: frame.height
            )
            setFrame(windowFrame, display: true)
        } else {
            // Fallback: position in top-right corner
            let windowX = screenFrame.maxX - frame.width - 20
            let windowY = screenFrame.maxY - menuBarHeight - frame.height - 10
            let windowFrame = NSRect(x: windowX, y: windowY, width: frame.width, height: frame.height)
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
    
    func showPreview(for capture: Capture) {
        print("🎯 CapturePreviewWindow.showPreview called for: \(capture.filename)")
        
        // Create and set the preview view
        let previewView = CapturePreviewView(capture: capture) { [weak self] action in
            self?.handleAction(action, for: capture)
        }
        
        contentView = NSHostingView(rootView: previewView)
        
        // Cancel any existing timer
        dismissTimer?.invalidate()
        
        print("🎯 Showing preview window with animation")
        // Show window with animation
        showWithAnimation()
        
        // Set up auto-dismiss timer (5 seconds)
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.hideWithAnimation()
        }
    }
    
    private func showWithAnimation() {
        // Start with window slightly above final position and transparent
        let finalFrame = frame
        let startFrame = NSRect(
            x: finalFrame.minX,
            y: finalFrame.minY + 20,
            width: finalFrame.width,
            height: finalFrame.height
        )
        
        setFrame(startFrame, display: false)
        alphaValue = 0.0
        orderFront(nil)
        
        // Animate to final position
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            animator().setFrame(finalFrame, display: true)
            animator().alphaValue = 1.0
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
    
    private func handleAction(_ action: CapturePreviewAction, for capture: Capture) {
        // Cancel auto-dismiss timer since user interacted
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        switch action {
        case .openViewer:
            openInGallery(capture)
        case .copy:
            copyToClipboard(capture)
        case .delete:
            deleteCapture(capture)
        case .dismiss:
            hideWithAnimation()
        }
        
        // Hide window after action
        hideWithAnimation()
    }
    
    private func openInGallery(_ capture: Capture) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showGallery()
        }
    }
    
    private func copyToClipboard(_ capture: Capture) {
        guard NSApp.delegate as? AppDelegate != nil else { return }
        
        let capturesDirectory = getCapturesDirectory()
        let filePath = capturesDirectory.appendingPathComponent(capture.filename)
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch capture.type {
        case .screen, .window, .selection:
            // Copy image to clipboard
            if let image = NSImage(contentsOf: filePath) {
                pasteboard.writeObjects([image])
            }
        case .clipboard:
            if capture.fileExtension == "png" {
                // Copy image to clipboard
                if let image = NSImage(contentsOf: filePath) {
                    pasteboard.writeObjects([image])
                }
            } else if capture.fileExtension == "txt" {
                // Copy text to clipboard
                if let text = try? String(contentsOf: filePath) {
                    pasteboard.setString(text, forType: .string)
                }
            }
        }
    }
    
    private func deleteCapture(_ capture: Capture) {
        let capturesDirectory = getCapturesDirectory()
        let filePath = capturesDirectory.appendingPathComponent(capture.filename)
        
        do {
            try FileManager.default.removeItem(at: filePath)
            print("🗑️ Deleted capture: \(capture.filename)")
        } catch {
            print("❌ Failed to delete capture: \(error)")
        }
    }
    
    private func getCapturesDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Grab/captures")
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

enum CapturePreviewAction {
    case openViewer
    case copy
    case delete
    case dismiss
}