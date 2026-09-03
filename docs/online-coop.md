# Online Co-op ve 1V1

`Aksoy Tank`, oda kodlu online co-op ve 1V1 destekler.

## Mimari

- Relay turu: TLS korumali `WebSocket` (`WSS`)
- Oda modeli: 2 oyuncu
- Yetki modeli: `host-authoritative`
- Veri akisi:
  - misafir oyuncu input gonderir
  - host tam simulasyonu calistirir
  - host duzenli snapshot yollar
  - relay sunucusu mesajlari oda icinde iletir

## Dosyalar

- `src/scripts/net_session.gd`: Godot istemci ag oturumu
- `online-relay/server.py`: Python relay sunucusu
- `src/scripts/prototype_arena.gd`: host/client ayrimi ve snapshot uygulama akisi
- `src/scripts/player_tank.gd`: local / network_input / replica kontrol kipleri

## Notlar

- Magaza sunucusu `wss://atify.com.tr/aksoy-tank/ws` adresindedir.
- Sunucu adresi magazaya giden uygulamada sabittir; oyuncu yalnizca oda kodunu girer.
- Hizli eslesme ayni mod ve uygulama surumundeki bekleyen oyunculari otomatik olarak ayni odaya alir.
- Kisa baglanti kesintilerinde istemci uc kez otomatik yeniden baglanmayi dener.
- Host ayrilirsa kalan oyuncu otomatik host olur ve oda yeni oyuncuyu beklemeye devam eder.
