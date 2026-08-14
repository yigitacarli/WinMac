import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var permissions = PermissionsManager.shared
    
    @State private var currentTab: SettingsTab = .switcher
    
    public init() {}
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case switcher = "Pencere Geçişi"
        case snap = "Pencere Yaslama"
        case autoquit = "Otomatik Çıkış"
        case mouse = "Fare & Kaydırma"
        case keyboard = "Klavye & Pano"
        case permissions = "İzinler & Hakkında"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .switcher: return "macwindow.on.rectangle"
            case .snap: return "rectangle.split.2x1.fill"
            case .autoquit: return "xmark.circle.fill"
            case .mouse: return "computermouse.fill"
            case .keyboard: return "keyboard.fill"
            case .permissions: return "checkmark.shield.fill"
            }
        }
        
        public var accentColor: Color {
            switch self {
            case .switcher: return .blue
            case .snap: return .indigo
            case .autoquit: return .red
            case .mouse: return .teal
            case .keyboard: return .orange
            case .permissions: return .green
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Modern Header & Top Navigation Bar
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.35), radius: 6, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WinMac")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("macOS Verimlilik Paketi")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(permissions.hasAccessibilityPermission ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(permissions.hasAccessibilityPermission ? "Aktif" : "İzin Gerekli")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(permissions.hasAccessibilityPermission ? .green : .orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (permissions.hasAccessibilityPermission ? Color.green : Color.orange).opacity(0.12)
                    )
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Top Tab Capsule Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(SettingsTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                    currentTab = tab
                                }
                            }) {
                                HStack(spacing: 7) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                    
                                    Text(tab.rawValue)
                                        .font(.system(size: 12.5, weight: currentTab == tab ? .bold : .medium, design: .rounded))
                                }
                                .foregroundColor(currentTab == tab ? .white : .secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    ZStack {
                                        if currentTab == tab {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(tab.accentColor.gradient)
                                                .shadow(color: tab.accentColor.opacity(0.35), radius: 6, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.white.opacity(0.04))
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
            .background(
                VisualEffectBlur(material: .headerView, blendingMode: .behindWindow)
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // MARK: - Dynamic Scrollable Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Global Permission Warning Banner
                    if !permissions.hasAccessibilityPermission {
                        PermissionAlertBanner(permissions: permissions)
                    }
                    
                    switch currentTab {
                    case .switcher:
                        SwitcherTabContent(settings: settings)
                    case .snap:
                        SnapTabContent(settings: settings)
                    case .autoquit:
                        AutoQuitTabContent(settings: settings)
                    case .mouse:
                        MouseTabContent(settings: settings)
                    case .keyboard:
                        KeyboardTabContent(settings: settings)
                    case .permissions:
                        PermissionsTabContent(permissions: permissions)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            VisualEffectBlur(material: .underWindowBackground, blendingMode: .behindWindow)
        )
    }
}

// MARK: - Permission Alert Banner

private struct PermissionAlertBanner: View {
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 22))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Erişilebilirlik İzni Gerekli")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("WinMac'in pencere değiştirici, pencere yaslama ve kısayolları çalıştırabilmesi için sistem izni gereklidir.")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                permissions.openAccessibilitySettings()
            }) {
                Text("İzin Ver")
                    .font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - 1. Switcher Tab Content

private struct SwitcherTabContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Pencere Değiştirici",
                subtitle: "macOS Command+Tab tarzında sade ve şık pencere geçiş arayüzü."
            )
            
            CardContainer {
                ModernToggleRow(
                    icon: "macwindow.on.rectangle",
                    color: .blue,
                    title: "Pencere Değiştiriciyi Etkinleştir",
                    subtitle: "Klavyeden pencere geçiş arayüzünü aktif hale getirir.",
                    isOn: $settings.altTabEnabled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tetikleyici Klavye Kısayolu:")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    
                    Picker("", selection: $settings.switcherShortcut) {
                        ForEach(AltTabShortcut.allCases) { shortcut in
                            Text(shortcut.title).tag(shortcut)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
}

// MARK: - 2. Snap Tab Content

private struct SnapTabContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Pencere Yaslama & Yerleşim",
                subtitle: "Pencereleri ekran kenarlarına sürükleyerek veya kısayollarla hızlıca hizalayın."
            )
            
            CardContainer {
                ModernToggleRow(
                    icon: "rectangle.split.2x1.fill",
                    color: .indigo,
                    title: "Sürükleyerek Yaslama (Aero Snap)",
                    subtitle: "Pencereyi ekran kenarlarına veya 4 köşesine sürükleyince mavi önizleme belirir ve bırakınca yaslanır.",
                    isOn: $settings.dragToSnapEnabled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "keyboard.fill",
                    color: .purple,
                    title: "Pencere Yaslama Kısayollarını Etkinleştir",
                    subtitle: "Global Carbon kısayollarını etkinleştirir.",
                    isOn: $settings.snapShortcutsEnabled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "arrow.triangle.2.circlepath",
                    color: .cyan,
                    title: "Tekrarlayan Kısayol Oran Döngüsü (1/2 -> 2/3 -> 1/3)",
                    subtitle: "Aynı kısayola art arda basıldığında pencere genişlik oranları arasında döner.",
                    isOn: $settings.cycleRepeatedShortcuts
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Klavye Kısayolları:")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 8) {
                        ShortcutPill(key: "⌥ + ⌃ + Sol / Sağ Ok", label: "Sol / Sağ Yarı (Döngülü)")
                        ShortcutPill(key: "⌥ + ⌃ + Yukarı Ok", label: "Tam Ekran (Maximize)")
                        ShortcutPill(key: "⌥ + ⌃ + Aşağı Ok", label: "Alt Yarı Ekran")
                        ShortcutPill(key: "⌥ + ⌃ + Return", label: "Tam Ekran")
                        ShortcutPill(key: "⌥ + ⌃ + C", label: "Merkeze Al")
                        ShortcutPill(key: "⌥ + ⌃ + U / I", label: "Sol Üst / Sağ Üst Çeyrek")
                        ShortcutPill(key: "⌥ + ⌃ + J / K", label: "Sol Alt / Sağ Alt Çeyrek")
                        ShortcutPill(key: "⌥ + ⌃ + D / F / G", label: "Sol / Orta / Sağ 1/3")
                        ShortcutPill(key: "⌥ + ⌃ + ⌘ + Oklar", label: "Diğer Ekrana Taşı")
                    }
                }
            }
        }
    }
}

// MARK: - 3. AutoQuit Tab Content

private struct AutoQuitTabContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Otomatik Çıkış",
                subtitle: "Kırmızı 'X' butonuyla son pencere kapandığında uygulamayı sonlandırın."
            )
            
            CardContainer {
                ModernToggleRow(
                    icon: "xmark.circle.fill",
                    color: .red,
                    title: "Otomatik Çıkışı Etkinleştir",
                    subtitle: "Son pencere 'X' veya Cmd+W ile kapatıldığında uygulamayı kendiliğinden kapatır.",
                    isOn: $settings.swiftQuitEnabled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
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
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    Text("Sarı küçültme (-) butonuyla Dock'a alınan veya Cmd+H ile gizlenen uygulamalar korunur.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 4. Mouse Tab Content

private struct MouseTabContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Fare & Kaydırma Denetimi",
                subtitle: "Bağımsız tekerlek yönü, imleç hassasiyeti ve tuş modifikatörleri."
            )
            
            CardContainer {
                ModernToggleRow(
                    icon: "computermouse.fill",
                    color: .teal,
                    title: "Bağımsız Fare Tekerleği Yönü (Standart Yön)",
                    subtitle: "Trackpad doğal kaydırmada kalır, harici fare tekerleği aşağı doğru kaydırır.",
                    isOn: $settings.invertMouseWheel
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "arrow.left.and.right",
                    color: .cyan,
                    title: "Yatay Kaydırma Yönünü Ters Çevir",
                    subtitle: "Harici farelerin yatay kaydırmasını tersine çevirir.",
                    isOn: $settings.invertHorizontalScroll
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Fare İmleç Hassasiyeti:")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(String(format: "%.1fx", settings.mousePointerSensitivity))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.teal)
                    }
                    Slider(value: $settings.mousePointerSensitivity, in: 0.5...2.5, step: 0.1)
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "speedometer",
                    color: .orange,
                    title: "Doğrusal Fare İvmesi (1:1 Hassasiyet)",
                    subtitle: "macOS ivmelenme eğrisini sıfırlayarak sabit 1:1 fare hassasiyeti sağlar.",
                    isOn: $settings.disableMouseAcceleration
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Kaydırma Hızı:")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(String(format: "%.2fx", settings.scrollSpeedMultiplier))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    Slider(value: $settings.scrollSpeedMultiplier, in: 0.5...3.0, step: 0.25)
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                Text("Tekerlek Modifikatörleri:")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                
                ModernToggleRow(
                    icon: "plus.magnifyingglass",
                    color: .green,
                    title: "Cmd + Tekerlek: Yakınlaştır / Uzaklaştır (Zoom)",
                    subtitle: "Tarayıcılarda ve dökümanlarda sayfayı yakınlaştırır.",
                    isOn: $settings.cmdZoomScrollEnabled
                )
                
                ModernToggleRow(
                    icon: "arrow.left.and.right",
                    color: .indigo,
                    title: "Shift + Tekerlek: Yatay Kaydırma",
                    subtitle: "Tekerleği çevirirken sayfayı sağa/sola kaydırır.",
                    isOn: $settings.shiftHorizontalScrollEnabled
                )
                
                ModernToggleRow(
                    icon: "hare.fill",
                    color: .yellow,
                    title: "Option + Tekerlek: 3x Süper Hızlı Kaydırma",
                    subtitle: "Uzun sayfalarda 3 kat hızlı kaydırma sağlar.",
                    isOn: $settings.optionFastScrollEnabled
                )
                
                ModernToggleRow(
                    icon: "tortoise.fill",
                    color: .blue,
                    title: "Control + Tekerlek: 0.3x Hassas Yavaş Kaydırma",
                    subtitle: "Piksel hassasiyetinde yavaş ve kontrollü kaydırır.",
                    isOn: $settings.ctrlSlowScrollEnabled
                )
            }
        }
    }
}

// MARK: - 5. Keyboard Tab Content

private struct KeyboardTabContent: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Klavye Kısayolları & Pano Geçmişi",
                subtitle: "Evrensel kısayolları ve aranabilir pano hafızasını kullanın."
            )
            
            CardContainer {
                ModernToggleRow(
                    icon: "keyboard.fill",
                    color: .orange,
                    title: "Ctrl+C, Ctrl+V, Ctrl+Z (Undo), Ctrl+Y (Redo), Ctrl+A -> Cmd",
                    subtitle: "Kopyalama, yapıştırma, geri ve ileri alma işlemlerini standart kısayollarla yapın.",
                    isOn: $settings.ctrlToCmdRemapEnabled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "lock.fill",
                    color: .red,
                    title: "Option + L (⌥ + L) ile Ekranı Kilitle",
                    subtitle: "Tek bir hamleyle ekranı anında kilitler.",
                    isOn: $settings.winLToLockEnabled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "gauge",
                    color: .blue,
                    title: "Ctrl + Shift + Esc ile Etkinlik Monitörünü Aç",
                    subtitle: "macOS Etkinlik Monitörünü doğrudan başlatır.",
                    isOn: $settings.ctrlShiftEscTaskManager
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                ModernToggleRow(
                    icon: "doc.on.clipboard.fill",
                    color: .purple,
                    title: "Pano Geçmişini Etkinleştir",
                    subtitle: "Option + V (⌥ + V) veya Control + Shift + V ile açılır.",
                    isOn: $settings.clipboardHistoryEnabled
                )
                
                if settings.clipboardHistoryEnabled {
                    Divider().background(Color.white.opacity(0.08))
                    
                    HStack {
                        Stepper("Maksimum Kayıt Sayısı: \(settings.maxClipboardItems)", value: $settings.maxClipboardItems, in: 10...200, step: 10)
                        Spacer()
                        Button(action: {
                            ClipboardManager.shared.clearAll()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Panoyu Temizle")
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - 6. Permissions Tab Content

private struct PermissionsTabContent: View {
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Sistem İzinleri & Hakkında",
                subtitle: "WinMac'in kesintisiz çalışması için gerekli sistem izinleri."
            )
            
            CardContainer {
                HStack(spacing: 14) {
                    Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(permissions.hasAccessibilityPermission ? .green : .orange)
                        .font(.system(size: 26))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Erişilebilirlik İzni")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        Text("Pencereleri yönetmek, odaklamak ve kısayolları çalıştırmak için gereklidir.")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if permissions.hasAccessibilityPermission {
                        Text("Aktif")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                    } else {
                        Button("İzin Ver") {
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            // App info card
            CardContainer {
                HStack(spacing: 16) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WinMac")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("Sürüm 3.7.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Reusable Modern UI Components

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

private struct CardContainer<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

private struct ModernToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
    }
}

private struct ShortcutPill: View {
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
                .lineLimit(1)
            Spacer()
        }
    }
}
