import SwiftUI
import AppKit

class CommandCenterWindow: NSWindow {
    private var previousApp: NSRunningApplication?
    
    init() {
        // Start with screen size since we'll expand to fill screen anyway
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isReleasedWhenClosed = false
        self.level = .modalPanel
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.animationBehavior = .alertPanel
        
        let commandCenterView = CommandCenterView(onDismiss: { [weak self] in
            self?.hideWithAnimation()
        })
        
        self.contentView = NSHostingView(rootView: commandCenterView)
        
        setupEventHandlers()
    }
    
    private func setupEventHandlers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )
    }
    
    @objc private func windowDidResignKey(_ notification: Notification) {
        hideWithAnimation()
    }
    
    func showAtCenter() {
        guard let screen = NSScreen.main else { return }
        
        // Save the currently active app before we steal focus
        previousApp = NSWorkspace.shared.frontmostApplication
        
        // Make window fill entire screen to capture clicks anywhere
        let screenFrame = screen.frame
        self.setFrame(screenFrame, display: false)
        
        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)
        
        // Force window to become key and main
        NSApp.activate(ignoringOtherApps: true)
        self.makeKey()
        self.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        })
    }
    
    func hideWithAnimation() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            self.resignKey()
            
            // Restore focus like Alt-Tab would
            if let app = self.previousApp,
               app.bundleIdentifier != Bundle.main.bundleIdentifier,
               !app.isTerminated {
                // Activate with normal priority, respecting window ordering
                app.activate(options: [])
            }
            
            self.previousApp = nil
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}