import CoreGraphics
import Foundation
import Cocoa
import ApplicationServices

public final class EventTapManager: @unchecked Sendable {
    public static let shared = EventTapManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Alt + Tab State Tracking
    private var isAltTabActive = false
    private var activeTriggerModifier: TriggerModifier = .option
    
    private enum TriggerModifier {
        case option
        case control
    }
    
    private init() {}
    
    public func start() {
        guard eventTap == nil else { return }
        guard AXIsProcessTrusted() else {
            print("[WinMac] Cannot start EventTap: Accessibility permission not granted.")
            return
        }
        
        // Start Carbon HotKeys for global window snapping on main thread
        DispatchQueue.main.async {
            HotKeyManager.shared.start()
        }
        
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue)
        )
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else {
                return Unmanaged.passUnretained(event)
            }
            let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleEvent(proxy: proxy, type: type, event: event)
        }
        
        var tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if tap == nil {
            tap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        }
        
        guard let validTap = tap else {
            print("[WinMac] Warning: Failed to create CGEventTap.")
            return
        }
        
        self.eventTap = validTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, validTap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: validTap, enable: true)
        print("[WinMac] Global EventTap successfully started.")
    }
    
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
            print("[WinMac] EventTap stopped safely.")
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Critical safety check: if user revoked permission, stop immediately to avoid UI deadlock
        if type == .tapDisabledByUserInput {
            self.stop()
            return Unmanaged.passUnretained(event)
        }
        
        if type == .tapDisabledByTimeout {
            if AXIsProcessTrusted(), let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            } else {
                self.stop()
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 1. Mouse Drag to Snap (Aero Snap)
        if type == .leftMouseDragged {
            let loc = event.location
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseDrag(point: loc)
            }
            return Unmanaged.passUnretained(event)
        }
        if type == .leftMouseUp {
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseUp()
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 2. Mouse Movement & Sensitivity scaling
        if type == .mouseMoved {
            if let scaled = ScrollInverter.shared.handlePointerEvent(event: event) {
                return Unmanaged.passUnretained(scaled)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 3. Mouse Scroll Inversion & Modifiers (LinearMouse Engine)
        if type == .scrollWheel {
            if let modified = ScrollInverter.shared.handleScrollEvent(event: event) {
                return Unmanaged.passUnretained(modified)
            }
            return nil
        }
        
        let defaults = UserDefaults.standard
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 4. Modifier Key Release check (Option or Control released while Alt + Tab HUD is active)
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
        
        // 5. Alt + Tab Trigger (Option+Tab or Control+Tab configurable)
        let altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        let shortcutPref = defaults.string(forKey: "switcherShortcut") ?? AltTabShortcut.optionTab.rawValue
        let isCtrlTabPref = shortcutPref == AltTabShortcut.ctrlTab.rawValue
        
        if type == .keyDown && altTabEnabled {
            let isTriggerMatch: Bool
            let currentModifier: TriggerModifier
            
            if isCtrlTabPref {
                // Control + Tab
                isTriggerMatch = (keyCode == 48 && flags.contains(.maskControl) && !flags.contains(.maskAlternate) && !flags.contains(.maskCommand))
                currentModifier = .control
            } else {
                // Option + Tab (Alt + Tab)
                isTriggerMatch = (keyCode == 48 && flags.contains(.maskAlternate) && !flags.contains(.maskControl) && !flags.contains(.maskCommand))
                currentModifier = .option
            }
            
            if isTriggerMatch {
                if !isAltTabActive {
                    isAltTabActive = true
                    activeTriggerModifier = currentModifier
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
        
        // 6. Window Snapping Keyboard Shortcuts (Option + Control / Command + Option)
        let snapEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        if type == .keyDown && snapEnabled {
            let isOptCtrl = flags.contains(.maskAlternate) && flags.contains(.maskControl) && !flags.contains(.maskCommand)
            let isOptCmd = flags.contains(.maskAlternate) && flags.contains(.maskCommand) && !flags.contains(.maskControl)
            let isOptCtrlCmd = flags.contains(.maskAlternate) && flags.contains(.maskControl) && flags.contains(.maskCommand)
            
            if isOptCtrlCmd {
                if keyCode == 123 { // Left Arrow -> Display left
                    DispatchQueue.main.async { SnapEngine.shared.moveFocusedWindowToDisplay(direction: -1) }
                    return nil
                } else if keyCode == 124 { // Right Arrow -> Display right
                    DispatchQueue.main.async { SnapEngine.shared.moveFocusedWindowToDisplay(direction: 1) }
                    return nil
                }
            } else if isOptCtrl || isOptCmd {
                if let snapAction = snapActionFor(keyCode: keyCode) {
                    DispatchQueue.main.async {
                        SnapEngine.shared.handleShortcutAction(snapAction)
                    }
                    return nil
                }
            }
        }
        
        // 7. Option + V / Control + Shift + V / Command + Shift + V -> Clipboard History
        let clipEnabled = defaults.object(forKey: "clipboardHistoryEnabled") as? Bool ?? true
        if type == .keyDown && clipEnabled {
            let isOptV = (keyCode == 9 && flags.contains(.maskAlternate) && !flags.contains(.maskControl) && !flags.contains(.maskCommand))
            let isCtrlShiftV = (keyCode == 9 && flags.contains(.maskControl) && flags.contains(.maskShift) && !flags.contains(.maskCommand))
            let isCmdShiftV = (keyCode == 9 && flags.contains(.maskCommand) && flags.contains(.maskShift) && !flags.contains(.maskControl))
            
            if isOptV || isCtrlShiftV || isCmdShiftV {
                DispatchQueue.main.async {
                    ClipboardHUDController.shared.toggle()
                }
                return nil
            }
        }
        
        // 8. System Shortcuts (Option + L -> Lock Screen, etc.)
        if let sysResult = SystemShortcuts.shared.handleKeyEvent(type: type, event: event) {
            if sysResult !== event {
                return Unmanaged.passRetained(sysResult)
            }
        } else {
            return nil
        }
        
        // 9. Ctrl to Cmd Key Remapping (Ctrl+C/V/Z/Y/A/S/F/W/T/P/N/R)
        if let ctrlResult = CtrlToCmdMapper.shared.handleKeyEvent(type: type, event: event) {
            if ctrlResult !== event {
                return Unmanaged.passRetained(ctrlResult)
            }
        } else {
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func snapActionFor(keyCode: CGKeyCode) -> SnapAction? {
        switch keyCode {
        case 123: return .leftHalf            // Left Arrow
        case 124: return .rightHalf           // Right Arrow
        case 126: return .topHalf             // Up Arrow
        case 125: return .bottomHalf          // Down Arrow
        case 36:  return .maximize            // Return
        case 8:   return .center              // C
        case 32:  return .topLeftQuarter      // U
        case 34:  return .topRightQuarter     // I
        case 38:  return .bottomLeftQuarter   // J
        case 40:  return .bottomRightQuarter  // K
        case 2:   return .leftThird           // D
        case 3:   return .centerThird         // F
        case 5:   return .rightThird          // G
        case 14:  return .leftTwoThirds       // E
        case 17:  return .rightTwoThirds      // T
        case 24:  return .expandSize          // = / +
        case 27:  return .shrinkSize          // -
        default:  return nil
        }
    }
}
