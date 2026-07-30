import asyncio
import json
import logging
import os
import re
from dataclasses import dataclass
from typing import Dict, Optional

from websockets.asyncio.server import ServerConnection, serve
from websockets.exceptions import ConnectionClosed


logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(message)s")

ROOM_CODE_RE = re.compile(r"[^A-Z0-9]")
MAX_ROOM_SIZE = 2


@dataclass
class Peer:
	connection: ServerConnection
	room_code: str
	role: str
	slot: int
	mode: str


ROOMS: Dict[str, Dict[ServerConnection, Peer]] = {}
ROOM_LOCK = asyncio.Lock()


def sanitize_room_code(value: str) -> str:
	code = ROOM_CODE_RE.sub("", value.upper().strip())
	return (code or "ALFA1")[:8]


async def send_json(connection: ServerConnection, payload: dict) -> None:
	await connection.send(json.dumps(payload, separators=(",", ":")))


async def send_room_status(room_code: str) -> None:
	room = ROOMS.get(room_code, {})
	player_count = len(room)
	connected = player_count == MAX_ROOM_SIZE

	for peer in room.values():
		await send_json(
			peer.connection,
			{
				"type": "peer_status",
				"connected": connected,
				"player_count": player_count,
			},
		)


async def remove_peer(connection: ServerConnection) -> None:
	async with ROOM_LOCK:
		for room_code, peers in list(ROOMS.items()):
			if connection in peers:
				peers.pop(connection, None)
				if not peers:
					ROOMS.pop(room_code, None)
				else:
					await send_room_status(room_code)
				return


async def join_room(connection: ServerConnection, room_code: str, mode: str) -> Optional[Peer]:
	async with ROOM_LOCK:
		room = ROOMS.setdefault(room_code, {})
		if len(room) >= MAX_ROOM_SIZE:
			await send_json(connection, {"type": "error", "message": "Oda dolu."})
			return None
		if room and next(iter(room.values())).mode != mode:
			await send_json(connection, {"type": "error", "message": "Oda farkli bir oyun modunda."})
			return None

		role = "host" if not room else "guest"
		slot = 1 if role == "host" else 2
		peer = Peer(connection=connection, room_code=room_code, role=role, slot=slot, mode=mode)
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
		},
	)
	await send_room_status(room_code)
	return peer


async def relay_to_room(sender: Peer, payload: dict) -> None:
	room = ROOMS.get(sender.room_code, {})
	for peer in room.values():
		if peer.connection == sender.connection:
			continue

		message = {
			"type": payload.get("type", ""),
			"from_role": sender.role,
			"from_slot": sender.slot,
			"payload": payload.get("payload", {}),
		}
		await send_json(peer.connection, message)


async def handler(connection: ServerConnection) -> None:
	current_peer: Optional[Peer] = None

	try:
		async for raw_message in connection:
			try:
				payload = json.loads(raw_message)
			except json.JSONDecodeError:
				await send_json(connection, {"type": "error", "message": "Gecersiz JSON."})
				continue

			message_type = str(payload.get("type", ""))
			if message_type == "join":
				if current_peer is not None:
					await send_json(connection, {"type": "error", "message": "Baglanti zaten bir odada."})
					continue

				room_code = sanitize_room_code(str(payload.get("room_code", "")))
				mode = str(payload.get("mode", "online_coop"))
				if mode not in {"online_coop", "online_vs"}:
					mode = "online_coop"
				current_peer = await join_room(connection, room_code, mode)
				continue

			if current_peer is None:
				await send_json(connection, {"type": "error", "message": "Once odaya katil."})
				continue

			if message_type not in {"input", "snapshot"}:
				await send_json(connection, {"type": "error", "message": "Desteklenmeyen mesaj tipi."})
				continue

			await relay_to_room(current_peer, payload)
	except ConnectionClosed:
		pass
	finally:
		await remove_peer(connection)


async def main() -> None:
	host = os.environ.get("STEEL_BASTION_RELAY_HOST", "127.0.0.1")
	port = int(os.environ.get("STEEL_BASTION_RELAY_PORT", "8765"))

	async with serve(handler, host, port):
		logging.info("Aksoy Tank relay server listening on ws://%s:%s", host, port)
		await asyncio.Future()


if __name__ == "__main__":
	asyncio.run(main())
