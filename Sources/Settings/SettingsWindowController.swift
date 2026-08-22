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
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            win.title = "WinMac Ayarları"
            win.minSize = NSSize(width: 640, height: 440)
            win.center()
            win.setFrameAutosaveName("WinMacSettingsWindow_v5")
            win.contentView = NSHostingView(rootView: SettingsView())
            win.isReleasedWhenClosed = false
            self.window = win
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
