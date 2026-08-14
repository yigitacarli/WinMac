import Foundation
import Cocoa
import CoreGraphics
import ApplicationServices
import Combine

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()
    
    @Published public var hasAccessibilityPermission: Bool = false
    @Published public var hasScreenRecordingPermission: Bool = false
    
    private var timer: AnyCancellable?
    
    private init() {
        checkPermissions()
        startPolling()
    }
    
    public var allPermissionsGranted: Bool {
        hasAccessibilityPermission && hasScreenRecordingPermission
    }
    
    public func checkPermissions() {
        // Check Accessibility
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        self.hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
        
        // Check Screen Recording
        if #available(macOS 11.0, *) {
            self.hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
        } else {
            self.hasScreenRecordingPermission = true
        }
    }
    
    public func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    public func requestScreenRecordingPermission() {
        if #available(macOS 11.0, *) {
            _ = CGRequestScreenCaptureAccess()
        }
    }
    
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func startPolling() {
        timer = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkPermissions()
            }
    }
}
