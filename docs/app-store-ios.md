# Aksoy Tank - Mac olmadan App Store yukleme

Bu proje, GitHub Actions'in macOS makinesinde Godot iOS projesi olusturur,
Apple'in cloud signing sistemiyle imzalar ve App Store Connect'e yukler.
Apple anahtarlari repoya veya build dosyasina yazilmaz.

## Bir defalik Apple ayari

1. App Store Connect'te `Users and Access > Integrations > Team Keys` sayfasini ac.
2. `Generate API Key` ile `App Manager` yetkili bir anahtar olustur.
3. Su uc bilgiyi kaydet:
   - Issuer ID
   - Key ID
   - Yalnizca bir kez indirilebilen `AuthKey_....p8` dosyasi
4. Apple Developer hesabindaki Membership Details sayfasindan 10 karakterli Team ID'yi al.
5. App Store Connect'teki Aksoy Tank kaydinin Bundle ID degerinin
   `com.atalay.aksoytank` oldugunu dogrula.

## GitHub secrets

GitHub reposunda `Settings > Secrets and variables > Actions > New repository secret`
sayfasina gidip su dort secret'i ekle:

- `APPLE_TEAM_ID`: 10 karakterli Apple Team ID
- `APP_STORE_CONNECT_KEY_ID`: API Key ID
- `APP_STORE_CONNECT_ISSUER_ID`: Issuer ID
- `APP_STORE_CONNECT_PRIVATE_KEY`: `.p8` dosyasinin tamamini Not Defteri ile acip
  `BEGIN PRIVATE KEY` ve `END PRIVATE KEY` satirlari dahil yapistir

Anahtari sohbet mesajina, issue'ya veya kaynak koduna yapistirma.

## Build'i baslatma

1. GitHub reposunda `Actions` sekmesini ac.
2. Soldan `iOS - App Store'a Yukle` akisini sec.
3. `Run workflow` dugmesine bas.
4. Islem yesil olunca build App Store Connect'e yuklenmistir.
5. Apple'in islemesi tamamlaninca App Store Connect > Dagitim > iOS 1.0 > Insa etmek
   alanindan build'i sec.

Her calistirmada GitHub run numarasi kullanildigi icin Apple'a benzersiz bir build
numarasi gider. App Store surumu `1.0`, Bundle ID `com.atalay.aksoytank` olarak ayarlidir.
