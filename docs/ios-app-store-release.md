# Aksoy Tank iOS / App Store Yayin Kilavuzu

> Mac'i olmayan gelistirici icin guncel ve onerilen yol GitHub Actions'tir.
> Kurulum ve calistirma adimlari `docs/app-store-ios.md` dosyasindadir.

Bu kopya Godot 4.6.2, iPhone, yatay ekran ve App Store dagitimi icin hazirlandi.
Bundle ID `com.atalay.aksoytanks`, ilk App Store pazarlama surumu `1.0` ve
minimum sistem iOS 15.0 olarak ayarlidir. Build numarasi GitHub Actions
tarafindan her calistirmada otomatik artirilir.

## Neden son paket Mac'te alinmali?

Godot'un resmi iOS export akisi macOS ve Xcode ister. 28 Nisan 2026'dan beri
App Store Connect'e yuklenen iOS oyunlari iOS 26 SDK veya daha yenisiyle
derlenmelidir. Bu nedenle guncel Xcode 26.x ve onu destekleyen bir Mac gerekir.

Resmi kaynaklar:

- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_ios.html
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/xcode/system-requirements/

## 1. Apple hesabindan Team ID'yi al

Apple Developer hesabinda Membership details bolumundeki 10 karakterli Team
ID'yi kopyala. Kisi veya sirket adini degil, `ABCDE12XYZ` bicimindeki kodu
kullan.

Windows PowerShell'de bu klasorde:

```powershell
.\tools\configure_ios.ps1 -TeamId ABCDE12XYZ
.\tools\validate_ios_release.ps1
```

App Store Connect'te farkli bir Bundle ID kaydettiysen ayni komuta
`-BundleId yeni.bundle.id` ekle. Ancak yeni uygulama kaydi icin hazir ve onerilen
kimlik `com.atalay.aksoytanks`tir.

Her yeni yukleme denemesinde build numarasini artir:

```powershell
.\tools\configure_ios.ps1 -TeamId ABCDE12XYZ -ShortVersion 1.5.0 -BuildNumber 15
```

## 2. App Store Connect uygulama kaydini olustur

App Store Connect > Apps > `+` > New App:

- Platforms: iOS
- Name: Aksoy Tank
- Primary Language: Turkish
- Bundle ID: `com.atalay.aksoytanks`
- SKU: `aksoy-tank-ios-2026`
- User Access: Full Access

Bundle ID listede yoksa Apple Developer > Certificates, Identifiers & Profiles
> Identifiers altinda once explicit App ID olarak olustur. Push Notifications,
Game Center ve In-App Purchase yeteneklerini bu surum icin acma.

## 3. Gizlilik sayfasini yayinla

`docs/aksoy-tank-gizlilik.html` dosyasini kendi alan adinda herkese acik bir
HTTPS adrese koy. Giris, parola, PDF veya indirme zorunlulugu olmamali. Bu URL'yi
App Privacy > Privacy Policy URL alanina gir.

Bu yapida reklam, analiz, hesap, takip ve cevrim ici mod yoktur. Bu nedenle App
Privacy formunda `Data Not Collected` secilir. Uygulama davranisi degisirse beyan
da degistirilmelidir.

## 4. Klasoru Mac'e tasi ve Godot exportunu yap

Mac'te sunlar kurulu olmali:

- macOS Sequoia 15.6 veya Apple'in guncel Xcode 26 gereksinimini karsilayan daha yenisi
- Xcode 26.x; ilk acilista lisans ve ek bilesen kurulumu tamamlanmis
- Godot 4.6.2 ve 4.6.2 export templates

Terminal:

```bash
cd /Aksoy-Tank-iOS/klasorunun/yolu
chmod +x tools/export_ios_on_mac.sh
./tools/export_ios_on_mac.sh
```

Godot komutu PATH icinde degilse:

```bash
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/export_ios_on_mac.sh
```

Komut iOS 26 SDK'yi kontrol eder, kaynaklari import eder ve
`build/ios-xcode` altinda Xcode projesi olusturur.

## 5. Xcode'da imzala ve Archive al

1. Uretilen `AksoyTank.xcodeproj` dosyasini Xcode ile ac.
2. Target > Signing & Capabilities bolumunde `Automatically manage signing`
   acik olsun ve satin aldigin Apple Developer takimini sec.
3. Bundle Identifier degerinin `com.atalay.aksoytanks` oldugunu kontrol et.
4. Destination olarak `Any iOS Device (arm64)` sec.
5. Product > Archive komutunu calistir.
6. Organizer'da Validate App ile kontrol et.
7. Distribute App > App Store Connect > Upload yolunu izle.

Xcode hesabinda sertifika yoksa otomatik imzalama Apple Development ve Apple
Distribution sertifikalarini olusturur. Elle sertifika/provision profile ismi
yazma; preset bunlari bos birakarak Xcode otomatik imzalamaya izin verir.

## 6. App Store bilgilerini tamamla

Hazir metinler `docs/app-store-listing-ios-tr.md` dosyasindadir. Ayrica:

- iPhone 6.9-inc ekran goruntulerini `assets/store/listing/ios-screenshots` klasorunden yukle.
- App Privacy: Data Not Collected
- Age Rating: Cartoon/Fantasy Violence = Frequent, Guns/Weapons = Frequent;
  diger ilgili alanlar None/No. Yeni sistemde beklenen sonuc 13+.
- Export Compliance: Uygulama yalnizca Apple/Godot'un standart sifrelemesini
  kullandigi ve `ITSAppUsesNonExemptEncryption=false` ayarlandigi icin ek belge
  gerektirmeyen secenek kullanilir.
- Content Rights: Oyundaki tum gorsel, ses, ad ve bolumlerin sana ait oldugunu
  dogrula.
- App Review Notes: `No login is required. Solo mode works offline and all 60
  stages can be tested sequentially. To test Online 1V1, open the app on two
  devices, select ONLINE 1V1, enter the same room code, and tap JOIN 1V1 ROOM.
  The first device hosts the room and the second device joins it.`
- Review Contact: gercek ad, telefon ve aktif e-posta gir.

Build islendikten sonra 1.5.0 surumune build 15'i bagla, fiyat/ulke secimlerini
tamamla ve `Add for Review` > `Submit for Review` kullan.

## Son kontrol

- `tools/validate_ios_release.ps1` hatasiz bitiyor.
- Team ID gercek hesaba ait.
- Bundle ID Apple portal, Godot preset ve App Store Connect'te birebir ayni.
- Ikon 1024x1024 ve alpha kanalsiz.
- En az bir ekran goruntusu Apple'in kabul ettigi tam boyutta ve alpha kanalsiz.
- Gizlilik ve destek URL'leri herkese acik HTTPS uzerinden calisiyor.
- Xcode Validate App hata vermiyor.
- TestFlight'ta gercek bir iPhone'da menu, dokunmatik surus, ates, duraklatma,
  kaydetme/silme ve 10 dakikalik oyun testi tamamlandi.
