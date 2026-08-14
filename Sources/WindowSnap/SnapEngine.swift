import Cocoa
import CoreGraphics
import ApplicationServices

public enum SnapAction: Sendable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case maximize
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case center
}

@MainActor
public final class SnapEngine {
    public static let shared = SnapEngine()
    
    private init() {}
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        guard type == .keyDown, AppSettings.shared.snapShortcutsEnabled else { return event }
        
        let flags = event.flags
        guard flags.contains(.maskAlternate) && (flags.contains(.maskControl) || flags.contains(.maskCommand)) else {
            return event
        }
        
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        switch keyCode {
        case 123: // Left Arrow
            snapFocusedWindow(to: .leftHalf)
            return nil
        case 124: // Right Arrow
            snapFocusedWindow(to: .rightHalf)
            return nil
        case 126: // Up Arrow
            snapFocusedWindow(to: .maximize)
            return nil
        case 125: // Down Arrow
            snapFocusedWindow(to: .center)
            return nil
        default:
            return event
        }
    }
    
    public func snapFocusedWindow(to action: SnapAction) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        
        var focusedWindowVal: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowVal) == .success,
              let windowElement = focusedWindowVal as! AXUIElement? else {
            return
        }
        
        guard let screen = SystemUtils.screenForApp(pid: frontApp.processIdentifier) ?? NSScreen.main else {
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let mainScreenHeight = NSScreen.screens[0].frame.height
        
        var targetRect: CGRect = .zero
        let halfWidth = visibleFrame.width / 2.0
        let halfHeight = visibleFrame.height / 2.0
        
        switch action {
        case .leftHalf:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .rightHalf:
            targetRect = CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .topHalf:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: visibleFrame.width, height: halfHeight)
        case .bottomHalf:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: halfHeight)
        case .maximize:
            targetRect = visibleFrame
        case .topLeftQuarter:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .topRightQuarter:
            targetRect = CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .bottomLeftQuarter:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
        case .bottomRightQuarter:
            targetRect = CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
        case .center:
            let w = visibleFrame.width * 0.7
            let h = visibleFrame.height * 0.7
            targetRect = CGRect(
                x: visibleFrame.minX + (visibleFrame.width - w) / 2.0,
                y: visibleFrame.minY + (visibleFrame.height - h) / 2.0,
                width: w,
                height: h
            )
        }
        
        let axY = mainScreenHeight - targetRect.maxY
        var origin = CGPoint(x: targetRect.minX, y: axY)
        var size = CGSize(width: targetRect.width, height: targetRect.height)
        
        if let posVal = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
    }
}
