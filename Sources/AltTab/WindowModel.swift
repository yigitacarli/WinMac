import Cocoa
import Foundation
import CoreGraphics

public struct WindowModel: Identifiable, Equatable {
    public let id: CGWindowID
    public let windowID: CGWindowID
    public let pid: pid_t
    public let appName: String
    public let bundleId: String?
    public let appIcon: NSImage?
    public var title: String
    public let bounds: CGRect
    public var isMinimized: Bool
    public var isHidden: Bool

    public init(
        id: CGWindowID,
        pid: pid_t,
        appName: String,
        bundleId: String?,
        appIcon: NSImage?,
        title: String,
        bounds: CGRect,
        isMinimized: Bool = false,
        isHidden: Bool = false
    ) {
        self.id = id
        self.windowID = id
        self.pid = pid
        self.appName = appName
        self.bundleId = bundleId
        self.appIcon = appIcon
        self.title = title.isEmpty ? appName : title
        self.bounds = bounds
        self.isMinimized = isMinimized
        self.isHidden = isHidden
    }
    
    public static func == (lhs: WindowModel, rhs: WindowModel) -> Bool {
        return lhs.id == rhs.id
    }
}
