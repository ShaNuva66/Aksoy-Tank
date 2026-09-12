# Aksoy Tank VS / Co-op relay

The relay is an ephemeral, host-authoritative WebSocket forwarder. It keeps no
accounts, chat, match history, or gameplay database. A room is removed when its
last connection closes.

Local check:

```powershell
python -m pip install -r requirements.txt
python server.py
```

The Android client uses `wss://atify.com.tr/aksoy-tank/ws`. Production runs
behind Caddy on the private `atify_atify-net` Docker network; port 8765 is not
published to the internet.

Version 2.0.6 adds managed rooms with optional passwords and an HTTP directory
at `/aksoy-tank/rooms?mode=online_vs&build=2.0.6`. Password hashes and reconnect
tokens are held only in memory, never returned by the directory. For protocol,
deployment and validation details, see `../docs/rooms-2.0.6.md`.

The configured trusted proxy subnet must match the private Docker network.
Do not publish port 8765 or trust arbitrary internet-supplied forwarded headers.

Tests from the project root:

```powershell
python -m unittest discover -s online-relay -p test_relay.py -q
python online-relay/test_game_clients.py --godot PATH_TO_GODOT --browser --impaired
```
