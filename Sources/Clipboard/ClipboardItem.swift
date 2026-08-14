import Foundation
import Cocoa

public struct ClipboardItem: Identifiable, Equatable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public var isPinned: Bool
    
    public init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
    }
    
    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.content == rhs.content
    }
}
