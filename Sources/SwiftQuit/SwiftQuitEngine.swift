import Cocoa
import ApplicationServices

@MainActor
public final class SwiftQuitEngine {
    public static let shared = SwiftQuitEngine()
    
    private var timer: Timer?
    private var isRunning: Bool = false
    
    // System apps that should never be terminated
    private let systemExcludedBundleIDs: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.Spotlight",
        "com.apple.SystemSettings",
        "com.winmac.app"
    ]
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Listen to workspace application state changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDeactivated(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
        
        // Lightweight 1.5s check for apps with 0 windows
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkRunningApplications()
            }
        }
        
        print("[WinMac] SwiftQuitEngine started.")
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
        
        // Check user exclusions
        let userExclusions = AppSettings.shared.swiftQuitExcludedApps
        guard !userExclusions.contains(bundleID) else { return }
        
        // Check if app has any visible windows via AXUIElement
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsVal: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal)
        
        if result == .success {
            if let windowsList = windowsVal as? [AXUIElement] {
                // Filter out sheets or zero-sized hidden windows
                var visibleWindowCount = 0
                for win in windowsList {
                    var minVal: AnyObject?
                    var sizeVal: AnyObject?
                    AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute as CFString, &minVal)
                    AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeVal)
                    
                    let isMinimized = (minVal as? Bool) ?? false
                    if !isMinimized {
                        if let sVal = sizeVal {
                            var size = CGSize.zero
                            AXValueGetValue(sVal as! AXValue, .cgSize, &size)
                            if size.width > 50 && size.height > 50 {
                                visibleWindowCount += 1
                            }
                        } else {
                            visibleWindowCount += 1
                        }
                    }
                }
                
                if visibleWindowCount == 0 {
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
    }
    
    private func revalidateAndTerminate(_ app: NSRunningApplication) {
        guard !app.isTerminated else { return }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsVal: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsVal) == .success,
           let windowsList = windowsVal as? [AXUIElement], windowsList.isEmpty {
            terminateApp(app)
        }
    }
    
    private func terminateApp(_ app: NSRunningApplication) {
        print("[WinMac SwiftQuit] Auto-terminating application: \(app.localizedName ?? app.bundleIdentifier ?? "")")
        app.terminate()
    }
}
