import Foundation
import CoreGraphics

public final class ScrollWheelEventView {
    public let event: CGEvent
    
    public init(_ event: CGEvent) {
        assert(event.type == .scrollWheel)
        self.event = event
    }
    
    public var continuous: Bool {
        get { event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 }
        set { event.setIntegerValueField(.scrollWheelEventIsContinuous, value: newValue ? 1 : 0) }
    }
    
    public var deltaX: Int64 {
        get { event.getIntegerValueField(.scrollWheelEventDeltaAxis2) }
        set { event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: newValue) }
    }
    
    public var deltaXFixedPt: Double {
        get { event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2) }
        set { event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: newValue) }
    }
    
    public var deltaXPt: Double {
        get { event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2) }
        set { event.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: newValue) }
    }
    
    public var deltaY: Int64 {
        get { event.getIntegerValueField(.scrollWheelEventDeltaAxis1) }
        set { event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: newValue) }
    }
    
    public var deltaYFixedPt: Double {
        get { event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1) }
        set { event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: newValue) }
    }
    
    public var deltaYPt: Double {
        get { event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1) }
        set { event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: newValue) }
    }
    
    public func negate(vertically: Bool = false, horizontally: Bool = false) {
        if horizontally {
            deltaX = -deltaX
            deltaXFixedPt = -deltaXFixedPt
            deltaXPt = -deltaXPt
        }
        if vertically {
            deltaY = -deltaY
            deltaYFixedPt = -deltaYFixedPt
            deltaYPt = -deltaYPt
        }
    }
    
    public func scale(factorX: Double = 1.0, factorY: Double = 1.0) {
        if factorX != 1.0 {
            deltaX = Int64(Double(deltaX) * factorX)
            deltaXFixedPt = deltaXFixedPt * factorX
            deltaXPt = deltaXPt * factorX
        }
        if factorY != 1.0 {
            deltaY = Int64(Double(deltaY) * factorY)
            deltaYFixedPt = deltaYFixedPt * factorY
            deltaYPt = deltaYPt * factorY
        }
    }
}
