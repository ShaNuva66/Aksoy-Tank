extends Node

const STAGE_CATALOG = preload("res://src/scripts/stage_catalog.gd")
const SAVE_PATH := "user://campaign_progress.cfg"
const SESSION_MODES := ["solo", "online_coop", "online_vs"]
const CONTROL_STYLES := ["analog"]
const DEFAULT_SERVER_URL := "ws://127.0.0.1:8765/ws"
const DEFAULT_ROOM_CODE := "ALFA1"

signal progress_changed

var selected_stage_index: int = 0
var unlocked_stage_count: int = 1
var session_mode := "solo"
var server_url := DEFAULT_SERVER_URL
var room_code := DEFAULT_ROOM_CODE
var control_style := "analog"


func get_stage_count() -> int:
	return STAGE_CATALOG.get_stage_count()


func _ready() -> void:
	_load_progress()
	_apply_launch_arguments()


func get_selected_stage() -> Dictionary:
	return STAGE_CATALOG.get_stage(selected_stage_index)


func get_stage(index: int) -> Dictionary:
	return STAGE_CATALOG.get_stage(index)


func set_selected_stage(index: int) -> void:
	selected_stage_index = clamp(index, 0, get_highest_selectable_stage_index())
	_save_progress()


func shift_stage(delta: int) -> void:
	set_selected_stage(selected_stage_index + delta)


func has_next_stage() -> bool:
	return selected_stage_index < get_highest_selectable_stage_index()


func advance_to_next_stage() -> bool:
	if not has_next_stage():
		return false

	selected_stage_index += 1
	_save_progress()
	return true


func get_unlocked_stage_count() -> int:
	return unlocked_stage_count


func get_player_count() -> int:
	return 2 if is_online_mode() else 1


func get_local_control_player_count() -> int:
	return 1


func is_stage_unlocked(index: int) -> bool:
	return index >= 0 and index < unlocked_stage_count


func get_highest_selectable_stage_index() -> int:
	return max(unlocked_stage_count - 1, 0)


func mark_stage_completed(index: int) -> bool:
	var previous_unlocked := unlocked_stage_count
	unlocked_stage_count = max(unlocked_stage_count, min(index + 2, get_stage_count()))
	selected_stage_index = clamp(selected_stage_index, 0, get_highest_selectable_stage_index())
	_save_progress()

	if unlocked_stage_count != previous_unlocked:
		progress_changed.emit()
		return true

	progress_changed.emit()
	return false


func reset_progress() -> void:
	unlocked_stage_count = 1
	selected_stage_index = 0
	_save_progress()
	progress_changed.emit()


func get_session_mode() -> String:
	return session_mode


func get_control_style() -> String:
	return control_style


func set_control_style(style: String) -> void:
	control_style = "analog"
	_save_progress()
	progress_changed.emit()


func get_session_mode_label() -> String:
	match session_mode:
		"online_coop":
			return "ONLINE CO-OP"
		"online_vs":
			return "ONLINE VS"
		_:
			return "SOLO"


func is_local_coop_enabled() -> bool:
	return false


func is_online_mode() -> bool:
	return session_mode in ["online_coop", "online_vs"]


func is_online_coop() -> bool:
	return session_mode == "online_coop"


func is_online_vs() -> bool:
	return session_mode == "online_vs"


func set_session_mode(mode: String) -> void:
	if not SESSION_MODES.has(mode):
		mode = "solo"

	session_mode = mode
	_save_progress()
	progress_changed.emit()


func shift_session_mode(delta: int) -> void:
	var current_index := SESSION_MODES.find(session_mode)
	if current_index < 0:
		current_index = 0

	var next_index := clampi(current_index + delta, 0, SESSION_MODES.size() - 1)
	set_session_mode(SESSION_MODES[next_index])


func set_room_code(value: String) -> void:
	room_code = _sanitize_room_code(value)
	_save_progress()
	progress_changed.emit()


func get_room_code() -> String:
	return room_code


func set_server_url(value: String) -> void:
	var sanitized := value.strip_edges()
	server_url = DEFAULT_SERVER_URL if sanitized.is_empty() else sanitized
	_save_progress()
	progress_changed.emit()


func get_server_url() -> String:
	return server_url


func _load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error == OK:
		unlocked_stage_count = int(config.get_value("campaign", "unlocked_stage_count", 1))
		selected_stage_index = int(config.get_value("campaign", "selected_stage_index", 0))
		session_mode = String(config.get_value("settings", "session_mode", "solo"))
		server_url = String(config.get_value("settings", "server_url", DEFAULT_SERVER_URL))
		room_code = String(config.get_value("settings", "room_code", DEFAULT_ROOM_CODE))
		control_style = String(config.get_value("settings", "control_style", "analog"))

	unlocked_stage_count = clamp(unlocked_stage_count, 1, get_stage_count())
	selected_stage_index = clamp(selected_stage_index, 0, get_highest_selectable_stage_index())
	if session_mode == "local":
		session_mode = "solo"
	elif session_mode == "online":
		session_mode = "online_coop"
	if not SESSION_MODES.has(session_mode):
		session_mode = "solo"
	control_style = "analog"
	server_url = DEFAULT_SERVER_URL if server_url.strip_edges().is_empty() else server_url.strip_edges()
	room_code = _sanitize_room_code(room_code)


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("campaign", "unlocked_stage_count", unlocked_stage_count)
	config.set_value("campaign", "selected_stage_index", selected_stage_index)
	config.set_value("settings", "session_mode", session_mode)
	config.set_value("settings", "server_url", server_url)
	config.set_value("settings", "room_code", room_code)
	config.set_value("settings", "control_style", control_style)
	config.save(SAVE_PATH)


func _sanitize_room_code(value: String) -> String:
	var sanitized := value.to_upper().strip_edges()
	var result := ""

	for character in sanitized:
		if (character >= "A" and character <= "Z") or (character >= "0" and character <= "9"):
			result += character

	return DEFAULT_ROOM_CODE if result.is_empty() else result.substr(0, 8)


func _apply_launch_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--unlock-all-stages":
			unlocked_stage_count = get_stage_count()
		elif argument.begins_with("--start-stage="):
			var requested_stage := maxi(int(argument.trim_prefix("--start-stage=")), 1)
			unlocked_stage_count = get_stage_count()
			selected_stage_index = clampi(requested_stage - 1, 0, get_stage_count() - 1)
			session_mode = "solo"
