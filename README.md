# Geri Sayım

Önemli bir tarihe geri sayım: macOS masaüstünde bir kart, iPhone'da uygulama ve ana ekran / kilit ekranı widget'ı. Başlık ve tarih iCloud üzerinden Mac ile iPhone arasında senkronlanır.

- **Mac:** Pencerelerin arkasında duran, sürüklenebilir kart. Ayarlar için karta sağ tıkla ya da menü çubuğundaki ⏳ simgesini kullan.
- **iPhone:** Uygulamadan başlığı ve tarihi değiştir. Widget eklemek için ana ekranda boş bir yere basılı tut, ardından Düzenle → Widget Ekle → Geri Sayım.

## Kurulum (senkronlu, Xcode ile)

Gerekenler: Xcode 16+, Apple Developer hesabı, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
DEVELOPMENT_TEAM=<TeamID> xcodegen generate
open GeriSayim.xcodeproj
```

Xcode'da `GeriSayimiOS` şemasını iPhone'una, `GeriSayimMac` şemasını Mac'ine çalıştır. İki cihazda da aynı iCloud hesabı açık olmalı.

## Hızlı kurulum (sadece Mac, senkronsuz)

```bash
zsh build.sh
```

Uygulamayı `~/Applications/GeriSayim.app` olarak derler ve başlatır. Sadece Xcode Command Line Tools gerekir.
