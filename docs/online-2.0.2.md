# Online 2.0.2 / build 24

## Oynama

1. Bilgisayarda `aksoy-tank-online.cmd` online secim ekranini acar.
2. Iki oyuncu ayni surumu kullanmali: 2.0.2. Eski surumler ayni odaya alinmaz.
3. Sol ustten ONLINE CO-OP veya ONLINE VS secilir.
4. Arkadasla oynamak icin ayni oda kodu girilir. Ilk giren oyuncu host olur.
5. Co-op bolumunu host secer; misafir ayni bolume eslenir.
6. Rastgele eslesme icin iki oyuncu ayni modda HIZLI ESLES kullanir.
7. Sonuc ekraninda iki oyuncu da onaylayinca tekrar veya sonraki bolum baslar.
8. Sag ustteki mac menusunden ayrilmak mumkundur.

Hizli eslesmede baska oyuncu yoksa beklenir; bot rakip eklenmedi.
Tum oyuncular ayrilirsa oda sunucudan silinir. Kalici mac kaydi veya dereceli
rekabet icin sunucu otoriteli anti-cheat sistemi bu surumun kapsami degildir.

## Dogrulanan akislar

- Iki ayri Godot istemcisi, co-op ve versus: farkli yerel bolumlerin hosta
  eslenmesi; misafir yon/ates girdisinin hostta tank donusu ve ates uretmesi;
  sonuc aktarimi; iki tarafli sonraki bolum/rovans/tekrar; host kaybi ve yeniden
  katilma; yetki devrinde benzersiz nesne kimlikleri; sonuc ekranindayken
  misafir kopup yeniden geldiginde macin ve co-op zaferinin korunmasi.
- Eski raund paketleri reddedilir. Tam duvar durumu ara paketlerle kaybolmaz.
- Hareket/ates girdisi 500 ms yenilenmezse sifirlanir. Ayrilan oyuncunun
  girdileri ve devam oylari temizlenir.
- Baglanti beklerken tanklar, mermiler ve destek nesneleri durur; ag ve menu
  islemeye devam eder. Bitmis mac sonucu baglanti degisiminde korunur.
- 11 relay testi; uretim sunucusunda WSS eslesme/girdi/yetki devri kontrolu.
- 960x540 ve 1560x720 gorunumlerinde online menu, bekleme ve mac menusu:
  goruntu alindi, kontrol sinirlari denetlendi ve ekranlar incelendi.

## Sinirlar

Fiziksel telefon baglanamadi. Iki telefonda Wi-Fi/mobil veri gecisi, uzun
sureli performans, Android arka plan kisitlamalari ve Play uzerinden eski
surumun ustune guncelleme henuz dogrulanmadi. Otomatik testler bunlarin yerine
gecmez; ilk dagitim ic test grubuna yapilmalidir.

Tekrar: `play-store-hazirla.cmd` paketleme oncesi otomatik regresyonlari calistirir.
Gorsel kontrol: Godot ile `res://tools/online_ui_smoke_test.gd` calistirilir.

Android test APK'si debug imzalidir; mevcut Play kurulumunun ustune guncelleme
paketi olarak kullanilmaz. Kayitlari korumak icin eski oyunu silmeyin. Play
guncelleme testi imzali AAB'nin ic test kanalindan dagitilmasiyla yapilmalidir.

## Paket kaniti

- 2026-09-05: Son dokunma duzeltmesinden sonra APK ve AAB yeniden uretildi.
- AAB: 51,449,114 byte; imza ve ARMv7/ARM64 icerigi dogrulandi.
- Paket: `com.atalay.aksoytank`, surum 2.0.2 / 24, minimum API 24, hedef API 36.
- SHA-256: `57F965AA155DD096685633BA7943E9CF140AC5F4AF4708316B76D63299FC53A7`.
- Masaustu AAB kopyasinin hash'i ayni. Android 7 emulator acilisi gecti.
- Kaynak yedek dali: `codex/release-2.0.2-online` (origin).
