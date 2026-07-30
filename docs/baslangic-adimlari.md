# Baslangic Adimlari

Bu belge, oyunu ilk kez acacak biri icin en basit yol haritasidir.

## Bu bilgisayarda zaten hazir olanlar

- `Python 3.12`
- `Godot 4.6.2`
- proje klasoru: `C:\Users\atala\Desktop\mobil-oyun-projesi`

Yani sifirdan ekstra kurman gereken ana iki arac su anda bu bilgisayarda zaten var.

## Telefonda Hemen Acmak Icin

Telefonda oyunu acmanin en kolay yolu su:

```powershell
cd C:\Users\atala\Desktop\mobil-oyun-projesi
powershell -ExecutionPolicy Bypass -File .\tools\build_phone_apk.ps1
```

Bu komut sonunda su dosya olusur:

```text
C:\Users\atala\Desktop\aksoy-tank-builds\aksoy-tank-debug.apk
```

Telefon USB ile bagli ve `USB debugging` aciksa su komut tek seferde kurar:

```powershell
cd C:\Users\atala\Desktop\mobil-oyun-projesi
powershell -ExecutionPolicy Bypass -File .\tools\install_phone_apk.ps1
```

## En Kolay Baslangic

PowerShell ac ve su komutu calistir:

```powershell
cd C:\Users\atala\Desktop\mobil-oyun-projesi
powershell -ExecutionPolicy Bypass -File .\tools\start_online_test_env.ps1
```

Bu ne yapar:

- relay sunucusunu ayri bir PowerShell penceresinde acar
- gerekiyorsa `websockets` paketini kurar
- Godot editoru acar

## Godot Acildiginda

1. Ustteki oynat tusuna bas veya `F5` tusuna bas.
2. Menu acilinca `ONLINE 2P` modunu sec.
3. `ODA KODU` alanina bir kod yaz:
   - ornek: `ALFA1`
4. `SERVER URL` alanini ilk testte degistirme.
   - varsayilan: `ws://127.0.0.1:8765/ws`
5. `ONLINE ODAYA GIR` butonuna bas.

## Iki Pencere Ile Ayni Bilgisayarda Test

Online sistemi tek bilgisayarda denemek icin:

1. Ilk Godot penceresinde oyunu ac.
2. Ikinci bir Godot penceresi daha ac:

```powershell
cd C:\Users\atala\Desktop\mobil-oyun-projesi
powershell -ExecutionPolicy Bypass -File .\tools\open_godot_editor.ps1
```

3. Ikinci pencerede de oyunu `F5` ile calistir.
4. Iki pencerede de:
   - `ONLINE 2P`
   - ayni `ODA KODU`
   - ayni `SERVER URL`
5. Iki pencerede de `ONLINE ODAYA GIR` de.

Bunlardan biri `host`, digeri `guest` olur.

## Telefonda Test Etmek Icin

Iki telefon ayni Wi-Fi uzerindeyse:

1. Relay sunucusu bilgisayarda acik kalacak.
2. Bilgisayarin yerel IP adresini ogren:

```powershell
ipconfig
```

3. `IPv4 Address` satirindaki adresi bul.
   - ornek: `192.168.1.25`
4. Telefonlardaki oyunda `SERVER URL` alanina su formati yaz:

```text
ws://192.168.1.25:8765/ws
```

5. Iki telefonda da ayni oda kodunu kullan.

## Hangi Pencereyi Kapatmamalısın

- Relay penceresi acik kalmali
- Oyun pencereleri acik kalmali

Relay penceresini kapatirsan online baglanti biter.

## Sadece Relay Kurulumu Yapmak Istersen

```powershell
cd C:\Users\atala\Desktop\mobil-oyun-projesi
powershell -ExecutionPolicy Bypass -File .\tools\start_online_relay.ps1 -InstallRequirementsOnly
```

## Sorun Olursa

En sik 3 neden:

- relay penceresi kapali
- `SERVER URL` yanlis
- iki cihaz ayni oda kodunu kullanmiyor
