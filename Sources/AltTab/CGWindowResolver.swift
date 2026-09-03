import Cocoa
import CoreGraphics

/// Resolves real CGWindowIDs for Accessibility windows and provides WindowServer z-order.
///
/// AX window lists have unstable ordering, so a fake `pid<<8|index` identity breaks caches and
/// focus targeting. All matching here happens against a single CGWindowList snapshot taken once
/// per switcher scan.
///
/// Coordinate spaces: AX reports positions in Quartz top-left-origin coordinates relative to the
/// primary display (same space as CGWindowList bounds). Conversion from Cocoa bottom-left coords
/// mirrors Rectangle's `screenFlipped`: y' = maxY(primaryScreen) - maxY(rect). Using the tallest
/// screen's maxY instead of screens[0] also covers exotic multi-display arrangements.
public enum CGWindowResolver {

    public static var globalTopY: CGFloat {
        NSScreen.screens.map { $0.frame.maxY }.max() ?? 0
    }

    public static func quartzFrame(fromAx bounds: CGRect) -> CGRect {
        CGRect(x: bounds.minX, y: globalTopY - bounds.maxY, width: bounds.width, height: bounds.height)
    }

    public struct Entry {
        public let windowID: CGWindowID
        public let pid: pid_t
        public let frame: CGRect
    }

    public final class Snapshot {
        /// Layer-0 windows, front-to-back as reported by the WindowServer.
        public let entries: [Entry]
        private let rankByID: [CGWindowID: Int]

        public init(onScreenOnly: Bool = true) {
            let options: CGWindowListOption = onScreenOnly
                ? [.optionOnScreenOnly, .excludeDesktopElements]
                : [.optionAll]
            let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

            var collected: [Entry] = []
            var rank: [CGWindowID: Int] = [:]
            var order = 0

            for info in raw {
                let layer = info[kCGWindowLayer as String] as? Int ?? -1
                guard layer == 0 else { continue }
                guard let pidValue = info[kCGWindowOwnerPID as String] as? Int,
                      let idValue = info[kCGWindowNumber as String] as? UInt32 else { continue }

                var frame = CGRect.zero
                if let b = info[kCGWindowBounds as String] as? [String: CGFloat],
                   let x = b["X"], let y = b["Y"],
                   let w = b["Width"], let h = b["Height"] {
                    frame = CGRect(x: x, y: y, width: w, height: h)
                }

                let id = CGWindowID(idValue)
                collected.append(Entry(windowID: id, pid: pid_t(pidValue), frame: frame))
                rank[id] = order
                order += 1
            }

            self.entries = collected
            self.rankByID = rank
        }

        /// Front-to-back stacking position; lower = closer to the front.
        public func rank(of id: CGWindowID) -> Int? {
            rankByID[id]
        }

        /// Matches an AX window (Cocoa-space bounds) to its real CGWindowID by pid + geometry.
        /// Returns nil for minimized/offscreen windows (absent from the on-screen snapshot).
        public func resolveID(pid: pid_t, axBounds: CGRect) -> CGWindowID? {
            guard axBounds.width > 1, axBounds.height > 1 else { return nil }
            let target = CGWindowResolver.quartzFrame(fromAx: axBounds)

            var bestID: CGWindowID?
            var bestDistance = CGFloat.greatestFiniteMagnitude
            for entry in entries where entry.pid == pid {
                let distance = abs(entry.frame.midX - target.midX) + abs(entry.frame.midY - target.midY) +
                    abs(entry.frame.width - target.width) + abs(entry.frame.height - target.height)
                if distance < bestDistance {
                    bestDistance = distance
                    bestID = entry.windowID
                }
            }
            // Tolerance absorbs AX-vs-CGWindowList drift (shadows, insets); anything looser
            // would risk binding two overlapping windows of the same app to one ID.
            return bestDistance < 60 ? bestID : nil
        }
    }
}
