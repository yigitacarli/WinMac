# WinMac

**Windows'tan gelenler için macOS.** WinMac; Windows'a alışkın ve macOS'un
pencere yönetimi, kısayolları ve pencere değiştiricisinden hoşlanmayan kullanıcılar
için birkaç sevilen açık kaynak aracın davranışını **tek bir hafif, yerel Swift
uygulamasında** toplar.

> Bağımlılık yok, arka planda menü çubuğu uygulaması, ~5.000 satır Swift.

---

## Ne yapar?

| Modül | İlham | Ne sağlar |
|---|---|---|
| **Pencere Yaslama** | [Rectangle](https://github.com/rxhanson/Rectangle) | `⌃⌥` + ok tuşlarıyla yarım/çeyrek/üçte bir yaslama, kenara sürükleyerek yaslama (Windows tarzı mavi önizleme), boyut döngüsü, çoklu ekran taşıma. |
| **Pencere Değiştirici** | [AltTab](https://github.com/lwouis/alt-tab-macos) | `⌥Tab` ile pencere pencere (uygulama uygulama değil) geçiş, MRU sıralama, yazarak arama, HUD içinde `W`/`Q`/`M`/`F` eylemleri. İki görünüm: Büyük Simgeler ve Ayrıntılı Liste. |
| **Fare Denetimi** | [LinearMouse](https://github.com/linearmouse/linearmouse) | İmleç ivmesini hızdan ayırır (ivmeyi tamamen kapatabilirsiniz), IOHID üzerinden hassasiyet ayarı, bağlı farenin adı / donanım DPI / pil / sorgulama hızını (Hz) gösterir. Uygulama başına devre dışı bırakma listesi. Cihaz takılınca / uykudan dönünce otomatik yeniden uygular. |
| **Otomatik Çıkış** | [SwiftQuit](https://github.com/onmyway133/SwiftQuit) | Son pencere kırmızı ✕ ile kapandığında uygulamayı tamamen sonlandırır. Oyunlar, IDE'ler ve terminaller otomatik korunur. |
| **Klavye Kısayolları** | *(özgün — kullanıcı isteği)* | `Ctrl+C/V/X/Z/S/F/W/T…` → `Cmd`, `Ctrl+Y` → redo, `Ctrl+←/→` kelime atlama, `Ctrl+Backspace` kelime silme. Terminal ve IDE'lerde otomatik devre dışı. Ayrıca `⌥L` kilit, `⌥E` Finder, `⌥D` masaüstü, `Ctrl+Shift+Esc` Etkinlik Monitörü. |
| **Pano Geçmişi** | *(özgün)* | `⌥V` ile aranabilir metin pano geçmişi (25/50/100 öğe). |

Fare denetimi private IOKit API'lerine dayanır; macOS sürümüne göre davranışı
değişebilir. Sorun yaşarsanız modülü tek anahtarla kapatın — sistem varsayılanları
geri yüklenir. Kaydırma/jest denetimi WinMac'te **yoktur**.

---

## Kurulum

Ön derlenmiş bir sürüm için [Releases](https://github.com/yigitacarli/WinMac/releases)
sayfasına bakın veya kaynaktan derleyin:

```bash
git clone https://github.com/yigitacarli/WinMac.git
cd WinMac
./scripts/package_app.sh      # derler, ad-hoc imzalar, /Applications'a kurar
```

Gereksinimler: macOS 14+ ve Xcode komut satırı araçları (`swift` 6).

### İzinler

İlk açılışta **Sistem Ayarları → Gizlilik ve Güvenlik → Erişilebilirlik**
listesine WinMac'i ekleyin. Uygulama yalnızca bu izin verilene kadar ayar
penceresini açar; sonrasında menü çubuğunda yaşar.

---

## Derleme Notları

- `swift build` doğrudan çalışır.
- `scripts/package_app.sh`, iCloud senkronlu `Documents` klasöründeki SwiftPM
  `build.db` kilit hatasını önlemek için `~/Library/Caches/WinMacBuild` scratch
  yolunu kullanır.
- `scripts/create_dmg.sh` dağıtım için sıkıştırılmış `.dmg` üretir.

---

## Lisans & Atıf

WinMac **GPL-3.0** lisansı altındadır — bkz [LICENSE](LICENSE) ve [NOTICE](NOTICE).

Bu depo aşağıdaki projelerin kaynak kodunu **içermez**; modüller macOS API'leri
üzerine sıfırdan yazılmıştır ve yalnızca davranışları model alınmıştır. Pencere
değiştirici ve otomatik çıkış davranışları GPL-3.0 projelerden esinlendiği için
WinMac bütün olarak GPL-3.0 ile dağıtılır.

| Proje | Lisans | Model alınan davranış |
|---|---|---|
| [Rectangle](https://github.com/rxhanson/Rectangle) | MIT | Pencere yaslama |
| [LinearMouse](https://github.com/linearmouse/linearmouse) | MIT | IOHID imleç ivmesi/hızı |
| [AltTab](https://github.com/lwouis/alt-tab-macos) | GPL-3.0 | Pencere değiştirici |
| [SwiftQuit](https://github.com/onmyway133/SwiftQuit) | GPL-3.0 | Otomatik çıkış |

BetterMouse kapalı kaynak, ticari bir uygulamadır; WinMac hiçbir BetterMouse kodu içermez.

---

## Proje Belgeleri

- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) — mimari, sürüm geçmişi, teknik kararlar
- [AUDIT.md](AUDIT.md) — kod tabanı denetimi ve bakım notları
