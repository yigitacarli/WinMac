import Cocoa
import ApplicationServices

@MainActor
public final class SwiftQuitEngine {
    public static let shared = SwiftQuitEngine()
    
    private var timer: Timer?
    private var isRunning: Bool = false
    
    // System apps that should never be auto-terminated
    private let systemExcludedBundleIDs: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.Spotlight",
        "com.apple.SystemSettings",
        "com.apple.Music",
        "com.apple.mail",
        "com.winmac.app"
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
        
        // Periodic check for apps with 0 windows
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkRunningApplications()
            }
        }
        
        print("[WinMac] AutoQuitEngine started.")
    }
    
    public func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    @objc private func handleAppDeactivated(_ notification: Notification) {
        guard AppSettings.shared.swiftQuitEnabled else { return }
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        checkAndQuitAppIfNeeded(app)
    }
    
    public func checkRunningApplications() {
        guard AppSettings.shared.swiftQuitEnabled else { return }
        
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  !app.isTerminated,
                  app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                continue
            }
            
            checkAndQuitAppIfNeeded(app)
        }
    }
    
    private func checkAndQuitAppIfNeeded(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return }
        guard !systemExcludedBundleIDs.contains(bundleID) else { return }
        
        // User custom exclusions
        let userExclusions = AppSettings.shared.swiftQuitExcludedApps
        guard !userExclusions.contains(bundleID) else { return }
        
        // If app is hidden (Cmd+H), user intends to keep it alive in background
        if app.isHidden {
            return
        }
        
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsVal: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal)
        
        if result == .success, let windowsList = windowsVal as? [AXUIElement] {
            // Count genuine windows and check if any window is minimized into Dock
            var hasMinimizedWindows = false
            var activeWindowCount = 0
            
            for win in windowsList {
                var minVal: AnyObject?
                var sizeVal: AnyObject?
                
                AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &minVal)
                AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeVal)
                
                let isMin = (minVal as? Bool) ?? false
                if isMin {
                    hasMinimizedWindows = true
                }
                
                var size = CGSize.zero
                if let s = sizeVal {
                    AXValueGetValue(s as! AXValue, .cgSize, &size)
                }
                
                // Real window on screen
                if size.width > 60 && size.height > 60 {
                    activeWindowCount += 1
                }
            }
            
            // If the user minimized a window to Dock, DO NOT terminate the app!
            if hasMinimizedWindows {
                return
            }
            
            // Only quit if the app has ZERO open windows (all closed with 'X')
            if activeWindowCount == 0 && windowsList.isEmpty {
                let delay = AppSettings.shared.swiftQuitDelaySeconds
                if delay <= 0 {
                    terminateApp(app)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)) { [weak self] in
                        self?.revalidateAndTerminate(app)
                    }
                }
            }
        }
    }
    
    private func revalidateAndTerminate(_ app: NSRunningApplication) {
        guard !app.isTerminated, !app.isHidden else { return }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
           let windowsList = windowsVal as? [AXUIElement], windowsList.isEmpty {
            terminateApp(app)
        }
    }
    
    private func terminateApp(_ app: NSRunningApplication) {
        print("[WinMac AutoQuit] Closing application with 0 open windows: \(app.localizedName ?? app.bundleIdentifier ?? "")")
        app.terminate()
    }
}
