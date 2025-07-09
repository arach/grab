import SwiftUI
import UniformTypeIdentifiers

enum ClipboardContentType {
    case text
    case url
    case code
    case image
    case file
    
    var icon: String {
        switch self {
        case .text: return "doc.plaintext"
        case .url: return "link"
        case .code: return "curlybraces"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .cyan
        case .url: return .purple
        case .code: return .green
        case .image: return .orange
        case .file: return .blue
        }
    }
    
    var title: String {
        switch self {
        case .text: return "Text"
        case .url: return "Link"
        case .code: return "Code"
        case .image: return "Image"
        case .file: return "File"
        }
    }
}

struct ClipboardPreviewView: View {
    let content: String
    let contentType: ClipboardContentType
    let imageData: Data?
    let onDismiss: () -> Void
    let onOpenHistory: () -> Void
    
    @State private var isHovered = false
    @State private var countdownProgress: Double = 1.0
    
    private var displayContent: String {
        if content.count > 250 {
            return String(content.prefix(250)) + "..."
        }
        return content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with liquid glass effect
            HStack(spacing: 8) {
                // Content type indicator with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    contentType.color.opacity(0.3),
                                    contentType.color.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 2)
                    
                    Image(systemName: contentType.icon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [contentType.color, contentType.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(size: 11, weight: .semibold))
                        .shadow(color: contentType.color.opacity(0.5), radius: 4)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(contentType.title)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Copied to clipboard")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Close button with liquid glass
                Button(action: onDismiss) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(isHovered ? 0.15 : 0.08))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
                            )
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(isHovered ? 0.8 : 0.5))
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            }
            
            // Content Preview based on type
            contentPreviewView
            
            // Subtle border countdown - no separate progress bar needed
        }
        .padding(16)
        .background(liquidGlassBackground)
        .frame(maxWidth: 340)
        .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
        .onTapGesture {
            onOpenHistory()
        }
        .onAppear {
            // Start countdown animation
            withAnimation(.linear(duration: 3.0)) {
                countdownProgress = 0.0
            }
        }
    }
    
    @ViewBuilder
    private var contentPreviewView: some View {
        switch contentType {
        case .image:
            if let imageData = imageData,
               let nsImage = NSImage(data: imageData) {
                DraggableImagePreview(
                    image: nsImage,
                    imageData: imageData
                )
                .frame(maxHeight: 100)
                .onTapGesture {
                    openQuickLook(with: imageData)
                }
            } else {
                imagePreviewPlaceholder
            }
            
        case .url:
            urlPreview
            
        case .code:
            codePreview
            
        case .text:
            textPreview
            
        case .file:
            filePreview
        }
    }
    
    private var imagePreviewPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        .orange.opacity(0.1),
                        .orange.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 60)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.orange.opacity(0.6))
                    Text("Image copied")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            )
    }
    
    private var urlPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayContent)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.9), .purple.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineLimit(3)
                .underline()
            
            if let url = URL(string: content),
               let host = url.host {
                Text(host)
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.purple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.purple.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    private var codePreview: some View {
        ScrollView {
            Text(displayContent)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 60)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.green.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var textPreview: some View {
        Text(displayContent)
            .font(.system(size: 9, weight: .regular, design: .default))
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(5)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.cyan.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.cyan.opacity(0.15), lineWidth: 0.5)
                    )
            )
    }
    
    private var filePreview: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc")
                .font(.system(size: 16))
                .foregroundColor(.blue.opacity(0.7))
            
            Text(displayContent)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    private var liquidGlassBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        .black.opacity(0.6),
                        .black.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.2))
                    .blur(radius: 1)
            )
            .overlay(
                // Beautiful iridescent border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                contentType.color.opacity(0.6),
                                .white.opacity(0.4),
                                contentType.color.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            .shadow(color: contentType.color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func openQuickLook(with imageData: Data) {
        // Create a temporary file and open with default viewer
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "clipboard_image_\(UUID().uuidString).png"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: tempURL)
            
            // Open with default system viewer (Preview.app)
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Failed to write or open temporary image file: \(error)")
        }
    }
}

struct DraggableImagePreview: NSViewRepresentable {
    let image: NSImage
    let imageData: Data
    
    func makeNSView(context: Context) -> DraggableImagePreviewNSView {
        let view = DraggableImagePreviewNSView()
        view.setup(image: image, imageData: imageData)
        return view
    }
    
    func updateNSView(_ nsView: DraggableImagePreviewNSView, context: Context) {
        nsView.setup(image: image, imageData: imageData)
    }
}

class DraggableImagePreviewNSView: NSView {
    private var image: NSImage?
    private var imageData: Data?
    
    func setup(image: NSImage, imageData: Data) {
        self.image = image
        self.imageData = imageData
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let image = image else { return }
        
        // Draw the image with aspect fit
        let imageRect = bounds
        image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        // Draw border
        let borderPath = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        NSColor.white.withAlphaComponent(0.1).setStroke()
        borderPath.lineWidth = 0.5
        borderPath.stroke()
        
        // Draw Quick Look hint
        let iconSize: CGFloat = 20
        let iconRect = NSRect(
            x: bounds.maxX - iconSize - 6,
            y: bounds.maxY - iconSize - 6,
            width: iconSize,
            height: iconSize
        )
        
        // Draw icon background
        let iconBg = NSBezierPath(ovalIn: iconRect)
        NSColor.black.withAlphaComponent(0.6).setFill()
        iconBg.fill()
        
        // Note: In a real implementation, you'd draw the eye icon here
        // For now, just the background indicates it's interactive
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let imageData = imageData else { return }
        
        // Create temporary file for dragging
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "clipboard_image_\(UUID().uuidString).png"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: tempURL)
            
            // Setup drag operation
            let dragItem = NSDraggingItem(pasteboardWriter: tempURL as NSURL)
            dragItem.setDraggingFrame(bounds, contents: image)
            
            // Start the drag session
            beginDraggingSession(with: [dragItem], event: event, source: self)
        } catch {
            print("Failed to create temporary file for dragging: \(error)")
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

extension DraggableImagePreviewNSView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
    
    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        // Optional: Add visual feedback when drag begins
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // Optional: Clean up after drag ends
    }
}


#Preview {
    ClipboardPreviewView(
        content: "https://developer.apple.com/design/human-interface-guidelines/macos/visual-design/",
        contentType: .url,
        imageData: nil,
        onDismiss: {},
        onOpenHistory: {}
    )
    .background(.black)
    .frame(width: 400, height: 300)
}

#Preview {
    ClipboardPreviewView(
        content: "https://developer.apple.com/design/human-interface-guidelines/",
        contentType: .url,
        imageData: nil,
        onDismiss: {},
        onOpenHistory: {}
    )
    .background(.black)
}