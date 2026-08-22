import CoreGraphics
import Cocoa
import IOKit
import IOKit.hid

public final class ScrollInverter: @unchecked Sendable {
    public static let shared = ScrollInverter()
    
    private init() {}
    
    // MARK: - LinearMouse Scroll Wheel Transformer
    public func handleScrollEvent(event: CGEvent) -> CGEvent? {
        let view = ScrollWheelEventView(event)
        
        // LinearMouse rule: Trackpad continuous scrolls must never be inverted or altered
        if view.continuous {
            return event
        }
        
        let defaults = UserDefaults.standard
        let invertY = defaults.object(forKey: "invertMouseWheel") as? Bool ?? false
        let invertX = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? false
        let speed = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        let shiftHScroll = defaults.object(forKey: "shiftToHorizontalScroll") as? Bool ?? true
        
        let flags = event.flags
        
        // Shift + Wheel -> Horizontal Scroll
        if shiftHScroll && flags.contains(.maskShift) && !flags.contains(.maskCommand) && !flags.contains(.maskControl) {
            let originalY = view.deltaY
            let originalYPt = view.deltaYPt
            let originalYFixedPt = view.deltaYFixedPt
            
            if originalY != 0 {
                view.deltaX = originalY
                view.deltaXPt = originalYPt
                view.deltaXFixedPt = originalYFixedPt
                view.deltaY = 0
                view.deltaYPt = 0
                view.deltaYFixedPt = 0
            }
        }
        
        // Invert axes if enabled
        if invertY || invertX {
            view.negate(vertically: invertY, horizontally: invertX)
        }
        
        // Apply speed multiplier
        if speed != 1.0 && speed > 0.0 {
            view.scale(factorX: speed, factorY: speed)
        }
        
        return event
    }
    
    // MARK: - LinearMouse Hardware Pointer Engine (IOHID)
    public func updateHardwarePointerProperties(linear: Bool, sensitivity: Double) {
        // Base DPI is 400 at 1.0x sensitivity. Higher sensitivity = lower resolution value = faster cursor
        let targetResolution = max(10.0, min(1995.0, 400.0 / sensitivity))
        
        applyIOHIDSettings(
            disableAcceleration: linear,
            resolution: targetResolution,
            sensitivity: sensitivity
        )
    }
    
    public func applyPointerSpeedAndAcceleration() {
        let defaults = UserDefaults.standard
        let disableAccel = defaults.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        let sensitivity = defaults.object(forKey: "mousePointerSensitivity") as? Double ?? 1.0
        updateHardwarePointerProperties(linear: disableAccel, sensitivity: sensitivity)
    }
    
    private func applyIOHIDSettings(disableAcceleration: Bool, resolution: Double, sensitivity: Double) {
        typealias IOHIDEventSystemClientCreateType = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
        typealias IOHIDServiceClientSetPropertyType = @convention(c) (AnyObject, CFString, CFTypeRef) -> DarwinBoolean
        typealias IOHIDEventSystemClientCopyServicesType = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
        
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
            return
        }
        defer { dlclose(handle) }
        
        guard let createSym = dlsym(handle, "IOHIDEventSystemClientCreate"),
              let copyServicesSym = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
              let setPropSym = dlsym(handle, "IOHIDServiceClientSetProperty") else {
            return
        }
        
        let clientCreate = unsafeBitCast(createSym, to: IOHIDEventSystemClientCreateType.self)
        let copyServices = unsafeBitCast(copyServicesSym, to: IOHIDEventSystemClientCopyServicesType.self)
        let setProperty = unsafeBitCast(setPropSym, to: IOHIDServiceClientSetPropertyType.self)
        
        guard let clientObj = clientCreate(kCFAllocatorDefault)?.takeRetainedValue(),
              let servicesArray = copyServices(clientObj)?.takeRetainedValue() as? [AnyObject] else {
            return
        }
        
        for service in servicesArray {
            if disableAcceleration {
                // 1:1 Linear Acceleration
                let accelVal: Double = -1.0
                _ = setProperty(service, "HIDMouseAcceleration" as CFString, accelVal as CFNumber)
                _ = setProperty(service, "HIDPointerAcceleration" as CFString, accelVal as CFNumber)
                _ = setProperty(service, "HIDUseLinearScalingMouseAcceleration" as CFString, 1 as CFNumber)
                
                // 16.16 Fixed-Point DPI Resolution
                let fixedPointRes = Int32(resolution * 65536.0)
                _ = setProperty(service, "HIDPointerResolution" as CFString, fixedPointRes as CFNumber)
                _ = setProperty(service, "PointerResolution" as CFString, fixedPointRes as CFNumber)
            } else {
                // Restore macOS native curves
                let defaultAccel: Double = 0.6875
                _ = setProperty(service, "HIDMouseAcceleration" as CFString, defaultAccel as CFNumber)
                _ = setProperty(service, "HIDPointerAcceleration" as CFString, defaultAccel as CFNumber)
                _ = setProperty(service, "HIDUseLinearScalingMouseAcceleration" as CFString, 0 as CFNumber)
                
                let defaultFixedPointRes = Int32(400.0 * 65536.0)
                _ = setProperty(service, "HIDPointerResolution" as CFString, defaultFixedPointRes as CFNumber)
            }
        }
        
        // Update user defaults tracking speed dynamically so system stays in sync
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = "/usr/bin/defaults"
            let scaling = disableAcceleration ? (sensitivity * 1.5) : (sensitivity * 1.5)
            task.arguments = ["write", "-g", "com.apple.mouse.scaling", String(format: "%.2f", scaling)]
            try? task.run()
        }
    }
}
