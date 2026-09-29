extends SceneTree

const STAGE_CATALOG := preload("res://src/scripts/stage_catalog.gd")
const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"
const WALL_SCENE := "res://src/scenes/wall_block.tscn"

var _failed := false
var _game_session: Node = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("REGRESSION: gameplay rules started")
	_game_session = root.get_node_or_null("GameSession")
	_require(_game_session != null, "GameSession autoload is missing")
	if _game_session == null:
		quit(1)
		return
	_audit_catalog_rules()
	_audit_persistent_accessibility_settings()
	_audit_wall_geometry()
	await _audit_core_stage()
	await _audit_boss_stage()
	await _audit_vs_stage()
	_game_session.set_session_mode("solo")
	if _failed:
		print("REGRESSION: FAIL")
		quit(1)
	else:
		print("REGRESSION: PASS")
		quit(0)


func _audit_catalog_rules() -> void:
	var core_stage_count := 0
	var coreless_stage_count := 0
	for index in range(STAGE_CATALOG.get_stage_count()):
		var stage := STAGE_CATALOG.get_stage(index)
		var number := int(stage.get("number", 0))
		if bool(stage.get("core_enabled", true)):
			core_stage_count += 1
		else:
			coreless_stage_count += 1
		_require(int(stage.get("wave_count", 0)) in [2, 3, 4], "Stage %d has invalid waves" % number)
		_require(int(stage.get("max_alive", 0)) <= 7, "Stage %d exceeds the smooth pressure cap" % number)
		if number % 5 == 0:
			_require(String(stage.get("objective_type", "")) == "boss_hunt", "Stage %d is not a boss hunt" % number)
			_require(String(stage.get("objective_target_type", "")).begins_with("boss"), "Stage %d has no main boss" % number)
	_require(core_stage_count > 0, "Campaign has no core-defense stages")
	_require(coreless_stage_count > 0, "Campaign has no coreless missions")
	_require(_game_session.SESSION_MODES == ["solo", "online_coop", "online_vs"], "Online mode catalog is incomplete")


func _audit_wall_geometry() -> void:
	var wall = load(WALL_SCENE).instantiate()
	root.add_child(wall)
	var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
	var rectangle := shape_node.shape as RectangleShape2D
	_require(rectangle != null and rectangle.size == Vector2(48.0, 48.0), "Wall collider does not close cell seams")
	wall.queue_free()


func _audit_persistent_accessibility_settings() -> void:
	var old_effects := float(_game_session.get_effects_intensity())
	var old_reduced := bool(_game_session.is_reduced_motion_enabled())
	var old_haptics := bool(_game_session.is_haptics_enabled())
	_game_session.set_effects_intensity(0.35)
	_game_session.set_reduced_motion_enabled(true)
	_game_session.set_haptics_enabled(false)
	var config := ConfigFile.new()
	_require(config.load(_game_session.SAVE_PATH) == OK, "Settings save file could not be read")
	_require(is_equal_approx(float(config.get_value("settings", "effects_intensity", -1.0)), 0.35), "Effect intensity was not persisted")
	_require(bool(config.get_value("settings", "reduced_motion_enabled", false)), "Reduced motion was not persisted")
	_require(not bool(config.get_value("settings", "haptics_enabled", true)), "Haptics preference was not persisted")
	_game_session.set_effects_intensity(old_effects)
	_game_session.set_reduced_motion_enabled(old_reduced)
	_game_session.set_haptics_enabled(old_haptics)


func _audit_core_stage() -> void:
	_game_session.set_session_mode("solo")
	_game_session.unlocked_stage_count = STAGE_CATALOG.get_stage_count()
	_game_session.selected_stage_index = 0
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	var core = arena.get_node_or_null("Wall_12_12")
	_require(core != null and int(core.durability) == 5, "Core durability should be 5")
	for cell in [Vector2i(11, 12), Vector2i(13, 12), Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11)]:
		var fort = arena.get_node_or_null("Wall_%d_%d" % [cell.x, cell.y])
		_require(fort != null and String(fort.block_type) == "fortified" and int(fort.durability) == 7, "Core fort is not 7-hit fortified at %s" % cell)
	_require(arena.get_node_or_null("Hud/ShieldHud/VBox/Bar") != null, "Shield duration bar is missing")
	_require(not arena.get_node("Hud/HeaderBackdrop").visible, "Obsolete black HUD backdrop is still visible")
	_require(arena.get_node("Hud/Header").visible, "Compact wave HUD is hidden")
	_require(arena.get_node("Hud/Header/VBox/WaveLabel").visible, "Wave progress is not visible")
	_require(not arena.get_node("Hud/Header/VBox/InfoLabel").visible, "Bulky stage text returned to the compact HUD")
	_require(arena.get_node("Hud/ShieldHud").visible, "Active spawn shield duration is not visible")
	_require(arena.get_node("Hud/PauseButton").visible, "Solo mobile pause button is hidden")
	_require(arena.get_node_or_null("Hud/HeartHud") != null, "Minimal health indicator is missing")
	await _free_arena(arena)


func _audit_boss_stage() -> void:
	_game_session.set_session_mode("solo")
	_game_session.selected_stage_index = 4
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	_require(arena.get_node_or_null("Wall_12_12") == null, "Boss mission unexpectedly spawned a core")
	await _free_arena(arena)


func _audit_vs_stage() -> void:
	_game_session.set_session_mode("online_vs")
	_game_session.set_player_name("Ali Atalay")
	_game_session.set_tank_style("neon")
	_game_session.selected_stage_index = 0
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	var p1 = arena.get_node_or_null("PlayerTank1")
	var p2 = arena.get_node_or_null("PlayerTank2")
	_require(p1 != null and p2 != null, "VS mode did not create two tanks")
	if p1 != null and p2 != null:
		_require(p1.get_team() == "player_1" and p2.get_team() == "player_2", "VS tanks are not on opposing teams")
		_require(p1.get_callsign() == "Ali Atalay", "Local online player name was not applied")
		_require(String(p1.build_snapshot().get("style_id", "")) == "neon", "Selected tank style was not serialized")
		_require(is_equal_approx(float(p1._get_fire_cooldown()), p1.BASE_FIRE_COOLDOWN * 1.1), "VS fire-rate reduction was not applied equally")
		_require(arena.VS_CENTER_POSITION.distance_to((p1.global_position + p2.global_position) * 0.5) < 1.0, "VS center reward is not equidistant from both spawns")
		arena._capture_requested = true
		arena.notify_tank_hit_result(p2.global_position, p1.get_team(), p2.get_team(), 1, true, false)
		arena._capture_requested = false
		await _wait_frames(1)
		var hit_confirmations := get_nodes_in_group("hit_confirmations")
		_require(hit_confirmations.size() == 1, "VS damage did not create a visible hit confirmation")
		if hit_confirmations.size() == 1:
			var confirmation = hit_confirmations[0]
			_require(bool(confirmation.scored_by_local), "Shooter did not receive the positive hit-marker variant")
			_require(String(confirmation.feedback_text).contains("İSABET"), "Hit confirmation does not clearly communicate a successful shot")
			confirmation.queue_free()
		var hit_event: Dictionary = arena._build_world_snapshot().get("meta", {}).get("hit_event", {})
		_require(int(hit_event.get("sequence", 0)) > 0 and bool(hit_event.get("applied", false)), "Hit confirmation was not included in the online snapshot")
		arena._capture_requested = true
		arena.notify_tank_hit_result(p2.global_position, p1.get_team(), p2.get_team(), 1, false, false)
		arena._capture_requested = false
		await _wait_frames(1)
		var shield_confirmations := get_nodes_in_group("hit_confirmations")
		_require(shield_confirmations.size() == 1 and String(shield_confirmations[0].feedback_text).contains("KALKAN"), "Shield impact is not distinguished from health damage")
		for confirmation in shield_confirmations:
			confirmation.queue_free()
		await _wait_frames(1)
		arena._capture_requested = true
		arena.notify_tank_hit_result(p2.global_position, p1.get_team(), p2.get_team(), 1, true, true)
		arena._capture_requested = false
		await _wait_frames(1)
		var destroy_confirmations := get_nodes_in_group("hit_confirmations")
		_require(destroy_confirmations.size() == 1 and String(destroy_confirmations[0].feedback_text).contains("İMHA"), "Final hit does not show the destruction confirmation")
		for confirmation in destroy_confirmations:
			confirmation.queue_free()
		var normal_fire_cooldown := float(p1._get_fire_cooldown())
		p1.apply_powerup("tactical")
		_require(is_equal_approx(float(p1._get_move_speed()), p1.BASE_SPEED * p1.TACTICAL_SPEED_MULTIPLIER), "VS tactical reward movement boost is incorrect")
		_require(is_equal_approx(float(p1._get_fire_cooldown()), normal_fire_cooldown), "VS tactical reward must not increase fire rate")
		_require(float(p1.build_snapshot().get("tactical", 0.0)) > 0.0, "VS tactical reward is missing from network snapshots")
	for center_cell in arena.VS_CENTER_RESERVED_CELLS:
		for x_offset in range(-1, 2):
			for y_offset in range(-1, 2):
				var cell: Vector2i = Vector2i(center_cell) + Vector2i(x_offset, y_offset)
				_require(arena.get_node_or_null("Wall_%d_%d" % [cell.x, cell.y]) == null, "VS center contest area is blocked at %s" % cell)
	arena._spawn_vs_center_cache()
	await _wait_frames(2)
	var center_pickups := get_nodes_in_group("pickups")
	_require(center_pickups.size() == 1, "VS center did not create exactly one contested reward")
	if center_pickups.size() == 1:
		var center_pickup = center_pickups[0]
		_require(String(center_pickup.pickup_type) == "tactical", "VS center reward grants too much combat power")
		_require(center_pickup.global_position.distance_to(arena.VS_CENTER_POSITION) < 1.0, "VS center reward is not equidistant from both spawns")
		_require(float(center_pickup.lifetime) <= arena.VS_CENTER_LIFETIME, "VS center reward remains active too long")
		arena._spawn_vs_center_cache()
		_require(get_nodes_in_group("pickups").size() == 1, "VS center spawned duplicate rewards")
		center_pickup.queue_free()
	await _wait_frames(2)
	for cache_cell in arena.VS_CACHE_CELLS:
		for x_offset in range(-1, 2):
			for y_offset in range(-1, 2):
				var cell: Vector2i = Vector2i(cache_cell) + Vector2i(x_offset, y_offset)
				_require(arena.get_node_or_null("Wall_%d_%d" % [cell.x, cell.y]) == null, "VS corner cache approach is blocked at %s" % cell)
	arena._spawn_vs_corner_caches()
	await _wait_frames(2)
	var corner_pickups := get_nodes_in_group("pickups")
	_require(corner_pickups.size() == 2, "VS mode did not create a symmetric corner pickup pair")
	var expected_positions: Array[Vector2] = []
	for cache_cell in arena.VS_CACHE_CELLS:
		expected_positions.append(arena._cell_to_world(Vector2i(cache_cell)))
	for pickup in corner_pickups:
		_require(String(pickup.pickup_type) == "turbo", "First VS corner reward is too strong or asymmetric")
		_require(float(pickup.lifetime) <= arena.VS_CACHE_LIFETIME, "VS corner reward remains active too long")
		var is_expected_position := false
		for expected_position in expected_positions:
			if pickup.global_position.distance_to(expected_position) < 1.0:
				is_expected_position = true
		_require(is_expected_position, "VS corner reward spawned outside its marked risk zone")
	_require(arena.get_node_or_null("Wall_12_12") == null, "VS mode unexpectedly spawned a core")
	var result_fx = arena.get_node_or_null("Hud/ResultOverlay/ResultFX")
	_require(result_fx != null and result_fx.has_method("play_result"), "Animated result effects are missing")
	arena._winner_slot = 1
	arena._result_is_draw = false
	arena._elimination_text = "Rakip, Ali Atalay'ın tankı tarafından ezildi!"
	_require(arena._configure_local_vs_result(), "Local winner was not recognized")
	_require(String(arena.result_title.text) == "RAUND SENIN", "Winner round result is incorrect")
	_require(String(arena.result_subtitle.text).contains("HEDEF 3"), "Series target is missing from the result")
	arena._winner_slot = 2
	_require(not arena._configure_local_vs_result(), "Local loser was incorrectly marked as winner")
	_require(String(arena.result_title.text) == "RAUND KAYBEDILDI", "Loser round result is incorrect")
	arena._winner_slot = 1
	arena._capture_requested = true
	arena._finish_match(true, "Ali Atalay Arenayı Ezdi", arena._elimination_text)
	_require(int(arena._vs_series.get("p1", 0)) == 1, "Round victory did not update the series score")
	arena._finish_match(true, "Duplicate result", "")
	_require(int(arena._vs_series.get("p1", 0)) == 1, "Duplicate result counted the victory twice")
	arena._capture_requested = false
	await create_timer(0.8).timeout
	_require(arena.result_overlay.visible and result_fx.visible, "Winner animation did not become visible")
	_require(not arena.retry_button.disabled, "Result actions did not unlock after animation")
	arena._rematch_ready_slots[arena._local_player_slot] = true
	arena._update_rematch_ui()
	_require(arena.retry_button.disabled, "A single rematch vote did not lock the local button")
	_require(String(arena.result_subtitle.text).contains("1/2"), "Single rematch vote does not show that the opponent is required")
	_require(current_scene == arena, "A single rematch vote restarted one client")
	arena._rematch_ready_slots.clear()
	var final_meta: Dictionary = arena._build_world_snapshot().get("meta", {})
	_require(bool(final_meta.get("match_over", false)) and int(final_meta.get("winner_slot", 0)) == 1, "Final network result does not identify the winner")
	_require(int(final_meta.get("vs_cache_wave", 0)) == 1, "VS corner reward state is not synchronized")
	_require(int(final_meta.get("vs_center_wave", 0)) == 1, "VS center reward state is not synchronized")
	arena._on_online_rematch_status_updated([1, 2], true, 1)
	await _wait_frames(4)
	_require(current_scene != arena and current_scene != null and current_scene.scene_file_path == ARENA_SCENE, "Two rematch approvals did not restart the client")
	if current_scene != null:
		await _free_arena(current_scene)


func _free_arena(arena: Node) -> void:
	arena.queue_free()
	current_scene = null
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("REGRESSION FAIL: " + message)
