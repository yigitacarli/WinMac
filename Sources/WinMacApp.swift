import Cocoa
import SwiftUI
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        print("[WinMac] Application launching...")
        
        // Ensure regular Dock application
        NSApp.setActivationPolicy(.regular)
        
        // Set App Icon explicitly on Dock
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let iconImg = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = iconImg
        }
        
        setupStatusBar()
        EventTapManager.shared.start()
        
        PermissionsManager.shared.$hasAccessibilityPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasAccess in
                if hasAccess {
                    EventTapManager.shared.start()
                }
                self?.updateStatusMenu()
            }
            .store(in: &cancellables)
        
        // Always present settings window when user opens the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SettingsWindowController.shared.show()
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
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "WinMac")
            button.imagePosition = .imageLeft
        }
        
        updateStatusMenu()
    }
    
    private func updateStatusMenu() {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "WinMac (Alt + Tab & Superpowers)", action: nil, keyEquivalent: "")
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
        
        let altTabItem = NSMenuItem(
            title: "Alt + Tab Pencere Değiştirici: \(AppSettings.shared.altTabEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleAltTab),
            keyEquivalent: ""
        )
        altTabItem.target = self
        menu.addItem(altTabItem)
        
        let mouseScrollItem = NSMenuItem(
            title: "Ters Fare Tekerleği: \(AppSettings.shared.invertMouseWheel ? "Açık" : "Kapalı")",
            action: #selector(toggleMouseScroll),
            keyEquivalent: ""
        )
        mouseScrollItem.target = self
        menu.addItem(mouseScrollItem)
        
        let snapItem = NSMenuItem(
            title: "Pencere Yaslama (Rectangle): \(AppSettings.shared.snapShortcutsEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleSnap),
            keyEquivalent: ""
        )
        snapItem.target = self
        menu.addItem(snapItem)
        
        let ctrlCmdItem = NSMenuItem(
            title: "Ctrl -> Cmd Çevirici: \(AppSettings.shared.ctrlToCmdRemapEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleCtrlCmd),
            keyEquivalent: ""
        )
        ctrlCmdItem.target = self
        menu.addItem(ctrlCmdItem)
        
        let clipItem = NSMenuItem(
            title: "Win + V Pano Geçmişi: \(AppSettings.shared.clipboardHistoryEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleClipboard),
            keyEquivalent: ""
        )
        clipItem.target = self
        menu.addItem(clipItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "Ayarlar Penceresini Aç...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "WinMac'ten Çık",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleAltTab() {
        AppSettings.shared.altTabEnabled.toggle()
        updateStatusMenu()
    }
    
    @objc private func toggleMouseScroll() {
        AppSettings.shared.invertMouseWheel.toggle()
        updateStatusMenu()
    }
    
    @objc private func toggleSnap() {
        AppSettings.shared.snapShortcutsEnabled.toggle()
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
