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
    private typealias IOHIDEventSystemClientCopyServicesFunc = @convention(c) (UnsafeMutableRawPointer) -> CFArray?
    private typealias IOHIDServiceClientSetPropertyFunc = @convention(c) (UnsafeRawPointer, CFString, CFTypeRef) -> Bool
    private typealias IOHIDServiceClientCopyPropertyFunc = @convention(c) (UnsafeRawPointer, CFString) -> Unmanaged<CFTypeRef>?
    
    private var iohidHandle: UnsafeMutableRawPointer?
    private var iohidCreate: IOHIDEventSystemClientCreateFunc?
    private var iohidCopyServices: IOHIDEventSystemClientCopyServicesFunc?
    private var iohidServiceSetProp: IOHIDServiceClientSetPropertyFunc?
    private var iohidServiceCopyProp: IOHIDServiceClientCopyPropertyFunc?
    
    private init() {
        setupIOHID()
    }
    
    private func setupIOHID() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
            print("[WinMac] Warning: Unable to open IOKit framework.")
            return
        }
        self.iohidHandle = handle
        
        if let createSym = dlsym(handle, "IOHIDEventSystemClientCreate") {
            self.iohidCreate = unsafeBitCast(createSym, to: IOHIDEventSystemClientCreateFunc.self)
        }
        if let copyServicesSym = dlsym(handle, "IOHIDEventSystemClientCopyServices") {
            self.iohidCopyServices = unsafeBitCast(copyServicesSym, to: IOHIDEventSystemClientCopyServicesFunc.self)
        }
        if let serviceSetPropSym = dlsym(handle, "IOHIDServiceClientSetProperty") {
            self.iohidServiceSetProp = unsafeBitCast(serviceSetPropSym, to: IOHIDServiceClientSetPropertyFunc.self)
        }
        if let serviceCopyPropSym = dlsym(handle, "IOHIDServiceClientCopyProperty") {
            self.iohidServiceCopyProp = unsafeBitCast(serviceCopyPropSym, to: IOHIDServiceClientCopyPropertyFunc.self)
        }
    }
    
    // MARK: - Scroll Wheel Event Processing
    public func handleScrollEvent(event: CGEvent) -> CGEvent? {
        let defaults = UserDefaults.standard
        let invertV = defaults.object(forKey: "invertMouseWheel") as? Bool ?? false
        let invertH = defaults.object(forKey: "invertHorizontalScroll") as? Bool ?? false
        var speedMult = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        
        let shiftH = defaults.object(forKey: "shiftHorizontalScrollEnabled") as? Bool ?? true
        let cmdZoom = defaults.object(forKey: "cmdZoomScrollEnabled") as? Bool ?? true
        let optFast = defaults.object(forKey: "optionFastScrollEnabled") as? Bool ?? true
        let ctrlSlow = defaults.object(forKey: "ctrlSlowScrollEnabled") as? Bool ?? true
        
        // 1. Strict Trackpad vs External Physical Mouse Distinction
        // On macOS: Trackpads & Touch surfaces ALWAYS have scrollWheelEventIsContinuous != 0.
        // Physical notched mouse wheels ALWAYS have scrollWheelEventIsContinuous == 0.
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        if isContinuous {
            // Trackpad / Magic Mouse touch gesture — DO NOT MODIFY, return as-is for natural scroll
            return event
        }
        
        let flags = event.flags
        var deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        var deltaX = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
        
        var pointDeltaY = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        var pointDeltaX = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
        
        var fixedDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        var fixedDeltaX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        
        // Fallback for mice that don't emit point deltas
        if pointDeltaY == 0 && deltaY != 0 {
            pointDeltaY = deltaY * 12
        }
        if pointDeltaX == 0 && deltaX != 0 {
            pointDeltaX = deltaX * 12
        }
        if fixedDeltaY == 0 && deltaY != 0 {
            fixedDeltaY = Double(deltaY) * 12.0
        }
        if fixedDeltaX == 0 && deltaX != 0 {
            fixedDeltaX = Double(deltaX) * 12.0
        }
        
        // 2. Cmd + Wheel -> Zoom In / Zoom Out
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
                    keyDown.post(tap: .cgSessionEventTap)
                    keyUp.post(tap: .cgSessionEventTap)
                }
            }
            return nil
        }
        
        // 3. Option + Wheel -> 3x Fast Scroll
        if flags.contains(.maskAlternate) && optFast {
            speedMult *= 3.0
        }
        
        // 4. Control + Wheel -> 0.3x Precision Slow Scroll
        if flags.contains(.maskControl) && ctrlSlow {
            speedMult *= 0.3
        }
        
        // 5. Invert Vertical Scroll for Physical Mouse (if enabled)
        if invertV {
            deltaY = -deltaY
            pointDeltaY = -pointDeltaY
            fixedDeltaY = -fixedDeltaY
        }
        
        // 6. Invert Horizontal Scroll (if enabled)
        if invertH {
            deltaX = -deltaX
            pointDeltaX = -pointDeltaX
            fixedDeltaX = -fixedDeltaX
        }
        
        // 7. Apply Speed Multiplier
        if speedMult != 1.0 && speedMult > 0 {
            deltaY = Int64(Double(deltaY) * speedMult)
            pointDeltaY = Int64(Double(pointDeltaY) * speedMult)
            fixedDeltaY = fixedDeltaY * speedMult
            deltaX = Int64(Double(deltaX) * speedMult)
            pointDeltaX = Int64(Double(pointDeltaX) * speedMult)
            fixedDeltaX = fixedDeltaX * speedMult
        }
        
        // 8. Shift + Wheel -> Horizontal Scroll
        if flags.contains(.maskShift) && shiftH && (deltaY != 0 || pointDeltaY != 0) {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0.0)
            
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: deltaY)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: pointDeltaY)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaY)
            return event
        }
        
        // Write transformed values back into the CGEvent
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: deltaY)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: pointDeltaY)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: fixedDeltaY)
        
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: deltaX)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: pointDeltaX)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: fixedDeltaX)
        
        return event
    }
    
    // MARK: - Hardware Pointer Acceleration & Sensitivity (Linear 1:1 Response / Windows Style)
    public func updateHardwarePointerProperties(linear: Bool, sensitivity: Double) {
        lastLinearAccel = linear
        lastPointerSensitivity = sensitivity
        
        let baseResolution: Double = 800.0
        let targetResolution = max(100.0, baseResolution / sensitivity)
        
        // 1. Apply hardware acceleration & resolution properties directly to all external pointer services
        if let createFn = self.iohidCreate,
           let copyServicesFn = self.iohidCopyServices,
           let serviceSetPropFn = self.iohidServiceSetProp,
           let serviceCopyPropFn = self.iohidServiceCopyProp,
           let client = createFn(kCFAllocatorDefault) {
            
            if let services = copyServicesFn(client) {
                let count = CFArrayGetCount(services)
                for i in 0..<count {
                    if let service = CFArrayGetValueAtIndex(services, i) {
                        let product = serviceCopyPropFn(service, "Product" as CFString)?.takeRetainedValue()
                        let prodStr = "\(product ?? "" as CFTypeRef)"
                        let transport = serviceCopyPropFn(service, "Transport" as CFString)?.takeRetainedValue()
                        let transStr = "\(transport ?? "" as CFTypeRef)"
                        let usagePage = serviceCopyPropFn(service, "PrimaryUsagePage" as CFString)?.takeRetainedValue() as? Int ?? 0
                        let usage = serviceCopyPropFn(service, "PrimaryUsage" as CFString)?.takeRetainedValue() as? Int ?? 0
                        
                        let isInternal = prodStr.contains("Internal") || prodStr.contains("Apple Internal")
                        let isExternalTransport = transStr == "USB" || transStr == "Bluetooth" || transStr == "BTH"
                        let isPointerUsage = (usagePage == 1 && (usage == 1 || usage == 2 || usage == 6))
                        let isMouseProduct = prodStr.localizedCaseInsensitiveContains("mouse") ||
                                             prodStr.localizedCaseInsensitiveContains("receiver") ||
                                             prodStr.localizedCaseInsensitiveContains("wireless") ||
                                             prodStr.localizedCaseInsensitiveContains("pointer") ||
                                             prodStr.localizedCaseInsensitiveContains("trackball")
                        
                        if !isInternal && (isExternalTransport || isMouseProduct || isPointerUsage) {
                            if linear {
                                // -1.0 disables macOS non-linear acceleration curve
                                let accelVal = -1.0 as CFNumber
                                _ = serviceSetPropFn(service, "HIDMouseAcceleration" as CFString, accelVal)
                                _ = serviceSetPropFn(service, "HIDPointerAcceleration" as CFString, accelVal)
                            } else {
                                let accelVal = (sensitivity * 65536.0) as CFNumber
                                _ = serviceSetPropFn(service, "HIDMouseAcceleration" as CFString, accelVal)
                                _ = serviceSetPropFn(service, "HIDPointerAcceleration" as CFString, accelVal)
                            }
                            
                            let resVal = targetResolution as CFNumber
                            _ = serviceSetPropFn(service, "HIDPointerResolution" as CFString, resVal)
                        }
                    }
                }
            }
        }
        
        // 2. Global Preference Synchronization for macOS Pointer Scaling
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = "/usr/bin/defaults"
            let scaleVal = linear ? "-1" : String(format: "%.2f", sensitivity * 1.5)
            task.arguments = ["write", "-g", "com.apple.mouse.scaling", scaleVal]
            try? task.run()
        }
    }
}
