import SwiftUI

public struct ThumbnailGridView: View {
    @ObservedObject var state: AltTabState
    let windows: [WindowModel]
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16)
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
        .frame(maxHeight: 420)
    }
}

private struct ThumbnailCard: View {
    let window: WindowModel
    let isSelected: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: App Icon & Name
            HStack(spacing: 8) {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: "app.fill")
                        .foregroundColor(.blue)
                        .frame(width: 22, height: 22)
                }
                
                Text(window.appName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                if window.isMinimized {
                    Text("Gizli")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.18))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Body: Large App Icon & Window Title
            VStack(spacing: 12) {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
                }
                
                Text(window.title)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(Color.black.opacity(0.15))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.18)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.white.opacity(0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSelected
                        ? LinearGradient(colors: [Color.blue.opacity(0.95), Color.cyan.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected ? Color.blue.opacity(0.4) : Color.black.opacity(0.2),
            radius: isSelected ? 12 : 6,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isSelected)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            onHover(hovering)
        }
    }
}
