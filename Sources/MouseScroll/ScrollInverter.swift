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
        
        // Mouse wheel tick -> invert
        let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let fixedDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let pointDeltaY = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -deltaY)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedDeltaY)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointDeltaY)
        
        return event
    }
}
