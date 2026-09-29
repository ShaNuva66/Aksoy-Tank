extends SceneTree

const PLAYER_SCENE_PATH := "res://src/scenes/player_tank.tscn"
const WALL_SCENE_PATH := "res://src/scenes/wall_block.tscn"
const TANK_SPACING_PATH := "res://src/scripts/tank_spacing.gd"
const STEP := 1.0 / 60.0

var _failed := false
var _world: Node2D
var _player_scene: PackedScene
var _wall_scene: PackedScene
var _tank_spacing


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("TANK_SEPARATION: started")
	_player_scene = load(PLAYER_SCENE_PATH) as PackedScene
	_wall_scene = load(WALL_SCENE_PATH) as PackedScene
	_tank_spacing = load(TANK_SPACING_PATH)
	_require(_player_scene != null and _wall_scene != null and _tank_spacing != null, "Required separation test resources could not load")
	if _failed:
		quit(1)
		return
	_world = Node2D.new()
	root.add_child(_world)
	current_scene = _world
	await _test_exact_overlap_separates()
	await _test_inward_drive_is_rejected()
	await _test_head_on_contact_glides_apart()
	await _test_wall_pinned_pair_can_escape()
	if _failed:
		print("TANK_SEPARATION: FAIL")
		quit(1)
	else:
		print("TANK_SEPARATION: PASS")
		quit(0)


func _test_exact_overlap_separates() -> void:
	var p1 = await _spawn_player(Vector2(480.0, 300.0), "player_1")
	var p2 = await _spawn_player(Vector2(480.0, 300.0), "player_2")
	for _frame in range(30):
		_tank_spacing.apply_soft_separation(p1, p1.get_tank_spacing_radius(), STEP)
		_tank_spacing.apply_soft_separation(p2, p2.get_tank_spacing_radius(), STEP)
		await physics_frame
	var required_distance: float = float(p1.get_tank_spacing_radius()) + float(p2.get_tank_spacing_radius()) + float(_tank_spacing.CONTACT_BUFFER)
	_require(p1.global_position.distance_to(p2.global_position) >= required_distance - 0.8, "Exactly overlapping tanks did not separate completely")
	await _clear_world()


func _test_inward_drive_is_rejected() -> void:
	var p1 = await _spawn_player(Vector2(400.0, 300.0), "player_1")
	var p2 = await _spawn_player(Vector2(440.0, 300.0), "player_2")
	var p1_adjusted: Vector2 = _tank_spacing.adjust_velocity_for_tanks(p1, Vector2.RIGHT * 220.0, p1.get_tank_spacing_radius())
	var p2_adjusted: Vector2 = _tank_spacing.adjust_velocity_for_tanks(p2, Vector2.LEFT * 220.0, p2.get_tank_spacing_radius())
	_require(p1_adjusted.x <= 0.0, "Player one can still drive deeper into an overlapping opponent")
	_require(p2_adjusted.x >= 0.0, "Player two can still drive deeper into an overlapping opponent")
	_require(p1_adjusted.length() >= _tank_spacing.MIN_ESCAPE_SPEED and p2_adjusted.length() >= _tank_spacing.MIN_ESCAPE_SPEED, "Overlap escape force is too weak to break contact")
	await _clear_world()


func _test_head_on_contact_glides_apart() -> void:
	var p1 = await _spawn_player(Vector2(400.0, 300.0), "player_1")
	var p2 = await _spawn_player(Vector2(444.0, 300.0), "player_2")
	var initial_midpoint: Vector2 = (p1.global_position + p2.global_position) * 0.5
	for _frame in range(45):
		var p1_velocity: Vector2 = _tank_spacing.adjust_velocity_for_tanks(p1, Vector2.RIGHT * 220.0, p1.get_tank_spacing_radius())
		var p2_velocity: Vector2 = _tank_spacing.adjust_velocity_for_tanks(p2, Vector2.LEFT * 220.0, p2.get_tank_spacing_radius())
		p1.global_position += p1_velocity * STEP
		p2.global_position += p2_velocity * STEP
		_tank_spacing.apply_soft_separation(p1, p1.get_tank_spacing_radius(), STEP)
		_tank_spacing.apply_soft_separation(p2, p2.get_tank_spacing_radius(), STEP)
		await physics_frame
	var required_distance: float = float(p1.get_tank_spacing_radius()) + float(p2.get_tank_spacing_radius()) + float(_tank_spacing.CONTACT_BUFFER)
	_require(p1.global_position.distance_to(p2.global_position) >= required_distance - 0.8, "Head-on tanks remained locked together")
	_require(absf(p1.global_position.y - p2.global_position.y) >= 12.0, "Head-on contact did not create a smooth side-glide route")
	_require(((p1.global_position + p2.global_position) * 0.5).distance_to(initial_midpoint) < 8.0, "Contact glide pushed the pair asymmetrically")
	await _clear_world()


func _test_wall_pinned_pair_can_escape() -> void:
	var wall = _wall_scene.instantiate()
	wall.global_position = Vector2(300.0, 300.0)
	_world.add_child(wall)
	var p1 = await _spawn_player(Vector2(342.5, 300.0), "player_1")
	var p2 = await _spawn_player(Vector2(352.0, 300.0), "player_2")
	for _frame in range(45):
		_tank_spacing.apply_soft_separation(p1, p1.get_tank_spacing_radius(), STEP)
		_tank_spacing.apply_soft_separation(p2, p2.get_tank_spacing_radius(), STEP)
		await physics_frame
	var required_distance: float = float(p1.get_tank_spacing_radius()) + float(p2.get_tank_spacing_radius()) + float(_tank_spacing.CONTACT_BUFFER)
	_require(p1.global_position.distance_to(p2.global_position) >= required_distance - 0.8, "Wall-pinned contact kept the two tanks glued")
	_require(not p1._is_wall_position_blocked(p1.global_position), "Separation pushed the pinned tank into the wall")
	_require(not p2._is_wall_position_blocked(p2.global_position), "Separation pushed the escaping tank into the wall")
	await _clear_world()


func _spawn_player(at_position: Vector2, team_name: String):
	var player = _player_scene.instantiate()
	_world.add_child(player)
	player.global_position = at_position
	player.team = team_name
	player.set_spawn_bullets_enabled(false)
	player.set_physics_process(false)
	await physics_frame
	return player


func _clear_world() -> void:
	for child in _world.get_children():
		child.queue_free()
	await physics_frame
	await physics_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("TANK_SEPARATION FAIL: " + message)
