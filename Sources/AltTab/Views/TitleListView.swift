import SwiftUI

public struct TitleListView: View {
    @ObservedObject var state: AltTabState
    let windows: [WindowModel]
    
    public init(state: AltTabState, windows: [WindowModel]) {
        self.state = state
        self.windows = windows
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                    TitleListRow(
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
        .frame(maxHeight: 410)
    }
}

private struct TitleListRow: View {
    let window: WindowModel
    let isSelected: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            if let icon = window.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, y: 1)
            } else {
                Image(systemName: "macwindow")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
            }
            
            Text(window.appName)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 150, alignment: .leading)
            
            Text(window.title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [Color.blue.opacity(0.45), Color.blue.opacity(0.25)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white.opacity(0.04))
                    )
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1.5
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
        )
        .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 6, y: 2)
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
    }
}
