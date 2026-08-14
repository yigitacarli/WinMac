import Cocoa
import SwiftUI

@MainActor
public final class SettingsWindowController {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    private init() {}
    
    public func show() {
        if window == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 780, height: 560),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            win.title = "WinMac — Windows to Mac Superpowers"
            win.center()
            win.setFrameAutosaveName("WinMacSettingsWindow")
            win.contentView = NSHostingView(rootView: SettingsView())
            win.isReleasedWhenClosed = false
            self.window = win
        }
        
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
