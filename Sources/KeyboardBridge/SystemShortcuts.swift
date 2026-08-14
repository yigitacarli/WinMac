import Cocoa
import CoreGraphics

public final class SystemShortcuts: @unchecked Sendable {
    public static let shared = SystemShortcuts()
    
    private init() {}
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        guard type == .keyDown else { return event }
        
        let defaults = UserDefaults.standard
        let winLLock = defaults.object(forKey: "winLToLockEnabled") as? Bool ?? true
        
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 1. Win+L / Option+L -> Lock Screen (L is keyCode 37)
        if keyCode == 37 && winLLock {
            if (flags.contains(.maskAlternate) && flags.contains(.maskCommand)) || (flags.contains(.maskAlternate) && !flags.contains(.maskControl)) {
                DispatchQueue.main.async {
                    SystemUtils.lockScreen()
                }
                return nil
            }
        }
        
        // 2. Win+Shift+S / Option+Shift+S -> Snipping (S is keyCode 1)
        if keyCode == 1 && flags.contains(.maskShift) && (flags.contains(.maskAlternate) || flags.contains(.maskCommand)) {
            DispatchQueue.main.async {
                SystemUtils.triggerScreenshot()
            }
            return nil
        }
        
        return event
    }
}
