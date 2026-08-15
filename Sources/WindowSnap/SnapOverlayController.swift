import Cocoa

@MainActor
public final class SnapOverlayController {
    public static let shared = SnapOverlayController()
    
    private var window: NSWindow?
    private var box: NSBox?
    private var currentRect: NSRect = .zero
    
    private init() {}
    
    public func showPreview(for rect: NSRect, action: SnapAction = .maximize) {
        if window == nil {
            setupWindow()
        }
        
        guard let window = window else { return }
        
        if window.isVisible && currentRect.equalTo(rect) && window.alphaValue > 0.9 {
            return
        }
        
        self.currentRect = rect
        
        if window.isVisible && window.alphaValue > 0.05 {
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(rect, display: true)
                window.animator().alphaValue = 1.0
            }
        } else {
            window.setFrame(rect, display: true)
            window.alphaValue = 0.0
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1.0
            }
        }
    }
    
    public func hidePreview() {
        guard let window = window, window.isVisible else { return }
        self.currentRect = .zero
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor [weak self] in
                guard let self = self, self.currentRect == .zero else { return }
                window.orderOut(nil)
            }
        }
    }
    
    private func setupWindow() {
        let w = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        w.isOpaque = false
        w.backgroundColor = .clear
        w.level = NSWindow.Level(Int(CGWindowLevelForKey(.overlayWindow)))
        w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        
        // Exact Rectangle NSBox Theme (Minimalist Translucent Frame)
        let b = NSBox()
        b.boxType = .custom
        b.fillColor = NSColor.windowFrameTextColor.withAlphaComponent(0.2)
        b.borderColor = NSColor.windowFrameTextColor.withAlphaComponent(0.4)
        b.borderWidth = 1.0
        b.cornerRadius = 6.0
        
        w.contentView = b
        self.box = b
        self.window = w
    }
}
