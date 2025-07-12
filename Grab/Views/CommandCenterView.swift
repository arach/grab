import SwiftUI

struct CommandCenterView: View {
    let onDismiss: () -> Void
    @State private var hoveredCommand: String? = nil
    @FocusState private var isFocused: Bool
    
    private let commands: [(key: String, icon: String, title: String, action: String)] = [
        ("a", "rectangle.dashed", "Area", "captureArea"),
        ("s", "rectangle.inset.filled", "Screen", "captureScreen"),
        ("d", "rectangle.split.3x1", "Window", "captureWindow"),
        ("f", "doc.on.clipboard", "Clipboard", "captureClipboard"),
        ("b", "clock.arrow.circlepath", "Pastebin", "showPastebin"),
        ("g", "folder", "Gallery", "openGallery"),
        ("h", "clock", "History", "showHistory"),
        ("?", "questionmark.circle", "Help", "showHelp")
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background to capture clicks
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    removeKeyHandlers()  // Clean up first
                    onDismiss()
                }
            
            VStack(spacing: 16) {
                // Grid layout - 4x2
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(commands, id: \.key) { command in
                        CommandGridItem(
                            key: command.key,
                            icon: command.icon,
                            title: command.title,
                            isHovered: hoveredCommand == command.key
                        )
                        .onHover { isHovered in
                            hoveredCommand = isHovered ? command.key : nil
                        }
                        .onTapGesture {
                            handleCommand(command.action)
                        }
                    }
                }
            }
            .padding(16)
            .frame(width: 380)
            .background(Color.black.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            // Ensure we're focused
            DispatchQueue.main.async {
                isFocused = true
            }
            setupKeyHandlers()
        }
        .onDisappear {
            // Clean up keyboard handlers immediately
            removeKeyHandlers()
        }
    }
    
    private func handleCommand(_ action: String) {
        // Remove handlers BEFORE dismissing to prevent interference
        removeKeyHandlers()
        
        onDismiss()
        
        // For capture actions, we need a longer delay to ensure window is fully hidden
        let delay = ["captureArea", "captureScreen", "captureWindow"].contains(action) ? 0.5 : 0.1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            NotificationCenter.default.post(
                name: Notification.Name("GrabCommandCenterAction"),
                object: nil,
                userInfo: ["action": action]
            )
        }
    }
    
    @State private var keyHandler: Any?
    
    private func setupKeyHandlers() {
        keyHandler = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            print("🎯 CommandCenter: Key pressed: '\(key)'")
            
            // Check if it's a command key
            if let command = commands.first(where: { $0.key == key }) {
                print("🎯 CommandCenter: Found command for key '\(key)': \(command.action)")
                handleCommand(command.action)
                return nil
            }
            
            // Any other key dismisses
            print("🎯 CommandCenter: Dismissing on key '\(key)'")
            removeKeyHandlers()  // Clean up first
            onDismiss()
            return nil
        }
    }
    
    private func removeKeyHandlers() {
        if let handler = keyHandler {
            NSEvent.removeMonitor(handler)
            keyHandler = nil  // Clear the reference
            print("🎯 CommandCenter: Keyboard handlers removed")
        }
    }
}

struct CommandGridItem: View {
    let key: String
    let icon: String
    let title: String
    let isHovered: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isHovered ? 0.15 : 0.05))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(spacing: 2) {
                Text(key.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}