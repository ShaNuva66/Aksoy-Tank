extends SceneTree

var _peers := []
var _sent_join := {}
var _sent_input := false
var _host_received_input := false
var _guest_index := -1
var _host_index := -1
var _mode_mismatch_rejected := false
var _host_closed := false
var _host_migration_received := false
var _matchmaking_rooms := {}
var _matchmaking_paired := false
var _deadline_msec := 0


func _init() -> void:
	_deadline_msec = Time.get_ticks_msec() + 6000
	var server_url := "ws://127.0.0.1:8765/ws"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--server-url="):
			server_url = argument.trim_prefix("--server-url=")

	for index in range(6):
		var peer = WebSocketPeer.new()
		var error := peer.connect_to_url(server_url)
		if error != OK:
			push_error("Probe could not connect peer %d" % (index + 1))
			quit(1)
			return

		_peers.append(peer)
		_sent_join[index] = false


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() > _deadline_msec:
		push_error("WebSocket probe timed out.")
		quit(1)
		return false

	for index in range(_peers.size()):
		var peer: WebSocketPeer = _peers[index]
		peer.poll()

		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN and not _sent_join[index]:
			if index >= 4:
				peer.send_text(JSON.stringify({"type": "matchmake", "mode": "online_coop", "build": "2.0.6", "profile": {"name": "AutoProbe", "style_id": "akinci"}}))
			else:
				var room_code := "GODOT1" if index < 2 else "MODE1"
				var room_mode := "online_coop" if index == 3 else "online_vs"
				peer.send_text(JSON.stringify({"type": "join", "room_code": room_code, "mode": room_mode, "build": "2.0.6", "profile": {"name": "Probe", "style_id": "akinci"}}))
			_sent_join[index] = true

		while peer.get_available_packet_count() > 0:
			var payload = JSON.parse_string(peer.get_packet().get_string_from_utf8())
			if typeof(payload) != TYPE_DICTIONARY:
				continue

			var message: Dictionary = payload
			print("WS_PROBE[%d]: %s" % [index + 1, String(message.get("type", "unknown"))])
			if message.get("type", "") == "room_joined" and index < 2:
				if String(message.get("role", "")) == "host":
					_host_index = index
				else:
					_guest_index = index
			elif message.get("type", "") == "input" and index == _host_index:
				_host_received_input = true
			elif message.get("type", "") == "error" and index >= 2:
				_mode_mismatch_rejected = true
			elif message.get("type", "") == "authority_changed" and index == _guest_index:
				_host_migration_received = String(message.get("role", "")) == "host"
			elif message.get("type", "") == "room_joined" and index >= 4:
				_matchmaking_rooms[index] = String(message.get("room_code", ""))
				if _matchmaking_rooms.has(4) and _matchmaking_rooms.has(5):
					_matchmaking_paired = _matchmaking_rooms[4] == _matchmaking_rooms[5]

	if _host_index >= 0 and _guest_index >= 0 and not _sent_input:
		var guest_peer: WebSocketPeer = _peers[_guest_index]
		guest_peer.send_text(JSON.stringify({"type": "input", "payload": {"turn": 1, "drive": 0, "fire": true}}))
		_sent_input = true

	if _host_received_input and _mode_mismatch_rejected and not _host_closed:
		_peers[_host_index].close(1000, "probe migration")
		_host_closed = true

	if _host_received_input and _mode_mismatch_rejected and _host_migration_received and _matchmaking_paired:
		quit(0)
		return false

	return false
