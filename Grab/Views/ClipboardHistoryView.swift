import SwiftUI
import UniformTypeIdentifiers

struct ClipboardHistoryView: View {
    @ObservedObject var historyManager: ClipboardHistoryManager
    @State private var searchText = ""
    
    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return historyManager.items
        }
        return historyManager.items.filter { item in
            item.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Text("Paste Bin")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("\(historyManager.items.count) items")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 12))
                    
                    TextField("Search clipboard history...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }
            .padding(16)
            .background(.black.opacity(0.1))
            
            // Content
            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardHistoryItemView(item: item) {
                                // Copy to clipboard
                                copyToClipboard(item.content)
                            } onDelete: {
                                historyManager.removeItem(at: index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.visible)
                .scrollContentBackground(.hidden)
                .background(.black.opacity(0.75))
            }
        }
        .background(liquidGlassBackground)
        .frame(minWidth: 400, minHeight: 450)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No clipboard history")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Copy something to get started")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var liquidGlassBackground: some View {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 0,
            bottomLeading: 16,
            bottomTrailing: 16,
            topTrailing: 0
        ))
            .fill(.black.opacity(0.75)) // Dark but not completely opaque
            .background(.ultraThinMaterial.opacity(0.8)) // Material blur effect
            .overlay(
                UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 16,
                    bottomTrailing: 16,
                    topTrailing: 0
                ))
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}

struct ClipboardHistoryItemView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    private var contentTypeColor: Color {
        switch item.contentType.lowercased() {
        case "url": return .purple
        case "code": return .green
        case "image": return .orange
        case "file": return .blue
        default: return .cyan
        }
    }
    
    private var contentTypeIcon: String {
        switch item.contentType.lowercased() {
        case "url": return "link"
        case "code": return "curlybraces"
        case "image": return "photo"
        case "file": return "doc"
        default: return "doc.plaintext"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Content type indicator or image thumbnail
            Group {
                if item.contentType.lowercased() == "image", let imageData = item.imageData,
                   let nsImage = NSImage(data: imageData) {
                    // Image thumbnail with drag support
                    DraggableImageView(
                        image: nsImage,
                        imageData: imageData,
                        borderColor: contentTypeColor
                    )
                    .frame(width: 48, height: 48)
                } else {
                    // Content type indicator
                    ZStack {
                        Circle()
                            .fill(contentTypeColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: contentTypeIcon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(contentTypeColor.opacity(0.8))
                    }
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayContent)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(item.timeAgo)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Spacer()
                    
                    Text(item.contentType.uppercased())
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(contentTypeColor.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(contentTypeColor.opacity(0.1))
                        )
                }
            }
            
            // Actions
            if isHovered {
                HStack(spacing: 6) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.6))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(.red.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(isHovered ? 0.06 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onCopy()
        }
    }
}

struct DraggableImageView: NSViewRepresentable {
    let image: NSImage
    let imageData: Data
    let borderColor: Color
    
    func makeNSView(context: Context) -> DraggableImageNSView {
        let view = DraggableImageNSView()
        view.setup(image: image, imageData: imageData, borderColor: borderColor)
        return view
    }
    
    func updateNSView(_ nsView: DraggableImageNSView, context: Context) {
        nsView.setup(image: image, imageData: imageData, borderColor: borderColor)
    }
}

class DraggableImageNSView: NSView {
    private var image: NSImage?
    private var imageData: Data?
    private var borderColor: NSColor = .systemBlue
    
    func setup(image: NSImage, imageData: Data, borderColor: Color) {
        self.image = image
        self.imageData = imageData
        self.borderColor = NSColor(borderColor)
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let image = image else { return }
        
        // Draw the image with aspect fill
        let imageRect = bounds
        image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        // Draw border
        let borderPath = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        borderColor.withAlphaComponent(0.3).setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()
        
        // Add drag indicator in bottom right corner
        let dragIconSize: CGFloat = 12
        let dragIconRect = NSRect(
            x: bounds.maxX - dragIconSize - 2,
            y: bounds.minY + 2,
            width: dragIconSize,
            height: dragIconSize
        )
        
        // Draw small drag icon background
        let iconBg = NSBezierPath(roundedRect: dragIconRect, xRadius: 2, yRadius: 2)
        NSColor.black.withAlphaComponent(0.6).setFill()
        iconBg.fill()
        
        // Draw drag icon (simplified cursor/hand icon)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        let iconPath = NSBezierPath()
        iconPath.move(to: NSPoint(x: dragIconRect.minX + 3, y: dragIconRect.midY))
        iconPath.line(to: NSPoint(x: dragIconRect.maxX - 3, y: dragIconRect.midY))
        iconPath.move(to: NSPoint(x: dragIconRect.midX, y: dragIconRect.minY + 3))
        iconPath.line(to: NSPoint(x: dragIconRect.midX, y: dragIconRect.maxY - 3))
        iconPath.lineWidth = 1
        iconPath.stroke()
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

extension DraggableImageNSView: NSDraggingSource {
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
    ClipboardHistoryView(historyManager: ClipboardHistoryManager())
        .background(.black)
}