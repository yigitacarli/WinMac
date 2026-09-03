# WinMac — Denetim & Temizlik Planı

> Bu dosya, projenin bir defalık taranmasının (Claude / Sonnet 5, 3 Eylül 2026) sonucudur.
> Amaç: gelecekteki oturumların kod tabanını sıfırdan taramadan devam edebilmesi ve
> GitHub'a yükleme öncesi yapılacak temizliğin net bir listesi.
>
> **DURUM (3 Eylül 2026):** Bölüm 3-A, 3-B, 3-C ve v1.5 temizliği **tamamlandı**
> (bkz. PROJECT_CONTEXT.md → Sürüm 1.5). Kalanlar: Bölüm 3-D (opsiyonel kod notları)
> ve elle fonksiyonel test.

---

## 1. Proje Ne Durumda?

- **İsim:** WinMac — Windows'tan gelen ve macOS kullanımından hoşlanmayan kullanıcılar için
  4 açık kaynak aracın davranışını tek bir yerel Swift uygulamasında toplama denemesi.
- **Hedeflenen kaynaklar:** Rectangle (pencere yaslama), AltTab (pencere değiştirici),
  SwiftQuit (son pencere kapanınca uygulamayı sonlandırma), LinearMouse (fare/kaydırma).
- **Ekstra (kullanıcı isteği):** Windows klavye kısayolları köprüsü + pano geçmişi (Win+V).
- **Teknik:** SwiftPM executable, Swift 6, macOS 14+. Bağımlılık yok. ~5.500 satır.
- **Derleme:** `swift build` sorunsuz. Paketleme `scripts/package_app.sh` ile
  (`~/Library/Caches/WinMacBuild` scratch path — iCloud `build.db` kilidi bilinçli olarak atlanıyor).
- **Sürüm karmaşası:** `Info.plist` → `1.1`, `PROJECT_CONTEXT.md` → `v1.4`,
  kod içi fallback'ler → `1.2` / `1.3`. Tek bir kaynağa çekilmeli.

---

## 2. Modül Modül Tanı

| Modül | Dosyalar | Durum | Not |
|---|---|---|---|
| **Window Snap (Rectangle)** | `Sources/WindowSnap/*` | ✅ Çalışıyor | Carbon `RegisterEventHotKey` global kısayollar + drag-to-snap overlay. En sağlam modül. |
| **AltTab (Pencere Değiştirici)** | `Sources/AltTab/*` | ⚠️ Kısmen | Çekirdek çalışıyor; `switcherStyle` stilleri v1.3.1'de ayrıldı. Thumbnail yakalama Ekran Kaydı izni ister. 4 görünüm modu bakımı pahalı. |
| **SwiftQuit (Otomatik Çıkış)** | `Sources/SwiftQuit/SwiftQuitEngine.swift` | ✅ Çalışıyor | `didDeactivateApplicationNotification` + CGWindowList/AX çift doğrulama. Geniş yerleşik exclude listesi. Varsayılan **kapalı**. |
| **Klavye Kısayolları (Ctrl→Cmd)** | `Sources/KeyboardBridge/*` | ✅ Çalışıyor | Kullanıcının kendi istediği özellik. Terminal/IDE'lerde otomatik devre dışı. |
| **Pano Geçmişi (Win+V)** | `Sources/Clipboard/*` | ✅ Çalışıyor | 0.5 sn timer ile `NSPasteboard` polling. Yalnızca düz metin. |
| **LinearMouse (Fare/Kaydırma)** | `Sources/MouseScroll/*` | ❌ **Çalışmıyor** | Kullanıcı beyanı: hiçbir özellik çalışmadı, yerine **BetterMouse** kuruldu. **Kaldırılacak.** |

### LinearMouse modülü neden çıkarılıyor?
1. Kullanıcı hiçbir fonksiyonunun çalışmadığını ve BetterMouse'a geçtiğini belirtti.
2. `ScrollInverter.applyIOHIDSettings` özel/dokümentasyonsuz IOHID API'lerini `dlsym` ile
   çağırıyor ve **`defaults write -g com.apple.mouse.scaling -1`** komutunu kabuktan
   çalıştırıyor — kullanıcının sistem fare ayarını sessizce değiştiren, geri alması zor,
   riskli bir yan etki. Yayınlanacak bir projede istenmez.
3. `AppSettings.init()` her açılışta `updateHardwarePointerProperties(...)` çağırıyor →
   uygulama her başladığında donanım fare ayarına dokunuyor.

---

## 3. Temizlik Planı (GitHub öncesi)

### A. LinearMouse / Fare modülünü tamamen kaldır
- [ ] `Sources/MouseScroll/` klasörünü sil (`ScrollInverter.swift`, `ScrollWheelEventView.swift`)
- [ ] `AppSettings.swift`: `disableMouseAcceleration`, `mousePointerSensitivity`,
      `invertMouseWheel`, `invertHorizontalScroll`, `scrollSpeedMultiplier`,
      `shiftToHorizontalScroll`, `cmdToZoom` alanlarını ve init satırlarını sil;
      son satırdaki `ScrollInverter.shared.updateHardwarePointerProperties(...)` çağrısını sil.
- [ ] `EventTapManager.swift`: `scrollWheel` maskesini ve `ScrollInverter.shared.handleScrollEvent`
      dalını kaldır (kalan maske: flagsChanged, keyDown, leftMouse*).
- [ ] `WinMacApp.swift`: `toggleMouseScroll()` + "Fare Tekerleğini Ters Çevir" menü öğesini sil.
- [ ] `SettingsView.swift`: `MouseScrollPane`, sidebar'dan `.mouseAndScroll` case'i,
      `Design.tileColor` içindeki ilgili case, "Hakkında" metnindeki "LinearMouse" ismi.
- [ ] `PROJECT_CONTEXT.md` dosya haritası + sürüm notlarını güncelle.

### B. Repo hijyeni
- [ ] `build/` klasörünü git takibinden çıkar (`git rm -r --cached build`) ve `.gitignore`'a ekle
      — şu an `WinMac.app` binary'si + 2.6 MB `WinMac.dmg` repoda tutuluyor.
- [ ] `.DS_Store` dosyalarını sil (`.gitignore`'da var ama `build/.DS_Store` ve kök `.DS_Store` izlenmiş olabilir).
- [ ] `.github_sources/` (69 MB, 4 referans klonu) — gitignore'da, tamam. İstenirse tamamen silinebilir.
- [ ] `Yigit_Acarli_CV_...pdf` yalnızca `~/yigitosh` içinde, bu repoda değil — sorun yok.

### C. Eksik / tutarsız dosyalar
- [ ] **README.md yok.** `PROJECT_CONTEXT.md` dosya haritası README'den bahsediyor ama dosya mevcut değil.
      Kısa bir kullanıcı README'si yazılmalı (ne yapar, kurulum, izinler, kısayol tablosu, lisans/atıf).
- [ ] **LICENSE yok.** Kaynak projeler MIT (Rectangle, AltTab, LinearMouse) / MIT (SwiftQuit).
      MIT LICENSE eklenmeli + README'de "portlanan projeler ve lisansları" bölümü (atıf yükümlülüğü).
      LinearMouse çıkarılırsa onu atıftan da düşür.
- [ ] Sürüm numarasını tek yerde topla: `Info.plist` `CFBundleShortVersionString` → örn `1.4`,
      `CFBundleVersion` → `14`; koddaki `"1.2"`/`"1.3"` fallback'lerini `"1.4"` yap.
- [ ] `Resources/Info.plist`'e `NSAccessibilityUsageDescription` ve (AltTab thumbnails için)
      ekran kaydı gerekçe metni eklemek iyi olur.

### D. Küçük kod notları (opsiyonel, acil değil)
- `SnapEngine.handleShortcutAction` içindeki `.bottomHalf` cycle dalı iki kolda da aynı değeri
  atıyor (ölü kod) — sadeleştirilebilir.
- `EventTapManager` hem `SystemShortcuts` hem `CtrlToCmdMapper` içinde Win+L kilit mantığı
  var (çift işlem riski) — tek yerde toplanmalı.
- AltTab görünüm modları 4 taneden 2'ye indirilirse (Simgeler + Liste) bakım yükü düşer — kullanıcıya sor.
- `AppDelegate.applicationDidFinishLaunching` içinde `EventTapManager.start()` ve
  `SwiftQuitEngine.start()` iki kez çağrılıyor (bir kez doğrudan, bir kez permission sink'inde);
  `start()` guard'lı olduğu için zararsız ama gereksiz.

---

## 4. GitHub'a Yükleme Kontrol Listesi

1. [ ] Temizlik A–C tamamlandı, `swift build -c release` temiz.
2. [ ] `/Applications/WinMac.app` yeniden paketlendi ve elle test edildi (snap, alt-tab, ctrl→cmd, win+v, auto-quit).
3. [ ] README.md + LICENSE (MIT) eklendi.
4. [ ] `build/` ve türev dosyalar izlenmiyor.
5. [ ] Commit'ler anlamlı; `PROJECT_CONTEXT.md` güncel.
6. [ ] (Opsiyonel) Release'e imzasız `.dmg` eklenir — `scripts/create_dmg.sh` mevcut.
7. [ ] Repo görünürlüğü ve açıklaması ayarlandı (`github.com/yigitacarli/WinMac`).

---

## 5. Dosya Haritası (güncel, LinearMouse hariç hedef durum)

```
Sources/
├── main.swift, WinMacApp.swift          # NSApplication + status bar menü
├── Core/
│   ├── AppSettings.swift                # UserDefaults ayar modeli (6 modül → fare çıkınca 5)
│   ├── PermissionsManager.swift         # Accessibility izni
│   ├── EventTapManager.swift            # Tek birleşik CGEventTap (key + mouse drag)
│   └── SystemUtils.swift                # kilit, ekran görüntüsü, tuş sentezleme
├── WindowSnap/    (Rectangle)           # Carbon hotkey + drag-to-snap + overlay
├── AltTab/        (AltTab)              # CGWindowID çözümleme + HUD + 4 görünüm
├── SwiftQuit/     (SwiftQuit)           # son pencere kapanınca terminate
├── KeyboardBridge/                      # Ctrl→Cmd + Win+L/E/D + Ctrl+Shift+Esc
├── Clipboard/                           # Win+V pano geçmişi
└── Settings/                            # kart tabanlı ayar penceresi (780×560)
```
