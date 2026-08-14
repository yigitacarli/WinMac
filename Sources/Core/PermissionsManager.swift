import Cocoa
import ApplicationServices
import Combine

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()
    
    @Published public private(set) var hasAccessibilityPermission: Bool = false
    
    private var timer: Timer?
    
    private init() {
        checkPermissions()
        startPolling()
    }
    
    public var allPermissionsGranted: Bool {
        return hasAccessibilityPermission
    }
    
    public func checkPermissions() {
        let trusted = AXIsProcessTrusted()
        if self.hasAccessibilityPermission != trusted {
            self.hasAccessibilityPermission = trusted
            if trusted {
                print("[WinMac] Accessibility permission granted. Starting services.")
                EventTapManager.shared.start()
            } else {
                print("[WinMac] Accessibility permission revoked. Safely stopping services to prevent UI freeze.")
                EventTapManager.shared.stop()
            }
        }
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissions()
            }
        }
    }
    
    public func requestAccessibilityPermission() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        self.hasAccessibilityPermission = trusted
    }
    
    public func openAccessibilitySettings() {
        requestAccessibilityPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
