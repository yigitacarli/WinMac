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
    case leftThird
    case centerThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds
    case center
    case nextDisplay
    case previousDisplay
}

public final class SnapEngine: @unchecked Sendable {
    public static let shared = SnapEngine()
    
    private init() {}
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        let defaults = UserDefaults.standard
        let isEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        guard type == .keyDown, isEnabled else { return event }
        
        let flags = event.flags
        
        // 1. Multi-display moves: Option + Control + Command + Left/Right
        if flags.contains(.maskAlternate) && flags.contains(.maskControl) && flags.contains(.maskCommand) {
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == 123 { // Left
                DispatchQueue.main.async { self.moveFocusedWindowToDisplay(direction: -1) }
                return nil
            } else if keyCode == 124 { // Right
                DispatchQueue.main.async { self.moveFocusedWindowToDisplay(direction: 1) }
                return nil
            }
        }
        
        // 2. Standard Rectangle Snap: Option + Control
        guard flags.contains(.maskAlternate) && flags.contains(.maskControl) else {
            return event
        }
        
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        switch keyCode {
        // Halves
        case 123: // Left Arrow
            DispatchQueue.main.async { self.snapFocusedWindow(to: .leftHalf) }
            return nil
        case 124: // Right Arrow
            DispatchQueue.main.async { self.snapFocusedWindow(to: .rightHalf) }
            return nil
        case 126: // Up Arrow
            DispatchQueue.main.async { self.snapFocusedWindow(to: .topHalf) }
            return nil
        case 125: // Down Arrow
            DispatchQueue.main.async { self.snapFocusedWindow(to: .bottomHalf) }
            return nil
            
        // Maximize & Center
        case 36:  // Return Key -> Maximize
            DispatchQueue.main.async { self.snapFocusedWindow(to: .maximize) }
            return nil
        case 8:   // C Key -> Center
            DispatchQueue.main.async { self.snapFocusedWindow(to: .center) }
            return nil
            
        // Quarters (U, I, J, K)
        case 32:  // U -> Top Left
            DispatchQueue.main.async { self.snapFocusedWindow(to: .topLeftQuarter) }
            return nil
        case 34:  // I -> Top Right
            DispatchQueue.main.async { self.snapFocusedWindow(to: .topRightQuarter) }
            return nil
        case 38:  // J -> Bottom Left
            DispatchQueue.main.async { self.snapFocusedWindow(to: .bottomLeftQuarter) }
            return nil
        case 40:  // K -> Bottom Right
            DispatchQueue.main.async { self.snapFocusedWindow(to: .bottomRightQuarter) }
            return nil
            
        // Thirds (D, F, G, E, T)
        case 2:   // D -> Left 1/3
            DispatchQueue.main.async { self.snapFocusedWindow(to: .leftThird) }
            return nil
        case 3:   // F -> Center 1/3
            DispatchQueue.main.async { self.snapFocusedWindow(to: .centerThird) }
            return nil
        case 5:   // G -> Right 1/3
            DispatchQueue.main.async { self.snapFocusedWindow(to: .rightThird) }
            return nil
        case 14:  // E -> Left 2/3
            DispatchQueue.main.async { self.snapFocusedWindow(to: .leftTwoThirds) }
            return nil
        case 17:  // T -> Right 2/3
            DispatchQueue.main.async { self.snapFocusedWindow(to: .rightTwoThirds) }
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
        
        let gap = CGFloat(UserDefaults.standard.double(forKey: "snapWindowGaps"))
        let visibleFrame = screen.visibleFrame.insetBy(dx: gap, dy: gap)
        let mainScreenHeight = NSScreen.screens[0].frame.height
        
        var targetRect: CGRect = .zero
        
        let halfWidth = visibleFrame.width / 2.0
        let halfHeight = visibleFrame.height / 2.0
        let thirdWidth = visibleFrame.width / 3.0
        let twoThirdsWidth = (visibleFrame.width * 2.0) / 3.0
        
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
            
        case .leftThird:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .centerThird:
            targetRect = CGRect(x: visibleFrame.minX + thirdWidth, y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .rightThird:
            targetRect = CGRect(x: visibleFrame.minX + (thirdWidth * 2.0), y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .leftTwoThirds:
            targetRect = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: twoThirdsWidth, height: visibleFrame.height)
        case .rightTwoThirds:
            targetRect = CGRect(x: visibleFrame.minX + thirdWidth, y: visibleFrame.minY, width: twoThirdsWidth, height: visibleFrame.height)
            
        case .center:
            let w = visibleFrame.width * 0.72
            let h = visibleFrame.height * 0.72
            targetRect = CGRect(
                x: visibleFrame.minX + (visibleFrame.width - w) / 2.0,
                y: visibleFrame.minY + (visibleFrame.height - h) / 2.0,
                width: w,
                height: h
            )
        case .nextDisplay, .previousDisplay:
            return
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
    
    public func moveFocusedWindowToDisplay(direction: Int) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let screens = NSScreen.screens
        guard screens.count > 1 else { return }
        
        guard let currentScreen = SystemUtils.screenForApp(pid: frontApp.processIdentifier),
              let currentIndex = screens.firstIndex(of: currentScreen) else {
            return
        }
        
        let nextIndex = (currentIndex + direction + screens.count) % screens.count
        let targetScreen = screens[nextIndex]
        
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedWindowVal: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowVal) == .success,
              let windowElement = focusedWindowVal as! AXUIElement? else {
            return
        }
        
        let targetFrame = targetScreen.visibleFrame
        let mainScreenHeight = screens[0].frame.height
        
        var origin = CGPoint(x: targetFrame.minX + 50, y: mainScreenHeight - targetFrame.maxY + 50)
        if let posVal = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
    }
}
