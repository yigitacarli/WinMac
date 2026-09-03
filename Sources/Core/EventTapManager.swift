import CoreGraphics
import Foundation
import Cocoa
import ApplicationServices

public final class EventTapManager: @unchecked Sendable {
    public static let shared = EventTapManager()
    
    private var globalEventTap: CFMachPort?
    private var eventRunLoopSource: CFRunLoopSource?
    
    // Alt + Tab State Tracking
    private var isAltTabActive = false
    private var activeTriggerModifier: TriggerModifier = .option
    
    private enum TriggerModifier {
        case option
        case control
    }
    
    private init() {}
    
    public func start() {
        // Carbon HotKeys run independently of CGEventTap
        DispatchQueue.main.async {
            HotKeyManager.shared.start()
        }
        
        // CGEventTap requires Accessibility permissions
        if AXIsProcessTrusted() {
            startUnifiedEventTap()
        } else {
            print("[WinMac] Accessibility permission not yet granted. Carbon HotKeys active, EventTap deferred.")
        }
    }
    
    public func startEventTapIfNeeded() {
        guard globalEventTap == nil, AXIsProcessTrusted() else { return }
        startUnifiedEventTap()
    }
    
    public func stop() {
        stopUnifiedEventTap()
        print("[WinMac] All services stopped safely.")
    }
    
    // MARK: - Unified Global Event Tap (Scroll, Key, Drag, Snap)
    private func startUnifiedEventTap() {
        guard globalEventTap == nil else { return }
        
        let eventMask: CGEventMask = (
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue)
        )
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else {
                return Unmanaged.passUnretained(event)
            }
            let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleSystemEvent(proxy: proxy, type: type, event: event)
        }
        
        var tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if tap == nil {
            tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        }
        
        guard let validTap = tap else {
            print("[WinMac] Warning: Failed to create Unified EventTap.")
            return
        }
        
        self.globalEventTap = validTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, validTap, 0)
        self.eventRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: validTap, enable: true)
        print("[WinMac] Unified System EventTap successfully running.")
    }
    
    private func stopUnifiedEventTap() {
        if let tap = globalEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = eventRunLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                eventRunLoopSource = nil
            }
            globalEventTap = nil
        }
    }
    
    // MARK: - Event Handler Pipeline
    private func handleSystemEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if disabled by system timeout
        if type == .tapDisabledByUserInput || type == .tapDisabledByTimeout {
            if let tap = globalEventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 1. Mouse Drag & Snap Handling (window-snap engine)
        if type == .leftMouseDown {
            let loc = NSEvent.mouseLocation
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseDown(point: CGPoint(x: loc.x, y: loc.y))
            }
            return Unmanaged.passUnretained(event)
        }
        
        if type == .leftMouseDragged {
            let loc = NSEvent.mouseLocation
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseDrag(point: CGPoint(x: loc.x, y: loc.y))
            }
            return Unmanaged.passUnretained(event)
        }
        
        if type == .leftMouseUp {
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseUp()
            }
            return Unmanaged.passUnretained(event)
        }
        
        let defaults = UserDefaults.standard
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 3. Modifier Key Release Check (Alt + Tab Dismiss)
        if type == .flagsChanged {
            if isAltTabActive {
                let modifierReleased: Bool
                switch activeTriggerModifier {
                case .option:
                    modifierReleased = !flags.contains(.maskAlternate)
                case .control:
                    modifierReleased = !flags.contains(.maskControl)
                }
                
                if modifierReleased {
                    isAltTabActive = false
                    DispatchQueue.main.async {
                        AltTabState.shared.confirmSelection()
                    }
                }
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 4. Alt + Tab Trigger (Option+Tab or Control+Tab)
        let altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        let shortcutPref = defaults.string(forKey: "switcherShortcut") ?? AltTabShortcut.optionTab.rawValue
        let isCtrlTabPref = shortcutPref == AltTabShortcut.ctrlTab.rawValue
        
        if type == .keyDown && altTabEnabled {
            let isTriggerMatch: Bool
            let currentModifier: TriggerModifier
            
            if isCtrlTabPref {
                isTriggerMatch = keyCode == 48 && flags.contains(.maskControl)
                currentModifier = .control
            } else {
                isTriggerMatch = keyCode == 48 && flags.contains(.maskAlternate)
                currentModifier = .option
            }
            
            if isTriggerMatch {
                let isBackwards = flags.contains(.maskShift)
                // Auto-repeat must not wrap: pinning at the ends during a held Tab matches
                // the original's KeyRepeatTimer behaviour.
                let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                activeTriggerModifier = currentModifier

                if !isAltTabActive {
                    isAltTabActive = true
                    DispatchQueue.main.async {
                        AltTabState.shared.showSwitcher()
                        if isBackwards {
                            AltTabState.shared.selectPrevious()
                        } else {
                            AltTabState.shared.selectNext()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if isBackwards {
                            AltTabState.shared.selectPrevious(wrapAllowed: !isAutoRepeat)
                        } else {
                            AltTabState.shared.selectNext(wrapAllowed: !isAutoRepeat)
                        }
                    }
                }
                return nil // Suppress raw Tab so system doesn't beep
            }

            // 5. In-Switcher Navigation Keys — the single input authority for the switcher;
            // no local NSEvent monitor runs in parallel.
            if isAltTabActive {
                // Escape key (KeyCode 53) -> Cancel
                if keyCode == 53 {
                    isAltTabActive = false
                    DispatchQueue.main.async {
                        AltTabState.shared.cancelSelection()
                    }
                    return nil
                }
                // Left arrow (KeyCode 123) / Up arrow (126)
                if keyCode == 123 || keyCode == 126 {
                    DispatchQueue.main.async { AltTabState.shared.selectPrevious() }
                    return nil
                }
                // Right arrow (KeyCode 124) / Down arrow (125)
                if keyCode == 124 || keyCode == 125 {
                    DispatchQueue.main.async { AltTabState.shared.selectNext() }
                    return nil
                }
                // Return / Enter (KeyCode 36) -> Confirm
                if keyCode == 36 {
                    isAltTabActive = false
                    DispatchQueue.main.async { AltTabState.shared.confirmSelection() }
                    return nil
                }
                // 'W' key (KeyCode 13) -> Close focused window
                if keyCode == 13 && !flags.contains(.maskAlternate) && !flags.contains(.maskCommand) {
                    DispatchQueue.main.async { AltTabState.shared.closeSelectedWindow() }
                    return nil
                }
                // 'Q' key (KeyCode 12) -> Quit focused app
                if keyCode == 12 && !flags.contains(.maskAlternate) && !flags.contains(.maskCommand) {
                    DispatchQueue.main.async { AltTabState.shared.quitSelectedApp() }
                    return nil
                }
                // 'M' key (KeyCode 46) -> Minimize focused window
                if keyCode == 46 && !flags.contains(.maskAlternate) && !flags.contains(.maskCommand) {
                    DispatchQueue.main.async { AltTabState.shared.minimizeCurrentWindow() }
                    return nil
                }
                // 'F' key (KeyCode 3) -> Maximize focused window
                if keyCode == 3 && !flags.contains(.maskAlternate) && !flags.contains(.maskCommand) {
                    DispatchQueue.main.async { AltTabState.shared.maximizeCurrentWindow() }
                    return nil
                }
                // Backspace (KeyCode 51) edits the search filter
                let searchEnabled = defaults.object(forKey: "searchFilterEnabled") as? Bool ?? true
                if searchEnabled && keyCode == 51 {
                    DispatchQueue.main.async {
                        if !AltTabState.shared.searchText.isEmpty {
                            AltTabState.shared.searchText.removeLast()
                        }
                    }
                    return nil
                }
                // Printable characters feed the search filter; everything else passes through
                if searchEnabled, let text = Self.keyboardString(for: event),
                   text.count == 1,
                   let scalar = text.unicodeScalars.first,
                   CharacterSet.alphanumerics.contains(scalar),
                   !flags.contains(.maskCommand) {
                    DispatchQueue.main.async {
                        AltTabState.shared.searchText.append(text)
                    }
                    return nil
                }
            }
        }
        
        // 6. System Shortcuts (Win+L lock, Win+Shift+S screenshot)
        if type == .keyDown {
            if let sysEvent = SystemShortcuts.shared.handleKeyEvent(type: type, event: event) {
                if let remappedEvent = CtrlToCmdMapper.shared.handleKeyEvent(type: type, event: sysEvent) {
                    return Unmanaged.passUnretained(remappedEvent)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        if let remappedEvent = CtrlToCmdMapper.shared.handleKeyEvent(type: type, event: event) {
            return Unmanaged.passUnretained(remappedEvent)
        } else {
            return nil
        }
    }

    /// CGEvent → Unicode without an NSEvent; works inside the global tap where local
    /// monitors never fire (the HUD panel doesn't own key focus).
    private static func keyboardString(for event: CGEvent) -> String? {
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        guard length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}
