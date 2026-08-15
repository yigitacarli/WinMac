import CoreGraphics
import Foundation
import Cocoa
import IOKit

public final class ScrollInverter: @unchecked Sendable {
    public static let shared = ScrollInverter()
    
    private var lastZoomTime: TimeInterval = 0
    private var lastLinearAccel: Bool?
    private var lastPointerSensitivity: Double?
    
    // MARK: - IOHID Dynamic Function Pointers (LinearMouse Architecture)
    private typealias IOHIDEventSystemClientCreateFunc = @convention(c) (CFAllocator?) -> UnsafeMutableRawPointer?
    private typealias IOHIDEventSystemClientSetPropertyFunc = @convention(c) (UnsafeMutableRawPointer, CFString, CFTypeRef) -> Bool
    private typealias IOHIDEventSystemClientCopyServicesFunc = @convention(c) (UnsafeMutableRawPointer) -> CFArray?
    private typealias IOHIDServiceClientSetPropertyFunc = @convention(c) (UnsafeMutableRawPointer, CFString, CFTypeRef) -> Bool
    
    private var iohidHandle: UnsafeMutableRawPointer?
    private var iohidCreate: IOHIDEventSystemClientCreateFunc?
    private var iohidClientSetProp: IOHIDEventSystemClientSetPropertyFunc?
    private var iohidCopyServices: IOHIDEventSystemClientCopyServicesFunc?
    private var iohidServiceSetProp: IOHIDServiceClientSetPropertyFunc?
    
    private init() {
        setupIOHID()
    }
    
    private func setupIOHID() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        self.iohidHandle = handle
        
        if let createSym = dlsym(handle, "IOHIDEventSystemClientCreate") {
            self.iohidCreate = unsafeBitCast(createSym, to: IOHIDEventSystemClientCreateFunc.self)
        }
        if let setPropSym = dlsym(handle, "IOHIDEventSystemClientSetProperty") {
            self.iohidClientSetProp = unsafeBitCast(setPropSym, to: IOHIDEventSystemClientSetPropertyFunc.self)
        }
        if let copyServicesSym = dlsym(handle, "IOHIDEventSystemClientCopyServices") {
            self.iohidCopyServices = unsafeBitCast(copyServicesSym, to: IOHIDEventSystemClientCopyServicesFunc.self)
        }
        if let serviceSetPropSym = dlsym(handle, "IOHIDServiceClientSetProperty") {
            self.iohidServiceSetProp = unsafeBitCast(serviceSetPropSym, to: IOHIDServiceClientSetPropertyFunc.self)
        }
    }
    
    // MARK: - Scroll Wheel Event Processing (LinearMouse Transformer Pipeline)
    public func handleScrollEvent(event: CGEvent) -> CGEvent? {
        let defaults = UserDefaults.standard
        let invertV = defaults.object(forKey: "invertMouseWheel") as? Bool ?? true
        let invertH = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? true
        var speedMult = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        
        let shiftH = defaults.object(forKey: "shiftHorizontalScrollEnabled") as? Bool ?? true
        let cmdZoom = defaults.object(forKey: "cmdZoomScrollEnabled") as? Bool ?? true
        let optFast = defaults.object(forKey: "optionFastScrollEnabled") as? Bool ?? true
        let ctrlSlow = defaults.object(forKey: "ctrlSlowScrollEnabled") as? Bool ?? true
        let linearAccel = defaults.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        let sensitivity = defaults.object(forKey: "mousePointerSensitivity") as? Double ?? 1.0
        
        // LinearMouse LinearScrolling.swift birebir: Trackpad olaylarına dokunma
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        if isContinuous {
            // Bu bir trackpad/Magic Mouse jesti — müdahale etme, olduğu gibi geçir
            return event
        }
        
        // Sync hardware pointer acceleration and sensitivity in real time
        updateHardwarePointerProperties(linear: linearAccel, sensitivity: sensitivity)
        
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
        
        // 1. Cmd + Wheel -> Zoom In / Zoom Out (LinearMouse Keystroke Synthesis)
        if flags.contains(.maskCommand) && cmdZoom && (deltaY != 0 || pointDeltaY != 0) {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastZoomTime > 0.07 {
                lastZoomTime = now
                let isUp = (deltaY != 0 ? deltaY > 0 : pointDeltaY > 0)
                let zoomIn = invertV ? !isUp : isUp
                
                // Key 24 is '+ / =', Key 27 is '-'
                let keyCode: CGKeyCode = zoomIn ? 24 : 27
                let source = CGEventSource(stateID: .hidSystemState)
                if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
                   let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                    keyDown.flags = .maskCommand
                    keyUp.flags = .maskCommand
                    keyDown.post(tap: .cghidEventTap)
                    keyUp.post(tap: .cghidEventTap)
                }
            }
            return nil
        }
        
        // 2. Option + Wheel -> 3x Fast Scroll
        if flags.contains(.maskAlternate) && optFast {
            speedMult *= 3.0
        }
        
        // 3. Control + Wheel -> 0.3x Precision Slow Scroll
        if flags.contains(.maskControl) && ctrlSlow {
            speedMult *= 0.3
        }
        
        // 4. Invert Vertical Scroll
        if invertV {
            deltaY = -deltaY
            pointDeltaY = -pointDeltaY
            fixedDeltaY = -fixedDeltaY
        }
        
        // 5. Invert Horizontal Scroll
        if invertH {
            deltaX = -deltaX
            pointDeltaX = -pointDeltaX
            fixedDeltaX = -fixedDeltaX
        }
        
        // 6. Apply Speed Multiplier
        if speedMult != 1.0 && speedMult > 0 {
            deltaY *= speedMult
            pointDeltaY *= speedMult
            fixedDeltaY *= speedMult
            deltaX *= speedMult
            pointDeltaX *= speedMult
            fixedDeltaX *= speedMult
        }
        
        // 7. Shift + Wheel -> Horizontal Scroll
        if flags.contains(.maskShift) && shiftH && (deltaY != 0 || pointDeltaY != 0) {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0.0)
            
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(deltaY))
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: Int64(pointDeltaY))
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaY)
            return event
        }
        
        // Write transformed values directly back into the CGEvent in-place
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
        let linearAccel = UserDefaults.standard.object(forKey: "disableMouseAcceleration") as? Bool ?? false
        updateHardwarePointerProperties(linear: linearAccel, sensitivity: sensitivity)
        return event
    }
    
    // MARK: - Hardware Pointer Acceleration & Sensitivity (LinearMouse PointerSpeed.swift birebir)
    public func updateHardwarePointerProperties(linear: Bool, sensitivity: Double) {
        guard lastLinearAccel != linear || lastPointerSensitivity != sensitivity else { return }
        lastLinearAccel = linear
        lastPointerSensitivity = sensitivity
        
        // LinearMouse PointerSpeed.swift birebir: IOHIDEventSystemClient üzerinden tüm servislere uygula
        if let createFn = self.iohidCreate,
           let copyServicesFn = self.iohidCopyServices,
           let serviceSetPropFn = self.iohidServiceSetProp,
           let client = createFn(kCFAllocatorDefault),
           let services = copyServicesFn(client) as? [UnsafeMutableRawPointer] {
            
            for service in services {
                if linear {
                    // LinearMouse birebir: -1.0 as CFNumber (Double), key = "HIDMouseAcceleration"
                    let value = -1.0 as CFNumber
                    _ = serviceSetPropFn(service, "HIDMouseAcceleration" as CFString, value)
                } else {
                    // Sensitivity: 0.0 - 3.0 arası Double değer
                    let value = sensitivity as CFNumber
                    _ = serviceSetPropFn(service, "HIDMouseAcceleration" as CFString, value)
                }
            }
        }
        
        // Global Preference Synchronization
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = "/usr/bin/defaults"
            let scaleVal = linear ? "-1" : String(format: "%.2f", sensitivity * 1.5)
            task.arguments = ["write", "-g", "com.apple.mouse.scaling", scaleVal]
            try? task.run()
        }
    }
}
