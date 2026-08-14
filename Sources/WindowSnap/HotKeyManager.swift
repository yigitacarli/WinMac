import Carbon
import Cocoa

@MainActor
public final class HotKeyManager: @unchecked Sendable {
    public static let shared = HotKeyManager()
    
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var isInstalled = false
    
    private init() {}
    
    public func start() {
        guard !isInstalled else { return }
        isInstalled = true
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (handlerCallRef, eventRef, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    HotKeyManager.shared.handleHotKey(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        registerHotKeys()
        print("[WinMac] Carbon HotKeyManager registered successfully with GetEventDispatcherTarget.")
    }
    
    public func registerHotKeys() {
        unregisterAll()
        
        let optCtrl = UInt32(optionKey | controlKey)
        let cmdOpt = UInt32(cmdKey | optionKey)
        let optCtrlCmd = UInt32(optionKey | controlKey | cmdKey)
        
        // 1. Left Arrow (123)
        register(id: 1, keyCode: 123, modifiers: optCtrl)
        register(id: 1, keyCode: 123, modifiers: cmdOpt)
        // 2. Right Arrow (124)
        register(id: 2, keyCode: 124, modifiers: optCtrl)
        register(id: 2, keyCode: 124, modifiers: cmdOpt)
        // 3. Up Arrow (126)
        register(id: 3, keyCode: 126, modifiers: optCtrl)
        register(id: 3, keyCode: 126, modifiers: cmdOpt)
        // 4. Down Arrow (125)
        register(id: 4, keyCode: 125, modifiers: optCtrl)
        register(id: 4, keyCode: 125, modifiers: cmdOpt)
        
        // 5. Return / Maximize (36)
        register(id: 5, keyCode: 36, modifiers: optCtrl)
        register(id: 5, keyCode: 36, modifiers: cmdOpt)
        // 6. C / Center (8)
        register(id: 6, keyCode: 8, modifiers: optCtrl)
        register(id: 6, keyCode: 8, modifiers: cmdOpt)
        
        // 7. Quarters: U (32), I (34), J (38), K (40)
        register(id: 7, keyCode: 32, modifiers: optCtrl)
        register(id: 8, keyCode: 34, modifiers: optCtrl)
        register(id: 9, keyCode: 38, modifiers: optCtrl)
        register(id: 10, keyCode: 40, modifiers: optCtrl)
        
        // 8. Thirds: D (2), F (3), G (5), E (14), T (17)
        register(id: 11, keyCode: 2, modifiers: optCtrl)
        register(id: 12, keyCode: 3, modifiers: optCtrl)
        register(id: 13, keyCode: 5, modifiers: optCtrl)
        register(id: 14, keyCode: 14, modifiers: optCtrl)
        register(id: 15, keyCode: 17, modifiers: optCtrl)
        
        // 9. Resize: '=' / '+' (24), '-' (27)
        register(id: 16, keyCode: 24, modifiers: optCtrl)
        register(id: 17, keyCode: 27, modifiers: optCtrl)
        
        // 10. Multi-Display: Opt+Ctrl+Cmd + Left (123), Right (124)
        register(id: 18, keyCode: 123, modifiers: optCtrlCmd)
        register(id: 19, keyCode: 124, modifiers: optCtrlCmd)
    }
    
    private func register(id: UInt32, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x57494E4D), id: id) // 'WINM'
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }
    
    private func unregisterAll() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }
    
    private func handleHotKey(id: UInt32) {
        let defaults = UserDefaults.standard
        let snapEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        guard snapEnabled else { return }
        
        switch id {
        case 1: // Left Arrow
            SnapEngine.shared.handleShortcutAction(.leftHalf)
        case 2: // Right Arrow
            SnapEngine.shared.handleShortcutAction(.rightHalf)
        case 3: // Up Arrow
            SnapEngine.shared.handleShortcutAction(.topHalf)
        case 4: // Down Arrow
            SnapEngine.shared.handleShortcutAction(.bottomHalf)
            
        case 5: // Maximize
            SnapEngine.shared.handleShortcutAction(.maximize)
        case 6: // Center
            SnapEngine.shared.handleShortcutAction(.center)
            
        case 7: // U -> Top Left
            SnapEngine.shared.handleShortcutAction(.topLeftQuarter)
        case 8: // I -> Top Right
            SnapEngine.shared.handleShortcutAction(.topRightQuarter)
        case 9: // J -> Bottom Left
            SnapEngine.shared.handleShortcutAction(.bottomLeftQuarter)
        case 10: // K -> Bottom Right
            SnapEngine.shared.handleShortcutAction(.bottomRightQuarter)
            
        case 11: // D -> Left 1/3
            SnapEngine.shared.handleShortcutAction(.leftThird)
        case 12: // F -> Center 1/3
            SnapEngine.shared.handleShortcutAction(.centerThird)
        case 13: // G -> Right 1/3
            SnapEngine.shared.handleShortcutAction(.rightThird)
        case 14: // E -> Left 2/3
            SnapEngine.shared.handleShortcutAction(.leftTwoThirds)
        case 15: // T -> Right 2/3
            SnapEngine.shared.handleShortcutAction(.rightTwoThirds)
            
        case 16: // Expand
            SnapEngine.shared.handleShortcutAction(.expandSize)
        case 17: // Shrink
            SnapEngine.shared.handleShortcutAction(.shrinkSize)
            
        case 18: // Multi-display Left
            SnapEngine.shared.moveFocusedWindowToDisplay(direction: -1)
        case 19: // Multi-display Right
            SnapEngine.shared.moveFocusedWindowToDisplay(direction: 1)
            
        default:
            break
        }
    }
}
