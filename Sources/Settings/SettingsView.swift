import SwiftUI
import AppKit

// MARK: - Navigation Tabs

public enum SettingsTab: String, CaseIterable, Identifiable {
    case rectangle = "rectangle"
    case linearMouse = "linearMouse"
    case swiftQuit = "swiftQuit"
    case altTab = "altTab"
    case windowsShortcuts = "windowsShortcuts"
    case about = "about"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .rectangle: return "Rectangle Pro"
        case .linearMouse: return "Linear Mouse"
        case .swiftQuit: return "SwiftQuit"
        case .altTab: return "AltTab"
        case .windowsShortcuts: return "Windows Kısayolları"
        case .about: return "Hakkında & İzinler"
        }
    }
    
    public var icon: String {
        switch self {
        case .rectangle: return "rectangle.split.2x1.fill"
        case .linearMouse: return "cursorarrow.rays"
        case .swiftQuit: return "xmark.app.fill"
        case .altTab: return "macwindow.on.rectangle"
        case .windowsShortcuts: return "keyboard.fill"
        case .about: return "info.circle.fill"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .rectangle: return .blue
        case .linearMouse: return .teal
        case .swiftQuit: return .red
        case .altTab: return .indigo
        case .windowsShortcuts: return .orange
        case .about: return .purple
        }
    }
}

// MARK: - Main Settings View

public struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var permissions = PermissionsManager.shared
    @State private var selectedTab: SettingsTab = .rectangle
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Sidebar Navigation
            VStack(alignment: .leading, spacing: 6) {
                // Header Brand
                HStack(spacing: 9) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("WinMac")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("v1.1 Native Suite")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 10)
                
                Divider()
                    .opacity(0.4)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                
                // Tab Items List
                VStack(spacing: 3) {
                    ForEach(SettingsTab.allCases) { tab in
                        SidebarButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Status pill at bottom
                HStack(spacing: 6) {
                    Circle()
                        .fill(permissions.hasAccessibilityPermission ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                    Text(permissions.hasAccessibilityPermission ? "Erişilebilirlik Aktif" : "İzin Bekleniyor")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .frame(width: 200)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
            
            Divider()
                .opacity(0.5)
            
            // MARK: - Main Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .rectangle:
                        RectangleProSettingsContent(settings: settings)
                    case .linearMouse:
                        LinearMouseSettingsContent(settings: settings)
                    case .swiftQuit:
                        SwiftQuitSettingsContent(settings: settings)
                    case .altTab:
                        AltTabSettingsContent(settings: settings)
                    case .windowsShortcuts:
                        WindowsShortcutsSettingsContent(settings: settings)
                    case .about:
                        AboutSettingsContent(settings: settings, permissions: permissions)
                    }
                }
                .padding(22)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
        }
        .frame(width: 760, height: 550)
    }
}

// MARK: - Sidebar Button Component

private struct SidebarButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : tab.tintColor)
                    .frame(width: 18)
                
                Text(tab.title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header & Group Box

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    let badge: String?
    
    init(title: String, subtitle: String, badge: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                        .foregroundColor(.accentColor)
                }
            }
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    
    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title.uppercased())
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(NSColor.separatorColor).opacity(0.35), lineWidth: 0.5)
                    )
            )
        }
    }
}

private struct SettingRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: () -> Trailing
    
    init(
        icon: String,
        iconColor: Color = .blue,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 5)
    }
}

private struct Keycap: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - 1. Rectangle Pro Tab

private struct RectangleProSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Rectangle Pro",
                subtitle: "Ekran kenarlarına sürükleyerek veya kısayollarla pencereleri anında hizalayın.",
                badge: "Orijinal Çekirdek"
            )
            
            SettingsCard(title: "Sürükle-Yasla (Aero Snap)") {
                SettingRow(
                    icon: "cursorarrow.motionlines",
                    iconColor: .blue,
                    title: "Sürükle-Yasla Önizlemesini Etkinleştir",
                    subtitle: "Pencereleri ekran kenarlarına veya köşelerine sürüklediğinizde yarı saydam önizleme gösterir."
                ) {
                    Toggle("", isOn: $settings.dragToSnapEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Pencereler Arası Boşluk (Gaps)")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text("\(Int(settings.snapWindowGaps)) px")
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.snapWindowGaps, in: 0...30, step: 2)
                }
                .padding(.vertical, 4)
            }
            
            SettingsCard(title: "Klavye Kısayolları & Döngü") {
                SettingRow(
                    icon: "keyboard",
                    iconColor: .indigo,
                    title: "Kısayol ile Hizalamayı Etkinleştir",
                    subtitle: "Option + Control tuş kombinasyonları ile pencereleri anında yerleştirir."
                ) {
                    Toggle("", isOn: $settings.snapShortcutsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .purple,
                    title: "Tekrarlanan Kısayollarda Boyut Döngüsü",
                    subtitle: "Aynı kısayola ard arda basıldığında pencereyi 1/2 ➔ 2/3 ➔ 1/3 oranlarında döngüye sokar."
                ) {
                    Toggle("", isOn: $settings.cycleRepeatedShortcuts)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ShortcutItem(keys: "⌥ ⌃ ← / →", desc: "Sol / Sağ Yarı (Döngülü)")
                    ShortcutItem(keys: "⌥ ⌃ ↑", desc: "Tam Ekran")
                    ShortcutItem(keys: "⌥ ⌃ ↓", desc: "Alt Yarı Ekran")
                    ShortcutItem(keys: "⌥ ⌃ Return", desc: "Tam Ekran")
                    ShortcutItem(keys: "⌥ ⌃ C", desc: "Merkeze Al (Center)")
                    ShortcutItem(keys: "⌥ ⌃ U / I", desc: "Sol Üst / Sağ Üst Çeyrek")
                    ShortcutItem(keys: "⌥ ⌃ J / K", desc: "Sol Alt / Sağ Alt Çeyrek")
                    ShortcutItem(keys: "⌥ ⌃ ⌘ Oklar", desc: "Diğer Ekrana Taşı")
                }
                .padding(.top, 4)
            }
        }
    }
}

private struct ShortcutItem: View {
    let keys: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 6) {
            Keycap(text: keys)
            Text(desc)
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer()
        }
    }
}

// MARK: - 2. Linear Mouse Tab

private struct LinearMouseSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Linear Mouse",
                subtitle: "Doğrusal ivme, donanım DPI hassasiyeti ve tekerlek yönü denetimi.",
                badge: "IOHID Sürücüsü"
            )
            
            SettingsCard(title: "İmleç İvmesi & Hız") {
                SettingRow(
                    icon: "speedometer",
                    iconColor: .teal,
                    title: "Doğrusal Fare İvmesi (1:1 Hassasiyet)",
                    subtitle: "macOS ivmelenme eğrisini sıfırlayarak sabit 1:1 net ve kesintisiz Windows tarzı fare kontrolü sağlar."
                ) {
                    Toggle("", isOn: $settings.disableMouseAcceleration)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Fare İmleç Hassasiyeti / Hızı (DPI)")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(String(format: "%.1fx", settings.mousePointerSensitivity))
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.mousePointerSensitivity, in: 0.5...3.0, step: 0.1)
                }
                .padding(.vertical, 4)
            }
            
            SettingsCard(title: "Tekerlek Kaydırma Yönü (Scroll Wheel)") {
                SettingRow(
                    icon: "computermouse",
                    iconColor: .blue,
                    title: "Dikey Kaydırma Yönünü Tersine Çevir",
                    subtitle: "Fiziksel fare tekerleğinin yönünü tersine çevirir. Trackpad doğal kaydırmada kalır ve jestlere dokunulmaz."
                ) {
                    Toggle("", isOn: $settings.invertMouseWheel)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "arrow.left.and.right",
                    iconColor: .purple,
                    title: "Yatay Kaydırma Yönünü Tersine Çevir",
                    subtitle: "Harici farelerin yatay tekerlek hareketini tersine çevirir."
                ) {
                    Toggle("", isOn: $settings.invertHorizontalScroll)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Kaydırma Hızı Çarpanı")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(String(format: "%.2fx", settings.scrollSpeedMultiplier))
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.scrollSpeedMultiplier, in: 0.5...4.0, step: 0.25)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 3. SwiftQuit Tab

private struct SwiftQuitSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "SwiftQuit",
                subtitle: "Son pencere kapatıldığında uygulamayı arka planda açık bırakmaz, otomatik sonlandırır.",
                badge: "Olay Odaklı"
            )
            
            SettingsCard(title: "Otomatik Çıkış Denetimi") {
                SettingRow(
                    icon: "xmark.app.fill",
                    iconColor: .red,
                    title: "Pencere Kapanınca Otomatik Çıkış Yap",
                    subtitle: "Bir uygulamanın son penceresini kırmızı 'X' ile kapattığınızda Dock'taki açık noktasını kaldırır ve uygulamayı kapatır."
                ) {
                    Toggle("", isOn: $settings.swiftQuitEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Kapanma Gecikmesi Süresi")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text("\(settings.swiftQuitDelaySeconds) saniye")
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settings.swiftQuitDelaySeconds) },
                        set: { settings.swiftQuitDelaySeconds = Int($0) }
                    ), in: 0...10, step: 1)
                }
                .padding(.vertical, 4)
            }
            
            SettingsCard(title: "Dokunulmazlık & Korumalı Uygulamalar") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aşağıdaki uygulama türleri asla otomatik kapatılmaz:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ProtectedBadge(icon: "gamecontroller.fill", text: "Oyunlar (LoL, Steam, Riot)")
                        ProtectedBadge(icon: "chevron.left.forwardslash.chevron.right", text: "IDE'ler (Antigravity, VSCode)")
                    }
                    
                    HStack(spacing: 8) {
                        ProtectedBadge(icon: "terminal.fill", text: "Terminaller")
                        ProtectedBadge(icon: "music.note", text: "Müzik & İletişim")
                    }
                    
                    Text("💡 Not: Sarı butonla simge durumuna küçültülen (Minimize) ve ⌘ Cmd + H ile gizlenen pencereler de asla kapatılmaz.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ProtectedBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
            Text(text)
                .font(.system(size: 11.5, weight: .medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

// MARK: - 4. AltTab Tab

private struct AltTabSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "AltTab",
                subtitle: "Windows tarzı zengin önizlemeli pencere değiştirici HUD arayüzü.",
                badge: "Z-Order Sıralaması"
            )
            
            SettingsCard(title: "Genel") {
                SettingRow(
                    icon: "macwindow.on.rectangle",
                    iconColor: .indigo,
                    title: "AltTab Değiştiriciyi Etkinleştir",
                    subtitle: "Klavyeden hızlı pencere geçiş HUD arayüzünü aktif eder."
                ) {
                    Toggle("", isOn: $settings.altTabEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "command",
                    iconColor: .blue,
                    title: "Tetikleyici Kısayol",
                    subtitle: "Arayüzü açmak için kullanılacak tuş kombinasyonu."
                ) {
                    Picker("", selection: $settings.switcherShortcut) {
                        ForEach(AltTabShortcut.allCases) { shortcut in
                            Text(shortcut.title).tag(shortcut)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "square.grid.2x2",
                    iconColor: .purple,
                    title: "Görünüm Stili",
                    subtitle: "Pencerelerin switcher üzerinde nasıl listeleneceği."
                ) {
                    Picker("", selection: $settings.switcherStyle) {
                        ForEach(SwitcherStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "display",
                    iconColor: .teal,
                    title: "Monitör Konumu",
                    subtitle: "Pencere seçicinin hangi ekranda açılacağı."
                ) {
                    Picker("", selection: $settings.displayMode) {
                        ForEach(SwitcherDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }
            }
            
            SettingsCard(title: "Klavye Gezinimi (HUD Açıkken)") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ShortcutItem(keys: "Tab / ⇧ Tab", desc: "Sonraki / Önceki Pencere")
                    ShortcutItem(keys: "← / →", desc: "Ok Tuşlarıyla Gezin")
                    ShortcutItem(keys: "W", desc: "Seçili Pencereyi Kapat")
                    ShortcutItem(keys: "Q", desc: "Seçili Uygulamadan Çık")
                    ShortcutItem(keys: "Return", desc: "Pencereye Odaklan")
                    ShortcutItem(keys: "Esc", desc: "HUD İptal Et")
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 5. Windows Shortcuts Tab

private struct WindowsShortcutsSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Windows Kısayolları & Pano",
                subtitle: "Ctrl+C, Ctrl+V kas hafızası eşlemesi, Option+V pano geçmişi ve sistem tuşları.",
                badge: "Kas Hafızası"
            )
            
            SettingsCard(title: "Ctrl Tuş Eşlemesi (Ctrl ➔ Command)") {
                SettingRow(
                    icon: "keyboard.fill",
                    iconColor: .orange,
                    title: "Ctrl Tuşlarını Command Olarak Eşle",
                    subtitle: "Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+Y, Ctrl+A, Ctrl+S kısayollarını macOS üzerinde aynen çalıştırır."
                ) {
                    Toggle("", isOn: $settings.ctrlToCmdRemapEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ShortcutItem(keys: "⌃ C / ⌃ V", desc: "Kopyala / Yapıştır")
                    ShortcutItem(keys: "⌃ X / ⌃ A", desc: "Kes / Tümünü Seç")
                    ShortcutItem(keys: "⌃ Z / ⌃ Y", desc: "Geri Al / Yinele")
                    ShortcutItem(keys: "⌃ S / ⌃ F", desc: "Kaydet / Bul")
                }
                .padding(.top, 4)
            }
            
            SettingsCard(title: "Pano Geçmişi (Option + V)") {
                SettingRow(
                    icon: "doc.on.clipboard.fill",
                    iconColor: .blue,
                    title: "Pano Geçmişini Etkinleştir",
                    subtitle: "⌥ Option + V ile kopyalanan metinleri listeleyin, arayın ve tek tıkla yapıştırın."
                ) {
                    Toggle("", isOn: $settings.clipboardHistoryEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "list.number",
                    iconColor: .secondary,
                    title: "Maksimum Pano Kayıt Sayısı",
                    subtitle: "Hafızada saklanacak geçmiş kopyalama sayısı."
                ) {
                    Picker("", selection: $settings.maxClipboardItems) {
                        Text("25 Öğe").tag(25)
                        Text("50 Öğe").tag(50)
                        Text("100 Öğe").tag(100)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
            
            SettingsCard(title: "Hızlı Sistem Kısayolları") {
                SettingRow(
                    icon: "lock.fill",
                    iconColor: .gray,
                    title: "Win + L (⌥ Option + ⌘ Command + L) ile Ekran Kilitle",
                    subtitle: "Windows'taki Win+L gibi ekranı anında kilitler / uyku moduna alır."
                ) {
                    Toggle("", isOn: $settings.winLToLockEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 6)
                
                SettingRow(
                    icon: "gauge.with.needle.fill",
                    iconColor: .green,
                    title: "Ctrl + Shift + Esc ➔ Etkinlik Monitörü",
                    subtitle: "Windows Görev Yöneticisi kısayoluyla macOS Etkinlik Monitörü'nü anında açar."
                ) {
                    Toggle("", isOn: $settings.ctrlShiftEscTaskManager)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }
}

// MARK: - 6. About & Permissions Tab

private struct AboutSettingsContent: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Hakkında & İzinler",
                subtitle: "WinMac sürüm bilgileri, sistem erişilebilirlik izinleri ve genel ayarlar."
            )
            
            SettingsCard(title: "Sistem İzinleri") {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(permissions.hasAccessibilityPermission ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 17))
                            .foregroundColor(permissions.hasAccessibilityPermission ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(permissions.hasAccessibilityPermission ? "Erişilebilirlik İzni Aktif" : "Erişilebilirlik İzni Gerekli")
                            .font(.system(size: 13.5, weight: .semibold))
                        Text(permissions.hasAccessibilityPermission ? "Pencere yönetimi, fare ve kısayollar sorunsuz çalışıyor." : "Pencere yaslama ve fare denetimi için Sistem Ayarları'ndan izin vermeniz gerekir.")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !permissions.hasAccessibilityPermission {
                        Button("İzni Aç") {
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
            
            SettingsCard(title: "Görünürlük & Başlangıç") {
                SettingRow(
                    icon: "dock.rectangle",
                    iconColor: .purple,
                    title: "Dock Çubuğunda Göster",
                    subtitle: "WinMac simgesinin macOS Dock çubuğunda görünmesini sağlar."
                ) {
                    Toggle("", isOn: $settings.showInDock)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            
            SettingsCard(title: "Uygulama Bilgisi") {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("WinMac v1.1")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Rectangle Pro, Linear Mouse, SwiftQuit, AltTab ve Windows Kısayollarını tek bir hafif yerel Swift uygulamasında birleştiren sistem aracı.")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com/yigitacarli/WinMac")!)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.vertical, 4)
            }
        }
    }
}
