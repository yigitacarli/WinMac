# 🪟 WinMac (AltTab+ & Windows-to-Mac Superpowers)

> **AltTab'ın Pro yaptığı tüm özellikler tamamen ÜCRETSİZ & Açık Kaynak** + Windows'tan Mac'e geçenlerin kronik sorunlarını çözen hepsi-bir-arada macOS aracı.

---

## 🌟 Neden WinMac?

AltTab son sürümlerinde arama, simge görünümleri ve kısayollar gibi temel özellikleri Pro abonelik arkasına aldı. Ayrıca Windows'tan macOS'e geçen bir kullanıcının ters fare tekerleği, `Ctrl+C/V` alışkanlığı, pencere yaslama gibi sorunları çözmek için 5-6 farklı uygulama (Rectangle, LinearMouse, Maccy, AltTab) kurması gerekiyordu.

**WinMac**, tüm bu işlevleri tek bir ultra hafif (~20 MB RAM), 120 FPS hızında yerel Swift 6 / SwiftUI uygulamasında toplar.

---

## ⚡ Özellikler

### 1. 🪟 AltTab Gelişmiş Pencere Değiştirici
- 🖼️ **3 Farklı Görünüm:** Küçük Resimler (Retina Thumbnails), Uygulama Simgeleri, Kompakt Başlıklar/Liste.
- 🔍 **Canlı Yazarak Arama:** `Alt+Tab` açıkken doğrudan klavyeden yazarak pencereleri anında filtreleme.
- ⚡ **Hızlı Aksiyonlar:** `W` (Kapat), `Q` (Uygulamadan Çık), `F` (Büyüt), `M` (Küçült).
- ⌨️ `Tab`, `Shift+Tab`, `Ok Tuşları`, `Enter` veya `Alt/Option` tuşu bırakıldığında pencereye odaklanma.

### 2. 🖱️ Bağımsız Fare Tekerleği Yönü (Reverse Scroll)
- Trackpad **Doğal (Natural)** kaydırmada kalır.
- Harici USB / Bluetooth farenin tekerleği **Windows standart yönünde** çalışır.

### 3. ⌨️ Windows Klavye Alışkanlıkları (Muscle Memory Bridge)
- `Ctrl+C`, `Ctrl+V`, `Ctrl+X`, `Ctrl+Z`, `Ctrl+A`, `Ctrl+S`, `Ctrl+F` tuşlarını sistem genelinde `Cmd` olarak işletir (Terminal ve VS Code hariç tutulabilir).
- **Finder:** `Enter` ile dosyayı açar, `F2` ile yeniden adlandırır, `Delete` ile çöpe atar.

### 4. 📋 Win + V: Pano Geçmişi (Clipboard History)
- `Win + V` (veya `Option + V` / `Cmd + Shift + V`) basıldığında açılan aranabilir pano geçmişi HUD paneli.

### 5. 🪟 Pencere Yaslama (Aero Snap)
- `⌥ + ⌃ + Sol Ok`: Sol Yarı Ekran
- `⌥ + ⌃ + Sağ Ok`: Sağ Yarı Ekran
- `⌥ + ⌃ + Yukarı Ok`: Tam Ekran (Maximize)
- `⌥ + ⌃ + Aşağı Ok`: Merkeze Al

### 6. ⚡ Sistem Kısayolları
- `Win + L`: Ekranı anında kilitle.
- `Ctrl + Shift + Esc`: Görev Yöneticisi / Etkinlik Monitörünü aç.
- `Win + Shift + S`: Ekran alıntısı/kırpma aracını başlat.

---

## 🛠️ Kurulum & Çalıştırma

### Hazır Paketi Çalıştırma:
```bash
open build/WinMac.app
```

### Kaynak Koddan Derleme:
```bash
./scripts/package_app.sh
```

---

## 🛡️ Gereken İzinler
Uygulamanın çalışabilmesi için macOS sistem izinleri:
1. **Erişilebilirlik (Accessibility):** Global kısayollar ve pencere odaklama için.
2. **Ekran Kaydı (Screen Recording):** AltTab pencere önizlemeleri (thumbnails) için.
