import SwiftUI

struct CaptureView: View {
    @State private var hoveredButton: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with personality
            HStack {
                Text("-‿¬")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Grab")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    hideWindow()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            )
            
            // Capture options
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    CaptureButton(
                        icon: "display",
                        title: "Screen",
                        subtitle: "Full screen",
                        isHovered: hoveredButton == "screen"
                    ) {
                        captureScreen()
                    }
                    .onHover { hovering in
                        hoveredButton = hovering ? "screen" : nil
                    }
                    
                    CaptureButton(
                        icon: "macwindow",
                        title: "Window",
                        subtitle: "Select window",
                        isHovered: hoveredButton == "window"
                    ) {
                        captureWindow()
                    }
                    .onHover { hovering in
                        hoveredButton = hovering ? "window" : nil
                    }
                }
                
                HStack(spacing: 12) {
                    CaptureButton(
                        icon: "viewfinder",
                        title: "Selection",
                        subtitle: "Area select",
                        isHovered: hoveredButton == "selection"
                    ) {
                        captureSelection()
                    }
                    .onHover { hovering in
                        hoveredButton = hovering ? "selection" : nil
                    }
                    
                    CaptureButton(
                        icon: "doc.on.clipboard",
                        title: "Clipboard",
                        subtitle: "Save current",
                        isHovered: hoveredButton == "clipboard"
                    ) {
                        saveClipboard()
                    }
                    .onHover { hovering in
                        hoveredButton = hovering ? "clipboard" : nil
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                    )
            )
        }
        .frame(width: 320, height: 240)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(4)
    }
    
    private func captureScreen() {
        hideWindow()
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.captureScreen()
        }
    }
    
    private func captureWindow() {
        hideWindow()
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.captureActiveWindow()
        }
    }
    
    private func captureSelection() {
        hideWindow()
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.captureSelection()
        }
    }
    
    private func saveClipboard() {
        hideWindow()
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.saveClipboard()
        }
    }
    
    private func hideWindow() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.hideCapturePanel()
        }
    }
}

struct CaptureButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isHovered ? .accentColor : .primary)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                isHovered ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

#Preview {
    CaptureView()
}