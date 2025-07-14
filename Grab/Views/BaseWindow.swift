import Cocoa

// Base window class that provides Q key handling for dismissal
class BaseWindow: NSWindow {
    
    var allowDismissKey: Bool = true
    
    override func keyDown(with event: NSEvent) {
        print("🔑 BaseWindow keyDown: keyCode=\(event.keyCode), char=\(event.characters ?? "nil"), window=\(String(describing: type(of: self)))")
        
        // Check for Q key (key code 12)
        if allowDismissKey && event.keyCode == 12 && !event.modifierFlags.contains(.command) {
            print("🔑 Q key detected - hiding window")
            // Hide the window instead of closing to prevent deallocation
            self.orderOut(nil)
            return
        }
        
        // Pass other key events up the chain
        super.keyDown(with: event)
    }
    
    // Helper method to properly take focus
    func takeFocus() {
        print("🎯 takeFocus called for \(String(describing: type(of: self)))")
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        makeKey()
        print("🎯 isKeyWindow: \(isKeyWindow), isMainWindow: \(isMainWindow), firstResponder: \(String(describing: firstResponder))")
    }
    
    // Override to ensure we can receive key events
    override var acceptsFirstResponder: Bool {
        return true
    }
}