import SwiftUI

/// Windows-style task switcher: a dimmed full-screen backdrop with a centred dark box.
/// `.icons` reproduces the classic Windows "hold-Alt" box (icon strip + title line);
/// `.list` is a vertical detail list for power users.
public struct AltTabHUDView: View {
    @ObservedObject var state: AltTabState
    @ObservedObject var settings = AppSettings.shared

    public init(state: AltTabState) {
        self.state = state
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Windows dims the whole desktop while switching. Tapping it cancels.
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { state.cancelSelection() }

                let windows = state.filteredWindows
                Group {
                    if windows.isEmpty {
                        emptyBox
                    } else if settings.switcherStyle == .list {
                        listBox(windows, maxHeight: geo.size.height * 0.7)
                    } else {
                        classicBox(windows, maxWidth: geo.size.width * 0.82, maxHeight: geo.size.height * 0.6)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: - Shared chrome

    private func boxBackground<V: View>(_ content: V) -> some View {
        content
            .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
            .background(Color.black.opacity(0.38))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 30, y: 12)
    }

    private func hoverSelect(_ index: Int) {
        if state.shouldAcceptHoverSelection() {
            state.selectIndex(index)
        }
    }

    private func confirm(_ index: Int) {
        state.selectIndex(index)
        state.confirmSelection()
    }

    // MARK: - Empty

    private var emptyBox: some View {
        boxBackground(
            VStack(spacing: 8) {
                Image(systemName: "macwindow")
                    .font(.system(size: 30, weight: .light))
                Text("Açık pencere yok")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 280, height: 120)
        )
    }

    // MARK: - Classic Windows box (icon strip + title)

    private static let tileSlot: CGFloat = 94      // grid cell
    private static let tileGap: CGFloat = 8
    private static let boxPad: CGFloat = 20

    private func classicBox(_ windows: [WindowModel], maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        let pitch = Self.tileSlot + Self.tileGap
        // Conservative column count (a little slack so LazyVGrid never wraps a row we
        // didn't budget height for).
        let availW = maxWidth - Self.boxPad * 2 - 6
        let perRow = max(1, min(windows.count, Int((availW + Self.tileGap) / pitch)))
        let rows = Int(ceil(Double(windows.count) / Double(perRow)))
        let gridInnerW = CGFloat(perRow) * pitch - Self.tileGap
        let boxW = max(320, gridInnerW + Self.boxPad * 2)
        let contentH = CGFloat(rows) * pitch - Self.tileGap + 4
        let gridH = min(contentH, maxHeight)
        let columns = [GridItem(.adaptive(minimum: Self.tileSlot, maximum: Self.tileSlot), spacing: Self.tileGap)]

        return boxBackground(
            VStack(spacing: 12) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: Self.tileGap) {
                            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                                iconTile(window, selected: state.selectedIndex == index)
                                    .id(index)
                                    .onTapGesture { confirm(index) }
                                    .onHover { _ in hoverSelect(index) }
                            }
                        }
                    }
                    .frame(width: gridInnerW, height: gridH)
                    .onChange(of: state.selectedIndex) { _, new in
                        withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(new, anchor: .center) }
                    }
                }

                Divider().overlay(Color.white.opacity(0.12))

                titleLine

                if !state.searchText.isEmpty {
                    searchChip(count: windows.count)
                }
            }
            .padding(Self.boxPad)
            .frame(width: boxW)
        )
    }

    private func iconTile(_ window: WindowModel, selected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? Color.white.opacity(0.16)
                      : (window.isDesktop ? Color.white.opacity(0.05) : Color.clear))
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    selected ? Color.accentColor
                    : (window.isDesktop ? Color.white.opacity(0.18) : Color.clear),
                    style: StrokeStyle(lineWidth: selected ? 2 : 1,
                                       dash: window.isDesktop && !selected ? [3, 3] : [])
                )

            Group {
                if window.isDesktop {
                    Image(systemName: "menubar.dock.rectangle")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(.white.opacity(0.9))
                } else if let icon = window.appIcon {
                    Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "app.dashed").font(.system(size: 52)).foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 66, height: 66)
            .opacity(window.isMinimized || window.isHidden ? 0.45 : 1)

            if window.isMinimized || window.isHidden {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .padding(3)
                    .background(Circle().fill(Color(nsColor: .systemOrange)))
                    .offset(x: 28, y: -28)
            }
        }
        .frame(width: Self.tileSlot, height: Self.tileSlot)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.10), value: selected)
    }

    @ViewBuilder
    private var titleLine: some View {
        if let selected = state.selectedWindow {
            VStack(spacing: 2) {
                Text(selected.title.isEmpty ? selected.appName : selected.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !selected.isDesktop, !selected.title.isEmpty, selected.title != selected.appName {
                    Text(selected.appName)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 34)
        } else {
            Color.clear.frame(height: 34)
        }
    }

    private func searchChip(count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 10, weight: .bold))
            Text(state.searchText).font(.system(size: 11, weight: .medium))
            Text("· \(count)").font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.10)))
    }

    // MARK: - List box

    private func listBox(_ windows: [WindowModel], maxHeight: CGFloat) -> some View {
        let rowH: CGFloat = 46
        let listH = min(CGFloat(windows.count) * rowH + 16, maxHeight)
        return boxBackground(
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 2) {
                            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                                listRow(window, selected: state.selectedIndex == index)
                                    .id(index)
                                    .contentShape(Rectangle())
                                    .onTapGesture { confirm(index) }
                                    .onHover { _ in hoverSelect(index) }
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: listH)
                    .onChange(of: state.selectedIndex) { _, new in
                        withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(new, anchor: .center) }
                    }
                }
                if !state.searchText.isEmpty {
                    Divider().overlay(Color.white.opacity(0.12))
                    searchChip(count: windows.count).padding(8)
                }
            }
            .frame(width: 460)
        )
    }

    private func listRow(_ window: WindowModel, selected: Bool) -> some View {
        HStack(spacing: 10) {
            if window.isDesktop {
                Image(systemName: "menubar.dock.rectangle")
                    .font(.system(size: 15)).frame(width: 24, height: 24)
                    .foregroundStyle(.white.opacity(0.9))
            } else if let icon = window.appIcon {
                Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit).frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.dashed").font(.system(size: 18)).frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(window.title.isEmpty ? window.appName : window.title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
                if !window.isDesktop {
                    Text(window.appName)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if window.isMinimized {
                Image(systemName: "minus.circle").font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.30) : Color.clear)
        )
    }
}

// MARK: - Blur Background (also used by the clipboard HUD)

public struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
