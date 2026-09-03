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

    /// Invalidated on every scan so async thumbnail work from a previous session is dropped.
    private var scanToken = UUID()
    /// Cursor position when the switcher appeared; hover selection stays dead inside this
    /// radius so the tile under a resting cursor doesn't steal the selection (AltTab's 25px deadzone).
    private var hoverOrigin: CGPoint = .zero

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

    // MARK: - Scanning

    public func reloadWindows() {
        scanToken = UUID()
        self.windows = WindowEngine.shared.getWindows()
        self.searchText = ""
        self.selectedIndex = 0
    }

    // MARK: - Selection

    public func selectNext(wrapAllowed: Bool = true) { advance(by: 1, wrapAllowed: wrapAllowed) }
    public func selectPrevious(wrapAllowed: Bool = true) { advance(by: -1, wrapAllowed: wrapAllowed) }

    /// OS key-repeat holds Tab and wraps the selection every few ticks. Suppressing wrap for
    /// auto-repeat events pins the selection at the ends until the key is re-pressed — the
    /// behaviour AltTab implements via its KeyRepeatTimer.
    public func advance(by step: Int, wrapAllowed: Bool = true) {
        let count = filteredWindows.count
        guard count > 0 else { return }
        var next = selectedIndex + step
        if next >= count {
            next = wrapAllowed ? 0 : count - 1
        } else if next < 0 {
            next = wrapAllowed ? count - 1 : 0
        }
        selectedIndex = next
    }

    public func selectIndex(_ index: Int) {
        let count = filteredWindows.count
        if index >= 0 && index < count {
            selectedIndex = index
        }
    }

    // MARK: - Hover (deadzone-gated)

    public func beginHoverSession() {
        hoverOrigin = NSEvent.mouseLocation
    }

    public func shouldAcceptHoverSelection(at point: CGPoint = NSEvent.mouseLocation) -> Bool {
        guard AppSettings.shared.hoverSelectEnabled else { return false }
        let dx = point.x - hoverOrigin.x
        let dy = point.y - hoverOrigin.y
        return dx * dx + dy * dy > 26 * 26
    }

    // MARK: - Actions

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
        clampAfterRemoval()
    }

    public func quitCurrentApp() {
        guard let target = selectedWindow else { return }
        WindowEngine.shared.quitApp(target)
        windows.removeAll { $0.pid == target.pid }
        clampAfterRemoval()
    }

    private func clampAfterRemoval() {
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
