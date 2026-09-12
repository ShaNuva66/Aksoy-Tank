extends SceneTree

var leader := false
var mode := "online_coop"
var server := "ws://127.0.0.1:8769/ws"
var promoted := false
var rejoined := false
var failed := false
var remote_shots := 0
var room_code := "INTEG42"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--leader":
			leader = true
		elif arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--server="):
			server = arg.trim_prefix("--server=")
		elif arg.begins_with("--room="):
			room_code = arg.trim_prefix("--room=")
	call_deferred("run")


func run() -> void:
	var net = root.get_node("NetSession")
	var session = root.get_node("GameSession")
	var old_state := [session.session_mode, session.selected_stage_index, session.unlocked_stage_count, session.onboarding_completed]
	net.status_changed.connect(func(state, message): print("NET_STATUS: ", state, " ", message))
	net.authority_changed.connect(func(_role, _slot): promoted = true)
	net.room_joined.connect(func(room, role, slot):
		rejoined = true
		print("JOIN: ", room, " ", role, " ", slot, " at=", Time.get_unix_time_from_system()))
	net.connect_to_room(server, room_code, mode)
	var deadline := Time.get_ticks_msec() + 15000
	while not net.is_peer_connected() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not net.is_peer_connected():
		push_error("Integration pairing timeout")
		quit(1)
		return
	# Internet connection ordering need not match process launch ordering.
	leader = net.is_host()
	session.session_mode = mode
	session.selected_stage_index = 2 if leader else 8
	if not leader:
		await create_timer(1.0).timeout
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await create_timer(0.5).timeout
	if not current_scene._waiting_for_peer or current_scene._spawned_enemies != 0:
		push_error("Match ran before both arenas were ready and countdown finished")
		failed = true
	await wait_for_start()
	arena = current_scene
	if int(arena._stage_data.get("index", -1)) != 2:
		push_error("Clients did not synchronize the host stage")
		failed = true
	arena._set_pause_state(true)
	if paused or not arena.pause_resume_button.can_process():
		failed = true
	arena._set_pause_state(false)
	var remote_player = arena._get_player_by_slot(2)
	var initial_rotation: float = remote_player.rotation
	if leader:
		remote_player.shot_fired.connect(func(): remote_shots += 1)
	else:
		set_key(KEY_ENTER, true)
		set_key(KEY_RIGHT, true)
	await create_timer(1.2).timeout
	if not leader:
		set_key(KEY_ENTER, false)
		set_key(KEY_RIGHT, false)
	await create_timer(0.4).timeout
	if leader and (remote_shots == 0 or absf(angle_difference(initial_rotation, remote_player.rotation)) < 0.05):
		push_error("Guest steering or firing did not execute on authority")
		failed = true
	# Exercise the actual result buttons and scene transitions on both clients.
	if leader:
		arena._winner_slot = 1
		arena._finish_match(true, "Zafer", "Integration result")
	await create_timer(1.0).timeout
	if not arena._match_over:
		push_error("Guest did not receive the final result")
		failed = true
	if mode == "online_coop":
		arena._go_to_next_stage()
	else:
		arena._on_retry_requested()
	await create_timer(2.0).timeout
	await wait_for_start()
	arena = current_scene
	var expected_stage := 3 if mode == "online_coop" else 2
	if mode == "online_vs" and (arena._vs_series.p1 != 1 or arena._vs_series.p2 != 0 or arena._vs_series.round != 2):
		push_error("VS score was lost between rounds")
		failed = true
	if arena._match_over or int(arena._stage_data.get("index", -1)) != expected_stage:
		push_error("Synchronized next round failed: stage=%s over=%s round=%s" % [arena._stage_data.get("index"), arena._match_over, net._round_id])
		failed = true
	await create_timer(0.5).timeout
	if leader:
		if mode == "online_vs":
			arena._winner_slot = 2
		arena._finish_match(false, "Kayip", "Integration retry")
	await create_timer(1.0).timeout
	arena._on_retry_requested()
	await create_timer(2.0).timeout
	await wait_for_start()
	arena = current_scene
	if arena._match_over or int(arena._stage_data.get("index", -1)) != expected_stage:
		push_error("Synchronized retry failed")
		failed = true
	rejoined = false
	if leader:
		net._socket.close()
	await create_timer(7.0).timeout
	if not net.is_peer_connected() or net.get_status() != net.STATUS_CONNECTED:
		failed = true
	if leader and not rejoined:
		failed = true
	if not leader and (not promoted or not net.is_host()):
		failed = true
	var ids := {}
	for group in ["enemy_tanks", "bullets", "pickups"]:
		for entity in get_nodes_in_group(group):
			var id: int = entity.network_id
			if id >= 0:
				if ids.has(id):
					failed = true
				ids[id] = true
	if not leader:
		arena._winner_slot = 2
		arena._finish_match(true, "Zafer", "Reconnect on result")
	await create_timer(1.0).timeout
	if leader:
		net._socket.close()
	await create_timer(5.0).timeout
	if not net.is_peer_connected() or not arena._match_over:
		push_error("Completed match was lost on guest rejoin")
		failed = true
	if mode == "online_coop" and arena._status_text != "Zafer":
		push_error("Co-op victory was overwritten by reconnect status")
		failed = true
	if mode == "online_vs":
		if arena._vs_series.p1 != 1 or arena._vs_series.p2 != 2:
			push_error("VS score was lost on host migration or result reconnect")
			failed = true
		arena._on_retry_requested()
		await create_timer(2.0).timeout
		await wait_for_start()
		arena = current_scene
		if net.is_host():
			arena._winner_slot = 2
			arena._finish_match(true, "Zafer", "Series winner")
		await create_timer(1.0).timeout
		if arena._vs_series.winner != 2 or arena._vs_series.p2 != 3:
			push_error("Third VS win did not end the series")
			failed = true
		arena._on_retry_requested()
		await create_timer(2.0).timeout
		await wait_for_start()
		arena = current_scene
		if arena._vs_series.p1 != 0 or arena._vs_series.p2 != 0 or arena._vs_series.round != 1:
			push_error("Confirmed VS rematch did not reset the score")
			failed = true
	print("NETWORK_METRICS: rtt_ms=", snappedf(net.get_latency_ms(), 0.1), " jitter_ms=", snappedf(net.get_jitter_ms(), 0.1))
	print("NETWORK_CLIENT: ", "FAIL" if failed else "PASS", " mode=", mode, " leader=", leader, " role=", net._role)
	await create_timer(2.0).timeout
	net.disconnect_session(false)
	arena.process_mode = Node.PROCESS_MODE_DISABLED
	arena.queue_free()
	await process_frame
	session.session_mode = old_state[0]
	session.selected_stage_index = old_state[1]
	session.unlocked_stage_count = old_state[2]
	session.onboarding_completed = old_state[3]
	quit(1 if failed else 0)


func wait_for_start() -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while current_scene._waiting_for_peer and Time.get_ticks_msec() < deadline:
		await process_frame
	if current_scene._waiting_for_peer:
		failed = true
		push_error("Ready/countdown did not release the arena")
	await create_timer(0.5).timeout


func set_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
