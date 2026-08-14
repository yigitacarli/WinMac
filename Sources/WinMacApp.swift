import Cocoa
import SwiftUI
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        print("[WinMac] Application launching...")
        
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
        
        if !PermissionsManager.shared.allPermissionsGranted {
            SettingsWindowController.shared.show()
        }
        
        print("[WinMac] Ready.")
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
        
        let titleItem = NSMenuItem(title: "WinMac (AltTab+ & Tools)", action: nil, keyEquivalent: "")
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
            title: "AltTab Pencere Değiştirici: \(AppSettings.shared.altTabEnabled ? "Açık" : "Kapalı")",
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
        
        let ctrlCmdItem = NSMenuItem(
            title: "Ctrl -> Cmd Çevirici: \(AppSettings.shared.ctrlToCmdRemapEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleCtrlCmd),
            keyEquivalent: ""
        )
        ctrlCmdItem.target = self
        menu.addItem(ctrlCmdItem)
        
        let clipItem = NSMenuItem(
            title: "Win+V Pano Geçmişi: \(AppSettings.shared.clipboardHistoryEnabled ? "Açık" : "Kapalı")",
            action: #selector(toggleClipboard),
            keyEquivalent: ""
        )
        clipItem.target = self
        menu.addItem(clipItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "Ayarlar...",
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
