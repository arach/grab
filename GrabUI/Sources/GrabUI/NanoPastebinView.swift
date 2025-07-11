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
    
    @State private var isHovered = false
    @State private var countdownProgress: Double = 0.0
    @State private var isCountdownActive = true
    
    private var categorizedItems: (logs: [ClipboardItem], prompts: [ClipboardItem], images: [ClipboardItem], other: [ClipboardItem]) {
        var logs: [ClipboardItem] = []
        var prompts: [ClipboardItem] = []
        var images: [ClipboardItem] = []
        var other: [ClipboardItem] = []
        
        for item in items {
            if item.isImage {
                images.append(item)
            } else if item.isLog {
                logs.append(item)
            } else if item.isPrompt {
                prompts.append(item)
            } else {
                // Everything else goes to Other
                other.append(item)
            }
        }
        
        // Return all items (no limit)
        return (
            logs: logs,
            prompts: prompts,
            images: images,
            other: other
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated border
                if isCountdownActive {
                    let inset: CGFloat = 2
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: inset)
                        .trim(from: 0, to: countdownProgress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .cyan.opacity(0.7),
                                    .white.opacity(0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 5.0), value: countdownProgress)
                }
                // Main content
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        categoryColumn(
                            title: "Logs",
                            icon: "doc.text",
                            color: .orange,
                            items: categorizedItems.logs
                        )
                        Divider()
                            .background(Color.white.opacity(0.1))
                        categoryColumn(
                            title: "Prompts", 
                            icon: "text.bubble",
                            color: .purple,
                            items: categorizedItems.prompts
                        )
                        Divider()
                            .background(Color.white.opacity(0.1))
                        imageColumn(items: categorizedItems.images)
                        Divider()
                            .background(Color.white.opacity(0.1))
                        categoryColumn(
                            title: "Other",
                            icon: "doc.plaintext",
                            color: .cyan,
                            items: categorizedItems.other
                        )
                    }
                    .frame(height: 260)
                }
                .background(backgroundView)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(minWidth: 600, idealWidth: 600, maxWidth: .infinity, minHeight: 260, idealHeight: 260, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            .onTapGesture {
                isCountdownActive = false
                NotificationCenter.default.post(name: Notification.Name("CancelNanoPastebinAutoDismiss"), object: nil)
            }
            .onAppear {
                withAnimation(.linear(duration: 5.0)) {
                    countdownProgress = 1.0
                }
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onAppear {
                        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                            if event.keyCode == 53 {
                                onDismiss()
                                return nil
                            }
                            return event
                        }
                    }
            )
        }
    }
    
    @ViewBuilder
    private func categoryColumn(title: String, icon: String, color: Color, items: [ClipboardItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            
            // Items
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items) { item in
                        itemRow(item: item, color: color)
                    }
                }
                .padding(8)
            }
            
            Spacer(minLength: 0)
        }
        .frame(width: 150)
    }
    
    @ViewBuilder
    private func imageColumn(items: [ClipboardItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                
                Text("Images")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            
            // Images grid
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(items) { item in
                        if let imageData = item.imageData,
                           let nsImage = NSImage(data: imageData) {
                            DraggableImageThumbnail(
                                image: nsImage,
                                imageData: imageData
                            )
                            .frame(maxHeight: 40)
                            .onTapGesture {
                                // Copy image data to clipboard
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setData(imageData, forType: .png)
                                onDismiss()
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.1))
                                .frame(height: 40)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.blue.opacity(0.3))
                                )
                        }
                    }
                }
                .padding(8)
            }
            
            Spacer(minLength: 0)
        }
        .frame(width: 150)
    }
    
    @ViewBuilder
    private func itemRow(item: ClipboardItem, color: Color) -> some View {
        HStack {
            Text(item.content)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(color.opacity(0.05))
        .cornerRadius(4)
        .onTapGesture {
            // Copy to clipboard
            onCopy(item.content)
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Dark background with larger corner radius
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
            
            // Subtle border
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
