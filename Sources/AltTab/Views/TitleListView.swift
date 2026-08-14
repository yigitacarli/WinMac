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
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.25)
                        : Color.white.opacity(0.04)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    isSelected
                        ? Color.accentColor.opacity(0.8)
                        : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
    }
}
