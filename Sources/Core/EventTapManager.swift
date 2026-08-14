import Cocoa
import CoreGraphics

public final class EventTapManager: @unchecked Sendable {
    public static let shared = EventTapManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Alt + Tab hotkey tracking
    private var isAltTabActive: Bool = false
    private var isAltHeld: Bool = false
    
    private init() {}
    
    public func start() {
        guard eventTap == nil else { return }
        
        // Start Carbon HotKeys for 100% reliable global window snapping
        HotKeyManager.shared.start()
        
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)
        )
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[WinMac] Warning: Failed to create CGEventTap at .cgSessionEventTap. Needs Accessibility permission.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[WinMac] Global EventTap successfully started at .cgSessionEventTap.")
    }
    
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 1. Mouse Scroll Inversion & Modifiers (LinearMouse Pro Engine)
        if type == .scrollWheel {
            if let modified = ScrollInverter.shared.handleScrollEvent(event: event) {
                return (modified === event) ? Unmanaged.passUnretained(event) : Unmanaged.passRetained(modified)
            }
            return nil
        }
        
        let defaults = UserDefaults.standard
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 2. Modifier Key Release check (Option/Alt released while Alt + Tab HUD is active)
        if type == .flagsChanged {
            let altHeld = flags.contains(.maskAlternate)
            self.isAltHeld = altHeld
            
            if isAltTabActive && !altHeld {
                isAltTabActive = false
                DispatchQueue.main.async {
                    AltTabState.shared.confirmSelection()
                }
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 3. Alt + Tab Trigger
        let altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        if type == .keyDown && altTabEnabled {
            if keyCode == 48 && flags.contains(.maskAlternate) && !flags.contains(.maskControl) {
                if !isAltTabActive {
                    isAltTabActive = true
                    DispatchQueue.main.async {
                        AltTabHUDController.shared.show()
                    }
                } else {
                    DispatchQueue.main.async {
                        if flags.contains(.maskShift) {
                            AltTabState.shared.selectPrevious()
                        } else {
                            AltTabState.shared.selectNext()
                        }
                    }
                }
                return nil
            }
        }
        
        // 4. Win + V / Option + V -> Clipboard History
        let clipEnabled = defaults.object(forKey: "clipboardHistoryEnabled") as? Bool ?? true
        if type == .keyDown && clipEnabled {
            if (keyCode == 9 && flags.contains(.maskAlternate) && !flags.contains(.maskControl)) ||
               (keyCode == 9 && flags.contains(.maskCommand) && flags.contains(.maskShift)) {
                DispatchQueue.main.async {
                    ClipboardHUDController.shared.toggle()
                }
                return nil
            }
        }
        
        // 5. System Shortcuts (Win+L, etc.)
        if let sysResult = SystemShortcuts.shared.handleKeyEvent(type: type, event: event) {
            if sysResult !== event {
                return Unmanaged.passRetained(sysResult)
            }
        } else {
            return nil
        }
        
        // 6. Finder Shortcuts (Enter to open, F2 rename, Delete trash)
        if let finderResult = FinderBridge.shared.handleKeyEvent(type: type, event: event) {
            if finderResult !== event {
                return Unmanaged.passRetained(finderResult)
            }
        } else {
            return nil
        }
        
        // 7. Ctrl to Cmd Key Remapping
        if let ctrlResult = CtrlToCmdMapper.shared.handleKeyEvent(type: type, event: event) {
            if ctrlResult !== event {
                return Unmanaged.passRetained(ctrlResult)
            }
        } else {
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
}
