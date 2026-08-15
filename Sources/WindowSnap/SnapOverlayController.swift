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

// MARK: - Rectangle FootprintWindow.swift Birebir Snap Preview

private struct PremiumSnapGhostView: View {
    var body: some View {
        ZStack {
            // Rectangle birebir: NSColor.selectedControlColor eşdeğeri
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.22))
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.accentColor.opacity(0.55), lineWidth: 1.5)
        }
        .padding(4)
    }
}
