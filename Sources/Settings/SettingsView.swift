import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var permissions = PermissionsManager.shared
    
    @State private var selectedTab: SettingsTab = .alttab
    
    public init() {}
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case alttab = "Alt + Tab"
        case snap = "Pencere Yaslama (Rectangle Pro)"
        case swiftquit = "X ile Tamamen Kapat (SwiftQuit)"
        case mouse = "Linear Mouse Pro"
        case keyboard = "Klavye"
        case finder = "Finder"
        case clipboard = "Pano (Win + V)"
        case permissions = "İzinler & Hakkında"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .alttab: return "macwindow.on.rectangle"
            case .snap: return "rectangle.split.2x1.fill"
            case .swiftquit: return "xmark.circle.fill"
            case .mouse: return "computermouse.fill"
            case .keyboard: return "keyboard.fill"
            case .finder: return "folder.fill"
            case .clipboard: return "doc.on.clipboard.fill"
            case .permissions: return "checkmark.shield.fill"
            }
        }
        
        public var color: Color {
            switch self {
            case .alttab: return .blue
            case .snap: return .indigo
            case .swiftquit: return .red
            case .mouse: return .teal
            case .keyboard: return .orange
            case .finder: return .cyan
            case .clipboard: return .purple
            case .permissions: return .green
            }
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(tab.color.gradient)
                            )
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .padding(.vertical, 3)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 260)
        } detail: {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .alttab:
                        AltTabSettingsSection(settings: settings)
                    case .snap:
                        SnapSettingsSection(settings: settings)
                    case .swiftquit:
                        SwiftQuitSettingsSection(settings: settings)
                    case .mouse:
                        MouseSettingsSection(settings: settings)
                    case .keyboard:
                        KeyboardSettingsSection(settings: settings)
                    case .finder:
                        FinderSettingsSection(settings: settings)
                    case .clipboard:
                        ClipboardSettingsSection(settings: settings)
                    case .permissions:
                        PermissionsSettingsSection(permissions: permissions)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 840, height: 600)
    }
}

// MARK: - Sections

private struct AltTabSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Alt + Tab Pencere Değiştirici", subtitle: "Windows tarzı zengin pencere geçişi ve arama motoru.")
            
            SettingsCard {
                ToggleRow(
                    title: "Alt + Tab'ı Etkinleştir",
                    subtitle: "Option + Tab ile pencereler arasında geçiş yapın.",
                    isOn: $settings.altTabEnabled
                )
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Görünüm Stili:")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    
                    Picker("", selection: $settings.switcherStyle) {
                        ForEach(SwitcherStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Gösterilecek Ekran:")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    
                    Picker("", selection: $settings.displayMode) {
                        ForEach(SwitcherDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                }
                
                Divider()
                
                ToggleRow(
                    title: "Yazarak Canlı Pencere Arama (Type-to-Search)",
                    subtitle: "Alt + Tab açıkken doğrudan klavyeden yazarak pencereleri anında daraltır.",
                    isOn: $settings.searchFilterEnabled
                )
            }
        }
    }
}

private struct SnapSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Pencere Yaslama (Rectangle Pro)", subtitle: "Ekran kenarlarına sürükleme önizlemesi ve tekrarlayan kısayol döngüleri.")
            
            SettingsCard {
                ToggleRow(
                    title: "Kenarlara Sürükleyerek Yaslama (Drag-to-Snap)",
                    subtitle: "Pencereyi ekran kenarına/köşesine sürükleyince mavi önizleme belirir ve bırakınca yaslanır.",
                    isOn: $settings.dragToSnapEnabled
                )
                
                Divider()
                
                ToggleRow(
                    title: "Tekrarlayan Kısayol Döngüsü (Cycle Thirds)",
                    subtitle: "Aynı kısayola art arda basınca pencere 1/2 -> 2/3 -> 1/3 oranları arasında döner.",
                    isOn: $settings.cycleRepeatedShortcuts
                )
                
                Divider()
                
                ToggleRow(
                    title: "Pencere Yaslama Kısayollarını Etkinleştir",
                    subtitle: "Tüm klavye kısayollarını etkinleştirir.",
                    isOn: $settings.snapShortcutsEnabled
                )
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Pencereler Arası Boşluk (Gaps):")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(Int(settings.snapWindowGaps)) px")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    Slider(value: $settings.snapWindowGaps, in: 0...24, step: 2)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kullanılabilir Kısayollar:")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ShortcutRow(key: "⌥ + ⌃ + Sol / Sağ Ok", label: "Sol / Sağ Yarı (Döngülü)")
                        ShortcutRow(key: "⌥ + ⌃ + Yukarı / Aşağı", label: "Üst Yarı / Alt Yarı / Max")
                        ShortcutRow(key: "⌥ + ⌃ + Return", label: "Tam Ekran (Maximize)")
                        ShortcutRow(key: "⌥ + ⌃ + C", label: "Merkeze Al")
                        ShortcutRow(key: "⌥ + ⌃ + U / I", label: "Sol Üst / Sağ Üst Çeyrek")
                        ShortcutRow(key: "⌥ + ⌃ + J / K", label: "Sol Alt / Sağ Alt Çeyrek")
                        ShortcutRow(key: "⌥ + ⌃ + D / F / G", label: "Sol / Orta / Sağ 1/3")
                        ShortcutRow(key: "⌥ + ⌃ + E / T", label: "Sol / Sağ 2/3")
                        ShortcutRow(key: "⌥ + ⌃ + + / -", label: "Pencereyi Büyüt / Küçült")
                        ShortcutRow(key: "⌥ + ⌃ + ⌘ + Oklar", label: "Diğer Monitöre Taşı")
                    }
                }
            }
        }
    }
}

private struct SwiftQuitSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "X ile Kapat (SwiftQuit)", subtitle: "Kırmızı 'X' butonuna basıp son pencereyi kapattığınızda uygulamadan tamamen çıkın.")
            
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "xmark.app.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Windows Tarzı Çıkış Deneyimi")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("Mac'te sol üstteki kırmızı 'X' butonuna bastığınızda uygulama arka planda çalışmaya devam eder (Dock'ta noktası kalır). SwiftQuit özelliği sayesinde bir uygulamanın son penceresi kapandığında uygulama tıpkı Windows'taki gibi kendiliğinden tamamen kapanır (Quit).")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(Color.red.opacity(0.12))
            .cornerRadius(12)
            
            SettingsCard {
                ToggleRow(
                    title: "Otomatik Çıkışı Etkinleştir (SwiftQuit)",
                    subtitle: "Son pencere kapandığında uygulamayı sonlandırır.",
                    isOn: $settings.swiftQuitEnabled
                )
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kapanma Gecikmesi:")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    
                    Picker("", selection: $settings.swiftQuitDelaySeconds) {
                        Text("Anında (0 sn)").tag(0)
                        Text("1 Saniye Gecikme").tag(1)
                        Text("2 Saniye Gecikme").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Varsayılan Olarak Korunan Uygulamalar:")
                        .font(.system(size: 12, weight: .bold))
                    Text("Finder, Sistem Ayarları, Müzik ve Mail gibi arka planda kalması gereken uygulamalar otomatik olarak korunur.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct MouseSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Linear Mouse Pro & Kaydırma", subtitle: "Bağımsız fare tekerleği, tuşlu tekerlek aksiyonları ve ivme kontrolü.")
            
            SettingsCard {
                ToggleRow(
                    title: "Bağımsız Fare Tekerleği Yönü (Windows Yönü)",
                    subtitle: "Trackpad doğal kaydırmada kalır, harici fare tekerleği Windows gibi aşağı doğru kaydırır.",
                    isOn: $settings.invertMouseWheel
                )
                
                Divider()
                
                ToggleRow(
                    title: "Yatay Kaydırma Yönünü Ters Çevir",
                    subtitle: "Harici farelerin yatay tekerlek kaydırmasını tersine çevirir.",
                    isOn: $settings.invertHorizontalScroll
                )
                
                Divider()
                
                Text("Tekerlek & Tuş Modifikatörleri (Modifiers):")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                
                ToggleRow(
                    title: "Cmd + Tekerlek: Yakınlaştır / Uzaklaştır (Zoom)",
                    subtitle: "Tarayıcılarda ve belgelerde sayfayı yakınlaştırır.",
                    isOn: $settings.cmdZoomScrollEnabled
                )
                
                ToggleRow(
                    title: "Shift + Tekerlek: Yatay Kaydırma",
                    subtitle: "Tekerleği çevirirken sayfayı sağa/sola kaydırır.",
                    isOn: $settings.shiftHorizontalScrollEnabled
                )
                
                ToggleRow(
                    title: "Option + Tekerlek: 3x Süper Hızlı Kaydırma",
                    subtitle: "Uzun dökümanlarda 3 kat daha hızlı kaydırma sağlar.",
                    isOn: $settings.optionFastScrollEnabled
                )
                
                ToggleRow(
                    title: "Control + Tekerlek: 0.3x Hassas Yavaş Kaydırma",
                    subtitle: "Piksel hassasiyetinde yavaş ve kontrollü kaydırır.",
                    isOn: $settings.ctrlSlowScrollEnabled
                )
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Genel Kaydırma Hızı:")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(String(format: "%.2fx", settings.scrollSpeedMultiplier))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    Slider(value: $settings.scrollSpeedMultiplier, in: 0.5...3.0, step: 0.25)
                }
                
                Stepper("Tekerlek Çentiği Başına Satır: \(settings.linesPerScrollTick)", value: $settings.linesPerScrollTick, in: 1...10)
                
                Divider()
                
                ToggleRow(
                    title: "Doğrusal Fare İvmesi (Linear Curve)",
                    subtitle: "macOS'in ivmelenme eğrisini sıfırlayarak 1:1 Windows fare hassasiyeti sağlar.",
                    isOn: $settings.disableMouseAcceleration
                )
            }
        }
    }
}

private struct KeyboardSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Klavye & Muscle Memory", subtitle: "Windows kısayollarını macOS üzerinde kesintisiz kullanın.")
            
            SettingsCard {
                ToggleRow(
                    title: "Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+A -> Cmd Çevirisi",
                    subtitle: "Yılların klavye alışkanlığıyla doğrudan kopyala/yapıştır yapın.",
                    isOn: $settings.ctrlToCmdRemapEnabled
                )
                
                Divider()
                
                ToggleRow(
                    title: "Win + L ile Ekranı Kilitle (Option + L)",
                    subtitle: "Windows'taki gibi ekranı tek hamlede kilitler.",
                    isOn: $settings.winLToLockEnabled
                )
                
                Divider()
                
                ToggleRow(
                    title: "Ctrl + Shift + Esc ile Görev Yöneticisini Aç",
                    subtitle: "macOS Etkinlik Monitörünü doğrudan başlatır.",
                    isOn: $settings.ctrlShiftEscTaskManager
                )
            }
        }
    }
}

private struct FinderSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Finder (Dosya Gezgini) İyileştirmeleri", subtitle: "Mac'te dosya açma ve yeniden adlandırma alışkanlıklarını düzeltin.")
            
            SettingsCard {
                ToggleRow(
                    title: "Enter / Return ile Dosyayı Aç (Cmd + Down)",
                    subtitle: "Mac'te Enter basınca dosya ismini düzenlemek yerine dosyayı doğrudan açar.",
                    isOn: $settings.finderEnterToOpen
                )
                
                Divider()
                
                ToggleRow(
                    title: "F2 ile Dosyayı Yeniden Adlandır",
                    subtitle: "Windows gibi F2'ye bastığınızda dosya ismini düzenlemeye açar.",
                    isOn: $settings.finderF2ToRename
                )
                
                Divider()
                
                ToggleRow(
                    title: "Delete / Backspace ile Çöpe Gönder",
                    subtitle: "Mac klavyesindeki silme tuşuna basıldığında dosyayı doğrudan çöp kutusuna taşır.",
                    isOn: $settings.finderDeleteToTrash
                )
            }
        }
    }
}

private struct ClipboardSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Pano Geçmişi (Win + V)", subtitle: "Kopyaladığınız her şeyi saklar, istediğiniz zaman geri yapıştırın.")
            
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 22))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pano Özelliği Nedir?")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("Normalde bir şey kopyaladığınızda sadece son kopyaladığınızı yapıştırabilirsiniz. Win + V (veya ⌥ + V) kopyaladığınız son 50 metni hafızada tutar. Böylece sekmeler arasında git-gel yapmadan topluca kopyalayıp istediğinizi listeden seçerek yapıştırabilirsiniz.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(Color.purple.opacity(0.12))
            .cornerRadius(12)
            
            SettingsCard {
                ToggleRow(
                    title: "Pano Geçmişini Etkinleştir",
                    subtitle: "Win + V veya Option + V ile açılır.",
                    isOn: $settings.clipboardHistoryEnabled
                )
                
                Divider()
                
                Stepper("Maksimum Kayıt Sayısı: \(settings.maxClipboardItems)", value: $settings.maxClipboardItems, in: 10...200, step: 10)
                
                Divider()
                
                Button(action: {
                    ClipboardManager.shared.clearAll()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Pano Geçmişini Temizle")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

private struct PermissionsSettingsSection: View {
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderTitle(title: "Sistem İzinleri & Hakkında", subtitle: "WinMac'in kusursuz çalışması için gerekli macOS izinleri.")
            
            SettingsCard {
                PermissionRow(
                    title: "Erişilebilirlik (Accessibility)",
                    subtitle: "Global kısayollar, pencere odaklama ve yaslama için gereklidir.",
                    isGranted: permissions.hasAccessibilityPermission,
                    onRequest: {
                        permissions.requestAccessibilityPermission()
                        permissions.openAccessibilitySettings()
                    }
                )
                
                Divider()
                
                PermissionRow(
                    title: "Ekran Kaydı (Screen Recording)",
                    subtitle: "Alt + Tab pencerelerinin canlı küçük resimlerini (thumbnails) üretmek için gereklidir.",
                    isGranted: permissions.hasScreenRecordingPermission,
                    onRequest: {
                        permissions.requestScreenRecordingPermission()
                        permissions.openScreenRecordingSettings()
                    }
                )
            }
            
            // About Box
            HStack(spacing: 16) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("WinMac — Windows to Mac Super Toolkit")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("Sürüm 3.1.0 • SwiftQuit & Rectangle Pro & LinearMouse")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Reusable UI Components

private struct HeaderTitle: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 12.5))
                .foregroundColor(.secondary)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
}

private struct ShortcutRow: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.12))
                .cornerRadius(5)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let subtitle: String
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isGranted ? .green : .orange)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isGranted {
                Text("Aktif")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Button("İzin Ver", action: onRequest)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
