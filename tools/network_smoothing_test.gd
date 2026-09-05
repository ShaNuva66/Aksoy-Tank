extends SceneTree

const PLAYER_PATH := "res://src/scripts/player_tank.gd"
const BULLET_PATH := "res://src/scripts/bullet.gd"
const ARENA_PATH := "res://src/scripts/prototype_arena.gd"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("NETWORK_SMOOTHING: started")
	_test_network_rates()
	await _test_remote_player_interpolation()
	await _test_local_prediction_reconciliation()
	await _test_authoritative_shot_angle()
	await _test_bullet_prediction()
	if _failed:
		print("NETWORK_SMOOTHING: FAIL")
		quit(1)
	else:
		print("NETWORK_SMOOTHING: PASS")
		quit(0)


func _test_network_rates() -> void:
	var arena = load(ARENA_PATH).new()
	var constants: Dictionary = arena.get_script().get_script_constant_map()
	arena.free()
	_require(is_equal_approx(float(constants.get("SNAPSHOT_INTERVAL", 1.0)), 0.05), "Snapshots must run at 20 Hz")
	_require(is_equal_approx(float(constants.get("INPUT_SEND_INTERVAL", 1.0)), 0.033), "Inputs must run near 30 Hz")
	_require(bool(ProjectSettings.get_setting("physics/common/physics_interpolation", false)), "Physics interpolation is disabled")


func _test_remote_player_interpolation() -> void:
	var player = load(PLAYER_PATH).new()
	root.add_child(player)
	player.set_control_mode("replica")
	player.apply_snapshot({"x": 100.0, "y": 100.0, "rotation": 0.0}, "smooth")
	player.apply_snapshot({"x": 160.0, "y": 100.0, "rotation": 0.5}, "smooth")
	_require(player.global_position.x < 160.0, "Remote player hard-snapped to the latest packet")
	player._physics_process(1.0 / 60.0)
	_require(player.global_position.x > 100.0 and player.global_position.x < 160.0, "Remote player did not interpolate")
	player.queue_free()
	await process_frame


func _test_local_prediction_reconciliation() -> void:
	var player = load(PLAYER_PATH).new()
	root.add_child(player)
	player.global_position = Vector2(100.0, 100.0)
	player.set_control_mode("external")
	player.set_external_input({"turn": 0.0, "drive": 0.0, "move_x": 0.0, "move_y": 0.0, "fire": false})
	player.apply_snapshot({"x": 140.0, "y": 100.0}, "reconcile")
	player._physics_process(1.0 / 60.0)
	_require(player.global_position.distance_to(Vector2(100.0, 100.0)) < 1.0, "Normal latency caused local snap-back")
	player.apply_snapshot({"x": 220.0, "y": 100.0}, "reconcile")
	player._physics_process(1.0 / 60.0)
	_require(player.global_position.x > 100.0 and player.global_position.x < 220.0, "Large divergence was not reconciled gradually")
	player.rotation = 0.0
	player.apply_snapshot({"x": player.global_position.x, "y": player.global_position.y, "rotation": 0.7}, "reconcile")
	for _frame in range(12):
		player._physics_process(1.0 / 60.0)
	_require(player.rotation > 0.0 and player.rotation < 0.7, "Local aim did not reconcile smoothly after steering stopped")
	player.rotation = 0.0
	player.set_control_mode("external")
	player.apply_snapshot({"x": player.global_position.x, "y": player.global_position.y, "rotation": 0.02}, "reconcile")
	for _frame in range(15):
		player._physics_process(1.0 / 60.0)
	_require(is_zero_approx(player.rotation), "Tiny network angle noise made the barrel shake")
	player.queue_free()
	await process_frame


func _test_authoritative_shot_angle() -> void:
	var player = load(PLAYER_PATH).new()
	root.add_child(player)
	player.set_control_mode("network_input")
	player.set_external_input({"turn": 1.0, "drive": 0.0, "move_x": 0.0, "move_y": 0.0, "aim_rotation": 1.2, "fire": false})
	player._physics_process(1.0 / 60.0)
	_require(absf(angle_difference(player.rotation, 1.2)) < 0.001, "Server tank drifted away from the shooter's aim")
	var captured: Dictionary = player.build_snapshot()
	_require(absf(angle_difference(float(captured.get("rotation", 0.0)), 1.2)) < 0.001, "Snapshot did not preserve the shot angle")
	player.queue_free()
	await process_frame


func _test_bullet_prediction() -> void:
	var bullet = load(BULLET_PATH).new()
	root.add_child(bullet)
	bullet.set_replica_mode(true)
	bullet.apply_snapshot({"id": 1, "x": 100.0, "y": 100.0, "rotation": 0.0, "velocity_x": 300.0, "velocity_y": 0.0})
	bullet._physics_process(1.0 / 60.0)
	_require(bullet.global_position.x > 100.0, "Replica bullet did not predict between packets")
	var start_x: float = bullet.global_position.x
	for frame in range(12):
		bullet._physics_process(1.0 / 60.0)
	_require(absf(bullet.global_position.x - start_x - 60.0) < 0.01, "Replica bullet slowed toward an obsolete target between packets")
	bullet.apply_snapshot({"id": 1, "x": 100.0, "y": 100.0, "rotation": 0.0, "velocity_x": 300.0, "velocity_y": 0.0})
	bullet.global_position = Vector2(105.0, 100.0)
	bullet.apply_snapshot({"id": 1, "x": 112.0, "y": 100.0, "rotation": 0.0, "velocity_x": 300.0, "velocity_y": 0.0})
	_require(bullet.global_position.x < 112.0, "Replica bullet hard-snapped to a normal correction")
	bullet.queue_free()
	await process_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("NETWORK_SMOOTHING FAIL: " + message)
