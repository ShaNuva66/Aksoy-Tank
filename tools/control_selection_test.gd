extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var session = root.get_node("GameSession")
	var original: String = session.get_control_style()
	var original_mode: String = session.session_mode
	var menu = load("res://src/scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	menu._control_buttons["buttons"].pressed.emit()
	check(session.get_control_style() == "buttons", "Menu selection")
	session.control_style = "analog"
	session._load_progress()
	check(session.get_control_style() == "buttons", "Persisted selection")
	var controls = load("res://src/scenes/mobile_controls.tscn").instantiate()
	root.add_child(controls)
	await process_frame
	check(controls.player_one_button_pad.visible and not controls.player_one_shell.visible, "Button layout")
	for slot in [1, 2]:
		controls.configure_layout(1, slot)
		touch(controls, 10, controls.player_one_up.get_global_rect().get_center(), true)
		touch(controls, 11, controls.player_one_right.get_global_rect().get_center(), true)
		touch(controls, 12, controls.player_one_fire.get_global_rect().get_center(), true)
		check(controls.get_move_axis(slot) == 1 and controls.get_turn_axis(slot) == 1 and controls.is_fire_pressed(slot), "Move + turn + fire: %s %s %s viewport=%s" % [controls.get_move_axis(slot), controls.get_turn_axis(slot), controls.is_fire_pressed(slot), root.get_visible_rect()])
		check(controls.get_move_axis(3 - slot) == 0 and controls.get_turn_axis(3 - slot) == 0, "Guest slot isolation")
		controls.set_controls_enabled(false)
		controls.set_controls_enabled(true)
		check(controls.get_move_axis(slot) == 0 and not controls.is_fire_pressed(slot), "Pause clears inputs")
	controls.set_control_style("analog")
	check(controls.player_one_shell.visible and not controls.player_one_button_pad.visible, "Analog layout")
	controls.set_control_style("invalid")
	check(controls.get_control_style() == "analog", "Invalid setting fallback")
	controls.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		for mode in ["solo", "online_coop", "online_vs"]:
			menu._select_mode(mode)
			await create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			var viewport := Rect2(Vector2.ZERO, root.get_visible_rect().size)
			check(viewport.encloses(menu.menu_panel.get_global_rect()), "Menu fits " + mode)
			check(not menu.menu_panel.get_global_rect().intersects(menu.mode_row.get_global_rect()), "Navigation clear " + mode)
			root.get_texture().get_image().save_png("user://control-selection-%s-%d.png" % [mode, root.size.x])
	session.set_control_style(original)
	root.get_node("NetSession").disconnect_session(false)
	session.set_session_mode(original_mode)
	menu.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("CONTROL_SELECTION: FAIL" if failed else "CONTROL_SELECTION: PASS")
	quit(1 if failed else 0)

func touch(controls: Node, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	controls._handle_screen_touch(event)

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
