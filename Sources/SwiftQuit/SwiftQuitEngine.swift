import Cocoa
import ApplicationServices
import CoreGraphics

@MainActor
public final class SwiftQuitEngine {
    public static let shared = SwiftQuitEngine()
    
    private var isRunning: Bool = false
    private var pendingTerminationTasks: [pid_t: DispatchWorkItem] = [:]
    
    // System apps, IDEs, terminals, and games that must NEVER be auto-terminated
    private let systemExcludedBundleIDs: Set<String> = [
        // System
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.Spotlight",
        "com.apple.SystemSettings",
        "com.apple.Music",
        "com.apple.mail",
        "com.apple.Terminal",
        "com.apple.ActivityMonitor",
        "com.apple.dt.Xcode",
        "com.winmac.app",
        
        // Developer Tools & IDEs
        "com.google.antigravity",
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.cursor.Cursor",
        "com.sublimetext.4",
        "com.jetbrains.intellij",
        "com.jetbrains.pycharm",
        "com.jetbrains.webstorm",
        "com.jetbrains.rider",
        "com.jetbrains.CLion",
        "com.jetbrains.AppCode",
        "com.jetbrains.DataGrip",
        "com.jetbrains.GoLand",
        "com.jetbrains.RubyMine",
        "com.jetbrains.fleet",
        
        // Terminals
        "com.googlecode.iterm2",
        "net.kovidgoyal.kitty",
        "com.github.wez.wezterm",
        "dev.warp.Warp-Stable",
        "io.alacritty",
        
        // Games & Launchers
        "com.riotgames.RiotGames.RiotClient",
        "com.riotgames.LeagueofLegends.LeagueClientUx",
        "com.riotgames.LeagueofLegends.GameClient",
        "com.valvesoftware.steam",
        "com.epicgames.EpicGamesLauncher",
        "net.battle.net",
        "com.ea.mac.eaapp",
        
        // Communication
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "ru.keepcoder.Telegram",
        "com.spotify.client"
    ]
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDeactivated(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
        
        print("[WinMac] AutoQuitEngine started safely.")
    }
    
    public func stop() {
        isRunning = false
        pendingTerminationTasks.values.forEach { $0.cancel() }
        pendingTerminationTasks.removeAll()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    @objc private func handleAppDeactivated(_ notification: Notification) {
        guard AppSettings.shared.swiftQuitEnabled else { return }
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        checkAndScheduleQuitIfNeeded(app)
    }
    
    private func isExcluded(bundleID: String, localizedName: String) -> Bool {
        if systemExcludedBundleIDs.contains(bundleID) {
            return true
        }
        
        // Check wildcard / prefix exclusions
        let lowerID = bundleID.lowercased()
        let lowerName = localizedName.lowercased()
        
        if lowerID.contains("riot") || lowerID.contains("league") || lowerID.contains("steam") ||
           lowerID.contains("epicgames") || lowerID.contains("antigravity") || lowerID.contains("jetbrains") ||
           lowerID.contains("terminal") || lowerID.contains("xcode") || lowerID.contains("electron") {
            return true
        }
        
        if lowerName.contains("league") || lowerName.contains("riot") || lowerName.contains("steam") ||
           lowerName.contains("antigravity") || lowerName.contains("terminal") || lowerName.contains("xcode") {
            return true
        }
        
        // User custom exclusions
        let userExclusions = AppSettings.shared.swiftQuitExcludedApps
        if userExclusions.contains(bundleID) {
            return true
        }
        
        return false
    }
    
    private func hasActiveWindows(pid: pid_t) -> Bool {
        // 1. CoreGraphics Window List Verification (handles Metal, OpenGL, Games, Electron)
        if let windowList = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] {
            for info in windowList {
                let winPid = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
                guard winPid == pid else { continue }
                
                let layer = info[kCGWindowLayer as String] as? Int ?? -1
                let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
                let width = boundsDict["Width"] ?? 0
                let height = boundsDict["Height"] ?? 0
                
                // Layer 0 is standard app windows. Layer 3 is modal sheets.
                if (layer == 0 || layer == 3) && width > 60 && height > 60 {
                    return true
                }
            }
        }
        
        // 2. Accessibility API Verification
        let appElement = AXUIElementCreateApplication(pid)
        var windowsVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
           let windowsList = windowsVal as? [AXUIElement], !windowsList.isEmpty {
            for win in windowsList {
                var minVal: AnyObject?
                var sizeVal: AnyObject?
                AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &minVal)
                AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeVal)
                
                let isMin = (minVal as? Bool) ?? false
                if isMin { return true } // Minimized window in dock counts as alive
                
                var size = CGSize.zero
                if let s = sizeVal {
                    AXValueGetValue(s as! AXValue, .cgSize, &size)
                    if size.width > 60 && size.height > 60 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func checkAndScheduleQuitIfNeeded(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return }
        let name = app.localizedName ?? ""
        
        // Protection checks
        guard app.activationPolicy == .regular,
              !app.isTerminated,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              !app.isHidden,
              !isExcluded(bundleID: bundleID, localizedName: name) else {
            return
        }
        
        // If app currently has any active or minimized window, cancel any pending quit task
        let pid = app.processIdentifier
        if hasActiveWindows(pid: pid) {
            pendingTerminationTasks[pid]?.cancel()
            pendingTerminationTasks.removeValue(forKey: pid)
            return
        }
        
        // Grace period delay (minimum 2.0s) so dialog transitions don't kill the app
        let delaySeconds = max(2.0, Double(AppSettings.shared.swiftQuitDelaySeconds))
        
        // Cancel existing pending task for this PID if any
        pendingTerminationTasks[pid]?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                self.pendingTerminationTasks.removeValue(forKey: pid)
                
                // Re-validate before terminating
                guard !app.isTerminated,
                      !app.isHidden,
                      AppSettings.shared.swiftQuitEnabled,
                      !self.hasActiveWindows(pid: pid) else {
                    return
                }
                
                print("[WinMac AutoQuit] Gracefully closing app with 0 open windows: \(name) (\(bundleID))")
                app.terminate()
            }
        }
        
        pendingTerminationTasks[pid] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds, execute: workItem)
    }
}
