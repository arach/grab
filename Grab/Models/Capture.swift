import Foundation
import AppKit

struct Capture: Codable {
    let id: UUID
    let timestamp: Date
    let type: CaptureType
    let filename: String
    let fileExtension: String
    let fileSize: Int64
    let metadata: CaptureMetadata
    
    init(type: CaptureType, filename: String, fileExtension: String, fileSize: Int64, metadata: CaptureMetadata) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.filename = filename
        self.fileExtension = fileExtension
        self.fileSize = fileSize
        self.metadata = metadata
    }
}

enum CaptureType: String, Codable, CaseIterable {
    case screen = "screen"
    case window = "window"
    case selection = "selection"
    case clipboard = "clipboard"
    
    var displayName: String {
        switch self {
        case .screen:
            return "Full Screen"
        case .window:
            return "Window"
        case .selection:
            return "Selection"
        case .clipboard:
            return "Clipboard"
        }
    }
}

struct CaptureMetadata: Codable {
    let dimensions: CGSize?
    let applicationName: String?
    let windowTitle: String?
    let clipboardType: ClipboardType?
    
    init(dimensions: CGSize? = nil, applicationName: String? = nil, windowTitle: String? = nil, clipboardType: ClipboardType? = nil) {
        self.dimensions = dimensions
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.clipboardType = clipboardType
    }
}

enum ClipboardType: String, Codable {
    case text = "text"
    case image = "image"
    case url = "url"
    case file = "file"
    case unknown = "unknown"
}