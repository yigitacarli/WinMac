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
        var speedMult = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        let linesPerTick = defaults.object(forKey: "linesPerScrollTick") as? Int ?? 3
        
        let shiftH = defaults.object(forKey: "shiftHorizontalScrollEnabled") as? Bool ?? true
        let cmdZoom = defaults.object(forKey: "cmdZoomScrollEnabled") as? Bool ?? true
        let optFast = defaults.object(forKey: "optionFastScrollEnabled") as? Bool ?? true
        let ctrlSlow = defaults.object(forKey: "ctrlSlowScrollEnabled") as? Bool ?? true
        
        let flags = event.flags
        var deltaY = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
        var deltaX = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
        
        var fixedDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        var fixedDeltaX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        
        // 1. LinearMouse Pro: Cmd + Wheel -> Zoom In / Zoom Out
        if flags.contains(.maskCommand) && cmdZoom && deltaY != 0 {
            let zoomIn = deltaY > 0
            DispatchQueue.main.async {
                // Key 24 is '+' / '=', Key 27 is '-'
                SystemUtils.sendKeystroke(keyCode: zoomIn ? 24 : 27, flags: .maskCommand)
            }
            return nil
        }
        
        // 2. LinearMouse Pro: Option + Wheel -> 3x Fast Scroll
        if flags.contains(.maskAlternate) && optFast {
            speedMult *= 3.0
        }
        
        // 3. LinearMouse Pro: Control + Wheel -> 0.3x Slow Precision Scroll
        if flags.contains(.maskControl) && ctrlSlow {
            speedMult *= 0.3
        }
        
        // 4. Multiply with linesPerTick
        let lineFactor = Double(linesPerTick) / 3.0
        speedMult *= lineFactor
        
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
