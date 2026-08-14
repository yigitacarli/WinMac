import SwiftUI

public struct ThumbnailGridView: View {
    @ObservedObject var state: AltTabState
    let windows: [WindowModel]
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)
    ]
    
    public init(state: AltTabState, windows: [WindowModel]) {
        self.state = state
        self.windows = windows
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                    ThumbnailCard(
                        window: window,
                        isSelected: state.selectedIndex == index,
                        onTap: {
                            state.selectIndex(index)
                            state.confirmSelection()
                        },
                        onHover: { isHovered in
                            if isHovered {
                                state.selectIndex(index)
                            }
                        }
                    )
                }
            }
            .padding(20)
        }
        .frame(maxHeight: 480)
    }
}

private struct ThumbnailCard: View {
    let window: WindowModel
    let isSelected: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Window Preview Frame
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .frame(height: 140)
                
                if let thumb = window.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    // Elegant fallback
                    VStack(spacing: 8) {
                        if let icon = window.appIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 54, height: 54)
                        } else {
                            Image(systemName: "macwindow")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Subtle glass light highlight
                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .allowsHitTesting(false)
                
                // Floating App Icon Squircle Badge (Top-Left)
                VStack {
                    HStack {
                        if let icon = window.appIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 26, height: 26)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.black.opacity(0.65))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                                )
                                .padding(8)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(height: 140)
            
            // Labels
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(window.appName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.95))
                        .lineLimit(1)
                    
                    Text(window.title)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 6)
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Color.white.opacity(0.06))
                    )
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            }
        )
        .shadow(
            color: isSelected ? Color.blue.opacity(0.45) : Color.black.opacity(0.2),
            radius: isSelected ? 12 : 6,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isSelected)
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
    }
}
