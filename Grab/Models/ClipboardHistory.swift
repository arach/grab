import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let contentType: String
    let timestamp: Date
    let dataFileName: String? // Store filename for any data (images, files, etc.)
    let fileSize: Int64? // Track file size for storage monitoring
    
    // Non-persistent imageData for in-memory access
    var imageData: Data? {
        get {
            guard let fileName = dataFileName, contentType.lowercased() == "image" else { return nil }
            let clipboardDir = ClipboardHistoryManager.getClipboardDirectory()
            let fileURL = clipboardDir.appendingPathComponent(fileName)
            return try? Data(contentsOf: fileURL)
        }
    }
    
    init(content: String, contentType: String, timestamp: Date, imageData: Data? = nil) {
        self.id = UUID()
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        
        // Determine if we should save data to file
        let shouldSaveToFile = imageData != nil || content.count > 10000 // Large text gets saved as file
        
        if shouldSaveToFile {
            let fileName = Self.generateFileName(for: contentType, id: id)
            let clipboardDir = ClipboardHistoryManager.getClipboardDirectory()
            let fileURL = clipboardDir.appendingPathComponent(fileName)
            
            do {
                // Create full directory structure including subdirectories
                let parentDirectory = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
                
                if let imageData = imageData {
                    // Save image data
                    try imageData.write(to: fileURL)
                    self.fileSize = Int64(imageData.count)
                    print("💾 Saved \(contentType) data (\(Self.formatBytes(Int64(imageData.count)))) to: \(fileName)")
                } else {
                    // Save large text content as file
                    let contentData = content.data(using: .utf8) ?? Data()
                    if contentType.lowercased() == "url" {
                        // Create proper .webloc file
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
                        try weblocContent.write(to: fileURL, atomically: true, encoding: .utf8)
                        self.fileSize = Int64(weblocContent.utf8.count)
                    } else {
                        try contentData.write(to: fileURL)
                        self.fileSize = Int64(contentData.count)
                    }
                    print("💾 Saved \(contentType) file (\(Self.formatBytes(self.fileSize!))) to: \(fileName)")
                }
                
                self.dataFileName = fileName
            } catch {
                print("❌ Failed to save \(contentType) data: \(error)")
                self.dataFileName = nil
                self.fileSize = nil
            }
        } else {
            self.dataFileName = nil
            self.fileSize = nil
        }
    }
    
    private static func generateFileName(for contentType: String, id: UUID) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        switch contentType.lowercased() {
        case "image":
            return "images/clipboard_\(timestamp)_\(id.uuidString.prefix(8)).png"
        case "url":
            return "urls/clipboard_\(timestamp)_\(id.uuidString.prefix(8)).webloc"
        case "code":
            return "code/clipboard_\(timestamp)_\(id.uuidString.prefix(8)).txt"
        case "file":
            return "files/clipboard_\(timestamp)_\(id.uuidString.prefix(8)).txt"
        default:
            return "text/clipboard_\(timestamp)_\(id.uuidString.prefix(8)).txt"
        }
    }
    
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // Computed properties for display
    var displayContent: String {
        if content.count > 200 {
            return String(content.prefix(200)) + "..."
        }
        return content
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

class ClipboardHistoryManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private let maxStorageMB = 100 // 100MB limit
    private let maxItems = 1000 // Secondary limit to prevent excessive memory usage
    private let userDefaults = UserDefaults.standard
    private let storageKey = "clipboardHistory"
    
    init() {
        loadHistory()
    }
    
    static func getClipboardDirectory() -> URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupportDir.appendingPathComponent("Grab/clipboard_history")
    }
    
    static func getStorageInfo() -> (totalSize: Int64, itemCount: Int, warning: String?) {
        let directory = getClipboardDirectory()
        var totalSize: Int64 = 0
        var itemCount = 0
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                if let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                    itemCount += 1
                }
            }
        } catch {
            // Directory doesn't exist or is empty
        }
        
        let maxSizeMB = 100 // 100MB limit
        let maxSizeBytes = Int64(maxSizeMB * 1024 * 1024)
        
        var warning: String? = nil
        if totalSize > maxSizeBytes {
            warning = "Clipboard history using \(formatBytes(totalSize)). Consider clearing old items."
        } else if totalSize > maxSizeBytes / 2 {
            warning = "Clipboard history using \(formatBytes(totalSize)). Storage limit is \(maxSizeMB)MB."
        }
        
        return (totalSize, itemCount, warning)
    }
    
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func getCurrentStorageUsage() -> Int64 {
        let (totalSize, _, _) = Self.getStorageInfo()
        return totalSize
    }
    
    private func getMaxStorageBytes() -> Int64 {
        return Int64(maxStorageMB * 1024 * 1024)
    }
    
    func addItem(content: String, contentType: String, imageData: Data? = nil) {
        // Don't add duplicates of the most recent item
        if let lastItem = items.first, lastItem.content == content {
            return
        }
        
        let newItem = ClipboardItem(
            content: content,
            contentType: contentType,
            timestamp: Date(),
            imageData: imageData
        )
        
        items.insert(newItem, at: 0) // Add to beginning
        
        // Clean up old items based on storage size (100MB limit) and item count (1000 limit)
        let maxStorageBytes = getMaxStorageBytes()
        var currentStorageUsage = getCurrentStorageUsage()
        var removedCount = 0
        
        // Remove oldest items until we're under the storage limit or item count limit
        while (currentStorageUsage > maxStorageBytes || items.count > maxItems) && items.count > 1 {
            let oldestItem = items.removeLast()
            removedCount += 1
            
            // Clean up data file if it exists
            if let fileName = oldestItem.dataFileName {
                let clipboardDir = Self.getClipboardDirectory()
                let fileURL = clipboardDir.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: fileURL)
                
                // Update storage usage
                if let fileSize = oldestItem.fileSize {
                    currentStorageUsage -= fileSize
                }
                print("🗑️ Cleaned up old file: \(fileName) (freed \(Self.formatBytes(oldestItem.fileSize ?? 0)))")
            }
        }
        
        if removedCount > 0 {
            print("🧹 Cleaned up \(removedCount) old items to stay under \(maxStorageMB)MB limit")
            print("📊 Current storage usage: \(Self.formatBytes(currentStorageUsage)) / \(maxStorageMB)MB")
        }
        
        saveHistory()
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        let item = items[index]
        
        // Clean up data file if it exists
        if let fileName = item.dataFileName {
            let clipboardDir = Self.getClipboardDirectory()
            let fileURL = clipboardDir.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
            print("🗑️ Removed file: \(fileName)")
        }
        
        items.remove(at: index)
        saveHistory()
    }
    
    func clearHistory() {
        // Clean up all image files
        let clipboardDir = Self.getClipboardDirectory()
        try? FileManager.default.removeItem(at: clipboardDir)
        
        items.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        // Now we can save all items since images are stored as file references
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }
        
        items = decoded
    }
}