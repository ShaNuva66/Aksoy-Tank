extends SceneTree

var failed := false

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func tap(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = position
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func run() -> void:
	var session = root.get_node("GameSession")
	var original_style: String = session.get_control_style()
	var original_mode: String = session.session_mode
	session.session_mode = "solo"
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	await process_frame
	await tap(arena.pause_button.get_global_rect().get_center())
	check(paused and arena.pause_overlay.visible, "Touch pause must stop solo gameplay")
	arena._on_pause_button_pressed()
	check(paused, "Duplicate pause activation must not resume gameplay")
	check(not arena.can_process(), "Arena must stop processing while paused")
	var remaining: float = arena.spawn_timer.time_left
	await create_timer(0.2, true).timeout
	check(is_equal_approx(remaining, arena.spawn_timer.time_left), "Spawn timer advanced during pause")
	await tap(arena.pause_buttons_button.get_global_rect().get_center())
	check(arena.mobile_controls.get_control_style() == "buttons", "Pause menu must honor button selection")
	await tap(arena.pause_resume_button.get_global_rect().get_center())
	check(not paused and not arena.pause_overlay.visible, "Touch resume must restore gameplay")
	var controls = arena.mobile_controls
	for button in controls._get_direction_buttons(1).values():
		check(button.size == Vector2(112, 112), "Direction targets must be enlarged")
		check(root.get_visible_rect().encloses(button.get_global_rect()), "Direction button outside viewport")
		check(not button.get_global_rect().intersects(controls.player_one_fire.get_global_rect()), "Direction/fire overlap")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://buttons-gameplay.png")
	await tap(arena.pause_button.get_global_rect().get_center())
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://buttons-pause.png")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	check(not paused, "Escape must resume a paused game")
	for mode in ["online_coop", "online_vs"]:
		arena._session_mode = mode
		await tap(arena.pause_button.get_global_rect().get_center())
		check(not paused and arena.pause_overlay.visible, "Online menu must preserve networking")
		await tap(arena.pause_resume_button.get_global_rect().get_center())
		check(not arena.pause_overlay.visible, "Online touch resume failed")
	paused = false
	arena.queue_free()
	await process_frame
	session.set_control_style(original_style)
	session.session_mode = original_mode
	print("PAUSE_TOUCH: FAIL" if failed else "PAUSE_TOUCH: PASS")
	quit(1 if failed else 0)
