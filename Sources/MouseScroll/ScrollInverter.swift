import CoreGraphics
import Foundation
import Cocoa

public final class ScrollInverter: @unchecked Sendable {
    public static let shared = ScrollInverter()
    
    private var lastZoomTime: TimeInterval = 0
    private var mouseAccelerationApplied: Bool?
    private var mouseScalingApplied: Double?
    
    private init() {}
    
    public func handleScrollEvent(event: CGEvent) -> CGEvent? {
        let defaults = UserDefaults.standard
        let invertV = defaults.object(forKey: "invertMouseWheel") as? Bool ?? true
        let invertH = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? true
        var speedMult = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        let linesPerTick = defaults.object(forKey: "linesPerScrollTick") as? Int ?? 3
        
        let shiftH = defaults.object(forKey: "shiftHorizontalScrollEnabled") as? Bool ?? true
        let cmdZoom = defaults.object(forKey: "cmdZoomScrollEnabled") as? Bool ?? true
        let optFast = defaults.object(forKey: "optionFastScrollEnabled") as? Bool ?? true
        let ctrlSlow = defaults.object(forKey: "ctrlSlowScrollEnabled") as? Bool ?? true
        let linearAccel = defaults.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        let sensitivity = defaults.object(forKey: "mousePointerSensitivity") as? Double ?? 1.0
        
        // Handle mouse acceleration and scaling
        applyMouseSettings(linear: linearAccel, sensitivity: sensitivity)
        
        let flags = event.flags
        var deltaY = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
        var deltaX = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
        
        var pointDeltaY = Double(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1))
        var pointDeltaX = Double(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2))
        
        var fixedDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        var fixedDeltaX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        
        if pointDeltaY == 0 && deltaY != 0 {
            pointDeltaY = deltaY * 10.0
        }
        if pointDeltaX == 0 && deltaX != 0 {
            pointDeltaX = deltaX * 10.0
        }
        if fixedDeltaY == 0 && deltaY != 0 {
            fixedDeltaY = deltaY * 10.0
        }
        if fixedDeltaX == 0 && deltaX != 0 {
            fixedDeltaX = deltaX * 10.0
        }
        
        // 1. Cmd + Wheel -> Zoom In / Zoom Out
        if flags.contains(.maskCommand) && cmdZoom && (deltaY != 0 || pointDeltaY != 0) {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastZoomTime > 0.08 {
                lastZoomTime = now
                let isZoomIn = (deltaY != 0 ? deltaY > 0 : pointDeltaY > 0)
                let zoomIn = invertV ? !isZoomIn : isZoomIn
                DispatchQueue.main.async {
                    SystemUtils.sendKeystroke(keyCode: zoomIn ? 24 : 27, flags: .maskCommand)
                }
            }
            return nil
        }
        
        // 2. Option + Wheel -> 3x Fast Scroll
        if flags.contains(.maskAlternate) && optFast {
            speedMult *= 3.0
        }
        
        // 3. Control + Wheel -> 0.3x Slow Precision Scroll
        if flags.contains(.maskControl) && ctrlSlow {
            speedMult *= 0.3
        }
        
        // 4. Lines per tick factor
        let lineFactor = Double(linesPerTick) / 3.0
        speedMult *= lineFactor
        
        // Invert Vertical Scroll
        if invertV {
            deltaY = -deltaY
            pointDeltaY = -pointDeltaY
            fixedDeltaY = -fixedDeltaY
        }
        
        // Invert Horizontal Scroll
        if invertH {
            deltaX = -deltaX
            pointDeltaX = -pointDeltaX
            fixedDeltaX = -fixedDeltaX
        }
        
        // Apply Speed Multiplier
        if speedMult != 1.0 && speedMult > 0 {
            deltaY *= speedMult
            pointDeltaY *= speedMult
            fixedDeltaY *= speedMult
            deltaX *= speedMult
            pointDeltaX *= speedMult
            fixedDeltaX *= speedMult
        }
        
        // Shift + Wheel -> Horizontal Scroll
        if flags.contains(.maskShift) && shiftH && (deltaY != 0 || pointDeltaY != 0) {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0.0)
            
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(deltaY))
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: Int64(pointDeltaY))
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaY)
            return event
        }
        
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: Int64(deltaY))
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: Int64(pointDeltaY))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: fixedDeltaY)
        
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(deltaX))
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: Int64(pointDeltaX))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaX)
        
        return event
    }
    
    public func handlePointerEvent(event: CGEvent) -> CGEvent? {
        let sensitivity = UserDefaults.standard.object(forKey: "mousePointerSensitivity") as? Double ?? 1.0
        guard sensitivity != 1.0 && sensitivity > 0 else { return event }
        
        var deltaX = Double(event.getIntegerValueField(.mouseEventDeltaX))
        var deltaY = Double(event.getIntegerValueField(.mouseEventDeltaY))
        
        deltaX *= sensitivity
        deltaY *= sensitivity
        
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY))
        
        return event
    }
    
    public func applyMouseSettings(linear: Bool, sensitivity: Double) {
        guard mouseAccelerationApplied != linear || mouseScalingApplied != sensitivity else { return }
        mouseAccelerationApplied = linear
        mouseScalingApplied = sensitivity
        
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = "/usr/bin/defaults"
            let scaleVal = linear ? "-1" : String(format: "%.2f", sensitivity * 1.5)
            task.arguments = ["write", ".GlobalPreferences", "com.apple.mouse.scaling", scaleVal]
            try? task.run()
        }
    }
}
