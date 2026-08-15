# 🧠 WinMac (AltBridge) — Master Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve sürüm geçmişini kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac
- **Mevcut Sürüm:** v4.3.0
- **Amaç:** 
  1. **Pencere Değiştirici (Window Switcher):** Canlı arama, 3 farklı görünüm modu, özelleştirilebilir kısayollar (Option+Tab & Control+Tab) ve 0ms gecikmeli pencere odaklama.
  2. **Pencere Yaslama & Düzenleme (Window Snapping):** Ekran kenarlarına sürükleyerek (Aero Snap) şeffaf önizleme kutusu ve otomatik yaslama veya global Carbon kısayollarıyla pencereleri 1/2, 2/3, 1/3, çeyrek veya tam ekran hizalama, pencere boşlukları (gaps).
  3. **Fare & Kaydırma Denetimi (Mouse & Scroll Engine):** Harici fare için standart ters kaydırma (Windows yönü), Trackpad jestlerini %100 koruyan doğal kaydırma ayrımı, Windows tarzı doğrusal (1:1) ivme kontrolü (`HIDMouseAcceleration = -1.0`), fare imleç hassasiyeti ve hızı, Cmd+Tekerlek Yakınlaştırma (Zoom), Shift+Tekerlek yatay kaydırma, Option+Tekerlek 3x hızlı kaydırma, Control+Tekerlek 0.3x hassas kaydırma.
  4. **Otomatik Çıkış Motoru (Auto-Quit on Close):** Mac'te sol üstteki kırmızı 'X' butonuna basılıp son pencere kapandığında uygulamanın arka planda gereksiz bellek tüketmesini engelleyerek otomatik olarak sonlanmasını sağlamak (Sarı - minimize ve Cmd+H gizleme korumalı).
  5. **Klavye Kısayolları & Pano:** Evrensel `Ctrl+C/V/Z/Y/A`, `Option+L` Ekran Kilidi, `Ctrl+Shift+Esc` Etkinlik Monitörü ve `Option+V` Pano Geçmişi.

---

## 📝 Sürüm Geçmişi (Changelog)

### Sürüm 4.3.0 (Güncel)
- **Pencere Yaslama (Aero Snap & Ghost Preview):**
  1. `EventTapManager.swift` içerisinde fare sürükleme dinleyicisi `NSEvent` global monitor yerine doğrudan `CGEventTap` (`.leftMouseDown`, `.leftMouseDragged`, `.leftMouseUp`) seviyesine taşındı. Pencere modal sürükleme döngülerinde fare olaylarının kaybolması engellendi.
  2. `SnapOverlayController.swift` pencere seviyesi `.overlayWindow` / `.screenSaver` katmanına çıkarıldı ve animasyon alpha çakışması (görünmezlik hatası) giderildi. Şeffaf, hafif buzlu cam efektli modern önizleme kutusu uygulandı.
  3. `SnapEngine.swift` içerisine katmanlı pencere tespiti (`AXUIElementCopyElementAtPosition` -> `kAXFocusedWindowAttribute` -> `kAXMainWindowAttribute`) ve gap hesaplaması eklendi.
- **Linear Mouse & Kaydırma & İvme Motoru:**
  1. Trackpad ve harici fare tekerleği ayrımı kesinleştirildi (`scrollWheelEventIsContinuous != 0`, `scrollPhase != 0`, `momentumPhase != 0` kontrolü ile Trackpad jestlerine dokunulmaz, yalnızca fiziksel fare tekerleği tersine çevrilir).
  2. Windows tarzı doğrusal (1:1) fare ivmesi donanım seviyesinde `IOHIDServiceClientSetProperty` ile `HIDMouseAcceleration = -1.0` ve `com.apple.mouse.scaling = -1` senkronizasyonu ile sağlandı.
  3. Fare imleç hızı ve hassasiyet kontrolleri geliştirildi.
- **Yerel macOS Arayüz Tasarımı (UI Redesign):**
  1. Yapay zeka tasarım klişeleri (aşırı büyük neon kartlar, mor/cyan gradyanlar, hantal çerçeveler) tamamen kaldırıldı.
  2. Apple Human Interface Guidelines'a uygun; sol tarafta kompakt sidebar navigasyonu, sağ tarafta standart Form / Grouped kartlar, net SF Symbols ve Apple klavye tuşu badge'leri içeren kompakt (720x490) şık bir ayarlar penceresi oluşturuldu.
- **Paketleme & Kurulum:**
  1. `./scripts/package_app.sh` scripti derlenen ve imzalanan `WinMac.app` paketini doğrudan `/Applications/WinMac.app` dizinine otomatik olarak yükleyecek şekilde güncellendi.

### Sürüm 4.2.0
- **Pencere Yaslama & Sürükleme Motoru İyileştirmeleri:**
  1. `SnapEngine.swift` içerisindeki ekran tespit mantığı `NSMouseInRect` yerine tam kapalı sınır kontrolü ile güncellendi.
  2. Pencere tespitinde pencerenin merkez noktası (`center`) ve kesişim (`intersects`) hesaplamasıyla çoklu ekran ve tek ekran ayrımı geliştirildi.

### Sürüm 3.1.0
- **SwiftQuit Entegrasyonu (`SwiftQuitEngine.swift`):** Bir uygulamanın son penceresi kırmızı 'X' ile kapatıldığında, uygulamanın arka planda asılı kalmasını engelleyip Windows tarzı otomatik olarak tamamen kapanmasını (Quit) sağlayan motor eklendi. Gecikme süresi (0s, 1s, 2s) ve koruma listesi ayarları eklendi.
- **Carbon HotKey Mimarisi (`HotKeyManager.swift`):** Rectangle kısayolları için macOS çekirdek seviyesi `RegisterEventHotKey` sistemi entegre edildi.
- **LinearMouse `.cgSessionEventTap` Mimarisi:** Fare dinleme ve modifikatör motoru kullanıcı oturumu seviyesine taşınarak EventTap kilitlenmeleri çözüldü.

### Sürüm 3.0.0
- **Rectangle Pro & LinearMouse Pro Paketi:** Drag-to-Snap görsel hayalet önizleme kutusu, art arda basışta 1/2 -> 2/3 -> 1/3 döngüleri, pencere boşlukları (gaps), Cmd+Tekerlek Zoom, Shift+Tekerlek yatay kaydırma eklendi.

### Sürüm 2.1.0
- **Sade İkon:** Manzara ve dock silindi; saf mat koyu Apple squircle üzerinde 3D neon cam katmanları yerleştirildi. %100 şeffaf köşeler ve Apple ortam gölgesi üretildi.
- **Dock & Reopen:** `/Applications` veya Launchpad'den tıklandığında ayarlar penceresinin doğrudan açılması sağlandı.

---

## 🏗️ Proje Mimarisi & Dosya Haritası

```
hopeful-lovelace/
├── Package.swift                     # SPM derleme manifesti (Swift 6, macOS 14+)
├── README.md                         # Kullanıcı odaklı GitHub dokümantasyonu
├── PROJECT_CONTEXT.md                # Geliştirici & AI için master mimari ve hafıza
├── scripts/
│   ├── package_app.sh                # Release derleme, ad-hoc imzalama ve /Applications kurulumu
│   ├── create_dmg.sh                 # Sıkıştırılmış DMG kurulum paketi oluşturucu
│   ├── make_pure_icon.py             # Apple Squircle kırpma ve şeffaf köşe/gölge üretici
│   └── make_macos_icon.py            # İkon seti maskeleme aracı
├── Resources/
│   ├── AppIcon.icns                  # Çoklu retina çözünürlüklü macOS ikonu
│   ├── AppIcon_1024.png              # 1024x1024 master şeffaf squircle ikon
│   ├── WinMac.entitlements           # Sandbox / Accessibility izin tanımları
│   └── Info.plist                    # Bundle ID, CFBundleIconFile, macOS 14+ ayarları
└── Sources/
    ├── main.swift                    # NSApplication.shared (.regular policy) başlatıcı
    ├── WinMacApp.swift               # AppDelegate: Status bar, Dock ikonu & Reopen yöneticisi
    ├── Core/
    │   ├── AppSettings.swift         # UserDefaults destekli @MainActor ayar modeli
    │   ├── PermissionsManager.swift  # Accessibility & Screen Recording izin kontrolü
    │   ├── EventTapManager.swift     # Global Unified CGEventTap (.cgSessionEventTap / .cghidEventTap)
    │   └── SystemUtils.swift         # Ekran hesaplama, kilit, ekran alıntısı, tuş sentezleme
    ├── SwiftQuit/
    │   └── SwiftQuitEngine.swift     # Son pencere kapandığında uygulamayı sonlandıran motor
    ├── AltTab/
    │   ├── WindowModel.swift         # Pencere veri modeli
    │   ├── WindowEngine.swift        # Pencere tarama ve odaklama
    │   ├── ThumbnailCache.swift      # Retina kalitesinde canlı önizleme önbelleği
    │   ├── AltTabState.swift         # Switcher klavye gezinme ve filtreleme
    │   ├── AltTabHUDController.swift # Floating NSPanel pencere yöneticisi
    │   └── Views/
    │       ├── AltTabHUDView.swift   # Glassmorphic Liquid Blur ana overlay
    │       ├── ThumbnailGridView.swift # Mod 1: Küçük resim ızgarası
    │       ├── AppIconGridView.swift   # Mod 2: Büyük uygulama simgeleri
    │       ├── TitleListView.swift     # Mod 3: Kompakt başlık / liste
    │       └── SearchBarView.swift   # Canlı Type-to-Search filtre çubuğu
    ├── MouseScroll/
    │   └── ScrollInverter.swift      # LinearMouse: Bağımsız tekerlek ayrımı, 1:1 Doğrusal ivme, Zoom, Hızlı kaydırma
    ├── KeyboardBridge/
    │   ├── CtrlToCmdMapper.swift     # Ctrl+C/V/Z/Y/A/S/F/W/T/P/N/R -> Cmd dönüştürücü
    │   └── SystemShortcuts.swift     # Option+L (Kilit), Ctrl+Shift+Esc (Etkinlik Monitörü)
    ├── Clipboard/
    │   ├── ClipboardItem.swift       # Pano kayıt modeli
    │   ├── ClipboardManager.swift    # NSPasteboard dinleyici ve hafıza
    │   ├── ClipboardHUDController.swift # Win+V için NSPanel yöneticisi
    │   └── ClipboardHUDView.swift    # Win+V aranabilir SwiftUI pano arayüzü
    ├── WindowSnap/
    │   ├── HotKeyManager.swift       # Carbon RegisterEventHotKey global kısayollar
    │   ├── SnapEngine.swift          # Aero Snap & Drag-to-Snap & Cycle Fractions motoru
    │   └── SnapOverlayController.swift # Drag-to-snap şeffaf mavi önizleme paneli
    └── Settings/
        ├── SettingsWindowController.swift # Ayarlar penceresi yöneticisi
        └── SettingsView.swift        # Kompakt & şık yerel macOS SwiftUI Ayarlar paneli
```
