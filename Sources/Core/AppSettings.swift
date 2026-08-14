import Foundation
import SwiftUI
import Combine

public enum SwitcherStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case thumbnails = "thumbnails"
    case icons = "icons"
    case titles = "titles"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .thumbnails: return "Küçük Resimler (Thumbnails)"
        case .icons: return "Uygulama Simgeleri (Icons)"
        case .titles: return "Kompakt Liste (Titles)"
        }
    }
}

public enum SwitcherDisplayMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case cursorDisplay = "cursorDisplay"
    case activeAppDisplay = "activeAppDisplay"
    case allDisplays = "allDisplays"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .cursorDisplay: return "Fare İmlecinin Olduğu Ekran"
        case .activeAppDisplay: return "Aktif Pencerenin Olduğu Ekran"
        case .allDisplays: return "Tüm Ekranlar"
        }
    }
}

public enum AltTabShortcut: String, CaseIterable, Identifiable, Codable, Sendable {
    case optionTab = "Option + Tab (Alt + Tab)"
    case cmdTab = "Command + Tab"
    case ctrlTab = "Control + Tab"
    
    public var id: String { rawValue }
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
    @Published public var smoothScrollEnabled: Bool {
        didSet { defaults.set(smoothScrollEnabled, forKey: "smoothScrollEnabled") }
    }
    @Published public var disableMouseAcceleration: Bool {
        didSet { defaults.set(disableMouseAcceleration, forKey: "disableMouseAcceleration") }
    }
    @Published public var scrollSpeedMultiplier: Double {
        didSet { defaults.set(scrollSpeedMultiplier, forKey: "scrollSpeedMultiplier") }
    }
    @Published public var linesPerScrollTick: Int {
        didSet { defaults.set(linesPerScrollTick, forKey: "linesPerScrollTick") }
    }
    @Published public var shiftHorizontalScrollEnabled: Bool {
        didSet { defaults.set(shiftHorizontalScrollEnabled, forKey: "shiftHorizontalScrollEnabled") }
    }
    @Published public var cmdZoomScrollEnabled: Bool {
        didSet { defaults.set(cmdZoomScrollEnabled, forKey: "cmdZoomScrollEnabled") }
    }
    @Published public var optionFastScrollEnabled: Bool {
        didSet { defaults.set(optionFastScrollEnabled, forKey: "optionFastScrollEnabled") }
    }
    @Published public var ctrlSlowScrollEnabled: Bool {
        didSet { defaults.set(ctrlSlowScrollEnabled, forKey: "ctrlSlowScrollEnabled") }
    }
    
    // MARK: - Keyboard & Muscle Memory Settings
    @Published public var ctrlToCmdRemapEnabled: Bool {
        didSet { defaults.set(ctrlToCmdRemapEnabled, forKey: "ctrlToCmdRemapEnabled") }
    }
    @Published public var excludedAppsForCtrl: [String] {
        didSet { defaults.set(excludedAppsForCtrl, forKey: "excludedAppsForCtrl") }
    }
    
    // MARK: - Finder Settings
    @Published public var finderEnterToOpen: Bool {
        didSet { defaults.set(finderEnterToOpen, forKey: "finderEnterToOpen") }
    }
    @Published public var finderF2ToRename: Bool {
        didSet { defaults.set(finderF2ToRename, forKey: "finderF2ToRename") }
    }
    @Published public var finderDeleteToTrash: Bool {
        didSet { defaults.set(finderDeleteToTrash, forKey: "finderDeleteToTrash") }
    }
    
    // MARK: - Clipboard History (Win + V)
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
        
        self.altTabEnabled = defaults.object(forKey: "altTabEnabled") as? Bool ?? true
        
        let styleStr = defaults.string(forKey: "switcherStyle") ?? SwitcherStyle.thumbnails.rawValue
        self.switcherStyle = SwitcherStyle(rawValue: styleStr) ?? .thumbnails
        
        let shortcutStr = defaults.string(forKey: "switcherShortcut") ?? AltTabShortcut.optionTab.rawValue
        self.switcherShortcut = AltTabShortcut(rawValue: shortcutStr) ?? .optionTab
        
        let dispStr = defaults.string(forKey: "displayMode") ?? SwitcherDisplayMode.cursorDisplay.rawValue
        self.displayMode = SwitcherDisplayMode(rawValue: dispStr) ?? .cursorDisplay
        
        self.searchFilterEnabled = defaults.object(forKey: "searchFilterEnabled") as? Bool ?? true
        self.hideHiddenApps = defaults.object(forKey: "hideHiddenApps") as? Bool ?? false
        self.itemSize = defaults.object(forKey: "itemSize") as? Double ?? 1.0
        
        self.invertMouseWheel = defaults.object(forKey: "invertMouseWheel") as? Bool ?? true
        self.invertHorizontalScroll = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? true
        self.smoothScrollEnabled = defaults.object(forKey: "smoothScrollEnabled") as? Bool ?? true
        self.disableMouseAcceleration = defaults.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        self.scrollSpeedMultiplier = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        self.linesPerScrollTick = defaults.object(forKey: "linesPerScrollTick") as? Int ?? 3
        self.shiftHorizontalScrollEnabled = defaults.object(forKey: "shiftHorizontalScrollEnabled") as? Bool ?? true
        self.cmdZoomScrollEnabled = defaults.object(forKey: "cmdZoomScrollEnabled") as? Bool ?? true
        self.optionFastScrollEnabled = defaults.object(forKey: "optionFastScrollEnabled") as? Bool ?? true
        self.ctrlSlowScrollEnabled = defaults.object(forKey: "ctrlSlowScrollEnabled") as? Bool ?? true
        
        self.ctrlToCmdRemapEnabled = defaults.object(forKey: "ctrlToCmdRemapEnabled") as? Bool ?? true
        self.excludedAppsForCtrl = defaults.stringArray(forKey: "excludedAppsForCtrl") ?? [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "net.kovidgoyal.kitty",
            "com.github.wez.wezterm",
            "com.microsoft.VSCode",
            "com.jetbrains.intellij"
        ]
        
        self.finderEnterToOpen = defaults.object(forKey: "finderEnterToOpen") as? Bool ?? true
        self.finderF2ToRename = defaults.object(forKey: "finderF2ToRename") as? Bool ?? true
        self.finderDeleteToTrash = defaults.object(forKey: "finderDeleteToTrash") as? Bool ?? true
        
        self.clipboardHistoryEnabled = defaults.object(forKey: "clipboardHistoryEnabled") as? Bool ?? true
        self.maxClipboardItems = defaults.object(forKey: "maxClipboardItems") as? Int ?? 50
        
        self.aeroSnapEnabled = defaults.object(forKey: "aeroSnapEnabled") as? Bool ?? true
        self.dragToSnapEnabled = defaults.object(forKey: "dragToSnapEnabled") as? Bool ?? true
        self.snapShortcutsEnabled = defaults.object(forKey: "snapShortcutsEnabled") as? Bool ?? true
        self.cycleRepeatedShortcuts = defaults.object(forKey: "cycleRepeatedShortcuts") as? Bool ?? true
        self.snapWindowGaps = defaults.object(forKey: "snapWindowGaps") as? Double ?? 0.0
        
        self.winLToLockEnabled = defaults.object(forKey: "winLToLockEnabled") as? Bool ?? true
        self.ctrlShiftEscTaskManager = defaults.object(forKey: "ctrlShiftEscTaskManager") as? Bool ?? true
    }
}
