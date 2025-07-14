import Cocoa
import SwiftUI

class CaptureEditorWindow: BaseWindow {
    private var capture: Capture?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    convenience init() {
        self.init(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                  styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                  backing: .buffered,
                  defer: false)
    }
    
    private func setupWindow() {
        title = "Edit Capture"
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        
        // Center on screen
        center()
        
        // Set minimum size
        contentMinSize = NSSize(width: 600, height: 400)
        
        // Set delegate to handle window close
        if let appDelegate = AppDelegate.shared {
            delegate = appDelegate
        }
    }
    
    func editCapture(_ capture: Capture) {
        self.capture = capture
        
        let editorView = CaptureEditorView(capture: capture) { [weak self] action in
            self?.handleAction(action)
        }
        
        contentView = NSHostingView(rootView: editorView)
        
        // Show window and bring to front
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        level = .floating  // Temporarily float above other windows
        
        // After a brief moment, return to normal level
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.level = .normal
        }
    }
    
    private func handleAction(_ action: CaptureEditorAction) {
        switch action {
        case .save(let editedImage):
            saveEditedCapture(editedImage)
        case .cancel:
            close()
        }
    }
    
    private func saveEditedCapture(_ image: NSImage) {
        guard let capture = self.capture else { 
            DispatchQueue.main.async { [weak self] in
                self?.close()
            }
            return 
        }
        
        // Get the captures directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let capturesDir = appSupport.appendingPathComponent("Grab/captures")
        
        // Create a new filename for the edited version
        let editedFilename = capture.filename.replacingOccurrences(of: ".png", with: "_edited.png")
        let editedURL = capturesDir.appendingPathComponent(editedFilename)
        
        // Save the edited image
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: editedURL)
                print("✅ Saved edited capture to: \(editedFilename)")
                
                // Copy to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
                
                // Play sound feedback
                NSSound.beep()
            } catch {
                print("❌ Failed to save edited capture: \(error)")
            }
        }
        
        // Close window on main thread with delay to ensure save completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.close()
        }
    }
}

enum CaptureEditorAction {
    case save(NSImage)
    case cancel
}