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
                case .thumbnails: thumbnailStrip(windows)
                case .compact: compactStrip(windows)
                case .list: listLayout(windows)
                }
            }
        }
        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 28, y: 10)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "macwindow")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("Açık pencere yok")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 280, height: 110)
    }
    
    // MARK: - Shared horizontal scroll strip
    
    private func strip<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                content()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
            }
            .onChange(of: state.selectedIndex) { _, newIndex in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    private func selectedLabel(_ selected: WindowModel) -> some View {
        VStack(spacing: 2) {
            Text(selected.appName)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if !selected.title.isEmpty && selected.title != selected.appName {
                Text(selected.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - 1. Büyük Simgeler (varsayılan Command+Tab görünümü)
    
    private func iconStrip(_ windows: [WindowModel]) -> some View {
        VStack(spacing: 10) {
            strip {
                HStack(spacing: 12) {
                    ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                        SwitcherCard(
                            window: window,
                            isSelected: state.selectedIndex == index,
                            content: {
                                if let icon = window.appIcon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 62, height: 62)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.blue)
                                }
                            },
                            cardSize: CGSize(width: 88, height: 88),
                            onTap: {
                                state.selectIndex(index)
                                state.confirmSelection()
                            },
                            onHover: { if $0 { state.selectIndex(index) } }
                        )
                        .id(index)
                    }
                }
            }
            if let selected = state.selectedWindow {
                selectedLabel(selected)
            }
        }
        .frame(minWidth: min(CGFloat(max(windows.count, 1) * 100 + 40), 780))
    }
    
    // MARK: - 2. Pencere Önizlemeleri (canlı ekran görüntülü kartlar)
    
    private func thumbnailStrip(_ windows: [WindowModel]) -> some View {
        VStack(spacing: 10) {
            strip {
                HStack(spacing: 14) {
                    ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                        SwitcherCard(
                            window: window,
                            isSelected: state.selectedIndex == index,
                            content: {
                                VStack(spacing: 5) {
                                    if let thumb = window.thumbnail {
                                        Image(nsImage: thumb)
                                            .resizable()
                                            .aspectRatio(16/10, contentMode: .fit)
                                            .frame(width: 148, height: 92)
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    } else if let icon = window.appIcon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 56, height: 56)
                                            .frame(width: 148, height: 92)
                                    } else {
                                        Image(systemName: "macwindow")
                                            .font(.system(size: 34))
                                            .foregroundColor(.secondary)
                                            .frame(width: 148, height: 92)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        if let icon = window.appIcon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 13, height: 13)
                                        }
                                        Text(window.appName)
                                            .font(.system(size: 10.5, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(1)
                                    }
                                }
                            },
                            cardSize: CGSize(width: 160, height: 122),
                            onTap: {
                                state.selectIndex(index)
                                state.confirmSelection()
                            },
                            onHover: { if $0 { state.selectIndex(index) } }
                        )
                        .id(index)
                    }
                }
            }
            if let selected = state.selectedWindow {
                selectedLabel(selected)
            }
        }
        .frame(minWidth: min(CGFloat(max(windows.count, 1) * 174 + 40), 900))
    }
    
    // MARK: - 3. Kompakt Izgara (küçük kartlar, yoğun geçiş)
    
    private func compactStrip(_ windows: [WindowModel]) -> some View {
        strip {
            HStack(spacing: 6) {
                ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                    SwitcherCard(
                        window: window,
                        isSelected: state.selectedIndex == index,
                        content: {
                            VStack(spacing: 3) {
                                if let icon = window.appIcon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                }
                                
                                Text(window.appName)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineLimit(1)
                                    .frame(maxWidth: 52)
                            }
                        },
                        cardSize: CGSize(width: 58, height: 58),
                        cornerRadius: 8,
                        onTap: {
                            state.selectIndex(index)
                            state.confirmSelection()
                        },
                        onHover: { if $0 { state.selectIndex(index) } }
                    )
                    .id(index)
                }
            }
        }
        .frame(minWidth: min(CGFloat(max(windows.count, 1) * 64 + 30), 700))
    }
    
    // MARK: - 4. Ayrıntılı Liste (dikey satırlar, başlık odaklı)
    
    private func listLayout(_ windows: [WindowModel]) -> some View {
        VStack(spacing: 0) {
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
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 22, height: 22)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(window.title)
                                        .font(.system(size: 12.5, weight: state.selectedIndex == index ? .semibold : .regular))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(window.appName)
                                        .font(.system(size: 10.5))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if window.isMinimized {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(state.selectedIndex == index ? Color.white.opacity(0.20) : Color.clear)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                state.selectIndex(index)
                                state.confirmSelection()
                            }
                            .onHover { if $0 { state.selectIndex(index) } }
                            .id(index)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: state.selectedIndex) { _, newIndex in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 420, height: min(CGFloat(windows.count * 44 + 20), 380))
    }
}

// MARK: - Switcher Card (strip stilleri için ortak çerçeve)

private struct SwitcherCard<Content: View>: View {
    let window: WindowModel
    let isSelected: Bool
    @ViewBuilder let content: () -> Content
    let cardSize: CGSize
    var cornerRadius: CGFloat = 12
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        content()
            .frame(width: cardSize.width, height: cardSize.height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.65) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.8), value: isSelected)
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
