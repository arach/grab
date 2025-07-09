import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let contentType: String
    let timestamp: Date
    let imageData: Data?
    
    init(content: String, contentType: String, timestamp: Date, imageData: Data? = nil) {
        self.id = UUID()
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        self.imageData = imageData
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
}

class ClipboardHistoryManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private let maxItems = 100
    private let userDefaults = UserDefaults.standard
    private let storageKey = "clipboardHistory"
    
    init() {
        loadHistory()
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
        
        // Keep only the most recent items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        saveHistory()
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        saveHistory()
    }
    
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        // Only save text-based items to UserDefaults (images are too large)
        let textItems = items.compactMap { item -> ClipboardItem? in
            if item.imageData == nil {
                return item
            }
            return ClipboardItem(
                content: item.content,
                contentType: item.contentType,
                timestamp: item.timestamp,
                imageData: nil
            )
        }
        
        if let encoded = try? JSONEncoder().encode(textItems) {
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