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
            HStack(spacing: 12) {
                // Style Picker
                HStack(spacing: 4) {
                    ForEach(SwitcherStyle.allCases) { style in
                        Button(action: {
                            settings.switcherStyle = style
                        }) {
                            Image(systemName: iconForStyle(style))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(settings.switcherStyle == style ? .white : .secondary)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(settings.switcherStyle == style ? Color.accentColor : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(style.title)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                
                Spacer()
                
                // Real-time Search Filter
                if settings.searchFilterEnabled {
                    SearchBarView(text: $state.searchText)
                        .frame(width: 240)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Content
            let list = state.filteredWindows
            if list.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "questionmark.folder")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Açık pencere bulunamadı")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
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
                .background(Color.white.opacity(0.12))
            
            // Footer Shortcuts Helper
            HStack(spacing: 14) {
                ShortcutHint(key: "Tab", label: "Sonraki")
                ShortcutHint(key: "⇧ Tab", label: "Önceki")
                ShortcutHint(key: "W", label: "Pencereyi Kapat")
                ShortcutHint(key: "Q", label: "Uygulamayı Kapat")
                ShortcutHint(key: "F", label: "Büyüt")
                ShortcutHint(key: "M", label: "Küçült")
                
                Spacer()
                
                ShortcutHint(key: "↵ / Bırak", label: "Odaklan")
                ShortcutHint(key: "Esc", label: "İptal")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.2))
        }
        .frame(minWidth: 540, maxWidth: 840)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 24, y: 10)
    }
    
    private func iconForStyle(_ style: SwitcherStyle) -> String {
        switch style {
        case .thumbnails: return "square.grid.2x2.fill"
        case .icons: return "app.fill"
        case .titles: return "list.bullet"
        }
    }
}

private struct ShortcutHint: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                )
            
            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

// NSVisualEffectView wrapper for SwiftUI
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
