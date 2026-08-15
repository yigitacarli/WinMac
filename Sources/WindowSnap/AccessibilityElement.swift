import Foundation
import Cocoa
import ApplicationServices

public final class AccessibilityElement: @unchecked Sendable {
    public let wrappedElement: AXUIElement
    public var axElement: AXUIElement { wrappedElement }
    
    public init(_ element: AXUIElement) {
        self.wrappedElement = element
    }
    
    public convenience init(_ pid: pid_t) {
        self.init(AXUIElementCreateApplication(pid))
    }
    
    public static func application(for pid: pid_t) -> AccessibilityElement {
        return AccessibilityElement(pid)
    }
    
    public convenience init?(_ position: CGPoint) {
        var element: AXUIElement?
        if AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(position.x), Float(position.y), &element) == .success,
           let el = element {
            self.init(el)
        } else {
            return nil
        }
    }
    
    public static func getWindowElementUnderCursor() -> AccessibilityElement? {
        let mouseLoc = NSEvent.mouseLocation
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main ?? NSScreen.screens[0]
        let cgPoint = CGPoint(x: mouseLoc.x, y: primaryScreen.frame.maxY - mouseLoc.y)
        
        guard let element = AccessibilityElement(cgPoint) else { return nil }
        return element.window()
    }
    
    public static func getFrontWindowElement() -> AccessibilityElement? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let app = AccessibilityElement(frontApp.processIdentifier)
        return app.focusedWindow() ?? app.mainWindow()
    }
    
    public func window() -> AccessibilityElement? {
        var current: AccessibilityElement? = self
        for _ in 0..<10 {
            guard let cur = current else { break }
            if cur.isWindow == true {
                return cur
            }
            current = cur.parent()
        }
        return nil
    }
    
    public func parent() -> AccessibilityElement? {
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(wrappedElement, kAXParentAttribute as CFString, &value) == .success,
           let val = value {
            return AccessibilityElement(val as! AXUIElement)
        }
        return nil
    }
    
    public func focusedWindow() -> AccessibilityElement? {
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(wrappedElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
           let val = value {
            return AccessibilityElement(val as! AXUIElement)
        }
        return nil
    }
    
    public func mainWindow() -> AccessibilityElement? {
        var mainWinVal: AnyObject?
        if AXUIElementCopyAttributeValue(wrappedElement, kAXMainWindowAttribute as CFString, &mainWinVal) == .success,
           let val = mainWinVal {
            return AccessibilityElement(val as! AXUIElement)
        }
        return nil
    }
    
    public var role: String? {
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(wrappedElement, kAXRoleAttribute as CFString, &value) == .success {
            return value as? String
        }
        return nil
    }
    
    public var isWindow: Bool? {
        guard let r = role else { return nil }
        return r == (kAXWindowRole as String)
    }
    
    public var pid: pid_t? {
        var p: pid_t = 0
        if AXUIElementGetPid(wrappedElement, &p) == .success {
            return p
        }
        return nil
    }
    
    public func getPosition() -> CGPoint? {
        return position
    }
    
    public func getSize() -> CGSize? {
        return size
    }
    
    public var position: CGPoint? {
        get {
            var value: AnyObject?
            if AXUIElementCopyAttributeValue(wrappedElement, kAXPositionAttribute as CFString, &value) == .success,
               let val = value {
                var point = CGPoint.zero
                if AXValueGetValue(val as! AXValue, .cgPoint, &point) {
                    return point
                }
            }
            return nil
        }
        set {
            guard var newPos = newValue else { return }
            if let posVal = AXValueCreate(.cgPoint, &newPos) {
                AXUIElementSetAttributeValue(wrappedElement, kAXPositionAttribute as CFString, posVal)
            }
        }
    }
    
    public var size: CGSize? {
        get {
            var value: AnyObject?
            if AXUIElementCopyAttributeValue(wrappedElement, kAXSizeAttribute as CFString, &value) == .success,
               let val = value {
                var size = CGSize.zero
                if AXValueGetValue(val as! AXValue, .cgSize, &size) {
                    return size
                }
            }
            return nil
        }
        set {
            guard var newSize = newValue else { return }
            if let sizeVal = AXValueCreate(.cgSize, &newSize) {
                AXUIElementSetAttributeValue(wrappedElement, kAXSizeAttribute as CFString, sizeVal)
            }
        }
    }
    
    public var frame: CGRect? {
        get {
            guard let pos = position, let sz = size else { return nil }
            return CGRect(origin: pos, size: sz)
        }
        set {
            guard let newFrame = newValue else { return }
            setFrame(newFrame)
        }
    }
    
    public func setFrame(_ newFrame: CGRect) {
        setFrame(position: newFrame.origin, size: newFrame.size, appElement: nil)
    }
    
    public func setFrame(position: CGPoint, size: CGSize, appElement: AccessibilityElement? = nil) {
        var appEl: AXUIElement? = appElement?.wrappedElement
        if appEl == nil, let p = pid {
            appEl = AXUIElementCreateApplication(p)
        }
        
        var didDisableEnhancedUI = false
        if let app = appEl {
            var enhancedUIState: AnyObject?
            if AXUIElementCopyAttributeValue(app, "AXEnhancedUserInterface" as CFString, &enhancedUIState) == .success {
                if let boolVal = enhancedUIState as? Bool, boolVal {
                    AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse)
                    didDisableEnhancedUI = true
                }
            }
        }
        
        var pos = position
        var sz = size
        
        if let posVal = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(wrappedElement, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &sz) {
            AXUIElementSetAttributeValue(wrappedElement, kAXSizeAttribute as CFString, sizeVal)
        }
        if let posVal2 = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(wrappedElement, kAXPositionAttribute as CFString, posVal2)
        }
        
        if didDisableEnhancedUI, let app = appEl {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
            }
        }
    }
    
    public func bringToFront() {
        AXUIElementPerformAction(wrappedElement, kAXRaiseAction as CFString)
    }
}
