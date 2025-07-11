import SwiftUI
import UniformTypeIdentifiers

// Categories for nano paste
enum NanoPasteCategory {
    case log
    case prompt
    case image
    
    var title: String {
        switch self {
        case .log: return "Logs"
        case .prompt: return "Prompts"
        case .image: return "Images"
        }
    }
    
    var icon: String {
        switch self {
        case .log: return "doc.text"
        case .prompt: return "text.bubble"
        case .image: return "photo"
        }
    }
    
    var color: Color {
        switch self {
        case .log: return .orange
        case .prompt: return .purple
        case .image: return .blue
        }
    }
}

struct NanoPastebinView: View {
    let items: [ClipboardItem]
    let onDismiss: () -> Void
    let onCopy: (String) -> Void
    
    @State private var isCountdownActive = true
    @State private var numberKeyHandler: Any?
    
    // Track total items vs displayed
    private var totalItemsCount: Int {
        items.count
    }
    
    private var displayedItemsCount: Int {
        categorizedItems.logs.count + categorizedItems.prompts.count + 
        categorizedItems.images.count + categorizedItems.other.count
    }
    
    // Get all items in order with their number assignments
    private var numberedItems: [(number: Int, item: ClipboardItem)] {
        var result: [(number: Int, item: ClipboardItem)] = []
        var number = 1
        
        // Add items in column order: logs, prompts, images, other
        for item in categorizedItems.logs {
            result.append((number, item))
            number += 1
        }
        for item in categorizedItems.prompts {
            result.append((number, item))
            number += 1
        }
        for item in categorizedItems.images {
            result.append((number, item))
            number += 1
        }
        for item in categorizedItems.other {
            result.append((number, item))
            number += 1
        }
        
        return result
    }
    
    private var categorizedItems: (logs: [ClipboardItem], prompts: [ClipboardItem], images: [ClipboardItem], other: [ClipboardItem]) {
        var logs: [ClipboardItem] = []
        var prompts: [ClipboardItem] = []
        var images: [ClipboardItem] = []
        var other: [ClipboardItem] = []
        
        print("🎯 Categorizing \(items.count) items (max 10 per category)")
        
        // Go through items and categorize them, limiting to 10 per category
        for item in items {
            if item.isImage && images.count < 10 {
                images.append(item)
                print("  📸 Image: \(item.content.prefix(30))...")
            } else if item.isLog && logs.count < 10 {
                logs.append(item)
                print("  📝 Log: \(item.content.prefix(30))...")
            } else if item.isPrompt && prompts.count < 10 {
                prompts.append(item)
                print("  💬 Prompt: \(item.content.prefix(30))...")
            } else if !item.isImage && !item.isLog && !item.isPrompt && other.count < 10 {
                // Only add to "other" if it doesn't fit the other categories
                other.append(item)
                print("  📄 Other: \(item.content.prefix(30))...")
            }
            
            // Early exit if all categories are full
            if logs.count >= 10 && prompts.count >= 10 && images.count >= 10 && other.count >= 10 {
                print("✅ All categories full, stopping categorization")
                break
            }
        }
        
        print("📊 Final count: \(logs.count) logs, \(prompts.count) prompts, \(images.count) images, \(other.count) other")
        
        return (
            logs: logs,
            prompts: prompts,
            images: images,
            other: other
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Logs
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(icon: "chevron.right", title: "logs", color: .green, count: categorizedItems.logs.count)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedItems.logs.enumerated()), id: \ .element.id) { idx, item in
                                PastebinCard(
                                    icon: "chevron.right",
                                    index: idx + 1,
                                    timeAgo: item.timeAgo,
                                    content: item.content,
                                    color: .green,
                                    onCopy: { 
                                        isCountdownActive = false
                                        NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
                                        onCopy(item.content) 
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .frame(width: 280)
                Divider().background(Color.white.opacity(0.08))
                // Images
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(icon: "photo", title: "images", color: .blue, count: categorizedItems.images.count)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedItems.images.enumerated()), id: \ .element.id) { idx, item in
                                if let imageData = item.imageData,
                                   let nsImage = NSImage(data: imageData) {
                                    ImagePastebinCard(
                                        icon: "photo",
                                        index: idx + 1,
                                        timeAgo: item.timeAgo,
                                        image: nsImage,
                                        imageData: imageData,
                                        color: .blue,
                                        onCopy: { 
                                            isCountdownActive = false
                                            NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setData(imageData, forType: .png)
                                            onDismiss()
                                        }
                                    )
                                } else {
                                    PastebinCard(
                                        icon: "photo",
                                        index: idx + 1,
                                        timeAgo: item.timeAgo,
                                        content: "[Image: \(item.content.prefix(50))...]",
                                        color: .blue,
                                        onCopy: { 
                                            isCountdownActive = false
                                            NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
                                            onCopy(item.content) 
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .frame(width: 280)
                Divider().background(Color.white.opacity(0.08))
                // Prompts
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(icon: "bubble.left", title: "prompts", color: .purple, count: categorizedItems.prompts.count)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedItems.prompts.enumerated()), id: \ .element.id) { idx, item in
                                PastebinCard(
                                    icon: "bubble.left",
                                    index: idx + 1,
                                    timeAgo: item.timeAgo,
                                    content: item.content,
                                    color: .purple,
                                    onCopy: { 
                                        isCountdownActive = false
                                        NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
                                        onCopy(item.content) 
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .frame(width: 280)
                Divider().background(Color.white.opacity(0.08))
                // Other
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(icon: "doc.plaintext", title: "other", color: .cyan, count: categorizedItems.other.count)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedItems.other.enumerated()), id: \ .element.id) { idx, item in
                                PastebinCard(
                                    icon: "doc.plaintext",
                                    index: idx + 1,
                                    timeAgo: item.timeAgo,
                                    content: item.content,
                                    color: .cyan,
                                    onCopy: { 
                                        isCountdownActive = false
                                        NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
                                        onCopy(item.content) 
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .frame(width: 280)
            }
            .background(Color(red: 0.10, green: 0.12, blue: 0.16))
            .padding(.top, 0)
            .padding(.bottom, 0)
            .frame(minHeight: 400, idealHeight: 500, maxHeight: .infinity)
            Divider().background(Color.white.opacity(0.10))
            HStack {
                Text("ESC to close")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.leading, 16)
                Spacer()
                
                // Show count indicator if not all items are displayed
                if totalItemsCount > displayedItemsCount {
                    Text("Showing \(displayedItemsCount) of \(totalItemsCount) items")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.8))
                    Spacer()
                }
                
                Text("⌘+C to copy · ⌘+V to paste")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.trailing, 16)
            }
            .frame(height: 32)
            .background(Color(red: 0.09, green: 0.10, blue: 0.13))
        }
        .background(Color(red: 0.10, green: 0.12, blue: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
        .onTapGesture {
            isCountdownActive = false
            NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
        }
        .onHover { hovering in
            if hovering && isCountdownActive {
                isCountdownActive = false
                NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
            }
        }
        .onAppear {
            // Set up number key handler
            numberKeyHandler = NotificationCenter.default.addObserver(
                forName: Notification.Name("NanoPastebinNumberPressed"),
                object: nil,
                queue: .main
            ) { notification in
                if let number = notification.userInfo?["number"] as? Int {
                    // Find the item with this number
                    let items = numberedItems
                    if number <= items.count {
                        let item = items[number - 1].item
                        if item.isImage, let imageData = item.imageData {
                            // Copy image
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setData(imageData, forType: .png)
                        } else {
                            // Copy text
                            onCopy(item.content)
                        }
                        onDismiss()
                    }
                }
            }
        }
        .onDisappear {
            // Clean up notification observer
            if let handler = numberKeyHandler {
                NotificationCenter.default.removeObserver(handler)
            }
        }
    }
    
    @ViewBuilder
    private func categoryColumn(title: String, icon: String, color: Color, items: [ClipboardItem], startNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header - minimal terminal style
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
                Spacer()
                
                // Item count
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.03))
            .overlay(
                // Bottom border only
                Rectangle()
                    .fill(color.opacity(0.15))
                    .frame(height: 1),
                alignment: .bottom
            )
            // Items
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item: item, color: color, number: startNumber + index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 195)
    }
    
    @ViewBuilder
    private func imageColumnHeader(itemCount: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.blue.opacity(0.8))
            Text("Images")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .tracking(0.5)
            Spacer()
            
            // Item count
            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.03))
        .overlay(
            Rectangle()
                .fill(Color.blue.opacity(0.15))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func imageColumn(items: [ClipboardItem], startNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            imageColumnHeader(itemCount: items.count)
            // Images grid
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if let imageData = item.imageData,
                           let nsImage = NSImage(data: imageData) {
                            ZStack(alignment: .topLeading) {
                                DraggableImageThumbnail(
                                    image: nsImage,
                                    imageData: imageData
                                )
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                                .onTapGesture {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setData(imageData, forType: .png)
                                    onDismiss()
                                }
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                                .opacity(0.9)
                                
                                // Number indicator - keyboard hint style
                                Text("\(startNumber + index)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.blue.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.black.opacity(0.6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.08))
                                .frame(height: 60)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.blue.opacity(0.25))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 195)
    }
    
    @ViewBuilder
    private func itemRow(item: ClipboardItem, color: Color, number: Int) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.content)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 28) // Make room for number on left
            .padding(.trailing, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
            
            // Number indicator - keyboard hint style
            Text("\(number)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(color.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .offset(x: 4, y: 6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            onCopy(item.content)
        }
        .draggable(item.content) {
            // Drag preview
            HStack {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                Text(item.content)
                    .lineLimit(1)
                    .font(.caption)
            }
            .padding(6)
            .background(Color.black.opacity(0.8))
            .cornerRadius(6)
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .opacity(0.9)
    }
    
    private var backgroundView: some View {
        ZStack {
            // Terminal chic dark background with subtle gradient
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.92))
            
            // Subtle backdrop blur effect
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.01),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        }
    }
}

struct DraggableImageThumbnail: View {
    let image: NSImage
    let imageData: Data
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// ClipboardItem extension already exists in ClipboardHistory.swift

struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    let count: Int
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
            Text(title.lowercased())
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text("(") + Text("\(count)").foregroundColor(.gray) + Text(")")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

struct PastebinCard: View {
    let icon: String
    let index: Int
    let timeAgo: String
    let content: String
    let color: Color
    let onCopy: () -> Void
    @State private var isHovered = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                Text("#\(index)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(timeAgo)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                Button(action: { onCopy() }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .help("Copy to clipboard")
                }
                .buttonStyle(.plain)
            }
            Text(content)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isHovered ? 0.06 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(isHovered ? 0.25 : 0.12), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(isHovered ? 0.18 : 0.08), radius: isHovered ? 8 : 4, x: 0, y: 2)
        )
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NanoPastebinWindow.shared?.isMovableByWindowBackground = false
                NSCursor.pointingHand.push()
            } else {
                NanoPastebinWindow.shared?.isMovableByWindowBackground = true
                NSCursor.pop()
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .padding(.bottom, 10)
        .draggable(content) {
            // Drag preview for text
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(color.opacity(0.8))
                    Text("#\(index)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Text(content)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.windowBackgroundColor)))
            .frame(width: 220)
        }
    }
}

struct ImagePastebinCard: View {
    let icon: String
    let index: Int
    let timeAgo: String
    let image: NSImage
    let imageData: Data
    let color: Color
    let onCopy: () -> Void
    @State private var isHovered = false
    
    // Compute file URL for drag
    var fileURL: URL? {
        // Try to get a temp file URL for the image
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "grab-npb-image-\(UUID().uuidString.prefix(8)).png"
        let url = tempDir.appendingPathComponent(fileName)
        do {
            try imageData.write(to: url)
            return url
        } catch {
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                Text("#\(index)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(timeAgo)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                Button(action: { onCopy() }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .help("Copy image to clipboard")
                }
                .buttonStyle(.plain)
            }
            // Image preview
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 120)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isHovered ? 0.06 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(isHovered ? 0.25 : 0.12), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(isHovered ? 0.18 : 0.08), radius: isHovered ? 8 : 4, x: 0, y: 2)
        )
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NanoPastebinWindow.shared?.isMovableByWindowBackground = false
                NSCursor.pointingHand.push()
            } else {
                NanoPastebinWindow.shared?.isMovableByWindowBackground = true
                NSCursor.pop()
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .padding(.bottom, 10)
        .ifLet(fileURL) { view, url in
            view.draggable(url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(6)
                    .shadow(radius: 4)
            }
        }
    }
}

// Helper for conditional modifier
extension View {
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            return AnyView(transform(self, value))
        } else {
            return AnyView(self)
        }
    }
}

struct NanoPastebinView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock clipboard items
        let mockItems = [
            ClipboardItem(content: "[INFO] Application started successfully", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "[ERROR] Failed to connect to database", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "Write a function to parse JSON", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "How do I implement a binary search tree?", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "DEBUG: Connection established", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "https://example.com/api/docs", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "Random text that doesn't fit other categories", contentType: "text", timestamp: Date())
        ]
        
        NanoPastebinView(
            items: mockItems,
            onDismiss: { print("Dismissed") },
            onCopy: { content in print("Copied: \(content)") }
        )
        .frame(width: 600, height: 250)
        .background(Color(NSColor.windowBackgroundColor))
        .preferredColorScheme(.dark)
    }
}