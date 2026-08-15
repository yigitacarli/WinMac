import Foundation
import Combine
import Cocoa
import CoreGraphics

public enum SwitcherStyle: String, CaseIterable, Identifiable, Sendable {
    case thumbnails = "thumbnails"
    case icons = "icons"
    case compact = "compact"
    case list = "list"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .thumbnails: return "Pencere Önizlemeleri"
        case .icons: return "Simgeler (Büyük)"
        case .compact: return "Kompakt Izgara"
        case .list: return "Ayrıntılı Liste"
        }
    }
}

public enum AltTabShortcut: String, CaseIterable, Identifiable, Sendable {
    case optionTab = "optionTab"
    case ctrlTab = "ctrlTab"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .optionTab: return "⌥ Option + Tab"
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
        case .activeAppDisplay: return "Aktif Uygulama Ekranında"
        case .allDisplays: return "Tüm Ekranlarda Aynı Anda"
        }
    }
}

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - General Settings
    @Published public var showInDock: Bool {
        didSet {
            defaults.set(showInDock, forKey: "showInDock")
            NSApp?.setActivationPolicy(showInDock ? .regular : .accessory)
        }
    }
    
    // MARK: - SwiftQuit (Auto Quit on Last Window Close)
    @Published public var swiftQuitEnabled: Bool {
        didSet { defaults.set(swiftQuitEnabled, forKey: "swiftQuitEnabled") }
    }
    @Published public var swiftQuitDelaySeconds: Int {
        didSet { defaults.set(swiftQuitDelaySeconds, forKey: "swiftQuitDelaySeconds") }
    }
    @Published public var swiftQuitExcludedApps: [String] {
        didSet { defaults.set(swiftQuitExcludedApps, forKey: "swiftQuitExcludedApps") }
    }
    
    // MARK: - Alt + Tab Settings
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
    @Published public var itemSize: Double {
        didSet { defaults.set(itemSize, forKey: "itemSize") }
    }
    
    // MARK: - Linear Mouse & Scroll Pro Settings
    @Published public var invertMouseWheel: Bool {
        didSet { defaults.set(invertMouseWheel, forKey: "invertMouseWheel") }
    }
    @Published public var invertHorizontalScroll: Bool {
        didSet { defaults.set(invertHorizontalScroll, forKey: "invertHorizontalScroll") }
    }
    @Published public var disableMouseAcceleration: Bool {
        didSet {
            defaults.set(disableMouseAcceleration, forKey: "disableMouseAcceleration")
            ScrollInverter.shared.updateHardwarePointerProperties(linear: disableMouseAcceleration, sensitivity: mousePointerSensitivity)
        }
    }
    @Published public var scrollSpeedMultiplier: Double {
        didSet { defaults.set(scrollSpeedMultiplier, forKey: "scrollSpeedMultiplier") }
    }
    @Published public var mousePointerSensitivity: Double {
        didSet {
            defaults.set(mousePointerSensitivity, forKey: "mousePointerSensitivity")
            ScrollInverter.shared.updateHardwarePointerProperties(linear: disableMouseAcceleration, sensitivity: mousePointerSensitivity)
        }
    }
    
    // MARK: - Keyboard & Muscle Memory Settings
    @Published public var ctrlToCmdRemapEnabled: Bool {
        didSet { defaults.set(ctrlToCmdRemapEnabled, forKey: "ctrlToCmdRemapEnabled") }
    }
    @Published public var excludedAppsForCtrl: [String] {
        didSet { defaults.set(excludedAppsForCtrl, forKey: "excludedAppsForCtrl") }
    }
    
    // MARK: - Clipboard History
    @Published public var clipboardHistoryEnabled: Bool {
        didSet { defaults.set(clipboardHistoryEnabled, forKey: "clipboardHistoryEnabled") }
    }
    @Published public var maxClipboardItems: Int {
        didSet { defaults.set(maxClipboardItems, forKey: "maxClipboardItems") }
    }
    
    // MARK: - Rectangle Pro (Window Snapping & Drag-to-Snap)
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
    
    // MARK: - System Shortcuts
    @Published public var winLToLockEnabled: Bool {
        didSet { defaults.set(winLToLockEnabled, forKey: "winLToLockEnabled") }
    }
    @Published public var ctrlShiftEscTaskManager: Bool {
        didSet { defaults.set(ctrlShiftEscTaskManager, forKey: "ctrlShiftEscTaskManager") }
    }
    
    // MARK: - Initializer
    private init() {
        self.showInDock = defaults.object(forKey: "showInDock") as? Bool ?? true
        
        self.swiftQuitEnabled = defaults.object(forKey: "swiftQuitEnabled") as? Bool ?? true
        self.swiftQuitDelaySeconds = defaults.object(forKey: "swiftQuitDelaySeconds") as? Int ?? 0
        self.swiftQuitExcludedApps = defaults.stringArray(forKey: "swiftQuitExcludedApps") ?? [
            "com.apple.Music",
            "com.apple.mail"
        ]
        
        self.altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        
        let styleStr = defaults.string(forKey: "switcherStyle") ?? SwitcherStyle.icons.rawValue
        self.switcherStyle = SwitcherStyle(rawValue: styleStr) ?? .icons
        
        let shortcutStr = defaults.string(forKey: "switcherShortcut") ?? AltTabShortcut.optionTab.rawValue
        self.switcherShortcut = AltTabShortcut(rawValue: shortcutStr) ?? .optionTab
        
        let dispStr = defaults.string(forKey: "displayMode") ?? SwitcherDisplayMode.cursorDisplay.rawValue
        self.displayMode = SwitcherDisplayMode(rawValue: dispStr) ?? .cursorDisplay
        
        self.searchFilterEnabled = defaults.object(forKey: "searchFilterEnabled") as? Bool ?? true
        self.hideHiddenApps = defaults.object(forKey: "hideHiddenApps") as? Bool ?? false
        self.itemSize = defaults.object(forKey: "itemSize") as? Double ?? 1.0
        
        self.invertMouseWheel = defaults.object(forKey: "invertMouseWheel") as? Bool ?? false
        self.invertHorizontalScroll = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? false
        self.disableMouseAcceleration = defaults.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        self.scrollSpeedMultiplier = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        self.mousePointerSensitivity = defaults.object(forKey: "mousePointerSensitivity") as? Double ?? 1.0
        
        self.ctrlToCmdRemapEnabled = defaults.object(forKey: "ctrlToCmdRemapEnabled") as? Bool ?? true
        self.excludedAppsForCtrl = defaults.stringArray(forKey: "excludedAppsForCtrl") ?? [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "net.kovidgoyal.kitty",
            "com.github.wez.wezterm",
            "com.microsoft.VSCode",
            "com.jetbrains.intellij"
        ]
        
        self.clipboardHistoryEnabled = defaults.object(forKey: "clipboardHistoryEnabled") as? Bool ?? true
        self.maxClipboardItems = defaults.object(forKey: "maxClipboardItems") as? Int ?? 50
        
        self.aeroSnapEnabled = defaults.object(forKey: "aeroSnapEnabled") as? Bool ?? true
        self.dragToSnapEnabled = defaults.object(forKey: "dragToSnapEnabled") as? Bool ?? true
        self.snapShortcutsEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        self.cycleRepeatedShortcuts = defaults.object(forKey: "cycleRepeatedShortcuts") as? Bool ?? true
        self.snapWindowGaps = defaults.object(forKey: "snapWindowGaps") as? Double ?? 0.0
        
        self.winLToLockEnabled = defaults.object(forKey: "winLToLockEnabled") as? Bool ?? true
        self.ctrlShiftEscTaskManager = defaults.object(forKey: "ctrlShiftEscTaskManager") as? Bool ?? true
        
        // Sync hardware pointer state on startup
        ScrollInverter.shared.updateHardwarePointerProperties(linear: self.disableMouseAcceleration, sensitivity: self.mousePointerSensitivity)
    }
}
