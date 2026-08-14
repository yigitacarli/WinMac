# 🧠 WinMac (AltBridge) — Master Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve gelecek yol haritasını kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac (veya AltBridge / AltTabPlus)
- **Amaç:** 
  1. `AltTab macOS` uygulamasının son sürümlerinde **Pro** abonelik arkasına aldığı tüm özellikleri (canlı arama, 3 farklı görünüm modu, kısayollar) **%100 ücretsiz, açık kaynak ve reklamsız** sunmak.
  2. Windows'tan macOS'e geçen veya Mac'te üretkenlik arayan kullanıcıların en büyük kronik sorunlarını (ters fare tekerleği, `Ctrl+C/V` alışkanlığı, Finder dosya açma, `Win+V` pano geçmişi, pencere yaslama vb.) tek bir hafif (~20MB RAM) yerel Swift/SwiftUI uygulamasında çözmek.

---

## 🏗️ Proje Mimarisi & Dosya Haritası

```
hopeful-lovelace/
├── Package.swift                     # SPM derleme manifesti (Swift 6, macOS 14+)
├── .gitignore                        # Git dışlama kuralları
├── README.md                         # Kullanıcı odaklı GitHub dokümantasyonu
├── PROJECT_CONTEXT.md                # Geliştirici & AI için kalıcı hafıza ve mimari
├── scripts/
│   └── package_app.sh                # Release derleme, Info.plist ve ad-hoc imzalama scripti
├── Resources/
│   ├── Info.plist                    # LSUIElement = true (Menü çubuğu aracı) & İzin açıklamaları
│   └── WinMac.entitlements           # macOS yetkilendirme dosyası
└── Sources/
    ├── main.swift                    # NSApplication & AppDelegate başlatıcı
    ├── WinMacApp.swift               # AppDelegate: NSStatusItem (menü çubuğu) & hızlı anahtarlar
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
    │   └── SnapEngine.swift          # Aero Snap: ⌥+⌃+Ok tuşları ile ekran bölme (1/2, 1/4, Maximize)
    └── Settings/
        ├── SettingsWindowController.swift # Ayarlar penceresi yöneticisi
        └── SettingsView.swift        # Çok sekmeli modern SwiftUI Ayarlar paneli
```

---

## 🛠️ Nasıl Derlenir ve Paketlenir?

1. **Geliştirme Modunda Derleme (Debug):**
   ```bash
   swift build
   ```
2. **Release Modunda `.app` Paketi Üretme:**
   ```bash
   ./scripts/package_app.sh
   ```
3. **Uygulamayı Çalıştırma:**
   ```bash
   open /Users/yigitacarli/Documents/antigravity/hopeful-lovelace/build/WinMac.app
   ```
   *Veya Uygulamalar klasörüne kopyalamak için:*
   ```bash
   cp -R build/WinMac.app /Applications/
   open /Applications/WinMac.app
   ```

---

## 🔒 Swift 6 ve Eşzamanlılık (Concurrency) Kuralları
- Tüm UI nesneleri (`NSHostingView`, `NSPanel`, `NSWindow`, `ObservableObject` UI State) `@MainActor` ile işaretlenmiştir.
- `EventTapManager`, `ScrollInverter`, `CtrlToCmdMapper`, `FinderBridge`, `ThumbnailCache` gibi düşük seviyeli sınıflar `@unchecked Sendable` olarak tanımlanıp UI güncellemelerini `DispatchQueue.main.async` veya `Task { @MainActor in ... }` ile iletir.
- Projede harici 3. parti bağımlılık yoktur; tamamen saf yerel macOS API'ları (`AppKit`, `SwiftUI`, `CoreGraphics`, `ApplicationServices`, `Combine`) kullanılmıştır.

---

## 🚀 Gelecek Yol Haritası (İleride Eklenebilecek Özellikler)
1. **Dock Üzeri Önizlemeler (Taskbar Hover):** Dock simgelerinin üzerine fareyle gelindiğinde mini pencereleri gösterme.
2. **Aero Shake:** Pencereyi sallayınca arkadaki tüm pencereleri simge durumuna küçültme.
3. **Pürüzsüz Kaydırma (Smooth Scroll):** Fare tekerleği için fizik tabanlı akıcı kaydırma interpolasyonu.
4. **Çoklu Dil Desteği:** Türkçe, İngilizce, Almanca, İspanyolca yerelleştirme (Localization).
