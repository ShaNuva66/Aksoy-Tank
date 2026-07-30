extends Node

signal status_changed(state: String, message: String)
signal room_joined(room_code: String, role: String, slot: int)
signal peer_status_changed(connected: bool, player_count: int)
signal snapshot_updated

const STATUS_DISCONNECTED := "disconnected"
const STATUS_CONNECTING := "connecting"
const STATUS_JOINING := "joining"
const STATUS_CONNECTED := "connected"
const STATUS_ERROR := "error"

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


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if _socket == null:
		return

	_socket.poll()
	var ready_state := _socket.get_ready_state()

	if ready_state == WebSocketPeer.STATE_OPEN:
		if not _join_sent:
			_join_sent = true
			_send_json({
				"type": "join",
				"room_code": _pending_room_code,
				"mode": _pending_mode,
				"build": ProjectSettings.get_setting("application/config/version", "1.4.0")
			})
			_set_status(STATUS_JOINING, "Odaya katiliniyor...")

		while _socket.get_available_packet_count() > 0:
			var payload_text := _socket.get_packet().get_string_from_utf8()
			_handle_message(payload_text)
	elif ready_state == WebSocketPeer.STATE_CONNECTING:
		return
	elif ready_state == WebSocketPeer.STATE_CLOSED and _status != STATUS_DISCONNECTED:
		_reset_connection_state()
		_set_status(STATUS_DISCONNECTED, "Baglanti kapandi.")


func connect_to_room(server_url: String, room_code: String, mode: String = "online_coop") -> void:
	disconnect_session(false)
	_socket = WebSocketPeer.new()
	_pending_server_url = server_url.strip_edges()
	_pending_room_code = _sanitize_room_code(room_code)
	_pending_mode = mode if mode in ["online_coop", "online_vs"] else "online_coop"
	_join_sent = false

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


func _handle_message(payload_text: String) -> void:
	var parsed = JSON.parse_string(payload_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var message: Dictionary = parsed
	match String(message.get("type", "")):
		"room_joined":
			_role = String(message.get("role", "guest"))
			_local_slot = int(message.get("slot", 1))
			_player_count = int(message.get("player_count", 1))
			_peer_connected = _player_count > 1
			_set_status(STATUS_CONNECTED, "Odaya baglandi.")
			room_joined.emit(String(message.get("room_code", "")), _role, _local_slot)
			peer_status_changed.emit(_peer_connected, _player_count)
		"peer_status":
			_player_count = int(message.get("player_count", 1))
			_peer_connected = bool(message.get("connected", false))
			var status_text := "Es oyuncu baglandi." if _peer_connected else "Es oyuncu bekleniyor."
			_set_status(_status, status_text)
			peer_status_changed.emit(_peer_connected, _player_count)
		"snapshot":
			_latest_snapshot = Dictionary(message.get("payload", {}).duplicate(true))
			snapshot_updated.emit()
		"input":
			var from_slot := int(message.get("from_slot", 2))
			_remote_inputs[from_slot] = Dictionary(message.get("payload", {}).duplicate(true))
		"error":
			_set_status(STATUS_ERROR, String(message.get("message", "Sunucu hatasi.")))
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

	return "ALFA1" if result.is_empty() else result.substr(0, 8)
