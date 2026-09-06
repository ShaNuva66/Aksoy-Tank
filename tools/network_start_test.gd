extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var net = root.get_node("NetSession")
	var session = root.get_node("GameSession")
	var old_mode: String = session.session_mode
	session.session_mode = "online_coop"
	net._role = "host"
	net._status = net.STATUS_CONNECTED
	net._peer_connected = true
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	# Drive the countdown deterministically while entity physics stays frozen.
	arena.set_physics_process(false)
	check(arena._waiting_for_peer and not arena._get_local_player().can_process(), "Initial arena was not frozen")
	var token: int = arena._online_ready_token
	net._remote_inputs[2] = {"ready_token": token - 1}
	net._remote_input_times[2] = Time.get_ticks_msec()
	arena._tick_online_start(10.0)
	check(arena._online_start_remaining < 0.0, "Stale arena acknowledgement started match")
	net._remote_inputs[2] = {"ready_token": token}
	net._remote_input_times[2] = Time.get_ticks_msec() - 1000
	arena._tick_online_start(10.0)
	check(arena._online_start_remaining < 0.0, "Expired acknowledgement started match")
	net._remote_input_times[2] = Time.get_ticks_msec()
	arena._tick_online_start(0.1)
	check(arena._online_start_remaining == 3.0, "Valid acknowledgement did not start three-second countdown")
	arena._set_pause_state(true)
	check(not arena._online_countdown_label.visible, "Countdown overlapped match menu")
	arena._tick_online_start(1.0)
	check(not arena._online_countdown_label.visible, "Next countdown number reappeared over menu")
	arena._set_pause_state(false)
	check(arena._online_countdown_label.visible, "Countdown failed to return after menu")
	arena._tick_online_start(1.9)
	check(arena._waiting_for_peer and arena._spawned_enemies == 0, "Simulation began during countdown")
	arena._tick_online_start(0.2)
	check(not arena._waiting_for_peer and arena._get_local_player().can_process(), "Countdown did not release simulation")
	arena._stop_match_entities()
	check(not arena._online_countdown_label.visible, "Countdown overlapped result")
	arena._on_online_peer_status_changed(false, 1)
	check(arena._waiting_for_peer and arena._online_start_remaining < 0.0 and arena._online_ready_token != token, "Disconnect did not invalidate readiness")
	arena._match_over = true
	var result_token: int = arena._online_ready_token
	arena._reset_online_start()
	check(arena._online_ready_token == result_token, "Result screen restarted countdown")
	arena.queue_free()
	await process_frame
	net.disconnect_session(false)
	session.session_mode = old_mode
	print("NETWORK_START: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
