# WinMac

**Windows'tan gelenler için macOS.** WinMac; Windows'a alışkın ve macOS'un
pencere yönetimi, kısayolları ve pencere değiştiricisinden hoşlanmayan kullanıcılar
için birkaç sevilen açık kaynak aracın davranışını **tek bir hafif, yerel Swift
uygulamasında** toplar.

> Bağımlılık yok, arka planda menü çubuğu uygulaması, ~4.500 satır Swift.

---

## Ne yapar?

| Modül | İlham | Ne sağlar |
|---|---|---|
| **Pencere Yaslama** | [Rectangle](https://github.com/rxhanson/Rectangle) | `⌃⌥` + ok tuşlarıyla yarım/çeyrek/üçte bir yaslama, kenara sürükleyerek yaslama (Aero Snap), boyut döngüsü, çoklu ekran taşıma. |
| **Pencere Değiştirici** | [AltTab](https://github.com/lwouis/alt-tab-macos) | `⌥Tab` ile pencere pencere (uygulama uygulama değil) geçiş, MRU sıralama, yazarak arama, HUD içinde `W`/`Q`/`M`/`F` eylemleri. İki görünüm: Büyük Simgeler ve Ayrıntılı Liste. |
| **Otomatik Çıkış** | [SwiftQuit](https://github.com/onmyway133/SwiftQuit) | Son pencere kırmızı ✕ ile kapandığında uygulamayı tamamen sonlandırır. Oyunlar, IDE'ler ve terminaller otomatik korunur. |
| **Klavye Kısayolları** | *(özgün — kullanıcı isteği)* | `Ctrl+C/V/X/Z/S/F/W/T…` → `Cmd`, `Ctrl+Y` → redo, `Ctrl+←/→` kelime atlama, `Ctrl+Backspace` kelime silme. Terminal ve IDE'lerde otomatik devre dışı. Ayrıca `⌥L` kilit, `⌥E` Finder, `⌥D` masaüstü, `Ctrl+Shift+Esc` Etkinlik Monitörü. |
| **Pano Geçmişi** | *(özgün)* | `⌥V` ile aranabilir metin pano geçmişi (25/50/100 öğe). |

Fare/kaydırma denetimi bu uygulamada **yoktur** — bunun için
[LinearMouse](https://github.com/linearmouse/linearmouse) veya BetterMouse gibi
adanmış bir araç önerilir.

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

WinMac **MIT lisansı** altındadır — bkz [LICENSE](LICENSE).

İlham alınan projelerin tümü de MIT lisanslıdır. Bu depo onların kaynak kodunu
içermez; davranışları macOS API'leri üzerine sıfırdan yeniden uygulanmıştır:

- Rectangle — © Ryan Hanson — MIT
- AltTab — © Louis Pontoise — MIT
- SwiftQuit — © Khoa Pham — MIT

---

## Proje Belgeleri

- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) — mimari, sürüm geçmişi, teknik kararlar
- [AUDIT.md](AUDIT.md) — kod tabanı denetimi ve bakım notları
