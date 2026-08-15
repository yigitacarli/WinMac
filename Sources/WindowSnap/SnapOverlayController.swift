import Cocoa
import SwiftUI

@MainActor
public final class SnapOverlayController {
    public static let shared = SnapOverlayController()
    
    private var panel: NSPanel?
    private var currentRect: NSRect = .zero
    private var isHiding = false
    
    private init() {}
    
    public func showPreview(for rect: NSRect) {
        if panel == nil {
            setupPanel()
        }
        
        guard let panel = panel else { return }
        isHiding = false
        
        if panel.isVisible && currentRect.equalTo(rect) && panel.alphaValue > 0.9 {
            return
        }
        
        self.currentRect = rect
        
        if panel.isVisible && panel.alphaValue > 0.05 {
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(rect, display: true)
                panel.animator().alphaValue = 1.0
            }
        } else {
            panel.setFrame(rect, display: true)
            panel.alphaValue = 0.0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.14
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1.0
            }
        }
    }
    
    public func hidePreview() {
        guard let panel = panel, panel.isVisible, !isHiding else { return }
        isHiding = true
        self.currentRect = .zero
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor [weak self] in
                guard let self = self, self.isHiding else { return }
                panel.orderOut(nil)
                self.isHiding = false
            }
        }
    }
    
    private func setupPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = NSWindow.Level(Int(CGWindowLevelForKey(.overlayWindow)))
        p.hasShadow = false
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        p.contentView = NSHostingView(rootView: PremiumSnapGhostView())
        self.panel = p
    }
}

// MARK: - Modern Snap Preview Ghost View

private struct PremiumSnapGhostView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))
            
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor.opacity(0.6), lineWidth: 1.5)
        }
        .padding(4)
    }
}
