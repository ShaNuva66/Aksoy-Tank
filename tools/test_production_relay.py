import asyncio
import json
import secrets
import urllib.request

from websockets.asyncio.client import connect


BASE_URL = "https://atify.com.tr/aksoy-tank"
WS_URL = "wss://atify.com.tr/aksoy-tank/ws"


async def receive_type(socket, expected_type, attempts=8):
    for _ in range(attempts):
        message = json.loads(await asyncio.wait_for(socket.recv(), 4))
        if message.get("type") == expected_type:
            return message
    raise RuntimeError(f"Missing {expected_type} message")


async def join(socket, room_code):
    await socket.send(
        json.dumps(
            {
                "type": "join",
                "room_code": room_code,
                "mode": "online_vs",
                "build": "1.8.0",
                "profile": {"name": "Probe", "style_id": "akinci"},
            }
        )
    )
    return await receive_type(socket, "room_joined")


async def main():
    with urllib.request.urlopen(BASE_URL + "/health", timeout=5) as response:
        health = json.loads(response.read())
    with urllib.request.urlopen(BASE_URL + "/privacy", timeout=5) as response:
        privacy = response.read()
    if health.get("status") != "ok" or b"Gizlilik Politikasi" not in privacy:
        raise RuntimeError("Production HTTP endpoints failed")

    room_code = "T" + "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(7))
    async with connect(WS_URL, compression=None) as host, connect(WS_URL, compression=None) as guest:
        host_joined = await join(host, room_code)
        guest_joined = await join(guest, room_code)
        if host_joined.get("role") != "host" or guest_joined.get("role") != "guest":
            raise RuntimeError("Production room roles are invalid")

        await guest.send(
            json.dumps(
                {
                    "type": "input",
                    "payload": {"turn": 0.5, "drive": 1.0, "fire": True},
                }
            )
        )
        relayed_input = await receive_type(host, "input")
        if relayed_input.get("from_slot") != 2:
            raise RuntimeError("Guest input wasn't relayed to host")

        await host.send(json.dumps({"type": "snapshot", "payload": {"test": True}}))
        snapshot = await receive_type(guest, "snapshot")
        if not snapshot.get("payload", {}).get("test"):
            raise RuntimeError("Host snapshot wasn't relayed to guest")

        await host.send(json.dumps({"type": "rematch_vote", "payload": {"ready": True}}))
        host_waiting = await receive_type(host, "rematch_status")
        guest_waiting = await receive_type(guest, "rematch_status")
        if host_waiting.get("start") or guest_waiting.get("start"):
            raise RuntimeError("One rematch vote started the match")

        await guest.send(json.dumps({"type": "rematch_vote", "payload": {"ready": True}}))
        host_start = await receive_type(host, "rematch_status")
        guest_start = await receive_type(guest, "rematch_status")
        if not host_start.get("start") or not guest_start.get("start"):
            raise RuntimeError("Two rematch votes didn't start both clients")

    print("PRODUCTION_RELAY: PASS health, privacy, WSS room, input, snapshot, two-player rematch")


if __name__ == "__main__":
    asyncio.run(main())
