# Android Release Akisi

Bu proje artik hem telefona kurulabilir `APK`, hem de Google Play icin signed `AAB` uretebiliyor.

## Tek Komut

```powershell
.\tools\export_android.ps1
```

Yayin oncesi test + build + release notlari icin cift tik dosyasi:

```powershell
.\play-store-hazirla.cmd
```

Bu script sunlari yapar:

- store icon ve feature graphic dosyalarini uretir
- Android asset staging klasorlerini otomatik doldurur
- signed debug `APK` olusturur
- signed release `AAB` olusturur
- store screenshotlarini capture eder

## Cikti Dosyalari

- `C:\Users\atala\Desktop\Masaustu\aksoy-tank-builds\aksoy-tank-debug.apk`
- `C:\Users\atala\Desktop\Masaustu\aksoy-tank-builds\aksoy-tank-release.aab`
- `C:\Users\atala\Desktop\Masaustu\aksoy-tank-builds\guncelleme-notlari-1.4.0.txt`
- `assets/store/listing/screenshots/*.png`

## Ayrik Scriptler

Sadece telefona kurulabilir paket icin:

```powershell
.\tools\build_phone_apk.ps1
```

Sadece Play Store paketi icin:

```powershell
.\tools\build_release_bundle.ps1
```

Telefon USB ile bagliyken dogrudan yuklemek icin:

```powershell
.\tools\install_phone_apk.ps1
```

## Yerel Gizli Dosyalar

Su dosyalar `git` disinda tutulur:

- `local/android/aksoy-mucadelisi-release.keystore`
- `local/android/release-keystore.json`

## Uygulama Kimligi

- Oyun adi: `Aksoy Tank`
- Paket adi: `com.atalay.aksoytank`
- Surum adi: `1.4.0`
- Surum kodu: `14`
- Minimum Android: `7.0 / API 24`
- Hedef Android: `16 / API 36`
- ABI destegi: `armeabi-v7a` ve `arm64-v8a`

## Not

Google Play production yayini oncesi son bir kez package name, signing key ve store listing metinleri yeniden kontrol edilmelidir.
