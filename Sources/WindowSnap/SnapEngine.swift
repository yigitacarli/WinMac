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
    
    private init() {}
    
    // MARK: - Drag to Snap Engine (Rectangle Aero Snap)
    public func handleMouseDrag(point: CGPoint) {
        guard UserDefaults.standard.object(forKey: "dragToSnapEnabled") as? Bool ?? true else { return }
        
        let cocoaPoint = NSPoint(x: point.x, y: point.y)
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(cocoaPoint, $0.frame, false) }) ?? NSScreen.main else {
            return
        }
        
        let sFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let edgeThreshold: CGFloat = 25.0
        let cornerThreshold: CGFloat = 70.0
        
        var targetAction: SnapAction?
        var previewRect: NSRect?
        
        let halfW = visibleFrame.width / 2.0
        let halfH = visibleFrame.height / 2.0
        
        // 1. Top Edge & Corners (Cocoa Y near sFrame.maxY)
        if cocoaPoint.y >= sFrame.maxY - edgeThreshold {
            if cocoaPoint.x <= sFrame.minX + cornerThreshold {
                targetAction = .topLeftQuarter
                previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY + halfH, width: halfW, height: halfH)
            } else if cocoaPoint.x >= sFrame.maxX - cornerThreshold {
                targetAction = .topRightQuarter
                previewRect = NSRect(x: visibleFrame.minX + halfW, y: visibleFrame.minY + halfH, width: halfW, height: halfH)
            } else {
                targetAction = .maximize
                previewRect = visibleFrame
            }
        }
        // 2. Bottom Edge & Corners (Cocoa Y near sFrame.minY)
        else if cocoaPoint.y <= sFrame.minY + edgeThreshold {
            if cocoaPoint.x <= sFrame.minX + cornerThreshold {
                targetAction = .bottomLeftQuarter
                previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfW, height: halfH)
            } else if cocoaPoint.x >= sFrame.maxX - cornerThreshold {
                targetAction = .bottomRightQuarter
                previewRect = NSRect(x: visibleFrame.minX + halfW, y: visibleFrame.minY, width: halfW, height: halfH)
            } else {
                targetAction = .bottomHalf
                previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: halfH)
            }
        }
        // 3. Left Edge
        else if cocoaPoint.x <= sFrame.minX + edgeThreshold {
            targetAction = .leftHalf
            previewRect = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfW, height: visibleFrame.height)
        }
        // 4. Right Edge
        else if cocoaPoint.x >= sFrame.maxX - edgeThreshold {
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
    
    public func handleMouseUp() {
        if let target = currentDragSnapTarget {
            DispatchQueue.main.async { [weak self] in
                self?.snapFocusedWindow(to: target)
                SnapOverlayController.shared.hidePreview()
            }
            self.currentDragSnapTarget = nil
        } else {
            DispatchQueue.main.async {
                SnapOverlayController.shared.hidePreview()
            }
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
        
        DispatchQueue.main.async {
            self.snapFocusedWindow(to: effectiveAction)
        }
    }
    
    // MARK: - Window Manipulation Engine (Rectangle Architecture)
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
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowVal) == .success,
              let windowElement = focusedWindowVal as! AXUIElement? else {
            // Fallback: try first window of front app
            var windowsVal: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
               let windowsList = windowsVal as? [AXUIElement], let firstWin = windowsList.first {
                applySnap(windowElement: firstWin, appElement: appElement, frontApp: frontApp, action: action)
            }
            return
        }
        
        applySnap(windowElement: windowElement, appElement: appElement, frontApp: frontApp, action: action)
    }
    
    private func calculateTargetRect(for action: SnapAction, visibleFrame: CGRect) -> CGRect {
        let halfWidth = visibleFrame.width / 2.0
        let halfHeight = visibleFrame.height / 2.0
        let thirdWidth = visibleFrame.width / 3.0
        let twoThirdsWidth = (visibleFrame.width * 2.0) / 3.0
        
        switch action {
        case .leftHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .rightHalf:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .topHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: visibleFrame.width, height: halfHeight)
        case .bottomHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: halfHeight)
        case .maximize:
            return visibleFrame
        case .topLeftQuarter:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .topRightQuarter:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .bottomLeftQuarter:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
        case .bottomRightQuarter:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
            
        case .leftThird:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .centerThird:
            return CGRect(x: visibleFrame.minX + thirdWidth, y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .rightThird:
            return CGRect(x: visibleFrame.minX + (thirdWidth * 2.0), y: visibleFrame.minY, width: thirdWidth, height: visibleFrame.height)
        case .leftTwoThirds:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: twoThirdsWidth, height: visibleFrame.height)
        case .rightTwoThirds:
            return CGRect(x: visibleFrame.minX + thirdWidth, y: visibleFrame.minY, width: twoThirdsWidth, height: visibleFrame.height)
            
        case .center:
            let w = visibleFrame.width * 0.72
            let h = visibleFrame.height * 0.72
            return CGRect(
                x: visibleFrame.minX + (visibleFrame.width - w) / 2.0,
                y: visibleFrame.minY + (visibleFrame.height - h) / 2.0,
                width: w,
                height: h
            )
        case .nextDisplay, .previousDisplay, .expandSize, .shrinkSize:
            return visibleFrame
        }
    }
    
    private func applySnap(windowElement: AXUIElement, appElement: AXUIElement, frontApp: NSRunningApplication, action: SnapAction) {
        guard let screen = SystemUtils.screenForApp(pid: frontApp.processIdentifier) ?? NSScreen.main else {
            return
        }
        
        let visibleFrame = screen.visibleFrame
        let primaryMaxY = NSScreen.screens.first?.frame.maxY ?? NSScreen.screens[0].frame.height
        
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
        
        // 1. Set size first
        if let sizeVal = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
        // 2. Set position
        if let posVal = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
        // 3. Set size again to ensure constraints
        if let sizeVal = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
        
        if hasEnhancedUI {
            AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
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
        let primaryHeight = screens[0].frame.height
        
        let origin = CGPoint(x: targetFrame.minX + 40, y: primaryHeight - targetFrame.maxY + 40)
        let size = CGSize(width: targetFrame.width * 0.7, height: targetFrame.height * 0.7)
        
        setFrame(windowElement: windowElement, appElement: appElement, position: origin, size: size)
    }
}
