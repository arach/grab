import SwiftUI

struct ClipboardPreviewView: View {
    let content: String
    let contentType: String
    let imageData: Data?
    let onDismiss: () -> Void
    let onClick: () -> Void
    
    @State private var isHovered = false
    @State private var opacity = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and type
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(contentTypeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Click hint
                if isHovered {
                    Text("Click to view history")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Close button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            // Content area
            if let imageData = imageData,
               let nsImage = NSImage(data: imageData) {
                // Image preview
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 140)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            } else {
                // Text preview
                ScrollView(.vertical, showsIndicators: false) {
                    Text(content)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxHeight: 140)
            }
            
            // Footer with metadata
            HStack {
                Text("Just copied")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                // Size indicator for images or character count for text
                if imageData != nil {
                    Text(formatBytes(imageData?.count ?? 0))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    Text("\(content.count) characters")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Base layer
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(isHovered ? 0.92 : 0.88))
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(isHovered ? 0.15 : 0.08), lineWidth: 0.5)
            }
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1.0
            }
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            onClick()
        }
    }
    
    private var contentTypeLabel: String {
        switch contentType {
        case "image": return "Image"
        case "file": return "File"
        case "url": return "URL"
        case "code": return "Code"
        case "log": return "Log Output"
        case "prompt": return "Prompt"
        default: return "Text"
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private var iconName: String {
        switch contentType {
        case "image": return "photo"
        case "file": return "doc.fill"
        case "url": return "link"
        case "code": return "chevron.left.forwardslash.chevron.right"
        case "log": return "terminal"
        case "prompt": return "text.bubble"
        default: return "doc.on.clipboard"
        }
    }
    
    private var iconColor: Color {
        switch contentType {
        case "image": return .blue
        case "file": return .orange
        case "url": return .green
        case "code": return .purple
        case "log": return .yellow
        case "prompt": return .pink
        default: return .gray
        }
    }
}