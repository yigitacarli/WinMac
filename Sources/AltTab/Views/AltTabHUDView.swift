import SwiftUI

public struct AltTabHUDView: View {
    @ObservedObject var state: AltTabState
    @ObservedObject var settings = AppSettings.shared

    public init(state: AltTabState) {
        self.state = state
    }

    public var body: some View {
        let windows = state.filteredWindows

        Group {
            if windows.isEmpty {
                emptyState
            } else {
                switch settings.switcherStyle {
                case .icons: iconStrip(windows)
                case .list: listLayout(windows)
                }
            }
        }
        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 22, y: 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "macwindow")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary)
            Text("Açık pencere yok")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 280, height: 110)
    }

    // MARK: - Shared horizontal strip

    private func strip<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                content()
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
            }
            .onChange(of: state.selectedIndex) { _, newIndex in
                withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
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

    /// Compact caption chip under the strip: app name bold, window title secondary.
    @ViewBuilder
    private func selectedLabel(_ selected: WindowModel) -> some View {
        HStack(spacing: 8) {
            Text(selected.appName)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            if !selected.title.isEmpty && selected.title != selected.appName {
                Text(selected.title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            if selected.isMinimized || selected.isHidden {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(nsColor: .systemOrange))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.bottom, 14)
    }

    // MARK: - 1. Büyük Simgeler (Command+Tab görünümü)

    private func iconStrip(_ windows: [WindowModel]) -> some View {
        VStack(spacing: 8) {
            strip {
                HStack(spacing: 10) {
                    ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                        SwitcherCard(
                            window: window,
                            isSelected: state.selectedIndex == index,
                            cardSize: CGSize(width: 86, height: 86),
                            cornerRadius: 18,
                            onTap: { confirm(index) },
                            onHover: { _ in hoverSelect(index) }
                        ) {
                            if let icon = window.appIcon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 58, height: 58)
                            } else {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(Color.accentColor)
                            }
                            badgeDots(window)
                                .offset(x: 30, y: -30)
                        }
                        .id(index)
                    }
                }
            }
            if let selected = state.selectedWindow {
                selectedLabel(selected)
            }
        }
        .frame(minWidth: min(CGFloat(max(windows.count, 1)) * 96 + 56, 780))
    }

    // MARK: - 2. Ayrıntılı Liste

    private func listLayout(_ windows: [WindowModel]) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                        HStack(spacing: 10) {
                            if let icon = window.appIcon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 22, height: 22)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(window.title)
                                    .font(.system(size: 12.5, weight: state.selectedIndex == index ? .semibold : .regular))
                                    .lineLimit(1)
                                Text(window.appName)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if window.isMinimized {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(state.selectedIndex == index ? Color.accentColor.opacity(0.24) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { confirm(index) }
                        .onHover { _ in hoverSelect(index) }
                        .id(index)
                    }
                }
                .padding(10)
            }
            .onChange(of: state.selectedIndex) { _, newIndex in
                withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(width: 440)
    }

    @ViewBuilder
    private func badgeDots(_ window: WindowModel) -> some View {
        if window.isMinimized || window.isHidden {
            Circle()
                .fill(Color(nsColor: .systemOrange))
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Switcher Card (strip stilleri için ortak çerçeve)

private struct SwitcherCard<Content: View>: View {
    let window: WindowModel
    let isSelected: Bool
    let cardSize: CGSize
    var cornerRadius: CGFloat = 14
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(width: cardSize.width, height: cardSize.height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.20) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.85) : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
            .onTapGesture(perform: onTap)
            .onHover(perform: onHover)
    }
}

// MARK: - Blur Background

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
