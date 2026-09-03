import Cocoa
import SwiftUI

@MainActor
public final class AltTabHUDController {
    public static let shared = AltTabHUDController()

    private var panel: NSPanel?
    private var outsideClickMonitor: Any?

    private init() {
        AltTabState.shared.onDismiss = { [weak self] in
            self?.hide()
        }
    }

    public func show() {
        if panel == nil {
            setupPanel()
        }
        guard let panel = panel else { return }

        AltTabState.shared.reloadWindows()
        AltTabState.shared.beginHoverSession()
        AltTabState.shared.isVisible = true

        let screen = SystemUtils.targetScreen(for: AppSettings.shared.displayMode)
        let screenFrame = screen.visibleFrame

        // Shrink-wrap the HUD to its content instead of always filling 85% of the screen;
        // a small strip reads faster and matches the original's compact footprint.
        let size = preferredSize(forScreen: screenFrame)
        let originX = screenFrame.midX - (size.width / 2.0)
        let originY = screenFrame.midY - (size.height / 2.0)

        panel.setFrame(NSRect(origin: NSPoint(x: originX, y: originY), size: size), display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1.0
        }

        startOutsideClickMonitoring()
    }

    public func hide(immediately: Bool = false) {
        stopOutsideClickMonitoring()
        guard let panel = panel, panel.isVisible else { return }

        if immediately {
            panel.alphaValue = 0.0
            panel.orderOut(nil)
            AltTabState.shared.isVisible = false
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor in
                panel.orderOut(nil)
                AltTabState.shared.isVisible = false
            }
        }
    }

    public func toggle() {
        if AltTabState.shared.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func preferredSize(forScreen screenFrame: NSRect) -> NSSize {
        let windows = AltTabState.shared.filteredWindows.count
        switch AppSettings.shared.switcherStyle {
        case .icons:
            let width = min(CGFloat(max(windows, 1)) * 96 + 56, screenFrame.width * 0.85)
            return NSSize(width: width, height: 176)
        case .list:
            return NSSize(
                width: 440,
                height: min(CGFloat(windows) * 42 + 36, min(screenFrame.height * 0.7, 420))
            )
        }
    }

    private func setupPanel() {
        let p = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        p.isOpaque = false
        p.backgroundColor = .clear
        // .popUpMenu, not .screenSaver: the original explicitly avoids screenSaver level
        // because it breaks drag & drop and overlays of other top-level utilities.
        p.level = .popUpMenu
        p.hasShadow = true
        p.isMovableByWindowBackground = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        p.contentView = NSHostingView(rootView: AltTabHUDView(state: AltTabState.shared))
        self.panel = p
    }

    /// Clicking anywhere outside the HUD dismisses without changing focus — mirrors AltTab's
    /// hideUi-on-outside-click. Global monitor observes but does not consume the event.
    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                Task { @MainActor in
                    AltTabState.shared.cancelSelection()
                }
            }
        }
    }

    private func stopOutsideClickMonitoring() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}

/// Borderless panels can't become key by default; allowing it lets SwiftUI controls inside the
/// HUD receive events while the nonactivating mask keeps focus with the user's apps.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
