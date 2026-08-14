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
            } else {
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
        
        // Put the frontmost application's other windows or the most recently used window at the beginning
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let frontPid = frontApp.processIdentifier
            result.sort { (w1, w2) in
                if w1.pid == frontPid && w2.pid != frontPid {
                    return false
                } else if w1.pid != frontPid && w2.pid == frontPid {
                    return true
                }
                return false
            }
        }
        
        return result
    }
    
    // MARK: - Window Focus & Control
    public func focusWindow(_ window: WindowModel) {
        guard let app = NSRunningApplication(processIdentifier: window.pid) else { return }
        
        if app.isHidden {
            app.unhide()
        }
        
        app.activate(options: [.activateIgnoringOtherApps])
        
        let appElement = AXUIElementCreateApplication(window.pid)
        var windowListValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListValue)
        
        if result == .success, let axWindows = windowListValue as? [AXUIElement] {
            for axWindow in axWindows {
                var titleValue: AnyObject?
                _ = AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleValue)
                let title = (titleValue as? String) ?? ""
                
                if title == window.title || axWindows.count == 1 || window.title == window.appName {
                    var minVal: AnyObject?
                    if AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minVal) == .success,
                       let isMin = minVal as? Bool, isMin {
                        AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                    }
                    
                    AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
                    AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                    break
                }
            }
        }
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
