# Online Co-op

`Aksoy Tank` artik oda kodlu online 2 kisilik co-op altyapisina sahip.

## Mimari

- Relay turu: `WebSocket`
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

- Bu ilk surum, kararlilik ve Play Store'a gidebilecek temel online akisa odaklidir.
- Varsayilan `server_url` su anda yerel test icin `ws://127.0.0.1:8765/ws`.
- Gercek cihazdan internet uzerinden oynamak icin relay'i `wss://` ile yayinlamak gerekir.
- Host ayrilirsa oda bekleme durumuna geri doner.
