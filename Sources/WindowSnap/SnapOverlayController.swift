import Cocoa
import SwiftUI

@MainActor
public final class SnapOverlayController {
    public static let shared = SnapOverlayController()
    
    private var panel: NSPanel?
    private var currentRect: NSRect = .zero
    
    private init() {}
    
    public func showPreview(for rect: NSRect) {
        if panel == nil {
            setupPanel()
        }
        
        guard let panel = panel else { return }
        
        // If rect didn't change and already visible, do nothing
        if panel.isVisible && currentRect.equalTo(rect) {
            return
        }
        
        self.currentRect = rect
        panel.setFrame(rect, display: true, animate: panel.isVisible)
        
        if !panel.isVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().alphaValue = 1.0
            }
        }
    }
    
    public func hidePreview() {
        guard let panel = panel, panel.isVisible else { return }
        self.currentRect = .zero
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor in
                panel.orderOut(nil)
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
        p.level = .screenSaver
        p.hasShadow = false
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        p.contentView = NSHostingView(rootView: SnapGhostView())
        self.panel = p
    }
}

private struct SnapGhostView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.28), Color.cyan.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        }
        .padding(6)
        .shadow(color: Color.blue.opacity(0.4), radius: 16, y: 4)
    }
}
