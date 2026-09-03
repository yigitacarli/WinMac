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
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.title = "WinMac Ayarları"
            win.minSize = NSSize(width: 700, height: 480)
            win.titlebarAppearsTransparent = false
            win.center()
            win.setFrameAutosaveName("WinMacSettingsWindow_v6")
            win.contentView = NSHostingView(rootView: SettingsView())
            win.isReleasedWhenClosed = false
            self.window = win
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
