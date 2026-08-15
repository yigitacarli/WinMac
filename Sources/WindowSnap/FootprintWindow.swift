import Cocoa

public final class FootprintWindow: NSWindow {
    private var orderOutCanceled = false
    
    public init() {
        let initialRect = NSRect(x: 0, y: 0, width: 0, height: 0)
        super.init(contentRect: initialRect, styleMask: .titled, backing: .buffered, defer: false)
        
        self.title = "Rectangle"
        self.isOpaque = false
        self.level = .modalPanel
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        self.alphaValue = 0.0
        
        self.styleMask.insert(.fullSizeContentView)
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.collectionBehavior.insert([.transient, .canJoinAllSpaces, .fullScreenAuxiliary])
        self.ignoresMouseEvents = true
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.toolbarButton)?.isHidden = true
        
        let boxView = NSBox()
        boxView.boxType = .custom
        boxView.borderColor = .lightGray
        boxView.borderWidth = 2.0
        boxView.cornerRadius = 10.0
        boxView.wantsLayer = true
        boxView.fillColor = NSColor.black.withAlphaComponent(0.25)
        
        self.contentView = boxView
    }
    
    public override func orderFront(_ sender: Any?) {
        self.orderOutCanceled = true
        super.orderFront(sender)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 0.8
        }
    }
    
    public override func orderOut(_ sender: Any?) {
        self.orderOutCanceled = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor [weak self] in
                self?.performDismissal()
            }
        }
    }
    
    private func performDismissal() {
        if !self.orderOutCanceled {
            super.orderOut(nil)
        }
    }
}
