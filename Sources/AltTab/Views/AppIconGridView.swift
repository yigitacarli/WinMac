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
            if let icon = window.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.blue)
            }
            
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
        .padding(14)
        .frame(minWidth: 104)
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
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
        )
        .shadow(
            color: isSelected ? Color.blue.opacity(0.4) : Color.black.opacity(0.15),
            radius: isSelected ? 10 : 4,
            y: 2
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
    }
}
