import AppKit
import ApplicationServices

struct UIElementInfo {
    let frame: CGRect
    let role: String
    let title: String?
    let type: UIElementType
}

class AccessibilityDetector {
    static let shared = AccessibilityDetector()
    
    private init() {}
    
    func detectUIElements(in screenRect: CGRect) -> [UIElementInfo] {
        var elements: [UIElementInfo] = []
        
        // Get the system-wide accessibility element
        let systemWide = AXUIElementCreateSystemWide()
        
        // Try to get focused application
        var focusedApp: CFTypeRef?
        AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        
        if let app = focusedApp {
            elements.append(contentsOf: getElementsFromApplication(app as! AXUIElement, in: screenRect))
        }
        
        // Also check menu bar
        elements.append(contentsOf: getMenuBarElements())
        
        return elements
    }
    
    private func getElementsFromApplication(_ app: AXUIElement, in screenRect: CGRect) -> [UIElementInfo] {
        var elements: [UIElementInfo] = []
        
        // Get all windows
        var windows: CFTypeRef?
        AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
        
        if let windowArray = windows as? [AXUIElement] {
            for window in windowArray {
                elements.append(contentsOf: getElementsFromWindow(window, in: screenRect))
            }
        }
        
        return elements
    }
    
    private func getElementsFromWindow(_ window: AXUIElement, in screenRect: CGRect) -> [UIElementInfo] {
        var elements: [UIElementInfo] = []
        
        // Get window position and size
        var position: CFTypeRef?
        var size: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size)
        
        if let posValue = position, let sizeValue = size {
            var windowPos = CGPoint.zero
            var windowSize = CGSize.zero
            AXValueGetValue(posValue as! AXValue, .cgPoint, &windowPos)
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &windowSize)
            
            let windowRect = CGRect(origin: windowPos, size: windowSize)
            
            // Only process if window intersects with our screen rect
            if windowRect.intersects(screenRect) {
                // Get all UI elements in the window
                elements.append(contentsOf: getChildElements(window, in: screenRect))
            }
        }
        
        return elements
    }
    
    private func getChildElements(_ parent: AXUIElement, in screenRect: CGRect, depth: Int = 0) -> [UIElementInfo] {
        guard depth < 10 else { return [] } // Prevent infinite recursion
        
        var elements: [UIElementInfo] = []
        
        // Get children
        var children: CFTypeRef?
        AXUIElementCopyAttributeValue(parent, kAXChildrenAttribute as CFString, &children)
        
        if let childArray = children as? [AXUIElement] {
            for child in childArray {
                if let info = getElementInfo(child) {
                    if screenRect.contains(info.frame) || screenRect.intersects(info.frame) {
                        elements.append(info)
                    }
                }
                
                // Recursively get children
                elements.append(contentsOf: getChildElements(child, in: screenRect, depth: depth + 1))
            }
        }
        
        return elements
    }
    
    private func getElementInfo(_ element: AXUIElement) -> UIElementInfo? {
        // Get role
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        
        guard let roleString = role as? String else { return nil }
        
        // Get position and size
        var position: CFTypeRef?
        var size: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size)
        
        guard let posValue = position, let sizeValue = size else { return nil }
        
        var elementPos = CGPoint.zero
        var elementSize = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &elementPos)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &elementSize)
        
        // Get title
        var title: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
        let titleString = title as? String
        
        // Determine type
        let type = uiElementType(from: roleString)
        
        return UIElementInfo(
            frame: CGRect(origin: elementPos, size: elementSize),
            role: roleString,
            title: titleString,
            type: type
        )
    }
    
    private func getMenuBarElements() -> [UIElementInfo] {
        var elements: [UIElementInfo] = []
        
        // Get menu bar
        let systemWide = AXUIElementCreateSystemWide()
        var menuBar: CFTypeRef?
        AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &menuBar)
        
        if let app = menuBar {
            var menuBarElement: CFTypeRef?
            AXUIElementCopyAttributeValue(app as! AXUIElement, kAXMenuBarAttribute as CFString, &menuBarElement)
            
            if let menuBar = menuBarElement {
                elements.append(contentsOf: getChildElements(menuBar as! AXUIElement, in: NSScreen.main?.frame ?? .zero))
            }
        }
        
        return elements
    }
    
    private func uiElementType(from role: String) -> UIElementType {
        switch role {
        case "AXButton":
            return .button
        case "AXMenuBar", "AXMenu", "AXMenuItem", "AXMenuBarItem":
            return .menu
        case "AXTextField", "AXTextArea":
            return .textField
        default:
            return .unknown
        }
    }
    
    // Check if we have accessibility permissions
    static func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        return AXIsProcessTrustedWithOptions(options)
    }
}