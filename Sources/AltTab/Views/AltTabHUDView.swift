import SwiftUI

public struct AltTabHUDView: View {
    @ObservedObject var state: AltTabState
    @ObservedObject var settings = AppSettings.shared
    
    public init(state: AltTabState) {
        self.state = state
    }
    
    public var body: some View {
        let windows = state.filteredWindows
        
        VStack(spacing: 10) {
            // Horizontal App/Window Strip (Clean Command+Tab style)
            if windows.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Açık pencere yok")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 280, height: 110)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                                SwitcherItemCard(
                                    window: window,
                                    isSelected: state.selectedIndex == index,
                                    useThumbnails: settings.switcherStyle == .thumbnails,
                                    onTap: {
                                        state.selectIndex(index)
                                        state.confirmSelection()
                                    },
                                    onHover: { hovered in
                                        if hovered { state.selectIndex(index) }
                                    }
                                )
                                .id(index)
                            }
                        }
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
                
                // Centered App Name & Window Title
                if let selected = state.selectedWindow {
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
            }
        }
        .frame(minWidth: min(CGFloat(max(windows.count, 1) * 95 + 40), 780))
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 28, y: 10)
    }
}

// MARK: - Switcher Item Card

private struct SwitcherItemCard: View {
    let window: WindowModel
    let isSelected: Bool
    let useThumbnails: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if useThumbnails, let thumb = window.thumbnail {
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(16/10, contentMode: .fit)
                        .frame(width: 120, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    if let icon = window.appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .padding(3)
                            .background(Color.black.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .offset(x: 4, y: 4)
                    }
                }
                .padding(6)
            } else {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 62, height: 62)
                        .padding(10)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .padding(10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isSelected
                        ? Color.white.opacity(0.22)
                        : Color.white.opacity(0.04)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isSelected
                        ? Color.white.opacity(0.65)
                        : Color.clear,
                    lineWidth: 1.5
                )
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
