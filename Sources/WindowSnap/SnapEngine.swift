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
    case expandSize
    case shrinkSize
}

public final class SnapEngine: @unchecked Sendable {
    public static let shared = SnapEngine()
    
    // Cycle memory
    private var lastAction: SnapAction?
    private var lastActionTime: Date = .distantPast
    private var cycleStep: Int = 0
    
    // Drag-to-snap state
    private var isDragging: Bool = false
    private var currentDragSnapTarget: SnapAction?
    private var dragMonitor: Any?
    
    private init() {
        setupDragToSnapMonitor()
    }
    
    // MARK: - Drag to Snap (Rectangle Pro)
    private func setupDragToSnapMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return }
            let defaults = UserDefaults.standard
            let dragEnabled = defaults.object(forKey: "dragToSnapEnabled") as? Bool ?? true
            guard dragEnabled else { return }
            
            if event.type == .leftMouseDragged {
                self.handleMouseDrag()
            } else if event.type == .leftMouseUp {
                self.handleMouseUp()
            }
        }
    }
    
    private func handleMouseDrag() {
        let mouseLoc = NSEvent.mouseLocation
        let screen = SystemUtils.screenWithMouse()
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        let edgeThreshold: CGFloat = 20.0
        let cornerThreshold: CGFloat = 50.0
        
        var targetAction: SnapAction?
        var previewRect: NSRect?
        
        let halfW = visibleFrame.width / 2.0
        let halfH = visibleFrame.height / 2.0
        
        // 1. Top Corners or Top Edge (Maximize)
        if mouseLoc.y >= frame.maxY - edgeThreshold {
            if mouseLoc.x <= frame.minX + cornerThreshold {
                targetAction = .topLeftQuarter
                previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY + halfH, width: halfW, height: halfH)
            } else if mouseLoc.x >= frame.maxX - cornerThreshold {
                targetAction = .topRightQuarter
                previewRect = NSRect(x: visibleFrame.minX + halfW, y: visibleFrame.minY + halfH, width: halfW, height: halfH)
            } else {
                targetAction = .maximize
                previewRect = visibleFrame
            }
        }
        // 2. Bottom Corners
        else if mouseLoc.y <= frame.minY + edgeThreshold {
            if mouseLoc.x <= frame.minX + cornerThreshold {
                targetAction = .bottomLeftQuarter
                previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfW, height: halfH)
            } else if mouseLoc.x >= frame.maxX - cornerThreshold {
                targetAction = .bottomRightQuarter
                previewRect = NSRect(x: visibleFrame.minX + halfW, y: visibleFrame.minY, width: halfW, height: halfH)
            } else {
                targetAction = .bottomHalf
                previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: halfH)
            }
        }
        // 3. Left Edge
        else if mouseLoc.x <= frame.minX + edgeThreshold {
            targetAction = .leftHalf
            previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfW, height: visibleFrame.height)
        }
        // 4. Right Edge
        else if mouseLoc.x >= frame.maxX - edgeThreshold {
            targetAction = .rightHalf
            previewRect = NSRect(x: visibleFrame.minX + halfW, y: visibleFrame.minY, width: halfW, height: visibleFrame.height)
        }
        
        self.currentDragSnapTarget = targetAction
        
        if let preview = previewRect {
            DispatchQueue.main.async {
                SnapOverlayController.shared.showPreview(for: preview)
            }
        } else {
            DispatchQueue.main.async {
                SnapOverlayController.shared.hidePreview()
            }
        }
    }
    
    private func handleMouseUp() {
        if let target = currentDragSnapTarget {
            DispatchQueue.main.async {
                self.snapFocusedWindow(to: target)
                SnapOverlayController.shared.hidePreview()
            }
            self.currentDragSnapTarget = nil
        }
    }
    
    // MARK: - Keyboard Shortcuts (Rectangle Pro)
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        let defaults = UserDefaults.standard
        let isEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        guard type == .keyDown, isEnabled else { return event }
        
        let flags = event.flags
        let cycleEnabled = defaults.object(forKey: "cycleRepeatedShortcuts") as? Bool ?? true
        
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
        let now = Date()
        let isRecent = now.timeIntervalSince(lastActionTime) < 1.4
        
        switch keyCode {
        // Halves & Cycling Thirds
        case 123: // Left Arrow
            var action: SnapAction = .leftHalf
            if cycleEnabled && isRecent && (lastAction == .leftHalf || lastAction == .leftTwoThirds || lastAction == .leftThird) {
                cycleStep = (cycleStep + 1) % 3
                action = cycleStep == 0 ? .leftHalf : (cycleStep == 1 ? .leftTwoThirds : .leftThird)
            } else {
                cycleStep = 0
            }
            recordAction(action)
            DispatchQueue.main.async { self.snapFocusedWindow(to: action) }
            return nil
            
        case 124: // Right Arrow
            var action: SnapAction = .rightHalf
            if cycleEnabled && isRecent && (lastAction == .rightHalf || lastAction == .rightTwoThirds || lastAction == .rightThird) {
                cycleStep = (cycleStep + 1) % 3
                action = cycleStep == 0 ? .rightHalf : (cycleStep == 1 ? .rightTwoThirds : .rightThird)
            } else {
                cycleStep = 0
            }
            recordAction(action)
            DispatchQueue.main.async { self.snapFocusedWindow(to: action) }
            return nil
            
        case 126: // Up Arrow -> Top Half or Maximize
            var action: SnapAction = .topHalf
            if cycleEnabled && isRecent && (lastAction == .topHalf || lastAction == .maximize) {
                action = lastAction == .topHalf ? .maximize : .topHalf
            }
            recordAction(action)
            DispatchQueue.main.async { self.snapFocusedWindow(to: action) }
            return nil
            
        case 125: // Down Arrow -> Bottom Half or Center
            var action: SnapAction = .bottomHalf
            if cycleEnabled && isRecent && (lastAction == .bottomHalf || lastAction == .center) {
                action = lastAction == .bottomHalf ? .center : .bottomHalf
            }
            recordAction(action)
            DispatchQueue.main.async { self.snapFocusedWindow(to: action) }
            return nil
            
        // Maximize & Center
        case 36:  // Return Key -> Maximize
            recordAction(.maximize)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .maximize) }
            return nil
        case 8:   // C Key -> Center
            recordAction(.center)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .center) }
            return nil
            
        // Resize Window (+ / -)
        case 24:  // '+' / '='
            DispatchQueue.main.async { self.snapFocusedWindow(to: .expandSize) }
            return nil
        case 27:  // '-'
            DispatchQueue.main.async { self.snapFocusedWindow(to: .shrinkSize) }
            return nil
            
        // Quarters (U, I, J, K)
        case 32:  // U -> Top Left
            recordAction(.topLeftQuarter)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .topLeftQuarter) }
            return nil
        case 34:  // I -> Top Right
            recordAction(.topRightQuarter)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .topRightQuarter) }
            return nil
        case 38:  // J -> Bottom Left
            recordAction(.bottomLeftQuarter)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .bottomLeftQuarter) }
            return nil
        case 40:  // K -> Bottom Right
            recordAction(.bottomRightQuarter)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .bottomRightQuarter) }
            return nil
            
        // Thirds (D, F, G, E, T)
        case 2:   // D -> Left 1/3
            recordAction(.leftThird)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .leftThird) }
            return nil
        case 3:   // F -> Center 1/3
            recordAction(.centerThird)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .centerThird) }
            return nil
        case 5:   // G -> Right 1/3
            recordAction(.rightThird)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .rightThird) }
            return nil
        case 14:  // E -> Left 2/3
            recordAction(.leftTwoThirds)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .leftTwoThirds) }
            return nil
        case 17:  // T -> Right 2/3
            recordAction(.rightTwoThirds)
            DispatchQueue.main.async { self.snapFocusedWindow(to: .rightTwoThirds) }
            return nil
            
        default:
            return event
        }
    }
    
    private func recordAction(_ action: SnapAction) {
        self.lastAction = action
        self.lastActionTime = Date()
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
        
        // Handle expand / shrink
        if action == .expandSize || action == .shrinkSize {
            var sizeVal: AnyObject?
            var posVal: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeVal) == .success,
               AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posVal) == .success {
                var currentSize = CGSize.zero
                var currentPos = CGPoint.zero
                AXValueGetValue(sizeVal as! AXValue, .cgSize, &currentSize)
                AXValueGetValue(posVal as! AXValue, .cgPoint, &currentPos)
                
                let scale: CGFloat = (action == .expandSize) ? 1.1 : 0.9
                let newW = min(visibleFrame.width, currentSize.width * scale)
                let newH = min(visibleFrame.height, currentSize.height * scale)
                let deltaW = newW - currentSize.width
                let deltaH = newH - currentSize.height
                
                var newSize = CGSize(width: newW, height: newH)
                var newOrigin = CGPoint(x: currentPos.x - (deltaW / 2.0), y: currentPos.y - (deltaH / 2.0))
                
                if let s = AXValueCreate(.cgSize, &newSize) { AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, s) }
                if let p = AXValueCreate(.cgPoint, &newOrigin) { AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, p) }
            }
            return
        }
        
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
        case .nextDisplay, .previousDisplay, .expandSize, .shrinkSize:
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
