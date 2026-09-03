# Play Console Data Safety - Online Co-op ve 1V1

Google Play, cihazdan disariya gonderilen ve yalnizca RAM'de gercek zamanli
istegi tamamlayacak kadar tutulan verilerin de forma dahil edilmesini ister.
Standarda uyan `ephemeral processing` verileri formda bildirilir ancak magaza
sayfasindaki Data Safety bolumunde kullaniciya toplanan veri olarak gosterilmez.

Aksoy Tank 2.0.0 icin onerilen beyan:

- Uygulama cihaz disina veri gonderiyor: Evet (yalnizca kullanici online co-op veya 1V1'i secerse)
- Veri turleri: App activity / Other actions ve oyuncunun girdigi ad icin Personal info / Name
- Amac: App functionality
- Zorunluluk: Optional; solo mod internet olmadan calisir
- Isleme: Processed ephemerally
- Paylasim: Hayir; relay ve barindirma saglayicisi gelistirici adina hizmet saglayicidir
- Aktarim guvenligi: Evet, `wss://` / TLS ile sifreli
- Hesap: Yok; hesap silme gereksinimi yok
- Reklam, analiz, takip ve kalici mac gecmisi: Yok

Relay oda kodunu, build surumunu, oyuncu adini, tank stilini, oyuncu girdisini ve
anlik mac durumunu sadece oda acikken RAM'de tutar/iletir. Oyuncu adi ve tank
stili ayni odadaki rakibe gosterilir. Bu veriler kalici bir oyun veritabanina
yazilmaz. IP adresi konum cikarmak, reklam, analiz veya kullanici profili icin
kullanilmaz.

Resmi aciklama:
https://support.google.com/googleplay/android-developer/answer/10787469
