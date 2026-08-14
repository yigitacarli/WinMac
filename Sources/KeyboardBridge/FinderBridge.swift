import Cocoa
import CoreGraphics

public final class FinderBridge: @unchecked Sendable {
    public static let shared = FinderBridge()
    
    private init() {}
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        guard type == .keyDown else { return event }
        
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 1. Enter Key (keyCode 36) -> Open file (Cmd + O)
        if keyCode == 36 && flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty {
            DispatchQueue.main.async {
                if let frontApp = NSWorkspace.shared.frontmostApplication,
                   frontApp.bundleIdentifier == "com.apple.finder" {
                    SystemUtils.sendKeystroke(keyCode: 31, flags: .maskCommand) // 31 is O
                }
            }
            // If in finder, swallow
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.bundleIdentifier == "com.apple.finder" {
                return nil
            }
        }
        
        // 2. F2 Key (keyCode 120) -> Rename file (Enter)
        if keyCode == 120 {
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.bundleIdentifier == "com.apple.finder" {
                SystemUtils.sendKeystroke(keyCode: 36, flags: [])
                return nil
            }
        }
        
        // 3. Delete / Backspace (keyCode 51 or 117) -> Move to Trash (Cmd + Backspace)
        if (keyCode == 51 || keyCode == 117) && flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty {
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.bundleIdentifier == "com.apple.finder" {
                SystemUtils.sendKeystroke(keyCode: 51, flags: .maskCommand)
                return nil
            }
        }
        
        return event
    }
}
