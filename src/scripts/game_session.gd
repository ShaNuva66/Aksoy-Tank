extends Node

const STAGE_CATALOG = preload("res://src/scripts/stage_catalog.gd")
const SAVE_PATH := "user://campaign_progress.cfg"
const SESSION_MODES := ["solo", "online_coop", "online_vs"]
const AVAILABLE_SESSION_MODES := ["solo", "online_coop", "online_vs"]
const ONLINE_AVAILABLE := true
const CONTROL_STYLES := ["analog"]
const DEFAULT_SERVER_URL := "wss://atify.com.tr/aksoy-tank/ws"
const DEFAULT_ROOM_CODE := ""
const DEFAULT_PLAYER_NAME := "Oyuncu"
const DEFAULT_TANK_STYLE := "akinci"
const TANK_STYLE_ORDER := ["akinci", "gece", "col", "neon", "orman"]
const TANK_STYLES := {
	"akinci": {"label": "AKINCI", "body_color": "#b84f45", "turret_color": "#f1c75b", "track_color": "#282c35", "accent_color": "#fff0b0"},
	"gece": {"label": "GECE AVCISI", "body_color": "#314a68", "turret_color": "#60c8d4", "track_color": "#172330", "accent_color": "#a8f5ff"},
	"col": {"label": "COL FIRTINASI", "body_color": "#b99058", "turret_color": "#df713f", "track_color": "#3b3028", "accent_color": "#ffe0a3"},
	"neon": {"label": "NEON PENÇE", "body_color": "#69479a", "turret_color": "#e958a5", "track_color": "#241b35", "accent_color": "#ffc1ef"},
	"orman": {"label": "ORMAN MUHAFIZI", "body_color": "#477b58", "turret_color": "#c5a957", "track_color": "#25352b", "accent_color": "#dcf5a4"}
}

signal progress_changed

var selected_stage_index: int = 0
var unlocked_stage_count: int = 1
var session_mode := "solo"
var server_url := DEFAULT_SERVER_URL
var room_code := DEFAULT_ROOM_CODE
var control_style := "analog"
var player_name := DEFAULT_PLAYER_NAME
var tank_style_id := DEFAULT_TANK_STYLE
var music_volume := 0.55
var sfx_volume := 0.8
var haptics_enabled := true
var effects_intensity := 0.8
var reduced_motion_enabled := false
var onboarding_completed := false


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
	onboarding_completed = false
	_save_progress()
	progress_changed.emit()


func get_session_mode() -> String:
	return session_mode


func get_session_mode_count() -> int:
	return AVAILABLE_SESSION_MODES.size()


func is_online_available() -> bool:
	return ONLINE_AVAILABLE


func get_control_style() -> String:
	return control_style


func get_music_volume() -> float:
	return music_volume


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_save_progress()
	progress_changed.emit()


func get_sfx_volume() -> float:
	return sfx_volume


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_save_progress()
	progress_changed.emit()


func is_haptics_enabled() -> bool:
	return haptics_enabled


func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled
	_save_progress()
	progress_changed.emit()


func get_effects_intensity() -> float:
	return effects_intensity


func set_effects_intensity(value: float) -> void:
	effects_intensity = clampf(value, 0.0, 1.0)
	_save_progress()
	progress_changed.emit()


func is_reduced_motion_enabled() -> bool:
	return reduced_motion_enabled


func set_reduced_motion_enabled(enabled: bool) -> void:
	reduced_motion_enabled = enabled
	_save_progress()
	progress_changed.emit()


func has_completed_onboarding() -> bool:
	return onboarding_completed


func complete_onboarding() -> void:
	if onboarding_completed:
		return
	onboarding_completed = true
	_save_progress()


func set_control_style(style: String) -> void:
	control_style = "buttons" if style == "buttons" else "analog"
	_save_progress()
	progress_changed.emit()


func get_session_mode_label() -> String:
	match session_mode:
		"online_coop":
			return "ONLINE CO-OP"
		"online_vs":
			return "ONLINE 1V1"
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
	var current_index := AVAILABLE_SESSION_MODES.find(session_mode)
	if current_index < 0:
		current_index = 0

	var next_index := clampi(current_index + delta, 0, AVAILABLE_SESSION_MODES.size() - 1)
	set_session_mode(AVAILABLE_SESSION_MODES[next_index])


func set_room_code(value: String) -> void:
	room_code = _sanitize_room_code(value)
	_save_progress()
	progress_changed.emit()


func get_room_code() -> String:
	return room_code


func set_server_url(_value: String) -> void:
	server_url = DEFAULT_SERVER_URL
	_save_progress()
	progress_changed.emit()


func get_server_url() -> String:
	return server_url


func set_player_name(value: String) -> void:
	player_name = _sanitize_player_name(value)
	_save_progress()
	progress_changed.emit()


func get_player_name() -> String:
	return player_name


func set_tank_style(style_id: String) -> void:
	tank_style_id = style_id if TANK_STYLES.has(style_id) else DEFAULT_TANK_STYLE
	_save_progress()
	progress_changed.emit()


func shift_tank_style(delta: int) -> void:
	var current_index := TANK_STYLE_ORDER.find(tank_style_id)
	if current_index < 0:
		current_index = 0
	set_tank_style(TANK_STYLE_ORDER[wrapi(current_index + delta, 0, TANK_STYLE_ORDER.size())])


func get_tank_style_id() -> String:
	return tank_style_id


func get_tank_style() -> Dictionary:
	return Dictionary(TANK_STYLES.get(tank_style_id, TANK_STYLES[DEFAULT_TANK_STYLE]).duplicate(true))


func build_tank_profile(profile_name: String, style_id: String) -> Dictionary:
	var safe_style_id := style_id if TANK_STYLES.has(style_id) else DEFAULT_TANK_STYLE
	var style := Dictionary(TANK_STYLES[safe_style_id])
	var safe_name := _sanitize_player_name(profile_name)
	if safe_name.length() < 3:
		safe_name = DEFAULT_PLAYER_NAME
	return {
		"name": safe_name,
		"style_id": safe_style_id,
		"body_color": String(style.get("body_color", "#7fb069")),
		"turret_color": String(style.get("turret_color", "#d3ad58")),
		"track_color": String(style.get("track_color", "#2e3945")),
		"accent_color": String(style.get("accent_color", "#fff0b0"))
	}


func get_network_profile() -> Dictionary:
	return build_tank_profile(player_name, tank_style_id)


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
		player_name = String(config.get_value("profile", "player_name", DEFAULT_PLAYER_NAME))
		tank_style_id = String(config.get_value("profile", "tank_style_id", DEFAULT_TANK_STYLE))
		music_volume = float(config.get_value("settings", "music_volume", 0.55))
		sfx_volume = float(config.get_value("settings", "sfx_volume", 0.8))
		haptics_enabled = bool(config.get_value("settings", "haptics_enabled", true))
		effects_intensity = float(config.get_value("settings", "effects_intensity", 0.8))
		reduced_motion_enabled = bool(config.get_value("settings", "reduced_motion_enabled", false))
		onboarding_completed = bool(config.get_value("campaign", "onboarding_completed", false))
	else:
		room_code = _generate_room_code()

	unlocked_stage_count = clamp(unlocked_stage_count, 1, get_stage_count())
	selected_stage_index = clamp(selected_stage_index, 0, get_highest_selectable_stage_index())
	if session_mode == "local":
		session_mode = "solo"
	elif session_mode == "online":
		session_mode = "online_coop"
	if not AVAILABLE_SESSION_MODES.has(session_mode):
		session_mode = "solo"
	control_style = "buttons" if control_style == "buttons" else "analog"
	server_url = DEFAULT_SERVER_URL
	room_code = _sanitize_room_code(room_code)
	player_name = _sanitize_player_name(player_name)
	if player_name.length() < 3:
		player_name = DEFAULT_PLAYER_NAME
	if not TANK_STYLES.has(tank_style_id):
		tank_style_id = DEFAULT_TANK_STYLE
	music_volume = clampf(music_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	effects_intensity = clampf(effects_intensity, 0.0, 1.0)
	if room_code.is_empty() or room_code == "ALFA1":
		room_code = _generate_room_code()


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("campaign", "unlocked_stage_count", unlocked_stage_count)
	config.set_value("campaign", "selected_stage_index", selected_stage_index)
	config.set_value("settings", "session_mode", session_mode)
	config.set_value("settings", "server_url", server_url)
	config.set_value("settings", "room_code", room_code)
	config.set_value("settings", "control_style", control_style)
	config.set_value("profile", "player_name", player_name)
	config.set_value("profile", "tank_style_id", tank_style_id)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "haptics_enabled", haptics_enabled)
	config.set_value("settings", "effects_intensity", effects_intensity)
	config.set_value("settings", "reduced_motion_enabled", reduced_motion_enabled)
	config.set_value("campaign", "onboarding_completed", onboarding_completed)
	config.save(SAVE_PATH)


func _sanitize_room_code(value: String) -> String:
	var sanitized := value.to_upper().strip_edges()
	var result := ""

	for character in sanitized:
		if (character >= "A" and character <= "Z") or (character >= "0" and character <= "9"):
			result += character

	return result.substr(0, 8)


func _sanitize_player_name(value: String) -> String:
	const ALLOWED := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ÇĞİÖŞÜçğıöşü-_"
	var result := ""
	var previous_was_space := false
	for character in value.strip_edges():
		if not ALLOWED.contains(character):
			continue
		var is_space := character == " "
		if is_space and previous_was_space:
			continue
		result += character
		previous_was_space = is_space
	return result.strip_edges().substr(0, 18)


func _generate_room_code() -> String:
	const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var generated := ""
	for _index in range(6):
		generated += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return generated


func _apply_launch_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--unlock-all-stages":
			unlocked_stage_count = get_stage_count()
		elif argument == "--online-vs":
			session_mode = "online_vs"
		elif argument.begins_with("--room-code="):
			room_code = _sanitize_room_code(argument.trim_prefix("--room-code="))
		elif argument.begins_with("--player-name="):
			player_name = _sanitize_player_name(argument.trim_prefix("--player-name="))
		elif argument.begins_with("--tank-style="):
			set_tank_style(argument.trim_prefix("--tank-style="))
		elif argument.begins_with("--start-stage="):
			var requested_stage := maxi(int(argument.trim_prefix("--start-stage=")), 1)
			unlocked_stage_count = get_stage_count()
			selected_stage_index = clampi(requested_stage - 1, 0, get_stage_count() - 1)
			session_mode = "solo"
