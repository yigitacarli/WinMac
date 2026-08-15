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
        
        if panel.isVisible && currentRect.equalTo(rect) {
            return
        }
        
        self.currentRect = rect
        
        if panel.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(rect, display: true)
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
        p.level = .floating
        p.hasShadow = false
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        p.contentView = NSHostingView(rootView: PremiumSnapGhostView())
        self.panel = p
    }
}

// MARK: - Rectangle Pro / Native macOS Sequoia Translucent Frosted Glass Ghost View

private struct PremiumSnapGhostView: View {
    var body: some View {
        ZStack {
            // Frosted backdrop
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.20))
                .background(
                    VisualEffectBlur(material: .fullScreenUI, blendingMode: .withinWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )
            
            // Subtle translucent fill
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
            
            // Crisp refined hairline border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.40),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .padding(8)
        .shadow(color: Color.black.opacity(0.35), radius: 24, y: 6)
    }
}
