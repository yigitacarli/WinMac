import SwiftUI
import AppKit

// MARK: - Navigation Tabs

public enum SettingsTab: String, CaseIterable, Identifiable {
    case snap = "snap"
    case mouse = "mouse"
    case switcher = "switcher"
    case tools = "tools"
    case general = "general"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .snap: return "Pencere Yaslama"
        case .mouse: return "Fare & İmleç"
        case .switcher: return "Alt + Tab"
        case .tools: return "Pano & Kısayollar"
        case .general: return "Genel & İzinler"
        }
    }
    
    public var icon: String {
        switch self {
        case .snap: return "rectangle.split.2x1"
        case .mouse: return "cursorarrow.rays"
        case .switcher: return "macwindow.on.rectangle"
        case .tools: return "doc.on.clipboard"
        case .general: return "gearshape"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .snap: return .blue
        case .mouse: return .teal
        case .switcher: return .indigo
        case .tools: return .orange
        case .general: return .gray
        }
    }
}

// MARK: - Main Settings View

public struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var permissions = PermissionsManager.shared
    @State private var selectedTab: SettingsTab = .snap
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Sidebar
            VStack(alignment: .leading, spacing: 6) {
                // App Brand
                HStack(spacing: 9) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("WinMac")
                            .font(.system(size: 13, weight: .bold))
                        Text("v1.1")
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)
                
                Divider()
                    .opacity(0.4)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                
                // Tab Items
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
            }
            .frame(width: 185)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
            
            Divider()
                .opacity(0.5)
            
            // MARK: - Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .snap:
                        SnapSettingsContent(settings: settings)
                    case .mouse:
                        MouseSettingsContent(settings: settings)
                    case .switcher:
                        SwitcherSettingsContent(settings: settings)
                    case .tools:
                        ToolsSettingsContent(settings: settings)
                    case .general:
                        GeneralSettingsContent(settings: settings, permissions: permissions)
                    }
                }
                .padding(20)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
        .frame(width: 670, height: 480)
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
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
            Text(subtitle)
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 2)
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
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
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
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Keyboard Keycap

private struct Keycap: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - 1. Window Snap Tab

private struct SnapSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Pencere Yaslama",
                subtitle: "Ekran kenarlarına sürükleyerek veya kısayollarla pencereleri anında hizalayın."
            )
            
            SettingsCard(title: "Sürükle-Yasla") {
                SettingRow(
                    icon: "cursorarrow.motionlines",
                    iconColor: .blue,
                    title: "Sürükle-Yasla Önizlemesini Etkinleştir",
                    subtitle: "Pencereleri ekran kenarlarına veya köşelerine sürüklediğinizde önizleme kutusu gösterir."
                ) {
                    Toggle("", isOn: $settings.dragToSnapEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Pencereler Arası Boşluk (Gaps)")
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text("\(Int(settings.snapWindowGaps)) px")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.snapWindowGaps, in: 0...24, step: 2)
                }
                .padding(.vertical, 4)
            }
            
            SettingsCard(title: "Klavye Kısayolları") {
                SettingRow(
                    icon: "keyboard",
                    iconColor: .indigo,
                    title: "Kısayol ile Hizalamayı Etkinleştir",
                    subtitle: "Option + Control + Yön Tuşları ile pencereleri anında yarıya, çeyreğe veya tam ekrana hizalar."
                ) {
                    Toggle("", isOn: $settings.snapShortcutsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                    ShortcutItem(keys: "⌥ ⌃ ← / →", desc: "Sol / Sağ Yarı (Döngülü)")
                    ShortcutItem(keys: "⌥ ⌃ ↑", desc: "Tam Ekran")
                    ShortcutItem(keys: "⌥ ⌃ ↓", desc: "Alt Yarı Ekran")
                    ShortcutItem(keys: "⌥ ⌃ Return", desc: "Tam Ekran")
                    ShortcutItem(keys: "⌥ ⌃ C", desc: "Merkeze Al")
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
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer()
        }
    }
}

// MARK: - 2. Mouse & Pointer Tab

private struct MouseSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Fare & İmleç Denetimi",
                subtitle: "Doğrusal ivme, donanım DPI hassasiyeti ve tekerlek yönü denetimi."
            )
            
            SettingsCard(title: "İmleç İvmesi & Hız") {
                SettingRow(
                    icon: "speedometer",
                    iconColor: .teal,
                    title: "Doğrusal Fare İvmesi (1:1 Hassasiyet)",
                    subtitle: "macOS ivmelenme eğrisini sıfırlayarak sabit 1:1 net ve kesintisiz fare kontrolü sağlar."
                ) {
                    Toggle("", isOn: $settings.disableMouseAcceleration)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Fare İmleç Hassasiyeti / Hızı")
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text(String(format: "%.1fx", settings.mousePointerSensitivity))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.mousePointerSensitivity, in: 0.5...2.5, step: 0.1)
                }
                .padding(.vertical, 4)
            }
            
            SettingsCard(title: "Tekerlek Kaydırma Yönü") {
                SettingRow(
                    icon: "computermouse",
                    iconColor: .blue,
                    title: "Fare Tekerlek Yönünü Tersine Çevir",
                    subtitle: "Fare tekerleğinin dikey kaydırma yönünü tersine çevirir. Trackpad doğal kaydırmada kalır ve jestlere dokunulmaz."
                ) {
                    Toggle("", isOn: $settings.invertMouseWheel)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                SettingRow(
                    icon: "arrow.left.and.right",
                    iconColor: .purple,
                    title: "Yatay Kaydırma Yönünü Tersine Çevir",
                    subtitle: "Harici farelerin yatay tekerlek kaydırmasını tersine çevirir."
                ) {
                    Toggle("", isOn: $settings.invertHorizontalScroll)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Kaydırma Hızı Çarpanı")
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text(String(format: "%.2fx", settings.scrollSpeedMultiplier))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.scrollSpeedMultiplier, in: 0.5...3.0, step: 0.25)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 3. Alt + Tab Switcher Tab

private struct SwitcherSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Pencere Değiştirici (Alt + Tab)",
                subtitle: "Gelişmiş pencere switcher arayüzü ve hızlı klavye gezinimi."
            )
            
            SettingsCard(title: "Genel") {
                SettingRow(
                    icon: "macwindow.on.rectangle",
                    iconColor: .indigo,
                    title: "Pencere Değiştiriciyi Etkinleştir",
                    subtitle: "Klavyeden hızlı pencere geçiş HUD arayüzünü aktif eder."
                ) {
                    Toggle("", isOn: $settings.altTabEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
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
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                SettingRow(
                    icon: "display",
                    iconColor: .purple,
                    title: "Görünüm Konumu",
                    subtitle: "Pencere seçicinin hangi monitörde açılacağı."
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
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                SettingRow(
                    icon: "magnifyingglass",
                    iconColor: .green,
                    title: "Canlı Başlık Araması",
                    subtitle: "Arayüz açıkken klavyeden harf yazarak pencereleri anında filtreler."
                ) {
                    Toggle("", isOn: $settings.searchFilterEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }
}

// MARK: - 4. Tools & Shortcuts Tab

private struct ToolsSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Pano & Kısayollar",
                subtitle: "Option + V pano geçmişi, otomatik çıkış ve sistem kısayolları."
            )
            
            SettingsCard(title: "Pano Geçmişi") {
                SettingRow(
                    icon: "doc.on.clipboard",
                    iconColor: .orange,
                    title: "Pano Geçmişini Etkinleştir",
                    subtitle: "⌥ Option + V ile kopyalanan metinleri arayın ve tek tuşla yapıştırın."
                ) {
                    Toggle("", isOn: $settings.clipboardHistoryEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                SettingRow(
                    icon: "list.number",
                    iconColor: .secondary,
                    title: "Maksimum Kayıt Sayısı",
                    subtitle: "Hafızada tutulacak maksimum pano öğesi."
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
            
            SettingsCard(title: "Otomatik Çıkış & Kısayollar") {
                SettingRow(
                    icon: "xmark.circle",
                    iconColor: .red,
                    title: "Pencere Kapanınca Otomatik Çıkış",
                    subtitle: "Bir uygulamanın son penceresi kapandığında uygulamayı arka planda açık bırakmaz, otomatik olarak sonlandırır."
                ) {
                    Toggle("", isOn: $settings.swiftQuitEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                SettingRow(
                    icon: "lock",
                    iconColor: .gray,
                    title: "Win + L ile Ekranı Kilitle",
                    subtitle: "⌥ Option + ⌘ Command + L kısayolu ile ekranı anında kilitler."
                ) {
                    Toggle("", isOn: $settings.winLToLockEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Divider().opacity(0.4).padding(.vertical, 4)
                
                SettingRow(
                    icon: "gauge.with.needle",
                    iconColor: .blue,
                    title: "Ctrl + Shift + Esc -> Etkinlik Monitörü",
                    subtitle: "Etkinlik Monitörü'nü anında açmak için hızlı sistem kısayolu."
                ) {
                    Toggle("", isOn: $settings.ctrlShiftEscTaskManager)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }
}

// MARK: - 5. General & Permissions Tab

private struct GeneralSettingsContent: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Genel & Sistem İzinleri",
                subtitle: "Uygulama davranışları ve sistem erişilebilirlik izinleri."
            )
            
            SettingsCard(title: "Sistem İzinleri") {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(permissions.hasAccessibilityPermission ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(permissions.hasAccessibilityPermission ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(permissions.hasAccessibilityPermission ? "Erişilebilirlik İzni Verildi" : "Erişilebilirlik İzni Gerekli")
                            .font(.system(size: 13, weight: .semibold))
                        Text(permissions.hasAccessibilityPermission ? "Pencere yönetimi ve fare kontrolleri etkin." : "Pencere yaslama ve fare denetimi için Sistem Ayarları'ndan izin vermeniz gerekir.")
                            .font(.system(size: 11))
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
            
            SettingsCard(title: "Görünürlük") {
                SettingRow(
                    icon: "dock.rectangle",
                    iconColor: .purple,
                    title: "Dock'ta Göster",
                    subtitle: "WinMac simgesinin macOS Dock çubuğunda görünmesini sağlar."
                ) {
                    Toggle("", isOn: $settings.showInDock)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            
            SettingsCard(title: "Hakkında") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WinMac")
                            .font(.system(size: 13, weight: .semibold))
                        Text("macOS için gelişmiş pencere yönetimi, fare denetimi ve verimlilik araçları.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com/yigitacarli/WinMac")!)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.vertical, 4)
            }
        }
    }
}
