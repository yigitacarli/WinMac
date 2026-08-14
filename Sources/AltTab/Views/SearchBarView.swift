import SwiftUI

public struct SearchBarView: View {
    @Binding var text: String
    
    public init(text: Binding<String>) {
        self._text = text
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(text.isEmpty ? .secondary : .cyan)
                .font(.system(size: 13, weight: .semibold))
            
            TextField("Pencerelerde ara...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13, weight: .medium, design: .rounded))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    text.isEmpty
                        ? LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 1
                )
        )
    }
}
