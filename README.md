# Mobil Oyun Projesi

Bu klasor, `backend` projesinden tamamen bagimsiz yeni bir mobil oyun calisma alani olarak olusturuldu.

Secilen yapi:

- Motor: Godot 4.x
- Dil: GDScript
- Hedef: Android ve Google Play
- Tur: klasik ustten bakisli tank savasindan ilham alan ozgun 2D arcade aksiyon
- Calisma adi: `Aksoy Tank`

## Neden Bu Yapi?

- 2D mobil oyun icin hizli prototip verir.
- Godot MIT lisansli oldugu icin motor tarafinda lisans/royalty baskisi yoktur.
- Android export akisi ve AAB cikisi icin resmi dokumantasyon vardir.
- Kucuk ekip ve tek gelistirici senaryosu icin cok uygundur.

## Klasorler

- `assets/`: gorseller, sesler ve ikonlar
- `docs/`: marka, telif, yayin ve tasarim notlari
- `src/scenes/`: Godot sahneleri
- `src/scripts/`: GDScript dosyalari
- `prototype/`: hizli deneyler ve referanslar
- `build/`: alinmis ciktilar ve paketler

## Ilk Hedef

Orijinal gorunume sahip, tek oyunculu, ustten bakisli bir tank savunma oyunu yapmak.

Klasik tank arcade oyunlarindan yalnizca su yuksek seviye fikirler alinacak:

- ustten bakisli tank savasi
- engel kirma ve arena baskisi
- kisa ve hizli bolumler
- us/base koruma hissi

Kopyalanmayacaklar:

- oyun adi
- karakter ve tank tasarimlari
- haritalarin birebir dizilimi
- muzik ve sesler
- ikonlar, HUD ve menu duzeni
- markaya cagrisim yapan renk dili ve metinler

## Dosyalar

- `project.godot`: Godot proje dosyasi
- `docs/legal-ve-marka.md`: telif riskini dusuren kurallar
- `docs/play-store-yayin.md`: Play Store hazirlik checklist'i
- `docs/oyun-vizyonu.md`: urun vizyonu ve farklilastirma kararlari

## Su An Hazir Olanlar

- ana menu
- stage secimi
- 60 bolumluk, bolume gore degisen campaign akisi
- yerel save ile stage unlock sistemi
- oynanabilir prototip arena
- oyuncu tank hareketi ve atesi
- 1P solo oyun modu
- hizli eslesmeli veya oda kodlu, internet uzerinden online co-op ve 1V1 modlari
- 4 dusman arketipi: grunt, scout, brute, sniper
- dusmanlardan dusen pickup sistemi: repair, shield, overdrive, turbo, fortify
- stage bazli renk paleti ve atmosfer temalari
- kirilabilir/kirilamaz bloklar
- cekirdek savunma, dalga temizleme, komutan avi ve boss avi hedefleri
- kazanma/kaybetme ekrani
- mobil analog joystick ve ates kontrol katmani
- etkilesimli ilk oyun egitimi ve azaltmis hareket/gorsel efekt ayarlari
- sabit arena kamera yapisi ve cache'li dusman hedef secimi
- mermi hareketinde normalize maliyetini azaltan hafif optimizasyonlar
- guvenli `WSS` relay uzerinden host-authoritative co-op ve 1V1 eslesmesi

## Kontroller

- `1P`: `W A S D` ile sur, `F` veya `Space` ile ates et
- Online ikinci oyuncu: uzak cihazdan kendi mobil kontrollerini kullanir

## Online Relay

- Relay sunucusu: `online-relay/server.py`
- Bagimliliklar: `online-relay/requirements.txt`
- Yerelde baslatmak icin:

```powershell
python -m pip install -r .\online-relay\requirements.txt
python .\online-relay\server.py
```

- Magaza baglanti adresi: `wss://atify.com.tr/aksoy-tank/ws`
- Relay Docker'da ozel agda calisir; 8765 portu internete acilmaz ve TLS Caddy tarafindan sonlandirilir.

## Build ve Yayin

- Android export presetleri hazir: `export_presets.cfg`
- Store iconlari ve feature graphic uretimi: `tools/generate_store_assets.ps1`
- Signed AAB export denemesi ve yayin dosya hazirligi: `tools/export_android.ps1`
- Store screenshot capture akisi: `tools/capture_store_screens.ps1`

Tek komutla paket almak icin:

```powershell
.\tools\export_android.ps1
```

Bu akisin urettigi veya hedefledigi ana ciktilar:

- `C:\Users\atala\Desktop\Masaustu\aksoy-tank-builds\aksoy-tank-release.aab`
- `assets/store/listing/google-play-icon-512.png`
- `assets/store/listing/google-play-feature-graphic-1024x500.png`
- `assets/store/listing/screenshots/*.png`

## Yayin Notlari

- Oyun adi ve marka dili `Aksoy Tank` uzerinden guncellendi.
- Paket adi artik `com.atalay.aksoytank` olarak ayarli.
- Privacy policy ve store listing taslaklari `docs/` altinda hazir.
