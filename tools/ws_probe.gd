extends SceneTree

var _peers := []
var _sent_join := {}
var _sent_input := false
var _host_received_input := false
var _guest_joined := false
var _host_joined := false
var _mode_mismatch_rejected := false
var _deadline_msec := 0


func _init() -> void:
	_deadline_msec = Time.get_ticks_msec() + 6000

	for index in range(4):
		var peer = WebSocketPeer.new()
		var error := peer.connect_to_url("ws://127.0.0.1:8765/ws")
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
			var room_code := "GODOT1" if index < 2 else "MODE1"
			var room_mode := "online_vs" if index == 3 else "online_coop"
			peer.send_text(JSON.stringify({"type": "join", "room_code": room_code, "mode": room_mode}))
			_sent_join[index] = true

		while peer.get_available_packet_count() > 0:
			var payload = JSON.parse_string(peer.get_packet().get_string_from_utf8())
			if typeof(payload) != TYPE_DICTIONARY:
				continue

			var message: Dictionary = payload
			if message.get("type", "") == "room_joined":
				if index == 0:
					_host_joined = true
				else:
					_guest_joined = true
			elif message.get("type", "") == "input" and index == 0:
				_host_received_input = true
			elif message.get("type", "") == "error" and index >= 2:
				_mode_mismatch_rejected = String(message.get("message", "")).contains("farkli")

	if _host_joined and _guest_joined and not _sent_input:
		var guest_peer: WebSocketPeer = _peers[1]
		guest_peer.send_text(JSON.stringify({"type": "input", "payload": {"turn": 1, "drive": 0, "fire": true}}))
		_sent_input = true

	if _host_received_input and _mode_mismatch_rejected:
		quit(0)
		return false

	return false
