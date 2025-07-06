import Foundation
import AppKit
import CoreGraphics
import UniformTypeIdentifiers
import UserNotifications

class CaptureManager: ObservableObject {
    private let capturesDirectory: URL
    private let capturesHistoryFile: URL
    private var captureHistory: [Capture] = []
    
    // Check if we're running in a proper app bundle
    private var isRunningInAppBundle: Bool {
        return Bundle.main.bundleIdentifier != nil
    }
    
    init() {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.capturesDirectory = appSupportDir.appendingPathComponent("Grab/captures")
        self.capturesHistoryFile = capturesDirectory.appendingPathComponent("history.json")
        
        setupCapturesDirectory()
        loadCaptureHistory()
        
        // Only request notification permission if we're running in an app bundle
        if isRunningInAppBundle {
            requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        guard isRunningInAppBundle else {
            print("Skipping notification permission request - not running in app bundle")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Notification permission granted: \(granted)")
        }
    }
    
    private func setupCapturesDirectory() {
        do {
            try FileManager.default.createDirectory(at: capturesDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create captures directory: \(error)")
        }
    }
    
    private func loadCaptureHistory() {
        guard FileManager.default.fileExists(atPath: capturesHistoryFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: capturesHistoryFile)
            captureHistory = try JSONDecoder().decode([Capture].self, from: data)
        } catch {
            print("Failed to load capture history: \(error)")
        }
    }
    
    private func saveCaptureHistory() {
        do {
            let data = try JSONEncoder().encode(captureHistory)
            try data.write(to: capturesHistoryFile)
        } catch {
            print("Failed to save capture history: \(error)")
        }
    }
    
    private func generateFilename(for type: CaptureType, extension fileExtension: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        return "\(type.rawValue)_\(timestamp).\(fileExtension)"
    }
    
    private func saveCapture(_ capture: Capture) {
        captureHistory.append(capture)
        saveCaptureHistory()
    }
    
    func captureScreen() {
        Task {
            await performScreenCapture(type: .screen)
        }
    }
    
    func captureWindow() {
        Task {
            await performScreenCapture(type: .window)
        }
    }
    
    func captureSelection() {
        Task {
            await performScreenCapture(type: .selection)
        }
    }
    
    @MainActor
    private func performScreenCapture(type: CaptureType) async {
        let screenshotTask = Process()
        screenshotTask.launchPath = "/usr/sbin/screencapture"
        
        let filename = generateFilename(for: type, extension: "png")
        let filePath = capturesDirectory.appendingPathComponent(filename)
        
        var arguments = ["-x", filePath.path]
        
        switch type {
        case .screen:
            arguments.append("-m")
        case .window:
            arguments.append("-w")
        case .selection:
            arguments.append("-s")
        case .clipboard:
            break
        }
        
        screenshotTask.arguments = arguments
        screenshotTask.launch()
        screenshotTask.waitUntilExit()
        
        if screenshotTask.terminationStatus == 0 {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath.path)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0
                
                let image = NSImage(contentsOf: filePath)
                let dimensions = image?.size ?? CGSize.zero
                
                let metadata = CaptureMetadata(dimensions: dimensions)
                let capture = Capture(
                    type: type,
                    filename: filename,
                    fileExtension: "png",
                    fileSize: fileSize,
                    metadata: metadata
                )
                
                saveCapture(capture)
                showNotification(for: capture)
            } catch {
                print("Failed to get file attributes: \(error)")
            }
        }
    }
    
    func saveClipboard() {
        let pasteboard = NSPasteboard.general
        
        if let image = pasteboard.readObjects(forClasses: [NSImage.self])?.first as? NSImage {
            saveClipboardImage(image)
        } else if let string = pasteboard.string(forType: .string) {
            saveClipboardText(string)
        } else if let url = pasteboard.string(forType: .URL) {
            saveClipboardURL(url)
        } else {
            print("No supported clipboard content found")
        }
    }
    
    private func saveClipboardImage(_ image: NSImage) {
        let filename = generateFilename(for: .clipboard, extension: "png")
        let filePath = capturesDirectory.appendingPathComponent(filename)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to convert image to PNG")
            return
        }
        
        do {
            try pngData.write(to: filePath)
            
            let metadata = CaptureMetadata(
                dimensions: image.size,
                clipboardType: .image
            )
            
            let capture = Capture(
                type: .clipboard,
                filename: filename,
                fileExtension: "png",
                fileSize: Int64(pngData.count),
                metadata: metadata
            )
            
            saveCapture(capture)
            showNotification(for: capture)
        } catch {
            print("Failed to save clipboard image: \(error)")
        }
    }
    
    private func saveClipboardText(_ text: String) {
        let filename = generateFilename(for: .clipboard, extension: "txt")
        let filePath = capturesDirectory.appendingPathComponent(filename)
        
        do {
            try text.write(to: filePath, atomically: true, encoding: .utf8)
            
            let fileSize = Int64(text.utf8.count)
            let clipboardType: ClipboardType = text.isValidURL ? .url : .text
            
            let metadata = CaptureMetadata(clipboardType: clipboardType)
            let capture = Capture(
                type: .clipboard,
                filename: filename,
                fileExtension: "txt",
                fileSize: fileSize,
                metadata: metadata
            )
            
            saveCapture(capture)
            showNotification(for: capture)
        } catch {
            print("Failed to save clipboard text: \(error)")
        }
    }
    
    private func saveClipboardURL(_ url: String) {
        let filename = generateFilename(for: .clipboard, extension: "url")
        let filePath = capturesDirectory.appendingPathComponent(filename)
        
        let urlContent = """
        [InternetShortcut]
        URL=\(url)
        """
        
        do {
            try urlContent.write(to: filePath, atomically: true, encoding: .utf8)
            
            let fileSize = Int64(urlContent.utf8.count)
            let metadata = CaptureMetadata(clipboardType: .url)
            let capture = Capture(
                type: .clipboard,
                filename: filename,
                fileExtension: "url",
                fileSize: fileSize,
                metadata: metadata
            )
            
            saveCapture(capture)
            showNotification(for: capture)
        } catch {
            print("Failed to save clipboard URL: \(error)")
        }
    }
    
    private func showNotification(for capture: Capture) {
        guard isRunningInAppBundle else {
            // Fallback to console output when notifications aren't available
            print("✅ Saved \(capture.type.displayName) capture: \(capture.filename)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Grab"
        content.body = "Saved \(capture.type.displayName) capture"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
                // Fallback to console output if notification fails
                print("✅ Saved \(capture.type.displayName) capture: \(capture.filename)")
            }
        }
    }
    
    func openCapturesFolder() {
        NSWorkspace.shared.open(capturesDirectory)
    }
    
    func getCaptureHistory() -> [Capture] {
        return captureHistory
    }
}