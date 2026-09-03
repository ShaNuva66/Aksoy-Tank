extends SceneTree

const PLAYER_SCENE_PATH := "res://src/scenes/player_tank.tscn"
const ENEMY_SCENE_PATH := "res://src/scenes/enemy_tank.tscn"
const BULLET_SCENE_PATH := "res://src/scenes/bullet.tscn"
const WALL_SCENE_PATH := "res://src/scenes/wall_block.tscn"

var _failed := false
var _world: Node2D
var _player_scene: PackedScene
var _enemy_scene: PackedScene
var _bullet_scene: PackedScene
var _wall_scene: PackedScene


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("HITBOX: professional collision audit started")
	# Load after SceneTree initialization so project autoloads are registered.
	_player_scene = load(PLAYER_SCENE_PATH) as PackedScene
	_enemy_scene = load(ENEMY_SCENE_PATH) as PackedScene
	_bullet_scene = load(BULLET_SCENE_PATH) as PackedScene
	_wall_scene = load(WALL_SCENE_PATH) as PackedScene
	_require(_player_scene != null, "Player scene could not be loaded")
	_require(_enemy_scene != null, "Enemy scene could not be loaded")
	_require(_bullet_scene != null, "Bullet scene could not be loaded")
	_require(_wall_scene != null, "Wall scene could not be loaded")
	if _failed:
		print("HITBOX: FAIL")
		quit(1)
		return
	_world = Node2D.new()
	root.add_child(_world)
	current_scene = _world
	await _test_shape_alignment()
	await _test_high_speed_direct_hit()
	await _test_point_blank_spawn_sweep()
	await _test_visible_edge_hit()
	await _test_near_miss_stays_clean()
	await _test_wall_always_wins_occlusion()
	await _test_friendly_projectile_passes_safely()
	if _failed:
		print("HITBOX: FAIL")
		quit(1)
	else:
		print("HITBOX: PASS")
		quit(0)


func _test_shape_alignment() -> void:
	var player = _player_scene.instantiate()
	_world.add_child(player)
	player.set_physics_process(false)
	var player_shape := player.get_node("Hurtbox/CollisionShape2D").shape as CapsuleShape2D
	_require(player_shape != null, "Player damage hurtbox is missing")
	if player_shape:
		_require(is_equal_approx(player_shape.radius, 21.0) and is_equal_approx(player_shape.height, 48.0), "Player hurtbox does not match the visible chassis")
	var boss = _enemy_scene.instantiate()
	boss.configure("boss_final")
	_world.add_child(boss)
	boss.set_physics_process(false)
	var boss_shape := boss.get_node("Hurtbox/CollisionShape2D").shape as CapsuleShape2D
	var expected_size: Vector2 = boss.get_damage_hitbox_size()
	_require(boss_shape != null, "Boss damage hurtbox is missing")
	if boss_shape:
		_require(is_equal_approx(boss_shape.radius * 2.0, expected_size.x), "Boss hurtbox width does not scale with its visual body")
		_require(is_equal_approx(boss_shape.height, expected_size.y), "Boss hurtbox height does not scale with its visual body")
	player.queue_free()
	boss.queue_free()
	await _wait_physics_frames(2)


func _test_high_speed_direct_hit() -> void:
	var player = await _spawn_player(Vector2(360.0, 240.0), "player_target")
	var bullet = await _spawn_bullet(Vector2(120.0, 240.0), Vector2.RIGHT, "attacker", 1200.0)
	bullet._physics_process(0.25)
	_require(player.health == player.max_health - 1, "High-speed projectile tunneled through the tank")
	_require(bullet._spent, "High-speed hit did not consume the projectile")
	await _clear_case()


func _test_point_blank_spawn_sweep() -> void:
	var player = await _spawn_player(Vector2(210.0, 240.0), "player_target")
	var bullet = await _spawn_bullet(Vector2(242.0, 240.0), Vector2.RIGHT, "attacker", 620.0, Vector2(200.0, 240.0))
	bullet._physics_process(1.0 / 60.0)
	_require(player.health == player.max_health - 1, "Point-blank muzzle position skipped the overlapping opponent")
	_require(bullet._spent, "Point-blank confirmed hit did not consume the projectile")
	await _clear_case()


func _test_visible_edge_hit() -> void:
	var player = await _spawn_player(Vector2(340.0, 240.0), "player_target")
	var bullet = await _spawn_bullet(Vector2(180.0, 260.0), Vector2.RIGHT, "attacker", 900.0)
	bullet._physics_process(0.24)
	_require(player.health == player.max_health - 1, "Projectile touching the visible chassis edge was not counted")
	await _clear_case()


func _test_near_miss_stays_clean() -> void:
	var player = await _spawn_player(Vector2(340.0, 240.0), "player_target")
	var bullet = await _spawn_bullet(Vector2(180.0, 270.5), Vector2.RIGHT, "attacker", 900.0)
	bullet._physics_process(0.24)
	_require(player.health == player.max_health, "A visually clear near miss caused damage")
	_require(not bullet._spent, "Near-miss projectile was incorrectly consumed")
	await _clear_case()


func _test_wall_always_wins_occlusion() -> void:
	var wall = _wall_scene.instantiate()
	wall.global_position = Vector2(280.0, 240.0)
	_world.add_child(wall)
	var player = await _spawn_player(Vector2(318.0, 240.0), "player_target")
	var bullet = await _spawn_bullet(Vector2(180.0, 240.0), Vector2.RIGHT, "attacker", 1000.0)
	bullet._physics_process(0.2)
	_require(player.health == player.max_health, "Tank was damaged through solid cover")
	_require(bullet._spent, "Projectile did not stop on solid cover")
	await _clear_case()


func _test_friendly_projectile_passes_safely() -> void:
	var player = await _spawn_player(Vector2(300.0, 240.0), "allies")
	var bullet = await _spawn_bullet(Vector2(220.0, 240.0), Vector2.RIGHT, "allies", 700.0)
	bullet._physics_process(0.2)
	_require(player.health == player.max_health, "Friendly projectile damaged its own team")
	_require(not bullet._spent, "Friendly projectile was consumed by its own team")
	_require(bullet.global_position.x > player.global_position.x, "Friendly projectile did not pass through its teammate")
	await _clear_case()


func _spawn_player(at_position: Vector2, team_name: String):
	var player = _player_scene.instantiate()
	_world.add_child(player)
	player.global_position = at_position
	player.team = team_name
	player.set_spawn_bullets_enabled(false)
	player.set_physics_process(false)
	await _wait_physics_frames(2)
	return player


func _spawn_bullet(at_position: Vector2, travel_direction: Vector2, team_name: String, travel_speed: float, sweep_origin := Vector2(INF, INF)):
	var bullet = _bullet_scene.instantiate()
	bullet.global_position = at_position
	bullet.direction = travel_direction
	bullet.rotation = travel_direction.angle() + PI * 0.5
	bullet.owner_team = team_name
	bullet.speed = travel_speed
	_world.add_child(bullet)
	bullet.set_physics_process(false)
	if sweep_origin.is_finite():
		bullet.set_spawn_sweep_origin(sweep_origin)
	await _wait_physics_frames(2)
	return bullet


func _clear_case() -> void:
	for child in _world.get_children():
		child.queue_free()
	await _wait_physics_frames(2)


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("HITBOX FAIL: " + message)
