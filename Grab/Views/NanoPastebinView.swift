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
    let categorizedCache: CategorizedClipboard
    let onDismiss: () -> Void
    let onCopy: (String) -> Void
    
    @State private var isCountdownActive = true
    @State private var numberKeyHandler: Any?
    @State private var categoryKeyHandler: Any?
    @State private var hoveredItem: String? = nil
    @State private var filterText: String = ""
    @State private var focusedCategory: String? = nil
    
    init(categorizedCache: CategorizedClipboard, onDismiss: @escaping () -> Void, onCopy: @escaping (String) -> Void) {
        self.categorizedCache = categorizedCache
        self.onDismiss = onDismiss
        self.onCopy = onCopy
        
        // Log what we received from the pre-computed cache
        print("🎯 NanoPastebinView initialized with pre-computed cache:")
        print("   📂 Logs: \(categorizedCache.logs.count)")
        print("   💬 Prompts: \(categorizedCache.prompts.count)")
        print("   🖼️ Images: \(categorizedCache.images.count)")
        print("   📄 Other: \(categorizedCache.other.count)")
    }
    
    // Track total items vs displayed
    private var totalItemsCount: Int {
        // Since we're using pre-categorized cache, we only know about displayed items
        displayedItemsCount
    }
    
    private var displayedItemsCount: Int {
        categorizedCache.logs.count + categorizedCache.prompts.count + 
        categorizedCache.images.count + categorizedCache.other.count
    }
    
    // Filter items based on search text
    private func isItemFiltered(_ item: ClipboardItem) -> Bool {
        if filterText.isEmpty { return true }
        return item.content.localizedCaseInsensitiveContains(filterText)
    }
    
    private func getFilteredItemsCount() -> Int {
        var count = 0
        count += categorizedCache.logs.filter(isItemFiltered).count
        count += categorizedCache.prompts.filter(isItemFiltered).count
        count += categorizedCache.images.filter(isItemFiltered).count
        count += categorizedCache.other.filter(isItemFiltered).count
        return count
    }
    
    // Get all items in order with their number assignments
    private var numberedItems: [(number: Int, item: ClipboardItem)] {
        var result: [(number: Int, item: ClipboardItem)] = []
        var number = 1
        
        // Add items in column order: logs, prompts, images, other
        for item in categorizedCache.logs {
            result.append((number, item))
            number += 1
        }
        for item in categorizedCache.prompts {
            result.append((number, item))
            number += 1
        }
        for item in categorizedCache.images {
            result.append((number, item))
            number += 1
        }
        for item in categorizedCache.other {
            result.append((number, item))
            number += 1
        }
        
        return result
    }
    
    // No longer needed - using pre-computed cache!
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                // Logs
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(icon: "chevron.right", title: "logs", color: .green, count: categorizedCache.logs.count)
                        .overlay(
                            // Focus indicator
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.green, lineWidth: 2)
                                .padding(2)
                                .opacity(focusedCategory == "logs" ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: focusedCategory)
                        )
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedCache.logs.enumerated()).filter { isItemFiltered($0.element) }, id: \ .element.id) { idx, item in
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
                    SectionHeader(icon: "photo", title: "images", color: .blue, count: categorizedCache.images.count)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 2)
                                .padding(2)
                                .opacity(focusedCategory == "images" ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: focusedCategory)
                        )
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedCache.images.enumerated()).filter { isItemFiltered($0.element) }, id: \ .element.id) { idx, item in
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
                    SectionHeader(icon: "bubble.left", title: "prompts", color: .purple, count: categorizedCache.prompts.count)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.purple, lineWidth: 2)
                                .padding(2)
                                .opacity(focusedCategory == "prompts" ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: focusedCategory)
                        )
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedCache.prompts.enumerated()).filter { isItemFiltered($0.element) }, id: \ .element.id) { idx, item in
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
                    SectionHeader(icon: "doc.plaintext", title: "other", color: .cyan, count: categorizedCache.other.count)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.cyan, lineWidth: 2)
                                .padding(2)
                                .opacity(focusedCategory == "other" ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: focusedCategory)
                        )
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(categorizedCache.other.enumerated()).filter { isItemFiltered($0.element) }, id: \ .element.id) { idx, item in
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
            
            // Terminal-style filter bar
            HStack(spacing: 4) {
                Text("/")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.leading, 16)
                
                TextField("", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                
                if !filterText.isEmpty {
                    Button(action: { filterText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Show filtered count if filtering
                if !filterText.isEmpty {
                    let filteredCount = getFilteredItemsCount()
                    Text("\(filteredCount) matches")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.8))
                }
                
                Text("esc to close • l/i/p/o to jump")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.trailing, 16)
            }
            .frame(height: 36)
            .background(Color(red: 0.08, green: 0.09, blue: 0.11))
            .overlay(
                // Subtle placeholder when empty - could show hint after 5 uses
                HStack {
                    if filterText.isEmpty {
                        Text("")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.4))
                            .padding(.leading, 36)
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            )
            } // End of main window VStack
            .background(Color(red: 0.10, green: 0.12, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
        } // End of outer VStack with hints
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
            
            // Set up category jump handler
            categoryKeyHandler = NotificationCenter.default.addObserver(
                forName: Notification.Name("NanoPastebinCategoryJump"),
                object: nil,
                queue: .main
            ) { notification in
                if let category = notification.userInfo?["category"] as? String {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        focusedCategory = category
                    }
                    
                    // Reset focus after a moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            focusedCategory = nil
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Clean up notification observers
            if let handler = numberKeyHandler {
                NotificationCenter.default.removeObserver(handler)
            }
            if let handler = categoryKeyHandler {
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
    
    var shortcutKey: String {
        switch title.lowercased() {
        case "logs": return "L"
        case "images": return "I"
        case "prompts": return "P"
        case "other": return "O"
        default: return ""
        }
    }
    
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
                    .foregroundColor(color.opacity(isHovered ? 1.0 : 0.8))
                Text("#\(index)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(isHovered ? color.opacity(0.7) : .gray)
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
    static var mockCache: CategorizedClipboard = {
        // Create mock categorized clipboard cache
        var cache = CategorizedClipboard()
        
        // Add mock items to categories
        cache.logs = [
            ClipboardItem(content: "[INFO] Application started successfully", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "[ERROR] Failed to connect to database", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "DEBUG: Connection established", contentType: "text", timestamp: Date())
        ]
        
        cache.prompts = [
            ClipboardItem(content: "Write a function to parse JSON", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "How do I implement a binary search tree?", contentType: "text", timestamp: Date())
        ]
        
        cache.other = [
            ClipboardItem(content: "https://example.com/api/docs", contentType: "text", timestamp: Date()),
            ClipboardItem(content: "Random text that doesn't fit other categories", contentType: "text", timestamp: Date())
        ]
        
        return cache
    }()
    
    static var previews: some View {
        NanoPastebinView(
            categorizedCache: mockCache,
            onDismiss: { print("Dismissed") },
            onCopy: { content in print("Copied: \(content)") }
        )
        .frame(width: 600, height: 250)
        .background(Color(NSColor.windowBackgroundColor))
        .preferredColorScheme(.dark)
    }
}