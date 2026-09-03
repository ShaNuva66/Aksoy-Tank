extends SceneTree

const STAGE_CATALOG := preload("res://src/scripts/stage_catalog.gd")
const ENEMY_TANK_SCRIPT := preload("res://src/scripts/enemy_tank.gd")
const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"
const STAGES_PER_BAND := 10

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("COMPLETION: 60-stage state-machine simulation started")
	var game_session := root.get_node_or_null("GameSession")
	if game_session == null:
		_fail("GameSession autoload is missing")
		quit(1)
		return
	var previous_session_mode: String = game_session.session_mode
	var previous_stage_index: int = game_session.selected_stage_index
	var previous_unlocked_count: int = game_session.unlocked_stage_count
	var previous_onboarding: bool = game_session.onboarding_completed
	game_session.session_mode = "solo"
	game_session.unlocked_stage_count = STAGE_CATALOG.get_stage_count()
	game_session.onboarding_completed = true

	var band_totals: Array[float] = []
	for _band in range(6):
		band_totals.append(0.0)

	for stage_index in range(STAGE_CATALOG.get_stage_count()):
		var stage := STAGE_CATALOG.get_stage(stage_index)
		var band_index := floori(float(stage_index) / float(STAGES_PER_BAND))
		band_totals[band_index] += _threat_score(stage)
		await _simulate_stage_completion(game_session, stage_index, stage)

	for band_index in range(1, band_totals.size()):
		var previous_average := band_totals[band_index - 1] / STAGES_PER_BAND
		var current_average := band_totals[band_index] / STAGES_PER_BAND
		_require(current_average >= previous_average * 0.9, "Difficulty band %d falls too far: %.1f after %.1f" % [band_index + 1, current_average, previous_average])
		print("COMPLETION: difficulty band %d average=%.1f" % [band_index + 1, current_average])

	game_session.session_mode = previous_session_mode
	game_session.selected_stage_index = previous_stage_index
	game_session.unlocked_stage_count = previous_unlocked_count
	game_session.onboarding_completed = previous_onboarding
	game_session._save_progress()

	if _failed:
		print("COMPLETION: FAIL")
		quit(1)
	else:
		print("COMPLETION: PASS")
		quit(0)


func _simulate_stage_completion(game_session: Node, stage_index: int, stage: Dictionary) -> void:
	game_session.selected_stage_index = stage_index
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	arena.spawn_timer.stop()
	var queue: Array = arena._enemy_queue
	var max_steps := queue.size() + int(arena._wave_count) + 8
	var steps := 0
	while not arena._match_over and steps < max_steps:
		steps += 1
		var before_spawned := int(arena._spawned_enemies)
		arena._on_spawn_timer_timeout()
		await physics_frame
		if int(arena._spawned_enemies) == before_spawned:
			if int(arena._alive_enemies) == 0 and before_spawned >= int(arena._current_wave_end):
				arena._complete_current_wave()
			continue

		var enemy_type := String(queue[before_spawned])
		for enemy in get_nodes_in_group("enemy_tanks"):
			if is_instance_valid(enemy):
				enemy.queue_free()
		arena._on_enemy_destroyed(enemy_type, Vector2(640.0, 120.0))
		await _wait_frames(1)
		arena.spawn_timer.stop()

	var number := stage_index + 1
	_require(arena._match_over, "Stage %02d did not reach a result" % number)
	_require(String(arena._status_text) == "Zafer", "Stage %02d ended without victory" % number)
	_require(arena.result_overlay.visible, "Stage %02d did not show its result UI" % number)
	print("COMPLETION: Stage %02d PASS spawned=%d/%d waves=%d" % [number, arena._spawned_enemies, queue.size(), arena._wave_count])
	arena.queue_free()
	current_scene = null
	await _wait_frames(2)


func _threat_score(stage: Dictionary) -> float:
	var score := 0.0
	var profiles: Dictionary = ENEMY_TANK_SCRIPT.PROFILES
	for enemy_type_value in stage.get("enemy_queue", []):
		var profile: Dictionary = profiles.get(String(enemy_type_value), {})
		score += float(profile.get("health", 1)) * float(profile.get("damage", 1))
		score += float(profile.get("speed", 100.0)) / 180.0
	score *= 1.0 + float(stage.get("max_alive", 1)) * 0.08
	return score


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failed = true
	push_error("COMPLETION FAIL: " + message)
	print("COMPLETION: FAIL - " + message)
