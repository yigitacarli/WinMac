import CoreGraphics
import Foundation

public final class ScrollInverter: @unchecked Sendable {
    public static let shared = ScrollInverter()
    
    private init() {}
    
    public func handleScrollEvent(event: CGEvent) -> CGEvent? {
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        if isContinuous != 0 {
            // Touchpad / Trackpad gesture -> preserve natural scrolling
            return event
        }
        
        let defaults = UserDefaults.standard
        let invertV = defaults.object(forKey: "invertMouseWheel") as? Bool ?? true
        let invertH = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? true
        let speedMult = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        let shiftH = defaults.object(forKey: "shiftHorizontalScrollEnabled") as? Bool ?? true
        
        let flags = event.flags
        var deltaY = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
        var deltaX = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
        
        var fixedDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        var fixedDeltaX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        
        // Invert Vertical Scroll
        if invertV {
            deltaY = -deltaY
            fixedDeltaY = -fixedDeltaY
        }
        
        // Invert Horizontal Scroll
        if invertH {
            deltaX = -deltaX
            fixedDeltaX = -fixedDeltaX
        }
        
        // Apply Speed Multiplier
        if speedMult != 1.0 && speedMult > 0 {
            deltaY *= speedMult
            fixedDeltaY *= speedMult
            deltaX *= speedMult
            fixedDeltaX *= speedMult
        }
        
        // Shift + Wheel -> Horizontal Scroll
        if flags.contains(.maskShift) && shiftH && deltaY != 0 {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0.0)
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(deltaY))
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaY)
            return event
        }
        
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: Int64(deltaY))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: fixedDeltaY)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(deltaX))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaX)
        
        return event
    }
}
