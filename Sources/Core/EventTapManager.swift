import CoreGraphics
import Foundation
import Cocoa
import ApplicationServices

public final class EventTapManager: @unchecked Sendable {
    public static let shared = EventTapManager()
    
    private var globalEventTap: CFMachPort?
    private var eventRunLoopSource: CFRunLoopSource?
    private var mouseDragMonitor: Any?
    private var mouseUpMonitor: Any?
    
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
            self.startGlobalMouseMonitors()
        }
        
        // CGEventTap requires Accessibility permissions
        if AXIsProcessTrusted() {
            startUnifiedEventTap()
        } else {
            print("[WinMac] Accessibility permission not yet granted. HotKeys and monitors started, CGEventTap deferred.")
        }
    }
    
    public func startScrollEventTapIfNeeded() {
        guard globalEventTap == nil, AXIsProcessTrusted() else { return }
        startUnifiedEventTap()
    }
    
    public func stop() {
        stopUnifiedEventTap()
        stopGlobalMouseMonitors()
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
    
    // MARK: - Global Mouse Monitors (Supplementary backup)
    private func startGlobalMouseMonitors() {
        stopGlobalMouseMonitors()
        
        mouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { _ in
            let loc = NSEvent.mouseLocation
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseDrag(point: CGPoint(x: loc.x, y: loc.y))
            }
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { _ in
            DispatchQueue.main.async {
                SnapEngine.shared.handleMouseUp()
            }
        }
    }
    
    private func stopGlobalMouseMonitors() {
        if let monitor = mouseDragMonitor {
            NSEvent.removeMonitor(monitor)
            mouseDragMonitor = nil
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
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
        
        // 1. Mouse Drag & Snap Handling
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
        
        // 2. Mouse Scroll Inversion & Modifiers (LinearMouse Engine)
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
        
        // 5. Option + V / Control + Shift + V / Command + Shift + V -> Clipboard History
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
        
        // 6. System Shortcuts (Option + L -> Lock Screen, etc.)
        if let sysResult = SystemShortcuts.shared.handleKeyEvent(type: type, event: event) {
            if sysResult !== event {
                return Unmanaged.passRetained(sysResult)
            }
        } else {
            return nil
        }
        
        // 7. Ctrl to Cmd Key Remapping (Ctrl+C/V/Z/Y/A/S/F/W/T/P/N/R)
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
