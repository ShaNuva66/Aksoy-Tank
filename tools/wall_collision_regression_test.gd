extends SceneTree

const PLAYER_SCENE_PATH := "res://src/scenes/player_tank.tscn"
const WALL_SCENE_PATH := "res://src/scenes/wall_block.tscn"

var _failed := false
var _world: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("WALL_COLLISION: started")
	_world = Node2D.new()
	root.add_child(_world)
	current_scene = _world
	_spawn_wall(Vector2(320.0, 240.0))
	_spawn_wall(Vector2(320.0, 288.0))
	await _wait_physics_frames(2)
	await _test_direct_wall_pressure()
	await _test_wall_seam_is_closed()
	await _test_corner_escape()
	await _test_network_correction_cannot_enter_wall()
	await _test_replica_cannot_cut_through_wall()
	if _failed:
		print("WALL_COLLISION: FAIL")
		quit(1)
	else:
		print("WALL_COLLISION: PASS")
		quit(0)


func _test_direct_wall_pressure() -> void:
	var player = await _make_player(Vector2(260.0, 240.0), "network_input")
	player.set_external_input(_input_state(PI * 0.5, 1.0))
	for _frame in range(150):
		player._physics_process(1.0 / 60.0)
		_require(not player._is_wall_position_blocked(player.global_position), "Tank entered a wall under continuous pressure")
	_require(player.global_position.x <= 278.5, "Tank crossed the wall face")
	await _remove_player(player)


func _test_wall_seam_is_closed() -> void:
	var player = await _make_player(Vector2(260.0, 264.0), "network_input")
	player.set_external_input(_input_state(PI * 0.5, 1.0))
	for _frame in range(150):
		player._physics_process(1.0 / 60.0)
		_require(not player._is_wall_position_blocked(player.global_position), "Tank entered the seam between adjacent walls")
	_require(player.global_position.x <= 278.5, "Tank leaked through a wall seam")
	await _remove_player(player)


func _test_corner_escape() -> void:
	var player = await _make_player(Vector2(270.0, 190.0), "network_input")
	player.set_external_input({"turn": 0.0, "drive": 0.0, "move_x": 1.0, "move_y": 1.0, "aim_rotation": 2.35, "fire": false})
	for _frame in range(90):
		player._physics_process(1.0 / 60.0)
		_require(not player._is_wall_position_blocked(player.global_position), "Diagonal corner movement embedded the tank")
	var corner_position: Vector2 = player.global_position
	player.set_external_input({"turn": 0.0, "drive": 0.0, "move_x": -1.0, "move_y": -1.0, "aim_rotation": -0.78, "fire": false})
	for _frame in range(30):
		player._physics_process(1.0 / 60.0)
	_require(player.global_position.distance_to(corner_position) > 24.0, "Tank remained stuck after steering away from a corner")
	_require(not player._is_wall_position_blocked(player.global_position), "Corner escape left the tank overlapping a wall")
	await _remove_player(player)


func _test_network_correction_cannot_enter_wall() -> void:
	var player = await _make_player(Vector2(260.0, 240.0), "external")
	player.set_external_input(_input_state(0.0, 0.0))
	for frame in range(180):
		if frame % 3 == 0:
			player.apply_snapshot({"x": 380.0, "y": 240.0, "rotation": 0.0}, "reconcile")
		player._physics_process(1.0 / 60.0)
		_require(not player._is_wall_position_blocked(player.global_position), "Network reconciliation pushed the local tank into a wall")
	_require(player.global_position.x <= 278.5, "Network reconciliation crossed a solid wall")
	await _remove_player(player)


func _test_replica_cannot_cut_through_wall() -> void:
	var player = await _make_player(Vector2(260.0, 240.0), "replica")
	player.apply_snapshot({"x": 260.0, "y": 240.0, "rotation": 0.0}, "smooth")
	player.apply_snapshot({"x": 380.0, "y": 240.0, "rotation": 0.0}, "smooth")
	for _frame in range(120):
		player._physics_process(1.0 / 60.0)
		_require(not player._is_wall_position_blocked(player.global_position), "Remote interpolation cut through a wall")
	_require(player.global_position.x <= 278.5, "Remote tank crossed a wall that still exists locally")
	await _remove_player(player)


func _make_player(at_position: Vector2, mode: String):
	var player = load(PLAYER_SCENE_PATH).instantiate()
	_world.add_child(player)
	player.global_position = at_position
	player.set_control_mode(mode)
	player.set_spawn_bullets_enabled(false)
	player.set_physics_process(false)
	await _wait_physics_frames(1)
	return player


func _spawn_wall(at_position: Vector2) -> void:
	var wall = load(WALL_SCENE_PATH).instantiate()
	wall.position = at_position
	_world.add_child(wall)


func _input_state(aim_rotation: float, drive: float) -> Dictionary:
	return {"turn": 0.0, "drive": drive, "move_x": 0.0, "move_y": 0.0, "aim_rotation": aim_rotation, "fire": false}


func _remove_player(player: Node) -> void:
	player.queue_free()
	await _wait_physics_frames(1)


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("WALL_COLLISION FAIL: " + message)
