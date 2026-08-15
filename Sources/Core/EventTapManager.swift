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
        // HotKeys run independently of Accessibility
        DispatchQueue.main.async {
            HotKeyManager.shared.start()
        }
        
        // CGEventTap requires Accessibility permissions
        if AXIsProcessTrusted() {
            startUnifiedEventTap()
        } else {
            print("[WinMac] Accessibility permission not yet granted. HotKeys started, CGEventTap deferred.")
        }
    }
    
    public func startScrollEventTapIfNeeded() {
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
            (1 << CGEventType.scrollWheel.rawValue) |
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
    
    // MARK: - Event Handler
    private func handleSystemEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if disabled by system timeout
        if type == .tapDisabledByUserInput || type == .tapDisabledByTimeout {
            if let tap = globalEventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 1. Mouse Drag & Snap Handling (Single source of truth)
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
        
        // 2. Mouse Scroll Inversion (LinearMouse Engine)
        if type == .scrollWheel {
            if let modified = ScrollInverter.shared.handleScrollEvent(event: event) {
                return Unmanaged.passUnretained(modified)
            }
            return nil
        }
        
        let defaults = UserDefaults.standard
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 3. Modifier Key Release check (Option or Control released while Alt + Tab HUD is active)
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
        
        // 4. Alt + Tab Trigger (Option+Tab or Control+Tab configurable)
        let altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        let shortcutPref = defaults.string(forKey: "switcherShortcut") ?? AltTabShortcut.optionTab.rawValue
        let isCtrlTabPref = shortcutPref == AltTabShortcut.ctrlTab.rawValue
        
        if type == .keyDown && altTabEnabled {
            let isTriggerMatch: Bool
            let currentModifier: TriggerModifier
            
            if isCtrlTabPref {
                // Control + Tab
                isTriggerMatch = keyCode == 48 && flags.contains(.maskControl)
                currentModifier = .control
            } else {
                // Option + Tab
                isTriggerMatch = keyCode == 48 && flags.contains(.maskAlternate)
                currentModifier = .option
            }
            
            if isTriggerMatch {
                let isBackwards = flags.contains(.maskShift)
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
                            AltTabState.shared.selectPrevious()
                        } else {
                            AltTabState.shared.selectNext()
                        }
                    }
                }
                return nil // Suppress raw event so system doesn't beep
            }
            
            // 5. In-Switcher Navigation Keys
            if isAltTabActive {
                // Escape key (KeyCode 53) -> Cancel
                if keyCode == 53 {
                    isAltTabActive = false
                    DispatchQueue.main.async {
                        AltTabState.shared.cancelSelection()
                    }
                    return nil
                }
                // Left arrow (KeyCode 123)
                if keyCode == 123 {
                    DispatchQueue.main.async { AltTabState.shared.selectPrevious() }
                    return nil
                }
                // Right arrow (KeyCode 124)
                if keyCode == 124 {
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
                if keyCode == 13 {
                    DispatchQueue.main.async { AltTabState.shared.closeSelectedWindow() }
                    return nil
                }
                // 'Q' key (KeyCode 12) -> Quit focused app
                if keyCode == 12 {
                    DispatchQueue.main.async { AltTabState.shared.quitSelectedApp() }
                    return nil
                }
            }
        }
        
        // 6. Windows Shortcuts: Win + L to Lock Screen (Option + Command + L)
        let winL = defaults.object(forKey: "winLToLockEnabled") as? Bool ?? true
        if type == .keyDown && winL && keyCode == 37 && flags.contains(.maskAlternate) && flags.contains(.maskCommand) {
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.launchPath = "/usr/bin/pmset"
                task.arguments = ["displaysleepnow"]
                try? task.run()
            }
            return nil
        }
        
        // 7. Windows Shortcuts: Ctrl + Shift + Esc -> Task Manager (Activity Monitor)
        let ctrlShiftEsc = defaults.object(forKey: "ctrlShiftEscTaskManager") as? Bool ?? true
        if type == .keyDown && ctrlShiftEsc && keyCode == 53 && flags.contains(.maskControl) && flags.contains(.maskShift) {
            DispatchQueue.main.async {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"),
                    configuration: NSWorkspace.OpenConfiguration()
                )
            }
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
}
