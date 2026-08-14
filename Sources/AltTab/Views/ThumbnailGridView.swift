import SwiftUI

public struct ThumbnailGridView: View {
    @ObservedObject var state: AltTabState
    let windows: [WindowModel]
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 14)
    ]
    
    public init(state: AltTabState, windows: [WindowModel]) {
        self.state = state
        self.windows = windows
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
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
            .padding(16)
        }
        .frame(maxHeight: 460)
    }
}

private struct ThumbnailCard: View {
    let window: WindowModel
    let isSelected: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail Preview Container
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .frame(height: 130)
                
                if let thumb = window.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    // Fallback to app icon if thumbnail is unavailable
                    if let icon = window.appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                    } else {
                        Image(systemName: "macwindow")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
                
                // Top-Left App Icon Badge
                VStack {
                    HStack {
                        if let icon = window.appIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: 28, height: 28)
                                )
                                .padding(6)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(height: 130)
            
            // App and Window Title
            VStack(alignment: .leading, spacing: 2) {
                Text(window.appName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary.opacity(0.9))
                    .lineLimit(1)
                
                Text(window.title)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.15), radius: isSelected ? 8 : 4, y: 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
    }
}
