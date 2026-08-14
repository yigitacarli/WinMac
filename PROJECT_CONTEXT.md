# 🧠 WinMac (AltBridge) — Master Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve sürüm geçmişini kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac (veya AltBridge)
- **Amaç:** 
  1. `AltTab macOS` uygulamasının son sürümlerinde **Pro** abonelik arkasına aldığı tüm özellikleri (canlı arama, 3 farklı görünüm modu, kısayollar) **%100 ücretsiz, açık kaynak ve reklamsız** sunmak.
  2. `Rectangle` pencere yaslama (Aero Snap) ve `LinearMouse` (ters kaydırma, ivme sıfırlama, hız çarpanı) özelliklerini tek bir ultra hafif (~20MB RAM) yerel Swift 6 / SwiftUI uygulamasında toplamak.
  3. Windows'tan macOS'e geçen kullanıcıların tüm kronik alışkanlıklarını (`Ctrl+C/V`, Finder `Enter`/`F2`/`Delete`, `Win+V` Pano Geçmişi, `Win+L` Kilit) tek pakette çözmek.

---

## 📝 Sürüm Geçmişi (Changelog)

### Sürüm 2.1.0 (Güncel)
- **İkon Tasarımı:** Arka plan manzarası ve dock simgeleri tamamen temizlendi; saf koyu mat Apple süperelipsi (squircle) üzerinde ışıldayan neon cam katmanları yerleştirildi. %100 şeffaf köşeler ve Apple ortam gölgesi eklendi.
- **Dock & Reopen Entegrasyonu:** Uygulama `/Applications` veya Launchpad'den tıklandığında ayarlar penceresinin anında odaklanması (`applicationShouldHandleReopen`) sağlandı.
- **LaunchServices:** `lsregister` ve Dock önbelleği otomatik yenileme desteği.

### Sürüm 2.0.0
- **Rectangle Entegrasyonu:** Tüm yarı ekran, çeyrek ekran, 3'lü bölme ve çoklu monitör kısayolları (`⌥ + ⌃ + Oklar / U / I / J / K / D / F / G / C / Return / ⌘`) eklendi.
- **LinearMouse Entegrasyonu:** Bağımsız dikey/yatay ters kaydırma, kaydırma hızı çarpanı (0.5x - 3.0x), Shift+Tekerlek yatay kaydırma ve doğrusal ivme (Linear curve) kontrolleri eklendi.
- **Liquid Glassmorphism:** `Option + Tab` ekranı çok katmanlı Apple buzlu cam efekti, 3D Keycap tuşları ve 120 FPS yaylanma animasyonlarıyla baştan tasarlandı.
- **İsimlendirme:** Tüm "AltTab" ibareleri "Alt + Tab" olarak güncellendi.
- **DMG Paketi:** Tek tıkla indirilebilir `WinMac.dmg` yükleyici scripti (`scripts/create_dmg.sh`) eklendi.

### Sürüm 1.0.0
- Temel Alt+Tab pencere tarayıcı, canlı önizlemeler, `Win+V` pano geçmişi, Finder Enter/F2/Delete düzeltmeleri ve durum çubuğu menüsü oluşturuldu.

---

## 🏗️ Proje Mimarisi & Dosya Haritası

```
hopeful-lovelace/
├── Package.swift                     # SPM derleme manifesti (Swift 6, macOS 14+)
├── .gitignore                        # Git dışlama kuralları
├── README.md                         # Kullanıcı odaklı GitHub dokümantasyonu
├── PROJECT_CONTEXT.md                # Geliştirici & AI için kalıcı hafıza ve mimari
├── scripts/
│   ├── package_app.sh                # Release derleme, Info.plist ve ad-hoc imzalama scripti
│   ├── create_dmg.sh                 # Sıkıştırılmış DMG kurulum paketi oluşturucu
│   ├── make_pure_icon.py             # Apple Squircle kırpma ve şeffaf köşe/gölge üretici
│   └── make_macos_icon.py            # İkon seti maskeleme aracı
├── Resources/
│   ├── AppIcon.icns                  # Çoklu retina çözünürlüklü macOS ikonu
│   ├── AppIcon_1024.png              # 1024x1024 master şeffaf squircle ikon
│   ├── Info.plist                    # Bundle ID, CFBundleIconFile, macOS 14+ ayarları
│   └── WinMac.entitlements           # macOS yetkilendirme dosyası
└── Sources/
    ├── main.swift                    # NSApplication.shared (.regular policy) & AppDelegate başlatıcı
    ├── WinMacApp.swift               # AppDelegate: Status bar, Dock ikonu & Reopen yöneticisi
    ├── Core/
    │   ├── AppSettings.swift         # UserDefaults destekli @MainActor ayar modeli
    │   ├── PermissionsManager.swift  # Accessibility & Screen Recording izin kontrolü
    │   ├── EventTapManager.swift     # Global CGEventTap (sıfır gecikmeli tuş & fare dinleyici)
    │   └── SystemUtils.swift         # Ekran hesaplama, kilit, ekran alıntısı, tuş sentezleme
    ├── AltTab/
    │   ├── WindowModel.swift         # Pencere veri modeli (ID, pid, appName, title, bounds, icon, thumbnail)
    │   ├── WindowEngine.swift        # CGWindowList & AXUIElement pencere tarama ve odaklama
    │   ├── ThumbnailCache.swift      # Retina kalitesinde canlı ekran görüntüsü önbelleği
    │   ├── AltTabState.swift         # @MainActor switcher durumu ve klavye gezinme mantığı
    │   ├── AltTabHUDController.swift # Floating NSPanel pencere yöneticisi
    │   └── Views/
    │       ├── AltTabHUDView.swift   # Glassmorphic Liquid Blur ana overlay
    │       ├── ThumbnailGridView.swift # Mod 1: Küçük resim ızgarası + App badge
    │       ├── AppIconGridView.swift   # Mod 2: Büyük uygulama simgeleri ızgarası
    │       ├── TitleListView.swift     # Mod 3: Kompakt başlık / liste görünümü
    │       └── SearchBarView.swift   # Canlı Type-to-Search filtre arama çubuğu
    ├── MouseScroll/
    │   ├── ScrollInverter.swift      # Bağımsız fare tekerleği tersine çevirici (Trackpad doğal kalır)
    │   ├── MouseAcceleration.swift   # Doğrusal fare ivmelenmesi kontrolü
    ├── KeyboardBridge/
    │   ├── CtrlToCmdMapper.swift     # Ctrl+C/V/Z/A/S/F/W/T -> Cmd dönüştürücü (Whitelist destekli)
    │   ├── FinderBridge.swift        # Finder: Enter ile aç, F2 ile yeniden adlandır, Delete ile çöpe at
    │   └── SystemShortcuts.swift     # Win+L (Kilit), Ctrl+Shift+Esc (Görev Yöneticisi), Win+Shift+S (Snipping)
    ├── Clipboard/
    │   ├── ClipboardItem.swift       # Pano kayıt modeli
    │   ├── ClipboardManager.swift    # NSPasteboard dinleyici ve hafıza yöneticisi
    │   ├── ClipboardHUDController.swift # Win+V için NSPanel yöneticisi
    │   └── ClipboardHUDView.swift    # Win+V aranabilir SwiftUI pano arayüzü
    ├── WindowSnap/
    │   └── SnapEngine.swift          # Aero Snap: ⌥+⌃+Ok tuşları ile ekran bölme (1/2, 1/3, 1/4, Maximize)
    └── Settings/
        ├── SettingsWindowController.swift # Ayarlar penceresi yöneticisi
        └── SettingsView.swift        # Çok sekmeli modern SwiftUI Ayarlar paneli
```
