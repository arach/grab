import Foundation
import Carbon
import AppKit

class HotkeyManager {
    private let captureManager: CaptureManager
    private var hotkeys: [EventHotKeyRef?] = []
    
    private enum HotkeyID: UInt32 {
        case captureScreen = 1
        case captureWindow = 2
        case captureSelection = 3
        case saveClipboard = 4
    }
    
    init(captureManager: CaptureManager) {
        self.captureManager = captureManager
    }
    
    deinit {
        unregisterHotkeys()
    }
    
    func registerHotkeys() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotkeyID = EventHotKeyID()
            GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
            
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
            manager.handleHotkey(id: HotkeyID(rawValue: hotkeyID.id))
            
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)
        
        registerHotkey(.captureScreen, keyCode: 1, modifiers: UInt32(cmdKey | shiftKey))
        registerHotkey(.captureWindow, keyCode: 13, modifiers: UInt32(cmdKey | shiftKey))
        registerHotkey(.captureSelection, keyCode: 0, modifiers: UInt32(cmdKey | shiftKey))
        registerHotkey(.saveClipboard, keyCode: 8, modifiers: UInt32(cmdKey | shiftKey))
    }
    
    private func registerHotkey(_ hotkeyID: HotkeyID, keyCode: UInt32, modifiers: UInt32) {
        var hotkey: EventHotKeyRef?
        let hotkeyIDStruct = EventHotKeyID(signature: OSType(hotkeyID.rawValue), id: hotkeyID.rawValue)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &hotkey
        )
        
        if status == noErr {
            hotkeys.append(hotkey)
        } else {
            print("Failed to register hotkey \(hotkeyID): \(status)")
        }
    }
    
    private func handleHotkey(id: HotkeyID?) {
        guard let id = id else { return }
        
        switch id {
        case .captureScreen:
            captureManager.captureScreen()
        case .captureWindow:
            captureManager.captureWindow()
        case .captureSelection:
            captureManager.captureSelection()
        case .saveClipboard:
            captureManager.saveClipboard()
        }
    }
    
    func unregisterHotkeys() {
        for hotkey in hotkeys {
            if let hotkey = hotkey {
                UnregisterEventHotKey(hotkey)
            }
        }
        hotkeys.removeAll()
    }
}