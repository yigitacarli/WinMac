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
