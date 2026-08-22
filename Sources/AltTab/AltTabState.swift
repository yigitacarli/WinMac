import SwiftUI
import Combine

@MainActor
public final class AltTabState: ObservableObject {
    public static let shared = AltTabState()
    
    @Published public var windows: [WindowModel] = []
    @Published public var selectedIndex: Int = 0
    @Published public var searchText: String = ""
    @Published public var isVisible: Bool = false
    
    public var onDismiss: (@Sendable @MainActor () -> Void)?
    
    private init() {}
    
    public var filteredWindows: [WindowModel] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return windows
        }
        let query = searchText.lowercased()
        return windows.filter {
            $0.appName.lowercased().contains(query) ||
            $0.title.lowercased().contains(query)
        }
    }
    
    public var selectedWindow: WindowModel? {
        let list = filteredWindows
        guard !list.isEmpty, selectedIndex >= 0, selectedIndex < list.count else {
            return nil
        }
        return list[selectedIndex]
    }
    
    public func reloadWindows() {
        let scanned = WindowEngine.shared.getWindows()
        self.windows = scanned
        self.searchText = ""
        // Index 0 = currently focused window; the caller advances with selectNext()
        self.selectedIndex = 0
    }
    
    public func selectNext() {
        let count = filteredWindows.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
    }
    
    public func selectPrevious() {
        let count = filteredWindows.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
    }
    
    public func selectIndex(_ index: Int) {
        let count = filteredWindows.count
        if index >= 0 && index < count {
            selectedIndex = index
        }
    }
    
    public func confirmSelection() {
        let target = selectedWindow
        dismiss()
        if let target = target {
            WindowEngine.shared.focusWindow(target)
        }
    }
    
    public func dismiss() {
        self.isVisible = false
        self.searchText = ""
        onDismiss?()
    }
    
    public func closeCurrentWindow() {
        guard let target = selectedWindow else { return }
        WindowEngine.shared.closeWindow(target)
        windows.removeAll { $0.id == target.id }
        let count = filteredWindows.count
        if count == 0 {
            dismiss()
        } else {
            selectedIndex = min(selectedIndex, count - 1)
        }
    }
    
    public func quitCurrentApp() {
        guard let target = selectedWindow else { return }
        WindowEngine.shared.quitApp(target)
        windows.removeAll { $0.pid == target.pid }
        let count = filteredWindows.count
        if count == 0 {
            dismiss()
        } else {
            selectedIndex = min(selectedIndex, count - 1)
        }
    }
    
    public func minimizeCurrentWindow() {
        guard let target = selectedWindow else { return }
        WindowEngine.shared.minimizeWindow(target)
    }
    
    public func showSwitcher() {
        AltTabHUDController.shared.show()
    }
    
    public func cancelSelection() {
        dismiss()
    }
    
    public func closeSelectedWindow() {
        closeCurrentWindow()
    }
    
    public func quitSelectedApp() {
        quitCurrentApp()
    }
    
    public func maximizeCurrentWindow() {
        guard let target = selectedWindow else { return }
        WindowEngine.shared.maximizeWindow(target)
        confirmSelection()
    }
}
