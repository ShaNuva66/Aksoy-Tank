extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var session = root.get_node("GameSession")
	var net = root.get_node("NetSession")
	var old_mode: String = session.session_mode
	session.session_mode = "online_coop"
	var menu = load("res://src/scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(1.5).timeout
	check_control(menu.start_button)
	check_control(menu._quick_match_button)
	check_control(menu.stage_row)
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
	arena._set_pause_state(true)
	await create_timer(0.3).timeout
	check_control(arena.pause_menu_button)
	check_control(arena.pause_resume_button)
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
	arena._set_pause_state(true)
	await create_timer(0.15).timeout
	if arena._online_countdown_label.visible:
		failed = true
	await capture("online-countdown-menu")
	arena._set_pause_state(false)
	if not arena._online_countdown_label.visible:
		failed = true
	arena.queue_free()
	await process_frame
	net.disconnect_session(false)
	session.session_mode = old_mode
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
