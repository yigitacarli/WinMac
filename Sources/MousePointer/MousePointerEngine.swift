import Cocoa
import IOKit
import IOKit.hid

/// Cursor acceleration & speed control for external mice.
///
/// Approach modelled on LinearMouse (MIT): the pointer resolution / acceleration
/// properties of every `IOHIDServiceClient` in the HID event system are overridden.
/// Unlike the earlier `ScrollInverter`, this:
///   • never touches `com.apple.mouse.scaling` defaults,
///   • captures each device's original values and restores them on disable / quit,
///   • re-applies when a mouse re-connects, on wake, and on a slow safety timer,
///   • suspends itself while an excluded app is frontmost.
///
/// All of the `IOHIDEventSystemClient*` symbols are private IOKit SPI resolved via
/// `dlsym` at runtime; if they ever disappear the engine degrades to a no-op.
@MainActor
public final class MousePointerEngine {
    public static let shared = MousePointerEngine()

    private var started = false
    private var active = false                 // currently applying overrides?
    private var safetyTimer: Timer?
    private var ioNotifyPort: IONotificationPortRef?
    private var ioIterator: io_iterator_t = 0

    /// Original values, keyed by a stable device signature ("vendor:product:location").
    /// Persisted so a restore still works after a relaunch or crash.
    private var baseline: [String: Baseline] {
        get {
            guard let raw = UserDefaults.standard.dictionary(forKey: "mousePointerBaseline") as? [String: [String: Double]] else { return [:] }
            return raw.compactMapValues { Baseline(dict: $0) }
        }
        set {
            UserDefaults.standard.set(newValue.mapValues { $0.dict }, forKey: "mousePointerBaseline")
        }
    }

    private struct Baseline {
        var resolution: Double
        var acceleration: Double
        var dict: [String: Double] { ["resolution": resolution, "acceleration": acceleration] }
        init(resolution: Double, acceleration: Double) { self.resolution = resolution; self.acceleration = acceleration }
        init?(dict: [String: Double]) {
            guard let r = dict["resolution"], let a = dict["acceleration"] else { return nil }
            resolution = r; acceleration = a
        }
    }

    private init() {}

    // MARK: - Lifecycle

    public func start() {
        guard !started else { syncFromSettings(); return }
        started = true

        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleAppActivated), name: NSWorkspace.didActivateApplicationNotification, object: nil)

        registerHardwareReconnectNotification()
        syncFromSettings()
    }

    /// Re-reads AppSettings and applies or restores accordingly. Call after any setting change.
    public func syncFromSettings() {
        guard started else { return }
        let s = AppSettings.shared
        guard s.mousePointerEnabled, !isFrontmostExcluded() else {
            deactivate()
            return
        }
        activate()
    }

    public func stop() {
        deactivate()
    }

    // MARK: - Apply / restore

    private func activate() {
        applyOverrides()
        active = true
        if safetyTimer == nil {
            // Cheap idempotent re-apply; the private API silently forgets overrides
            // across some sleep / fast-user-switch / device power cycles.
            let t = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.active else { return }
                    self.applyOverrides()
                }
            }
            RunLoop.main.add(t, forMode: .common)
            safetyTimer = t
        }
    }

    private func deactivate() {
        safetyTimer?.invalidate()
        safetyTimer = nil
        if active {
            restoreOverrides()
            active = false
        }
    }

    private func applyOverrides() {
        let s = AppSettings.shared
        forEachPointerService { client, signature in
            // Capture the untouched values exactly once per device.
            if baseline[signature] == nil {
                let res = Self.copyIOFixed(client, kIOHIDPointerResolutionKey) ?? 400
                let acc = Self.copyIOFixed(client, "HIDMouseAcceleration") ?? 0.6875
                var b = baseline
                b[signature] = Baseline(resolution: res, acceleration: acc)
                baseline = b
            }
            let base = baseline[signature] ?? Baseline(resolution: 400, acceleration: 0.6875)

            // Speed: a multiplier over the device's own resolution (lower value = faster).
            let targetRes = (base.resolution / max(0.1, s.mousePointerSpeed)).clamped(10, 1995)
            Self.setIOFixed(client, kIOHIDPointerResolutionKey, targetRes)

            if s.mousePointerDisableAccel {
                Self.setInt(client, "HIDUseLinearScalingMouseAcceleration", 1)
                Self.setIOFixed(client, "HIDMouseAcceleration", -1)
                Self.setIOFixed(client, "HIDPointerAcceleration", -1)
            } else {
                Self.setInt(client, "HIDUseLinearScalingMouseAcceleration", 0)
                let acc = s.mousePointerAcceleration.clamped(0, 20)
                Self.setIOFixed(client, "HIDMouseAcceleration", acc)
                Self.setIOFixed(client, "HIDPointerAcceleration", acc)
            }
            // HACK (from LinearMouse): nudging acceleration makes a resolution change take effect.
            Self.setIOFixed(client, kIOHIDPointerResolutionKey, targetRes)
        }
    }

    private func restoreOverrides() {
        let snapshot = baseline
        forEachPointerService { client, signature in
            let base = snapshot[signature]
            Self.setInt(client, "HIDUseLinearScalingMouseAcceleration", 0)
            Self.setIOFixed(client, "HIDMouseAcceleration", base?.acceleration ?? 0.6875)
            Self.setIOFixed(client, "HIDPointerAcceleration", base?.acceleration ?? 0.6875)
            Self.setIOFixed(client, kIOHIDPointerResolutionKey, base?.resolution ?? 400)
        }
    }

    // MARK: - Notifications

    @objc private func handleWake() {
        guard active else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.applyOverrides()
        }
    }

    @objc private func handleAppActivated() {
        syncFromSettings()
    }

    private func isFrontmostExcluded() -> Bool {
        guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return AppSettings.shared.mousePointerExcludedApps.contains(id)
    }

    /// Fires when any HID pointing device is added to the IORegistry.
    private func registerHardwareReconnectNotification() {
        let port = IONotificationPortCreate(kIOMainPortDefault)
        guard let port else { return }
        ioNotifyPort = port
        IONotificationPortSetDispatchQueue(port, DispatchQueue.main)

        let matching = IOServiceMatching("IOHIDDevice")
        let callback: IOServiceMatchingCallback = { context, iterator in
            // Drain the iterator (required to re-arm the notification) then re-apply.
            while case let next = IOIteratorNext(iterator), next != 0 { IOObjectRelease(next) }
            guard let context else { return }
            let engine = Unmanaged<MousePointerEngine>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                guard engine.active else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { engine.applyOverrides() }
            }
        }
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        var iter: io_iterator_t = 0
        let kr = IOServiceAddMatchingNotification(port, kIOMatchedNotification, matching, callback, ctx, &iter)
        if kr == KERN_SUCCESS {
            ioIterator = iter
            while case let next = IOIteratorNext(iter), next != 0 { IOObjectRelease(next) } // arm
        }
    }

    // MARK: - IOHID service enumeration (private SPI via dlsym)

    private typealias CreateFn = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
    private typealias CopyServicesFn = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
    private typealias CopyPropertyFn = @convention(c) (AnyObject, CFString) -> Unmanaged<CFTypeRef>?
    private typealias SetPropertyFn = @convention(c) (AnyObject, CFString, CFTypeRef) -> DarwinBoolean
    private typealias ConformsToFn = @convention(c) (AnyObject, UInt32, UInt32) -> DarwinBoolean

    private struct SPI {
        let create: CreateFn
        let copyServices: CopyServicesFn
        let copyProperty: CopyPropertyFn
        let setProperty: SetPropertyFn
        let conformsTo: ConformsToFn?
    }

    private static let spi: SPI? = {
        guard let h = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY) else { return nil }
        func sym<T>(_ name: String, _ type: T.Type) -> T? {
            guard let p = dlsym(h, name) else { return nil }
            return unsafeBitCast(p, to: T.self)
        }
        guard let create = sym("IOHIDEventSystemClientCreate", CreateFn.self),
              let copyServices = sym("IOHIDEventSystemClientCopyServices", CopyServicesFn.self),
              let copyProperty = sym("IOHIDServiceClientCopyProperty", CopyPropertyFn.self),
              let setProperty = sym("IOHIDServiceClientSetProperty", SetPropertyFn.self)
        else { return nil }
        return SPI(create: create, copyServices: copyServices, copyProperty: copyProperty,
                   setProperty: setProperty, conformsTo: sym("IOHIDServiceClientConformsTo", ConformsToFn.self))
    }()

    private var cachedClient: AnyObject?

    private func eventSystemClient() -> AnyObject? {
        if let c = cachedClient { return c }
        guard let spi = Self.spi, let c = spi.create(kCFAllocatorDefault)?.takeRetainedValue() else { return nil }
        cachedClient = c
        return c
    }

    /// Runs `body` for every service that is a real mouse.
    ///
    /// Deliberately excludes trackpads: they conform to the *Pointer* usage but not
    /// the *Mouse* usage, and overriding their resolution/acceleration feels wrong.
    /// If the `conformsTo` SPI is unavailable we touch nothing rather than risk it.
    private func forEachPointerService(_ body: (_ client: AnyObject, _ signature: String) -> Void) {
        guard let spi = Self.spi,
              let conforms = spi.conformsTo,
              let client = eventSystemClient(),
              let services = spi.copyServices(client)?.takeRetainedValue() as? [AnyObject]
        else { return }

        let kHIDPage_GenericDesktop: UInt32 = 0x01
        let kHIDUsage_GD_Mouse: UInt32 = 0x02

        for service in services {
            guard conforms(service, kHIDPage_GenericDesktop, kHIDUsage_GD_Mouse).boolValue else { continue }
            let name = (Self.copyProperty(service, kIOHIDProductKey) as? String)?.lowercased() ?? ""
            if name.contains("trackpad") || name.contains("touchpad") { continue }
            body(service, Self.signature(for: service))
        }
    }

    private static func signature(for service: AnyObject) -> String {
        let vid = (copyProperty(service, kIOHIDVendorIDKey) as? NSNumber)?.intValue ?? 0
        let pid = (copyProperty(service, kIOHIDProductIDKey) as? NSNumber)?.intValue ?? 0
        let loc = (copyProperty(service, "LocationID") as? NSNumber)?.intValue ?? 0
        return "\(vid):\(pid):\(loc)"
    }

    // MARK: - Typed property helpers

    fileprivate static func copyProperty(_ service: AnyObject, _ key: String) -> Any? {
        guard let spi = spi else { return nil }
        return spi.copyProperty(service, key as CFString)?.takeRetainedValue()
    }

    fileprivate static func copyIOFixed(_ service: AnyObject, _ key: String) -> Double? {
        guard let n = copyProperty(service, key) as? NSNumber else { return nil }
        return Double(n.int32Value) / 65_536.0
    }

    private static func setIOFixed(_ service: AnyObject, _ key: String, _ value: Double) {
        guard let spi = spi else { return }
        let fixed = Int32(truncatingIfNeeded: Int(value * 65_536.0))
        _ = spi.setProperty(service, key as CFString, NSNumber(value: fixed))
    }

    private static func setInt(_ service: AnyObject, _ key: String, _ value: Int) {
        guard let spi = spi else { return }
        _ = spi.setProperty(service, key as CFString, NSNumber(value: value))
    }
}

private extension Double {
    func clamped(_ lo: Double, _ hi: Double) -> Double { Swift.min(Swift.max(self, lo), hi) }
}
