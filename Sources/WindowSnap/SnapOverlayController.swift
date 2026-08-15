import Cocoa

@MainActor
public final class SnapOverlayController {
    public static let shared = SnapOverlayController()
    
    private var box: FootprintWindow?
    private var currentRect: NSRect = .zero
    
    private init() {}
    
    public func showPreview(for rect: NSRect, action: SnapAction = .maximize) {
        if box == nil {
            box = FootprintWindow()
        }
        
        guard let box = box else { return }
        
        if box.isVisible && currentRect.equalTo(rect) && box.alphaValue > 0.6 {
            return
        }
        
        self.currentRect = rect
        
        if box.isVisible && box.alphaValue > 0.05 {
            box.orderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                box.animator().setFrame(rect, display: true)
                box.animator().alphaValue = 0.8
            }
        } else {
            box.setFrame(rect, display: true)
            box.orderFront(nil)
        }
    }
    
    public func hidePreview() {
        guard let box = box, box.isVisible else { return }
        self.currentRect = .zero
        box.orderOut(nil)
    }
}
