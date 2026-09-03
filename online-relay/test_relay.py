import asyncio
import json
import unittest
import urllib.request

from websockets.asyncio.client import connect
from websockets.asyncio.server import serve

import server


async def receive_type(socket, expected_type, attempts=8):
    for _ in range(attempts):
        message = json.loads(await asyncio.wait_for(socket.recv(), 2))
        if message.get("type") == expected_type:
            return message
    raise AssertionError(f"Did not receive message type {expected_type}")


async def join(socket, room_code, build="1.5.0", mode="online_vs", name="Oyuncu", style_id="akinci"):
    await socket.send(
        json.dumps(
            {
                "type": "join",
                "room_code": room_code,
                "mode": mode,
                "build": build,
                "profile": {"name": name, "style_id": style_id},
            }
        )
    )
    return await receive_type(socket, "room_joined" if mode == "online_vs" else "error")


class RelayIntegrationTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        server.ROOMS.clear()
        server.ROOM_ROUNDS.clear()
        self.relay = await serve(
            server.handler,
            "127.0.0.1",
            0,
            max_size=server.MAX_MESSAGE_BYTES,
            compression=None,
            process_request=server.process_http_request,
        )
        port = self.relay.sockets[0].getsockname()[1]
        self.url = f"ws://127.0.0.1:{port}/ws"
        self.http_base = f"http://127.0.0.1:{port}"
        self.connections = []

    async def asyncTearDown(self):
        for socket in self.connections:
            await socket.close()
        self.relay.close()
        await self.relay.wait_closed()
        server.ROOMS.clear()
        server.ROOM_ROUNDS.clear()

    async def open(self):
        socket = await connect(self.url, compression=None)
        self.connections.append(socket)
        return socket

    async def test_two_players_relay_input_and_disconnect(self):
        host = await self.open()
        guest = await self.open()
        self.assertEqual((await join(host, "DUEL01"))["role"], "host")
        self.assertEqual((await join(guest, "DUEL01"))["role"], "guest")
        connected = await receive_type(host, "peer_status")
        while not connected.get("connected"):
            connected = await receive_type(host, "peer_status")
        await guest.send(
            json.dumps(
                {
                    "type": "input",
                    "payload": {
                        "turn": 1.0,
                        "drive": 0.0,
                        "aim_rotation": 1.25,
                        "fire": True,
                    },
                }
            )
        )
        relayed = await receive_type(host, "input")
        self.assertEqual(relayed["from_slot"], 2)
        self.assertEqual(relayed["payload"]["aim_rotation"], 1.25)
        await guest.close()
        disconnected = await receive_type(host, "peer_status")
        self.assertFalse(disconnected["connected"])

    async def test_profiles_are_sanitized_and_shared(self):
        host = await self.open()
        guest = await self.open()
        host_joined = await join(host, "NAME01", name="Ali Atalay", style_id="neon")
        self.assertEqual(host_joined["profiles"][0]["name"], "Ali Atalay")
        await join(guest, "NAME01", name="  Bora   Tankçı!!! ", style_id="gece")
        connected = await receive_type(host, "peer_status")
        while not connected.get("connected"):
            connected = await receive_type(host, "peer_status")
        profiles = {profile["slot"]: profile for profile in connected["profiles"]}
        self.assertEqual(profiles[1]["style_id"], "neon")
        self.assertEqual(profiles[2]["name"], "Bora Tankçı")

    async def test_ping_is_answered_without_relaying_to_peer(self):
        host = await self.open()
        guest = await self.open()
        await join(host, "PING01")
        await join(guest, "PING01")
        await receive_type(host, "peer_status")
        await receive_type(guest, "peer_status")
        await host.send(json.dumps({"type": "ping", "sent_at": 123456}))
        pong = await receive_type(host, "pong")
        self.assertEqual(pong["sent_at"], 123456)
        with self.assertRaises(asyncio.TimeoutError):
            await asyncio.wait_for(guest.recv(), 0.1)

    async def test_rematch_requires_both_players(self):
        host = await self.open()
        guest = await self.open()
        await join(host, "READY1")
        await join(guest, "READY1")
        await receive_type(host, "peer_status")
        await receive_type(guest, "peer_status")

        await host.send(json.dumps({"type": "rematch_vote", "payload": {"ready": True}}))
        host_waiting = await receive_type(host, "rematch_status")
        guest_waiting = await receive_type(guest, "rematch_status")
        self.assertEqual(host_waiting["ready_slots"], [1])
        self.assertFalse(host_waiting["start"])
        self.assertFalse(guest_waiting["start"])

        await guest.send(json.dumps({"type": "rematch_vote", "payload": {"ready": True}}))
        host_start = await receive_type(host, "rematch_status")
        guest_start = await receive_type(guest, "rematch_status")
        self.assertEqual(host_start["ready_slots"], [1, 2])
        self.assertTrue(host_start["start"])
        self.assertTrue(guest_start["start"])
        self.assertEqual(host_start["round_id"], 1)

    async def test_rejects_third_player_and_build_mismatch(self):
        host = await self.open()
        guest = await self.open()
        third = await self.open()
        mismatch = await self.open()
        await join(host, "FULL01")
        await join(guest, "FULL01")
        await third.send(
            json.dumps(
                {"type": "join", "room_code": "FULL01", "mode": "online_vs", "build": "1.5.0"}
            )
        )
        self.assertIn("dolu", (await receive_type(third, "error"))["message"])
        await mismatch.send(
            json.dumps(
                {"type": "join", "room_code": "BUILD1", "mode": "online_vs", "build": "1.5.1"}
            )
        )
        self.assertEqual((await receive_type(mismatch, "room_joined"))["role"], "host")
        mismatch_guest = await self.open()
        await mismatch_guest.send(
            json.dumps(
                {"type": "join", "room_code": "BUILD1", "mode": "online_vs", "build": "1.5.0"}
            )
        )
        self.assertIn("uyusmuyor", (await receive_type(mismatch_guest, "error"))["message"])

    async def test_rejects_wrong_role_and_invalid_mode(self):
        host = await self.open()
        await join(host, "RULE01")
        await host.send(
            json.dumps(
                {"type": "input", "payload": {"turn": 0.0, "drive": 0.0, "fire": False}}
            )
        )
        self.assertIn("Gecersiz", (await receive_type(host, "error"))["message"])
        coop = await self.open()
        rejection = await join(coop, "COOP01", mode="online_coop")
        self.assertIn("1V1", rejection["message"])

    async def test_host_departure_closes_room(self):
        host = await self.open()
        guest = await self.open()
        await join(host, "LEAVE1")
        await join(guest, "LEAVE1")
        await host.close()
        error = await receive_type(guest, "error")
        self.assertIn("Oda sahibi", error["message"])
        await asyncio.wait_for(guest.wait_closed(), 2)
        self.assertNotIn("LEAVE1", server.ROOMS)

    async def test_health_and_privacy_pages(self):
        def fetch(path):
            with urllib.request.urlopen(self.http_base + path, timeout=2) as response:
                return response.status, response.read()

        health_status, health_body = await asyncio.to_thread(fetch, "/aksoy-tank/health")
        privacy_status, privacy_body = await asyncio.to_thread(fetch, "/aksoy-tank/privacy")
        self.assertEqual(health_status, 200)
        self.assertEqual(json.loads(health_body)["status"], "ok")
        self.assertEqual(privacy_status, 200)
        self.assertIn(b"Gizlilik Politikasi", privacy_body)


if __name__ == "__main__":
    unittest.main(verbosity=2)
