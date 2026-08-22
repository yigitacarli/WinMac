import Cocoa
import SwiftUI
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    
    public static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return (version?.isEmpty == false) ? version! : "1.2"
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
        
        PermissionsManager.shared.$hasAccessibilityPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasAccess in
                if hasAccess {
                    EventTapManager.shared.start()
                    SwiftQuitEngine.shared.start()
                }
                self?.updateStatusMenu()
            }
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
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "WinMac")
            button.imagePosition = .imageLeft
        }
        
        updateStatusMenu()
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
        
        let mouseItem = NSMenuItem(
            title: "Fare Tekerleğini Ters Çevir: \(AppSettings.shared.invertMouseWheel ? "Açık" : "Kapalı")",
            action: #selector(toggleMouseScroll),
            keyEquivalent: ""
        )
        mouseItem.target = self
        menu.addItem(mouseItem)
        
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
    
    @objc private func toggleMouseScroll() {
        AppSettings.shared.invertMouseWheel.toggle()
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
