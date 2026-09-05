extends SceneTree

var leader := false
var mode := "online_coop"
var server := "ws://127.0.0.1:8769/ws"
var promoted := false
var rejoined := false
var failed := false


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--leader":
			leader = true
		elif arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--server="):
			server = arg.trim_prefix("--server=")
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
	net.connect_to_room(server, "INTEG42", mode)
	var deadline := Time.get_ticks_msec() + 15000
	while not net.is_peer_connected() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not net.is_peer_connected():
		push_error("Integration pairing timeout")
		quit(1)
		return
	session.session_mode = mode
	session.selected_stage_index = 2
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await create_timer(2.0).timeout
	arena._set_pause_state(true)
	if paused or not arena.pause_resume_button.can_process():
		failed = true
	arena._set_pause_state(false)
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
