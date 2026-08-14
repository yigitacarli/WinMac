import SwiftUI

public struct ClipboardHUDView: View {
    @ObservedObject var manager = ClipboardManager.shared
    public var onSelect: ((ClipboardItem) -> Void)?
    
    public init(onSelect: ((ClipboardItem) -> Void)? = nil) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 15))
                
                Text("Pano Geçmişi (⌥ + V)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !manager.items.isEmpty {
                    Button(action: { manager.clearAll() }) {
                        Text("Temizle")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            
            // Search Input
            SearchBarView(text: $manager.searchText)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // List of clips
            let list = manager.filteredItems
            if list.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Henüz kopyalanmış öğe yok")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 6) {
                        ForEach(list) { item in
                            ClipboardRowView(
                                item: item,
                                onTap: {
                                    onSelect?(item)
                                },
                                onDelete: {
                                    manager.removeItem(item)
                                }
                            )
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 340)
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Footer
            HStack {
                Text("↵ / Tıkla: Yapıştır")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Esc: Kapat")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
        }
        .frame(width: 380)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, y: 8)
    }
}

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "text.alignleft")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.content)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(timeString(from: item.timestamp))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(perform: onTap)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
