import Cocoa
import SwiftUI

@MainActor
public final class SnapOverlayController {
    public static let shared = SnapOverlayController()
    
    private var panel: NSPanel?
    private var currentRect: NSRect = .zero
    private var currentAction: SnapAction = .maximize
    private var isHiding = false
    
    private init() {}
    
    public func showPreview(for rect: NSRect, action: SnapAction = .maximize) {
        if panel == nil {
            setupPanel()
        }
        
        guard let panel = panel else { return }
        isHiding = false
        self.currentAction = action
        
        if panel.isVisible && currentRect.equalTo(rect) && panel.alphaValue > 0.9 {
            return
        }
        
        self.currentRect = rect
        panel.contentView = NSHostingView(rootView: PremiumSnapGhostView(action: action))
        
        if panel.isVisible && panel.alphaValue > 0.05 {
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.14
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(rect, display: true)
                panel.animator().alphaValue = 1.0
            }
        } else {
            panel.setFrame(rect, display: true)
            panel.alphaValue = 0.0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
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
            context.duration = 0.12
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
        p.hasShadow = true
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        p.contentView = NSHostingView(rootView: PremiumSnapGhostView(action: .maximize))
        self.panel = p
    }
}

// MARK: - Premium Glass Snap Preview Ghost View

private struct SnapGhostBlurView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

private struct PremiumSnapGhostView: View {
    let action: SnapAction
    
    private var iconName: String {
        switch action {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .maximize: return "arrow.up.left.and.arrow.down.right"
        case .topLeftQuarter: return "rectangle.topthird.inset.filled"
        case .topRightQuarter: return "rectangle.topthird.inset.filled"
        case .bottomLeftQuarter: return "rectangle.bottomthird.inset.filled"
        case .bottomRightQuarter: return "rectangle.bottomthird.inset.filled"
        case .leftThird, .centerThird, .rightThird: return "rectangle.split.3x1"
        case .leftTwoThirds, .rightTwoThirds: return "rectangle.split.2x1"
        case .center: return "rectangle.center.inset.filled"
        default: return "macwindow"
        }
    }
    
    var body: some View {
        ZStack {
            // 1. Frosted Glass Backdrop
            SnapGhostBlurView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(0.85)
            
            // 2. Subtle Accent Tint
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
            
            // 3. Crisp Glass Stroke Border
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.accentColor.opacity(0.5),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            
            // 4. Centered Icon Badge
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color.accentColor.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(6)
    }
}
