import Cocoa

public final class FootprintWindow: NSWindow {
    private var orderOutCanceled = false
    
    public init() {
        let initialRect = NSRect(x: 0, y: 0, width: 0, height: 0)
        super.init(contentRect: initialRect, styleMask: .titled, backing: .buffered, defer: false)
        
        self.title = "WinMac"
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
        
        // Windows Snap Assist görünümü: yarı saydam accent-mavi dolgu + parlak mavi kenarlık.
        let boxView = NSBox()
        boxView.boxType = .custom
        boxView.borderColor = NSColor(srgbRed: 0.29, green: 0.68, blue: 1.0, alpha: 0.95)
        boxView.borderWidth = 2.5
        boxView.cornerRadius = 8.0
        boxView.wantsLayer = true
        boxView.fillColor = NSColor(srgbRed: 0.0, green: 0.47, blue: 0.83, alpha: 0.28)

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
