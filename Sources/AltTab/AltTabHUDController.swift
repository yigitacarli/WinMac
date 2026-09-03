import Cocoa
import SwiftUI

@MainActor
public final class AltTabHUDController {
    public static let shared = AltTabHUDController()

    private var panel: NSPanel?

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

        // Windows-style: a full-screen dimmed backdrop with the switcher box centred in it.
        let screen = SystemUtils.targetScreen(for: AppSettings.shared.displayMode)
        panel.setFrame(screen.frame, display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        // Force it above full-screen / borderless games and other overlays.
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.11
            panel.animator().alphaValue = 1.0
        }
    }

    public func hide(immediately: Bool = false) {
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

    private func setupPanel() {
        let p = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.isMovableByWindowBackground = false
        // Assistive-tech-high sits above the screen-saver level and most game overlays,
        // so the switcher is visible over borderless / full-screen games (exclusive
        // full-screen apps still capture the display — no overlay can draw over those).
        p.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)))
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        p.contentView = NSHostingView(rootView: AltTabHUDView(state: AltTabState.shared))
        self.panel = p
    }
}

/// Borderless panels can't become key by default; allowing it lets SwiftUI controls inside the
/// HUD receive events while the nonactivating mask keeps focus with the user's apps.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
