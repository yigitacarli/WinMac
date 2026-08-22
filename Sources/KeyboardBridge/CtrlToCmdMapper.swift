import Cocoa
import CoreGraphics

public final class CtrlToCmdMapper: @unchecked Sendable {
    public static let shared = CtrlToCmdMapper()
    
    private init() {}
    
    // Standard Ctrl -> Cmd mapped keys
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
        15  // R
    ]
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        guard type == .keyDown else { return event }
        
        let defaults = UserDefaults.standard
        let isEnabled = defaults.object(forKey: "ctrlToCmdRemapEnabled") as? Bool ?? true
        
        // Check if frontmost app is an excluded terminal or developer environment
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier {
            let excluded = defaults.stringArray(forKey: "excludedAppsForCtrl") ?? [
                "com.apple.Terminal",
                "com.googlecode.iterm2",
                "net.kovidgoyal.kitty",
                "com.github.wez.wezterm",
                "dev.warp.Warp-Stable",
                "io.alacritty"
            ]
            if excluded.contains(bundleId) {
                return event
            }
        }
        
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 1. Task Manager: Ctrl + Shift + Esc
        if keyCode == 53 && flags.contains(.maskControl) && flags.contains(.maskShift) {
            let taskMgrEnabled = defaults.object(forKey: "ctrlShiftEscTaskManager") as? Bool ?? true
            if taskMgrEnabled {
                DispatchQueue.main.async {
                    SystemUtils.openActivityMonitor()
                }
                return nil
            }
        }
        
        // 2. Lock Screen: Win+L (Option + Command + L or Option + L)
        if keyCode == 37 && (flags.contains(.maskAlternate) && flags.contains(.maskCommand)) {
            let winLEnabled = defaults.object(forKey: "winLToLockEnabled") as? Bool ?? true
            if winLEnabled {
                DispatchQueue.global(qos: .userInitiated).async {
                    let task = Process()
                    task.launchPath = "/usr/bin/pmset"
                    task.arguments = ["displaysleepnow"]
                    try? task.run()
                }
                return nil
            }
        }
        
        // 3. File Explorer: Option + E (Win + E)
        if keyCode == 14 && flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && !flags.contains(.maskControl) {
            let winEEnabled = defaults.object(forKey: "winEToFileExplorer") as? Bool ?? true
            if winEEnabled {
                DispatchQueue.main.async {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"))
                }
                return nil
            }
        }
        
        // 4. Show Desktop: Option + D (Win + D)
        if keyCode == 2 && flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && !flags.contains(.maskControl) {
            let winDEnabled = defaults.object(forKey: "winDToShowDesktop") as? Bool ?? true
            if winDEnabled {
                DispatchQueue.main.async {
                    for runningApp in NSWorkspace.shared.runningApplications {
                        if runningApp.activationPolicy == .regular && runningApp.bundleIdentifier != "com.apple.finder" {
                            runningApp.hide()
                        }
                    }
                    if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
                        finder.activate(options: [.activateAllWindows])
                    }
                }
                return nil
            }
        }
        
        // 5. Clipboard History: Option + V (Win + V)
        if keyCode == 9 && flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && !flags.contains(.maskControl) {
            let clipEnabled = defaults.object(forKey: "clipboardHistoryEnabled") as? Bool ?? true
            if clipEnabled {
                DispatchQueue.main.async {
                    ClipboardHUDController.shared.toggle()
                }
                return nil
            }
        }
        
        guard isEnabled else { return event }
        
        // Only process pure Control key combinations (Ctrl pressed, Cmd not pressed)
        guard flags.contains(.maskControl) && !flags.contains(.maskCommand) else {
            return event
        }
        
        // 6. Word-level text deletions: Ctrl + Backspace -> Option + Backspace
        let wordDelEnabled = defaults.object(forKey: "ctrlBackspaceWordDelete") as? Bool ?? true
        if wordDelEnabled {
            if keyCode == 51 { // Backspace
                var newFlags = flags
                newFlags.remove(.maskControl)
                newFlags.insert(.maskAlternate)
                event.flags = newFlags
                return event
            }
            if keyCode == 117 { // Forward Delete
                var newFlags = flags
                newFlags.remove(.maskControl)
                newFlags.insert(.maskAlternate)
                event.flags = newFlags
                return event
            }
        }
        
        // 7. Word-level arrow navigations: Ctrl + Left/Right -> Option + Left/Right
        let arrowJumpEnabled = defaults.object(forKey: "ctrlArrowWordJump") as? Bool ?? true
        if arrowJumpEnabled {
            if keyCode == 123 || keyCode == 124 { // Left / Right Arrow
                var newFlags = flags
                newFlags.remove(.maskControl)
                newFlags.insert(.maskAlternate)
                event.flags = newFlags
                return event
            }
        }
        
        // 8. Windows Redo: Ctrl + Y -> macOS Cmd + Shift + Z
        if keyCode == 16 { // Y key
            var newFlags = flags
            newFlags.remove(.maskControl)
            newFlags.insert(.maskCommand)
            newFlags.insert(.maskShift)
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(6)) // Z keycode
            event.flags = newFlags
            return event
        }
        
        // 9. Windows Redo alternative: Ctrl + Shift + Z -> Cmd + Shift + Z
        if keyCode == 6 && flags.contains(.maskShift) { // Z + Shift
            var newFlags = flags
            newFlags.remove(.maskControl)
            newFlags.insert(.maskCommand)
            newFlags.insert(.maskShift)
            event.flags = newFlags
            return event
        }
        
        // 10. Reopen closed tab: Ctrl + Shift + T -> Cmd + Shift + T
        if keyCode == 17 && flags.contains(.maskShift) { // T + Shift
            var newFlags = flags
            newFlags.remove(.maskControl)
            newFlags.insert(.maskCommand)
            newFlags.insert(.maskShift)
            event.flags = newFlags
            return event
        }
        
        // 11. Standard Ctrl -> Cmd (Ctrl+C, Ctrl+V, Ctrl+X, Ctrl+A, Ctrl+Z, Ctrl+S, Ctrl+F, Ctrl+W, Ctrl+T, Ctrl+P, Ctrl+N, Ctrl+R)
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
