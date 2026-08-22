# 🧠 WinMac (Master Suite) — Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve sürüm geçmişini kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac
- **Sürüm:** v1.3
- **Son Güncelleme:** 22 Ağustos 2026
- **Ana Hedef:** macOS için pencere yönetimi, fare denetimi, pencere değiştirici, Windows klavye köprüsü ve pano geçmişini tek bir hafif, yerel Swift uygulamasında birleştirmek.

---

## 🚀 Sürüm 1.3 Yenilikleri (22 Ağustos 2026)

### Arayüzün Baştan Tasarımı — Native macOS Ayarlar Paneli
- `SettingsView.swift` sıfırdan yazıldı: Apple System Settings birebir görünümü (`NavigationSplitView` + `List(selection:)` sidebar + `Form` + `.formStyle(.grouped)`).
- Üçüncü parti marka isimleri menülerden kaldırıldı; işlevsel bölüm adları kullanılıyor: **Genel**, **Pencere Yönetimi**, **Fare ve Kaydırma**, **Pencere Değiştirici**, **Klavye Kısayolları**, **Otomatik Çıkış**.
- Kompakt tek pencere: 720×500, standart titlebar, `fullSizeContentView`.
- Yeni `ToggleRow`, `PickerRow`, `SliderRow`, `ShortcutRow` satır bileşenleri; tüm ayarlar gruplu inset formlarda.
- Otomatik Çıkış pane'inde hariç tutulan uygulamalar artık seçim gerektirmeden satır satır silinebiliyor (+ "Uygulama Ekle…" `.application` content-type filtreli NSOpenPanel).
- Genel pane'ine **Girişte Otomatik Başlat** anahtarı eklendi (SMAppService).
- `SettingsWindowController` native başlıklı pencereye çevrildi (şeffaf titlebar hilesi kaldırıldı), autosave adı `v5`.

### Düzeltilen Bozuk Fonksiyonlar
1. **SystemShortcuts dead code'tu** → `EventTapManager` pipeline'a bağlandı. `⌥⇧S` ekran alıntısı artık çalışıyor; `⌘⌥L` kilit çakışması önlendi.
2. **AltTab ilk Tab'da 2 pencere atlıyordu** → `reloadWindows` artık index=0'dan başlar; EventTap tek `selectNext()` yapar.
3. **AltTab sıralaması tersineydi** → frontmost uygulamanın pencereleri artık listenin BAŞINA gelir (index 0 = aktif pencere).
4. **launchAtLogin no-op'tu** → `SMAppService.mainApp.register()/unregister()` bağlandı.
5. **SwiftQuit "Seçileni Çıkar" hep son öğeyi siluyordu** → yeni listede her satırın kendi silme butonu var.
6. **Her açılışta ayar penceresi zorla açılıyordu** → yalnızca erişilebilirlik izni eksikse açılır; sonrasında Dock tıklaması (`applicationShouldHandleReopen`) açar.
7. **Sürüm numarası elle gömülüydu** → `AppDelegate.appVersion` CFBundleShortVersionString'ten okur.
8. Status bar menüsü işlevsel adlarla sadeleştirildi (üçüncü parti marka referansları kaldırıldı).
9. `.github_sources/` (Rectangle, AltTab, LinearMouse, SwiftQuit referans klonları) repodan çıkarılıp `.gitignore`'a eklendi; yalnızca yerel portlama referansı olarak kalır.

---

## 🏗️ Proje Mimarisi & Dosya Haritası

```
hopeful-lovelace/
├── Package.swift                     # SPM derleme manifesti (Swift 6, macOS 14+)
├── README.md                         # Kullanıcı odaklı dokümantasyon
├── PROJECT_CONTEXT.md                # Geliştirici & AI için master mimari ve hafıza
├── scripts/
│   ├── package_app.sh                # Release derleme, ad-hoc imzalama ve /Applications kurulumu
│   ├── create_dmg.sh                 # Sıkıştırılmış DMG kurulum paketi oluşturucu
│   ├── make_pure_icon.py             # Apple Squircle ikon aracı
│   └── make_macos_icon.py            # İkon seti maskeleme aracı
├── Resources/
│   ├── AppIcon.icns                  # Çoklu retina çözünürlüklü macOS ikonu
│   ├── AppIcon_1024.png              # 1024x1024 master squircle ikon
│   ├── WinMac.entitlements           # Sandbox / Accessibility izin tanımları
│   └── Info.plist                    # Bundle ID, CFBundleIconFile, macOS 14+ ayarları
└── Sources/
    ├── main.swift                    # NSApplication.shared başlatıcı
    ├── WinMacApp.swift               # AppDelegate: Status bar, Dock ikonu & Reopen yöneticisi
    ├── Core/
    │   ├── AppSettings.swift         # UserDefaults destekli @MainActor ayar modeli (6 modül)
    │   ├── PermissionsManager.swift  # Accessibility & Screen Recording izin kontrolü
    │   ├── EventTapManager.swift     # Global Unified CGEventTap (.cgSessionEventTap / .cghidEventTap)
    │   └── SystemUtils.swift         # Ekran hesaplama, kilit, ekran alıntısı, tuş sentezleme
    ├── SwiftQuit/
    │   └── SwiftQuitEngine.swift     # Son pencere kapandığında uygulamayı sonlandıran motor
    ├── AltTab/
    │   ├── WindowModel.swift         # Pencere veri modeli
    │   ├── WindowEngine.swift        # Pencere tarama ve odaklama
    │   ├── ThumbnailCache.swift      # Canlı önizleme önbelleği
    │   ├── AltTabState.swift         # Switcher klavye gezinme ve filtreleme
    │   ├── AltTabHUDController.swift # Floating NSPanel pencere yöneticisi
    │   └── Views/                    # Switcher görünüm modları
    ├── MouseScroll/
    │   ├── ScrollInverter.swift      # LinearMouse: Bağımsız tekerlek ayrımı, 1:1 Doğrusal ivme, Shift+Wheel
    │   └── ScrollWheelEventView.swift # CGEvent kaydırma dönüştürücü
    ├── KeyboardBridge/
    │   ├── CtrlToCmdMapper.swift     # Ctrl+C/V/Z/Y/A/S/F/W/T/P/N/R, Backspace, Win tuşları
    │   └── SystemShortcuts.swift     # Sistem kısayolları ve Finder / Task Manager tetikleyicileri
    ├── Clipboard/
    │   ├── ClipboardItem.swift       # Pano kayıt modeli
    │   ├── ClipboardManager.swift    # NSPasteboard dinleyici ve hafıza
    │   ├── ClipboardHUDController.swift # Win+V için NSPanel yöneticisi
    │   └── ClipboardHUDView.swift    # Win+V aranabilir SwiftUI pano arayüzü
    ├── WindowSnap/
    │   ├── AccessibilityElement.swift # AXUIElement sarmalayıcı
    │   ├── FootprintWindow.swift     # Hayalet önizleme penceresi
    │   ├── HotKeyManager.swift       # Carbon RegisterEventHotKey global kısayollar
    │   ├── SnapEngine.swift          # Aero Snap & Drag-to-Snap & Cycle Fractions motoru
    │   ├── SnapOverlayController.swift # Drag-to-snap şeffaf önizleme paneli
    │   └── WindowCalculation.swift   # Pencere geometri ve gap hesaplama motoru
    └── Settings/
        ├── SettingsWindowController.swift # Native başlıklı ayar penceresi (720×500, autosave v5)
        └── SettingsView.swift        # System Settings tarzı NavigationSplitView + grouped Form panelleri
```
