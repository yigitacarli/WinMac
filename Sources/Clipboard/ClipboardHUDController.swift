import Cocoa
import SwiftUI

@MainActor
public final class ClipboardHUDController {
    public static let shared = ClipboardHUDController()
    
    private var panel: NSPanel?
    private var isVisible: Bool = false
    
    private init() {}
    
    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        if panel == nil {
            setupPanel()
        }
        
        guard let panel = panel else { return }
        
        let screen = SystemUtils.screenWithMouse()
        let screenFrame = screen.visibleFrame
        let mouseLocation = NSEvent.mouseLocation
        
        let panelWidth: CGFloat = 380
        let panelHeight: CGFloat = 460
        
        var originX = mouseLocation.x - (panelWidth / 2.0)
        var originY = mouseLocation.y - (panelHeight / 2.0)
        
        originX = max(screenFrame.minX + 20, min(originX, screenFrame.maxX - panelWidth - 20))
        originY = max(screenFrame.minY + 20, min(originY, screenFrame.maxY - panelHeight - 20))
        
        panel.setFrame(NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight), display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1.0
        }
        
        self.isVisible = true
    }
    
    public func hide() {
        guard let panel = panel, isVisible else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor in
                panel.orderOut(nil)
                self.isVisible = false
            }
        }
    }
    
    private func setupPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = .floating
        p.hasShadow = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let view = ClipboardHUDView(onSelect: { [weak self] item in
            self?.hide()
            ClipboardManager.shared.pasteItem(item)
        })
        
        p.contentView = NSHostingView(rootView: view)
        self.panel = p
    }
}
