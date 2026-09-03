import Foundation
import Cocoa
import CoreGraphics
import ApplicationServices

public struct SystemUtils {
    
    // MARK: - Screens
    public static func screenWithMouse() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if NSMouseInRect(mouseLocation, screen.frame, false) {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }
    
    public static func targetScreen(for mode: SwitcherDisplayMode) -> NSScreen {
        switch mode {
        case .cursorDisplay:
            return screenWithMouse()
        case .activeAppDisplay:
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               let screen = screenForApp(pid: frontApp.processIdentifier) {
                return screen
            }
            return NSScreen.main ?? NSScreen.screens.first!
        case .allDisplays:
            return screenWithMouse()
        }
    }
    
    public static func screenForApp(pid: pid_t) -> NSScreen? {
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.25)
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        if result == .success, let windowElement = focusedWindow as! AXUIElement? {
            var positionVal: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionVal) == .success,
               let positionVal = positionVal {
                var point = CGPoint.zero
                AXValueGetValue(positionVal as! AXValue, .cgPoint, &point)
                
                // Convert Carbon/Cocoa coordinate
                for screen in NSScreen.screens {
                    let flippedY = NSScreen.screens[0].frame.maxY - point.y
                    let cocoaPoint = NSPoint(x: point.x, y: flippedY)
                    if NSMouseInRect(cocoaPoint, screen.frame, false) {
                        return screen
                    }
                }
            }
        }
        return NSScreen.main
    }
    
    // MARK: - Actions
    public static func lockScreen() {
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        if let libHandle = libHandle {
            let sym = dlsym(libHandle, "SACLockScreenImmediate")
            if let sym = sym {
                typealias Function = @convention(c) () -> Void
                let lockFunction = unsafeBitCast(sym, to: Function.self)
                lockFunction()
                dlclose(libHandle)
                return
            }
            dlclose(libHandle)
        }
        
        let script = "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
        }
    }
    
    public static func openActivityMonitor() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public static func triggerScreenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        try? task.run()
    }
    
    // MARK: - Keystroke Synthesis
    public static func postKey(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        if let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
            event.flags = flags
            event.post(tap: .cgSessionEventTap)
        }
    }
    
    public static func sendKeystroke(keyCode: CGKeyCode, flags: CGEventFlags) {
        postKey(keyCode: keyCode, flags: flags, keyDown: true)
        usleep(10000)
        postKey(keyCode: keyCode, flags: flags, keyDown: false)
    }
}
