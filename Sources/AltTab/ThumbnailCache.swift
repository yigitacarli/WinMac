import Cocoa
import CoreGraphics
import Foundation

public final class ThumbnailCache: @unchecked Sendable {
    public static let shared = ThumbnailCache()
    
    private let cache = NSCache<NSNumber, NSImage>()
    
    private init() {
        cache.countLimit = 100
    }
    
    public func thumbnail(for windowID: CGWindowID, bounds: CGRect) -> NSImage? {
        if let cached = cache.object(forKey: NSNumber(value: windowID)) {
            return cached
        }
        
        if let image = generateThumbnail(windowID: windowID, bounds: bounds) {
            cache.setObject(image, forKey: NSNumber(value: windowID))
            return image
        }
        
        return nil
    }
    
    /// Resolves the real CGWindowID for an Accessibility window (AX uses bottom-left origin,
    /// CGWindowList top-left) and captures its live thumbnail. Returns nil for minimized/offscreen windows.
    public func thumbnail(forPid pid: pid_t, axBounds: CGRect) -> NSImage? {
        guard axBounds.width > 1, axBounds.height > 1 else { return nil }
        
        let primaryMaxY = NSScreen.screens.first?.frame.maxY ?? 0
        let target = CGRect(
            x: axBounds.minX,
            y: primaryMaxY - axBounds.maxY,
            width: axBounds.width,
            height: axBounds.height
        )
        
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        var bestID: CGWindowID?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        
        for info in list {
            let ownerPid = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
            guard ownerPid == pid else { continue }
            let layer = info[kCGWindowLayer as String] as? Int ?? -1
            guard layer == 0 else { continue }
            
            guard let b = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let w = b["Width"], let h = b["Height"],
                  let x = b["X"], let y = b["Y"] else { continue }
            let frame = CGRect(x: x, y: y, width: w, height: h)
            
            let distance = abs(frame.midX - target.midX) + abs(frame.midY - target.midY) +
                abs(frame.width - target.width) + abs(frame.height - target.height)
            if distance < bestDistance {
                bestDistance = distance
                bestID = info[kCGWindowNumber as String] as? CGWindowID
            }
        }
        
        // Tolerate small coordinate drift between AX and CGWindowList
        guard let windowID = bestID, bestDistance < 120 else { return nil }
        return thumbnail(for: windowID, bounds: target)
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
    
    public func generateThumbnail(windowID: CGWindowID, bounds: CGRect) -> NSImage? {
        let imageOption: CGWindowImageOption = [.boundsIgnoreFraming, .bestResolution]
        let listOption: CGWindowListOption = [.optionIncludingWindow]
        
        guard let cgImage = CGWindowListCreateImage(.null, listOption, windowID, imageOption) else {
            return nil
        }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 0, height > 0 else { return nil }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: width / 2.0, height: height / 2.0))
        return nsImage
    }
}
