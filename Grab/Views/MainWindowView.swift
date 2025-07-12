import SwiftUI

// Terminal Chic Color Palette
extension Color {
    static let terminalBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let terminalGreen = Color(red: 0.0, green: 1.0, blue: 0.0)
    static let terminalDimGreen = Color(red: 0.0, green: 0.6, blue: 0.0)
    static let terminalBorder = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let terminalText = Color(red: 0.9, green: 0.9, blue: 0.9)
    static let terminalSubtext = Color(red: 0.6, green: 0.6, blue: 0.6)
}

struct MainWindowView: View {
    @ObservedObject var clipboardHistory: ClipboardHistoryManager
    @ObservedObject var captureManager: CaptureManager
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Terminal background
            Color.terminalBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ASCII Art Header
                TerminalHeader()
                
                // Tab Selection
                TerminalTabBar(selectedTab: $selectedTab)
                
                // Terminal Border
                Rectangle()
                    .fill(Color.terminalGreen)
                    .frame(height: 1)
                
                // Content
                ZStack {
                    switch selectedTab {
                    case 0:
                        ClipboardTab(clipboardHistory: clipboardHistory, searchText: $searchText)
                    case 1:
                        CapturesTab(captureManager: captureManager)
                    case 2:
                        ActionsTab()
                    default:
                        SettingsTab()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
    }
}

struct TerminalHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("""
                 ██████╗ ██████╗  █████╗ ██████╗ 
                ██╔════╝ ██╔══██╗██╔══██╗██╔══██╗
                ██║  ███╗██████╔╝███████║██████╔╝
                ██║   ██║██╔══██╗██╔══██║██╔══██╗
                ╚██████╔╝██║  ██║██║  ██║██████╔╝
                 ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
                """)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .padding(.top, 20)
            
            Text("[ AI-POWERED CLIPBOARD & CAPTURE MANAGER ]")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalDimGreen)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .background(Color.terminalBackground)
    }
}

struct TerminalTabBar: View {
    @Binding var selectedTab: Int
    let tabs = [
        ("CLIPBOARD", "clipboard.txt"),
        ("CAPTURES", "screen.png"),
        ("ACTIONS", "hotkeys.sh"),
        ("SETTINGS", "config.ini")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TerminalTabButton(
                    title: tabs[index].0,
                    filename: tabs[index].1,
                    isSelected: selectedTab == index,
                    action: { selectedTab = index }
                )
                
                if index < tabs.count - 1 {
                    Text("│")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalBorder)
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.terminalBackground)
    }
}

struct TerminalTabButton: View {
    let title: String
    let filename: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(isSelected ? "▼" : "▸")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .monospaced))
                Text(filename)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .opacity(0.6)
            }
            .foregroundColor(isSelected ? .terminalGreen : .terminalSubtext)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Clipboard Tab
struct ClipboardTab: View {
    @ObservedObject var clipboardHistory: ClipboardHistoryManager
    @Binding var searchText: String
    @State private var selectedItem: ClipboardItem?
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardHistory.items
        }
        return clipboardHistory.items.filter { item in
            item.content.localizedCaseInsensitiveContains(searchText) ||
            item.appName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        HSplitView {
            // List Panel
            VStack(spacing: 0) {
                // Terminal-style search
                HStack(spacing: 8) {
                    Text("$")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                    
                    Text("grep")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalDimGreen)
                    
                    TextField("pattern", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalText)
                    
                    Text("clipboard.history")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalSubtext)
                }
                .padding(12)
                .background(Color.black.opacity(0.3))
                
                Rectangle()
                    .fill(Color.terminalBorder)
                    .frame(height: 1)
                
                // Items list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            TerminalClipboardRow(
                                item: item,
                                index: index,
                                isSelected: selectedItem?.id == item.id,
                                onSelect: { selectedItem = item }
                            )
                            
                            if index < filteredItems.count - 1 {
                                Rectangle()
                                    .fill(Color.terminalBorder.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 350, idealWidth: 400)
            .background(Color.black.opacity(0.2))
            
            // Detail Panel
            if let selected = selectedItem {
                TerminalDetailView(item: selected)
                    .frame(minWidth: 500)
            } else {
                TerminalEmptyView(message: "NO SELECTION")
                    .frame(minWidth: 500)
            }
        }
    }
}

struct TerminalClipboardRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Index
                Text(String(format: "%03d", index))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalDimGreen)
                    .frame(width: 30)
                
                // Type indicator
                Text(item.typeSymbol)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(item.typeTerminalColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview)
                        .lineLimit(1)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(isSelected ? .terminalGreen : .terminalText)
                    
                    HStack(spacing: 8) {
                        Text("[\(item.contentType)]")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalSubtext)
                        
                        Text("•")
                            .foregroundColor(.terminalBorder)
                        
                        Text(item.timeAgo)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalSubtext)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Text(">")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.terminalGreen.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TerminalDetailView: View {
    let item: ClipboardItem
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("╔═══════════════════════════════════════════════════════════════╗")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalBorder)
                
                HStack {
                    Text("║")
                        .foregroundColor(.terminalBorder)
                    
                    Text("TYPE:")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalDimGreen)
                    
                    Text(item.contentType.uppercased())
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                    
                    Text("│")
                        .foregroundColor(.terminalBorder)
                        .padding(.horizontal, 8)
                    
                    Text("TIME:")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalDimGreen)
                    
                    Text(item.timestamp, format: .dateTime)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalText)
                    
                    Spacer()
                    
                    Text("║")
                        .foregroundColor(.terminalBorder)
                }
                .padding(.horizontal, 0)
                
                Text("╠═══════════════════════════════════════════════════════════════╣")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalBorder)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Content
            ScrollView {
                HStack(alignment: .top) {
                    Text("║")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalBorder)
                    
                    if item.isImage {
                        Text("[IMAGE DATA - \(item.fileSize ?? 0) bytes]")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalSubtext)
                            .padding(.vertical, 8)
                    } else {
                        Text(item.content)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalText)
                            .padding(.vertical, 8)
                            .textSelection(.enabled)
                    }
                    
                    Spacer()
                    
                    Text("║")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalBorder)
                }
                .padding(.horizontal, 16)
            }
            
            // Footer with actions
            VStack(alignment: .leading, spacing: 4) {
                Text("╠═══════════════════════════════════════════════════════════════╣")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalBorder)
                
                HStack {
                    Text("║")
                        .foregroundColor(.terminalBorder)
                    
                    Button(action: copyToClipboard) {
                        HStack(spacing: 4) {
                            Text("[")
                                .foregroundColor(.terminalBorder)
                            Text(isCopied ? "COPIED!" : "COPY")
                                .foregroundColor(.terminalGreen)
                            Text("]")
                                .foregroundColor(.terminalBorder)
                        }
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("│")
                        .foregroundColor(.terminalBorder)
                        .padding(.horizontal, 8)
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Text("[")
                                .foregroundColor(.terminalBorder)
                            Text("SHARE")
                                .foregroundColor(.terminalGreen)
                            Text("]")
                                .foregroundColor(.terminalBorder)
                        }
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text("║")
                        .foregroundColor(.terminalBorder)
                }
                
                Text("╚═══════════════════════════════════════════════════════════════╝")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalBorder)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.3))
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// MARK: - Captures Tab
struct CapturesTab: View {
    @ObservedObject var captureManager: CaptureManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("$")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.terminalGreen)
                
                Text("ls -la ~/captures/")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalText)
            }
            .padding(16)
            
            Rectangle()
                .fill(Color.terminalBorder)
                .frame(height: 1)
            
            if captureManager.recentCaptures.isEmpty {
                TerminalEmptyView(message: "NO CAPTURES FOUND")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Directory header
                        Text("total \(captureManager.recentCaptures.count)")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalSubtext)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        ForEach(Array(captureManager.recentCaptures.enumerated()), id: \.element.id) { index, capture in
                            TerminalCaptureRow(capture: capture)
                            
                            if index < captureManager.recentCaptures.count - 1 {
                                Rectangle()
                                    .fill(Color.terminalBorder.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
}

struct TerminalCaptureRow: View {
    let capture: Capture
    
    var body: some View {
        HStack(spacing: 12) {
            // Permissions
            Text("-rw-r--r--")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalSubtext)
            
            // Size
            Text(formatFileSize(capture.fileSize))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalText)
                .frame(width: 60, alignment: .trailing)
            
            // Date
            Text(capture.timestamp, format: .dateTime.day().month().hour().minute())
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalText)
            
            // Filename
            Text("\(capture.filename).\(capture.fileExtension)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            Spacer()
            
            // Type badge
            Text("[\(capture.type.displayName)]")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalDimGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.0fK", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.1fM", mb)
        }
    }
}

// MARK: - Actions Tab
struct ActionsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("#!/bin/bash")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalDimGreen)
                
                Text("# GRAB HOTKEYS AND ACTIONS")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalSubtext)
                
                // Sections
                TerminalActionSection(
                    title: "CAPTURE_FUNCTIONS",
                    actions: [
                        ("capture_screen()", "⌘⇧3", "Full screen capture"),
                        ("capture_window()", "⌘⇧4", "Active window capture"),
                        ("capture_selection()", "⌘⇧5", "Selection area capture")
                    ]
                )
                
                TerminalActionSection(
                    title: "CLIPBOARD_FUNCTIONS",
                    actions: [
                        ("show_history()", "⌘⇧V", "Display clipboard history"),
                        ("save_clipboard()", "⌘⇧S", "Save current clipboard"),
                        ("nano_pastebin()", "⌘⇧N", "Quick share via pastebin")
                    ]
                )
                
                TerminalActionSection(
                    title: "AI_FUNCTIONS",
                    actions: [
                        ("smart_categorize()", "none", "Auto-categorize content"),
                        ("extract_text()", "none", "OCR from images"),
                        ("generate_summary()", "none", "AI-powered summarization")
                    ]
                )
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
}

struct TerminalActionSection: View {
    let title: String
    let actions: [(function: String, shortcut: String, description: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("# \(title)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .padding(.bottom, 4)
            
            ForEach(actions, id: \.function) { action in
                HStack(spacing: 0) {
                    Text(action.function)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalText)
                        .frame(width: 200, alignment: .leading)
                    
                    Text(" # ")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalSubtext)
                    
                    if action.shortcut != "none" {
                        Text("[\(action.shortcut)]")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalGreen)
                            .frame(width: 80)
                    } else {
                        Text("[--]")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.terminalBorder)
                            .frame(width: 80)
                    }
                    
                    Text(action.description)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.terminalSubtext)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Settings Tab
struct SettingsTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = false
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("# GRAB CONFIGURATION FILE")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalSubtext)
                
                Text("# ~/.config/grab/config.ini")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalSubtext.opacity(0.7))
                
                // General Section
                Group {
                    Text("[GENERAL]")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                        .padding(.top, 10)
                    
                    TerminalToggleSetting(
                        key: "launch_at_login",
                        value: $launchAtLogin,
                        description: "Start Grab when macOS starts"
                    )
                    
                    TerminalToggleSetting(
                        key: "show_in_dock",
                        value: $showInDock,
                        description: "Display icon in dock"
                    )
                }
                
                // History Section
                Group {
                    Text("[CLIPBOARD]")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                        .padding(.top, 20)
                    
                    TerminalNumberSetting(
                        key: "max_history_items",
                        value: $maxHistoryItems,
                        description: "Maximum clipboard history entries"
                    )
                }
                
                // About Section
                Group {
                    Text("[ABOUT]")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                        .padding(.top, 20)
                    
                    TerminalInfoRow(key: "version", value: "0.1.0")
                    TerminalInfoRow(key: "build", value: "2024.001")
                    TerminalInfoRow(key: "website", value: "https://arach.github.io/grab")
                    TerminalInfoRow(key: "license", value: "MIT")
                }
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
    }
}

struct TerminalToggleSetting: View {
    let key: String
    @Binding var value: Bool
    let description: String
    
    var body: some View {
        HStack {
            Text("\(key) = ")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalText)
            
            Button(action: { value.toggle() }) {
                Text(value ? "true" : "false")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalGreen)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(" # \(description)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalSubtext)
            
            Spacer()
        }
    }
}

struct TerminalNumberSetting: View {
    let key: String
    @Binding var value: Int
    let description: String
    @State private var textValue: String = ""
    
    var body: some View {
        HStack {
            Text("\(key) = ")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalText)
            
            TextField("", text: $textValue)
                .frame(width: 60)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .onAppear { textValue = String(value) }
                .onChange(of: textValue) { newValue in
                    if let intValue = Int(newValue) {
                        value = intValue
                    }
                }
            
            Text(" # \(description)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalSubtext)
            
            Spacer()
        }
    }
}

struct TerminalInfoRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(key) = ")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalText)
            
            if value.starts(with: "http") {
                Link(value, destination: URL(string: value)!)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalGreen)
            } else {
                Text(value)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalGreen)
            }
            
            Spacer()
        }
    }
}

// MARK: - Helper Views
struct TerminalEmptyView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text("╔═══════════════════════════════════╗")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalBorder)
            
            HStack {
                Text("║")
                    .foregroundColor(.terminalBorder)
                Text(message.padding(toLength: 33, withPad: " ", startingAt: 0))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.terminalSubtext)
                Text("║")
                    .foregroundColor(.terminalBorder)
            }
            
            Text("╚═══════════════════════════════════╝")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.terminalBorder)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extensions
extension ClipboardItem {
    var typeSymbol: String {
        if isImage { return "◉" }
        if isURL { return "⛓" }
        if isCode { return "⟨⟩" }
        if isPrompt { return "❯" }
        if isLog { return "▤" }
        return "¶"
    }
    
    var typeTerminalColor: Color {
        if isImage { return Color(red: 0.5, green: 0.5, blue: 1.0) }
        if isURL { return Color(red: 0.0, green: 0.8, blue: 0.8) }
        if isCode { return Color(red: 1.0, green: 0.6, blue: 0.0) }
        if isPrompt { return Color(red: 1.0, green: 1.0, blue: 0.0) }
        if isLog { return Color(red: 0.8, green: 0.8, blue: 0.8) }
        return .terminalText
    }
    
    var preview: String {
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first ?? content
        if firstLine.count > 60 {
            return String(firstLine.prefix(57)) + "..."
        }
        return firstLine
    }
    
    var appName: String {
        return "clipboard"  // Terminal style - lowercase
    }
    
    var isURL: Bool {
        return contentType.lowercased() == "url" || 
               content.hasPrefix("http://") || 
               content.hasPrefix("https://")
    }
    
    var isCode: Bool {
        return contentType.lowercased() == "code"
    }
}