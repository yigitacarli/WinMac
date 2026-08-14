import Cocoa
import SwiftUI

@MainActor
public final class AltTabHUDController {
    public static let shared = AltTabHUDController()
    
    private var panel: NSPanel?
    private var localKeyMonitor: Any?
    
    private init() {
        AltTabState.shared.onDismiss = { [weak self] in
            self?.hide()
        }
    }
    
    public func show() {
        if panel == nil {
            setupPanel()
        }
        
        guard let panel = panel else { return }
        
        // Scan windows
        AltTabState.shared.reloadWindows()
        AltTabState.shared.isVisible = true
        
        // Center on target screen
        let screen = SystemUtils.targetScreen(for: AppSettings.shared.displayMode)
        let screenFrame = screen.visibleFrame
        
        let panelWidth: CGFloat = min(screenFrame.width * 0.85, 840)
        let panelHeight: CGFloat = min(screenFrame.height * 0.7, 520)
        
        let originX = screenFrame.midX - (panelWidth / 2.0)
        let originY = screenFrame.midY - (panelHeight / 2.0)
        
        panel.setFrame(NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight), display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1.0
        }
        
        startLocalKeyMonitoring()
    }
    
    public func hide(immediately: Bool = false) {
        stopLocalKeyMonitoring()
        guard let panel = panel, panel.isVisible else { return }
        
        if immediately {
            panel.alphaValue = 0.0
            panel.orderOut(nil)
            AltTabState.shared.isVisible = false
            return
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            Task { @MainActor in
                panel.orderOut(nil)
                AltTabState.shared.isVisible = false
            }
        }
    }
    
    public func toggle() {
        if AltTabState.shared.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    private func setupPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = .screenSaver
        p.hasShadow = false
        p.isMovableByWindowBackground = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        let hosting = NSHostingView(rootView: AltTabHUDView(state: AltTabState.shared))
        p.contentView = hosting
        
        self.panel = p
    }
    
    private func startLocalKeyMonitoring() {
        stopLocalKeyMonitoring()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self, AltTabState.shared.isVisible else { return event }
            return self.handleKeyEvent(event)
        }
    }
    
    private func stopLocalKeyMonitoring() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        if event.type == .keyDown {
            let keyCode = event.keyCode
            
            // Tab key
            if keyCode == 48 {
                if event.modifierFlags.contains(.shift) {
                    AltTabState.shared.selectPrevious()
                } else {
                    AltTabState.shared.selectNext()
                }
                return nil
            }
            
            // Right / Down Arrow
            if keyCode == 124 || keyCode == 125 {
                AltTabState.shared.selectNext()
                return nil
            }
            
            // Left / Up Arrow
            if keyCode == 123 || keyCode == 126 {
                AltTabState.shared.selectPrevious()
                return nil
            }
            
            // Enter key
            if keyCode == 36 {
                AltTabState.shared.confirmSelection()
                return nil
            }
            
            // Escape key
            if keyCode == 53 {
                AltTabState.shared.dismiss()
                return nil
            }
            
            // Character actions
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                if chars == "w" {
                    AltTabState.shared.closeCurrentWindow()
                    return nil
                }
                if chars == "q" {
                    AltTabState.shared.quitCurrentApp()
                    return nil
                }
                if chars == "f" {
                    AltTabState.shared.maximizeCurrentWindow()
                    return nil
                }
                if chars == "m" {
                    AltTabState.shared.minimizeCurrentWindow()
                    return nil
                }
                
                // Search typing
                if AppSettings.shared.searchFilterEnabled && !chars.isEmpty && chars.count == 1 {
                    let scalar = chars.unicodeScalars.first
                    if let scalar = scalar, CharacterSet.alphanumerics.contains(scalar) {
                        AltTabState.shared.searchText.append(chars)
                        return nil
                    }
                }
            }
            
            // Backspace for search
            if keyCode == 51 && !AltTabState.shared.searchText.isEmpty {
                AltTabState.shared.searchText.removeLast()
                return nil
            }
        }
        
        return event
    }
}
