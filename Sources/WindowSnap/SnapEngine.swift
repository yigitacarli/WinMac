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

@MainActor
public final class SnapEngine: @unchecked Sendable {
    public static let shared = SnapEngine()
    
    // Cycle memory
    private var lastAction: SnapAction?
    private var lastActionTime: Date = .distantPast
    private var cycleStep: Int = 0
    
    // Drag-to-snap state
    private var currentDragSnapTarget: SnapAction?
    private var lastDragPoint: CGPoint?
    
    private init() {}
    
    // MARK: - Drag to Snap Engine (Rectangle Aero Snap)
    
    public func handleMouseDown(point: CGPoint) {
        lastDragPoint = point
    }
    
    public func handleMouseDrag(point: CGPoint) {
        guard UserDefaults.standard.object(forKey: "dragToSnapEnabled") as? Bool ?? true else {
            if currentDragSnapTarget != nil {
                currentDragSnapTarget = nil
                SnapOverlayController.shared.hidePreview()
            }
            return
        }
        
        lastDragPoint = point
        let cursor = NSPoint(x: point.x, y: point.y)
        
        let screens = NSScreen.screens
        guard let screen = screens.first(where: {
            cursor.x >= $0.frame.minX && cursor.x <= $0.frame.maxX &&
            cursor.y >= $0.frame.minY && cursor.y <= $0.frame.maxY
        }) ?? NSScreen.main ?? screens.first else {
            return
        }
        
        let sFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let edgeThreshold: CGFloat = 30.0
        let cornerThreshold: CGFloat = 85.0
        
        var targetAction: SnapAction?
        var previewRect: NSRect?
        
        let gaps = CGFloat(UserDefaults.standard.double(forKey: "snapWindowGaps"))
        let adjustedFrame = visibleFrame.insetBy(dx: gaps, dy: gaps)
        let halfW = (adjustedFrame.width - gaps) / 2.0
        let halfH = (adjustedFrame.height - gaps) / 2.0
        
        // 1. Top Edge & Corners
        if cursor.y >= sFrame.maxY - edgeThreshold {
            if cursor.x <= sFrame.minX + cornerThreshold {
                targetAction = .topLeftQuarter
                previewRect = NSRect(x: adjustedFrame.minX, y: adjustedFrame.minY + halfH + gaps, width: halfW, height: halfH)
            } else if cursor.x >= sFrame.maxX - cornerThreshold {
                targetAction = .topRightQuarter
                previewRect = NSRect(x: adjustedFrame.minX + halfW + gaps, y: adjustedFrame.minY + halfH + gaps, width: halfW, height: halfH)
            } else {
                targetAction = .maximize
                previewRect = adjustedFrame
            }
        }
        // 2. Bottom Edge & Corners
        else if cursor.y <= sFrame.minY + edgeThreshold {
            if cursor.x <= sFrame.minX + cornerThreshold {
                targetAction = .bottomLeftQuarter
                previewRect = NSRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: halfW, height: halfH)
            } else if cursor.x >= sFrame.maxX - cornerThreshold {
                targetAction = .bottomRightQuarter
                previewRect = NSRect(x: adjustedFrame.minX + halfW + gaps, y: adjustedFrame.minY, width: halfW, height: halfH)
            } else {
                targetAction = .bottomHalf
                previewRect = NSRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: adjustedFrame.width, height: halfH)
            }
        }
        // 3. Left Edge
        else if cursor.x <= sFrame.minX + edgeThreshold {
            targetAction = .leftHalf
            previewRect = NSRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: halfW, height: adjustedFrame.height)
        }
        // 4. Right Edge
        else if cursor.x >= sFrame.maxX - edgeThreshold {
            targetAction = .rightHalf
            previewRect = NSRect(x: adjustedFrame.minX + halfW + gaps, y: adjustedFrame.minY, width: halfW, height: adjustedFrame.height)
        }
        
        self.currentDragSnapTarget = targetAction
        
        if let preview = previewRect, let action = targetAction {
            SnapOverlayController.shared.showPreview(for: preview, action: action)
        } else {
            SnapOverlayController.shared.hidePreview()
        }
    }
    
    public func handleMouseUp() {
        guard let target = currentDragSnapTarget else {
            SnapOverlayController.shared.hidePreview()
            return
        }
        
        self.currentDragSnapTarget = nil
        SnapOverlayController.shared.hidePreview()
        
        // Execute snap with a micro-delay to let the drag finish releasing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.snapWindowAtCursorOrFocused(to: target)
        }
    }
    
    // MARK: - HotKey Dispatcher
    
    public func handleShortcutAction(_ action: SnapAction) {
        let defaults = UserDefaults.standard
        let cycleEnabled = defaults.object(forKey: "cycleRepeatedShortcuts") as? Bool ?? true
        let now = Date()
        let isRecent = now.timeIntervalSince(lastActionTime) < 1.4
        
        var effectiveAction = action
        
        if cycleEnabled && isRecent {
            switch action {
            case .leftHalf, .leftTwoThirds, .leftThird:
                cycleStep = (cycleStep + 1) % 3
                effectiveAction = cycleStep == 0 ? .leftHalf : (cycleStep == 1 ? .leftTwoThirds : .leftThird)
            case .rightHalf, .rightTwoThirds, .rightThird:
                cycleStep = (cycleStep + 1) % 3
                effectiveAction = cycleStep == 0 ? .rightHalf : (cycleStep == 1 ? .rightTwoThirds : .rightThird)
            case .topHalf, .maximize:
                effectiveAction = lastAction == .topHalf ? .maximize : .topHalf
            case .bottomHalf, .center:
                effectiveAction = lastAction == .bottomHalf ? .center : .bottomHalf
            default:
                break
            }
        } else {
            cycleStep = 0
        }
        
        self.lastAction = effectiveAction
        self.lastActionTime = now
        
        snapFocusedWindow(to: effectiveAction)
    }
    
    // MARK: - Window Manipulation Engine (Rectangle Architecture)
    
    public func snapWindowAtCursorOrFocused(to action: SnapAction) {
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main ?? NSScreen.screens[0]
        let primaryMaxY = primaryScreen.frame.maxY
        let cursorLoc = NSEvent.mouseLocation
        
        // 1. Try finding window under cursor via System-Wide Accessibility
        let sysElement = AXUIElementCreateSystemWide()
        var hitElement: AXUIElement?
        let axPointX = Float(cursorLoc.x)
        let axPointY = Float(primaryMaxY - cursorLoc.y)
        
        if AXUIElementCopyElementAtPosition(sysElement, axPointX, axPointY, &hitElement) == .success,
           let hit = hitElement {
            if let targetWindow = findWindowElement(from: hit) {
                var pid: pid_t = 0
                if AXUIElementGetPid(targetWindow, &pid) == .success {
                    let appElement = AXUIElementCreateApplication(pid)
                    if let app = NSRunningApplication(processIdentifier: pid) {
                        applySnap(windowElement: targetWindow, appElement: appElement, frontApp: app, action: action)
                        return
                    }
                }
            }
        }
        
        // 2. Fallback to focused window
        snapFocusedWindow(to: action)
    }
    
    private func findWindowElement(from element: AXUIElement) -> AXUIElement? {
        var current = element
        for _ in 0..<10 {
            var roleVal: AnyObject?
            if AXUIElementCopyAttributeValue(current, kAXRoleAttribute as CFString, &roleVal) == .success,
               let role = roleVal as? String {
                if role == (kAXWindowRole as String) {
                    return current
                }
            }
            
            var parentVal: AnyObject?
            if AXUIElementCopyAttributeValue(current, kAXParentAttribute as CFString, &parentVal) == .success,
               let parent = parentVal {
                current = parent as! AXUIElement
            } else {
                break
            }
        }
        return nil
    }
    
    public func snapFocusedWindow(to action: SnapAction) {
        let ownPid = ProcessInfo.processInfo.processIdentifier
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        // If WinMac itself is frontmost, snap WinMac's own window directly
        if frontApp.processIdentifier == ownPid {
            if let keyWin = NSApp.keyWindow ?? NSApp.mainWindow {
                let screen = keyWin.screen ?? NSScreen.main ?? NSScreen.screens[0]
                let visibleFrame = screen.visibleFrame
                let targetRect = calculateTargetRect(for: action, visibleFrame: visibleFrame)
                keyWin.setFrame(targetRect, display: true, animate: true)
                return
            }
        }
        
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        
        var focusedWindowVal: AnyObject?
        let axStatus = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowVal)
        
        if axStatus == .success, let windowElement = focusedWindowVal as! AXUIElement? {
            applySnap(windowElement: windowElement, appElement: appElement, frontApp: frontApp, action: action)
            return
        }
        
        // Fallback: try kAXMainWindowAttribute
        var mainWinVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainWinVal) == .success,
           let mainWin = mainWinVal as! AXUIElement? {
            applySnap(windowElement: mainWin, appElement: appElement, frontApp: frontApp, action: action)
            return
        }
        
        // Fallback: try first window of front app
        var windowsVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
           let windowsList = windowsVal as? [AXUIElement], let firstWin = windowsList.first {
            applySnap(windowElement: firstWin, appElement: appElement, frontApp: frontApp, action: action)
        }
    }
    
    private func calculateTargetRect(for action: SnapAction, visibleFrame: CGRect) -> CGRect {
        let gaps = CGFloat(UserDefaults.standard.double(forKey: "snapWindowGaps"))
        let adjustedFrame = visibleFrame.insetBy(dx: gaps, dy: gaps)
        
        let halfWidth = (adjustedFrame.width - gaps) / 2.0
        let halfHeight = (adjustedFrame.height - gaps) / 2.0
        let thirdWidth = (adjustedFrame.width - (gaps * 2.0)) / 3.0
        let twoThirdsWidth = (adjustedFrame.width * 2.0) / 3.0
        
        switch action {
        case .leftHalf:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: halfWidth, height: adjustedFrame.height)
        case .rightHalf:
            return CGRect(x: adjustedFrame.minX + halfWidth + gaps, y: adjustedFrame.minY, width: halfWidth, height: adjustedFrame.height)
        case .topHalf:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY + halfHeight + gaps, width: adjustedFrame.width, height: halfHeight)
        case .bottomHalf:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: adjustedFrame.width, height: halfHeight)
        case .maximize:
            return adjustedFrame
        case .topLeftQuarter:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY + halfHeight + gaps, width: halfWidth, height: halfHeight)
        case .topRightQuarter:
            return CGRect(x: adjustedFrame.minX + halfWidth + gaps, y: adjustedFrame.minY + halfHeight + gaps, width: halfWidth, height: halfHeight)
        case .bottomLeftQuarter:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: halfWidth, height: halfHeight)
        case .bottomRightQuarter:
            return CGRect(x: adjustedFrame.minX + halfWidth + gaps, y: adjustedFrame.minY, width: halfWidth, height: halfHeight)
            
        case .leftThird:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: thirdWidth, height: adjustedFrame.height)
        case .centerThird:
            return CGRect(x: adjustedFrame.minX + thirdWidth + gaps, y: adjustedFrame.minY, width: thirdWidth, height: adjustedFrame.height)
        case .rightThird:
            return CGRect(x: adjustedFrame.minX + (thirdWidth * 2.0) + (gaps * 2.0), y: adjustedFrame.minY, width: thirdWidth, height: adjustedFrame.height)
        case .leftTwoThirds:
            return CGRect(x: adjustedFrame.minX, y: adjustedFrame.minY, width: twoThirdsWidth, height: adjustedFrame.height)
        case .rightTwoThirds:
            return CGRect(x: adjustedFrame.minX + (adjustedFrame.width - twoThirdsWidth), y: adjustedFrame.minY, width: twoThirdsWidth, height: adjustedFrame.height)
            
        case .center:
            let w = adjustedFrame.width * 0.72
            let h = adjustedFrame.height * 0.72
            return CGRect(
                x: adjustedFrame.minX + (adjustedFrame.width - w) / 2.0,
                y: adjustedFrame.minY + (adjustedFrame.height - h) / 2.0,
                width: w,
                height: h
            )
        case .nextDisplay, .previousDisplay, .expandSize, .shrinkSize:
            return adjustedFrame
        }
    }
    
    private func applySnap(windowElement: AXUIElement, appElement: AXUIElement, frontApp: NSRunningApplication, action: SnapAction) {
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main ?? NSScreen.screens[0]
        let primaryMaxY = primaryScreen.frame.maxY
        
        var screen: NSScreen = primaryScreen
        
        var posVal: AnyObject?
        var sizeVal: AnyObject?
        if AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posVal) == .success,
           AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeVal) == .success,
           let pVal = posVal, let sVal = sizeVal {
            var pt = CGPoint.zero
            var sz = CGSize.zero
            AXValueGetValue(pVal as! AXValue, .cgPoint, &pt)
            AXValueGetValue(sVal as! AXValue, .cgSize, &sz)
            
            let cocoaWinRect = CGRect(
                x: pt.x,
                y: primaryMaxY - (pt.y + sz.height),
                width: sz.width,
                height: sz.height
            )
            let center = CGPoint(x: cocoaWinRect.midX, y: cocoaWinRect.midY)
            
            if let matchedScreen = NSScreen.screens.first(where: {
                center.x >= $0.frame.minX && center.x <= $0.frame.maxX &&
                center.y >= $0.frame.minY && center.y <= $0.frame.maxY
            }) ?? NSScreen.screens.first(where: { $0.frame.intersects(cocoaWinRect) }) {
                screen = matchedScreen
            }
        }
        
        let visibleFrame = screen.visibleFrame
        
        // Handle expand / shrink
        if action == .expandSize || action == .shrinkSize {
            var sizeVal2: AnyObject?
            var posVal2: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeVal2) == .success,
               AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posVal2) == .success,
               let sVal2 = sizeVal2, let pVal2 = posVal2 {
                var currentSize = CGSize.zero
                var currentPos = CGPoint.zero
                AXValueGetValue(sVal2 as! AXValue, .cgSize, &currentSize)
                AXValueGetValue(pVal2 as! AXValue, .cgPoint, &currentPos)
                
                let scale: CGFloat = (action == .expandSize) ? 1.1 : 0.9
                let newW = min(visibleFrame.width, currentSize.width * scale)
                let newH = min(visibleFrame.height, currentSize.height * scale)
                let deltaW = newW - currentSize.width
                let deltaH = newH - currentSize.height
                
                let newSize = CGSize(width: newW, height: newH)
                let newOrigin = CGPoint(x: currentPos.x - (deltaW / 2.0), y: currentPos.y - (deltaH / 2.0))
                
                setFrame(windowElement: windowElement, appElement: appElement, position: newOrigin, size: newSize)
            }
            return
        }
        
        let targetRect = calculateTargetRect(for: action, visibleFrame: visibleFrame)
        let axY = primaryMaxY - targetRect.maxY
        let origin = CGPoint(x: targetRect.minX, y: axY)
        let size = CGSize(width: targetRect.width, height: targetRect.height)
        
        setFrame(windowElement: windowElement, appElement: appElement, position: origin, size: size)
    }
    
    private func setFrame(windowElement: AXUIElement, appElement: AXUIElement, position: CGPoint, size: CGSize) {
        // Rectangle technique: disable AXEnhancedUserInterface temporarily to allow Chromium/Electron apps to resize
        var enhancedUIRef: AnyObject?
        let hasEnhancedUI = AXUIElementCopyAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, &enhancedUIRef) == .success
        if hasEnhancedUI {
            AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse)
        }
        
        var s = size
        var p = position
        
        // Rectangle 3-step order: Position -> Size -> Position (Chromium / Electron / macOS compatibility)
        if let posVal = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
        if let posVal = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
        
        if hasEnhancedUI {
            AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
        }
    }
    
    public func moveFocusedWindowToDisplay(direction: Int) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let screens = NSScreen.screens
        guard screens.count > 1 else { return }
        
        let primaryScreen = screens.first ?? NSScreen.main ?? screens[0]
        let primaryMaxY = primaryScreen.frame.maxY
        
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedWindowVal: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowVal) == .success,
              let windowElement = focusedWindowVal as! AXUIElement? else {
            return
        }
        
        var currentScreen = primaryScreen
        var posVal: AnyObject?
        var sizeVal: AnyObject?
        if AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posVal) == .success,
           AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeVal) == .success,
           let pVal = posVal, let sVal = sizeVal {
            var pt = CGPoint.zero
            var sz = CGSize.zero
            AXValueGetValue(pVal as! AXValue, .cgPoint, &pt)
            AXValueGetValue(sVal as! AXValue, .cgSize, &sz)
            
            let cocoaWinRect = CGRect(
                x: pt.x,
                y: primaryMaxY - (pt.y + sz.height),
                width: sz.width,
                height: sz.height
            )
            let center = CGPoint(x: cocoaWinRect.midX, y: cocoaWinRect.midY)
            if let matched = screens.first(where: {
                center.x >= $0.frame.minX && center.x <= $0.frame.maxX &&
                center.y >= $0.frame.minY && center.y <= $0.frame.maxY
            }) {
                currentScreen = matched
            }
        }
        
        guard let currentIndex = screens.firstIndex(of: currentScreen) else { return }
        let nextIndex = (currentIndex + direction + screens.count) % screens.count
        let targetScreen = screens[nextIndex]
        
        let targetFrame = targetScreen.visibleFrame
        let origin = CGPoint(x: targetFrame.minX + 40, y: primaryMaxY - targetFrame.maxY + 40)
        let size = CGSize(width: targetFrame.width * 0.7, height: targetFrame.height * 0.7)
        
        setFrame(windowElement: windowElement, appElement: appElement, position: origin, size: size)
    }
}
