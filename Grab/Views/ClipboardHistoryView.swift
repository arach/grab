import SwiftUI
import UniformTypeIdentifiers

struct ClipboardHistoryView: View {
    @ObservedObject var historyManager: ClipboardHistoryManager
    @State private var searchText = ""
    @State private var storageInfo: (totalSize: Int64, itemCount: Int, warning: String?) = (0, 0, nil)
    
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
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(historyManager.items.count) items")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        if storageInfo.totalSize > 0 {
                            Text(formatBytes(storageInfo.totalSize))
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                // Storage warning if needed
                if let warning = storageInfo.warning {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                        
                        Text(warning)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.orange.opacity(0.9))
                        
                        Spacer()
                        
                        Button("Clear Old Items") {
                            clearOldItems()
                        }
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.orange)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.orange.opacity(0.3), lineWidth: 0.5)
                            )
                    )
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
                .background(
                    // Try to influence scroll bar appearance through background
                    LinearGradient(
                        colors: [.black.opacity(0.75), .black.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .preferredColorScheme(.dark)
            }
        }
        .background(liquidGlassBackground)
        .frame(minWidth: 400, minHeight: 450)
        .onAppear {
            updateStorageInfo()
        }
        .onChange(of: historyManager.items) { _ in
            updateStorageInfo()
        }
    }
    
    private func updateStorageInfo() {
        storageInfo = ClipboardHistoryManager.getStorageInfo()
    }
    
    private func clearOldItems() {
        // Remove items older than 7 days
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let indicesToRemove = historyManager.items.enumerated().compactMap { index, item in
            item.timestamp < sevenDaysAgo ? index : nil
        }.reversed() // Remove from end to avoid index shifting
        
        for index in indicesToRemove {
            historyManager.removeItem(at: index)
        }
        
        updateStorageInfo()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
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
        // Use the safe copy method from AppDelegate to prevent feedback loops
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.copyToClipboardSafely(content)
        } else {
            // Fallback to direct clipboard access
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
        }
    }
}

struct ClipboardHistoryItemView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isExpanded = false
    
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
        ZStack {
            // Main content (always visible and stable)
            HStack(spacing: 12) {
                // Content type indicator or draggable thumbnail
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
                        // Draggable content type indicator for text, URLs, code, etc.
                        DraggableContentView(
                            content: item.content,
                            contentType: item.contentType,
                            borderColor: contentTypeColor,
                            icon: contentTypeIcon
                        )
                        .frame(width: 32, height: 32)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isExpanded ? item.content : item.displayContent)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(isExpanded ? nil : 4)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled) // Allow text selection when expanded
                        
                        if !isExpanded && item.content.count > 200 {
                            // Show expand indicator if content is truncated
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack {
                        Text(item.timeAgo)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Spacer()
                        
                        // Show collapse button when expanded
                        if isExpanded {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }) {
                                HStack(spacing: 2) {
                                    Text("COLLAPSE")
                                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 6, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        
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
                
                // Spacer to push content to the left and reserve space for buttons
                Spacer()
            }
            
            // Overlay buttons (appear on top without displacing content)
            if isHovered {
                VStack {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Button(action: onCopy) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(.black.opacity(0.85))
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                            )
                                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { generateFile() }) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.blue.opacity(0.9))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(.black.opacity(0.85))
                                            .overlay(
                                                Circle()
                                                    .stroke(.blue.opacity(0.3), lineWidth: 0.5)
                                            )
                                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.red.opacity(0.9))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(.black.opacity(0.85))
                                            .overlay(
                                                Circle()
                                                    .stroke(.red.opacity(0.3), lineWidth: 0.5)
                                            )
                                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 12)
                    }
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isHovered ? 0.06 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            // Single click toggles expansion
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        }
        .onTapGesture(count: 2) {
            // Double click copies content
            onCopy()
        }
    }
    
    private func generateFile() {
        // Create a save panel for file generation
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        
        // Set default filename and extension based on content type
        _ = getFileExtension(for: item.contentType)
        let defaultName = "clipboard_\(item.contentType)_\(item.timestamp.formatted(.dateTime.hour().minute()))"
        savePanel.nameFieldStringValue = defaultName
        savePanel.allowedContentTypes = [getUTType(for: item.contentType)]
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            
            do {
                if item.contentType.lowercased() == "url" {
                    // Create a proper .webloc file for URLs
                    let weblocContent = """
                    <?xml version="1.0" encoding="UTF-8"?>
                    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                    <plist version="1.0">
                    <dict>
                        <key>URL</key>
                        <string>\(item.content)</string>
                    </dict>
                    </plist>
                    """
                    try weblocContent.write(to: url, atomically: true, encoding: .utf8)
                } else if item.contentType.lowercased() == "image", let imageData = item.imageData {
                    // Save image data directly
                    try imageData.write(to: url)
                } else {
                    // For other content types, write as text
                    try item.content.write(to: url, atomically: true, encoding: .utf8)
                }
                
                // Open the file in Finder after saving
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
            } catch {
                print("Failed to save file: \(error)")
            }
        }
    }
    
    private func getFileExtension(for contentType: String) -> String {
        switch contentType.lowercased() {
        case "url":
            return "webloc"
        case "code":
            return "txt"
        case "image":
            return "png"
        case "file":
            return "txt"
        default:
            return "txt"
        }
    }
    
    private func getUTType(for contentType: String) -> UTType {
        switch contentType.lowercased() {
        case "url":
            return UTType(filenameExtension: "webloc") ?? .data
        case "code":
            return .plainText
        case "image":
            return .png
        case "file":
            return .plainText
        default:
            return .plainText
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

struct DraggableContentView: NSViewRepresentable {
    let content: String
    let contentType: String
    let borderColor: Color
    let icon: String
    
    func makeNSView(context: Context) -> DraggableContentNSView {
        let view = DraggableContentNSView()
        view.setup(content: content, contentType: contentType, borderColor: borderColor, icon: icon)
        return view
    }
    
    func updateNSView(_ nsView: DraggableContentNSView, context: Context) {
        nsView.setup(content: content, contentType: contentType, borderColor: borderColor, icon: icon)
    }
}

class DraggableContentNSView: NSView {
    private var content: String = ""
    private var contentType: String = ""
    private var borderColor: NSColor = .systemBlue
    private var icon: String = ""
    
    func setup(content: String, contentType: String, borderColor: Color, icon: String) {
        self.content = content
        self.contentType = contentType
        self.borderColor = NSColor(borderColor)
        self.icon = icon
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw circular background
        let circle = NSBezierPath(ovalIn: bounds)
        borderColor.withAlphaComponent(0.15).setFill()
        circle.fill()
        
        // Draw border
        borderColor.withAlphaComponent(0.3).setStroke()
        circle.lineWidth = 1
        circle.stroke()
        
        // Draw icon (simplified representation)
        let iconRect = NSRect(
            x: bounds.midX - 6,
            y: bounds.midY - 6,
            width: 12,
            height: 12
        )
        
        // Draw a simple icon representation
        borderColor.withAlphaComponent(0.8).setFill()
        let iconPath = NSBezierPath(rect: iconRect)
        iconPath.fill()
        
        // Add drag indicator in bottom right corner
        let dragIconSize: CGFloat = 8
        let dragIconRect = NSRect(
            x: bounds.maxX - dragIconSize - 1,
            y: bounds.minY + 1,
            width: dragIconSize,
            height: dragIconSize
        )
        
        // Draw small drag icon background
        let iconBg = NSBezierPath(ovalIn: dragIconRect)
        NSColor.black.withAlphaComponent(0.6).setFill()
        iconBg.fill()
        
        // Draw drag icon (simplified cursor/hand icon)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        let iconPath2 = NSBezierPath()
        iconPath2.move(to: NSPoint(x: dragIconRect.minX + 2, y: dragIconRect.midY))
        iconPath2.line(to: NSPoint(x: dragIconRect.maxX - 2, y: dragIconRect.midY))
        iconPath2.move(to: NSPoint(x: dragIconRect.midX, y: dragIconRect.minY + 2))
        iconPath2.line(to: NSPoint(x: dragIconRect.midX, y: dragIconRect.maxY - 2))
        iconPath2.lineWidth = 0.5
        iconPath2.stroke()
    }
    
    override func mouseDown(with event: NSEvent) {
        // Create temporary file for dragging based on content type
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileExtension = getFileExtension(for: contentType)
        let fileName = "clipboard_\(contentType)_\(UUID().uuidString).\(fileExtension)"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            if contentType.lowercased() == "url" {
                // Create a proper .webloc file for URLs
                let weblocContent = """
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>URL</key>
                    <string>\(content)</string>
                </dict>
                </plist>
                """
                try weblocContent.write(to: tempURL, atomically: true, encoding: .utf8)
            } else {
                // For other content types, write as text
                try content.write(to: tempURL, atomically: true, encoding: .utf8)
            }
            
            // Setup drag operation
            let dragItem = NSDraggingItem(pasteboardWriter: tempURL as NSURL)
            dragItem.setDraggingFrame(bounds, contents: nil)
            
            // Start the drag session
            beginDraggingSession(with: [dragItem], event: event, source: self)
        } catch {
            print("Failed to create temporary file for dragging: \(error)")
        }
    }
    
    private func getFileExtension(for contentType: String) -> String {
        switch contentType.lowercased() {
        case "url":
            return "webloc" // macOS web location file
        case "code":
            return "txt" // Could be improved to detect language
        case "file":
            return "txt"
        default:
            return "txt"
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

extension DraggableContentNSView: NSDraggingSource {
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