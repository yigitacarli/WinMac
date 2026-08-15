# 🧠 WinMac (AltBridge) — Master Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve sürüm geçmişini kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac
- **Amaç:** 
  1. **Pencere Değiştirici (Window Switcher):** Canlı arama, 3 farklı görünüm modu, özelleştirilebilir kısayollar (Option+Tab & Control+Tab) ve 0ms gecikmeli pencere odaklama.
  2. **Pencere Yaslama & Düzenleme (Window Snapping):** Ekran kenarlarına sürükleyerek (Aero Snap) veya global Carbon kısayollarıyla pencereleri 1/2, 2/3, 1/3, çeyrek veya tam ekran hizalama, pencere boşlukları (gaps).
  3. **Fare & Kaydırma Denetimi (Mouse & Scroll Engine):** Bağımsız standart fare tekerleği, yatay ters kaydırma, Cmd+Tekerlek Yakınlaştırma (Zoom), Shift+Tekerlek yatay kaydırma, Option+Tekerlek 3x hızlı kaydırma, Control+Tekerlek 0.3x hassas kaydırma ve 1:1 doğrusal ivme kontrolü.
  4. **Otomatik Çıkış Motoru (Auto-Quit on Close):** Mac'te sol üstteki kırmızı 'X' butonuna basılıp son pencere kapandığında uygulamanın arka planda gereksiz bellek tüketmesini engelleyerek otomatik olarak sonlanmasını sağlamak (Sarı - minimize ve Cmd+H gizleme korumalı).
  5. **Klavye Kısayolları & Pano:** Evrensel `Ctrl+C/V/Z/Y/A`, `Option+L` Ekran Kilidi, `Ctrl+Shift+Esc` Etkinlik Monitörü ve `Option+V` Pano Geçmişi.

---

## 📝 Sürüm Geçmişi (Changelog)

### Sürüm 4.1.0 (Güncel)
- **LinearMouse & Rectangle Birebir Çekirdek Düzeltmeleri (6 Kritik Hata):**
  1. **TCC İzin Guard & Servis Başlatma (#1):** `AXIsProcessTrusted()` guard'ı esnetilerek HotKey ve NSEvent global fare monitörlerinin her zaman çalışması sağlandı. `PermissionsManager` üzerinden `startScrollEventTapIfNeeded` ile izin verildiği anda CGEventTap otomatik ayağa kaldırılır.
  2. **LinearMouse IOHID Kernel Hızlandırma (#2):** `ScrollInverter.swift` içinde property key `"HIDMouseAcceleration"` ve değer `-1.0 as CFNumber` (veya `sensitivity as CFNumber`) olarak LinearMouse `PointerSpeed.swift` ile birebir eşitlendi.
  3. **Trackpad & Fiziksel Fare Ayrımı (#3):** `scrollWheelEventIsContinuous` kontrolü ile trackpad / Magic Mouse jestleri filtrelendi, doğal kaydırma bozulmadan sadece harici fare tekerleği işlenir hale getirildi.
  4. **Rectangle Accessibility Sırası (#4):** `SnapEngine.swift` `setFrame` metodu Rectangle `AccessibilityElement.swift` standardında (Pozisyon → Boyut → Pozisyon) yeniden düzenlendi, Chromium ve Electron uygulamalarında kayma giderildi.
  5. **Rectangle Footprint Snap Önizleme (#5):** `SnapOverlayController.swift` içerisindeki önizleme kutusu Rectangle `FootprintWindow.swift` ile birebir uyumlu `Color.accentColor.opacity(0.22)` ve 10 corner radius sadeliğine kavuşturuldu.
  6. **Kesintisiz Tap Kurtarma (#6):** `EventTapManager.swift` içinde `tapDisabledByUserInput` veya `tapDisabledByTimeout` durumlarında servisler kalıcı kapatılmak yerine anında `CGEvent.tapEnable(tap, true)` ile yeniden aktif edilir.

### Sürüm 4.0.0

### Sürüm 3.8.0

### Sürüm 3.7.0

### Sürüm 3.3.0

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
│   ├── package_app.sh                # Release derleme ve ad-hoc imzalama scripti
│   ├── create_dmg.sh                 # Sıkıştırılmış DMG kurulum paketi oluşturucu
│   ├── make_pure_icon.py             # Apple Squircle kırpma ve şeffaf köşe/gölge üretici
│   └── make_macos_icon.py            # İkon seti maskeleme aracı
├── Resources/
│   ├── AppIcon.icns                  # Çoklu retina çözünürlüklü macOS ikonu
│   ├── AppIcon_1024.png              # 1024x1024 master şeffaf squircle ikon
│   └── Info.plist                    # Bundle ID, CFBundleIconFile, macOS 14+ ayarları
└── Sources/
    ├── main.swift                    # NSApplication.shared (.regular policy) başlatıcı
    ├── WinMacApp.swift               # AppDelegate: Status bar, Dock ikonu & Reopen yöneticisi
    ├── Core/
    │   ├── AppSettings.swift         # UserDefaults destekli @MainActor ayar modeli
    │   ├── PermissionsManager.swift  # Accessibility & Screen Recording izin kontrolü
    │   ├── EventTapManager.swift     # Global CGEventTap (.cgSessionEventTap) dinleyici
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
    │   └── ScrollInverter.swift      # LinearMouse Pro: Ters kaydırma, Zoom, Shift/Opt/Ctrl modifikatörleri
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
    │   └── SnapOverlayController.swift # Drag-to-snap hayalet mavi önizleme kutusu
    └── Settings/
        ├── SettingsWindowController.swift # Ayarlar penceresi yöneticisi
        └── SettingsView.swift        # Çok sekmeli modern SwiftUI Ayarlar paneli
```
