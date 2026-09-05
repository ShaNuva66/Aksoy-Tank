import asyncio
import json
import logging
import math
import os
import re
import secrets
import time
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Deque, Dict, Optional

from websockets.asyncio.server import ServerConnection, serve
from websockets.datastructures import Headers
from websockets.exceptions import ConnectionClosed
from websockets.http11 import Request, Response


logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(message)s")

ROOM_CODE_RE = re.compile(r"[^A-Z0-9]")
BUILD_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?$")
MAX_ROOM_SIZE = 2
MAX_MESSAGE_BYTES = int(os.environ.get("AKSOY_TANK_MAX_MESSAGE_BYTES", "131072"))
MAX_ROOMS = int(os.environ.get("AKSOY_TANK_MAX_ROOMS", "1000"))
RATE_WINDOW_SECONDS = 2.0
MAX_MESSAGES_PER_WINDOW = 120
TANK_STYLES = {"akinci", "gece", "col", "neon", "orman"}
ALLOWED_PATHS = {
    path.strip()
    for path in os.environ.get(
        "AKSOY_TANK_ALLOWED_PATHS", "/ws,/aksoy-tank/ws"
    ).split(",")
    if path.strip()
}
PRIVACY_HTML = Path(__file__).with_name("privacy.html").read_bytes()


@dataclass
class Peer:
    connection: ServerConnection
    room_code: str
    role: str
    slot: int
    mode: str
    build: str
    profile: dict
    message_times: Deque[float] = field(default_factory=deque)
    rematch_ready: bool = False
    matchmaking: bool = False
    promoted_at: float = -1.0


ROOMS: Dict[str, Dict[ServerConnection, Peer]] = {}
ROOM_ROUNDS: Dict[str, int] = {}
ROOM_LOCK = asyncio.Lock()


def sanitize_room_code(value: str) -> str:
    return ROOM_CODE_RE.sub("", value.upper().strip())[:8]


def sanitize_profile(value: object) -> dict:
    raw = value if isinstance(value, dict) else {}
    name = " ".join(str(raw.get("name", "Oyuncu")).strip().split())
    name = "".join(character for character in name if character.isalnum() or character in " -_")[:18]
    if len(name) < 3:
        name = "Oyuncu"
    style_id = str(raw.get("style_id", "akinci"))
    if style_id not in TANK_STYLES:
        style_id = "akinci"
    return {"name": name, "style_id": style_id}


def room_profiles(room_code: str) -> list[dict]:
    return [
        {"slot": peer.slot, **peer.profile}
        for peer in sorted(ROOMS.get(room_code, {}).values(), key=lambda item: item.slot)
    ]


def valid_input(payload: object) -> bool:
    if not isinstance(payload, dict):
        return False
    allowed = {"turn", "drive", "move_x", "move_y", "aim_rotation", "fire"}
    if not set(payload).issubset(allowed):
        return False
    for key in ("turn", "drive", "move_x", "move_y"):
        value = payload.get(key, 0.0)
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return False
        if not math.isfinite(float(value)) or abs(float(value)) > 1.01:
            return False
    aim_rotation = payload.get("aim_rotation", 0.0)
    if isinstance(aim_rotation, bool) or not isinstance(aim_rotation, (int, float)):
        return False
    if not math.isfinite(float(aim_rotation)) or abs(float(aim_rotation)) > math.pi + 0.01:
        return False
    return isinstance(payload.get("fire", False), bool)


def within_rate_limit(peer: Peer) -> bool:
    now = time.monotonic()
    cutoff = now - RATE_WINDOW_SECONDS
    while peer.message_times and peer.message_times[0] < cutoff:
        peer.message_times.popleft()
    if len(peer.message_times) >= MAX_MESSAGES_PER_WINDOW:
        return False
    peer.message_times.append(now)
    return True


def http_response(status: int, reason: str, content_type: str, body: bytes) -> Response:
    return Response(
        status,
        reason,
        Headers(
            [
                ("Content-Type", content_type),
                ("Content-Length", str(len(body))),
                ("Cache-Control", "no-store"),
                ("X-Content-Type-Options", "nosniff"),
            ]
        ),
        body,
    )


def process_http_request(_connection: ServerConnection, request: Request) -> Optional[Response]:
    path = request.path.split("?", 1)[0]
    if path == "/aksoy-tank/health":
        return http_response(200, "OK", "application/json; charset=utf-8", b'{"status":"ok"}\n')
    if path == "/aksoy-tank/privacy":
        return http_response(200, "OK", "text/html; charset=utf-8", PRIVACY_HTML)
    if path.startswith("/aksoy-tank/") and path != "/aksoy-tank/ws":
        return http_response(404, "Not Found", "text/plain; charset=utf-8", b"Not found\n")
    return None


async def send_json(connection: ServerConnection, payload: dict) -> None:
    await connection.send(json.dumps(payload, separators=(",", ":"), allow_nan=False))


async def send_error(connection: ServerConnection, message: str) -> None:
    await send_json(connection, {"type": "error", "message": message})


async def send_room_status(room_code: str) -> None:
    peers = list(ROOMS.get(room_code, {}).values())
    player_count = len(peers)
    connected = player_count == MAX_ROOM_SIZE
    for peer in peers:
        try:
            await send_json(
                peer.connection,
                {
                    "type": "peer_status",
                    "connected": connected,
                    "player_count": player_count,
                    "profiles": room_profiles(room_code),
                },
            )
        except ConnectionClosed:
            pass


async def remove_peer(connection: ServerConnection) -> None:
    changed_room = ""
    promoted_peer: Optional[Peer] = None
    async with ROOM_LOCK:
        for room_code, peers in list(ROOMS.items()):
            if connection not in peers:
                continue
            removed_peer = peers.pop(connection)
            for remaining_peer in peers.values():
                remaining_peer.rematch_ready = False
            changed_room = room_code
            if removed_peer.role == "host" and peers:
                promoted_peer = min(peers.values(), key=lambda item: item.slot)
                promoted_peer.role = "host"
                promoted_peer.promoted_at = time.monotonic()
                promoted_peer.rematch_ready = False
            elif not peers:
                ROOMS.pop(room_code, None)
                ROOM_ROUNDS.pop(room_code, None)
            break
    if promoted_peer is not None:
        try:
            await send_json(
                promoted_peer.connection,
                {
                    "type": "authority_changed",
                    "role": "host",
                    "slot": promoted_peer.slot,
                },
            )
        except ConnectionClosed:
            pass
    if changed_room and changed_room in ROOMS:
        await send_room_status(changed_room)


async def join_room(
    connection: ServerConnection, room_code: str, mode: str, build: str, profile: object
) -> Optional[Peer]:
    matchmaking = not room_code
    if not matchmaking and len(room_code) < 4:
        await send_error(connection, "Oda kodu en az 4 karakter olmali.")
        return None
    if mode not in {"online_coop", "online_vs"}:
        await send_error(connection, "Desteklenmeyen oyun modu.")
        return None
    if not BUILD_RE.fullmatch(build):
        await send_error(connection, "Oyun surumu gecersiz.")
        return None

    async with ROOM_LOCK:
        if matchmaking:
            room_code = next(
                (
                    code
                    for code, candidate in ROOMS.items()
                    if len(candidate) == 1
                    and next(iter(candidate.values())).matchmaking
                    and next(iter(candidate.values())).mode == mode
                    and next(iter(candidate.values())).build == build
                ),
                "",
            )
            while not room_code:
                candidate_code = "Q" + secrets.token_hex(3).upper()
                if candidate_code not in ROOMS:
                    room_code = candidate_code
        room = ROOMS.get(room_code)
        if room is None:
            if len(ROOMS) >= MAX_ROOMS:
                await send_error(connection, "Sunucu kapasitesi dolu. Biraz sonra tekrar dene.")
                return None
            room = {}
            ROOMS[room_code] = room
            ROOM_ROUNDS[room_code] = 0
        if len(room) >= MAX_ROOM_SIZE:
            await send_error(connection, "Oda dolu.")
            return None
        if room:
            host = next(iter(room.values()))
            if host.mode != mode:
                await send_error(connection, "Oda farkli bir oyun modunda.")
                return None
            if host.build != build:
                await send_error(connection, "Oyun surumleri uyusmuyor.")
                return None
            for existing_peer in room.values():
                existing_peer.rematch_ready = False

        role = "host" if not room else "guest"
        occupied_slots = {item.slot for item in room.values()}
        slot = next(slot_number for slot_number in (1, 2) if slot_number not in occupied_slots)
        peer = Peer(connection, room_code, role, slot, mode, build, sanitize_profile(profile), matchmaking=matchmaking)
        room[connection] = peer
        player_count = len(room)

    await send_json(
        connection,
        {
            "type": "room_joined",
            "room_code": room_code,
            "role": role,
            "slot": slot,
            "mode": mode,
            "player_count": player_count,
            "round_id": ROOM_ROUNDS.get(room_code, 0),
            "profiles": room_profiles(room_code),
        },
    )
    await send_room_status(room_code)
    return peer


async def handle_rematch_vote(peer: Peer, ready: bool) -> None:
    async with ROOM_LOCK:
        room = ROOMS.get(peer.room_code, {})
        if peer.connection not in room:
            return
        peer.rematch_ready = ready
        ready_slots = sorted(item.slot for item in room.values() if item.rematch_ready)
        start = len(room) == MAX_ROOM_SIZE and len(ready_slots) == MAX_ROOM_SIZE
        if start:
            ROOM_ROUNDS[peer.room_code] = ROOM_ROUNDS.get(peer.room_code, 0) + 1
        message = {
            "type": "rematch_status",
            "ready_slots": ready_slots,
            "start": start,
            "round_id": ROOM_ROUNDS.get(peer.room_code, 0),
        }
        for room_peer in list(room.values()):
            try:
                await send_json(room_peer.connection, message)
            except ConnectionClosed:
                pass
        if start:
            for room_peer in room.values():
                room_peer.rematch_ready = False


async def relay_to_room(sender: Peer, payload: dict) -> None:
    peers = list(ROOMS.get(sender.room_code, {}).values())
    message = {
        "type": payload["type"],
        "from_role": sender.role,
        "from_slot": sender.slot,
        "payload": payload["payload"],
    }
    for peer in peers:
        if peer.connection != sender.connection:
            try:
                await send_json(peer.connection, message)
            except ConnectionClosed:
                # A departing recipient must not disconnect the healthy sender.
                continue


async def handler(connection: ServerConnection) -> None:
    current_peer: Optional[Peer] = None
    request_path = connection.request.path.split("?", 1)[0]
    if request_path not in ALLOWED_PATHS:
        await connection.close(1008, "unsupported path")
        return

    try:
        async for raw_message in connection:
            if isinstance(raw_message, bytes) or len(raw_message.encode("utf-8")) > MAX_MESSAGE_BYTES:
                await send_error(connection, "Mesaj boyutu gecersiz.")
                await connection.close(1009, "message too large")
                return
            try:
                payload = json.loads(
                    raw_message,
                    parse_constant=lambda value: (_ for _ in ()).throw(
                        ValueError(f"invalid number: {value}")
                    ),
                )
            except (json.JSONDecodeError, ValueError):
                await send_error(connection, "Gecersiz JSON.")
                continue
            if not isinstance(payload, dict):
                await send_error(connection, "Mesaj nesne olmali.")
                continue

            message_type = str(payload.get("type", ""))
            if message_type in {"join", "matchmake"}:
                if current_peer is not None:
                    await send_error(connection, "Baglanti zaten bir odada.")
                    continue
                current_peer = await join_room(
                    connection,
                    "" if message_type == "matchmake" else sanitize_room_code(str(payload.get("room_code", ""))),
                    str(payload.get("mode", "")),
                    str(payload.get("build", "")),
                    payload.get("profile", {}),
                )
                continue

            if current_peer is None:
                await send_error(connection, "Once odaya katil.")
                continue
            if not within_rate_limit(current_peer):
                await send_error(connection, "Cok fazla mesaj gonderildi.")
                await connection.close(1008, "rate limit")
                return

            if message_type == "ping":
                sent_at = payload.get("sent_at")
                if isinstance(sent_at, bool) or not isinstance(sent_at, (int, float)):
                    await send_error(connection, "Gecersiz ping mesaji.")
                    continue
                await send_json(connection, {"type": "pong", "sent_at": sent_at})
                continue

            if message_type == "rematch_vote":
                vote_payload = payload.get("payload")
                if not isinstance(vote_payload, dict) or not isinstance(vote_payload.get("ready"), bool):
                    await send_error(connection, "Gecersiz rovans onayi.")
                    continue
                await handle_rematch_vote(current_peer, vote_payload["ready"])
                continue

            if message_type == "input":
                # Guest inputs already in transit may arrive just after promotion.
                if (current_peer.role == "host" and current_peer.promoted_at >= 0
                        and time.monotonic() - current_peer.promoted_at < 2.0
                        and valid_input(payload.get("payload"))):
                    continue
                if current_peer.role != "guest" or not valid_input(payload.get("payload")):
                    await send_error(connection, "Gecersiz oyuncu girdisi.")
                    continue
            elif message_type == "snapshot":
                if current_peer.role != "host" or not isinstance(payload.get("payload"), dict):
                    await send_error(connection, "Gecersiz oyun goruntusu.")
                    continue
            else:
                await send_error(connection, "Desteklenmeyen mesaj tipi.")
                continue

            await relay_to_room(current_peer, payload)
    except ConnectionClosed:
        pass
    finally:
        await remove_peer(connection)


async def main() -> None:
    host = os.environ.get("AKSOY_TANK_RELAY_HOST", "127.0.0.1")
    port = int(os.environ.get("AKSOY_TANK_RELAY_PORT", "8765"))
    async with serve(
        handler,
        host,
        port,
        max_size=MAX_MESSAGE_BYTES,
        max_queue=16,
        ping_interval=20,
        ping_timeout=20,
        close_timeout=5,
        compression=None,
        process_request=process_http_request,
    ):
        logging.info("Aksoy Tank relay listening on ws://%s:%s", host, port)
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
