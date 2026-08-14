import SwiftUI

public struct AppIconGridView: View {
    @ObservedObject var state: AltTabState
    let windows: [WindowModel]
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 18)
    ]
    
    public init(state: AltTabState, windows: [WindowModel]) {
        self.state = state
        self.windows = windows
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                    AppIconCard(
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
            .padding(24)
        }
        .frame(maxHeight: 390)
    }
}

private struct AppIconCard: View {
    let window: WindowModel
    let isSelected: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            iconView
            labelView
        }
        .padding(14)
        .frame(minWidth: 100)
        .background(backgroundShape)
        .overlay(overlayBorder)
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
            radius: isSelected ? 8 : 2,
            y: isSelected ? 2 : 1
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = window.appIcon {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
        } else {
            Image(systemName: "app.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var labelView: some View {
        VStack(spacing: 2) {
            Text(window.appName)
                .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            if !window.title.isEmpty && window.title != window.appName {
                Text(window.title)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.white.opacity(0.05))
    }
    
    private var overlayBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(isSelected ? Color.accentColor.opacity(0.85) : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
    }
}
