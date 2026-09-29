extends SceneTree

var notifications := 0


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var net = root.get_node("NetSession")
	net.disconnect_session(false)
	net.snapshot_updated.connect(func():
		notifications += 1
		var snapshot: Dictionary = net.get_latest_snapshot()
		assert(not snapshot.is_empty()))
	var walls := []
	var enemies := []
	for i in range(120):
		walls.append({"name": "Wall_%d_1" % i, "durability": 7, "block_type": "brick"})
	for i in range(30):
		enemies.append({"id": i, "type": "boss_storm", "x": 20.0 * i, "y": 100.0, "health": 14})
	var full := JSON.stringify({"type": "snapshot", "payload": {"walls": walls, "walls_changed": true, "walls_revision": 1, "enemies": enemies, "meta": {"round_id": 0}}})
	var delta := JSON.stringify({"type": "snapshot", "payload": {"walls": [], "walls_changed": false, "walls_revision": 1, "enemies": enemies, "meta": {"round_id": 0}}})
	var start := Time.get_ticks_usec()
	for batch in range(100):
		var batched := "--batch" in OS.get_cmdline_user_args()
		if batched:
			net._polling_packets = true
		net._handle_message(full)
		for i in range(9):
			net._handle_message(delta)
		if batched:
			net._polling_packets = false
			net._flush_snapshot_notification()
	var elapsed := Time.get_ticks_usec() - start
	print("PACKET_BENCH: packets=1000 notifications=%d elapsed_us=%d" % [notifications, elapsed])
	var expected := 100 if "--batch" in OS.get_cmdline_user_args() else 1000
	net.disconnect_session(false)
	quit(0 if notifications == expected else 1)
