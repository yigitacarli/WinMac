import Cocoa
import ApplicationServices

public final class AccessibilityElement: @unchecked Sendable {
    public let axElement: AXUIElement
    
    public init(_ axElement: AXUIElement) {
        self.axElement = axElement
    }
    
    public static func systemWide() -> AccessibilityElement {
        return AccessibilityElement(AXUIElementCreateSystemWide())
    }
    
    public static func application(for pid: pid_t) -> AccessibilityElement {
        return AccessibilityElement(AXUIElementCreateApplication(pid))
    }
    
    public func getAttribute<T>(_ attribute: String, as type: T.Type) -> T? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(axElement, attribute as CFString, &value)
        guard result == .success, let unwrapped = value else { return nil }
        return unwrapped as? T
    }
    
    public func setAttribute<T>(_ attribute: String, value: T) -> Bool {
        let result = AXUIElementSetAttributeValue(axElement, attribute as CFString, value as AnyObject)
        return result == .success
    }
    
    public func getPosition() -> CGPoint? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &value)
        guard result == .success, let val = value else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(val as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }
    
    public func getSize() -> CGSize? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &value)
        guard result == .success, let val = value else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(val as! AXValue, .cgSize, &size) else { return nil }
        return size
    }
    
    public func setFrame(position: CGPoint, size: CGSize, appElement: AccessibilityElement? = nil) {
        // Rectangle technique: temporarily disable AXEnhancedUserInterface for Chromium / Electron apps
        var enhancedUIState: AnyObject?
        var didDisableEnhancedUI = false
        if let app = appElement {
            if AXUIElementCopyAttributeValue(app.axElement, "AXEnhancedUserInterface" as CFString, &enhancedUIState) == .success {
                if let boolVal = enhancedUIState as? Bool, boolVal {
                    AXUIElementSetAttributeValue(app.axElement, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse)
                    didDisableEnhancedUI = true
                }
            }
        }
        
        var p = position
        var s = size
        
        // Rectangle 3-step assignment: Position -> Size -> Position
        if let posVal = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(axElement, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(axElement, kAXSizeAttribute as CFString, sizeVal)
        }
        if let posVal2 = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(axElement, kAXPositionAttribute as CFString, posVal2)
        }
        
        // Restore AXEnhancedUserInterface if disabled
        if didDisableEnhancedUI, let app = appElement {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AXUIElementSetAttributeValue(app.axElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
            }
        }
    }
    
    public func bringToFront() {
        AXUIElementPerformAction(axElement, kAXRaiseAction as CFString)
    }
}
