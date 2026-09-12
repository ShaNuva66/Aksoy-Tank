extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var session = root.get_node("GameSession")
	var net = root.get_node("NetSession")
	var old_mode: String = session.session_mode
	var test_mode := "online_vs" if "--vs" in OS.get_cmdline_user_args() else "online_coop"
	session.session_mode = test_mode
	var menu = load("res://src/scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(1.5).timeout
	check_control(menu.start_button)
	check_control(menu._quick_match_button)
	if test_mode == "online_coop":
		check_control(menu.stage_row)
	for button in menu._mode_buttons.values():
		check_control(button)
	if menu.mode_row.get_global_rect().intersects(menu.menu_panel.get_global_rect()):
		failed = true
		push_error("Mode buttons overlap menu content")
	menu._mode_buttons["solo"].pressed.emit()
	if session.session_mode != "solo" or menu.online_config.visible:
		failed = true
	menu._mode_buttons[test_mode].pressed.emit()
	await capture("online-menu")
	menu.queue_free()
	await process_frame
	net._role = "host"
	net._status = net.STATUS_CONNECTED
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await create_timer(0.5).timeout
	check_control(arena.info_label)
	check_control(arena.pause_button)
	if not arena._waiting_for_peer or arena._get_local_player().can_process():
		failed = true
	await capture("online-wait")
	check_control(arena._lobby_label)
	arena._set_pause_state(true)
	await create_timer(0.3).timeout
	check_control(arena.pause_menu_button)
	check_control(arena.pause_resume_button)
	check_control(arena._story_button)
	await capture("online-menu-match")
	arena._set_pause_state(false)
	net._peer_connected = true
	net._remote_inputs[2] = {"ready_token": arena._online_ready_token}
	net._remote_input_times[2] = Time.get_ticks_msec()
	await create_timer(0.2).timeout
	check_control(arena._online_countdown_label)
	if not arena._waiting_for_peer or arena._online_countdown_label.text != "3":
		failed = true
	await capture("online-countdown")
	var controls = arena.mobile_controls
	var origin := Vector2(root.get_visible_rect().size) * Vector2(0.3, 0.64)
	controls._try_bind_joystick_pointer(42, origin)
	controls._update_pointer_position(42, origin + Vector2(64, -32))
	await capture("online-floating")
	controls._release_touch_pointer(42)
	arena._set_pause_state(true)
	await create_timer(0.15).timeout
	if arena._online_countdown_label.visible:
		failed = true
	await capture("online-countdown-menu")
	arena._set_pause_state(false)
	if not arena._online_countdown_label.visible:
		failed = true
	arena._set_pause_state(true)
	arena._story_button.pressed.emit()
	await process_frame
	await process_frame
	if session.session_mode != "solo" or net.get_status() != net.STATUS_DISCONNECTED or current_scene.scene_file_path != "res://src/scenes/main_menu.tscn":
		failed = true
		push_error("Online to story navigation failed")
	await create_timer(0.8).timeout
	await capture("story-menu")
	current_scene.queue_free()
	await process_frame
	net.disconnect_session(false)
	session.set_session_mode(old_mode)
	print("ONLINE_UI: FAIL" if failed else "ONLINE_UI: PASS")
	quit(1 if failed else 0)


func check_control(control: Control) -> void:
	var viewport := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	if not control.is_visible_in_tree() or not viewport.encloses(control.get_global_rect()):
		push_error("Online control outside viewport: " + str(control.get_path()))
		failed = true


func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "user://%s-%d.png" % [label, root.size.x]
	root.get_texture().get_image().save_png(path)
	print("UI_CAPTURE: ", ProjectSettings.globalize_path(path))
