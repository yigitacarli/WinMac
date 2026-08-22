import Cocoa
import CoreGraphics
import ApplicationServices

public enum SnapAction: Sendable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case maximize
    case almostMaximize
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
    
    // Rectangle Cycle Memory
    private var lastAction: SnapAction?
    private var lastActionTime: Date = .distantPast
    private var cycleStep: Int = 0
    
    // Rectangle Drag-to-Snap State Tracking
    private var currentDragSnapTarget: SnapAction?
    private var isDraggingWindow: Bool = false
    private var trackedWindow: AccessibilityElement?
    private var initialWindowOrigin: CGPoint?
    
    private init() {}
    
    // MARK: - Rectangle Frontmost App & Game Filter
    
    private func isFrontmostAppExcluded() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontApp.bundleIdentifier else {
            return false
        }
        let lowerID = bundleID.lowercased()
        let lowerName = (frontApp.localizedName ?? "").lowercased()
        
        if lowerID.contains("riot") || lowerID.contains("league") || lowerID.contains("steam") ||
           lowerID.contains("epicgames") || lowerID.contains("battle.net") || lowerID.contains("ea.app") {
            return true
        }
        if lowerName.contains("league") || lowerName.contains("riot") || lowerName.contains("steam") {
            return true
        }
        return false
    }
    
    // MARK: - Rectangle 1:1 Drag to Snap Engine
    
    public func handleMouseDown(point: CGPoint) {
        guard !isFrontmostAppExcluded() else {
            resetDragState()
            return
        }
        
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.activationPolicy == .regular,
              frontApp.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            resetDragState()
            return
        }
        
        let appElement = AccessibilityElement.application(for: frontApp.processIdentifier)
        var winElement: AnyObject?
        let status = AXUIElementCopyAttributeValue(appElement.axElement, kAXFocusedWindowAttribute as CFString, &winElement)
        
        if status == .success, let axWin = winElement as! AXUIElement? {
            let win = AccessibilityElement(axWin)
            if let pos = win.getPosition() {
                self.trackedWindow = win
                self.initialWindowOrigin = pos
                self.isDraggingWindow = false
                return
            }
        }
        
        resetDragState()
    }
    
    public func handleMouseDrag(point: CGPoint) {
        guard !isFrontmostAppExcluded(),
              let win = trackedWindow,
              let initialPos = initialWindowOrigin else {
            if currentDragSnapTarget != nil {
                resetDragState()
                SnapOverlayController.shared.hidePreview()
            }
            return
        }
        
        guard UserDefaults.standard.object(forKey: "dragToSnapEnabled") as? Bool ?? true else {
            if currentDragSnapTarget != nil {
                resetDragState()
                SnapOverlayController.shared.hidePreview()
            }
            return
        }
        
        guard let currentPos = win.getPosition() else {
            resetDragState()
            SnapOverlayController.shared.hidePreview()
            return
        }
        
        let distanceMoved = hypot(currentPos.x - initialPos.x, currentPos.y - initialPos.y)
        if distanceMoved < 15.0 {
            if currentDragSnapTarget != nil {
                currentDragSnapTarget = nil
                SnapOverlayController.shared.hidePreview()
            }
            return
        }
        
        self.isDraggingWindow = true
        
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
        let target = currentDragSnapTarget
        let wasDragging = isDraggingWindow
        let win = trackedWindow
        
        resetDragState()
        SnapOverlayController.shared.hidePreview()
        
        guard wasDragging, let snapTarget = target, let targetWin = win else { return }
        
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AccessibilityElement.application(for: frontApp.processIdentifier)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.applySnap(window: targetWin, app: appElement, action: snapTarget)
        }
    }
    
    private func resetDragState() {
        currentDragSnapTarget = nil
        isDraggingWindow = false
        trackedWindow = nil
        initialWindowOrigin = nil
    }
    
    // MARK: - Rectangle HotKey Dispatcher
    
    public func handleShortcutAction(_ action: SnapAction) {
        guard !isFrontmostAppExcluded() else { return }
        
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
    
    // MARK: - Window Snapping Execution
    
    public func snapFocusedWindow(to action: SnapAction) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication, !isFrontmostAppExcluded() else { return }
        
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
            
            let screens = NSScreen.screens
            var matched: NSScreen? = nil
            for s in screens {
                let f = s.frame
                if center.x >= f.minX && center.x <= f.maxX && center.y >= f.minY && center.y <= f.maxY {
                    matched = s
                    break
                }
            }
            if matched == nil {
                for s in screens {
                    if s.frame.intersects(cocoaWinRect) {
                        matched = s
                        break
                    }
                }
            }
            if let m = matched {
                screen = m
            }
        }
        
        let visibleFrame = screen.visibleFrame
        let gaps = CGFloat(UserDefaults.standard.double(forKey: "snapWindowGaps"))
        let almostPad = CGFloat(UserDefaults.standard.double(forKey: "almostMaximizePadding"))
        
        // Multi-display navigation
        if action == .nextDisplay || action == .previousDisplay {
            let allScreens = NSScreen.screens
            if allScreens.count > 1, let curIdx = allScreens.firstIndex(of: screen) {
                let nextIdx = (action == .nextDisplay) ? (curIdx + 1) % allScreens.count : (curIdx - 1 + allScreens.count) % allScreens.count
                let targetScreen = allScreens[nextIdx]
                let targetRect = WindowCalculation.calculateRect(for: .maximize, visibleFrame: targetScreen.visibleFrame, gaps: gaps, almostMaximizePadding: almostPad)
                let axY = primaryMaxY - targetRect.maxY
                window.setFrame(position: CGPoint(x: targetRect.minX, y: axY), size: CGSize(width: targetRect.width, height: targetRect.height), appElement: app)
                return
            }
        }
        
        let targetRect = WindowCalculation.calculateRect(for: action, visibleFrame: visibleFrame, gaps: gaps, almostMaximizePadding: almostPad)
        let axY = primaryMaxY - targetRect.maxY
        let origin = CGPoint(x: targetRect.minX, y: axY)
        let size = CGSize(width: targetRect.width, height: targetRect.height)
        
        window.setFrame(position: origin, size: size, appElement: app)
    }
}
