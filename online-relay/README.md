# Aksoy Tank 1V1 relay

The relay is an ephemeral, host-authoritative WebSocket forwarder. It keeps no
accounts, chat, match history, or gameplay database. A room is removed when its
last connection closes.

Local check:

```powershell
python -m pip install -r requirements.txt
python server.py
```

The App Store client uses `wss://atify.com.tr/aksoy-tank/ws`. Production runs
behind Caddy on the private `atify_atify-net` Docker network; port 8765 is not
published to the internet.
