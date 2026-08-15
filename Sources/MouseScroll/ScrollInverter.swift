import CoreGraphics
import Foundation
import Cocoa
import IOKit

public final class ScrollInverter: @unchecked Sendable {
    public static let shared = ScrollInverter()
    
    // MARK: - IOHID Dynamic Function Pointers
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
        let speedMult = defaults.object(forKey: "scrollSpeedMultiplier") as? Double ?? 1.0
        
        // 1. Strict Trackpad vs External Physical Mouse Distinction
        // On macOS: Trackpads & Touch surfaces ALWAYS have scrollWheelEventIsContinuous != 0.
        // Physical notched mouse wheels ALWAYS have scrollWheelEventIsContinuous == 0.
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        if isContinuous {
            // Trackpad touch gesture — DO NOT MODIFY, return as-is for natural scroll
            return event
        }
        
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
        
        // 2. Invert Vertical Scroll for Physical Mouse (if enabled)
        if invertV {
            deltaY = -deltaY
            pointDeltaY = -pointDeltaY
            fixedDeltaY = -fixedDeltaY
        }
        
        // 3. Invert Horizontal Scroll (if enabled)
        if invertH {
            deltaX = -deltaX
            pointDeltaX = -pointDeltaX
            fixedDeltaX = -fixedDeltaX
        }
        
        // 4. Apply Speed Multiplier
        if speedMult != 1.0 && speedMult > 0 {
            deltaY = Int64(Double(deltaY) * speedMult)
            pointDeltaY = Int64(Double(pointDeltaY) * speedMult)
            fixedDeltaY = fixedDeltaY * speedMult
            deltaX = Int64(Double(deltaX) * speedMult)
            pointDeltaX = Int64(Double(pointDeltaX) * speedMult)
            fixedDeltaX = fixedDeltaX * speedMult
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
    
    // MARK: - Hardware Pointer Acceleration & Sensitivity (Linear 1:1 Response)
    public func updateHardwarePointerProperties(linear: Bool, sensitivity: Double) {
        // Base DPI in macOS IOHID is represented in 16.16 fixed point format (DPI * 65536)
        // Standard macOS base resolution is ~400 DPI (400 * 65536 = 26214400)
        // Higher sensitivity -> Lower DPI value -> Cursor moves faster
        // Lower sensitivity -> Higher DPI value -> Cursor moves slower & with high precision
        let baseDPI: Double = 400.0
        let targetDPI = max(80.0, baseDPI / sensitivity)
        let fixedPointResolution = Int(targetDPI * 65536.0)
        
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
                                // -1.0 disables macOS non-linear acceleration curve for 1:1 raw input
                                let accelVal = -1.0 as CFNumber
                                _ = serviceSetPropFn(service, "HIDMouseAcceleration" as CFString, accelVal)
                                _ = serviceSetPropFn(service, "HIDPointerAcceleration" as CFString, accelVal)
                            } else {
                                let accelVal = (sensitivity * 65536.0) as CFNumber
                                _ = serviceSetPropFn(service, "HIDMouseAcceleration" as CFString, accelVal)
                                _ = serviceSetPropFn(service, "HIDPointerAcceleration" as CFString, accelVal)
                            }
                            
                            let resVal = fixedPointResolution as CFNumber
                            _ = serviceSetPropFn(service, "HIDPointerResolution" as CFString, resVal)
                        }
                    }
                }
            }
        }
        
        // 2. Global macOS mouse scaling preference sync
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = "/usr/bin/defaults"
            let scaleVal = String(format: "%.2f", max(0.1, sensitivity * 1.5))
            task.arguments = ["write", "-g", "com.apple.mouse.scaling", scaleVal]
            try? task.run()
        }
    }
}
