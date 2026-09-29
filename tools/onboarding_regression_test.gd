extends SceneTree

const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("ONBOARDING: interactive tutorial started")
	var game_session := root.get_node_or_null("GameSession")
	if game_session == null:
		_fail("GameSession autoload is missing")
		return
	var previous_completed := bool(game_session.onboarding_completed)
	game_session.session_mode = "solo"
	game_session.selected_stage_index = 0
	game_session.onboarding_completed = false

	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(6)
	_require(bool(arena._onboarding_active), "Tutorial did not start on the first campaign stage")
	_require(arena.spawn_timer.is_stopped(), "Enemy wave started before tutorial completion")
	var guide = arena.get_node_or_null("Hud/OnboardingGuide")
	var player = arena.get_node_or_null("PlayerTank1")
	_require(guide != null and player != null, "Tutorial guide or player is missing")
	if guide != null and player != null:
		player.global_position += Vector2(guide.MOVE_DISTANCE_REQUIRED + 4.0, 0.0)
		guide._process(0.05)
		_require(int(guide._phase) == 1, "Tutorial did not recognize real player movement")
		player._fire()
		guide._process(0.05)
		guide._process(0.9)
		await _wait_frames(2)
		_require(game_session.has_completed_onboarding(), "Tutorial completion was not persisted")
		_require(not bool(arena._onboarding_active), "Tutorial left the arena in training state")
		_require(not arena.spawn_timer.is_stopped(), "First enemy wave did not start after tutorial")

	arena.queue_free()
	current_scene = null
	game_session.onboarding_completed = previous_completed
	game_session._save_progress()
	await _wait_frames(2)
	if _failed:
		print("ONBOARDING: FAIL")
		quit(1)
	else:
		print("ONBOARDING: PASS")
		quit(0)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failed = true
	push_error("ONBOARDING FAIL: " + message)
	print("ONBOARDING: FAIL - " + message)
