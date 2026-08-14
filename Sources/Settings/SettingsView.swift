import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var permissions = PermissionsManager.shared
    
    @State private var selectedTab: SettingsTab = .alttab
    
    public init() {}
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case alttab = "AltTab"
        case mouse = "Fare & Kaydırma"
        case keyboard = "Klavye"
        case finder = "Finder"
        case clipboard = "Pano (Win+V)"
        case snap = "Pencere Yaslama"
        case permissions = "İzinler & Hakkında"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .alttab: return "macwindow.on.rectangle"
            case .mouse: return "computermouse.fill"
            case .keyboard: return "keyboard.fill"
            case .finder: return "folder.fill"
            case .clipboard: return "doc.on.clipboard.fill"
            case .snap: return "rectangle.split.2x1.fill"
            case .permissions: return "checkmark.shield.fill"
            }
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 190)
        } detail: {
            VStack {
                switch selectedTab {
                case .alttab:
                    AltTabSettingsSection(settings: settings)
                case .mouse:
                    MouseSettingsSection(settings: settings)
                case .keyboard:
                    KeyboardSettingsSection(settings: settings)
                case .finder:
                    FinderSettingsSection(settings: settings)
                case .clipboard:
                    ClipboardSettingsSection(settings: settings)
                case .snap:
                    SnapSettingsSection(settings: settings)
                case .permissions:
                    PermissionsSettingsSection(permissions: permissions)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 720, height: 500)
    }
}

// MARK: - Sections

private struct AltTabSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("Pencere Değiştirici (Alt+Tab)").font(.headline)) {
                Toggle("AltTab'ı Etkinleştir", isOn: $settings.altTabEnabled)
                
                Picker("Görünüm Stili:", selection: $settings.switcherStyle) {
                    ForEach(SwitcherStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                
                Picker("Gösterilecek Ekran:", selection: $settings.displayMode) {
                    ForEach(SwitcherDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                
                Toggle("Yazarak Canlı Filtreleme (Type-to-Search)", isOn: $settings.searchFilterEnabled)
                Toggle("Gizli / Arka Plandaki Pencereleri Hariç Tut", isOn: $settings.hideHiddenApps)
            }
        }
    }
}

private struct MouseSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("Fare & Tekerlek Ergonomisi").font(.headline)) {
                Toggle("Bağımsız Fare Tekerleği Yönü (Windows Yönü)", isOn: $settings.invertMouseWheel)
                    .help("Trackpad doğal kaydırmada kalır, harici fare tekerleği Windows gibi aşağı/yukarı doğru kaydırır.")
                
                Text("💡 Trackpad hareketleriniz bozulmaz, yalnızca USB/Bluetooth fareniz tersine çevrilir.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Toggle("Pürüzsüz Kaydırma (Smooth Scrolling)", isOn: $settings.smoothScrollEnabled)
                Toggle("Doğrusal Fare İvmesi (1:1 Linear Curve)", isOn: $settings.disableMouseAcceleration)
                    .help("macOS'in ivmelenme algoritmasını devre dışı bırakır.")
            }
        }
    }
}

private struct KeyboardSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("Klavye & Muscle Memory").font(.headline)) {
                Toggle("Ctrl+C, Ctrl+V, Ctrl+Z, Ctrl+A -> Cmd Eşlemesi", isOn: $settings.ctrlToCmdRemapEnabled)
                
                Text("💡 Windows alışkanlıklarınızı doğrudan kullanabilirsiniz.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Toggle("Win + L ile Ekranı Kilitle (Option + L)", isOn: $settings.winLToLockEnabled)
                Toggle("Ctrl + Shift + Esc ile Görev Yöneticisini Aç", isOn: $settings.ctrlShiftEscTaskManager)
            }
        }
    }
}

private struct FinderSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("Finder (Dosya Gezgini) Kolaylıkları").font(.headline)) {
                Toggle("Enter Tuşu ile Dosyayı/Klasörü Aç (Cmd + O)", isOn: $settings.finderEnterToOpen)
                Toggle("F2 Tuşu ile Dosyayı Yeniden Adlandır", isOn: $settings.finderF2ToRename)
                Toggle("Delete / Backspace ile Çöp Kutusuna Gönder", isOn: $settings.finderDeleteToTrash)
            }
        }
    }
}

private struct ClipboardSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("Pano Geçmişi (Win + V / Option + V)").font(.headline)) {
                Toggle("Pano Geçmişini Etkinleştir", isOn: $settings.clipboardHistoryEnabled)
                
                Stepper("Maksimum Kayıt Sayısı: \(settings.maxClipboardItems)", value: $settings.maxClipboardItems, in: 10...200, step: 10)
                
                Button("Pano Geçmişini Temizle") {
                    ClipboardManager.shared.clearAll()
                }
                .padding(.top, 4)
            }
        }
    }
}

private struct SnapSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("Pencere Yaslama (Aero Snap)").font(.headline)) {
                Toggle("Ekran Bölme Kısayolları", isOn: $settings.snapShortcutsEnabled)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kısayol Tuşları:")
                        .font(.subheadline.bold())
                    Text("• ⌥ + ⌃ + Sol Ok: Sol Yarı Ekran")
                    Text("• ⌥ + ⌃ + Sağ Ok: Sağ Yarı Ekran")
                    Text("• ⌥ + ⌃ + Yukarı Ok: Tam Ekran (Maximize)")
                    Text("• ⌥ + ⌃ + Aşağı Ok: Merkeze Al")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

private struct PermissionsSettingsSection: View {
    @ObservedObject var permissions: PermissionsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sistem İzinleri & Durum")
                .font(.headline)
            
            // Accessibility Row
            HStack {
                Image(systemName: permissions.hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(permissions.hasAccessibilityPermission ? .green : .orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading) {
                    Text("Erişilebilirlik (Accessibility)")
                        .font(.system(size: 13, weight: .bold))
                    Text("Global kısayollar ve pencere odaklama için gereklidir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !permissions.hasAccessibilityPermission {
                    Button("İzin Ver") {
                        permissions.requestAccessibilityPermission()
                        permissions.openAccessibilitySettings()
                    }
                } else {
                    Text("Aktif")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
            
            // Screen Recording Row
            HStack {
                Image(systemName: permissions.hasScreenRecordingPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(permissions.hasScreenRecordingPermission ? .green : .orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading) {
                    Text("Ekran Kaydı (Screen Recording)")
                        .font(.system(size: 13, weight: .bold))
                    Text("AltTab küçük resimlerini (thumbnails) oluşturmak için gereklidir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !permissions.hasScreenRecordingPermission {
                    Button("İzin Ver") {
                        permissions.requestScreenRecordingPermission()
                        permissions.openScreenRecordingSettings()
                    }
                } else {
                    Text("Aktif")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("WinMac — Windows to Mac Swiss Army Knife")
                    .font(.subheadline.bold())
                Text("Sürüm 1.0.0 (Açık Kaynak & %100 Ücretsiz)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
