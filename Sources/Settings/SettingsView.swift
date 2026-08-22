import SwiftUI
import AppKit

// MARK: - Sidebar Sections

public enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case general
    case windowManagement
    case mouseAndScroll
    case appSwitcher
    case keyboardShortcuts
    case autoQuit

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .general: return "Genel"
        case .windowManagement: return "Pencere Yönetimi"
        case .mouseAndScroll: return "Fare ve Kaydırma"
        case .appSwitcher: return "Pencere Değiştirici"
        case .keyboardShortcuts: return "Klavye Kısayolları"
        case .autoQuit: return "Otomatik Çıkış"
        }
    }

    public var icon: String {
        switch self {
        case .general: return "gearshape"
        case .windowManagement: return "rectangle.split.2x1"
        case .mouseAndScroll: return "computermouse"
        case .appSwitcher: return "square.stack.3d.up"
        case .keyboardShortcuts: return "command.square"
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
            List(selection: $selectedPane) {
                ForEach(SettingsPane.allCases) { pane in
                    Label(pane.title, systemImage: pane.icon)
                        .tag(pane)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 170, ideal: 185, max: 220)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(permissions.hasAccessibilityPermission ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    Text(permissions.hasAccessibilityPermission ? "İzinler tamam" : "Erişilebilirlik izni gerekli")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 18)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } detail: {
            Group {
                switch selectedPane {
                case .general:
                    GeneralPane(settings: settings, permissions: permissions)
                case .windowManagement:
                    WindowManagementPane(settings: settings)
                case .mouseAndScroll:
                    MouseScrollPane(settings: settings)
                case .appSwitcher:
                    AppSwitcherPane(settings: settings)
                case .keyboardShortcuts:
                    KeyboardShortcutsPane(settings: settings)
                case .autoQuit:
                    AutoQuitPane(settings: settings)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(selectedPane.title)
        }
        .frame(width: 720, height: 500)
    }
}

// MARK: - Shared Rows

private struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        LabeledContent {
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(.switch)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PickerRow<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    init(_ title: String, selection: Binding<Value>, options: [Value], label: @escaping (Value) -> String) {
        self.title = title
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(label(option)).tag(option)
            }
        }
    }
}

private struct ShortcutRow: View {
    let action: String
    let keys: String

    var body: some View {
        LabeledContent(action) {
            Text(keys)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(nsColor: .quaternaryLabelColor).opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

private struct SliderRow: View {
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
        LabeledContent(title) {
            HStack(spacing: 8) {
                Slider(value: value, in: range, step: step)
                    .frame(width: 150)
                Text(String(format: format, value.wrappedValue))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }
}

// MARK: - 1. Genel

private struct GeneralPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionsManager

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.2"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Button(permissions.hasAccessibilityPermission ? "İzin verildi" : "Sistem Ayarlarını Aç") {
                        permissions.openAccessibilitySettings()
                    }
                    .disabled(permissions.hasAccessibilityPermission)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Erişilebilirlik İzni")
                        Text("Klavye ve fare denetimi için gereklidir.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("İzinler")
            }

            Section {
                ToggleRow("Girişte Otomatik Başlat", isOn: $settings.launchAtLogin)
                ToggleRow("Dock'ta Göster",
                          subtitle: "Kapalıysa uygulama yalnızca menü çubuğunda çalışır.",
                          isOn: $settings.showInDock)
            } header: {
                Text("Başlangıç")
            }

            Section {
                LabeledContent("Sürüm") {
                    Text(appVersion).foregroundStyle(.secondary)
                }
                LabeledContent("Modüller") {
                    Text("Pencere Yönetimi · Fare · Değiştirici · Kısayollar · Pano · Otomatik Çıkış")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Hakkında")
            } footer: {
                Text("WinMac; açık kaynak Rectangle, LinearMouse, AltTab ve SwiftQuit projelerinden esinlenmiştir.")
            }
        }
    }
}

// MARK: - 2. Pencere Yönetimi

private struct WindowManagementPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                ToggleRow("Klavye Kısayollarını Etkinleştir", isOn: $settings.snapShortcutsEnabled)
                ToggleRow("Aynı Kısayolda Boyut Döngüsü",
                          subtitle: "Tekrar basıldığında yarım → üçte iki → üçte bir döngüsü.",
                          isOn: $settings.cycleRepeatedShortcuts)
            } header: {
                Text("Klavye ile Yaslama")
            }

            Section {
                ToggleRow("Kenara Sürükleerek Yasla",
                          subtitle: "Pencereyi ekran kenarına veya köşesine sürükleyin.",
                          isOn: $settings.dragToSnapEnabled)
                ToggleRow("Yaslama Önizlemesi", isOn: $settings.aeroSnapEnabled)
            } header: {
                Text("Fare ile Yaslama")
            }

            Section {
                SliderRow("Pencere Aralığı", value: $settings.snapWindowGaps, range: 0...30, step: 2, format: "%.0f px")
                SliderRow("Neredeyse Tam Ekran Boşluğu", value: $settings.almostMaximizePadding, range: 8...50, step: 2, format: "%.0f px")
            } header: {
                Text("Boşluklar")
            } footer: {
                Text("Boşluklar yaslanan pencerenin ekran kenarlarıyla arasında bırakılacak mesafeyi belirler.")
            }

            Section {
                ShortcutRow(action: "Sol Yarı", keys: "⌃⌥←")
                ShortcutRow(action: "Sağ Yarı", keys: "⌃⌥→")
                ShortcutRow(action: "Üst Yarı", keys: "⌃⌥↑")
                ShortcutRow(action: "Alt Yarı", keys: "⌃⌥↓")
                ShortcutRow(action: "Tam Ekran", keys: "⌃⌥↩")
                ShortcutRow(action: "Merkez", keys: "⌃⌥C")
                ShortcutRow(action: "Dörtte Birler", keys: "⌃⌥U İ J K")
                ShortcutRow(action: "Üçte Birler", keys: "⌃⌥D F G E T")
                ShortcutRow(action: "Diğer Ekrana Taşı", keys: "⌃⌥⌘← →")
            } header: {
                Text("Kısayol Referansı")
            }
        }
    }
}

// MARK: - 3. Fare ve Kaydırma

private struct MouseScrollPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                ToggleRow("Tekerleği Ters Çevir",
                          subtitle: "Trackpad'i etkilemez; yalnızca harici fare tekerleği.",
                          isOn: $settings.invertMouseWheel)
                ToggleRow("Yatay Kaydırmayı Ters Çevir", isOn: $settings.invertHorizontalScroll)
                ToggleRow("Shift + Tekerlek → Yatay Kaydırma", isOn: $settings.shiftToHorizontalScroll)
            } header: {
                Text("Kaydırma")
            }

            Section {
                SliderRow("Kaydırma Hızı", value: $settings.scrollSpeedMultiplier, range: 0.5...4.0, step: 0.25, format: "%.2f×")
            } header: {
                Text("Hız")
            }

            Section {
                ToggleRow("Doğrusal İmleç Hızı (1:1)",
                          subtitle: "macOS ivme eğrisini kapatır; oyunlar ve tasarım için önerilir.",
                          isOn: $settings.disableMouseAcceleration)
                SliderRow("İmleç Hassasiyeti", value: $settings.mousePointerSensitivity, range: 0.5...3.0, step: 0.1, format: "%.1f×")
            } header: {
                Text("İmleç")
            } footer: {
                Text("Değişiklikler donanım seviyesinde uygulanır ve sistem yeniden başlasa da korunur.")
            }
        }
    }
}

// MARK: - 4. Pencere Değiştirici

private struct AppSwitcherPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                ToggleRow("Pencere Değiştiriciyi Etkinleştir", isOn: $settings.altTabEnabled)
                PickerRow("Kısayol", selection: $settings.switcherShortcut, options: AltTabShortcut.allCases) { $0.title }
            } header: {
                Text("Etkinleştirme")
            }

            Section {
                PickerRow("Görünüm Stili", selection: $settings.switcherStyle, options: SwitcherStyle.allCases) { $0.title }
                PickerRow("Konum", selection: $settings.displayMode, options: SwitcherDisplayMode.allCases) { $0.title }
                ToggleRow("Yazarak Ara", isOn: $settings.searchFilterEnabled)
            } header: {
                Text("Görünüm")
            } footer: {
                Text("Değiştirici içinde: ← → gezinme, W pencereyi kapat, Q uygulamadan çık, M küçült, F büyüt.")
            }
        }
    }
}

// MARK: - 5. Klavye Kısayolları

private struct KeyboardShortcutsPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                ToggleRow("Ctrl ➔ Cmd Eşleştirmesi",
                          subtitle: "Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+S, Ctrl+F… Windows alışkanlığı.",
                          isOn: $settings.ctrlToCmdRemapEnabled)
                ToggleRow("Ctrl+Backspace → Kelime Sil", isOn: $settings.ctrlBackspaceWordDelete)
                ToggleRow("Ctrl+←/→ → Kelime Atla", isOn: $settings.ctrlArrowWordJump)
            } header: {
                Text("Metin Düzenleme")
            }

            Section {
                ToggleRow("⌘⌥L → Ekranı Kilitle", isOn: $settings.winLToLockEnabled)
                ToggleRow("Ctrl+Shift+Esc → Etkinlik Monitörü", isOn: $settings.ctrlShiftEscTaskManager)
                ToggleRow("⌥E → Yeni Finder Penceresi", isOn: $settings.winEToFileExplorer)
                ToggleRow("⌥D → Masaüstünü Göster", isOn: $settings.winDToShowDesktop)
                ToggleRow("⌥V → Pano Geçmişi", isOn: $settings.clipboardHistoryEnabled)
            } header: {
                Text("Sistem Kısayolları")
            }

            Section {
                PickerRow("Pano Kapasitesi", selection: $settings.maxClipboardItems, options: [25, 50, 100]) {
                    "\($0) öğe"
                }
            } header: {
                Text("Pano Geçmişi")
            } footer: {
                Text("Terminal ve IDE'lerde Ctrl kısayolları otomatik olarak devre dışı bırakılır.")
            }
        }
    }
}

// MARK: - 6. Otomatik Çıkış

private struct AutoQuitPane: View {
    @ObservedObject var settings: AppSettings
    @State private var selectedExclusion: String?

    var body: some View {
        Form {
            Section {
                ToggleRow("Son Pencere Kapanınca Uygulamayı Kapat",
                          subtitle: "Kırmızı ✕ ile son pencere kapatıldığında uygulama tamamen çıkar.",
                          isOn: $settings.swiftQuitEnabled)
                Stepper(value: $settings.swiftQuitDelaySeconds, in: 0...10) {
                    LabeledContent("Çıkış Gecikmesi") {
                        Text("\(settings.swiftQuitDelaySeconds) sn").foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Davranış")
            }

            Section {
                if settings.swiftQuitExcludedApps.isEmpty {
                    Text("Hariç tutulan uygulama yok.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settings.swiftQuitExcludedApps, id: \.self) { appId in
                        LabeledContent(appId) {
                            Button(role: .destructive) {
                                removeExclusion(appId)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                Button {
                    addExclusion()
                } label: {
                    Label("Uygulama Ekle…", systemImage: "plus")
                }
            } header: {
                Text("Hariç Tutulan Uygulamalar")
            } footer: {
                Text("Oyunlar, IDE'ler ve terminal uygulamaları zaten varsayılan olarak korunur.")
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

    private func removeExclusion(_ appId: String) {
        settings.swiftQuitExcludedApps.removeAll { $0 == appId }
    }
}
