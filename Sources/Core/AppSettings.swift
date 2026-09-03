import Foundation
import Combine
import Cocoa
import CoreGraphics
import ServiceManagement

public enum SwitcherStyle: String, CaseIterable, Identifiable, Sendable {
    case icons = "icons"
    case list = "list"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .icons: return "Büyük Uygulama Simgeleri"
        case .list: return "Ayrıntılı Liste"
        }
    }

    public var subtitle: String {
        switch self {
        case .icons: return "Hızlı simge odaklı geçiş"
        case .list: return "Başlık ve süreç detayları"
        }
    }
}

public enum AltTabShortcut: String, CaseIterable, Identifiable, Sendable {
    case optionTab = "optionTab"
    case ctrlTab = "ctrlTab"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .optionTab: return "⌥ Option + Tab (Önerilen)"
        case .ctrlTab: return "⌃ Control + Tab"
        }
    }
}

public enum SwitcherDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case cursorDisplay = "cursorDisplay"
    case activeAppDisplay = "activeAppDisplay"
    case allDisplays = "allDisplays"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .cursorDisplay: return "İmlecin Olduğu Ekranda"
        case .activeAppDisplay: return "Aktif Pencere Ekranında"
        case .allDisplays: return "Tüm Ekranlarda Aynı Anda"
        }
    }
}

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - 1. General & System Settings
    @Published public var showInDock: Bool {
        didSet {
            defaults.set(showInDock, forKey: "showInDock")
            NSApp?.setActivationPolicy(showInDock ? .regular : .accessory)
        }
    }
    
    @Published public var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: "showInMenuBar") }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[WinMac] LaunchAtLogin error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 2. Rectangle Pro (Window Snapping)
    @Published public var aeroSnapEnabled: Bool {
        didSet { defaults.set(aeroSnapEnabled, forKey: "aeroSnapEnabled") }
    }
    @Published public var dragToSnapEnabled: Bool {
        didSet { defaults.set(dragToSnapEnabled, forKey: "dragToSnapEnabled") }
    }
    @Published public var snapShortcutsEnabled: Bool {
        didSet { defaults.set(snapShortcutsEnabled, forKey: "snapShortcutsEnabled") }
    }
    @Published public var cycleRepeatedShortcuts: Bool {
        didSet { defaults.set(cycleRepeatedShortcuts, forKey: "cycleRepeatedShortcuts") }
    }
    @Published public var snapWindowGaps: Double {
        didSet { defaults.set(snapWindowGaps, forKey: "snapWindowGaps") }
    }
    @Published public var almostMaximizePadding: Double {
        didSet { defaults.set(almostMaximizePadding, forKey: "almostMaximizePadding") }
    }
    
    // MARK: - 3. SwiftQuit (Auto Termination)
    @Published public var swiftQuitEnabled: Bool {
        didSet { defaults.set(swiftQuitEnabled, forKey: "swiftQuitEnabled") }
    }
    @Published public var swiftQuitDelaySeconds: Int {
        didSet { defaults.set(swiftQuitDelaySeconds, forKey: "swiftQuitDelaySeconds") }
    }
    @Published public var swiftQuitExcludedApps: [String] {
        didSet { defaults.set(swiftQuitExcludedApps, forKey: "swiftQuitExcludedApps") }
    }
    
    // MARK: - 4. AltTab (Window Switcher HUD)
    @Published public var altTabEnabled: Bool {
        didSet { defaults.set(altTabEnabled, forKey: "altTabEnabled") }
    }
    @Published public var switcherStyle: SwitcherStyle {
        didSet { defaults.set(switcherStyle.rawValue, forKey: "switcherStyle") }
    }
    @Published public var switcherShortcut: AltTabShortcut {
        didSet { defaults.set(switcherShortcut.rawValue, forKey: "switcherShortcut") }
    }
    @Published public var displayMode: SwitcherDisplayMode {
        didSet { defaults.set(displayMode.rawValue, forKey: "displayMode") }
    }
    @Published public var searchFilterEnabled: Bool {
        didSet { defaults.set(searchFilterEnabled, forKey: "searchFilterEnabled") }
    }
    @Published public var hoverSelectEnabled: Bool {
        didSet { defaults.set(hoverSelectEnabled, forKey: "hoverSelectEnabled") }
    }
    @Published public var hideHiddenApps: Bool {
        didSet { defaults.set(hideHiddenApps, forKey: "hideHiddenApps") }
    }
    @Published public var showDesktopCard: Bool {
        didSet { defaults.set(showDesktopCard, forKey: "showDesktopCard") }
    }
    
    // MARK: - 5. Windows Shortcuts & Muscle Memory Remapping
    @Published public var ctrlToCmdRemapEnabled: Bool {
        didSet { defaults.set(ctrlToCmdRemapEnabled, forKey: "ctrlToCmdRemapEnabled") }
    }
    @Published public var ctrlBackspaceWordDelete: Bool {
        didSet { defaults.set(ctrlBackspaceWordDelete, forKey: "ctrlBackspaceWordDelete") }
    }
    @Published public var ctrlArrowWordJump: Bool {
        didSet { defaults.set(ctrlArrowWordJump, forKey: "ctrlArrowWordJump") }
    }
    @Published public var winLToLockEnabled: Bool {
        didSet { defaults.set(winLToLockEnabled, forKey: "winLToLockEnabled") }
    }
    @Published public var ctrlShiftEscTaskManager: Bool {
        didSet { defaults.set(ctrlShiftEscTaskManager, forKey: "ctrlShiftEscTaskManager") }
    }
    @Published public var winEToFileExplorer: Bool {
        didSet { defaults.set(winEToFileExplorer, forKey: "winEToFileExplorer") }
    }
    @Published public var winDToShowDesktop: Bool {
        didSet { defaults.set(winDToShowDesktop, forKey: "winDToShowDesktop") }
    }
    @Published public var excludedAppsForCtrl: [String] {
        didSet { defaults.set(excludedAppsForCtrl, forKey: "excludedAppsForCtrl") }
    }
    
    // MARK: - 6. Clipboard History (Win+V / Option+V)
    @Published public var clipboardHistoryEnabled: Bool {
        didSet { defaults.set(clipboardHistoryEnabled, forKey: "clipboardHistoryEnabled") }
    }
    @Published public var maxClipboardItems: Int {
        didSet { defaults.set(maxClipboardItems, forKey: "maxClipboardItems") }
    }

    // MARK: - 7. Mouse Pointer Control (cursor acceleration & speed)
    @Published public var mousePointerEnabled: Bool {
        didSet {
            defaults.set(mousePointerEnabled, forKey: "mousePointerEnabled")
            MousePointerEngine.shared.syncFromSettings()
        }
    }
    @Published public var mousePointerDisableAccel: Bool {
        didSet {
            defaults.set(mousePointerDisableAccel, forKey: "mousePointerDisableAccel")
            MousePointerEngine.shared.syncFromSettings()
        }
    }
    /// Cursor acceleration when acceleration is NOT disabled. macOS default ≈ 0.6875.
    @Published public var mousePointerAcceleration: Double {
        didSet {
            defaults.set(mousePointerAcceleration, forKey: "mousePointerAcceleration")
            MousePointerEngine.shared.syncFromSettings()
        }
    }
    /// Speed as a multiplier over the device's native resolution (2.0 = twice as fast).
    @Published public var mousePointerSpeed: Double {
        didSet {
            defaults.set(mousePointerSpeed, forKey: "mousePointerSpeed")
            MousePointerEngine.shared.syncFromSettings()
        }
    }
    /// While one of these apps is frontmost, pointer overrides are suspended.
    @Published public var mousePointerExcludedApps: [String] {
        didSet {
            defaults.set(mousePointerExcludedApps, forKey: "mousePointerExcludedApps")
            MousePointerEngine.shared.syncFromSettings()
        }
    }

    // MARK: - Initializer
    private init() {
        self.showInDock = defaults.object(forKey: "showInDock") as? Bool ?? true
        self.showInMenuBar = defaults.object(forKey: "showInMenuBar") as? Bool ?? true
        self.launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        
        // Rectangle
        self.aeroSnapEnabled = defaults.object(forKey: "aeroSnapEnabled") as? Bool ?? true
        self.dragToSnapEnabled = defaults.object(forKey: "dragToSnapEnabled") as? Bool ?? true
        self.snapShortcutsEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        self.cycleRepeatedShortcuts = defaults.object(forKey: "cycleRepeatedShortcuts") as? Bool ?? true
        self.snapWindowGaps = defaults.object(forKey: "snapWindowGaps") as? Double ?? 0.0
        self.almostMaximizePadding = defaults.object(forKey: "almostMaximizePadding") as? Double ?? 24.0
        
        // SwiftQuit
        self.swiftQuitEnabled = defaults.object(forKey: "swiftQuitEnabled") as? Bool ?? false
        self.swiftQuitDelaySeconds = defaults.object(forKey: "swiftQuitDelaySeconds") as? Int ?? 2
        self.swiftQuitExcludedApps = defaults.stringArray(forKey: "swiftQuitExcludedApps") ?? [
            "com.apple.Music",
            "com.apple.mail",
            "com.google.antigravity",
            "com.riotgames.RiotGames.RiotClient",
            "com.riotgames.LeagueofLegends.LeagueClientUx"
        ]
        
        // AltTab
        self.altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        let styleStr = defaults.string(forKey: "switcherStyle") ?? SwitcherStyle.icons.rawValue
        self.switcherStyle = SwitcherStyle(rawValue: styleStr) ?? .icons
        let shortcutStr = defaults.string(forKey: "switcherShortcut") ?? AltTabShortcut.optionTab.rawValue
        self.switcherShortcut = AltTabShortcut(rawValue: shortcutStr) ?? .optionTab
        let dispStr = defaults.string(forKey: "displayMode") ?? SwitcherDisplayMode.cursorDisplay.rawValue
        self.displayMode = SwitcherDisplayMode(rawValue: dispStr) ?? .cursorDisplay
        self.searchFilterEnabled = defaults.object(forKey: "searchFilterEnabled") as? Bool ?? true
        self.hoverSelectEnabled = defaults.object(forKey: "hoverSelectEnabled") as? Bool ?? true
        self.hideHiddenApps = defaults.object(forKey: "hideHiddenApps") as? Bool ?? false
        self.showDesktopCard = defaults.object(forKey: "showDesktopCard") as? Bool ?? true
        
        // Windows Shortcuts
        self.ctrlToCmdRemapEnabled = defaults.object(forKey: "ctrlToCmdRemapEnabled") as? Bool ?? true
        self.ctrlBackspaceWordDelete = defaults.object(forKey: "ctrlBackspaceWordDelete") as? Bool ?? true
        self.ctrlArrowWordJump = defaults.object(forKey: "ctrlArrowWordJump") as? Bool ?? true
        self.winLToLockEnabled = defaults.object(forKey: "winLToLockEnabled") as? Bool ?? true
        self.ctrlShiftEscTaskManager = defaults.object(forKey: "ctrlShiftEscTaskManager") as? Bool ?? true
        self.winEToFileExplorer = defaults.object(forKey: "winEToFileExplorer") as? Bool ?? true
        self.winDToShowDesktop = defaults.object(forKey: "winDToShowDesktop") as? Bool ?? true
        self.excludedAppsForCtrl = defaults.stringArray(forKey: "excludedAppsForCtrl") ?? [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "net.kovidgoyal.kitty",
            "com.github.wez.wezterm",
            "dev.warp.Warp-Stable",
            "io.alacritty"
        ]
        
        // Clipboard
        self.clipboardHistoryEnabled = defaults.object(forKey: "clipboardHistoryEnabled") as? Bool ?? true
        self.maxClipboardItems = defaults.object(forKey: "maxClipboardItems") as? Int ?? 50

        // Mouse Pointer Control (off by default; disabling accel is the common use)
        self.mousePointerEnabled = defaults.object(forKey: "mousePointerEnabled") as? Bool ?? false
        self.mousePointerDisableAccel = defaults.object(forKey: "mousePointerDisableAccel") as? Bool ?? true
        self.mousePointerAcceleration = defaults.object(forKey: "mousePointerAcceleration") as? Double ?? 0.6875
        self.mousePointerSpeed = defaults.object(forKey: "mousePointerSpeed") as? Double ?? 1.0
        self.mousePointerExcludedApps = defaults.stringArray(forKey: "mousePointerExcludedApps") ?? []
    }
}
