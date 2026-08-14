import Cocoa
import CoreGraphics

public final class CtrlToCmdMapper: @unchecked Sendable {
    public static let shared = CtrlToCmdMapper()
    
    private init() {}
    
    private let targetKeyCodes: Set<CGKeyCode> = [
        8,  // C
        9,  // V
        7,  // X
        6,  // Z
        0,  // A
        1,  // S
        3,  // F
        13, // W
        17, // T
        35, // P
        45, // N
        15, // R
        16  // Y
    ]
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        let defaults = UserDefaults.standard
        let isEnabled = defaults.object(forKey: "ctrlToCmdRemapEnabled") as? Bool ?? true
        guard isEnabled else { return event }
        
        // Don't intercept in terminal apps
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier {
            let excluded = defaults.stringArray(forKey: "excludedAppsForCtrl") ?? [
                "com.apple.Terminal",
                "com.googlecode.iterm2",
                "net.kovidgoyal.kitty",
                "com.github.wez.wezterm"
            ]
            if excluded.contains(bundleId) {
                return event
            }
        }
        
        let flags = event.flags
        guard flags.contains(.maskControl) && !flags.contains(.maskCommand) else {
            return event
        }
        
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // Special case: Ctrl+Shift+Esc is Task Manager
        if keyCode == 53 && flags.contains(.maskShift) { // Esc
            let taskMgrEnabled = defaults.object(forKey: "ctrlShiftEscTaskManager") as? Bool ?? true
            if taskMgrEnabled {
                DispatchQueue.main.async {
                    SystemUtils.openActivityMonitor()
                }
                return nil
            }
        }
        
        // Special case: Windows Ctrl+Y -> macOS Redo (Cmd + Shift + Z)
        if keyCode == 16 { // Y key
            var newFlags = flags
            newFlags.remove(.maskControl)
            newFlags.insert(.maskCommand)
            newFlags.insert(.maskShift)
            
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(6)) // Z keycode
            event.flags = newFlags
            return event
        }
        
        // Special case: Windows Ctrl+Shift+Z -> macOS Redo (Cmd + Shift + Z)
        if keyCode == 6 && flags.contains(.maskShift) { // Z key + Shift
            var newFlags = flags
            newFlags.remove(.maskControl)
            newFlags.insert(.maskCommand)
            newFlags.insert(.maskShift)
            event.flags = newFlags
            return event
        }
        
        // Standard Ctrl -> Cmd remapping (Ctrl+Z, Ctrl+C, Ctrl+V, Ctrl+A, Ctrl+X, etc.)
        if targetKeyCodes.contains(keyCode) {
            var newFlags = flags
            newFlags.remove(.maskControl)
            newFlags.insert(.maskCommand)
            event.flags = newFlags
            return event
        }
        
        return event
    }
}
