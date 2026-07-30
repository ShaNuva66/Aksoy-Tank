# Play Store Yayin Checklist'i

Bu proje Android ve Google Play hedeflenerek kuruluyor.

## Teknik Gereksinimler

- Yeni uygulamalar Google Play'e yuklenirken AAB cikisi kullanilmali
- 31 Agustos 2026 sonrasi guncellemeler Android 16 / API 36 hedeflemeli
- Eski cihaz kapsami icin Godot 4.6'nin guvenli siniri olan minimum Android 7.0 / API 24 tutuldu
- 32-bit ve 64-bit ARM cihazlar icin `armeabi-v7a` + `arm64-v8a` birlikte paketlenmeli
- Keystore dosyasi guvenli sekilde saklanmali
- Paket adi sabitlenmeli

## Hesap Gereksinimleri

- Yeni kisisel gelistirici hesaplarinda production'a cikmadan once kapali test gereksinimi var
- En az 12 tester 14 gun boyunca closed test icinde kalmali
- Sonrasinda production access basvurusu yapilmali

## Store Listing Gereksinimleri

- Oyun adi baska bir markaya benzemez olmali
- Ikon, kapak ve screenshot'lar tamamen ozgun olmali
- Gerekirse privacy policy hazirlanmali
- Data Safety formu dogru doldurulmali

## Bu Proje Icin Yorum

Teknik olarak Godot secimi bu akisla uyumlu.
En kritik risk motor degil, telif ve store listing benzerligi olacak.
