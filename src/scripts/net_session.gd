extends Node

signal status_changed(state: String, message: String)
signal room_joined(room_code: String, role: String, slot: int)
signal peer_status_changed(connected: bool, player_count: int)
signal snapshot_updated
signal profiles_updated
signal rematch_status_updated(ready_slots: Array, start: bool, round_id: int)

const STATUS_DISCONNECTED := "disconnected"
const STATUS_CONNECTING := "connecting"
const STATUS_JOINING := "joining"
const STATUS_CONNECTED := "connected"
const STATUS_ERROR := "error"
const CONNECTION_TIMEOUT_SECONDS := 12.0
const PING_INTERVAL_SECONDS := 1.0

var _socket: WebSocketPeer = null
var _status := STATUS_DISCONNECTED
var _status_message := "Bagli degil."
var _pending_room_code := ""
var _pending_server_url := ""
var _pending_mode := "online_coop"
var _join_sent := false
var _role := ""
var _local_slot := 1
var _player_count := 1
var _peer_connected := false
var _latest_snapshot: Dictionary = {}
var _remote_inputs := {}
var _connection_elapsed := 0.0
var _ping_elapsed := 0.0
var _latency_ms := -1.0
var _jitter_ms := 0.0
var _previous_latency_sample := -1.0
var _profiles_by_slot: Dictionary = {}
var _no_delay_applied := false


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if _socket == null:
		return

	if _status in [STATUS_CONNECTING, STATUS_JOINING]:
		_connection_elapsed += delta
		if _connection_elapsed >= CONNECTION_TIMEOUT_SECONDS:
			_fail_connection("Baglanti zaman asimina ugradi. Tekrar dene.")
			return

	_socket.poll()
	var ready_state := _socket.get_ready_state()

	if ready_state == WebSocketPeer.STATE_OPEN:
		if not _no_delay_applied:
			_socket.set_no_delay(true)
			_no_delay_applied = true
		if not _join_sent:
			_join_sent = true
			_send_json({
				"type": "join",
				"room_code": _pending_room_code,
				"mode": _pending_mode,
				"build": ProjectSettings.get_setting("application/config/version", "1.5.0"),
				"profile": GameSession.get_network_profile()
			})
			_set_status(STATUS_JOINING, "Odaya katiliniyor...")

		while _socket != null and _socket.get_available_packet_count() > 0:
			var payload_text := _socket.get_packet().get_string_from_utf8()
			_handle_message(payload_text)

		if _socket != null and _status == STATUS_CONNECTED:
			_ping_elapsed += delta
			if _ping_elapsed >= PING_INTERVAL_SECONDS:
				_ping_elapsed = 0.0
				_send_json({"type": "ping", "sent_at": Time.get_ticks_msec()})
	elif ready_state == WebSocketPeer.STATE_CONNECTING:
		return
	elif ready_state == WebSocketPeer.STATE_CLOSED and _status != STATUS_DISCONNECTED:
		var was_peer_connected := _peer_connected
		_socket = null
		_reset_connection_state()
		_set_status(STATUS_DISCONNECTED, "Baglanti kapandi.")
		if was_peer_connected:
			peer_status_changed.emit(false, 1)


func connect_to_room(server_url: String, room_code: String, mode: String = "online_coop") -> void:
	disconnect_session(false)
	_socket = WebSocketPeer.new()
	_socket.inbound_buffer_size = 262144
	_socket.outbound_buffer_size = 262144
	_socket.max_queued_packets = 256
	_socket.heartbeat_interval = 10.0
	_pending_server_url = server_url.strip_edges()
	_pending_room_code = _sanitize_room_code(room_code)
	_pending_mode = mode if mode in ["online_coop", "online_vs"] else "online_coop"
	_join_sent = false
	_no_delay_applied = false
	_connection_elapsed = 0.0

	var is_secure_url := _pending_server_url.begins_with("wss://")
	var is_local_debug_url := OS.is_debug_build() and (
		_pending_server_url.begins_with("ws://127.0.0.1")
		or _pending_server_url.begins_with("ws://localhost")
	)
	if not is_secure_url and not is_local_debug_url:
		_socket = null
		_set_status(STATUS_ERROR, "Guvenli sunucu adresi gecersiz.")
		return

	var error := _socket.connect_to_url(_pending_server_url)
	if error != OK:
		_socket = null
		_set_status(STATUS_ERROR, "Sunucuya baglanilamadi.")
		return

	_set_status(STATUS_CONNECTING, "Sunucuya baglaniliyor...")


func disconnect_session(emit_status: bool = true) -> void:
	if _socket:
		_socket.close()

	_socket = null
	_reset_connection_state()

	if emit_status:
		_set_status(STATUS_DISCONNECTED, "Bagli degil.")


func is_online_active() -> bool:
	return _status == STATUS_CONNECTED


func is_host() -> bool:
	return _role == "host"


func is_peer_connected() -> bool:
	return _peer_connected


func get_status() -> String:
	return _status


func get_status_message() -> String:
	return _status_message


func get_local_slot() -> int:
	return _local_slot


func get_player_count() -> int:
	return _player_count


func get_room_mode() -> String:
	return _pending_mode


func get_latency_ms() -> float:
	return _latency_ms


func get_jitter_ms() -> float:
	return _jitter_ms


func get_network_quality_text() -> String:
	if _latency_ms < 0.0:
		return "PING --"
	var quality := "IYI"
	if _latency_ms >= 140.0 or _jitter_ms >= 45.0:
		quality = "ZAYIF"
	elif _latency_ms >= 80.0 or _jitter_ms >= 25.0:
		quality = "ORTA"
	return "PING %d ms %s" % [roundi(_latency_ms), quality]


func get_latest_snapshot() -> Dictionary:
	return Dictionary(_latest_snapshot.duplicate(true))


func get_remote_input(slot: int) -> Dictionary:
	if _remote_inputs.has(slot):
		return Dictionary(_remote_inputs[slot].duplicate(true))

	return {
		"turn": 0.0,
		"drive": 0.0,
		"move_x": 0.0,
		"move_y": 0.0,
		"fire": false
	}


func get_player_profile(slot: int) -> Dictionary:
	if _profiles_by_slot.has(slot):
		var raw: Dictionary = _profiles_by_slot[slot]
		return GameSession.build_tank_profile(String(raw.get("name", "Oyuncu")), String(raw.get("style_id", "akinci")))
	if slot == _local_slot:
		return GameSession.get_network_profile()
	return GameSession.build_tank_profile("Rakip", "gece")


func clear_match_buffers() -> void:
	_latest_snapshot.clear()
	_remote_inputs.clear()


func send_input(input_state: Dictionary) -> void:
	if not is_online_active():
		return

	_send_json({
		"type": "input",
		"payload": input_state
	})


func send_snapshot(snapshot: Dictionary) -> void:
	if not is_online_active() or not is_host():
		return

	_send_json({
		"type": "snapshot",
		"payload": snapshot
	})


func send_rematch_vote(ready: bool = true) -> void:
	if not is_online_active() or not _peer_connected:
		return

	_send_json({
		"type": "rematch_vote",
		"payload": {"ready": ready}
	})


func _handle_message(payload_text: String) -> void:
	var parsed = JSON.parse_string(payload_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var message: Dictionary = parsed
	match String(message.get("type", "")):
		"room_joined":
			_role = String(message.get("role", "guest"))
			_local_slot = int(message.get("slot", 1))
			if _role not in ["host", "guest"] or _local_slot not in [1, 2]:
				_fail_connection("Sunucu yaniti gecersiz.")
				return
			_player_count = int(message.get("player_count", 1))
			_peer_connected = _player_count > 1
			_apply_profiles(Array(message.get("profiles", [])))
			_set_status(STATUS_CONNECTED, "Odaya baglandi.")
			room_joined.emit(String(message.get("room_code", "")), _role, _local_slot)
			peer_status_changed.emit(_peer_connected, _player_count)
		"peer_status":
			_player_count = int(message.get("player_count", 1))
			_peer_connected = bool(message.get("connected", false))
			_apply_profiles(Array(message.get("profiles", [])))
			var status_text := "Es oyuncu baglandi." if _peer_connected else "Es oyuncu bekleniyor."
			_set_status(_status, status_text)
			peer_status_changed.emit(_peer_connected, _player_count)
		"snapshot":
			_latest_snapshot = Dictionary(message.get("payload", {}).duplicate(true))
			snapshot_updated.emit()
		"input":
			var from_slot := int(message.get("from_slot", 2))
			_remote_inputs[from_slot] = Dictionary(message.get("payload", {}).duplicate(true))
		"rematch_status":
			var ready_slots := Array(message.get("ready_slots", [])).duplicate()
			var valid_slots: Array = []
			for slot_value in ready_slots:
				var slot := int(slot_value)
				if slot in [1, 2] and slot not in valid_slots:
					valid_slots.append(slot)
			valid_slots.sort()
			rematch_status_updated.emit(valid_slots, bool(message.get("start", false)), maxi(int(message.get("round_id", 0)), 0))
		"pong":
			var sent_at := int(message.get("sent_at", Time.get_ticks_msec()))
			var sample := clampf(float(Time.get_ticks_msec() - sent_at), 0.0, 5000.0)
			if _latency_ms < 0.0:
				_latency_ms = sample
			else:
				_latency_ms = lerpf(_latency_ms, sample, 0.25)
			if _previous_latency_sample >= 0.0:
				_jitter_ms = lerpf(_jitter_ms, absf(sample - _previous_latency_sample), 0.25)
			_previous_latency_sample = sample
		"error":
			_fail_connection(String(message.get("message", "Sunucu hatasi.")))
		_:
			return


func _send_json(payload: Dictionary) -> void:
	if _socket == null or _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_socket.send_text(JSON.stringify(payload))


func _reset_connection_state() -> void:
	_pending_room_code = ""
	_pending_server_url = ""
	_pending_mode = "online_coop"
	_join_sent = false
	_role = ""
	_local_slot = 1
	_player_count = 1
	_peer_connected = false
	_latest_snapshot.clear()
	_remote_inputs.clear()
	_connection_elapsed = 0.0
	_ping_elapsed = 0.0
	_latency_ms = -1.0
	_jitter_ms = 0.0
	_previous_latency_sample = -1.0
	_profiles_by_slot.clear()
	_no_delay_applied = false


func _fail_connection(message: String) -> void:
	var was_peer_connected := _peer_connected
	if _socket:
		_socket.close(1008, "protocol error")
	_socket = null
	_reset_connection_state()
	_set_status(STATUS_ERROR, message)
	if was_peer_connected:
		peer_status_changed.emit(false, 1)


func _set_status(state: String, message: String) -> void:
	_status = state
	_status_message = message
	status_changed.emit(_status, _status_message)


func _sanitize_room_code(value: String) -> String:
	var sanitized := value.to_upper().strip_edges()
	var result := ""

	for character in sanitized:
		if (character >= "A" and character <= "Z") or (character >= "0" and character <= "9"):
			result += character

	return result.substr(0, 8)


func _apply_profiles(profiles: Array) -> void:
	var changed := false
	for entry in profiles:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var profile: Dictionary = entry
		var slot := int(profile.get("slot", 0))
		if slot not in [1, 2]:
			continue
		var normalized := {
			"name": String(profile.get("name", "Oyuncu")),
			"style_id": String(profile.get("style_id", "akinci"))
		}
		if not _profiles_by_slot.has(slot) or _profiles_by_slot[slot] != normalized:
			_profiles_by_slot[slot] = normalized
			changed = true
	if changed:
		profiles_updated.emit()
