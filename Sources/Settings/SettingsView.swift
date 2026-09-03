import SwiftUI
import AppKit

// MARK: - Design Tokens
//
// Solid, layered native materials only — no blur/vibrancy gimmicks. Depth comes from
// hairline-separated cards on the standard window background, SF Symbols in tinted squircle
// tiles, and generous spacing.

private enum Design {
    static let cardInset: CGFloat = 18
    static let cardCorner: CGFloat = 12
    static let rowMinHeight: CGFloat = 42

    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.55)

    static func tileColor(_ pane: SettingsPane) -> Color {
        switch pane {
        case .general: return Color(nsColor: .systemGray)
        case .windowManagement: return Color(nsColor: .systemBlue)
        case .appSwitcher: return Color(nsColor: .systemIndigo)
        case .mouseControl: return Color(nsColor: .systemPurple)
        case .keyboardShortcuts: return Color(nsColor: .systemTeal)
        case .autoQuit: return Color(nsColor: .systemOrange)
        }
    }
}

// MARK: - Sidebar Sections

public enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case general
    case windowManagement
    case appSwitcher
    case mouseControl
    case keyboardShortcuts
    case autoQuit

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .general: return "Genel"
        case .windowManagement: return "Pencere Yönetimi"
        case .appSwitcher: return "Pencere Değiştirici"
        case .mouseControl: return "Fare"
        case .keyboardShortcuts: return "Klavye Kısayolları"
        case .autoQuit: return "Otomatik Çıkış"
        }
    }

    public var subtitle: String {
        switch self {
        case .general: return "Başlangıç ve izinler"
        case .windowManagement: return "Yaslama ve kısayollar"
        case .appSwitcher: return "Görünüm ve davranış"
        case .mouseControl: return "İvme, hız, cihaz bilgisi"
        case .keyboardShortcuts: return "Eşleştirmeler"
        case .autoQuit: return "Arka plan temizliği"
        }
    }

    public var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .windowManagement: return "rectangle.split.2x1.fill"
        case .appSwitcher: return "square.stack.3d.up.fill"
        case .mouseControl: return "computermouse.fill"
        case .keyboardShortcuts: return "command.square.fill"
        case .autoQuit: return "power.dotted"
        }
    }
}

// MARK: - Root View

public struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var permissions = PermissionsManager.shared
    @State private var selectedPane: SettingsPane = .general

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(width: 780, height: 560)
    }

    private var sidebar: some View {
        List(selection: $selectedPane) {
            ForEach(SettingsPane.allCases) { pane in
                Button {
                    selectedPane = pane
                } label: {
                    SidebarRow(pane: pane, isSelected: selectedPane == pane)
                }
                .buttonStyle(.plain)
                .tag(pane)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 210, ideal: 224, max: 260)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 7) {
                Circle()
                    .fill(permissions.hasAccessibilityPermission ? Color(nsColor: .systemGreen) : Color(nsColor: .systemOrange))
                    .frame(width: 8, height: 8)
                Text(permissions.hasAccessibilityPermission ? "İzinler tamam" : "Erişilebilirlik izni gerekli")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.leading, 20)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch selectedPane {
                case .general:
                    GeneralPane(settings: settings, permissions: permissions)
                case .windowManagement:
                    WindowManagementPane(settings: settings)
                case .appSwitcher:
                    AppSwitcherPane(settings: settings)
                case .mouseControl:
                    MouseControlPane(settings: settings)
                case .keyboardShortcuts:
                    KeyboardShortcutsPane(settings: settings)
                case .autoQuit:
                    AutoQuitPane(settings: settings)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Design.windowBackground)
        .navigationTitle(selectedPane.title)
    }
}

private struct SidebarRow: View {
    let pane: SettingsPane
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Design.tileColor(pane).gradient)
                .frame(width: 27, height: 27)
                .overlay(
                    Image(systemName: pane.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(pane.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.85))
                Text(pane.subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(isSelected ? Color.secondary : Color.secondary.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Building Blocks

/// A grouped section: optional caption above, solid card, optional footnote below.
struct SettingsCard<Content: View>: View {
    let header: String?
    let footer: String?
    @ViewBuilder let content: () -> Content

    init(header: String? = nil, footer: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let header {
                Text(header.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Design.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Design.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Design.cardCorner, style: .continuous)
                    .strokeBorder(Design.separator, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

            if let footer {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Standard row: leading title (+optional subtitle), trailing control. Rows inside a card get
/// automatic hairline dividers via RowGroup.
struct SettingRow<Control: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let control: () -> Control

    init(_ title: String, subtitle: String? = nil, @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.control = control
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            control()
        }
        .padding(.horizontal, Design.cardInset)
        .padding(.vertical, 9)
        .frame(minHeight: Design.rowMinHeight)
    }
}

/// Vertical separator between consecutive rows inside one card.
struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Design.separator)
            .frame(height: 1)
            .padding(.leading, Design.cardInset)
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        SettingRow(title, subtitle: subtitle) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

struct PickerRow<Value: Hashable>: View {
    let title: String
    let subtitle: String?
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    init(_ title: String, subtitle: String? = nil, selection: Binding<Value>, options: [Value], label: @escaping (Value) -> String) {
        self.title = title
        self.subtitle = subtitle
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        SettingRow(title, subtitle: subtitle) {
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 230)
        }
    }
}

/// Full-width slider row: label + live value chip on top, track underneath.
struct SliderRow: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    init(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) {
        self.title = title
        self.value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            Slider(value: value, in: range, step: step)
                .controlSize(.small)
        }
        .padding(.horizontal, Design.cardInset)
        .padding(.vertical, 10)
    }
}

/// Keycap sequence for read-only shortcut reference rows.
struct KeycapText: View {
    let keys: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys.components(separatedBy: " "), id: \.self) { key in
                Text(key)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.07)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            }
        }
    }
}

struct ShortcutRow: View {
    let action: String
    let keys: String

    var body: some View {
        SettingRow(action) {
            KeycapText(keys: keys)
        }
    }
}

// MARK: - 1. Genel

private struct GeneralPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionsManager

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.7"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(header: "İzinler") {
                SettingRow("Erişilebilirlik", subtitle: "Klavye ve fare denetimi için gereklidir.") {
                    Button(permissions.hasAccessibilityPermission ? "Verildi ✓" : "Sistem Ayarlarını Aç") {
                        permissions.openAccessibilitySettings()
                    }
                    .disabled(permissions.hasAccessibilityPermission)
                    .controlSize(.small)
                }
            }

            SettingsCard(header: "Başlangıç") {
                ToggleRow("Girişte Otomatik Başlat", isOn: $settings.launchAtLogin)
                RowDivider()
                ToggleRow("Dock'ta Göster",
                          subtitle: "Kapalıysa uygulama yalnızca menü çubuğunda yaşar.",
                          isOn: $settings.showInDock)
            }

            SettingsCard(
                header: "Hakkında",
                footer: "WinMac; pencere yaslama, pencere değiştirici, otomatik uygulama çıkışı, Windows klavye alışkanlıkları, fare denetimi ve pano geçmişini tek bir hafif yerel uygulamada birleştirir."
            ) {
                SettingRow("Sürüm") {
                    Text(appVersion)
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                RowDivider()
                SettingRow("Modüller") {
                    Text("Yaslama · Değiştirici · Fare · Kısayollar · Pano · Otomatik Çıkış")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - 2. Pencere Yönetimi

private struct WindowManagementPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(header: "Klavye ile Yaslama") {
                ToggleRow("Kısayolları Etkinleştir", isOn: $settings.snapShortcutsEnabled)
                RowDivider()
                ToggleRow("Aynı Kısayolda Boyut Döngüsü",
                          subtitle: "Tekrar basışta yarım → üçte iki → üçte bir döngüsü.",
                          isOn: $settings.cycleRepeatedShortcuts)
            }

            SettingsCard(header: "Fare ile Yaslama") {
                ToggleRow("Kenara Sürükleerek Yasla",
                          subtitle: "Pencereyi ekran kenarına veya köşesine sürükleyin.",
                          isOn: $settings.dragToSnapEnabled)
                RowDivider()
                ToggleRow("Yaslama Önizlemesi", isOn: $settings.aeroSnapEnabled)
            }

            SettingsCard(
                header: "Boşluklar",
                footer: "Yaslanan pencerenin ekran kenarlarıyla arasında bırakılacak mesafe."
            ) {
                SliderRow("Pencere Aralığı", value: $settings.snapWindowGaps, range: 0...30, step: 2, format: "%.0f px")
                RowDivider()
                SliderRow("Neredeyse Tam Ekran Boşluğu", value: $settings.almostMaximizePadding, range: 8...50, step: 2, format: "%.0f px")
            }

            SettingsCard(header: "Kısayol Referansı") {
                ShortcutRow(action: "Sol / Sağ Yarı", keys: "⌃⌥← ⌃⌥→")
                RowDivider()
                ShortcutRow(action: "Üst / Alt Yarı", keys: "⌃⌥↑ ⌃⌥↓")
                RowDivider()
                ShortcutRow(action: "Tam Ekran", keys: "⌃⌥↩")
                RowDivider()
                ShortcutRow(action: "Merkez", keys: "⌃⌥C")
                RowDivider()
                ShortcutRow(action: "Dörtte Birler", keys: "⌃⌥U İ J K")
                RowDivider()
                ShortcutRow(action: "Üçte Birler", keys: "⌃⌥D F G")
                RowDivider()
                ShortcutRow(action: "Diğer Ekrana Taşı", keys: "⌃⌥⌘← →")
            }
        }
    }
}

// MARK: - 3. Pencere Değiştirici

private struct AppSwitcherPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(header: "Etkinleştirme") {
                ToggleRow("Pencere Değiştirici", isOn: $settings.altTabEnabled)
                RowDivider()
                PickerRow("Kısayol", selection: $settings.switcherShortcut, options: AltTabShortcut.allCases) { $0.title }
            }

            SettingsCard(
                header: "Görünüm",
                footer: "Değiştirici içinde: ← → gezinme, W pencereyi kapat, Q uygulamadan çık, M küçült, F büyüt."
            ) {
                PickerRow("Stil", selection: $settings.switcherStyle, options: SwitcherStyle.allCases) { $0.title }
                RowDivider()
                PickerRow("Konum", selection: $settings.displayMode, options: SwitcherDisplayMode.allCases) { $0.title }
                RowDivider()
                ToggleRow("Yazarak Ara", isOn: $settings.searchFilterEnabled)
                RowDivider()
                ToggleRow("Fare ile Seçim",
                          subtitle: "İmleç bir karta yaklaştığında seçim taşınır (26px ölü bölge ile).",
                          isOn: $settings.hoverSelectEnabled)
                RowDivider()
                ToggleRow("Masaüstü Kartını Göster", isOn: $settings.showDesktopCard)
                RowDivider()
                ToggleRow("Gizli Uygulamaları Atla", isOn: $settings.hideHiddenApps)
            }
        }
    }
}

// MARK: - 4. Fare

private struct MouseControlPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var monitor = MousePointerMonitor.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(
                header: "Etkinleştirme",
                footer: "Fare denetimi private IOKit API'lerine dayanır; macOS sürümüne göre davranışı değişebilir. Kapatıldığında sistem varsayılanları geri yüklenir."
            ) {
                ToggleRow("Fare Denetimi", isOn: $settings.mousePointerEnabled)
            }

            SettingsCard(header: "İmleç") {
                ToggleRow("İvmeyi Kapat (1:1)",
                          subtitle: "macOS ivme eğrisini devre dışı bırakır; oyun ve tasarım için.",
                          isOn: $settings.mousePointerDisableAccel)
                if !settings.mousePointerDisableAccel {
                    RowDivider()
                    SliderRow("İvme", value: $settings.mousePointerAcceleration,
                              range: 0.0...2.0, step: 0.05, format: "%.2f")
                }
                RowDivider()
                SliderRow("Hız", value: $settings.mousePointerSpeed,
                          range: 0.25...3.0, step: 0.05, format: "%.2f×")
            }
            .disabled(!settings.mousePointerEnabled)
            .opacity(settings.mousePointerEnabled ? 1 : 0.5)

            SettingsCard(header: "Bağlı Cihaz") {
                SettingRow("Ad") { infoValue(monitor.deviceName) }
                RowDivider()
                SettingRow("Donanım Çözünürlüğü (DPI)") {
                    infoValue(monitor.nativeResolution.map { "\($0)" })
                }
                RowDivider()
                SettingRow("Pil") { infoValue(monitor.batteryPercent.map { "%\($0)" }) }
                RowDivider()
                SettingRow("Sorgulama Hızı") { infoValue(monitor.pollingRateHz.map { "\($0) Hz" }) }
            }

            AppExclusionCard(
                header: "Devre Dışı Uygulamalar",
                footer: "Bu uygulamalardan biri öndeyken imleç ayarları geçici olarak askıya alınır.",
                apps: $settings.mousePointerExcludedApps
            )
        }
        .onAppear { monitor.beginObserving() }
        .onDisappear { monitor.endObserving() }
    }

    @ViewBuilder
    private func infoValue(_ text: String?) -> some View {
        Text(text ?? "—")
            .font(.system(size: 12).monospacedDigit())
            .foregroundStyle(.secondary)
    }
}

/// Reusable "add / remove application bundle IDs" card.
struct AppExclusionCard: View {
    let header: String
    let footer: String
    @Binding var apps: [String]

    var body: some View {
        SettingsCard(header: header, footer: footer) {
            if apps.isEmpty {
                Text("Liste boş.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Design.cardInset)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(apps.enumerated()), id: \.element) { index, appId in
                    if index > 0 { RowDivider() }
                    SettingRow(appId) {
                        Button(role: .destructive) {
                            apps.removeAll { $0 == appId }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Color(nsColor: .systemRed))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                RowDivider()
            }
            SettingRow("Uygulama Ekle") {
                Button {
                    add()
                } label: {
                    Label("Seç…", systemImage: "plus")
                }
                .controlSize(.small)
            }
        }
    }

    private func add() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else { return }
        if !apps.contains(bundleId) { apps.append(bundleId) }
    }
}

// MARK: - 5. Klavye Kısayolları

private struct KeyboardShortcutsPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(header: "Metin Düzenleme") {
                ToggleRow("Ctrl ➔ Cmd Eşleştirmesi",
                          subtitle: "Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+S, Ctrl+F… Windows alışkanlığı.",
                          isOn: $settings.ctrlToCmdRemapEnabled)
                RowDivider()
                ToggleRow("Ctrl+Backspace → Kelime Sil", isOn: $settings.ctrlBackspaceWordDelete)
                RowDivider()
                ToggleRow("Ctrl+←/→ → Kelime Atla", isOn: $settings.ctrlArrowWordJump)
            }

            SettingsCard(header: "Sistem Kısayolları") {
                ToggleRow("⌘⌥L → Ekranı Kilitle", isOn: $settings.winLToLockEnabled)
                RowDivider()
                ToggleRow("Ctrl+Shift+Esc → Etkinlik Monitörü", isOn: $settings.ctrlShiftEscTaskManager)
                RowDivider()
                ToggleRow("⌥E → Yeni Finder Penceresi", isOn: $settings.winEToFileExplorer)
                RowDivider()
                ToggleRow("⌥D → Masaüstünü Göster", isOn: $settings.winDToShowDesktop)
            }

            SettingsCard(
                header: "Pano Geçmişi",
                footer: "Terminal ve IDE'lerde Ctrl kısayolları otomatik olarak devre dışı bırakılır."
            ) {
                ToggleRow("⌥V → Pano Geçmişi", isOn: $settings.clipboardHistoryEnabled)
                RowDivider()
                PickerRow("Kapasite", selection: $settings.maxClipboardItems, options: [25, 50, 100]) {
                    "\($0) öğe"
                }
            }
        }
    }
}

// MARK: - 6. Otomatik Çıkış

private struct AutoQuitPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsCard(header: "Davranış") {
                ToggleRow("Son Pencere Kapanınca Uygulamayı Kapat",
                          subtitle: "Kırmızı ✕ ile son pencere kapandığında uygulama tamamen çıkar.",
                          isOn: $settings.swiftQuitEnabled)
                RowDivider()
                Stepper(value: $settings.swiftQuitDelaySeconds, in: 0...10) {
                    HStack {
                        Text("Çıkış Gecikmesi")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(settings.swiftQuitDelaySeconds) sn")
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Design.cardInset)
                .padding(.vertical, 9)
                .frame(minHeight: Design.rowMinHeight)
            }

            SettingsCard(
                header: "Hariç Tutulan Uygulamalar",
                footer: "Oyunlar, IDE'ler ve terminal uygulamaları zaten varsayılan olarak korunur."
            ) {
                if settings.swiftQuitExcludedApps.isEmpty {
                    Text("Hariç tutulan uygulama yok.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Design.cardInset)
                        .padding(.vertical, 12)
                } else {
                    ForEach(Array(settings.swiftQuitExcludedApps.enumerated()), id: \.element) { index, appId in
                        if index > 0 {
                            RowDivider()
                        }
                        SettingRow(appId) {
                            Button(role: .destructive) {
                                settings.swiftQuitExcludedApps.removeAll { $0 == appId }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color(nsColor: .systemRed))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    RowDivider()
                }
                SettingRow("Uygulama Ekle") {
                    Button {
                        addExclusion()
                    } label: {
                        Label("Seç…", systemImage: "plus")
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    private func addExclusion() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else { return }
        if !settings.swiftQuitExcludedApps.contains(bundleId) {
            settings.swiftQuitExcludedApps.append(bundleId)
        }
    }
}
