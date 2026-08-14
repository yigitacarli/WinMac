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
                contentRect: NSRect(x: 0, y: 0, width: 840, height: 580),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            win.title = "WinMac"
            win.titlebarAppearsTransparent = true
            win.minSize = NSSize(width: 650, height: 450)
            win.center()
            win.setFrameAutosaveName("WinMacSettingsWindow_v3")
            win.contentView = NSHostingView(rootView: SettingsView())
            win.isReleasedWhenClosed = false
            self.window = win
        }
        
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
