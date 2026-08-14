import Cocoa
import CoreGraphics
import ApplicationServices
import Foundation

@MainActor
public final class WindowEngine {
    public static let shared = WindowEngine()
    
    private init() {}
    
    // MARK: - Fetch Windows
    public func getWindows() -> [WindowModel] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: AnyObject]] else {
            return []
        }
        
        var result: [WindowModel] = []
        let runningApps = NSWorkspace.shared.runningApplications
        let runningAppDict = Dictionary(uniqueKeysWithValues: runningApps.map { ($0.processIdentifier, $0) })
        
        let ownPid = ProcessInfo.processInfo.processIdentifier
        
        for info in windowInfoList {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else {
                continue // Only normal standard application windows
            }
            
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid != ownPid else {
                continue
            }
            
            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            
            let appName = (info[kCGWindowOwnerName as String] as? String) ?? "Uygulama"
            let windowTitle = (info[kCGWindowName as String] as? String) ?? ""
            
            // Bounds check
            guard let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  width > 80, height > 80 else {
                continue // Filter out invisible 0x0 or tiny auxiliary elements
            }
            
            let bounds = CGRect(x: x, y: y, width: width, height: height)
            
            // App info
            let app = runningAppDict[pid]
            if let app = app, app.activationPolicy != .regular {
                if windowTitle.isEmpty { continue }
            }
            
            let appIcon = app?.icon
            let bundleId = app?.bundleIdentifier
            
            // Thumbnail
            let thumbnail = ThumbnailCache.shared.thumbnail(for: windowID, bounds: bounds)
            
            let model = WindowModel(
                id: windowID,
                pid: pid,
                appName: appName,
                bundleId: bundleId,
                appIcon: appIcon,
                title: windowTitle.isEmpty ? appName : windowTitle,
                bounds: bounds,
                isMinimized: false,
                isHidden: app?.isHidden ?? false,
                thumbnail: thumbnail
            )
            
            result.append(model)
        }
        
        return result
    }
    
    // MARK: - Window Control Actions
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
                
                if let title = titleValue as? String, (title == window.title || axWindows.count == 1) {
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
                var closeButtonVal: AnyObject?
                if AXUIElementCopyAttributeValue(axWindow, kAXCloseButtonAttribute as CFString, &closeButtonVal) == .success,
                   let closeButton = closeButtonVal {
                    AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
                    break
                }
            }
        }
    }
    
    public func minimizeWindow(_ window: WindowModel) {
        let appElement = AXUIElementCreateApplication(window.pid)
        var windowListValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListValue) == .success,
           let axWindows = windowListValue as? [AXUIElement] {
            for axWindow in axWindows {
                var minimizeButtonVal: AnyObject?
                if AXUIElementCopyAttributeValue(axWindow, kAXMinimizeButtonAttribute as CFString, &minimizeButtonVal) == .success,
                   let minButton = minimizeButtonVal {
                    AXUIElementPerformAction(minButton as! AXUIElement, kAXPressAction as CFString)
                    break
                }
            }
        }
    }
    
    public func maximizeWindow(_ window: WindowModel) {
        let appElement = AXUIElementCreateApplication(window.pid)
        var windowListValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListValue) == .success,
           let axWindows = windowListValue as? [AXUIElement] {
            for axWindow in axWindows {
                var zoomButtonVal: AnyObject?
                if AXUIElementCopyAttributeValue(axWindow, kAXZoomButtonAttribute as CFString, &zoomButtonVal) == .success,
                   let zoomButton = zoomButtonVal {
                    AXUIElementPerformAction(zoomButton as! AXUIElement, kAXPressAction as CFString)
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
}
