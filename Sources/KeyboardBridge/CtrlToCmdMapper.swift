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
