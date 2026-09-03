# 🧠 WinMac (Master Suite) — Project Context & Architecture

> **Bu dosya, projenin tüm bağlamını, mimarisini, teknik kararlarını ve sürüm geçmişini kalıcı olarak saklar.**
> Yeni bir sohbet, farklı bir yapay zeka modeli veya yeni bir geliştirici bu repoya geldiğinde doğrudan bu dosyayı okuyarak projeye kaldığı yerden sıfır kayıpla devam edebilir.

---

## 📌 Proje Özeti & Vizyon
- **Proje Adı:** WinMac
- **Sürüm:** v1.6
- **Lisans:** GPL-3.0 (bkz. `LICENSE`, `NOTICE`)
- **Son Güncelleme:** 3 Eylül 2026
- **Ana Hedef:** macOS için pencere yönetimi, pencere değiştirici, fare denetimi, Windows klavye köprüsü ve pano geçmişini tek bir hafif, yerel Swift uygulamasında birleştirmek.

---

## 🚀 Sürüm 1.6 — Lisans, Fare Modülü Dönüşü, Windows Yaslama Rengi (3 Eylül 2026)

1. **Lisans MIT → GPL-3.0.** AltTab ve SwiftQuit üst projeleri GPL-3.0; WinMac'in
   pencere değiştirici ve otomatik çıkış davranışları bunlardan model alındığı
   için (kod kopyası yok) bütün proje GPL-3.0 ile dağıtılıyor. `NOTICE` dosyası
   ilham alınan 4 projeyi ve lisanslarını listeler. README ve commit dili
   "1:1 port" yerine "davranış model alındı" olarak yumuşatıldı.
2. **Fare modülü geri döndü — bu kez LinearMouse (MIT) temelli, doğru şekilde.**
   `Sources/MousePointer/`: C SPI shim (`WinMacC` hedefi) + `PointerDeviceManager`
   (IOHID cihaz izleme) + apply/restore. İmleç ivmesi + hız + ivme kapatma;
   cihaz adı / donanım DPI / pil / sorgulama hızı (Hz) gösterimi; uygulama başına
   devre dışı bırakma listesi. Cihaz eklendiğinde ve `NSWorkspace.didWakeNotification`
   ile uykudan dönüldüğünde yeniden uygular. Modül kapatılınca sistem
   varsayılanları geri yüklenir. **Not:** private API'ler; macOS sürümüne göre
   kırılgan olabilir. Eski `ScrollInverter`'ın hatası tek seferlik uygulama +
   `defaults write com.apple.mouse.scaling` idi; ikisi de yok.
3. **Windows tarzı yaslama önizlemesi.** `FootprintWindow` artık gri yerine
   yarı saydam accent-mavi dolgu (#0078D4 @ 28%) + parlak mavi kenarlık.
4. **Uygulama içi üçüncü parti isimleri temizlendi** (Ayarlar "Hakkında" metni,
   `FootprintWindow` başlığı "Rectangle" → "WinMac", log önekleri). Kaynak koddaki
   davranış-atıf yorumları GPL gereği korundu.
5. **Yaslama düzeltmeleri:** çalışmayan `⌃⌥=`/`⌃⌥−` büyüt/küçült kısayolları
   kaldırıldı (WindowCalculation'da maximize'a düşüyordu). Üst/alt yarı için ölü
   döngü kolları temizlendi — yalnızca sol/sağ yarı 1/2→2/3→1/3 döngüsü yapıyor.

---

## 🚀 Sürüm 1.5 — GitHub Öncesi Temizlik (3 Eylül 2026)

Ayrıntılar: [AUDIT.md](AUDIT.md). Özet:

1. **LinearMouse / Fare-Kaydırma modülü tamamen kaldırıldı.** Hiçbir özelliği
   güvenilir çalışmıyordu ve `ScrollInverter` özel IOHID API'leriyle + kabuktan
   `defaults write -g com.apple.mouse.scaling` ile kullanıcının sistem fare
   ayarını sessizce değiştiriyordu. Fare denetimi artık BetterMouse/LinearMouse
   gibi adanmış araçlara bırakıldı. Silinen: `Sources/MouseScroll/`,
   `AppSettings` bölüm 3, `EventTapManager` scrollWheel dalı, "Fare ve Kaydırma"
   ayar paneli + menü öğesi.
2. **AltTab görünüm modları 4 → 2'ye indirildi** (Büyük Simgeler + Ayrıntılı
   Liste). `thumbnails` ve `compact` stilleri, `ThumbnailCache.swift`, kullanılmayan
   `ThumbnailGridView`/`AppIconGridView`/`TitleListView` dosyaları ve
   `WindowModel.thumbnail` alanı silindi. Ekran Kaydı izni artık hiç gerekmiyor.
3. **Sürüm tek kaynağa çekildi:** `Info.plist` → `1.4`/`14`; koddaki
   `"1.2"`/`"1.3"` fallback'leri `"1.4"`.
4. **Repo hijyeni:** `build/` ve `*.dmg` git takibinden çıkarıldı ve
   `.gitignore`'a eklendi; `.DS_Store` temizlendi.
5. **README.md ve LICENSE (MIT) eklendi;** `Info.plist`'e `NSAccessibilityUsageDescription`.
6. `EventTapManager.startScrollEventTapIfNeeded()` → `startEventTapIfNeeded()`.

---

## 🚀 Sürüm 1.4 — AltTab & LinearMouse Derin Düzeltmeler + Arayüz Yenilemesi (23 Ağustos 2026)

### Pencere Değiştirici Çekirdek Yeniden Yazımı
1. **Gerçek CGWindowID kimliği:** Yeni `CGWindowResolver.swift` tek seferlik `CGWindowListCopyWindowInfo` anlık görüntüsüyle AX pencerelerini pid+geometri eşlemesinden gerçek WindowServer kimliğine bağlıyor (tolerans <60). Eski sahte `pid<<8|index` ID'si AX sırası değişince değiştiği için thumbnail cache'i zehirleniyor ve MRU imkânsızdı. Kimlik artık kararlı.
2. **Z-order = MRU sıralaması:** Liste artık CGWindowList katman-0 ön-arka sırasına göre diziliyor; minimize/gizli pencereler sona atılıyor. ⇧Tab gerçek odak geçmişinde geri yürüyor. Eski "frontmost-pid comparator"u gerçekte sort yapmıyordu (rastgele sıra).
3. **AX eleman yan tablosu:** `WindowEngine.axElementsByID[CGWindowID]` taramada dolduruluyor; odaklama/kapatma/küçültme artık ID ile birebir elemana gidiyor. Title-eşleşmesi kaldırıldı (iki "Untitled" penceresi hep yanlış odaklanıyordu); geometri fallback'i var.
4. **Subrole filtresi:** Sadece `AXStandardWindow`/`AXDialog` kabul; toolbar/palet/sistem diyaloğu kartları eleniyor. Boyut eşiği 100×50'e yükseltildi (minimize muaf). Placeholder kart yalnızca ön plandaki app için üretiliyor (arka plan daemon spam'i bitti).
5. **Asenkron thumbnail:** `reloadWindows()` artık capture beklemeden paneli açıyor; `scheduleThumbnailRefresh` arka planda çekip oturum-token'ıyla yayınlıyor. Capture ≤640px'e ölçekleniyor (5K Retina RAM patlaması önlendi).
6. **Hover deadzone + tek input katmanı:** Panel açılış imleç konumu `hoverOrigin` olarak saklanıyor; 26px içinde hover seçimi ölü (AltTab'in deadzone'u). Local NSEvent monitor tamamen silindi — klavyenin TEK otoritesi global tap: `CGEventKeyboardGetUnicodeString` ile yazarak-ara tap içinde çalışıyor, backspace dahil. Key-repeat wrap bastırma: `keyboardEventAutorepeat` iken seçim uçlara sabitleniyor.
7. **Panel davranışları:** Seviye `.screenSaver`→`.popUpMenu` (orijinalin bilinçli tercihi; drag&drop bozulması), dışarı tıkla-kapat monitor'ü, HUD içerik-boyutuna shrink-wrap, `canBecomeKey=true` panel alt sınıfı.

### Fare/Kaydırma Pipeline'ı (LinearMouse matematiği)
8. **Dört kolonlu matris dönüşümü:** `ScrollWheelEventView.transform(matrix:)` integer/fixedPt/pointDelta/**IOHID** kolonlarını birlikte dönüştürüyor; integer delta `sign×max(round(|v|),1)` ile normalize (eski kör çarpan küçük deltaları 0'a truncate edip kaydırmayı yok ediyordu). IOHID erişimi runtime dlsym (`CGEventCopyIOHIDEvent`, field 0x0B0001/2), ilk gerçek event'te makuliyet kontrolü başarısızsa kalıcı devre dışı (güvenli düşüş).
9. **Pipeline sırası:** invert → speed → Shift-swap (EN SON) + swap sonrası `maskShift` flag'i event'ten siliniyor (tarayıcıda yanlış zoom/geçmiş tetiklenmesi önlendi) + swap koşulu pt/fixedPt alanlarını da görüyor.
10. **Trackpad ayrımı:** `continuous==1` şartı KALDIRILDI; sadece faz taşıyan olaylar trackpad sayılıyor. Logitech tarzı sürekli-tekerlekli farelerin momentum olayları artık tutarlı işleniyor (karışık yön bug'ı). Sentetik marker `eventSourceUserData=0x534D4F4F5448` loop koruması.

### Arayüz
11. **Ayarlar yeniden tasarlandı (glassmorphism'siz):** Katmanlı solid kart sistemi — `windowBackgroundColor` üzerinde hairline çizgili `controlBackgroundColor` kartlar, tinted squircle sidebar rozetleri (renk: pane bazlı systemColor gradient'i), uppercase section caption'ları, değer chip'li full-width slider'lar, keycap stilli kısayol satırları. 780×560. Yeni anahtarlar: "Fare ile Seçim" (hoverSelectEnabled), "Masaüstü Kartını Göster", "Gizli Uygulamaları Atla".
12. **HUD restyle:** accent-color seçim halkası/dolgusu, minimize nokta rozeti, chip tarzı selected-label, stil bazlı shrink-wrap boyutlar, yumuşatılmış gölge/border. `hudWindow` material (Spotlight konvansiyonu) korundu — vibrancy abartısı yok.

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
10. **Build düzeltmesi:** `Documents` klasörünün iCloud senkronu SwiftPM `build.db` kilitlenmesine yol açıp `swift build`'i exit≠1 ile kesiyordu. `scripts/package_app.sh` artık `~/Library/Caches/WinMacBuild` scratch-path ile derliyor; `/Applications/WinMac.app` v1.3 binary'si ile yeniden paketlendi ve doğrulandı.

### v1.3.1 — Mouse & AltTab İşlevsel Düzeltmeleri (23 Ağustos 2026)
1. **Fare özellikleri hiç çalışmıyordu (yumuşak kaydırmalı fareler):** `ScrollInverter`, `scrollWheelEventIsContinuous == 1` olan TÜM olayları trackpad sanıp değiştirmeden geçiyordu; Logitech vb. modern fareler sürekli olay gönderdiği için ters çevirme/hız/Shift+yatay asla uygulanmıyordu. Yeni kural: yalnızca trackpad jesti taşıyan olaylar (`scrollPhase != 0 || momentumPhase != 0`) dokunulur; discrete tekerlek VE sürekli-fare olayları ayarlara tabidir.
2. **Doğrusal ivme yanlış sistem değeri yazıyordu:** `com.apple.mouse.scaling`'e `sensitivity*1.5` yerine, doğrusal modda `-1` (ivme tamamen kapalı) yazılıyor; kapalıyken anahtar silinip macOS native eğrisine dönülüyor.
3. **AltTab görünüm stilleri kozmetiktu:** `switcherStyle` seçimlerinden yalnızca `thumbnails` kontrol ediliyor, o da hiç doldurulmayan `window.thumbnail`'a bağlıydı → 4 stil de aynı simge şeridini basıyordu.
   - **Büyük Simgeler:** 88px simge kartları (Command+Tab benzeri)
   - **Pencere Önizlemeleri:** canlı ekran görüntülü 160×122 kartlar — `ThumbnailCache.thumbnail(forPid:axBounds:)` AX↔CG koordinat dönüşümüyle gerçek CGWindowID çözümlüyor
   - **Kompakt Izgara:** 58px yoğun mini kartlar + uygulama adı
   - **Ayrıntılı Liste:** 420px dikey liste, başlık + uygulama adı + küçültülmüş göstergesi

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
    │   ├── AppSettings.swift         # UserDefaults destekli @MainActor ayar modeli (5 modül)
    │   ├── PermissionsManager.swift  # Accessibility & Screen Recording izin kontrolü
    │   ├── EventTapManager.swift     # Global Unified CGEventTap — switcher input'unun TEK otoritesi
    │   └── SystemUtils.swift         # Ekran hesaplama, kilit, ekran alıntısı, tuş sentezleme
    ├── SwiftQuit/
    │   └── SwiftQuitEngine.swift     # Son pencere kapandığında uygulamayı sonlandıran motor
    ├── AltTab/
    │   ├── CGWindowResolver.swift    # Gerçek CGWindowID çözümleme + z-order snapshot (v1.4)
    │   ├── WindowModel.swift         # Pencere veri modeli
    │   ├── WindowEngine.swift        # Subrole filtreli tarama, MRU sıralama, ID bazlı odaklama
    │   ├── AltTabState.swift         # Seçim, deadzone hover, arama filtresi
    │   ├── AltTabHUDController.swift # popUpMenu seviyeli NSPanel + dışarı-tıkla-kapat
    │   └── Views/                    # AltTabHUDView (Simgeler + Liste), SearchBarView
    ├── MousePointer/
    │   ├── MousePointerEngine.swift  # IOHID imleç ivmesi/hızı override + restore; reconnect/wake/per-app
    │   └── MousePointerMonitor.swift # salt-okunur: cihaz adı, DPI, pil (IOPS), sorgulama hızı (listen-only tap)
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
        ├── SettingsWindowController.swift # Ayar penceresi (780×560)
        └── SettingsView.swift        # Kart tabanlı modern panel sistemi (solid, vibrancy'siz)
```
