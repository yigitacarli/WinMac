import Cocoa
import Combine
import CoreGraphics
import IOKit
import IOKit.hid
import IOKit.ps

/// Read-only live information about the connected pointing device, for the
/// "Fare" settings pane: name, native resolution ("DPI"), battery, polling rate.
///
/// Nothing here modifies device state. The polling-rate probe is a *listen-only*
/// event tap that only runs while the pane is on screen.
@MainActor
public final class MousePointerMonitor: ObservableObject {
    public static let shared = MousePointerMonitor()

    @Published public private(set) var deviceName: String?
    @Published public private(set) var nativeResolution: Int?      // "DPI"-ish, HIDPointerResolution
    @Published public private(set) var batteryPercent: Int?
    @Published public private(set) var pollingRateHz: Int?

    private var observers = 0
    private var refreshTimer: Timer?

    private var tap: CFMachPort?
    private var tapSource: CFRunLoopSource?
    private var timestamps: [Double] = []
    private let timestampCapacity = 96

    private init() {}

    // MARK: - Observation lifecycle (called by the Fare pane)

    public func beginObserving() {
        observers += 1
        guard observers == 1 else { return }
        refreshStaticInfo()
        startPollingProbe()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        refreshTimer = t
    }

    public func endObserving() {
        observers = max(0, observers - 1)
        guard observers == 0 else { return }
        refreshTimer?.invalidate()
        refreshTimer = nil
        stopPollingProbe()
        timestamps.removeAll()
        pollingRateHz = nil
    }

    private func tick() {
        refreshStaticInfo()
        recomputePollingRate()
    }

    // MARK: - Static info

    private func refreshStaticInfo() {
        let (name, resolution) = Self.primaryPointerInfo()
        if name != deviceName { deviceName = name }
        if let resolution, Int(resolution.rounded()) != nativeResolution {
            nativeResolution = Int(resolution.rounded())
        }
        let battery = Self.peripheralBatteryPercent()
        if battery != batteryPercent { batteryPercent = battery }
    }

    /// First mouse-like HID device: its product name and pointer resolution.
    private static func primaryPointerInfo() -> (String?, Double?) {
        guard let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone)) as IOHIDManager? else {
            return (nil, nil)
        }
        let match: [String: Any] = [
            kIOHIDDeviceUsagePageKey: 0x01,
            kIOHIDDeviceUsageKey: 0x02  // GenericDesktop / Mouse
        ]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, let device = devices.first else {
            return (nil, nil)
        }
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String
        var resolution: Double?
        if let n = IOHIDDeviceGetProperty(device, kIOHIDPointerResolutionKey as CFString) as? NSNumber {
            resolution = Double(n.int32Value) / 65_536.0
        }
        return (name, resolution)
    }

    /// Battery % of the first non-internal power source (wireless mouse / keyboard).
    private static func peripheralBatteryPercent() -> Int? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            let type = desc[kIOPSTypeKey as String] as? String
            if type == (kIOPSInternalBatteryType as String) { continue }
            guard let current = desc[kIOPSCurrentCapacityKey as String] as? Int else { continue }
            let max = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
            return max > 0 ? Int((Double(current) / Double(max) * 100).rounded()) : current
        }
        return nil
    }

    // MARK: - Polling-rate probe (listen-only)

    private func startPollingProbe() {
        guard tap == nil, AXIsProcessTrusted() else { return }
        let mask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue)
        let callback: CGEventTapCallBack = { _, _, event, refcon in
            if let refcon {
                let monitor = Unmanaged<MousePointerMonitor>.fromOpaque(refcon).takeUnretainedValue()
                let ts = Double(event.timestamp) / 1_000_000_000.0  // ns -> s
                Task { @MainActor in monitor.record(ts) }
            }
            return Unmanaged.passUnretained(event)
        }
        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }
        tap = newTap
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        tapSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
    }

    private func stopPollingProbe() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let tapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), tapSource, .commonModes) }
        tapSource = nil
        tap = nil
    }

    private func record(_ ts: Double) {
        timestamps.append(ts)
        if timestamps.count > timestampCapacity {
            timestamps.removeFirst(timestamps.count - timestampCapacity)
        }
    }

    private func recomputePollingRate() {
        guard timestamps.count >= 8 else { return }
        var deltas: [Double] = []
        for i in 1 ..< timestamps.count {
            let d = timestamps[i] - timestamps[i - 1]
            if d > 0.0002, d < 0.1 { deltas.append(d) }   // ignore 0 and long pauses
        }
        guard deltas.count >= 5 else { return }
        deltas.sort()
        let median = deltas[deltas.count / 2]
        guard median > 0 else { return }
        let hz = Int((1.0 / median).rounded())
        // Snap to the nearest common polling rate so the reading doesn't jitter.
        let common = [125, 250, 500, 1000, 2000, 4000, 8000]
        pollingRateHz = common.min(by: { abs($0 - hz) < abs($1 - hz) }).map { abs($0 - hz) < 80 ? $0 : hz } ?? hz
    }
}
