# 2.0.3 / 25 performans ve hata azaltma

## Degisiklikler

- Ayni ag okuma turundaki dunya paketleri birlestirilir; arena yalnizca en
  guncel durumu kopyalar. Yetki/oda/rovans mesajindan once bekleyen dunya
  bildirimi uygulanir. Duvar durumu ara paketler arasinda korunur.
- Bir karede en fazla 64 paket okunur. Paketler arasinda 3 ms butce kontrolu
  yapilir; tek bir buyuk paketin parse suresi bu butceyi asabilir.
- Normal isabetler 20 Hz dunya guncellemesini kullanir. Her isabette fazladan
  tam dunya gonderilmez; mac sonu isabeti aninda iletilmeye devam eder.
- Mermi tahmin hedefi mermiyle birlikte ilerler. Eski sabit hedefe dogru
  cekilip paket aralarinda yavaslama hatasi giderildi.
- Mermi boyutu degismiyorsa fizik sekli tekrar ayarlanmaz. Gizli destek
  etiketi her karede hesaplanmaz; ayni isim/renk etikete tekrar uygulanmaz.
- Bozuk dunya paketlerinin temel yapisi dogrulanir. Ag gonderim hatasi
  sessizce yutulmaz; yeniden baglanma akisina girilir.

## Olcum ve test kapsami

Ayni bilgisayarda 100 adet 10-paketlik yapay burst: toplam 1.000 paket,
120 duvar ve 30 dusmanlik veri. Degisiklik oncesi 1.000 arena bildirimi,
216.472 ms; ilk optimize kosuda 100 bildirim, 125.653 ms. Bu mikro olcum
FPS, paket kaybi veya internet pingi degildir. Sureler makine yukune gore
degisir; bildirim sayisindaki azalma testte kesin olarak denetlenir.

Canli `wss://atify.com.tr/aksoy-tank/ws` uzerinden iki ayri Godot istemcisi:
co-op ve versus, yon/ates, sonuc, ilerleme/tekrar, host devri ve yeniden
katilma PASS. Test sonu istemci gostergeleri: RTT 28.8, 30.7, 28.9, 30.3 ms;
jitter 2.2, 2.1, 2.6, 0.8 ms. Bu sayilar yalnizca bu baglantinin ornekleridir;
once/sonra ping iyilesmesi veya tum kullanicilar icin garanti ifade etmez.

Odakli regresyonlar: bozuk paket reddi; burst bildirimi birlestirme; rol
degisimi oncesinde dunya durumu sirasi; gecikmeli mermi hareketi; duvar
korunmasi; eski raund ve eski hareket girdisi reddi.

```powershell
godot --headless --path . --script res://tools/network_packet_benchmark.gd -- --batch
```

Gercek dusuk donanimli Android cihazda uzun sureli kare suresi, isi ve pil
olcumu yapilmadi. Mobil veri kaybi ve Wi-Fi gecisleri fiziksel cihazlarda
ayrica denenmeli. Tamamen hatasiz veya sifir gecikmeli oyun iddiasi yoktur.

## Paket

Surum 2.0.3 / 25, minimum API 24, hedef API 36. AAB boyutu 51,450,084 byte.
SHA-256: `2AFE72317758768320DFCBC2FB0138D6B2CC9B7023BCB4BA5135F8F67EA32368`.
Kaynak yedek dali: `codex/release-2.0.3-performance`.
Paketleme regresyonlari, 60 bolumluk kisa muharebe testi, 11 relay testi,
yerel iki istemci testi, Android 7 emulator acilisi ve AAB imza/mimari/manifest
kontrolleri gecti. Masaustu AAB kopyasinin hash'i dogrulandi.
Masaustundeki Test.apk debug imzalidir; Play kurulumunun ustune guncelleme
olarak kullanilmaz. Mevcut kayitlari korumak icin oyunu silmeyin.
