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
        
        if cycleEnabled && isRecent && lastAction == action {
            cycleStep = (cycleStep + 1) % 3
            switch action {
            case .leftHalf:
                if cycleStep == 1 { effectiveAction = .leftTwoThirds }
                else if cycleStep == 2 { effectiveAction = .leftThird }
                else { effectiveAction = .leftHalf }
            case .rightHalf:
                if cycleStep == 1 { effectiveAction = .rightTwoThirds }
                else if cycleStep == 2 { effectiveAction = .rightThird }
                else { effectiveAction = .rightHalf }
            case .topHalf:
                if cycleStep == 1 { effectiveAction = .maximize }
                else { effectiveAction = .topHalf }
            case .bottomHalf:
                if cycleStep == 1 { effectiveAction = .bottomHalf }
                else { effectiveAction = .bottomHalf }
            default:
                break
            }
        } else {
            cycleStep = 0
        }
        
        lastAction = action
        lastActionTime = now
        
        snapFocusedWindow(to: effectiveAction)
    }
    
    public func moveFocusedWindowToDisplay(direction: Int) {
        handleShortcutAction(direction > 0 ? .nextDisplay : .previousDisplay)
    }
    
    // MARK: - Window Detection & Snapping
    
    public func snapWindowAtCursorOrFocused(to action: SnapAction) {
        let mouseLoc = NSEvent.mouseLocation
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main ?? NSScreen.screens[0]
        let cgY = primaryScreen.frame.maxY - mouseLoc.y
        let cgPoint = CGPoint(x: mouseLoc.x, y: cgY)
        
        var elementAtPoint: AXUIElement?
        if AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(cgPoint.x), Float(cgPoint.y), &elementAtPoint) == .success,
           let el = elementAtPoint {
            if let winElement = findWindowElement(from: el) {
                var pid: pid_t = 0
                if AXUIElementGetPid(winElement, &pid) == .success,
                   let app = NSRunningApplication(processIdentifier: pid),
                   app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                    let wrappedWindow = AccessibilityElement(winElement)
                    let wrappedApp = AccessibilityElement.application(for: pid)
                    applySnap(window: wrappedWindow, app: wrappedApp, action: action)
                    return
                }
            }
        }
        
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
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        let appElement = AccessibilityElement.application(for: frontApp.processIdentifier)
        
        var focusedWindowVal: AnyObject?
        let axStatus = AXUIElementCopyAttributeValue(appElement.axElement, kAXFocusedWindowAttribute as CFString, &focusedWindowVal)
        
        if axStatus == .success, let windowElement = focusedWindowVal as! AXUIElement? {
            applySnap(window: AccessibilityElement(windowElement), app: appElement, action: action)
            return
        }
        
        var mainWinVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement.axElement, kAXMainWindowAttribute as CFString, &mainWinVal) == .success,
           let mainWin = mainWinVal as! AXUIElement? {
            applySnap(window: AccessibilityElement(mainWin), app: appElement, action: action)
            return
        }
        
        var windowsVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement.axElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
           let windowsList = windowsVal as? [AXUIElement], let firstWin = windowsList.first {
            applySnap(window: AccessibilityElement(firstWin), app: appElement, action: action)
        }
    }
    
    private func applySnap(window: AccessibilityElement, app: AccessibilityElement, action: SnapAction) {
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main ?? NSScreen.screens[0]
        let primaryMaxY = primaryScreen.frame.maxY
        
        var screen: NSScreen = primaryScreen
        
        if let pt = window.getPosition(), let sz = window.getSize() {
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
        let gaps = CGFloat(UserDefaults.standard.double(forKey: "snapWindowGaps"))
        
        // Multi-display navigation
        if action == .nextDisplay || action == .previousDisplay {
            let allScreens = NSScreen.screens
            if allScreens.count > 1, let curIdx = allScreens.firstIndex(of: screen) {
                let nextIdx = (action == .nextDisplay) ? (curIdx + 1) % allScreens.count : (curIdx - 1 + allScreens.count) % allScreens.count
                let targetScreen = allScreens[nextIdx]
                let targetRect = WindowCalculation.calculateRect(for: .maximize, visibleFrame: targetScreen.visibleFrame, gaps: gaps)
                let axY = primaryMaxY - targetRect.maxY
                window.setFrame(position: CGPoint(x: targetRect.minX, y: axY), size: CGSize(width: targetRect.width, height: targetRect.height), appElement: app)
                return
            }
        }
        
        let targetRect = WindowCalculation.calculateRect(for: action, visibleFrame: visibleFrame, gaps: gaps)
        let axY = primaryMaxY - targetRect.maxY
        let origin = CGPoint(x: targetRect.minX, y: axY)
        let size = CGSize(width: targetRect.width, height: targetRect.height)
        
        window.setFrame(position: origin, size: size, appElement: app)
    }
}
