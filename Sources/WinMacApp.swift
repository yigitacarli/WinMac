import Cocoa
import SwiftUI
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    
    public static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return (version?.isEmpty == false) ? version! : "1.8"
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        print("[WinMac] Application launching...")

        // Ensure regular Dock application
        NSApp.setActivationPolicy(AppSettings.shared.showInDock ? .regular : .accessory)
        
        // Set App Icon explicitly on Dock
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let iconImg = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = iconImg
        }
        
        setupStatusBar()
        EventTapManager.shared.start()
        SwiftQuitEngine.shared.start()
        MousePointerEngine.shared.start()

        PermissionsManager.shared.$hasAccessibilityPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasAccess in
                if hasAccess {
                    EventTapManager.shared.start()
                    SwiftQuitEngine.shared.start()
                    MousePointerEngine.shared.start()
                }
                self?.updateStatusMenu()
            }
            .store(in: &cancellables)

        AppSettings.shared.$showInMenuBar
            .merge(with: AppSettings.shared.$showInDock)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStatusItemVisibility() }
            .store(in: &cancellables)
        
        // Only present settings automatically when accessibility permission is missing
        if !PermissionsManager.shared.hasAccessibilityPermission {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SettingsWindowController.shared.show()
            }
        }
        
        print("[WinMac] Ready.")
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.show()
        return true
    }

    /// Closing the settings window must never quit a background utility.
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Restore the system pointer settings we overrode.
        MousePointerEngine.shared.stop()
    }
    
    private func setupStatusBar() {
        refreshStatusItemVisibility()
    }

    /// Adds or removes the menu-bar item to match the setting. Never lets the app become
    /// unreachable — if the Dock icon is also hidden, the menu-bar item stays.
    func refreshStatusItemVisibility() {
        let wanted = AppSettings.shared.showInMenuBar || !AppSettings.shared.showInDock
        if wanted, statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.image = Self.menuBarIcon()
            item.button?.image?.isTemplate = true
            statusItem = item
            updateStatusMenu()
        } else if !wanted, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    /// A 2×2 grid of little windows — the app-icon motif, as a monochrome template.
    private static func menuBarIcon() -> NSImage {
        let size = NSSize(width: 17, height: 15)
        let image = NSImage(size: size, flipped: false) { _ in
            let gap: CGFloat = 1.5
            let w = (size.width - gap) / 2
            let h = (size.height - gap) / 2
            let radius: CGFloat = 2.2
            let stroke: CGFloat = 1.5
            for (col, row) in [(0, 1), (1, 1), (0, 0), (1, 0)] {
                let cell = NSRect(x: CGFloat(col) * (w + gap),
                                  y: CGFloat(row) * (h + gap),
                                  width: w, height: h)
                let body = NSBezierPath(roundedRect: cell.insetBy(dx: stroke / 2, dy: stroke / 2),
                                        xRadius: radius, yRadius: radius)
                body.lineWidth = stroke
                NSColor.black.setStroke()
                body.stroke()
                // filled title bar so each cell reads as a window
                let bar = NSRect(x: cell.minX, y: cell.maxY - h * 0.30, width: cell.width, height: h * 0.30)
                let barPath = NSBezierPath(roundedRect: bar.insetBy(dx: stroke / 2, dy: stroke / 2),
                                           xRadius: radius * 0.6, yRadius: radius * 0.6)
                NSColor.black.setFill()
                barPath.fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
    
    private func updateStatusMenu() {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "WinMac v\(Self.appVersion)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        if !PermissionsManager.shared.hasAccessibilityPermission {
            let permItem = NSMenuItem(
                title: "⚠️ Erişilebilirlik İzni Gerekli",
                action: #selector(openPermissions),
                keyEquivalent: ""
            )
            permItem.target = self
            menu.addItem(permItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        let rectItem = NSMenuItem(
            title: "Pencere Yaslama Kısayolları: \(AppSettings.shared.snapShortcutsEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleSnap),
            keyEquivalent: ""
        )
        rectItem.target = self
        menu.addItem(rectItem)
        
        let quitItem = NSMenuItem(
            title: "Otomatik Uygulama Çıkışı: \(AppSettings.shared.swiftQuitEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleSwiftQuit),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        let altTabItem = NSMenuItem(
            title: "Pencere Değiştirici (⌥Tab): \(AppSettings.shared.altTabEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleAltTab),
            keyEquivalent: ""
        )
        altTabItem.target = self
        menu.addItem(altTabItem)

        let mouseItem = NSMenuItem(
            title: "Fare Denetimi: \(AppSettings.shared.mousePointerEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleMousePointer),
            keyEquivalent: ""
        )
        mouseItem.target = self
        menu.addItem(mouseItem)
        
        let ctrlCmdItem = NSMenuItem(
            title: "Ctrl ➔ Cmd Kısayolları: \(AppSettings.shared.ctrlToCmdRemapEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleCtrlCmd),
            keyEquivalent: ""
        )
        ctrlCmdItem.target = self
        menu.addItem(ctrlCmdItem)
        
        let clipItem = NSMenuItem(
            title: "Pano Geçmişi (⌥V): \(AppSettings.shared.clipboardHistoryEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleClipboard),
            keyEquivalent: ""
        )
        clipItem.target = self
        menu.addItem(clipItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "WinMac Ayarlarını Aç...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let exitItem = NSMenuItem(
            title: "WinMac'ten Çık",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        exitItem.target = self
        menu.addItem(exitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleSnap() {
        AppSettings.shared.snapShortcutsEnabled.toggle()
        updateStatusMenu()
    }
    
    @objc private func toggleSwiftQuit() {
        AppSettings.shared.swiftQuitEnabled.toggle()
        updateStatusMenu()
    }
    
    @objc private func toggleAltTab() {
        AppSettings.shared.altTabEnabled.toggle()
        updateStatusMenu()
    }

    @objc private func toggleMousePointer() {
        AppSettings.shared.mousePointerEnabled.toggle()
        updateStatusMenu()
    }
    
    @objc private func toggleCtrlCmd() {
        AppSettings.shared.ctrlToCmdRemapEnabled.toggle()
        updateStatusMenu()
    }
    
    @objc private func toggleClipboard() {
        AppSettings.shared.clipboardHistoryEnabled.toggle()
        updateStatusMenu()
    }
    
    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
    
    @objc private func openPermissions() {
        SettingsWindowController.shared.show()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
