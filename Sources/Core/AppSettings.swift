import Foundation
import Combine
import Cocoa
import CoreGraphics
import ServiceManagement

public enum SwitcherStyle: String, CaseIterable, Identifiable, Sendable {
    case thumbnails = "thumbnails"
    case icons = "icons"
    case compact = "compact"
    case list = "list"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .thumbnails: return "Pencere Önizlemeleri"
        case .icons: return "Büyük Uygulama Simgeleri"
        case .compact: return "Kompakt Izgara"
        case .list: return "Ayrıntılı Liste"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .thumbnails: return "Canlı pencere görselleri"
        case .icons: return "Hızlı simge odaklı geçiş"
        case .compact: return "Yüksek yoğunluklu kartlar"
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
    
    // MARK: - 3. LinearMouse (Mouse & Scroll Control)
    @Published public var disableMouseAcceleration: Bool {
        didSet {
            defaults.set(disableMouseAcceleration, forKey: "disableMouseAcceleration")
            ScrollInverter.shared.updateHardwarePointerProperties(linear: disableMouseAcceleration, sensitivity: mousePointerSensitivity)
        }
    }
    @Published public var mousePointerSensitivity: Double {
        didSet {
            defaults.set(mousePointerSensitivity, forKey: "mousePointerSensitivity")
            ScrollInverter.shared.updateHardwarePointerProperties(linear: disableMouseAcceleration, sensitivity: mousePointerSensitivity)
        }
    }
    @Published public var invertMouseWheel: Bool {
        didSet { defaults.set(invertMouseWheel, forKey: "invertMouseWheel") }
    }
    @Published public var invertHorizontalScroll: Bool {
        didSet { defaults.set(invertHorizontalScroll, forKey: "invertHorizontalScroll") }
    }
    @Published public var scrollSpeedMultiplier: Double {
        didSet { defaults.set(scrollSpeedMultiplier, forKey: "scrollSpeedMultiplier") }
    }
    @Published public var shiftToHorizontalScroll: Bool {
        didSet { defaults.set(shiftToHorizontalScroll, forKey: "shiftToHorizontalScroll") }
    }
    @Published public var cmdToZoom: Bool {
        didSet { defaults.set(cmdToZoom, forKey: "cmdToZoom") }
    }
    
    // MARK: - 4. SwiftQuit (Auto Termination)
    @Published public var swiftQuitEnabled: Bool {
        didSet { defaults.set(swiftQuitEnabled, forKey: "swiftQuitEnabled") }
    }
    @Published public var swiftQuitDelaySeconds: Int {
        didSet { defaults.set(swiftQuitDelaySeconds, forKey: "swiftQuitDelaySeconds") }
    }
    @Published public var swiftQuitExcludedApps: [String] {
        didSet { defaults.set(swiftQuitExcludedApps, forKey: "swiftQuitExcludedApps") }
    }
    
    // MARK: - 5. AltTab (Window Switcher HUD)
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
    @Published public var hideHiddenApps: Bool {
        didSet { defaults.set(hideHiddenApps, forKey: "hideHiddenApps") }
    }
    @Published public var showDesktopCard: Bool {
        didSet { defaults.set(showDesktopCard, forKey: "showDesktopCard") }
    }
    
    // MARK: - 6. Windows Shortcuts & Muscle Memory Remapping
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
    
    // MARK: - 7. Clipboard History (Win+V / Option+V)
    @Published public var clipboardHistoryEnabled: Bool {
        didSet { defaults.set(clipboardHistoryEnabled, forKey: "clipboardHistoryEnabled") }
    }
    @Published public var maxClipboardItems: Int {
        didSet { defaults.set(maxClipboardItems, forKey: "maxClipboardItems") }
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
        
        // LinearMouse
        self.disableMouseAcceleration = defaults.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        self.mousePointerSensitivity = defaults.object(forKey: "mousePointerSensitivity") as? Double ?? 1.0
        self.invertMouseWheel = defaults.object(forKey: "invertMouseWheel") as? Bool ?? false
        self.invertHorizontalScroll = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? false
        self.scrollSpeedMultiplier = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        self.shiftToHorizontalScroll = defaults.object(forKey: "shiftToHorizontalScroll") as? Bool ?? true
        self.cmdToZoom = defaults.object(forKey: "cmdToZoom") as? Bool ?? true
        
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
        
        // Sync hardware pointer state on startup
        ScrollInverter.shared.updateHardwarePointerProperties(linear: self.disableMouseAcceleration, sensitivity: self.mousePointerSensitivity)
    }
}
