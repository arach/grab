import SwiftUI
import AppKit

struct CapturePreviewView: View {
    let capture: Capture
    let onAction: (CapturePreviewAction) -> Void
    
    @State private var timeRemaining: Int = 5
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            // Preview thumbnail
            previewThumbnail
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(6)
            
            // Content info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(capture.type.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Auto-dismiss countdown
                    Text("\(timeRemaining)s")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                
                Text(captureSubtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Action buttons
                HStack(spacing: 8) {
                    ActionButton(
                        icon: "eye",
                        tooltip: "Open in Viewer"
                    ) {
                        onAction(.openViewer)
                    }
                    
                    ActionButton(
                        icon: "doc.on.doc",
                        tooltip: "Copy"
                    ) {
                        onAction(.copy)
                    }
                    
                    ActionButton(
                        icon: "trash",
                        tooltip: "Delete"
                    ) {
                        onAction(.delete)
                    }
                    
                    Spacer()
                    
                    ActionButton(
                        icon: "xmark",
                        tooltip: "Dismiss"
                    ) {
                        onAction(.dismiss)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 4)
        )
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    @ViewBuilder
    private var previewThumbnail: some View {
        switch capture.type {
        case .screen, .window, .selection:
            if let image = loadCaptureImage() {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            
        case .clipboard:
            if capture.fileExtension == "png", let image = loadCaptureImage() {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if capture.fileExtension == "txt" {
                VStack(spacing: 2) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    if let text = loadCaptureText() {
                        Text(text)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var captureSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        var subtitle = formatter.string(from: capture.timestamp)
        
        if let dimensions = capture.metadata.dimensions {
            subtitle += " • \(Int(dimensions.width))×\(Int(dimensions.height))"
        }
        
        subtitle += " • \(formatFileSize(capture.fileSize))"
        
        return subtitle
    }
    
    private func loadCaptureImage() -> NSImage? {
        let capturesDirectory = getCapturesDirectory()
        let filePath = capturesDirectory.appendingPathComponent(capture.filename)
        return NSImage(contentsOf: filePath)
    }
    
    private func loadCaptureText() -> String? {
        let capturesDirectory = getCapturesDirectory()
        let filePath = capturesDirectory.appendingPathComponent(capture.filename)
        return try? String(contentsOf: filePath)
    }
    
    private func getCapturesDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Grab/captures")
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                onAction(.dismiss)
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isHovered ? .accentColor : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 20, height: 20)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .help(tooltip)
    }
}

#Preview {
    CapturePreviewView(
        capture: Capture(
            type: .screen,
            filename: "screen_2024-01-01_12-00-00.png",
            fileExtension: "png",
            fileSize: 1024000,
            metadata: CaptureMetadata(dimensions: CGSize(width: 1920, height: 1080))
        )
    ) { action in
        print("Action: \(action)")
    }
    .frame(width: 280, height: 100)
}