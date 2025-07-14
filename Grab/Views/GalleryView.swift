import SwiftUI
import AppKit

struct GalleryView: View {
    @ObservedObject var captureManager: CaptureManager
    @State private var selectedCapture: Capture?
    @State private var searchText = ""
    @State private var selectedFilter: CaptureType?
    @State private var captures: [Capture] = []
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    var filteredCaptures: [Capture] {
        return captures.filter { capture in
            let matchesSearch = searchText.isEmpty || 
                capture.filename.localizedCaseInsensitiveContains(searchText) ||
                capture.type.displayName.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter = selectedFilter == nil || capture.type == selectedFilter
            
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search captures...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
                
                // Filters
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter by Type")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    FilterButton(title: "All", icon: "square.grid.2x2", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    
                    FilterButton(title: "Screen", icon: "rectangle.inset.filled", isSelected: selectedFilter == .screen) {
                        selectedFilter = .screen
                    }
                    
                    FilterButton(title: "Window", icon: "rectangle.split.3x1", isSelected: selectedFilter == .window) {
                        selectedFilter = .window
                    }
                    
                    FilterButton(title: "Selection", icon: "rectangle.dashed", isSelected: selectedFilter == .selection) {
                        selectedFilter = .selection
                    }
                    
                    FilterButton(title: "Clipboard", icon: "doc.on.clipboard", isSelected: selectedFilter == .clipboard) {
                        selectedFilter = .clipboard
                    }
                }
                .padding(.top)
                
                Spacer()
                
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Statistics")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Total captures:")
                        Spacer()
                        Text("\(captures.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Storage used:")
                        Spacer()
                        Text(formatTotalSize())
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding()
            }
            .frame(width: 250)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Main content
            ScrollView {
                if filteredCaptures.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No captures found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Text("Try adjusting your search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredCaptures) { capture in
                            CaptureGridItem(capture: capture, isSelected: selectedCapture?.id == capture.id)
                                .onTapGesture {
                                    selectedCapture = capture
                                }
                                .contextMenu {
                                    Button("Open in Editor") {
                                        openInEditor(capture)
                                    }
                                    
                                    Button("Show in Finder") {
                                        showInFinder(capture)
                                    }
                                    
                                    Divider()
                                    
                                    Button("Delete", role: .destructive) {
                                        deleteCapture(capture)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Detail view
            if let capture = selectedCapture {
                CaptureDetailView(capture: capture) {
                    openInEditor(capture)
                }
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a capture to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .onAppear {
            // Load captures safely
            captures = captureManager.getCaptureHistory().reversed()
        }
    }
    
    private func formatTotalSize() -> String {
        let totalBytes = captures.reduce(0) { $0 + $1.fileSize }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    private func openInEditor(_ capture: Capture) {
        if let appDelegate = AppDelegate.shared {
            if appDelegate.captureEditorWindow == nil {
                appDelegate.captureEditorWindow = CaptureEditorWindow()
            }
            appDelegate.captureEditorWindow?.editCapture(capture)
        }
    }
    
    private func showInFinder(_ capture: Capture) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let capturesDir = appSupport.appendingPathComponent("Grab/captures")
        let fileURL = capturesDir.appendingPathComponent(capture.filename)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    private func deleteCapture(_ capture: Capture) {
        // TODO: Implement delete functionality
    }
}

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct CaptureGridItem: View {
    let capture: Capture
    let isSelected: Bool
    @State private var thumbnail: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                } else {
                    Rectangle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(height: 150)
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: iconForType(capture.type))
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(capture.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Text(formatDate(capture.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatFileSize(capture.fileSize))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func iconForType(_ type: CaptureType) -> String {
        switch type {
        case .screen: return "rectangle.inset.filled"
        case .window: return "rectangle.split.3x1"
        case .selection: return "rectangle.dashed"
        case .clipboard: return "doc.on.clipboard"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func loadThumbnail() {
        DispatchQueue.global(qos: .background).async {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let capturesDir = appSupport.appendingPathComponent("Grab/captures")
            let fileURL = capturesDir.appendingPathComponent(capture.filename)
            
            if let image = NSImage(contentsOf: fileURL) {
                // Create thumbnail
                let targetSize = CGSize(width: 300, height: 200)
                let thumbnail = image.resized(to: targetSize)
                
                DispatchQueue.main.async {
                    self.thumbnail = thumbnail
                }
            }
        }
    }
}

struct CaptureDetailView: View {
    let capture: Capture
    let onEdit: () -> Void
    @State private var image: NSImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(capture.filename)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // Image
            ScrollView {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Type", systemImage: "info.circle")
                    Spacer()
                    Text(capture.type.displayName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Size", systemImage: "doc")
                    Spacer()
                    Text(formatFileSize(capture.fileSize))
                        .foregroundColor(.secondary)
                }
                
                if let dimensions = capture.metadata.dimensions {
                    HStack {
                        Label("Dimensions", systemImage: "aspectratio")
                        Spacer()
                        Text("\(Int(dimensions.width)) × \(Int(dimensions.height))")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("Created", systemImage: "calendar")
                    Spacer()
                    Text(formatDate(capture.timestamp))
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 400)
        .onAppear {
            loadImage()
        }
        .onChange(of: capture.id) { _ in
            loadImage()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func loadImage() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let capturesDir = appSupport.appendingPathComponent("Grab/captures")
        let fileURL = capturesDir.appendingPathComponent(capture.filename)
        
        image = NSImage(contentsOf: fileURL)
    }
}

