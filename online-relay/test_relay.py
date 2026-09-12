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
    return await receive_type(socket, "room_joined" if mode in {"online_coop", "online_vs"} else "error")


async def matchmake(socket, build="1.5.0", mode="online_vs"):
    await socket.send(
        json.dumps(
            {
                "type": "matchmake",
                "mode": mode,
                "build": build,
                "profile": {"name": "Otomatik", "style_id": "akinci"},
            }
        )
    )
    return await receive_type(socket, "room_joined")


class RelayIntegrationTests(unittest.IsolatedAsyncioTestCase):
    def test_ready_input_validation(self):
        self.assertTrue(server.valid_input({"ready_token": 2147483647}))
        self.assertTrue(server.valid_input({"fire": False, "ready_token": 12}))
        for token in (True, -1, 2147483648, 1.5, "12", None):
            self.assertFalse(server.valid_input({"ready_token": token}))

    async def asyncSetUp(self):
        server.ROOMS.clear()
        server.ROOM_ROUNDS.clear()
        server.ROOM_OPTIONS.clear()
        server.JOIN_ATTEMPTS.clear()
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

    async def browser(self, socket, action="create_room", expected="room_joined", **extra):
        await socket.send(json.dumps({"type": action, "mode": "online_vs", "build": "2.0.6",
                                      "room_name": "Test Odasi", "profile": {"name": "Test"}, **extra}))
        return await receive_type(socket, expected)

    async def test_browser_password_listing_and_resume(self):
        host = await self.open()
        created = await self.browser(host, password="test-secret")
        code = created["room_code"]
        rooms = server.public_rooms("online_vs", "2.0.6")
        self.assertEqual(len(rooms), 1)
        self.assertTrue(rooms[0]["locked"])
        self.assertFalse(rooms[0]["started"])
        self.assertNotIn("test-secret", json.dumps(rooms))
        self.assertNotIn(created["resume_token"], json.dumps(rooms))
        self.assertEqual(server.public_rooms("online_coop", "2.0.6"), [])
        self.assertEqual(server.public_rooms("online_vs", "2.0.5"), [])
        intruder = await self.open()
        error = await self.browser(intruder, "join", "error", room_code=code)
        self.assertIn("sifresi yanlis", error["message"])
        guest = await self.open()
        joined = await self.browser(guest, "join_room", room_code=code, password="test-secret")
        self.assertTrue(server.public_rooms("online_vs", "2.0.6")[0]["started"])
        self.assertNotEqual(created["resume_token"], joined["resume_token"])
        await guest.close()
        await asyncio.sleep(0.05)
        error = await self.browser(intruder, "join_room", "error", room_code=code, password="test-secret")
        self.assertIn("Mac basladi", error["message"])
        resumed = await self.open()
        reply = await self.browser(resumed, "join_room", room_code=code, password="test-secret", resume_token=joined["resume_token"])
        self.assertEqual(reply["slot"], joined["slot"])
        self.assertEqual(reply["resume_token"], joined["resume_token"])
        await resumed.close()
        await host.close()
        await asyncio.sleep(0.05)
        self.assertNotIn(code, server.ROOM_OPTIONS)
        error = await self.browser(intruder, "join_room", "error", room_code=code)
        self.assertIn("mevcut degil", error["message"])

    async def test_browser_open_room_http_and_capacity(self):
        host = await self.open()
        created = await self.browser(host)
        url = self.http_base + "/aksoy-tank/rooms?mode=online_vs&build=2.0.6"
        body = await asyncio.to_thread(lambda: urllib.request.urlopen(url).read())
        listed = json.loads(body)["rooms"]
        self.assertEqual(listed[0]["code"], created["room_code"])
        self.assertFalse(listed[0]["locked"])
        guest = await self.open()
        await self.browser(guest, "join_room", room_code=created["room_code"])
        third = await self.open()
        await self.browser(third, "join_room", "error", room_code=created["room_code"])
        self.assertEqual(len(server.ROOMS[created["room_code"]]), 2)

    async def test_browser_validation_and_join_throttle(self):
        socket = await self.open()
        for extra in ({"password": "abc"}, {"password": "a" * 65}, {"password": {}},
                      {"room_name": "x"}, {"room_name": None}, {"mode": "bad"},
                      {"password": "\ud800"}, {"resume_token": "\ud800"}):
            await self.browser(socket, expected="error", **extra)
        self.assertEqual(server.ROOM_OPTIONS, {})
        now = server.time.monotonic()
        server.JOIN_ATTEMPTS["127.0.0.1"] = server.deque([now] * 60)
        error = await self.browser(socket, expected="error")
        self.assertIn("bir dakika", error["message"].lower())

    async def test_browser_missing_code_does_not_matchmake(self):
        host = await self.open()
        created = await matchmake(host, build="2.0.6")
        guest = await self.open()
        error = await self.browser(guest, "join_room", "error", room_code="")
        self.assertIn("Oda kodu", error["message"])
        self.assertEqual(len(server.ROOMS[created["room_code"]]), 1)

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


    async def test_matchmaking_pairs_only_same_mode_and_build(self):
        first = await self.open()
        wrong_mode = await self.open()
        second = await self.open()
        first_joined = await matchmake(first, build="2.0.0", mode="online_coop")
        wrong_joined = await matchmake(wrong_mode, build="2.0.0", mode="online_vs")
        second_joined = await matchmake(second, build="2.0.0", mode="online_coop")
        self.assertNotEqual(first_joined["room_code"], wrong_joined["room_code"])
        self.assertEqual(first_joined["room_code"], second_joined["room_code"])
        self.assertEqual(second_joined["role"], "guest")
        connected = await receive_type(first, "peer_status")
        while not connected.get("connected"):
            connected = await receive_type(first, "peer_status")
        self.assertTrue(connected["connected"])

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
        coop_host = await self.open()
        coop_guest = await self.open()
        self.assertEqual((await join(coop_host, "COOP01", mode="online_coop"))["mode"], "online_coop")
        self.assertEqual((await join(coop_guest, "COOP01", mode="online_coop"))["role"], "guest")
        invalid = await self.open()
        rejection = await join(invalid, "BADMODE", mode="local")
        self.assertIn("Desteklenmeyen", rejection["message"])

    async def test_promoted_host_tolerates_in_flight_guest_input(self):
        host = await self.open()
        guest = await self.open()
        await join(host, "LATE01")
        await join(guest, "LATE01")
        await host.close()
        await receive_type(guest, "authority_changed")
        await guest.send(json.dumps({"type": "input", "payload": {"fire": False}}))
        await guest.send(json.dumps({"type": "ping", "sent_at": 42}))
        while True:
            message = json.loads(await asyncio.wait_for(guest.recv(), timeout=2))
            self.assertNotEqual(message["type"], "error")
            if message["type"] == "pong":
                self.assertEqual(message["sent_at"], 42)
                break

    async def test_host_departure_promotes_guest_and_accepts_replacement(self):
        host = await self.open()
        guest = await self.open()
        await join(host, "LEAVE1")
        await join(guest, "LEAVE1")
        await receive_type(host, "peer_status")
        await receive_type(guest, "peer_status")
        await host.close()
        promoted = await receive_type(guest, "authority_changed")
        self.assertEqual(promoted["role"], "host")
        self.assertEqual(promoted["slot"], 2)
        disconnected = await receive_type(guest, "peer_status")
        self.assertFalse(disconnected["connected"])

        replacement = await self.open()
        joined = await join(replacement, "LEAVE1")
        self.assertEqual(joined["role"], "guest")
        self.assertEqual(joined["slot"], 1)
        self.assertEqual(sorted(peer.role for peer in server.ROOMS["LEAVE1"].values()), ["guest", "host"])

    async def test_round_metadata_and_departure_clear_votes(self):
        host = await self.open()
        guest = await self.open()
        await join(host, "ROUND1", mode="online_coop")
        await join(guest, "ROUND1", mode="online_coop")
        peers = list(server.ROOMS["ROUND1"].values())
        await server.handle_rematch_vote(peers[0], True)
        await server.handle_rematch_vote(peers[1], True)
        self.assertEqual(server.ROOM_ROUNDS["ROUND1"], 1)
        await server.handle_rematch_vote(peers[0], True)
        await guest.close()
        for _ in range(100):
            if len(server.ROOMS["ROUND1"]) == 1:
                break
            await asyncio.sleep(0.01)
        self.assertFalse(next(iter(server.ROOMS["ROUND1"].values())).rematch_ready)
        replacement = await self.open()
        joined = await join(replacement, "ROUND1", mode="online_coop")
        self.assertEqual(joined["round_id"], 1)

    async def test_health_and_privacy_pages(self):
        def fetch(path):
            with urllib.request.urlopen(self.http_base + path, timeout=2) as response:
                return response.status, response.read()

        health_status, health_body = await asyncio.to_thread(fetch, "/aksoy-tank/health")
        privacy_status, privacy_body = await asyncio.to_thread(fetch, "/aksoy-tank/privacy")
        self.assertEqual(health_status, 200)
        self.assertEqual(json.loads(health_body)["status"], "ok")
        self.assertEqual(privacy_status, 200)
        self.assertIn("Gizlilik Politikası".encode("utf-8"), privacy_body)


if __name__ == "__main__":
    unittest.main(verbosity=2)
