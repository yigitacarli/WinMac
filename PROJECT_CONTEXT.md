# 🧠 WinMac (AltBridge) — Master Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve sürüm geçmişini kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac
- **Amaç:** 
  1. `AltTab macOS` uygulamasının son sürümlerinde **Pro** abonelik arkasına aldığı tüm özellikleri (canlı arama, 3 farklı görünüm modu, kısayollar) **%100 ücretsiz, açık kaynak ve reklamsız** sunmak.
  2. `Rectangle Pro` pencere yaslama (Aero Snap, Drag-to-Snap Ghost Overlay, Cycle Fractions 1/2 -> 2/3 -> 1/3, Window Gaps, Resize) özelliklerini Carbon Hotkeys ile 0ms gecikmeli sunmak.
  3. `LinearMouse Pro` (bağımsız dikey/yatay ters kaydırma, Cmd+Tekerlek Yakınlaştırma, Shift+Tekerlek yatay kaydırma, Option+Tekerlek 3x hızlı kaydırma, Ctrl+Tekerlek hassas kaydırma, ivme sıfırlama) özelliklerini entegre etmek.
  4. `SwiftQuit` motoru ile Mac'te sol üstteki kırmızı 'X' butonuna basılıp son pencere kapandığında uygulamanın Windows'taki gibi **otomatik olarak tamamen sonlanmasını (Quit)** sağlamak.
  5. Windows'tan macOS'e geçen kullanıcıların tüm kronik alışkanlıklarını (`Ctrl+C/V`, Finder `Enter`/`F2`/`Delete`, `Win+V` Pano Geçmişi, `Win+L` Kilit) tek pakette çözmek.

---

## 📝 Sürüm Geçmişi (Changelog)

### Sürüm 3.1.0 (Güncel)
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
    │   ├── CtrlToCmdMapper.swift     # Ctrl+C/V/Z/A/S/F/W/T -> Cmd dönüştürücü
    │   ├── FinderBridge.swift        # Finder: Enter ile aç, F2 yeniden adlandır, Delete çöpe at
    │   └── SystemShortcuts.swift     # Win+L (Kilit), Ctrl+Shift+Esc (Etkinlik Monitörü)
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
