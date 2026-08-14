import SwiftUI

public struct AltTabHUDView: View {
    @ObservedObject var state: AltTabState
    @ObservedObject var settings = AppSettings.shared
    
    public init(state: AltTabState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 16) {
                // WinMac Pill Badge
                HStack(spacing: 6) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    Text("Alt + Tab")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
                
                // Style Switcher Segmented Control
                HStack(spacing: 2) {
                    ForEach(SwitcherStyle.allCases) { style in
                        Button(action: {
                            settings.switcherStyle = style
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: iconForStyle(style))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(settings.switcherStyle == style ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        settings.switcherStyle == style
                                            ? AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                            : AnyShapeStyle(Color.clear)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(style.title)
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
                
                Spacer()
                
                // Real-time Search Filter
                if settings.searchFilterEnabled {
                    SearchBarView(text: $state.searchText)
                        .frame(width: 230)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)
            
            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.white.opacity(0.18), Color.white.opacity(0.02)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Content
            let list = state.filteredWindows
            if list.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Açık pencere bulunamadı")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                switch settings.switcherStyle {
                case .thumbnails:
                    ThumbnailGridView(state: state, windows: list)
                case .icons:
                    AppIconGridView(state: state, windows: list)
                case .titles:
                    TitleListView(state: state, windows: list)
                }
            }
            
            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.white.opacity(0.18), Color.white.opacity(0.02)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Modern Keycap Footer
            HStack(spacing: 12) {
                KeyCapHint(key: "Tab", label: "Sonraki")
                KeyCapHint(key: "⇧ Tab", label: "Önceki")
                KeyCapHint(key: "W", label: "Kapat")
                KeyCapHint(key: "Q", label: "Çık")
                KeyCapHint(key: "F", label: "Büyüt")
                KeyCapHint(key: "M", label: "Küçült")
                
                Spacer()
                
                KeyCapHint(key: "↵ / Bırak", label: "Odaklan")
                KeyCapHint(key: "Esc", label: "İptal")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(Color.black.opacity(0.35))
        }
        .frame(minWidth: 560, maxWidth: 860)
        .background(
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.1),
                            Color.cyan.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.55), radius: 32, y: 16)
    }
    
    private func iconForStyle(_ style: SwitcherStyle) -> String {
        switch style {
        case .thumbnails: return "square.grid.2x2.fill"
        case .icons: return "app.fill"
        case .titles: return "list.bullet"
        }
    }
}

private struct KeyCapHint: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
            
            Text(label)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

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
