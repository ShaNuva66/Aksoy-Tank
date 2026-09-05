# Canli online sunucu dogrulamasi

Tarih: 2026-09-05. Oyun surumu: 2.0.2 / 24.

## Sunucu

- Oyun endpoint'i: `wss://atify.com.tr/aksoy-tank/ws`.
- HTTPS saglik kontrolu: `https://atify.com.tr/aksoy-tank/health`.
- Caddy `/aksoy-tank/*` yolunu `aksoy-tank-relay:8765` servisine yonlendiriyor.
- Container saglikli; yeniden baslatma politikasi `unless-stopped`.
- Salt okunur dosya sistemi ve 128 MiB bellek siniri mevcut.
- Bu kontrolde servis yeniden baslatilmadi, aktif oda verileri silinmedi.

## Internet uzerinden test

Iki ayri Godot sureci yerel relay kullanmadan canli WSS adresine baglandi.
Her mod icin rastgele, ayri bir ozel oda kullanildi. Her iki mod ve her iki
istemci PASS verdi:

- Co-op ve versus oda eslesmesi.
- Host bolumunun misafire eslenmesi.
- Misafir yon ve ates girdilerinin hostta uygulanmasi.
- Sonuc aktarimi, ortak sonraki bolum, tekrar deneme ve rovans.
- Host baglantisi kapatilinca misafire yetki devri ve eski hostun geri gelmesi.
- Sonuc ekraninda baglanti kesilip yeniden gelindiginde sonucun korunmasi.

Test araci artik hostu surec acilis sirasindan degil sunucunun verdigi rolden
belirliyor; internet baglanti sirasi farkli olabiliyor.

Tekrar calistirma (GODOT_EXE yerine kurulu Godot executable yolu):

```powershell
python online-relay/test_game_clients.py --godot GODOT_EXE --server wss://atify.com.tr/aksoy-tank/ws
```

`--server` verilmezse onceki yerel test akisi korunur.

## Kapsam

Bu kurulum Android/bilgisayar oyun uygulamalarini internetten birbirine baglar.
Tarayicida calisan bir Web export yayinlanmadi. Iki test istemcisi ayni
bilgisayardan internet uzerinden baglandi; iki fiziksel telefonda mobil veri,
Wi-Fi gecisi ve uzun sureli performans testi yerine gecmez.
Oyun kaynak kodu degismedi; mevcut 2.0.2 AAB yeniden uretilmesini gerektiren
bir calisma zamani degisikligi yapilmadi.
