import Cocoa

// Base window class that provides ESC key handling for dismissal
class BaseWindow: NSWindow {
    
    var allowEscapeKey: Bool = true
    
    override func keyDown(with event: NSEvent) {
        // Check for ESC key (key code 53)
        if allowEscapeKey && event.keyCode == 53 {
            // Close the window
            self.close()
            return
        }
        
        // Pass other key events up the chain
        super.keyDown(with: event)
    }
}