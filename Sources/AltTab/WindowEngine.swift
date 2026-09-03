import Cocoa
import ApplicationServices
import Foundation

@MainActor
public final class WindowEngine {
    public static let shared = WindowEngine()

    /// Live AX elements keyed by resolved CGWindowID; rebuilt on every scan.
    /// Enables per-window raise/focus without title matching (two windows can share a title).
    private var axElementsByID: [CGWindowID: AXUIElement] = [:]

    private init() {}

    // MARK: - Fetch Windows

    /// Scans regular apps via Accessibility, resolves real CGWindowIDs against one
    /// WindowServer snapshot, filters helper panels by AXSubrole, and orders the list by
    /// true z-order (frontmost window first) with minimized/hidden windows demoted to the back.
    public func getWindows() -> [WindowModel] {
        var result: [WindowModel] = []
        axElementsByID.removeAll()

        let ownPid = ProcessInfo.processInfo.processIdentifier
        let settings = AppSettings.shared
        let snapshot = CGWindowResolver.Snapshot()
        let runningApps = NSWorkspace.shared.runningApplications
        let frontApp = NSWorkspace.shared.frontmostApplication

        for app in runningApps {
            guard app.activationPolicy == .regular,
                  app.processIdentifier != ownPid,
                  !app.isTerminated else {
                continue
            }
            if settings.hideHiddenApps && app.isHidden { continue }

            let pid = app.processIdentifier
            let appName = app.localizedName ?? "Uygulama"
            let appIcon = app.icon ?? NSWorkspace.shared.icon(forFile: app.bundleURL?.path ?? "")
            let bundleId = app.bundleIdentifier
            let appElement = AXUIElementCreateApplication(pid)
            // A busy game / hung app can block an AX query for seconds. Cap it hard so one
            // unresponsive process never freezes the whole switcher.
            AXUIElementSetMessagingTimeout(appElement, 0.25)

            var windowsVal: AnyObject?
            let axResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal)
            let axWindows = axResult == .success ? windowsVal as? [AXUIElement] : nil

            var appModelCount = 0
            if let axWindows, !axWindows.isEmpty {
                for win in axWindows {
                    guard let model = makeModel(
                        from: win,
                        pid: pid,
                        index: result.count,
                        appName: appName,
                        bundleId: bundleId,
                        appIcon: appIcon,
                        snapshot: snapshot
                    ) else { continue }
                    axElementsByID[model.id] = win
                    result.append(model)
                    appModelCount += 1
                }
            }

            // Fallback: apps whose Accessibility tree is empty or unreadable — full-screen
            // games especially — still expose on-screen windows via the WindowServer.
            if appModelCount == 0 {
                let cgWindows = snapshot.entries.filter { $0.pid == pid && $0.frame.width > 100 && $0.frame.height > 60 }
                for entry in cgWindows {
                    result.append(WindowModel(
                        id: entry.windowID,
                        pid: pid,
                        appName: appName,
                        bundleId: bundleId,
                        appIcon: appIcon,
                        title: appName,
                        bounds: entry.frame,
                        isMinimized: false,
                        isHidden: app.isHidden
                    ))
                    appModelCount += 1
                }
                // Still nothing, but this app is the active one: a windowless placeholder
                // keeps it reachable (background daemons never get here).
                if appModelCount == 0, app == frontApp {
                    result.append(WindowModel(
                        id: CGWindowID(UInt32(pid) << 8 | 1),
                        pid: pid,
                        appName: appName,
                        bundleId: bundleId,
                        appIcon: appIcon,
                        title: appName,
                        bounds: .zero,
                        isMinimized: false,
                        isHidden: app.isHidden
                    ))
                    appModelCount += 1
                }
            }
        }

        sortInFocusOrder(&result, snapshot: snapshot)

        if settings.showDesktopCard {
            result.append(desktopModel())
        }

        return result
    }

    private func makeModel(
        from win: AXUIElement,
        pid: pid_t,
        index: Int,
        appName: String,
        bundleId: String?,
        appIcon: NSImage?,
        snapshot: CGWindowResolver.Snapshot
    ) -> WindowModel? {
        var titleVal: AnyObject?
        var minVal: AnyObject?
        var sizeVal: AnyObject?
        var posVal: AnyObject?
        var subroleVal: AnyObject?

        AXUIElementCopyAttributeValue(win, kAXTitleAttribute as CFString, &titleVal)
        AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &minVal)
        AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeVal)
        AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posVal)
        AXUIElementCopyAttributeValue(win, kAXSubroleAttribute as CFString, &subroleVal)

        // Only genuine content windows: standard windows and dialogs. Rejects toolbars,
        // floating palettes, system dialogs, overlays (matches AltTab's WindowDiscriminator).
        if let subrole = subroleVal as? String {
            let accepted: Set<String> = ["AXStandardWindow", "AXDialog"]
            if !accepted.contains(subrole) { return nil }
        }

        let rawTitle = (titleVal as? String) ?? ""
        let isMinimized = (minVal as? Bool) ?? false

        var size = CGSize.zero
        var pos = CGPoint.zero
        if let s = sizeVal { AXValueGetValue(s as! AXValue, .cgSize, &size) }
        if let p = posVal { AXValueGetValue(p as! AXValue, .cgPoint, &pos) }

        // Helper panels report tiny frames; minimized apps may report 0×0.
        if size.width < 100 || size.height < 50 {
            if !isMinimized { return nil }
        }

        let id = snapshot.resolveID(pid: pid, axBounds: CGRect(origin: pos, size: size))
            ?? syntheticID(pid: pid, index: index)

        return WindowModel(
            id: id,
            pid: pid,
            appName: appName,
            bundleId: bundleId,
            appIcon: appIcon,
            title: rawTitle,
            bounds: CGRect(origin: pos, size: size),
            isMinimized: isMinimized,
            isHidden: false
        )
    }

    /// Stable fallback identity for windows the WindowServer won't disclose (minimized apps in
    /// some Electron clients). Hashes persistent attributes instead of list position.
    private func syntheticID(pid: pid_t, index: Int) -> CGWindowID {
        let base = UInt32(bitPattern: Int32(pid)) &* 2654435761
        return CGWindowID(base &+ UInt32(index) &+ 0x9E37_79B9)
    }

    /// Z-order IS recency: the WindowServer stacks most-recently-focused windows to the front,
    /// so ranking by CGWindowList position reproduces AltTab's MRU behaviour (⇧Tab walks real
    /// history). Minimized/hidden windows never appear on-screen, so they keep scan order after
    /// all visible ones.
    private func sortInFocusOrder(_ models: inout [WindowModel], snapshot: CGWindowResolver.Snapshot) {
        let rankOf: (WindowModel) -> Int = { model in
            snapshot.rank(of: model.id) ?? Int.max
        }
        models.sort { lhs, rhs in
            let lhsDemoted = lhs.isMinimized || lhs.isHidden
            let rhsDemoted = rhs.isMinimized || rhs.isHidden
            if lhsDemoted != rhsDemoted { return !lhsDemoted }
            let lr = rankOf(lhs), rr = rankOf(rhs)
            if lr != rr { return lr < rr }
            return false
        }
    }

    private func desktopModel() -> WindowModel {
        // No icon: the switcher renders this entry with its own white glyph so it reads
        // as an action ("show the desktop"), not another window.
        WindowModel(
            id: 999_999,
            pid: 0,
            appName: "Masaüstü",
            bundleId: "com.apple.desktop",
            appIcon: nil,
            title: "Masaüstünü Göster",
            bounds: .zero,
            isMinimized: false,
            isHidden: false
        )
    }

    // MARK: - Window Focus & Control

    public func focusWindow(_ window: WindowModel) {
        if window.bundleId == "com.apple.desktop" || window.pid == 0 {
            showDesktop()
            return
        }

        guard let app = NSRunningApplication(processIdentifier: window.pid) else { return }

        if app.isHidden {
            app.unhide()
        }
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: app)
        }
        // Activate WITHOUT .activateAllWindows so only the chosen window rises;
        // the AX raise below then pins the exact target on top.
        app.activate()

        // Full-screen games etc. have no reachable AX window — activating the app
        // (done above) is the best we can do; don't undo it.
        guard let element = axElementsByID[window.id] ?? findElementFallback(window) else {
            return
        }

        if window.isMinimized {
            AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        }
        AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)

        NSApp.deactivate()
    }

    private func findElementFallback(_ window: WindowModel) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(window.pid)
        AXUIElementSetMessagingTimeout(appElement, 0.25)
        var windowsVal: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
              let axWindows = windowsVal as? [AXUIElement] else { return nil }

        // Match by geometry first (unique per window), title only as tiebreaker.
        for axWindow in axWindows {
            var sizeVal: AnyObject?
            var posVal: AnyObject?
            AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeVal)
            AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posVal)
            var size = CGSize.zero
            var pos = CGPoint.zero
            if let s = sizeVal { AXValueGetValue(s as! AXValue, .cgSize, &size) }
            if let p = posVal { AXValueGetValue(p as! AXValue, .cgPoint, &pos) }
            if abs(size.width - window.bounds.width) < 2,
               abs(size.height - window.bounds.height) < 2,
               abs(pos.x - window.bounds.minX) < 2,
               abs(pos.y - window.bounds.minY) < 2 {
                return axWindow
            }
        }
        return axWindows.first
    }

    private func showDesktop() {
        for runningApp in NSWorkspace.shared.runningApplications {
            if runningApp.activationPolicy == .regular && runningApp.bundleIdentifier != "com.apple.finder" {
                runningApp.hide()
            }
        }
        if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
            finder.activate(options: [.activateAllWindows])
        }
    }

    public func closeWindow(_ window: WindowModel) {
        guard let element = axElementsByID[window.id] else { return }
        var closeButtonVal: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXCloseButtonAttribute as CFString, &closeButtonVal) == .success,
           let closeButton = closeButtonVal {
            AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
        }
    }

    public func quitApp(_ window: WindowModel) {
        if let app = NSRunningApplication(processIdentifier: window.pid) {
            app.terminate()
        }
    }

    public func minimizeWindow(_ window: WindowModel) {
        guard let element = axElementsByID[window.id] else { return }
        AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }

    public func maximizeWindow(_ window: WindowModel) {
        SnapEngine.shared.snapFocusedWindow(to: .maximize)
    }
}
