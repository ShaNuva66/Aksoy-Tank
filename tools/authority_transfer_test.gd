extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func run() -> void:
	var session = root.get_node("GameSession")
	var net = root.get_node("NetSession")
	var old_mode: String = session.session_mode
	session.session_mode = "solo"
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena.spawn_timer.stop()
	var enemy = load("res://src/scenes/enemy_tank.tscn").instantiate()
	enemy.set_replica_mode(true)
	arena.add_child(enemy)
	enemy.network_id = 900
	var snapshot: Dictionary = arena._build_world_snapshot()
	snapshot.meta.spawned = 4
	snapshot.meta.alive = 1
	snapshot.meta.wave = 2
	snapshot.walls_revision = 77
	arena._pending_network_snapshot = snapshot
	arena._session_mode = "online_coop"
	net._role = "host"
	arena._on_online_authority_changed("host", 1)
	require(arena._spawned_enemies == 4 and arena._current_wave == 2, "Promotion lost the newest pending wave state")
	require(arena._claim_network_id() > 900, "Promotion reused an existing entity ID")
	require(arena._wall_revision >= 77, "Promotion reset wall revision")
	require(enemy.destroyed.is_connected(arena._on_enemy_destroyed), "Promoted replica cannot update kill objectives")
	arena._set_pause_state(false)
	arena._session_mode = "solo"
	net.disconnect_session(false)
	arena.process_mode = Node.PROCESS_MODE_DISABLED
	arena.queue_free()
	await process_frame
	session.session_mode = old_mode
	print("AUTHORITY_TRANSFER: FAIL" if failed else "AUTHORITY_TRANSFER: PASS")
	quit(1 if failed else 0)
