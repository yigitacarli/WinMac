import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var permissions = PermissionsManager.shared
    @State private var selectedTab: SettingsTab = .snap
    
    public init() {}
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case snap = "Pencere Yaslama"
        case switcher = "Pencere Geçişi"
        case mouse = "Fare & Kaydırma"
        case keyboard = "Klavye & Pano"
        case autoquit = "Otomatik Çıkış"
        case general = "Genel & İzinler"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .snap: return "rectangle.split.2x1"
            case .switcher: return "macwindow.on.rectangle"
            case .mouse: return "computermouse"
            case .keyboard: return "keyboard"
            case .autoquit: return "xmark.circle"
            case .general: return "gearshape"
            }
        }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar Navigation
            VStack(alignment: .leading, spacing: 14) {
                // App Brand Header
                HStack(spacing: 10) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 30, height: 30)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("WinMac")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text("v4.3.0")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator dot
                    Circle()
                        .fill(permissions.hasAccessibilityPermission ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                        .help(permissions.hasAccessibilityPermission ? "Erişilebilirlik Aktif" : "Erişilebilirlik İzni Gerekli")
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                
                Divider()
                    .opacity(0.6)
                
                // Sidebar Navigation Items
                VStack(spacing: 3) {
                    ForEach(SettingsTab.allCases) { tab in
                        SidebarButton(
                            title: tab.rawValue,
                            icon: tab.icon,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Permission Warning in Sidebar if missing
                if !permissions.hasAccessibilityPermission {
                    Button(action: { permissions.openAccessibilitySettings() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 11))
                            Text("İzin Ver")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
                
                // Bottom Utility Links
                HStack {
                    Button(action: {
                        if let url = URL(string: "https://github.com/yigitacarli/WinMac") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("GitHub")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { NSApp.terminate(nil) }) {
                        Text("Çıkış")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(width: 190)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            
            Divider()
                .opacity(0.6)
            
            // MARK: - Right Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedTab {
                    case .snap:
                        SnapSettingsContent(settings: settings)
                    case .switcher:
                        SwitcherSettingsContent(settings: settings)
                    case .mouse:
                        MouseSettingsContent(settings: settings)
                    case .keyboard:
                        KeyboardSettingsContent(settings: settings)
                    case .autoquit:
                        AutoQuitSettingsContent(settings: settings)
                    case .general:
                        GeneralSettingsContent(settings: settings, permissions: permissions)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        }
        .frame(minWidth: 640, minHeight: 440)
    }
}

// MARK: - 1. Snap Settings (Rectangle Aero Snap & HotKeys)

private struct SnapSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Pencere Yaslama & Düzenleme",
                subtitle: "Ekran kenarlarına sürükleyerek (Aero Snap) veya klavye kısayollarıyla pencereleri hizalayın."
            )
            
            SettingsGroup(title: "Sürükle-Yasla (Aero Snap)") {
                ModernRow(
                    icon: "rectangle.split.2x1",
                    title: "Sürükleyerek Yaslama (Aero Snap)",
                    subtitle: "Pencereyi ekran kenarlarına veya 4 köşesine sürükleyince şeffaf önizleme kutusu belirir ve bırakıldığında otomatik yaslanır.",
                    content: {
                        Toggle("", isOn: $settings.dragToSnapEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "square.dashed",
                    title: "Pencere Kenar Boşlukları (Gaps)",
                    subtitle: "Yaslanan pencereler ve ekran kenarı arasında piksel boşluğu bırakır.",
                    content: {
                        HStack(spacing: 8) {
                            Text("\(Int(settings.snapWindowGaps)) px")
                                .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Stepper("", value: $settings.snapWindowGaps, in: 0...32, step: 4)
                                .labelsHidden()
                        }
                    }
                )
            }
            
            SettingsGroup(title: "Klavye Kısayolları") {
                ModernRow(
                    icon: "keyboard",
                    title: "Global Yaslama Kısayolları",
                    subtitle: "Option + Control ve Ok tuşları ile pencereleri doğrudan konumlandırın.",
                    content: {
                        Toggle("", isOn: $settings.snapShortcutsEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Tekrarlayan Kısayol Oran Döngüsü",
                    subtitle: "Aynı kısayola art arda basıldığında 1/2 -> 2/3 -> 1/3 oranları arasında döner.",
                    content: {
                        Toggle("", isOn: $settings.cycleRepeatedShortcuts)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                // Shortcut Cheat Sheet
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kısayol Referansı")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                        ShortcutRow(key: "⌥ ⌃ ← / →", desc: "Sol / Sağ Yarı (Döngülü)")
                        ShortcutRow(key: "⌥ ⌃ ↑", desc: "Tam Ekran (Maximize)")
                        ShortcutRow(key: "⌥ ⌃ ↓", desc: "Alt Yarı Ekran")
                        ShortcutRow(key: "⌥ ⌃ Return", desc: "Tam Ekran")
                        ShortcutRow(key: "⌥ ⌃ C", desc: "Merkeze Al")
                        ShortcutRow(key: "⌥ ⌃ U / I", desc: "Sol Üst / Sağ Üst Çeyrek")
                        ShortcutRow(key: "⌥ ⌃ J / K", desc: "Sol Alt / Sağ Alt Çeyrek")
                        ShortcutRow(key: "⌥ ⌃ ⌘ Oklar", desc: "Diğer Ekrana Taşı")
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - 2. Switcher Settings (Alt + Tab)

private struct SwitcherSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Pencere Değiştirici (Alt + Tab)",
                subtitle: "Windows tarzı zengin pencere switcher arayüzü ve hızlı klavye gezinimi."
            )
            
            SettingsGroup(title: "Genel") {
                ModernRow(
                    icon: "macwindow.on.rectangle",
                    title: "Pencere Değiştiriciyi Etkinleştir",
                    subtitle: "Klavyeden hızlı pencere geçiş HUD arayüzünü aktif eder.",
                    content: {
                        Toggle("", isOn: $settings.altTabEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "command",
                    title: "Tetikleyici Kısayol",
                    subtitle: "Arayüzü açmak için kullanılacak tuş kombinasyonu.",
                    content: {
                        Picker("", selection: $settings.switcherShortcut) {
                            ForEach(AltTabShortcut.allCases) { shortcut in
                                Text(shortcut.title).tag(shortcut)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 170)
                    }
                )
            }
            
            SettingsGroup(title: "Görünüm & Davranış") {
                ModernRow(
                    icon: "square.grid.2x2",
                    title: "Görünüm Stili",
                    subtitle: "Switcher arayüzünde pencerelerin sunulma biçimi.",
                    content: {
                        Picker("", selection: $settings.switcherStyle) {
                            ForEach(SwitcherStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 170)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "display",
                    title: "Gösterilecek Ekran",
                    subtitle: "Pencere değiştirici HUD'ının açılacağı ekran konumu.",
                    content: {
                        Picker("", selection: $settings.displayMode) {
                            ForEach(SwitcherDisplayMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 170)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "magnifyingglass",
                    title: "Canlı Başlık Araması",
                    subtitle: "Arayüz açıkken klavyeden harf yazarak pencereleri anında filtreler.",
                    content: {
                        Toggle("", isOn: $settings.searchFilterEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
            }
        }
    }
}

// MARK: - 3. Mouse & Scroll Settings

private struct MouseSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Fare & Kaydırma Denetimi",
                subtitle: "Harici fare tekerlek yönü ayrımı, Windows tarzı doğrusal ivme ve tekerlek tuş modifikatörleri."
            )
            
            SettingsGroup(title: "Tekerlek Yönü & Ayrımı") {
                ModernRow(
                    icon: "computermouse",
                    title: "Harici Fare için Standart Yön (Ters Kaydırma)",
                    subtitle: "Tekerlek aşağı çevrildiğinde sayfa aşağı kayar. Trackpad doğal kaydırmada kalır ve jestlere dokunulmaz.",
                    content: {
                        Toggle("", isOn: $settings.invertMouseWheel)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "arrow.left.and.right",
                    title: "Yatay Kaydırma Yönünü Ters Çevir",
                    subtitle: "Harici farelerin yatay tekerlek kaydırmasını tersine çevirir.",
                    content: {
                        Toggle("", isOn: $settings.invertHorizontalScroll)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
            }
            
            SettingsGroup(title: "İmleç Hızı & İvme (Windows Hissiyatı)") {
                ModernRow(
                    icon: "speedometer",
                    title: "Doğrusal Fare İvmesi (1:1 Hassasiyet)",
                    subtitle: "macOS ivmelenme eğrisini sıfırlayarak Windows'taki gibi sabit 1:1 doğrusal ve net fare kontrolü sağlar.",
                    content: {
                        Toggle("", isOn: $settings.disableMouseAcceleration)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Fare İmleç Hassasiyeti / Hızı", systemImage: "cursorarrow.rays")
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text(String(format: "%.1fx", settings.mousePointerSensitivity))
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.mousePointerSensitivity, in: 0.5...2.5, step: 0.1)
                }
                
                Divider().opacity(0.5)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Kaydırma Hızı Çarpanı", systemImage: "arrow.up.and.down")
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text(String(format: "%.2fx", settings.scrollSpeedMultiplier))
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.scrollSpeedMultiplier, in: 0.5...3.0, step: 0.25)
                }
            }
            
            SettingsGroup(title: "Tekerlek Modifikatörleri") {
                ModernRow(
                    icon: "plus.magnifyingglass",
                    title: "⌘ + Tekerlek: Yakınlaştır / Uzaklaştır (Zoom)",
                    subtitle: "Tarayıcılarda ve belgelerde sayfayı yakınlaştırır.",
                    content: {
                        Toggle("", isOn: $settings.cmdZoomScrollEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "arrow.left.and.right",
                    title: "Shift + Tekerlek: Yatay Kaydırma",
                    subtitle: "Tekerlek dikey çevrilirken sayfayı sağa/sola kaydırır.",
                    content: {
                        Toggle("", isOn: $settings.shiftHorizontalScrollEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "hare",
                    title: "Option + Tekerlek: 3x Hızlı Kaydırma",
                    subtitle: "Uzun dökümanlarda süper hızlı kaydırma sağlar.",
                    content: {
                        Toggle("", isOn: $settings.optionFastScrollEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "tortoise",
                    title: "Control + Tekerlek: 0.3x Hassas Kaydırma",
                    subtitle: "Piksel piksel kontrollü yavaş kaydırma sağlar.",
                    content: {
                        Toggle("", isOn: $settings.ctrlSlowScrollEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
            }
        }
    }
}

// MARK: - 4. Keyboard & Clipboard Settings

private struct KeyboardSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Klavye Kısayolları & Pano Geçmişi",
                subtitle: "Evrensel Windows kısayolları ve aranabilir pano geçmişi."
            )
            
            SettingsGroup(title: "Klavye Eşleme") {
                ModernRow(
                    icon: "keyboard",
                    title: "Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+Y, Ctrl+A",
                    subtitle: "Evrensel kopyalama, yapıştırma, geri/ileri alma ve tümünü seçme tuşlarını Cmd'ye yönlendirir.",
                    content: {
                        Toggle("", isOn: $settings.ctrlToCmdRemapEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "lock",
                    title: "Option + L (⌥ + L) ile Ekranı Kilitle",
                    subtitle: "Windows tarzı tek tuşla ekranı anında kilitler.",
                    content: {
                        Toggle("", isOn: $settings.winLToLockEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "chart.bar",
                    title: "Ctrl + Shift + Esc ile Etkinlik Monitörü",
                    subtitle: "macOS Etkinlik Monitörünü doğrudan başlatır.",
                    content: {
                        Toggle("", isOn: $settings.ctrlShiftEscTaskManager)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
            }
            
            SettingsGroup(title: "Pano Geçmişi (Option + V)") {
                ModernRow(
                    icon: "doc.on.clipboard",
                    title: "Pano Geçmişini Etkinleştir",
                    subtitle: "Option + V (⌥ + V) kısayolu ile açılan aranabilir pano listesi.",
                    content: {
                        Toggle("", isOn: $settings.clipboardHistoryEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                if settings.clipboardHistoryEnabled {
                    Divider().opacity(0.5)
                    
                    ModernRow(
                        icon: "list.number",
                        title: "Maksimum Kayıt Sayısı",
                        subtitle: "Hafızada saklanacak son kopyalanan öğe adedi.",
                        content: {
                            HStack(spacing: 8) {
                                Text("\(settings.maxClipboardItems)")
                                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Stepper("", value: $settings.maxClipboardItems, in: 10...200, step: 10)
                                    .labelsHidden()
                            }
                        }
                    )
                    
                    Divider().opacity(0.5)
                    
                    HStack {
                        Spacer()
                        Button(action: { ClipboardManager.shared.clearAll() }) {
                            Label("Panoyu Temizle", systemImage: "trash")
                                .font(.system(size: 11.5))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - 5. AutoQuit Settings (SwiftQuit)

private struct AutoQuitSettingsContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Otomatik Çıkış (SwiftQuit)",
                subtitle: "Son pencere kapandığında uygulamanın arka planda asılı kalmasını engelleyip tamamen sonlandırın."
            )
            
            SettingsGroup(title: "Genel") {
                ModernRow(
                    icon: "xmark.circle",
                    title: "Son Pencere Kapatıldığında Çık",
                    subtitle: "Kırmızı 'X' butonuyla veya Cmd+W ile son pencere kapandığında uygulamayı sonlandırır.",
                    content: {
                        Toggle("", isOn: $settings.swiftQuitEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                
                Divider().opacity(0.5)
                
                ModernRow(
                    icon: "timer",
                    title: "Kapanma Gecikmesi",
                    subtitle: "Uygulama sonlandırılmadan önceki bekleme süresi.",
                    content: {
                        Picker("", selection: $settings.swiftQuitDelaySeconds) {
                            Text("Anında (0s)").tag(0)
                            Text("1 Saniye").tag(1)
                            Text("2 Saniye").tag(2)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                )
            }
            
            // Helpful note
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                Text("Sarı küçültme (-) butonuyla Dock'a alınan veya Cmd+H ile gizlenen uygulamalar korunur ve kapatılmaz.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(nsColor: .separatorColor).opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - 6. General & Permissions Settings

private struct GeneralSettingsContent: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Genel Ayarlar & İzinler",
                subtitle: "Uygulama davranışları ve sistem yetkileri."
            )
            
            SettingsGroup(title: "Sistem İzinleri") {
                HStack(spacing: 12) {
                    Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(permissions.hasAccessibilityPermission ? .green : .orange)
                        .font(.system(size: 22))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Erişilebilirlik İzni")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Pencereleri yönetmek, yaslamak ve kısayolları dinlemek için gereklidir.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if permissions.hasAccessibilityPermission {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Etkin")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)
                    } else {
                        Button("İzin Ver") {
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            SettingsGroup(title: "Uygulama") {
                ModernRow(
                    icon: "dock.rectangle",
                    title: "Dock'ta Göster",
                    subtitle: "WinMac simgesinin Dock üzerinde görünmesini sağlar.",
                    content: {
                        Toggle("", isOn: $settings.showInDock)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
            }
            
            SettingsGroup(title: "Hakkında") {
                HStack(spacing: 12) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WinMac — macOS Verimlilik Paketi")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text("Sürüm 4.3.0 • Swift 6 & macOS 14+")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Reusable UI Components

private struct HeaderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
            Text(subtitle)
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 2)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 2)
            
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.8)
            )
        }
    }
}

private struct ModernRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            content
        }
    }
}

private struct ShortcutRow: View {
    let key: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(4)
            
            Text(desc)
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

private struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? Color.accentColor
                    : Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
