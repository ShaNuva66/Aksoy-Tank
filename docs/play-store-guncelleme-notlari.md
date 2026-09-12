# Play Store Güncelleme Notları

## tr-TR

Aksoy Tank 2.0.6 (surum kodu 28):

- VS ve Co-op odalarini listeleme, yenileme, oda olusturma ve listeden katilim.
- Istege bagli sifreli odalar, sunucuda sifre dogrulamasi ve katilim denemesi siniri.
- Oyuncu sayisi, acik/sifreli ve bekleyen/baslamis mac durumlari.
- Baslamis maclarda sadece mevcut oyuncuya ait oturum anahtariyla yeniden baglanma.
- Oda listesi ve sifrelerin islenmesini aciklayan guncel gizlilik metni.

Aksoy Tank 2.0.5 (surum kodu 27):

- Ilk dokunusu merkez alan kayan analog, bagimsiz coklu dokunusla ates ve odak kaybinda temizlenen kontroller.
- Buyuk menu dugmeleri ve dogrudan Hikaye, Co-op, VS secimi.
- Online lobide oyuncular, ortak geri sayim ve mac menusunden Hikaye'ye donus.
- VS icin uc galibiyetlik seri, uc simetrik harita, skorun yeniden baglanmada korunmasi ve iki onayli rovans.
- Geri sayim sirasinda tank adinin ters gorunmesi duzeltildi.
- Hikayede duraklatma oyunu durdurur; online menu diger oyuncunun oyununu durdurmaz.

Onceki surum notlari:

Aksoy Tank 2.0.4:

- Online maçlar iki oyuncunun arenası hazır olana kadar bekler; ortak 3 saniyelik geri sayımla başlar.
- Tekrarlanan alan adlarını azaltan, önceki paketten bağımsız kompakt oyun durumu biçimi eklendi.
- Gecikme, dalgalanma ve bant sınırı altında gerçek iki istemcili co-op ve 1V1 testleri eklendi.
- Yeniden bağlanırken eski hazır olma onaylarının yeni başlangıcı tetiklemesi engellendi.

2.0.3 sürümünden korunanlar:

- Online paket işleme yükü ve isabet başına gereksiz dünya gönderimi azaltıldı.
- Mermilerin paketler arasında yavaşlamasına neden olan tahmin hatası düzeltildi.
- Gizli arayüz hesapları ve isim etiketi güncellemeleri azaltıldı.
- Hatalı paket kontrolleri ve gönderim hatalarında yeniden bağlanma iyileştirildi.

2.0.2 sürümünden korunanlar:

- Co-op sonraki bölüm ve tekrar deneme iki oyuncunun onayıyla birlikte başlar.
- Host bölümü misafire eşitlenir; eski raund paketleri yeni maça uygulanmaz.
- Oda kodu ve bağlantı durumu görünür; bağlantı beklerken saha donar.
- Eski ateş/hareket komutları, duvar eşitleme ve yeniden katılma sorunları giderildi.

Önceki sürümlerden korunan iyileştirmeler:

- Online maç menüsü, Android geri düğmesi ve arka plana geçiş davranışı düzeltildi.
- Host devri sırasında nesne kimlikleri, duvar sürümü ve bekleyen dalga durumu korunur.
- Kapanan bağlantıya gönderilen mesajın diğer oyuncuyu da düşürmesi giderildi.
- Tahkimat desteğinin fizik işlemi sırasında duvar oluşturma hatası giderildi.

- Hızlı eşleşme veya oda koduyla çevrim içi co-op ve 1v1 modları açıldı.
- Kısa bağlantı kesintilerinde otomatik yeniden bağlanma ve oda sahibi devri eklendi.
- Tankların birbirine yapışması, üst üste binmesi ve temas anında fırlaması engellendi.
- 60 bölümün harita düzenleri çeşitlendirildi; düşman çıkışları ve kalıcı geçiş yolları denetlendi.
- Dalga ilerlemesi ve kalkan süresi sade oyun arayüzünde görünür hale getirildi.
- Boss boyutu, canı, hitbox'ı ve hasarı boss türüne göre dengelendi.
- Duvar aralıklarından hatalı ateş, çekirdeğin karşısında tehlikeli doğma ve geçilemeyen düzenler düzeltildi.
- Hareket ve ateş gerektiren ilk oyun eğitimi eklendi.
- Özgün müzik ve ses efektleri ile ses, titreşim, görsel efekt yoğunluğu ve hareketi azalt ayarları eklendi.
- Android hedef API düzeyi 36'ya yükseltildi; Android 7.0 ve sonrası destekleniyor.

## en-US

Aksoy Tank 2.0.4:

- Online matches wait for both arenas to load, then use a shared three-second countdown.
- Added compact, self-contained world packets without previous-packet dependencies.
- Added real two-client co-op and versus checks with latency, jitter and bandwidth limits.
- Invalidated stale readiness acknowledgements after reconnecting.

Retained from 2.0.3:

- Reduced packet processing and redundant full-world updates during combat.
- Fixed predicted bullets slowing toward stale network targets.
- Reduced hidden HUD calculations and redundant nameplate updates.
- Improved malformed packet checks and send-failure reconnection.

Retained from 2.0.2:

- Synchronized co-op stage progression, retries and versus rematches.
- Host stage synchronization and rejection of stale round snapshots.
- Visible room and connection state; simulation waits for the other player.
- Fixed stale inputs, wall state retention and rejoining completed matches.

Improvements retained from previous releases:

- Added quick matchmaking and private room-code online co-op and 1v1 modes.
- Added automatic reconnect and host migration for brief connection losses.
- Prevented tanks from sticking, overlapping, or launching each other at close range.
- Diversified all 60 stage layouts and audited spawn and permanent navigation routes.
- Added compact wave progress and shield duration indicators.
- Balanced boss size, health, hitbox, and damage by boss type.
- Fixed firing through wall gaps, unsafe core-facing spawns, and blocked layouts.
- Added an interactive first-play movement and firing tutorial.
- Added original music and SFX plus audio, haptics, visual intensity, and reduced-motion settings.
- Updated Android target API to 36 while retaining Android 7.0+ support.

## Play Console Kısa Not

Hızlı eşleşmeli online co-op/1v1, yeniden bağlanma, etkileşimli eğitim, erişilebilirlik ayarları, çeşitli haritalar ve yakın temas tank düzeltmeleri eklendi.
