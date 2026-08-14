import Cocoa
import CoreGraphics

public final class FinderBridge: @unchecked Sendable {
    public static let shared = FinderBridge()
    
    private init() {}
    
    public func handleKeyEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        guard type == .keyDown else { return event }
        
        let defaults = UserDefaults.standard
        let enterOpen = defaults.object(forKey: "finderEnterToOpen") as? Bool ?? true
        let f2Rename = defaults.object(forKey: "finderF2ToRename") as? Bool ?? true
        let deleteTrash = defaults.object(forKey: "finderDeleteToTrash") as? Bool ?? true
        
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier == "com.apple.finder" else {
            return event
        }
        
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 1. Return / Enter Key (keyCode 36) -> Open selected file (Cmd + Down)
        if keyCode == 36 && flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty {
            if enterOpen {
                DispatchQueue.main.async {
                    SystemUtils.sendKeystroke(keyCode: 125, flags: .maskCommand)
                }
                return nil
            }
        }
        
        // 2. F2 Key (keyCode 120) -> Rename selected file (Return)
        if keyCode == 120 {
            if f2Rename {
                DispatchQueue.main.async {
                    SystemUtils.sendKeystroke(keyCode: 36, flags: [])
                }
                return nil
            }
        }
        
        // 3. Delete / Backspace Key (keyCode 51 or 117) -> Move to Trash (Cmd + Delete)
        if (keyCode == 51 || keyCode == 117) && flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty {
            if deleteTrash {
                DispatchQueue.main.async {
                    SystemUtils.sendKeystroke(keyCode: 51, flags: .maskCommand)
                }
                return nil
            }
        }
        
        return event
    }
}
