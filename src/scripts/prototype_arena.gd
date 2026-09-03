extends Node2D

const STAGE_CATALOG := preload("res://src/scripts/stage_catalog.gd")
const PLAYER_TANK_SCENE := preload("res://src/scenes/player_tank.tscn")
const ENEMY_TANK_SCENE := preload("res://src/scenes/enemy_tank.tscn")
const BULLET_SCENE := preload("res://src/scenes/bullet.tscn")
const IMPACT_BURST_SCENE := preload("res://src/scenes/impact_burst.tscn")
const PICKUP_SCENE := preload("res://src/scenes/pickup.tscn")
const WALL_BLOCK_SCENE := preload("res://src/scenes/wall_block.tscn")
const BlackCatTheme := preload("res://src/scripts/black_cat_theme.gd")
const HeartHud := preload("res://src/scripts/heart_hud.gd")
const DamageVignette := preload("res://src/scripts/damage_vignette.gd")
const HitConfirmation := preload("res://src/scripts/hit_confirmation.gd")
const OnboardingGuide := preload("res://src/scripts/onboarding_guide.gd")
const MobileFeedback := preload("res://src/scripts/mobile_feedback.gd")
const CELL_SIZE := 48.0
const GRID_SIZE := Vector2i(26, 15)
const GRID_OFFSET := Vector2(16.0, 0.0)
const SPAWN_POINTS := [Vector2i(3, 1), Vector2i(8, 1), Vector2i(17, 1), Vector2i(22, 1)]
const BASE_RESERVED_CELLS := [
	Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11),
	Vector2i(11, 12), Vector2i(12, 12), Vector2i(13, 12)
]
const SNAPSHOT_INTERVAL := 0.05
const INPUT_SEND_INTERVAL := 0.033
const WAVE_BREAK_DELAY := 2.2
const VS_CACHE_CELLS := [Vector2i(2, 3), Vector2i(23, 11)]
const VS_CACHE_FIRST_DELAY := 9.0
const VS_CACHE_REPEAT_DELAY := 27.0
const VS_CACHE_LIFETIME := 8.0
const VS_CACHE_MAX_WAVES := 2
const VS_CENTER_POSITION := Vector2(640.0, 360.0)
const VS_CENTER_RESERVED_CELLS := [Vector2i(12, 7), Vector2i(13, 7)]
const VS_CENTER_FIRST_DELAY := 5.0
const VS_CENTER_REPEAT_DELAY := 24.0
const VS_CENTER_LIFETIME := 7.0
const VS_CENTER_MAX_WAVES := 2
const PLAYER_PROFILES := {
	1: {
		"slot": 1,
		"callsign": "P1",
		"body_color": Color("#7fb069"),
		"turret_color": Color("#d3ad58"),
		"track_color": Color("#2e3945")
	},
	2: {
		"slot": 2,
		"callsign": "P2",
		"body_color": Color("#6db5d9"),
		"turret_color": Color("#ffd883"),
		"track_color": Color("#264150")
	}
}

class PauseInputProxy:
	extends Node

	var arena: Node = null

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		set_process_input(true)

	func _input(event: InputEvent) -> void:
		if arena and arena.has_method("_handle_pause_overlay_input"):
			arena._handle_pause_overlay_input(event)

@onready var player_template = $PlayerTank
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var hud: CanvasLayer = $Hud
@onready var header_backdrop: ColorRect = $Hud/HeaderBackdrop
@onready var header: MarginContainer = $Hud/Header
@onready var info_label: Label = $Hud/Header/VBox/InfoLabel
@onready var brief_label: Label = $Hud/Header/VBox/BriefLabel
@onready var status_label: Label = $Hud/Header/VBox/StatusLabel
@onready var stats_label: Label = $Hud/Header/VBox/StatsLabel
@onready var wave_label: Label = $Hud/Header/VBox/WaveLabel
@onready var power_label: Label = $Hud/Header/VBox/PowerLabel
@onready var alert_label: Label = $Hud/Header/VBox/AlertLabel
@onready var pause_button: Button = $Hud/PauseButton
@onready var shield_backdrop: ColorRect = $Hud/ShieldBackdrop
@onready var shield_hud: MarginContainer = $Hud/ShieldHud
@onready var shield_label: Label = $Hud/ShieldHud/VBox/Label
@onready var shield_bar: ProgressBar = $Hud/ShieldHud/VBox/Bar
@onready var result_dim: ColorRect = $Hud/ResultOverlay/Dim
@onready var result_fx: Control = $Hud/ResultOverlay/ResultFX
@onready var result_panel: PanelContainer = $Hud/ResultOverlay/CenterContainer/Panel
@onready var result_overlay: Control = $Hud/ResultOverlay
@onready var result_title: Label = $Hud/ResultOverlay/CenterContainer/Panel/Margin/VBox/Title
@onready var result_subtitle: Label = $Hud/ResultOverlay/CenterContainer/Panel/Margin/VBox/Subtitle
@onready var next_stage_button: Button = $Hud/ResultOverlay/CenterContainer/Panel/Margin/VBox/NextStageButton
@onready var retry_button: Button = $Hud/ResultOverlay/CenterContainer/Panel/Margin/VBox/RetryButton
@onready var menu_button: Button = $Hud/ResultOverlay/CenterContainer/Panel/Margin/VBox/MenuButton
@onready var pause_panel: PanelContainer = $Hud/PauseOverlay/CenterContainer/Panel
@onready var pause_overlay: Control = $Hud/PauseOverlay
@onready var pause_control_label: Label = $Hud/PauseOverlay/CenterContainer/Panel/Margin/VBox/ControlLabel
@onready var pause_control_row: HBoxContainer = $Hud/PauseOverlay/CenterContainer/Panel/Margin/VBox/ControlRow
@onready var pause_analog_button: Button = $Hud/PauseOverlay/CenterContainer/Panel/Margin/VBox/ControlRow/AnalogButton
@onready var pause_buttons_button: Button = $Hud/PauseOverlay/CenterContainer/Panel/Margin/VBox/ControlRow/ButtonsButton
@onready var pause_resume_button: Button = $Hud/PauseOverlay/CenterContainer/Panel/Margin/VBox/ResumeButton
@onready var pause_menu_button: Button = $Hud/PauseOverlay/CenterContainer/Panel/Margin/VBox/MenuButton
@onready var mobile_controls = $MobileControls
@onready var camera: Camera2D = $ArenaCamera

var _stage_data: Dictionary = {}
var _enemy_queue: Array = []
var _session_mode := "solo"
var _player_count := 1
var _local_control_count := 1
var _local_player_slot := 1
var _players_by_slot := {}
var _player_spawn_cells: Array[Vector2i] = []
var _spawned_enemies := 0
var _alive_enemies := 0
var _total_enemies := 0
var _destroyed_enemies := 0
var _match_over := false
var _status_text := "Catismaya devam"
var _rng := RandomNumberGenerator.new()
var _capture_requested := false
var _capture_output_path := ""
var _capture_stage_index := -1
var _capture_delay_frames := 150
var _capture_size := Vector2i.ZERO
var _theme_palette: Dictionary = {}
var _combat_balance: Dictionary = {}
var _alert_time := 0.0
var _alert_color := Color("#f2d48f")
var _next_network_id := 1
var _snapshot_send_timer := SNAPSHOT_INTERVAL
var _input_send_timer := INPUT_SEND_INTERVAL
var _waiting_for_peer := false
var _paused := false
var _heart_hud: Control = null
var _damage_overlay: Control = null
var _onboarding_guide: Control = null
var _last_health_by_slot := {}
var _objective_type := "eliminate"
var _objective_target_type := ""
var _objective_target_total := 0
var _objective_target_remaining := 0
var _mission_label := ""
var _wave_count := 1
var _current_wave := 1
var _current_wave_end := 0
var _pending_network_snapshot: Dictionary = {}
var _wall_revision := 0
var _last_sent_wall_revision := -1
var _last_applied_wall_revision := -1
var _network_hud_timer := 0.0
var _winner_slot := 0
var _result_is_draw := false
var _result_animation_played := false
var _elimination_text := ""
var _vs_cache_timer := VS_CACHE_FIRST_DELAY
var _vs_cache_wave := 0
var _vs_center_timer := VS_CENTER_FIRST_DELAY
var _vs_center_wave := 0
var _rematch_ready_slots: Dictionary = {}
var _rematch_transition_started := false
var _hit_event_sequence := 0
var _last_hit_event: Dictionary = {}
var _hit_event_lifetime := 0.0
var _last_applied_hit_event_sequence := 0


func _ready() -> void:
	set_process_input(true)
	_configure_capture_request()
	if _capture_stage_index >= 0:
		GameSession.selected_stage_index = clampi(_capture_stage_index, 0, GameSession.get_stage_count() - 1)
		GameSession.unlocked_stage_count = GameSession.get_stage_count()

	_rng.randomize()
	_session_mode = "solo" if _capture_requested else GameSession.get_session_mode()
	_player_count = 1 if _capture_requested else (2 if _is_online_mode() else 1)
	_local_player_slot = 1 if not _is_online_mode() else NetSession.get_local_slot()
	_local_control_count = 1
	_stage_data = GameSession.get_selected_stage()
	_theme_palette = STAGE_CATALOG.get_theme(_stage_data.get("theme", "dust"))
	_combat_balance = _build_combat_balance()
	_player_spawn_cells = _build_player_spawn_cells()
	_enemy_queue = _build_enemy_queue()
	_total_enemies = _enemy_queue.size()
	_configure_waves()
	_setup_stage_objective()
	_build_arena()
	_configure_players()
	_configure_camera()
	_configure_mobile_controls()
	_connect_scene_signals()
	_apply_black_cat_theme()
	_install_game_feel_ui()
	_install_pause_input_proxy()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_resume_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_menu_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_analog_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_buttons_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_overlay.visible = false
	_update_wait_state(_is_online_mode() and not _capture_requested and not NetSession.is_peer_connected())
	_update_hud()
	_start_onboarding_if_needed()
	_refresh_pause_button_visibility()
	alert_label.visible = false
	queue_redraw()

	if _is_online_mode() and not _capture_requested:
		NetSession.peer_status_changed.connect(_on_online_peer_status_changed)
		NetSession.snapshot_updated.connect(_on_online_snapshot_updated)
		NetSession.profiles_updated.connect(_on_online_profiles_updated)
		NetSession.rematch_status_updated.connect(_on_online_rematch_status_updated)
		if _is_authority():
			if not _waiting_for_peer and not _is_vs_mode():
				spawn_timer.start(_scaled_spawn_delay(1.0))
		else:
			spawn_timer.stop()
			_show_alert("Online oda baglandi. Host snapshot bekleniyor.", _get_theme_color("hud_accent", Color("#f2d48f")))
	else:
		if not _is_vs_mode():
			spawn_timer.start(_scaled_spawn_delay(0.25 if _capture_requested else _get_initial_spawn_delay()))
		if not _capture_requested:
			_show_alert(_build_start_alert_text(), _get_theme_color("hud_accent", Color("#f2d48f")))

	if _capture_requested:
		if mobile_controls:
			mobile_controls.visible = false
		call_deferred("_capture_store_frame")


func _exit_tree() -> void:
	if _is_online_mode():
		if NetSession.peer_status_changed.is_connected(_on_online_peer_status_changed):
			NetSession.peer_status_changed.disconnect(_on_online_peer_status_changed)
		if NetSession.snapshot_updated.is_connected(_on_online_snapshot_updated):
			NetSession.snapshot_updated.disconnect(_on_online_snapshot_updated)
		if NetSession.profiles_updated.is_connected(_on_online_profiles_updated):
			NetSession.profiles_updated.disconnect(_on_online_profiles_updated)
		if NetSession.rematch_status_updated.is_connected(_on_online_rematch_status_updated):
			NetSession.rematch_status_updated.disconnect(_on_online_rematch_status_updated)


func _process(delta: float) -> void:
	_update_shield_hud(delta)
	if _is_online_mode():
		_network_hud_timer = maxf(_network_hud_timer - delta, 0.0)
		if _network_hud_timer <= 0.0:
			_network_hud_timer = 0.5
			_update_network_info_label()
			if _is_vs_mode():
				stats_label.text = _build_stats_summary()
	if _alert_time > 0.0:
		_alert_time = max(_alert_time - delta, 0.0)
		var alpha: float = 0.38 + 0.62 * minf(_alert_time / 2.4, 1.0)
		var tint := _alert_color
		tint.a = alpha
		alert_label.modulate = tint
		if _alert_time <= 0.0:
			alert_label.visible = false

	power_label.text = "Destek: " + _build_power_summary()



func _physics_process(delta: float) -> void:
	_hit_event_lifetime = maxf(_hit_event_lifetime - delta, 0.0)
	if _capture_requested or not _is_online_mode() or _match_over:
		return

	if _is_authority():
		_apply_remote_player_input()
		if _waiting_for_peer or not NetSession.is_peer_connected():
			return
		_tick_vs_center_cache(delta)
		_tick_vs_corner_caches(delta)
		_snapshot_send_timer = max(_snapshot_send_timer - delta, 0.0)
		if _snapshot_send_timer <= 0.0:
			_snapshot_send_timer = SNAPSHOT_INTERVAL
			NetSession.send_snapshot(_build_world_snapshot())
		return

	if not _pending_network_snapshot.is_empty():
		_apply_world_snapshot(_pending_network_snapshot)
		_pending_network_snapshot.clear()

	var local_player = _get_local_player()
	if local_player == null:
		return
	_input_send_timer = max(_input_send_timer - delta, 0.0)
	if _input_send_timer <= 0.0:
		_input_send_timer = INPUT_SEND_INTERVAL
		NetSession.send_input(local_player.capture_local_input_state())


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var touch_position: Vector2 = event.position

		if result_overlay.visible:
			if next_stage_button.visible and next_stage_button.get_global_rect().has_point(touch_position):
				_go_to_next_stage()
				return
			if retry_button.get_global_rect().has_point(touch_position):
				_on_retry_requested()
				return
			if menu_button.get_global_rect().has_point(touch_position):
				_go_to_main_menu()
				return

		if _handle_pause_overlay_input(event):
			return

		if pause_button.visible and pause_button.get_global_rect().has_point(touch_position):
			_on_pause_button_pressed()
			return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and not _match_over and not _capture_requested and not _is_online_mode():
			_toggle_pause_menu()
			return

		if _match_over:
			if event.keycode == KEY_R:
				_on_retry_requested()
				return
			if event.keycode == KEY_N and next_stage_button.visible:
				_go_to_next_stage()
				return

		if event.keycode == KEY_ESCAPE:
			_go_to_main_menu()


func _draw() -> void:
	var background_top := _get_theme_color("background_top", Color("#161d26"))
	var background_bottom := _get_theme_color("background_bottom", Color("#0e1319"))
	var grid_color := _get_theme_color("grid", Color(1, 1, 1, 0.05))

	for band_index in range(12):
		var weight := float(band_index) / 11.0
		var band_color := background_top.lerp(background_bottom, weight)
		draw_rect(Rect2(Vector2(0.0, band_index * 60.0), Vector2(1280.0, 64.0)), band_color)

	for x in range(GRID_SIZE.x + 1):
		var px := GRID_OFFSET.x + float(x) * CELL_SIZE
		draw_line(Vector2(px, 0.0), Vector2(px, 720.0), grid_color, 1.0)

	for y in range(GRID_SIZE.y + 1):
		var py := GRID_OFFSET.y + float(y) * CELL_SIZE
		draw_line(Vector2(GRID_OFFSET.x, py), Vector2(GRID_OFFSET.x + CELL_SIZE * GRID_SIZE.x, py), grid_color, 1.0)

	if _is_vs_mode():
		var center_fill := Color("#b98cff1f")
		var center_ring := Color("#d7b4ffaa")
		draw_circle(VS_CENTER_POSITION, 36.0, center_fill, true, -1.0, true)
		draw_arc(VS_CENTER_POSITION, 37.0, 0.0, TAU, 40, center_ring, 2.5, true)
		draw_line(VS_CENTER_POSITION + Vector2(-17.0, 0.0), VS_CENTER_POSITION + Vector2(17.0, 0.0), center_ring, 1.5, true)
		draw_line(VS_CENTER_POSITION + Vector2(0.0, -17.0), VS_CENTER_POSITION + Vector2(0.0, 17.0), center_ring, 1.5, true)
		for cache_cell in VS_CACHE_CELLS:
			var cache_position := _cell_to_world(cache_cell)
			var cache_fill := Color("#f3c86818")
			var cache_ring := Color("#f3c86888")
			draw_circle(cache_position, 30.0, cache_fill, true, -1.0, true)
			draw_arc(cache_position, 31.0, 0.0, TAU, 36, cache_ring, 2.0, true)
			draw_arc(cache_position, 23.0, -PI * 0.75, PI * 0.25, 24, cache_ring.lightened(0.18), 1.5, true)


func get_active_player_targets() -> Array:
	var active_players := []
	for slot in range(1, _player_count + 1):
		var player_node = _get_player_by_slot(slot)
		if is_instance_valid(player_node):
			active_players.append(player_node)
	return active_players


func _build_arena() -> void:
	for child in get_children():
		if child is StaticBody2D and child.name.begins_with("Wall"):
			child.queue_free()
		elif child.is_in_group("pickups"):
			child.queue_free()

	_spawn_border()
	_spawn_stage_layout()
	if _stage_has_core():
		_spawn_base_fort()


func _configure_players() -> void:
	_players_by_slot.clear()
	player_template.name = "PlayerTank1"

	for slot in range(1, _player_count + 1):
		var player_node = player_template if slot == 1 else PLAYER_TANK_SCENE.instantiate()
		var player_profile := _build_player_profile(slot)
		player_profile["team"] = "player_%d" % slot if _is_vs_mode() else "player"
		player_profile["max_health_bonus"] = int(_combat_balance.get("player_bonus_health", 0))
		player_profile["spawn_shield_duration"] = float(_combat_balance.get("spawn_shield_duration", 0.0))
		player_profile["fire_cooldown_scale"] = float(_combat_balance.get("player_fire_scale", 1.0))
		if slot > 1:
			player_node.name = "PlayerTank%d" % slot
			add_child(player_node)

		player_node.position = _cell_to_world(_player_spawn_cells[slot - 1])
		player_node.rotation = 0.0
		player_node.reset_physics_interpolation()
		player_node.configure_player(player_profile)
		player_node.set_mobile_controls(mobile_controls)
		player_node.destroyed.connect(_on_player_destroyed.bind(slot))
		player_node.health_changed.connect(_on_player_health_changed.bind(slot))

		if _is_online_mode() and not _capture_requested:
			if slot == _local_player_slot:
				player_node.set_control_mode("local")
				player_node.set_spawn_bullets_enabled(_is_authority())
			elif _is_authority():
				player_node.set_control_mode("network_input")
				player_node.set_spawn_bullets_enabled(true)
			else:
				player_node.set_control_mode("replica")
				player_node.set_spawn_bullets_enabled(false)
		else:
			player_node.set_control_mode("local")
			player_node.set_spawn_bullets_enabled(true)

		_players_by_slot[slot] = player_node


func _build_player_profile(slot: int) -> Dictionary:
	var profile := Dictionary(PLAYER_PROFILES[slot].duplicate(true))
	if _is_online_mode() and not _capture_requested:
		profile.merge(NetSession.get_player_profile(slot), true)
	return profile


func _apply_online_player_profiles() -> void:
	if not _is_online_mode():
		return
	for slot in range(1, _player_count + 1):
		var player_node = _get_player_by_slot(slot)
		if is_instance_valid(player_node) and player_node.has_method("apply_cosmetic_profile"):
			player_node.apply_cosmetic_profile(NetSession.get_player_profile(slot))


func _configure_camera() -> void:
	camera.position = Vector2(640.0, 360.0)


func _configure_mobile_controls() -> void:
	if mobile_controls and mobile_controls.has_method("configure_layout"):
		mobile_controls.configure_layout(_local_control_count, _local_player_slot)
	elif mobile_controls and mobile_controls.has_method("configure_player_count"):
		mobile_controls.configure_player_count(_local_control_count)

	if mobile_controls and mobile_controls.has_method("set_control_style"):
		mobile_controls.set_control_style(GameSession.get_control_style())


func _connect_scene_signals() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	next_stage_button.pressed.connect(_go_to_next_stage)
	retry_button.pressed.connect(_on_retry_requested)
	menu_button.pressed.connect(_go_to_main_menu)
	pause_button.pressed.connect(_on_pause_button_pressed)
	pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)
	pause_menu_button.pressed.connect(_on_pause_menu_button_pressed)
	pause_analog_button.pressed.connect(_on_pause_analog_button_pressed)
	pause_buttons_button.pressed.connect(_on_pause_buttons_button_pressed)
	_connect_button_feedback()


func _install_pause_input_proxy() -> void:
	var proxy := PauseInputProxy.new()
	proxy.name = "PauseInputProxy"
	proxy.arena = self
	add_child(proxy)


func _install_game_feel_ui() -> void:
	header_backdrop.visible = false
	header.visible = false
	pause_button.visible = false
	shield_backdrop.visible = false
	shield_hud.visible = false
	header.offset_left = 72.0
	header.offset_top = 54.0
	header.offset_right = 720.0
	header.offset_bottom = 174.0
	pause_button.offset_left = -238.0
	pause_button.offset_top = 54.0
	pause_button.offset_right = -72.0
	pause_button.offset_bottom = 106.0
	shield_hud.offset_left = -372.0
	shield_hud.offset_top = 116.0
	shield_hud.offset_right = -72.0
	shield_hud.offset_bottom = 170.0

	_heart_hud = HeartHud.new()
	_heart_hud.name = "HeartHud"
	_heart_hud.position = Vector2(72.0, 10.0)
	_heart_hud.size = Vector2(220.0, 48.0)
	_heart_hud.z_index = 20
	hud.add_child(_heart_hud)

	_damage_overlay = DamageVignette.new()
	_damage_overlay.name = "DamageVignette"
	_damage_overlay.anchor_right = 1.0
	_damage_overlay.anchor_bottom = 1.0
	_damage_overlay.z_index = 18
	hud.add_child(_damage_overlay)


func _start_onboarding_if_needed() -> void:
	if _capture_requested or _stage_data.get("index", 0) != 0 or _is_online_mode():
		return

	call_deferred("_spawn_onboarding_guide")


func _spawn_onboarding_guide() -> void:
	if not is_instance_valid(mobile_controls) or not is_instance_valid(_get_local_player()):
		return

	var joystick = mobile_controls.get_node_or_null("Root/PlayerOneControls/JoystickShell/JoystickArea")
	var fire_button = mobile_controls.get_node_or_null("Root/PlayerOneControls/FireButton")
	if joystick == null or fire_button == null:
		return

	_onboarding_guide = OnboardingGuide.new()
	_onboarding_guide.name = "OnboardingGuide"
	_onboarding_guide.anchor_right = 1.0
	_onboarding_guide.anchor_bottom = 1.0
	_onboarding_guide.z_index = 19
	hud.add_child(_onboarding_guide)
	_onboarding_guide.configure(joystick.get_global_rect(), fire_button.get_global_rect(), _get_local_player().global_position)


func _connect_button_feedback() -> void:
	for button in [pause_button, next_stage_button, retry_button, menu_button, pause_resume_button, pause_menu_button, pause_analog_button, pause_buttons_button]:
		if button == null:
			continue
		button.pivot_offset = button.size * 0.5
		button.button_down.connect(_animate_hud_button.bind(button, true))
		button.button_up.connect(_animate_hud_button.bind(button, false))


func _animate_hud_button(button: Control, pressed: bool) -> void:
	if not is_instance_valid(button):
		return

	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", Vector2(0.965, 0.965) if pressed else Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _handle_pause_overlay_input(event: InputEvent) -> bool:
	if not pause_overlay.visible:
		return false

	var touch_position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		touch_position = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		touch_position = event.position
		pressed = event.pressed
	else:
		return false

	if not pressed:
		return false

	if pause_analog_button.get_global_rect().has_point(touch_position):
		_on_pause_analog_button_pressed()
		return true
	if pause_buttons_button.get_global_rect().has_point(touch_position):
		_on_pause_buttons_button_pressed()
		return true
	if pause_resume_button.get_global_rect().has_point(touch_position):
		_on_pause_resume_button_pressed()
		return true
	if pause_menu_button.get_global_rect().has_point(touch_position):
		_on_pause_menu_button_pressed()
		return true
	return pause_overlay.get_global_rect().has_point(touch_position)


func _spawn_border() -> void:
	for x in range(GRID_SIZE.x):
		_spawn_wall(Vector2i(x, 0), "steel", 99)
		_spawn_wall(Vector2i(x, GRID_SIZE.y - 1), "steel", 99)

	for y in range(1, GRID_SIZE.y - 1):
		_spawn_wall(Vector2i(0, y), "steel", 99)
		_spawn_wall(Vector2i(GRID_SIZE.x - 1, y), "steel", 99)


func _spawn_stage_layout() -> void:
	var steel_lookup := {}
	for cell in _stage_data.get("steel_cells", []):
		steel_lookup[cell] = true

	for cell in _stage_data.get("brick_cells", []):
		if not _is_reserved_cell(cell) and not steel_lookup.has(cell):
			_spawn_wall(cell, "brick", 1)

	for cell in _stage_data.get("steel_cells", []):
		if not _is_reserved_cell(cell):
			_spawn_wall(cell, "steel", 99)


func _spawn_base_fort() -> void:
	_spawn_wall(Vector2i(12, 12), "base", 5)
	_spawn_wall(Vector2i(11, 12), "fortified", 7)
	_spawn_wall(Vector2i(13, 12), "fortified", 7)
	_spawn_wall(Vector2i(11, 11), "fortified", 7)
	_spawn_wall(Vector2i(12, 11), "fortified", 7)
	_spawn_wall(Vector2i(13, 11), "fortified", 7)


func _spawn_wall(cell: Vector2i, block_type: String, durability: int) -> void:
	var wall = WALL_BLOCK_SCENE.instantiate()
	wall.name = "Wall_%s_%s" % [cell.x, cell.y]
	wall.position = _cell_to_world(cell)
	wall.block_type = block_type
	wall.durability = durability
	if wall.has_method("apply_theme"):
		wall.apply_theme(_theme_palette)
	wall.destroyed.connect(_on_wall_destroyed)
	wall.state_changed.connect(_on_wall_state_changed)
	add_child(wall)


func _on_spawn_timer_timeout() -> void:
	if _match_over or _is_vs_mode() or _spawned_enemies >= _current_wave_end or not _is_authority() or _waiting_for_peer:
		return

	if _alive_enemies >= _get_max_alive_cap():
		spawn_timer.start(_scaled_spawn_delay(0.65))
		return

	var enemy_type := String(_enemy_queue[_spawned_enemies])
	var enemy = ENEMY_TANK_SCENE.instantiate()
	enemy.configure(enemy_type)
	var spawn_position := _choose_enemy_spawn_position(float(enemy.get_tank_collision_radius()))
	if spawn_position.x < 0.0:
		enemy.free()
		spawn_timer.start(_scaled_spawn_delay(0.3))
		return
	enemy.position = spawn_position
	enemy.network_id = _claim_network_id()
	enemy.destroyed.connect(_on_enemy_destroyed)
	add_child(enemy)

	_spawned_enemies += 1
	_alive_enemies += 1
	_status_text = "Catismaya devam"
	_update_hud()

	if _is_boss_enemy_type(enemy_type):
		_show_alert("Boss tank sahaya indi.", Color("#ffb85c"))
	elif _objective_type == "command_hunt" and _is_objective_target(enemy_type):
		_show_alert("Oncelikli hedef sahaya indi.", Color("#ffd97a"))

	if _spawned_enemies < _current_wave_end:
		spawn_timer.start(_scaled_spawn_delay(_rng.randf_range(_stage_data.get("spawn_interval_min", 1.0), _stage_data.get("spawn_interval_max", 1.8))))


func _configure_waves() -> void:
	_current_wave = 1
	if _total_enemies <= 0:
		_wave_count = 1
		_current_wave_end = 0
		return
	_wave_count = clampi(int(_stage_data.get("wave_count", 2)), 1, _total_enemies)
	_current_wave_end = _wave_end_for(_current_wave)


func _wave_end_for(wave_number: int) -> int:
	if _total_enemies <= 0:
		return 0
	return mini(int(ceil(float(_total_enemies) * float(wave_number) / float(_wave_count))), _total_enemies)


func _complete_current_wave() -> void:
	if _current_wave >= _wave_count or _spawned_enemies >= _total_enemies:
		var is_final_stage: bool = _stage_data.get("index", 0) >= _stage_data.get("total_stages", 1) - 1
		var title := "Sektor Temizlendi" if is_final_stage else "Bolum Tamamlandi"
		_finish_match(true, title, "Tum dusman dalgalari imha edildi.")
		return

	var cleared_wave := _current_wave
	_current_wave += 1
	_current_wave_end = _wave_end_for(_current_wave)
	_status_text = "Yeni dalga hazirlaniyor"
	_show_alert("%d. DALGA ATLATILDI" % cleared_wave, Color("#9de6c2"))
	_update_hud()
	spawn_timer.start(_scaled_spawn_delay(WAVE_BREAK_DELAY))


func _choose_enemy_spawn_position(enemy_radius: float) -> Vector2:
	var best_position := Vector2(-1.0, -1.0)
	var best_score := -INF
	var row_offsets := [1, 2, 3] if enemy_radius > 23.0 else [0, 1, 2]
	for base_cell in SPAWN_POINTS:
		for row_offset in row_offsets:
			for column_offset in [0, -1, 1]:
				var cell: Vector2i = Vector2i(base_cell) + Vector2i(int(column_offset), row_offset)
				if cell.x <= 0 or cell.x >= GRID_SIZE.x - 1 or cell.y <= 0 or cell.y >= GRID_SIZE.y - 1:
					continue
				var world_position := _cell_to_world(cell)
				if not _is_enemy_spawn_position_clear(world_position, enemy_radius):
					continue
				var nearest_player_distance := 100000.0
				for player_node in get_active_player_targets():
					nearest_player_distance = minf(nearest_player_distance, world_position.distance_to(player_node.global_position))
				var depth_penalty := float(row_offset) * 18.0
				var score := nearest_player_distance - depth_penalty + _rng.randf_range(0.0, 90.0)
				if score > best_score:
					best_score = score
					best_position = world_position
	return best_position


func _is_enemy_spawn_position_clear(world_position: Vector2, enemy_radius: float) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = enemy_radius + 0.5
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = false
	if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
		return false
	for tank in get_tree().get_nodes_in_group("tanks"):
		if not is_instance_valid(tank):
			continue
		var tank_radius := float(tank.get_tank_collision_radius()) if tank.has_method("get_tank_collision_radius") else 20.0
		if world_position.distance_to(tank.global_position) < enemy_radius + tank_radius + 12.0:
			return false
	return true


func _on_enemy_destroyed(enemy_type: String, at_position: Vector2) -> void:
	if not _is_authority():
		return

	_alive_enemies = max(_alive_enemies - 1, 0)
	_destroyed_enemies += 1
	var objective_cleared := false
	if _is_objective_target(enemy_type) and _objective_target_remaining > 0:
		_objective_target_remaining = max(_objective_target_remaining - 1, 0)
		objective_cleared = _objective_type != "eliminate" and _objective_target_remaining == 0
	_maybe_spawn_pickup(enemy_type, at_position)
	_update_hud()

	if objective_cleared and not _match_over:
		if _objective_type == "boss_hunt":
			_finish_match(true, "Boss Dusuruldu", "Agir komuta tanki sahadan silindi.")
		else:
			_finish_match(true, "Hedefler Temizlendi", "Oncelikli dusman tanklari etkisiz hale getirildi.")
		return

	if _spawned_enemies >= _current_wave_end and _alive_enemies == 0 and not _match_over:
		_complete_current_wave()


func _on_player_destroyed(slot: int) -> void:
	var defeated_player = _get_player_by_slot(slot)
	var defeated_name: String = String(defeated_player.get_callsign()) if is_instance_valid(defeated_player) else _player_name_for_slot(slot)
	_players_by_slot.erase(slot)
	_update_hud()

	var remaining_players := get_active_player_targets()
	if _is_vs_mode():
		if remaining_players.is_empty():
			_winner_slot = 0
			_result_is_draw = true
			_elimination_text = "İki tank da aynı anda hurdaya döndü. Arena yeni raundu bekliyor!"
			_finish_match(false, "Berabere", _elimination_text)
		else:
			var winner = remaining_players[0]
			_winner_slot = int(winner.player_slot)
			_result_is_draw = false
			var winner_name := String(winner.get_callsign())
			_elimination_text = "%s, %s tankı tarafından ezildi!" % [defeated_name, _possessive_name(winner_name)]
			_finish_match(_winner_slot == _local_player_slot, "%s Arenayı Ezdi!" % winner_name, _elimination_text)
		return

	if remaining_players.is_empty():
		_finish_match(false, "Tum Tanklar Dustu", "Birlik tamamen dagildi ve savunma hatti coktu.")
		return

	_show_alert("P%d sahadan dustu. Diger tank savunmaya devam ediyor." % slot, Color("#ff9e8b"))


func _on_player_health_changed(current_health: int, max_health: int, slot: int) -> void:
	var previous_health := int(_last_health_by_slot.get(slot, max_health))
	_last_health_by_slot[slot] = current_health

	if current_health < previous_health:
		if slot == _local_player_slot:
			MobileFeedback.damage()
			if _heart_hud and _heart_hud.has_method("pulse_damage"):
				_heart_hud.pulse_damage()
			if _damage_overlay and _damage_overlay.has_method("flash"):
				_damage_overlay.flash()

	_update_hud()


func _on_wall_destroyed(block_type: String) -> void:
	if not _is_authority():
		return

	if block_type == "base":
		_finish_match(false, "Cekirdek Kaybedildi", "Dusmanlar enerji cekirdegi savunmasini kirdi.")


func _on_wall_state_changed() -> void:
	if _is_authority():
		_wall_revision += 1


func _finish_match(player_won: bool, title: String, subtitle: String) -> void:
	if _match_over:
		return

	if _paused:
		_set_pause_state(false)

	_match_over = true
	var unlocked_new_stage := false
	if player_won and not _is_online_mode() and not _is_vs_mode():
		unlocked_new_stage = GameSession.mark_stage_completed(_stage_data.get("index", 0))
	elif player_won and _is_authority() and not _is_vs_mode():
		unlocked_new_stage = GameSession.mark_stage_completed(_stage_data.get("index", 0))

	spawn_timer.stop()
	result_title.text = title.to_upper()
	result_subtitle.text = _build_result_subtitle(player_won, subtitle, unlocked_new_stage)
	var local_won := player_won
	if _is_vs_mode():
		local_won = _configure_local_vs_result()
	else:
		_status_text = "Zafer" if player_won else "Kayip"
	status_label.text = "Durum: " + _status_text
	result_overlay.visible = true
	next_stage_button.visible = local_won and not _is_vs_mode() and GameSession.has_next_stage()
	_refresh_pause_button_visibility()
	_stop_match_entities()
	_play_result_presentation(local_won, _result_is_draw)
	# The regular network tick stops when the match ends, so deliver the final
	# winner/result frame immediately to ensure the guest sees the animation.
	if _is_online_mode() and _is_authority() and NetSession.is_peer_connected():
		NetSession.send_snapshot(_build_world_snapshot())


func _configure_local_vs_result() -> bool:
	if _result_is_draw or _winner_slot <= 0:
		_status_text = "Berabere"
		result_title.text = "BERABERE"
		result_subtitle.text = _elimination_text if not _elimination_text.is_empty() else "İkiz patlama! Yeni raundda son darbeyi sen vur."
		retry_button.text = "YENI RAUND"
		return false

	var local_won := _winner_slot == _local_player_slot
	if local_won:
		_status_text = "Zafer"
		result_title.text = "%s ZAFERDE!" % _player_name_for_slot(_winner_slot).to_upper()
		result_subtitle.text = _elimination_text
		retry_button.text = "BIR DAHA KAZAN"
	else:
		_status_text = "Kayip"
		result_title.text = "%s ARENAYI ALDI" % _player_name_for_slot(_winner_slot).to_upper()
		result_subtitle.text = _elimination_text
		retry_button.text = "ROVANS AL"
	return local_won


func _player_name_for_slot(slot: int) -> String:
	var player_node = _get_player_by_slot(slot)
	if is_instance_valid(player_node):
		return String(player_node.get_callsign())
	if _is_online_mode():
		return String(NetSession.get_player_profile(slot).get("name", "Oyuncu"))
	return "P%d" % slot


func _possessive_name(player_name: String) -> String:
	var lower := player_name.to_lower()
	var harmony := "in"
	for index in range(lower.length() - 1, -1, -1):
		var character := lower.substr(index, 1)
		if character in ["a", "ı"]:
			harmony = "ın"
			break
		if character in ["e", "i"]:
			harmony = "in"
			break
		if character in ["o", "u"]:
			harmony = "un"
			break
		if character in ["ö", "ü"]:
			harmony = "ün"
			break
	var last_character := lower.right(1)
	var buffer := "n" if last_character in ["a", "e", "ı", "i", "o", "ö", "u", "ü"] else ""
	return "%s'%s%s" % [player_name, buffer, harmony]


func _play_result_presentation(local_won: bool, draw_result: bool) -> void:
	if _result_animation_played:
		return
	_result_animation_played = true
	result_overlay.visible = true
	result_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	result_panel.pivot_offset = result_panel.size * 0.5
	result_title.pivot_offset = result_title.size * 0.5
	result_panel.scale = Vector2(0.58, 0.58) if local_won else Vector2(0.88, 0.88)
	result_title.scale = Vector2(0.72, 0.72)
	retry_button.disabled = true
	menu_button.disabled = true
	next_stage_button.disabled = true

	var accent := BlackCatTheme.ACCENT if local_won else (Color("#aeb9c9") if draw_result else BlackCatTheme.DANGER)
	result_dim.color = Color(0.03, 0.02, 0.01, 0.78) if local_won else Color(0.09, 0.015, 0.025, 0.82)
	result_title.add_theme_color_override("font_color", accent.lightened(0.18))
	result_panel.add_theme_stylebox_override("panel", BlackCatTheme.make_panel_style(BlackCatTheme.SURFACE_ALT, accent, 30, 3))
	if result_fx and result_fx.has_method("play_result"):
		result_fx.play_result(local_won, draw_result)

	var entrance := create_tween().set_parallel(true)
	entrance.set_trans(Tween.TRANS_BACK if local_won else Tween.TRANS_QUAD)
	entrance.set_ease(Tween.EASE_OUT)
	entrance.tween_property(result_overlay, "modulate:a", 1.0, 0.32)
	entrance.tween_property(result_panel, "scale", Vector2.ONE, 0.62 if local_won else 0.42)
	entrance.tween_property(result_title, "scale", Vector2.ONE, 0.5)

	var title_pulse := create_tween()
	title_pulse.tween_interval(0.42)
	title_pulse.tween_property(result_title, "scale", Vector2(1.08, 1.08), 0.2)
	title_pulse.tween_property(result_title, "scale", Vector2.ONE, 0.22)
	if local_won:
		title_pulse.set_loops(3)
	elif not draw_result:
		var defeat_shake := create_tween()
		defeat_shake.tween_interval(0.18)
		for angle in [0.025, -0.02, 0.014, -0.008, 0.0]:
			defeat_shake.tween_property(result_panel, "rotation", angle, 0.07)

	var unlock_buttons := create_tween()
	unlock_buttons.tween_interval(0.7)
	unlock_buttons.tween_callback(func():
		retry_button.disabled = false
		menu_button.disabled = false
		next_stage_button.disabled = false
	)


func _stop_match_entities() -> void:
	if mobile_controls and mobile_controls.has_method("set_controls_enabled"):
		mobile_controls.set_controls_enabled(false)
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.queue_free()
	for pickup in get_tree().get_nodes_in_group("pickups"):
		pickup.queue_free()
	for player_node in _players_by_slot.values():
		if is_instance_valid(player_node):
			player_node.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemy_tanks"):
		enemy.set_physics_process(false)


func _update_hud() -> void:
	_update_network_info_label()
	brief_label.text = _build_stage_brief()
	status_label.text = "Durum %s | Dusman %d" % [_status_text, _alive_enemies]
	stats_label.text = _build_stats_summary()
	wave_label.text = _build_wave_progress_text()
	power_label.text = "Destek " + _build_power_summary()

	var local_player = _get_local_player()
	if _heart_hud and is_instance_valid(local_player) and _heart_hud.has_method("set_health"):
		_heart_hud.set_health(int(local_player.health), int(local_player.get_max_health()))
		_last_health_by_slot[_local_player_slot] = int(local_player.health)


func _update_network_info_label() -> void:
	var network_suffix := ""
	if _is_online_mode():
		network_suffix = " | %s" % NetSession.get_network_quality_text()
	info_label.text = "S%02d | %s | %s%s" % [_stage_data.get("number", 1), _stage_data.get("name", "Arena"), _get_mode_label(), network_suffix]


func _update_shield_hud(delta: float) -> void:
	var local_player = _get_local_player()
	var remaining := 0.0
	var ratio := 0.0
	if is_instance_valid(local_player) and local_player.has_method("get_shield_remaining"):
		remaining = float(local_player.get_shield_remaining())
		ratio = float(local_player.get_shield_ratio())

	shield_bar.value = lerpf(float(shield_bar.value), ratio, minf(delta * 10.0, 1.0))
	shield_label.text = "KALKAN  %.1f sn" % remaining
	shield_hud.visible = false
	shield_backdrop.visible = false


func _on_retry_requested() -> void:
	if retry_button.disabled or _rematch_transition_started:
		return
	if not (_is_online_mode() and _is_vs_mode()):
		_restart_level()
		return
	if not _match_over:
		return
	if not NetSession.is_peer_connected():
		result_subtitle.text = "Rakip bağlı değil. Rövanş için iki oyuncu da odada olmalı."
		return
	if _rematch_ready_slots.has(_local_player_slot):
		return
	_rematch_ready_slots[_local_player_slot] = true
	_update_rematch_ui()
	NetSession.send_rematch_vote(true)


func _on_online_rematch_status_updated(ready_slots: Array, start: bool, _round_id: int) -> void:
	if not (_is_vs_mode() and _match_over) or _rematch_transition_started:
		return
	_rematch_ready_slots.clear()
	for slot_value in ready_slots:
		var slot := int(slot_value)
		if slot in [1, 2]:
			_rematch_ready_slots[slot] = true
	_update_rematch_ui()
	if start and _rematch_ready_slots.size() == 2:
		_begin_synchronized_rematch()


func _update_rematch_ui() -> void:
	if not (_is_vs_mode() and _match_over):
		return
	var ready_count := _rematch_ready_slots.size()
	var local_ready := _rematch_ready_slots.has(_local_player_slot)
	var remote_slot := 2 if _local_player_slot == 1 else 1
	var remote_ready := _rematch_ready_slots.has(remote_slot)
	if ready_count >= 2:
		result_subtitle.text = "Rövanş onayı 2/2 • Yeni raund başlıyor..."
		retry_button.text = "RAUND BAŞLIYOR"
		retry_button.disabled = true
	elif local_ready:
		result_subtitle.text = "Rövanş onayı 1/2 • Rakibin onayı bekleniyor."
		retry_button.text = "ONAY VERİLDİ • BEKLENİYOR"
		retry_button.disabled = true
	elif remote_ready:
		result_subtitle.text = "Rakip rövanşa hazır • Başlamak için sen de onayla."
		retry_button.text = "RÖVANŞI ONAYLA"
		retry_button.disabled = false


func _begin_synchronized_rematch() -> void:
	if _rematch_transition_started:
		return
	_rematch_transition_started = true
	retry_button.disabled = true
	retry_button.text = "RAUND BAŞLIYOR"
	result_subtitle.text = "Rövanş onayı 2/2 • Yeni raund başlıyor..."
	NetSession.clear_match_buffers()
	call_deferred("_change_to_arena")


func _change_to_arena() -> void:
	get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _restart_level() -> void:
	if _paused:
		_set_pause_state(false)
	get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _go_to_next_stage() -> void:
	if _paused:
		_set_pause_state(false)
	if GameSession.advance_to_next_stage():
		get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _go_to_main_menu() -> void:
	if _paused:
		_set_pause_state(false)
	if _is_online_mode():
		NetSession.disconnect_session()
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")


func _on_pause_button_pressed() -> void:
	_toggle_pause_menu()


func _on_pause_resume_button_pressed() -> void:
	_set_pause_state(false)


func _on_pause_menu_button_pressed() -> void:
	_set_pause_state(false)
	_go_to_main_menu()


func _on_pause_analog_button_pressed() -> void:
	_set_control_style("analog")


func _on_pause_buttons_button_pressed() -> void:
	_set_control_style("buttons")


func _toggle_pause_menu() -> void:
	if _match_over or _capture_requested or _is_online_mode():
		return

	_set_pause_state(not _paused)


func _set_pause_state(paused: bool) -> void:
	_paused = paused
	pause_overlay.visible = paused
	get_tree().paused = paused

	if mobile_controls and mobile_controls.has_method("set_controls_enabled"):
		mobile_controls.set_controls_enabled(not paused and not _match_over)

	_refresh_pause_overlay()
	_refresh_pause_button_visibility()


func _set_control_style(style: String) -> void:
	GameSession.set_control_style("analog")
	if mobile_controls and mobile_controls.has_method("set_control_style"):
		mobile_controls.set_control_style("analog")
	_refresh_pause_overlay()


func _refresh_pause_overlay() -> void:
	pause_control_label.visible = false
	pause_control_row.visible = false
	pause_analog_button.disabled = true
	pause_buttons_button.disabled = true


func _refresh_pause_button_visibility() -> void:
	pause_button.visible = false


func _apply_black_cat_theme() -> void:
	info_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT_SOFT)
	brief_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	status_label.add_theme_color_override("font_color", BlackCatTheme.TEXT)
	stats_label.add_theme_color_override("font_color", BlackCatTheme.TEXT)
	wave_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	power_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT)
	alert_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT_SOFT)
	for label in [info_label, brief_label, status_label, stats_label, wave_label, power_label, alert_label, shield_label]:
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
	shield_label.add_theme_color_override("font_color", Color("#bfeaff"))
	shield_bar.add_theme_stylebox_override("background", BlackCatTheme.make_panel_style(Color("#111a21"), Color("#38576a"), 4, 1))
	shield_bar.add_theme_stylebox_override("fill", BlackCatTheme.make_panel_style(Color("#72c9f4"), Color("#c5efff"), 4, 1))
	result_title.add_theme_color_override("font_color", BlackCatTheme.ACCENT_SOFT)
	result_subtitle.add_theme_color_override("font_color", BlackCatTheme.TEXT)
	result_panel.add_theme_stylebox_override("panel", BlackCatTheme.make_panel_style(BlackCatTheme.SURFACE_ALT, BlackCatTheme.border_mix(BlackCatTheme.SURFACE_ALT, BlackCatTheme.ACCENT, 0.24), 30, 2))
	pause_panel.add_theme_stylebox_override("panel", BlackCatTheme.make_panel_style(BlackCatTheme.SURFACE_ALT, BlackCatTheme.border_mix(BlackCatTheme.SURFACE_ALT, BlackCatTheme.ACCENT, 0.24), 28, 2))
	BlackCatTheme.apply_button(pause_button, BlackCatTheme.ACCENT, BlackCatTheme.SURFACE)
	BlackCatTheme.apply_button(next_stage_button, BlackCatTheme.ACCENT, BlackCatTheme.SURFACE)
	BlackCatTheme.apply_button(retry_button, BlackCatTheme.ACCENT_SOFT, BlackCatTheme.SURFACE)
	BlackCatTheme.apply_button(menu_button, BlackCatTheme.border_mix(BlackCatTheme.ACCENT, BlackCatTheme.TEXT, 0.12), BlackCatTheme.SURFACE)
	BlackCatTheme.apply_button(pause_resume_button, BlackCatTheme.ACCENT, BlackCatTheme.SURFACE)
	BlackCatTheme.apply_button(pause_menu_button, BlackCatTheme.border_mix(BlackCatTheme.ACCENT, BlackCatTheme.TEXT, 0.12), BlackCatTheme.SURFACE)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(cell.x, cell.y) * CELL_SIZE + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)


func _is_reserved_cell(cell: Vector2i) -> bool:
	if (_stage_has_core() and BASE_RESERVED_CELLS.has(cell)) or SPAWN_POINTS.has(cell):
		return true
	if _is_vs_mode():
		for cache_cell in VS_CACHE_CELLS:
			if absi(cell.x - cache_cell.x) <= 1 and absi(cell.y - cache_cell.y) <= 1:
				return true
		for center_cell in VS_CENTER_RESERVED_CELLS:
			if absi(cell.x - center_cell.x) <= 1 and absi(cell.y - center_cell.y) <= 1:
				return true

	for spawn_cell in _player_spawn_cells:
		if absi(cell.x - spawn_cell.x) <= 1 and absi(cell.y - spawn_cell.y) <= 1:
			return true

	return false


func _build_result_subtitle(player_won: bool, subtitle: String, unlocked_new_stage: bool) -> String:
	if _is_vs_mode():
		return subtitle
	if not player_won:
		return subtitle + " R ile tekrar dene."

	if GameSession.has_next_stage():
		var next_stage: Dictionary = GameSession.get_stage(GameSession.selected_stage_index + 1)
		var unlocked_note := " Yeni stage acildi." if unlocked_new_stage else ""
		return subtitle + unlocked_note + " Sonraki hedef: %s. N ile gec." % next_stage["name"]

	return subtitle + " Tum campaign temizlendi."


func notify_enemy_destroyed_visual(at_position: Vector2, enemy_type: String) -> void:
	var burst = IMPACT_BURST_SCENE.instantiate()
	burst.global_position = at_position

	if enemy_type == "scout":
		burst.color = Color("#8bd3ff")
	elif enemy_type == "brute":
		burst.color = Color("#ffb066")
	elif enemy_type == "sniper":
		burst.color = Color("#ccb8ff")
	elif enemy_type == "volley":
		burst.color = Color("#ff8f8f")
	elif enemy_type == "warden":
		burst.color = Color("#d7c38b")
	elif _is_boss_enemy_type(enemy_type):
		burst.color = Color("#ffb85c")
	else:
		burst.color = Color("#ffd166")

	_queue_runtime_child(burst)

	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.16, 4.0)


func notify_player_hit_visual(at_position: Vector2) -> void:
	var burst = IMPACT_BURST_SCENE.instantiate()
	burst.global_position = at_position
	burst.color = Color("#ff7b72")
	_queue_runtime_child(burst)

	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.1, 2.8)


func notify_tank_hit_result(at_position: Vector2, source_team: String, target_team: String, damage: int, applied: bool, destroyed: bool) -> void:
	if not _is_authority():
		return
	_hit_event_sequence += 1
	_last_hit_event = {
		"sequence": _hit_event_sequence,
		"x": at_position.x,
		"y": at_position.y,
		"source_team": source_team,
		"target_team": target_team,
		"damage": maxi(damage, 1),
		"applied": applied,
		"destroyed": destroyed
	}
	_hit_event_lifetime = 0.45
	_present_hit_event(_last_hit_event)
	# Send immediately instead of waiting for the 20 Hz world tick. This keeps
	# hit feedback crisp and also delivers the final IMHA event after match end.
	if _is_online_mode() and NetSession.is_peer_connected():
		NetSession.send_snapshot(_build_world_snapshot())


func _present_hit_event(hit_event: Dictionary) -> void:
	if hit_event.is_empty():
		return
	var sequence := int(hit_event.get("sequence", 0))
	if sequence <= _last_applied_hit_event_sequence:
		return
	_last_applied_hit_event_sequence = sequence
	var local_team := "player_%d" % _local_player_slot if _is_vs_mode() else "player"
	var source_team := String(hit_event.get("source_team", ""))
	var target_team := String(hit_event.get("target_team", ""))
	var local_scored := source_team == local_team
	var local_was_hit := target_team == local_team
	if not local_scored and not local_was_hit:
		return
	var at_position := Vector2(float(hit_event.get("x", 0.0)), float(hit_event.get("y", 0.0)))
	var applied := bool(hit_event.get("applied", false))
	_spawn_hit_confirmation(at_position, local_scored, int(hit_event.get("damage", 1)), bool(hit_event.get("destroyed", false)), not applied)
	if local_scored:
		MobileFeedback.confirmed_hit()


func _spawn_hit_confirmation(at_position: Vector2, local_scored: bool, damage: int, destroyed: bool = false, blocked: bool = false) -> void:
	var confirmation = HitConfirmation.new()
	confirmation.global_position = at_position
	confirmation.configure(local_scored, damage, destroyed, blocked)
	_queue_runtime_child(confirmation)
	if local_scored and camera and camera.has_method("add_shake"):
		camera.add_shake(0.055, 1.5)


func _configure_capture_request() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-output="):
			_capture_requested = true
			_capture_output_path = argument.trim_prefix("--capture-output=")
		elif argument.begins_with("--capture-stage="):
			var requested_stage := maxi(int(argument.trim_prefix("--capture-stage=")), 1)
			_capture_stage_index = requested_stage - 1
		elif argument.begins_with("--capture-delay-frames="):
			_capture_delay_frames = maxi(int(argument.trim_prefix("--capture-delay-frames=")), 45)
		elif argument.begins_with("--capture-size="):
			var dimensions := argument.trim_prefix("--capture-size=").to_lower().split("x", false, 2)
			if dimensions.size() == 2:
				_capture_size = Vector2i(maxi(int(dimensions[0]), 320), maxi(int(dimensions[1]), 180))

	if _capture_requested and _capture_output_path.is_empty():
		_capture_output_path = OS.get_user_data_dir().path_join("aksoy-tank-capture.png")


func _capture_store_frame() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_output_path.get_base_dir())
	for _frame in range(_capture_delay_frames):
		await get_tree().process_frame

	var image := get_viewport().get_texture().get_image()
	if _capture_size.x > 0 and _capture_size.y > 0 and image.get_size() != _capture_size:
		image.resize(_capture_size.x, _capture_size.y, Image.INTERPOLATE_LANCZOS)
	if image.get_format() != Image.FORMAT_RGB8:
		image.convert(Image.FORMAT_RGB8)
	var result := image.save_png(_capture_output_path)
	if result != OK:
		push_error("Store capture could not be saved: %s" % _capture_output_path)

	get_tree().quit()


func _maybe_spawn_pickup(enemy_type: String, at_position: Vector2) -> void:
	var drop_chance := 0.14
	if _is_boss_enemy_type(enemy_type):
		drop_chance = 1.0
	else:
		match enemy_type:
			"scout":
				drop_chance = 0.2
			"volley":
				drop_chance = 0.24
			"brute":
				drop_chance = 0.34
			"sniper":
				drop_chance = 0.26
			"warden":
				drop_chance = 0.42

	if _destroyed_enemies % 6 == 0:
		drop_chance = 1.0

	if _get_lowest_player_health() <= 1:
		drop_chance = maxf(drop_chance, 0.62)

	drop_chance += float(_combat_balance.get("pickup_drop_bonus", 0.0))

	if _rng.randf() > minf(drop_chance, 1.0):
		return

	var pickup = PICKUP_SCENE.instantiate()
	pickup.global_position = at_position
	pickup.network_id = _claim_network_id()
	pickup.configure(_roll_pickup_type(enemy_type))
	pickup.collected.connect(_on_pickup_collected)
	_queue_runtime_child(pickup)


func _tick_vs_corner_caches(delta: float) -> void:
	if not _is_vs_mode() or _vs_cache_wave >= VS_CACHE_MAX_WAVES:
		return
	_vs_cache_timer = maxf(_vs_cache_timer - delta, 0.0)
	if _vs_cache_timer > 0.0:
		return
	_spawn_vs_corner_caches()
	_vs_cache_timer = VS_CACHE_REPEAT_DELAY


func _spawn_vs_corner_caches() -> void:
	if not _is_vs_mode() or _vs_cache_wave >= VS_CACHE_MAX_WAVES:
		return
	var pickup_type := "turbo" if _vs_cache_wave == 0 else "overdrive"
	for cache_cell in VS_CACHE_CELLS:
		var pickup = PICKUP_SCENE.instantiate()
		pickup.global_position = _cell_to_world(cache_cell)
		pickup.network_id = _claim_network_id()
		pickup.lifetime = VS_CACHE_LIFETIME
		pickup.configure(pickup_type)
		pickup.collected.connect(_on_pickup_collected)
		_queue_runtime_child(pickup)
	_vs_cache_wave += 1
	var cache_label := "Turbo Palet" if pickup_type == "turbo" else "Overdrive"
	_show_alert("Köşe destekleri açıldı: %s. Risk al, üstünlüğü kap!" % cache_label, Color("#f3c868"))


func _tick_vs_center_cache(delta: float) -> void:
	if not _is_vs_mode() or _vs_center_wave >= VS_CENTER_MAX_WAVES:
		return
	_vs_center_timer = maxf(_vs_center_timer - delta, 0.0)
	if _vs_center_timer > 0.0:
		return
	_spawn_vs_center_cache()
	_vs_center_timer = VS_CENTER_REPEAT_DELAY


func _spawn_vs_center_cache() -> void:
	if not _is_vs_mode() or _vs_center_wave >= VS_CENTER_MAX_WAVES or _has_active_pickup_type("tactical"):
		return
	var pickup = PICKUP_SCENE.instantiate()
	pickup.global_position = VS_CENTER_POSITION
	pickup.network_id = _claim_network_id()
	pickup.lifetime = VS_CENTER_LIFETIME
	pickup.configure("tactical")
	pickup.collected.connect(_on_pickup_collected)
	_queue_runtime_child(pickup)
	_vs_center_wave += 1
	_show_alert("Merkez çekirdeği açıldı. Alana koşmak hızlıdır ama açık hedef olursun!", Color("#d7b4ff"))


func _has_active_pickup_type(pickup_type: String) -> bool:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if String(pickup.pickup_type) == pickup_type:
			return true
	return false


func _has_active_corner_cache() -> bool:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if String(pickup.pickup_type) in ["turbo", "overdrive"]:
			return true
	return false


func _roll_pickup_type(enemy_type: String) -> String:
	var options: Array[String] = []
	var lowest_player_hp := _get_lowest_player_health()

	if lowest_player_hp <= 1:
		options.append("repair")
		options.append("repair")
		options.append("shield")

	if _is_boss_enemy_type(enemy_type):
		options.append("fortify")
		options.append("shield")
		options.append("overdrive")
		options.append("repair")
	else:
		match enemy_type:
			"grunt":
				options.append("repair")
				options.append("turbo")
			"scout":
				options.append("turbo")
				options.append("overdrive")
				options.append("repair")
			"volley":
				options.append("overdrive")
				options.append("turbo")
				options.append("repair")
			"brute":
				options.append("shield")
				options.append("fortify")
				options.append("repair")
			"sniper":
				options.append("overdrive")
				options.append("shield")
				options.append("turbo")
			"warden":
				options.append("shield")
				options.append("fortify")
				options.append("overdrive")

	if _destroyed_enemies >= 5 and _destroyed_enemies % 5 == 0:
		options.append("fortify")

	if options.is_empty():
		options.append("repair")

	return options[_rng.randi_range(0, options.size() - 1)]


func _on_pickup_collected(pickup_type: String, at_position: Vector2, collector: Node) -> void:
	if not _is_authority():
		return

	var owner_name := "Ortak"
	var result := {
		"title": "Destek Paketi",
		"detail": "Saha avantaji toplandi.",
		"tint": _get_theme_color("hud_accent", Color("#f2d48f"))
	}

	if pickup_type == "fortify" and _stage_has_core():
		_reinforce_base_fort()
		result["title"] = "Cekirdek Tahkimi"
		result["detail"] = "Cekirdek cevresi 7 vurusluk zirhla yenilendi."
		result["tint"] = Color("#ffd97a")
	else:
		var target_player = collector if is_instance_valid(collector) else _get_local_player()
		if target_player == null:
			return
		var applied_type := "shield" if pickup_type == "fortify" else pickup_type
		result = target_player.apply_powerup(applied_type)
		owner_name = target_player.get_callsign() if target_player.has_method("get_callsign") else owner_name

	_spawn_pickup_burst(at_position, result["tint"])
	MobileFeedback.reward()
	_show_alert("%s | %s: %s" % [result["title"], owner_name, result["detail"]], result["tint"])
	_update_hud()


func _reinforce_base_fort() -> void:
	if not _stage_has_core():
		return
	_ensure_wall(Vector2i(12, 12), "base", 5)
	_ensure_wall(Vector2i(11, 12), "fortified", 7)
	_ensure_wall(Vector2i(13, 12), "fortified", 7)
	_ensure_wall(Vector2i(11, 11), "fortified", 7)
	_ensure_wall(Vector2i(12, 11), "fortified", 7)
	_ensure_wall(Vector2i(13, 11), "fortified", 7)


func _ensure_wall(cell: Vector2i, block_type: String, durability: int) -> void:
	var node_name := "Wall_%s_%s" % [cell.x, cell.y]
	var existing: Node = get_node_or_null(NodePath(node_name))

	if existing:
		if String(existing.get("block_type")) == block_type and int(existing.get("durability")) >= durability:
			return
		existing.name = existing.name + "_old"
		existing.queue_free()

	_spawn_wall(cell, block_type, durability)


func _spawn_pickup_burst(at_position: Vector2, tint: Color) -> void:
	var burst = IMPACT_BURST_SCENE.instantiate()
	burst.global_position = at_position
	burst.color = tint
	_queue_runtime_child(burst)

	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.08, 2.0)


func _show_alert(text: String, tint: Color) -> void:
	alert_label.text = text
	_alert_color = tint
	alert_label.modulate = tint
	alert_label.visible = true
	_alert_time = 2.4
	alert_label.pivot_offset = alert_label.size * 0.5
	alert_label.scale = Vector2(0.97, 0.97)
	var tween := create_tween()
	tween.tween_property(alert_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _get_theme_color(key: String, fallback: Color) -> Color:
	if _theme_palette.has(key):
		return _theme_palette[key]
	return fallback


func _setup_stage_objective() -> void:
	_objective_type = String(_stage_data.get("objective_type", "eliminate"))
	_objective_target_type = String(_stage_data.get("objective_target_type", ""))
	_mission_label = String(_stage_data.get("objective_label", "Tum dusmanlari temizle."))
	_objective_target_total = 0

	if _objective_type != "eliminate" and not _objective_target_type.is_empty():
		for enemy_type in _enemy_queue:
			if _is_objective_target(String(enemy_type)):
				_objective_target_total += 1

	if _objective_type != "eliminate" and _objective_target_total <= 0:
		_objective_type = "eliminate"
		_objective_target_type = ""
		_mission_label = "Tum dusmanlari temizle."

	_objective_target_remaining = _objective_target_total


func _build_start_alert_text() -> String:
	if _is_vs_mode():
		return "Rakip tanki etkisiz hale getir."
	if _objective_type == "command_hunt" or _objective_type == "boss_hunt":
		return _mission_label
	if _stage_has_core():
		return "Cekirdegi koru ve dusman dalgalarini temizle."
	return "Dusman dalgalarini temizle."


func _is_objective_target(enemy_type: String) -> bool:
	if _objective_target_type == "boss":
		return _is_boss_enemy_type(enemy_type)

	return enemy_type == _objective_target_type


func _is_boss_enemy_type(enemy_type: String) -> bool:
	return enemy_type.begins_with("boss")


func _build_player_spawn_cells() -> Array[Vector2i]:
	var anchor_cell: Vector2i = _stage_data.get("player_cell", Vector2i(12, 13))
	if _player_count <= 1:
		return [anchor_cell]
	if _is_vs_mode():
		return [Vector2i(5, 12), Vector2i(20, 2)]
	return [anchor_cell + Vector2i(-2, 0), anchor_cell + Vector2i(2, 0)]


func _build_enemy_queue() -> Array:
	if _is_vs_mode():
		return []
	var queue: Array = _stage_data.get("enemy_queue", []).duplicate()
	if _player_count <= 1:
		var trim_count := int(_combat_balance.get("queue_trim", 0))
		if trim_count > 0 and queue.size() > 5 and String(_stage_data.get("objective_type", "eliminate")) == "eliminate":
			queue.resize(maxi(queue.size() - trim_count, 5))
		return queue

	var bonus_ratio := float(_combat_balance.get("coop_enemy_bonus_ratio", 0.22))
	var bonus_count := maxi(int(ceil(queue.size() * bonus_ratio)), 2)
	var bonus_pool := ["grunt", "scout", "brute", "sniper"]
	if int(_stage_data.get("number", 1)) >= 31:
		bonus_pool = ["grunt", "scout", "volley", "brute", "sniper", "warden"]
	for bonus_index in range(bonus_count):
		var stage_pressure := clampi(_stage_data.get("index", 0) + bonus_index, 0, bonus_pool.size() - 1)
		var minimum_index := 1 if stage_pressure >= 4 else 0
		var selected_index := _rng.randi_range(minimum_index, mini(stage_pressure + 1, bonus_pool.size() - 1))
		queue.append(bonus_pool[selected_index])
	return queue


func _get_max_alive_cap() -> int:
	var base_cap := int(_stage_data.get("max_alive", 4))
	return maxi(base_cap + int(_combat_balance.get("max_alive_delta", 0)) + (_player_count - 1), 2)


func _build_stats_summary() -> String:
	if _is_vs_mode():
		var center_status := "SAHADA" if _has_active_pickup_type("tactical") else ("%ds" % ceili(_vs_center_timer) if _vs_center_wave < VS_CENTER_MAX_WAVES else "BİTTİ")
		var corner_status := "SAHADA" if _has_active_corner_cache() else ("%ds" % ceili(_vs_cache_timer) if _vs_cache_wave < VS_CACHE_MAX_WAVES else "BİTTİ")
		return "Tank %d/2 | Merkez %s | Köşe %s" % [get_active_player_targets().size(), center_status, corner_status]
	if _objective_type == "command_hunt" or _objective_type == "boss_hunt":
		return "Sahada %d | Hedef %d/%d" % [_alive_enemies, _objective_target_total - _objective_target_remaining, _objective_target_total]

	var remaining := _total_enemies - _spawned_enemies + _alive_enemies
	return "Sahada %d | Toplam kalan %d" % [_alive_enemies, remaining]


func _build_stage_brief() -> String:
	if _is_vs_mode():
		return "Tank düellosu | Merkez çekirdeği küçük avantaj sağlar; açık alanda risklidir."
	if _objective_type == "eliminate":
		return _stage_data.get("tagline", "Ozgun savunma duzeni.")

	return _mission_label


func _build_objective_progress_text() -> String:
	if _is_vs_mode():
		return "P1  VS  P2"
	var remaining := _total_enemies - _spawned_enemies + _alive_enemies

	if _objective_type == "command_hunt":
		return "Komutan %d/%d | Kalan %d" % [_objective_target_total - _objective_target_remaining, _objective_target_total, remaining]

	if _objective_type == "boss_hunt":
		return "Boss %d/%d | Kalan %d" % [_objective_target_total - _objective_target_remaining, _objective_target_total, remaining]

	return "Temiz %d/%d | Kalan %d" % [_destroyed_enemies, _total_enemies, remaining]


func _build_wave_progress_text() -> String:
	if _is_vs_mode():
		return _build_objective_progress_text()
	return "DALGA %d/%d | %s" % [_current_wave, _wave_count, _build_objective_progress_text()]


func _build_power_summary() -> String:
	var chunks: Array[String] = []
	for slot in range(1, _player_count + 1):
		var player_node = _get_player_by_slot(slot)
		if is_instance_valid(player_node):
			chunks.append("%s %s" % [player_node.get_callsign(), player_node.get_powerup_summary()])
	return " || ".join(chunks) if not chunks.is_empty() else "Saha bos"


func _get_lowest_player_health() -> int:
	var lowest_health := 99
	for slot in range(1, _player_count + 1):
		var player_node = _get_player_by_slot(slot)
		if is_instance_valid(player_node):
			lowest_health = mini(lowest_health, int(player_node.health))
	return 3 if lowest_health == 99 else lowest_health


func _get_player_by_slot(slot: int) -> Node:
	return _players_by_slot.get(slot, null)


func _get_local_player() -> Node:
	return _get_player_by_slot(_local_player_slot)


func _get_mode_label() -> String:
	if _is_vs_mode():
		return "ONLINE VS"
	if _is_online_mode():
		return "ONLINE CO-OP"
	return "SOLO"


func _is_online_mode() -> bool:
	return _session_mode in ["online_coop", "online_vs"]


func _is_vs_mode() -> bool:
	return _session_mode == "online_vs"


func _stage_has_core() -> bool:
	return not _is_vs_mode() and bool(_stage_data.get("core_enabled", true))


func _is_authority() -> bool:
	return not _is_online_mode() or NetSession.is_host() or _capture_requested


func _claim_network_id() -> int:
	var id := _next_network_id
	_next_network_id += 1
	return id


func _update_wait_state(waiting: bool) -> void:
	_waiting_for_peer = waiting
	if waiting and _is_online_mode():
		_status_text = "Rakip bekleniyor" if _is_vs_mode() else "Es oyuncu bekleniyor"
		spawn_timer.stop()
	elif not _match_over:
		_status_text = "Catismaya devam"


func _apply_remote_player_input() -> void:
	if not _is_online_mode() or not _is_authority():
		return

	for slot in range(1, _player_count + 1):
		if slot == _local_player_slot:
			continue
		var player_node = _get_player_by_slot(slot)
		if is_instance_valid(player_node):
			player_node.set_external_input(NetSession.get_remote_input(slot))


func _on_online_peer_status_changed(connected: bool, _count: int) -> void:
	_apply_online_player_profiles()
	_update_wait_state(not connected)

	if connected:
		if _is_authority():
			_last_sent_wall_revision = -1
		var connected_text := "Rakip baglandi. Duello basliyor." if _is_vs_mode() else "Es oyuncu baglandi. Operasyon basliyor."
		_show_alert(connected_text, _get_theme_color("hud_accent", Color("#f2d48f")))
		if _is_authority() and spawn_timer.is_stopped() and not _match_over and not _is_vs_mode():
			spawn_timer.start(_scaled_spawn_delay(1.0))
	else:
		_show_alert("Baglanti kesildi. Oda es oyuncuyu bekliyor.", Color("#ffb584"))

	_update_hud()


func _on_online_profiles_updated() -> void:
	_apply_online_player_profiles()
	_update_hud()


func _on_online_snapshot_updated() -> void:
	if _is_authority():
		return

	var snapshot := NetSession.get_latest_snapshot()
	if snapshot.is_empty():
		return

	# Network packets arrive during the idle loop. Keep only the newest snapshot
	# and apply it on the next physics tick to avoid mixed-clock transform jitter.
	_pending_network_snapshot = snapshot


func _build_world_snapshot() -> Dictionary:
	var walls_changed := _last_sent_wall_revision != _wall_revision
	var wall_snapshot := _serialize_walls() if walls_changed else []
	if walls_changed:
		_last_sent_wall_revision = _wall_revision
	return {
		"players": _serialize_players(),
		"enemies": _serialize_enemies(),
		"bullets": _serialize_bullets(),
		"pickups": _serialize_pickups(),
		"walls": wall_snapshot,
		"walls_changed": walls_changed,
		"walls_revision": _wall_revision,
		"meta": {
			"hit_event": _last_hit_event.duplicate(true) if _hit_event_lifetime > 0.0 else {},
			"spawned": _spawned_enemies,
			"alive": _alive_enemies,
			"total": _total_enemies,
			"destroyed": _destroyed_enemies,
			"wave": _current_wave,
			"wave_count": _wave_count,
			"wave_end": _current_wave_end,
			"objective_remaining": _objective_target_remaining,
			"status_text": _status_text,
			"match_over": _match_over,
			"winner_slot": _winner_slot,
			"result_is_draw": _result_is_draw,
			"elimination_text": _elimination_text,
			"vs_cache_timer": _vs_cache_timer,
			"vs_cache_wave": _vs_cache_wave,
			"vs_center_timer": _vs_center_timer,
			"vs_center_wave": _vs_center_wave,
			"result_title": result_title.text,
			"result_subtitle": result_subtitle.text,
			"next_stage_visible": next_stage_button.visible
		}
	}


func _serialize_players() -> Array:
	var snapshots := []
	for slot in range(1, _player_count + 1):
		var player_node = _get_player_by_slot(slot)
		if is_instance_valid(player_node):
			snapshots.append(player_node.build_snapshot())
		else:
			snapshots.append({"slot": slot, "callsign": "P%d" % slot, "alive": false})
	return snapshots


func _serialize_enemies() -> Array:
	var snapshots := []
	for enemy in get_tree().get_nodes_in_group("enemy_tanks"):
		if enemy.network_id < 0:
			enemy.network_id = _claim_network_id()
		snapshots.append(enemy.build_snapshot())
	return snapshots


func _serialize_bullets() -> Array:
	var snapshots := []
	for bullet in get_tree().get_nodes_in_group("bullets"):
		if bullet.network_id < 0:
			bullet.network_id = _claim_network_id()
		snapshots.append(bullet.build_snapshot())
	return snapshots


func _serialize_pickups() -> Array:
	var snapshots := []
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.network_id < 0:
			pickup.network_id = _claim_network_id()
		snapshots.append(pickup.build_snapshot())
	return snapshots


func _serialize_walls() -> Array:
	var snapshots := []
	for child in get_children():
		if child is StaticBody2D and child.name.begins_with("Wall"):
			var cell := _name_to_cell(child.name)
			snapshots.append({"name": child.name, "cell_x": cell.x, "cell_y": cell.y, "block_type": child.block_type, "durability": child.durability})
	return snapshots


func _apply_world_snapshot(snapshot: Dictionary) -> void:
	var incoming_wall_revision := int(snapshot.get("walls_revision", -1))
	if bool(snapshot.get("walls_changed", false)) and incoming_wall_revision > _last_applied_wall_revision:
		_apply_wall_snapshot(Array(snapshot.get("walls", [])))
		_last_applied_wall_revision = incoming_wall_revision
	_apply_player_snapshot(Array(snapshot.get("players", [])))
	_apply_enemy_snapshot(Array(snapshot.get("enemies", [])))
	_apply_bullet_snapshot(Array(snapshot.get("bullets", [])))
	_apply_pickup_snapshot(Array(snapshot.get("pickups", [])))
	_apply_meta_snapshot(Dictionary(snapshot.get("meta", {})))
	_update_hud()


func _apply_player_snapshot(players: Array) -> void:
	for player_state in players:
		var slot := int(player_state.get("slot", 1))
		var player_node = _get_player_by_slot(slot)
		var alive := bool(player_state.get("alive", true))

		if not alive:
			if is_instance_valid(player_node) and slot != _local_player_slot:
				player_node.queue_free()
				_players_by_slot.erase(slot)
			continue

		if not is_instance_valid(player_node):
			var new_player = PLAYER_TANK_SCENE.instantiate()
			new_player.name = "PlayerTank%d" % slot
			add_child(new_player)
			var profile := _build_player_profile(slot)
			profile["team"] = "player_%d" % slot if _is_vs_mode() else "player"
			new_player.configure_player(profile)
			new_player.set_mobile_controls(mobile_controls)
			new_player.set_control_mode("local" if slot == _local_player_slot else "replica")
			new_player.set_spawn_bullets_enabled(false)
			_players_by_slot[slot] = new_player
			player_node = new_player

		if slot == _local_player_slot and _is_online_mode():
			player_node.apply_snapshot(player_state, "reconcile")
		else:
			player_node.apply_snapshot(player_state, "smooth")


func _apply_enemy_snapshot(enemies: Array) -> void:
	var by_id := {}
	for enemy in get_tree().get_nodes_in_group("enemy_tanks"):
		by_id[enemy.network_id] = enemy

	var seen := {}
	for enemy_state in enemies:
		var enemy_id := int(enemy_state.get("id", -1))
		seen[enemy_id] = true
		var enemy_node = by_id.get(enemy_id, null)
		if enemy_node == null:
			enemy_node = ENEMY_TANK_SCENE.instantiate()
			enemy_node.set_replica_mode(true)
			add_child(enemy_node)
		enemy_node.set_replica_mode(true)
		enemy_node.apply_snapshot(enemy_state)

	for enemy in get_tree().get_nodes_in_group("enemy_tanks"):
		if not seen.has(enemy.network_id):
			enemy.queue_free()


func _apply_bullet_snapshot(bullets: Array) -> void:
	var by_id := {}
	for bullet in get_tree().get_nodes_in_group("bullets"):
		by_id[bullet.network_id] = bullet

	var seen := {}
	for bullet_state in bullets:
		var bullet_id := int(bullet_state.get("id", -1))
		seen[bullet_id] = true
		var bullet_node = by_id.get(bullet_id, null)
		if bullet_node == null:
			bullet_node = BULLET_SCENE.instantiate()
			bullet_node.set_replica_mode(true)
			add_child(bullet_node)
		bullet_node.set_replica_mode(true)
		bullet_node.apply_snapshot(bullet_state)

	for bullet in get_tree().get_nodes_in_group("bullets"):
		if not seen.has(bullet.network_id):
			bullet.queue_free()


func _apply_pickup_snapshot(pickups: Array) -> void:
	var by_id := {}
	for pickup in get_tree().get_nodes_in_group("pickups"):
		by_id[pickup.network_id] = pickup

	var seen := {}
	for pickup_state in pickups:
		var pickup_id := int(pickup_state.get("id", -1))
		seen[pickup_id] = true
		var pickup_node = by_id.get(pickup_id, null)
		if pickup_node == null:
			pickup_node = PICKUP_SCENE.instantiate()
			pickup_node.set_replica_mode(true)
			add_child(pickup_node)
		pickup_node.set_replica_mode(true)
		pickup_node.apply_snapshot(pickup_state)

	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not seen.has(pickup.network_id):
			pickup.queue_free()


func _apply_wall_snapshot(walls: Array) -> void:
	var wall_names := {}
	for wall_state in walls:
		var wall_name := String(wall_state.get("name", ""))
		wall_names[wall_name] = true
		var existing: Node = get_node_or_null(NodePath(wall_name))
		if existing == null:
			_spawn_wall(Vector2i(int(wall_state.get("cell_x", 0)), int(wall_state.get("cell_y", 0))), String(wall_state.get("block_type", "brick")), int(wall_state.get("durability", 1)))
			existing = get_node_or_null(NodePath(wall_name))
		if existing:
			var next_type := String(wall_state.get("block_type", existing.block_type))
			var next_durability := int(wall_state.get("durability", existing.durability))
			if existing.block_type != next_type or existing.durability != next_durability:
				existing.block_type = next_type
				existing.durability = next_durability
				existing.queue_redraw()

	for child in get_children():
		if child is StaticBody2D and child.name.begins_with("Wall") and not wall_names.has(child.name):
			child.collision_layer = 0
			child.collision_mask = 0
			child.queue_free()


func _apply_meta_snapshot(meta: Dictionary) -> void:
	var was_match_over := _match_over
	_present_hit_event(Dictionary(meta.get("hit_event", {})))
	_spawned_enemies = int(meta.get("spawned", _spawned_enemies))
	_alive_enemies = int(meta.get("alive", _alive_enemies))
	_total_enemies = int(meta.get("total", _total_enemies))
	_destroyed_enemies = int(meta.get("destroyed", _destroyed_enemies))
	_current_wave = int(meta.get("wave", _current_wave))
	_wave_count = int(meta.get("wave_count", _wave_count))
	_current_wave_end = int(meta.get("wave_end", _current_wave_end))
	_objective_target_remaining = int(meta.get("objective_remaining", _objective_target_remaining))
	_status_text = String(meta.get("status_text", _status_text))
	_match_over = bool(meta.get("match_over", _match_over))
	_winner_slot = int(meta.get("winner_slot", _winner_slot))
	_result_is_draw = bool(meta.get("result_is_draw", _result_is_draw))
	_elimination_text = String(meta.get("elimination_text", _elimination_text))
	_vs_cache_timer = float(meta.get("vs_cache_timer", _vs_cache_timer))
	_vs_cache_wave = int(meta.get("vs_cache_wave", _vs_cache_wave))
	_vs_center_timer = float(meta.get("vs_center_timer", _vs_center_timer))
	_vs_center_wave = int(meta.get("vs_center_wave", _vs_center_wave))

	if _match_over:
		var local_won := false
		if _is_vs_mode():
			local_won = _configure_local_vs_result()
		else:
			result_title.text = String(meta.get("result_title", result_title.text))
			result_subtitle.text = String(meta.get("result_subtitle", result_subtitle.text))
			local_won = _status_text == "Zafer"
		next_stage_button.visible = bool(meta.get("next_stage_visible", false))
		result_overlay.visible = true
		_stop_match_entities()
		if not was_match_over or not _result_animation_played:
			_play_result_presentation(local_won, _result_is_draw)


func _name_to_cell(name: String) -> Vector2i:
	var parts := name.split("_")
	if parts.size() >= 3:
		return Vector2i(int(parts[1]), int(parts[2]))
	return Vector2i.ZERO


func _build_combat_balance() -> Dictionary:
	var balance := {
		"player_bonus_health": 0,
		"spawn_shield_duration": 1.5,
		"player_fire_scale": 1.0,
		"spawn_delay_scale": 1.0,
		"max_alive_delta": 0,
		"queue_trim": 0,
		"pickup_drop_bonus": 0.0,
		"coop_enemy_bonus_ratio": 0.22
	}
	var stage_index := int(_stage_data.get("index", 0))
	if _is_vs_mode():
		balance["spawn_shield_duration"] = 1.5
		balance["player_fire_scale"] = 1.1
		balance["coop_enemy_bonus_ratio"] = 0.0
		return balance

	if _player_count <= 1:
		if stage_index < 4:
			balance["player_bonus_health"] = 1
			balance["spawn_shield_duration"] = 3.2
			balance["player_fire_scale"] = 0.9
			balance["spawn_delay_scale"] = 1.1
			balance["max_alive_delta"] = -1
			balance["queue_trim"] = 1
			balance["pickup_drop_bonus"] = 0.1
		elif stage_index < 14:
			balance["player_bonus_health"] = 1
			balance["spawn_shield_duration"] = 2.7
			balance["player_fire_scale"] = 0.96
			balance["spawn_delay_scale"] = 1.0
			balance["queue_trim"] = 1
			balance["pickup_drop_bonus"] = 0.08
		elif stage_index < 24:
			balance["player_bonus_health"] = 1
			balance["spawn_shield_duration"] = 2.2
			balance["player_fire_scale"] = 0.96
			balance["spawn_delay_scale"] = 1.02
			balance["max_alive_delta"] = -1
			balance["pickup_drop_bonus"] = 0.07
		elif stage_index < 39:
			balance["player_bonus_health"] = 1
			balance["spawn_shield_duration"] = 2.1
			balance["player_fire_scale"] = 0.94
			balance["spawn_delay_scale"] = 1.04
			balance["max_alive_delta"] = -1
			balance["pickup_drop_bonus"] = 0.08
		else:
			balance["player_bonus_health"] = 1
			balance["spawn_shield_duration"] = 2.4
			balance["player_fire_scale"] = 0.92
			balance["spawn_delay_scale"] = 1.08
			balance["max_alive_delta"] = -1
			balance["pickup_drop_bonus"] = 0.1
	elif _is_online_mode():
		balance["spawn_shield_duration"] = 2.25
		balance["spawn_delay_scale"] = 1.02
		balance["pickup_drop_bonus"] = 0.08
		balance["coop_enemy_bonus_ratio"] = 0.12
	else:
		balance["spawn_shield_duration"] = 1.75
		balance["spawn_delay_scale"] = 0.88 if stage_index >= 39 else 0.96
		balance["pickup_drop_bonus"] = 0.04
		balance["coop_enemy_bonus_ratio"] = 0.2

	return balance


func _scaled_spawn_delay(base_delay: float) -> float:
	if _capture_requested:
		return base_delay

	return base_delay * float(_combat_balance.get("spawn_delay_scale", 1.0))


func _get_initial_spawn_delay() -> float:
	var stage_index := int(_stage_data.get("index", 0))
	if stage_index == 0:
		return 2.0
	if stage_index >= 49:
		return 1.2
	if stage_index >= 29:
		return 1.15
	if stage_index >= 19:
		return 1.1
	return 1.0


func _queue_runtime_child(node: Node) -> void:
	call_deferred("_add_runtime_child", node)


func _add_runtime_child(node: Node) -> void:
	if is_instance_valid(node):
		add_child(node)
