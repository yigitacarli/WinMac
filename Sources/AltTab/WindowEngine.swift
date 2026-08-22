import Cocoa
import ApplicationServices
import Foundation

@MainActor
public final class WindowEngine {
    public static let shared = WindowEngine()
    
    private init() {}
    
    // MARK: - Fetch Windows (100% Accessibility-based, Zero Screen Recording required)
    public func getWindows() -> [WindowModel] {
        var result: [WindowModel] = []
        let ownPid = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            guard app.activationPolicy == .regular,
                  app.processIdentifier != ownPid,
                  !app.isTerminated else {
                continue
            }
            
            let pid = app.processIdentifier
            let appName = app.localizedName ?? "Uygulama"
            let appIcon = app.icon ?? NSWorkspace.shared.icon(forFile: app.bundleURL?.path ?? "")
            let bundleId = app.bundleIdentifier
            let appElement = AXUIElementCreateApplication(pid)
            
            var windowsVal: AnyObject?
            let axResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal)
            
            if axResult == .success, let axWindows = windowsVal as? [AXUIElement], !axWindows.isEmpty {
                for (index, win) in axWindows.enumerated() {
                    var titleVal: AnyObject?
                    var minVal: AnyObject?
                    var sizeVal: AnyObject?
                    var posVal: AnyObject?
                    
                    AXUIElementCopyAttributeValue(win, kAXTitleAttribute as CFString, &titleVal)
                    AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &minVal)
                    AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeVal)
                    AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posVal)
                    
                    let title = (titleVal as? String) ?? ""
                    let isMinimized = (minVal as? Bool) ?? false
                    
                    var size = CGSize.zero
                    var pos = CGPoint.zero
                    if let s = sizeVal { AXValueGetValue(s as! AXValue, .cgSize, &size) }
                    if let p = posVal { AXValueGetValue(p as! AXValue, .cgPoint, &pos) }
                    
                    // Filter out 0x0 hidden helper panels
                    if size.width < 50 && size.height < 50 && !isMinimized {
                        continue
                    }
                    
                    let windowTitle = title.isEmpty ? appName : title
                    let uniqueId = CGWindowID(UInt32(pid) << 8 | UInt32(index & 0xFF))
                    
                    let model = WindowModel(
                        id: uniqueId,
                        pid: pid,
                        appName: appName,
                        bundleId: bundleId,
                        appIcon: appIcon,
                        title: windowTitle,
                        bounds: CGRect(origin: pos, size: size),
                        isMinimized: isMinimized,
                        isHidden: app.isHidden,
                        thumbnail: nil
                    )
                    result.append(model)
                }
            } else if app.bundleIdentifier != "com.apple.finder" {
                // Only add windowless entries for non-Finder apps if needed
                let model = WindowModel(
                    id: CGWindowID(UInt32(pid) << 8),
                    pid: pid,
                    appName: appName,
                    bundleId: bundleId,
                    appIcon: appIcon,
                    title: appName,
                    bounds: .zero,
                    isMinimized: false,
                    isHidden: app.isHidden,
                    thumbnail: nil
                )
                result.append(model)
            }
        }
        
        // Put the frontmost application's windows FIRST (index 0 = currently active window)
        if let frontPid = NSWorkspace.shared.frontmostApplication?.processIdentifier {
            result.sort { (w1, w2) in
                let w1Front = w1.pid == frontPid
                let w2Front = w2.pid == frontPid
                if w1Front != w2Front { return w1Front }
                return false
            }
        }
        
        // Add special "Masaüstü" (Show Desktop) card at the end
        let desktopModel = WindowModel(
            id: 999999,
            pid: 0,
            appName: "Masaüstü",
            bundleId: "com.apple.desktop",
            appIcon: NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: "Masaüstü"),
            title: "Masaüstünü Göster",
            bounds: .zero,
            isMinimized: false,
            isHidden: false,
            thumbnail: nil
        )
        result.append(desktopModel)
        
        return result
    }
    
    // MARK: - Window Focus & Control
    public func focusWindow(_ window: WindowModel) {
        // Special Desktop Action
        if window.bundleId == "com.apple.desktop" || window.pid == 0 {
            for runningApp in NSWorkspace.shared.runningApplications {
                if runningApp.activationPolicy == .regular && runningApp.bundleIdentifier != "com.apple.finder" {
                    runningApp.hide()
                }
            }
            if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
                finder.activate(options: [.activateAllWindows])
            }
            return
        }
        
        guard let app = NSRunningApplication(processIdentifier: window.pid) else { return }
        
        // 1. Unhide if hidden
        if app.isHidden {
            app.unhide()
        }
        
        // 2. Yield activation on macOS 14+ and activate target application
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: app)
        }
        app.activate(options: [.activateAllWindows])
        
        // 3. Accessibility level raise and focus
        let appElement = AXUIElementCreateApplication(window.pid)
        AXUIElementSetAttributeValue(appElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        
        var windowListValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListValue)
        
        if result == .success, let axWindows = windowListValue as? [AXUIElement], !axWindows.isEmpty {
            var targetFound = false
            for axWindow in axWindows {
                var titleValue: AnyObject?
                _ = AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleValue)
                let title = (titleValue as? String) ?? ""
                
                if title == window.title || (window.title.isEmpty && title.isEmpty) {
                    var minVal: AnyObject?
                    if AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minVal) == .success,
                       let isMin = minVal as? Bool, isMin {
                        AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                    }
                    
                    AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
                    AXUIElementSetAttributeValue(axWindow, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                    AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                    targetFound = true
                    break
                }
            }
            
            // Fallback if title didn't match exactly
            if !targetFound, let firstWin = axWindows.first {
                var minVal: AnyObject?
                if AXUIElementCopyAttributeValue(firstWin, kAXMinimizedAttribute as CFString, &minVal) == .success,
                   let isMin = minVal as? Bool, isMin {
                    AXUIElementSetAttributeValue(firstWin, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                }
                AXUIElementSetAttributeValue(firstWin, kAXMainAttribute as CFString, kCFBooleanTrue)
                AXUIElementSetAttributeValue(firstWin, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                AXUIElementPerformAction(firstWin, kAXRaiseAction as CFString)
            }
        }
        
        // 4. Deactivate WinMac so target application is unconditionally in front
        NSApp.deactivate()
    }
    
    public func closeWindow(_ window: WindowModel) {
        let appElement = AXUIElementCreateApplication(window.pid)
        var windowListValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListValue) == .success,
           let axWindows = windowListValue as? [AXUIElement] {
            for axWindow in axWindows {
                var titleValue: AnyObject?
                _ = AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleValue)
                let title = (titleValue as? String) ?? ""
                if title == window.title || axWindows.count == 1 {
                    var closeButtonVal: AnyObject?
                    if AXUIElementCopyAttributeValue(axWindow, kAXCloseButtonAttribute as CFString, &closeButtonVal) == .success,
                       let closeButton = closeButtonVal {
                        AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
                    }
                    break
                }
            }
        }
    }
    
    public func quitApp(_ window: WindowModel) {
        if let app = NSRunningApplication(processIdentifier: window.pid) {
            app.terminate()
        }
    }
    
    public func minimizeWindow(_ window: WindowModel) {
        let appElement = AXUIElementCreateApplication(window.pid)
        var windowListValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListValue) == .success,
           let axWindows = windowListValue as? [AXUIElement], let first = axWindows.first {
            AXUIElementSetAttributeValue(first, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
        }
    }
    
    public func maximizeWindow(_ window: WindowModel) {
        SnapEngine.shared.snapFocusedWindow(to: .maximize)
    }
}
