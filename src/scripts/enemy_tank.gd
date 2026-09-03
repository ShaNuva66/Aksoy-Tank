extends CharacterBody2D

signal destroyed(enemy_type: String, at_position: Vector2)

const BULLET_SCENE := preload("res://src/scenes/bullet.tscn")
const TankSpacing := preload("res://src/scripts/tank_spacing.gd")
const TARGET_REFRESH_INTERVAL := 0.28
const AIM_SETTLE_TIME := 0.3
const VOLLEY_RECOVERY_MIN := 0.18
const VOLLEY_RECOVERY_MAX := 0.42
const PROFILES := {
	"grunt": {
		"speed": 140.0,
		"health": 1,
		"aggression": 0.55,
		"bullet_speed": 560.0,
		"fire_min": 1.45,
		"fire_max": 2.35,
		"decision_min": 0.8,
		"decision_max": 1.8,
		"aim_tolerance": 26.0,
		"body_color": "#d96c6c",
		"turret_color": "#f2d48f",
		"track_color": "#522f3a",
		"visual_scale": 1.0,
		"collider_radius": 18.0,
		"engine_color": "#ffb36b",
		"bob_amount": 0.35
	},
	"scout": {
		"speed": 195.0,
		"health": 1,
		"aggression": 0.4,
		"bullet_speed": 620.0,
		"fire_min": 1.85,
		"fire_max": 2.7,
		"decision_min": 0.45,
		"decision_max": 1.0,
		"aim_tolerance": 18.0,
		"body_color": "#6db5d9",
		"turret_color": "#d8f3ff",
		"track_color": "#24445d",
		"visual_scale": 0.96,
		"collider_radius": 17.0,
		"engine_color": "#96ecff",
		"bob_amount": 0.58
	},
	"brute": {
		"speed": 105.0,
		"health": 2,
		"aggression": 0.72,
		"bullet_speed": 530.0,
		"fire_min": 1.55,
		"fire_max": 2.2,
		"decision_min": 0.95,
		"decision_max": 1.7,
		"aim_tolerance": 32.0,
		"body_color": "#b86f3c",
		"turret_color": "#ffd79b",
		"track_color": "#5d331c",
		"visual_scale": 1.08,
		"collider_radius": 19.0,
		"engine_color": "#ffcf7f",
		"bob_amount": 0.22
	},
	"sniper": {
		"speed": 120.0,
		"health": 1,
		"aggression": 0.92,
		"bullet_speed": 760.0,
		"fire_min": 1.25,
		"fire_max": 1.9,
		"decision_min": 0.65,
		"decision_max": 1.2,
		"aim_tolerance": 20.0,
		"body_color": "#8a7cf0",
		"turret_color": "#efe6ff",
		"track_color": "#33295f",
		"burst_count": 1,
		"burst_spread": 0.0,
		"projectile_scale": 1.0,
		"visual_scale": 1.02,
		"collider_radius": 18.0,
		"engine_color": "#c7b8ff",
		"bob_amount": 0.26
	},
	"volley": {
		"speed": 162.0,
		"health": 1,
		"aggression": 0.82,
		"bullet_speed": 610.0,
		"fire_min": 1.0,
		"fire_max": 1.45,
		"decision_min": 0.42,
		"decision_max": 0.9,
		"aim_tolerance": 28.0,
		"body_color": "#d34f4f",
		"turret_color": "#ffe0a6",
		"track_color": "#532126",
		"burst_count": 2,
		"burst_spread": 0.14,
		"projectile_scale": 0.96,
		"visual_scale": 1.1,
		"collider_radius": 19.0,
		"engine_color": "#ff9a84",
		"bob_amount": 0.44
	},
	"warden": {
		"speed": 118.0,
		"health": 3,
		"aggression": 0.86,
		"bullet_speed": 620.0,
		"fire_min": 1.18,
		"fire_max": 1.72,
		"decision_min": 0.55,
		"decision_max": 1.1,
		"aim_tolerance": 30.0,
		"body_color": "#3d414d",
		"turret_color": "#d7c38b",
		"track_color": "#171a1f",
		"burst_count": 1,
		"burst_spread": 0.0,
		"projectile_scale": 1.18,
		"visual_scale": 1.24,
		"collider_radius": 22.0,
		"engine_color": "#e2c98a",
		"bob_amount": 0.28
	},
	"boss": {
		"speed": 96.0,
		"health": 6,
		"aggression": 0.98,
		"bullet_speed": 690.0,
		"fire_min": 0.92,
		"fire_max": 1.28,
		"decision_min": 0.35,
		"decision_max": 0.82,
		"aim_tolerance": 36.0,
		"body_color": "#15171e",
		"turret_color": "#ffb85c",
		"track_color": "#40321d",
		"burst_count": 3,
		"burst_spread": 0.2,
		"projectile_scale": 1.34,
		"visual_scale": 1.44,
		"collider_radius": 26.0,
		"engine_color": "#ffae4f",
		"bob_amount": 0.36,
		"damage": 1
	},
	"boss_raider": {
		"speed": 118.0,
		"health": 7,
		"aggression": 0.96,
		"bullet_speed": 700.0,
		"fire_min": 0.95,
		"fire_max": 1.3,
		"decision_min": 0.32,
		"decision_max": 0.72,
		"aim_tolerance": 32.0,
		"body_color": "#171c24",
		"turret_color": "#7ee0ff",
		"track_color": "#183844",
		"burst_count": 2,
		"burst_spread": 0.18,
		"projectile_scale": 1.28,
		"visual_scale": 1.5,
		"collider_radius": 27.0,
		"engine_color": "#6ce6ff",
		"bob_amount": 0.5,
		"damage": 1
	},
	"boss_hunter": {
		"speed": 90.0,
		"health": 8,
		"aggression": 1.0,
		"bullet_speed": 840.0,
		"fire_min": 1.12,
		"fire_max": 1.48,
		"decision_min": 0.36,
		"decision_max": 0.82,
		"aim_tolerance": 22.0,
		"body_color": "#1a1628",
		"turret_color": "#c7a7ff",
		"track_color": "#31204f",
		"burst_count": 1,
		"burst_spread": 0.0,
		"projectile_scale": 1.72,
		"visual_scale": 1.58,
		"collider_radius": 29.0,
		"engine_color": "#b98dff",
		"bob_amount": 0.32,
		"damage": 2
	},
	"boss_bulwark": {
		"speed": 76.0,
		"health": 10,
		"aggression": 0.92,
		"bullet_speed": 650.0,
		"fire_min": 1.18,
		"fire_max": 1.62,
		"decision_min": 0.48,
		"decision_max": 1.05,
		"aim_tolerance": 46.0,
		"body_color": "#20251f",
		"turret_color": "#b9e27d",
		"track_color": "#293b1e",
		"burst_count": 2,
		"burst_spread": 0.28,
		"projectile_scale": 1.62,
		"visual_scale": 1.72,
		"collider_radius": 32.0,
		"engine_color": "#abe36d",
		"bob_amount": 0.22,
		"damage": 2
	},
	"boss_siege": {
		"speed": 82.0,
		"health": 9,
		"aggression": 0.98,
		"bullet_speed": 720.0,
		"fire_min": 1.05,
		"fire_max": 1.38,
		"decision_min": 0.38,
		"decision_max": 0.9,
		"aim_tolerance": 40.0,
		"body_color": "#1f2028",
		"turret_color": "#ff944d",
		"track_color": "#4d2718",
		"burst_count": 3,
		"burst_spread": 0.24,
		"projectile_scale": 1.55,
		"visual_scale": 1.68,
		"collider_radius": 31.0,
		"engine_color": "#ff894f",
		"bob_amount": 0.42,
		"damage": 2
	},
	"boss_needle": {
		"speed": 104.0,
		"health": 11,
		"aggression": 1.0,
		"bullet_speed": 780.0,
		"fire_min": 0.9,
		"fire_max": 1.18,
		"decision_min": 0.3,
		"decision_max": 0.7,
		"aim_tolerance": 26.0,
		"body_color": "#201721",
		"turret_color": "#ff83bd",
		"track_color": "#4b1b35",
		"burst_count": 3,
		"burst_spread": 0.1,
		"projectile_scale": 1.48,
		"visual_scale": 1.78,
		"collider_radius": 33.0,
		"engine_color": "#ff77aa",
		"bob_amount": 0.58,
		"damage": 2
	},
	"boss_titan": {
		"speed": 70.0,
		"health": 13,
		"aggression": 1.0,
		"bullet_speed": 760.0,
		"fire_min": 1.18,
		"fire_max": 1.52,
		"decision_min": 0.42,
		"decision_max": 0.95,
		"aim_tolerance": 44.0,
		"body_color": "#101116",
		"turret_color": "#ffcf73",
		"track_color": "#3b2a12",
		"burst_count": 4,
		"burst_spread": 0.22,
		"projectile_scale": 1.78,
		"visual_scale": 1.92,
		"collider_radius": 36.0,
		"engine_color": "#ffc247",
		"bob_amount": 0.48,
		"damage": 2
	},
	"boss_storm": {
		"speed": 112.0,
		"health": 14,
		"aggression": 1.0,
		"bullet_speed": 735.0,
		"fire_min": 0.86,
		"fire_max": 1.16,
		"decision_min": 0.28,
		"decision_max": 0.68,
		"aim_tolerance": 38.0,
		"body_color": "#101d28",
		"turret_color": "#8ff4d8",
		"track_color": "#113a38",
		"burst_count": 4,
		"burst_spread": 0.28,
		"projectile_scale": 1.7,
		"visual_scale": 1.98,
		"collider_radius": 37.0,
		"engine_color": "#6dffd9",
		"bob_amount": 0.62,
		"damage": 2
	},
	"boss_crown": {
		"speed": 66.0,
		"health": 16,
		"aggression": 1.0,
		"bullet_speed": 790.0,
		"fire_min": 1.08,
		"fire_max": 1.42,
		"decision_min": 0.38,
		"decision_max": 0.86,
		"aim_tolerance": 48.0,
		"body_color": "#151017",
		"turret_color": "#ffd96a",
		"track_color": "#3e2811",
		"burst_count": 4,
		"burst_spread": 0.18,
		"projectile_scale": 1.92,
		"visual_scale": 2.08,
		"collider_radius": 40.0,
		"engine_color": "#ffbf3f",
		"bob_amount": 0.48,
		"damage": 3
	},
	"boss_final": {
		"speed": 60.0,
		"health": 18,
		"aggression": 1.0,
		"bullet_speed": 800.0,
		"fire_min": 1.32,
		"fire_max": 1.68,
		"decision_min": 0.46,
		"decision_max": 1.0,
		"aim_tolerance": 50.0,
		"body_color": "#08090d",
		"turret_color": "#ffe18a",
		"track_color": "#2f2210",
		"burst_count": 5,
		"burst_spread": 0.2,
		"projectile_scale": 2.05,
		"visual_scale": 2.18,
		"collider_radius": 42.0,
		"engine_color": "#ffd15c",
		"bob_amount": 0.55,
		"damage": 3
	}
}

var enemy_type: String = "grunt"
var team: String = "enemy"
var network_id: int = -1
var health: int = 1
var replica_mode := false
var _move_direction: Vector2 = Vector2.DOWN
var _direction_timer: float = 0.0
var _fire_timer: float = 1.2
var _rng := RandomNumberGenerator.new()
var _speed: float = 140.0
var _aggression: float = 0.55
var _bullet_speed: float = 560.0
var _fire_min: float = 1.0
var _fire_max: float = 1.8
var _decision_min: float = 0.8
var _decision_max: float = 1.8
var _aim_tolerance: float = 26.0
var _body_color := Color("#d96c6c")
var _turret_color := Color("#f2d48f")
var _track_color := Color("#522f3a")
var _burst_count := 1
var _burst_spread := 0.0
var _projectile_scale := 1.0
var _damage := 1
var _visual_scale := 1.0
var _collider_radius := 18.0
var _engine_color := Color("#ffb36b")
var _bob_amount := 0.35
var _flash_time := 0.0
var _arena: Node = null
var _target_player: Node2D = null
var _target_refresh_timer := 0.0
var _lane_lock_time := 0.0
var _anim_time := 0.0
var _recoil_time := 0.0


func _ready() -> void:
	add_to_group("enemy_tanks")
	add_to_group("tanks")
	collision_layer = 1
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = 0.2
	max_slides = 8
	_arena = get_tree().current_scene
	_rng.randomize()
	_apply_profile()
	_refresh_target_player()
	_pick_new_direction()
	_fire_timer = _rng.randf_range(_fire_min * 0.95, _fire_max * 1.15)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta * (1.8 + _speed / 180.0)
	_recoil_time = maxf(_recoil_time - delta * 4.5, 0.0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if replica_mode:
		return

	_flash_time = max(_flash_time - delta, 0.0)
	if _flash_time > 0.0:
		queue_redraw()

	_direction_timer -= delta
	_fire_timer -= delta
	_target_refresh_timer -= delta

	if _target_refresh_timer <= 0.0 or not is_instance_valid(_target_player):
		_refresh_target_player()

	if _direction_timer <= 0.0:
		_pick_new_direction()

	if _should_hunt_player():
		_face_player_lane()
		_lane_lock_time = minf(_lane_lock_time + delta, AIM_SETTLE_TIME + 0.5)
		if _lane_lock_time >= AIM_SETTLE_TIME:
			_fire_timer = min(_fire_timer, 0.36)
	else:
		_lane_lock_time = maxf(_lane_lock_time - delta * 2.4, 0.0)

	rotation = Vector2.UP.angle_to(_move_direction)
	var desired_velocity := _move_direction * _speed
	velocity = TankSpacing.adjust_velocity_for_tanks(self, desired_velocity, get_tank_spacing_radius())
	move_and_slide()
	TankSpacing.apply_soft_separation(self, get_tank_spacing_radius(), delta)
	if desired_velocity.length_squared() > 0.0 and velocity.dot(desired_velocity.normalized()) < _speed * 0.2:
		_direction_timer = 0.0

	if get_slide_collision_count() > 0:
		_pick_new_direction()

	if _fire_timer <= 0.0:
		_fire()


func _draw() -> void:
	var body_rect := Rect2(Vector2(-22.0, -24.0), Vector2(44.0, 48.0))
	if enemy_type == "brute":
		body_rect = Rect2(Vector2(-24.0, -26.0), Vector2(48.0, 52.0))
	elif enemy_type == "scout":
		body_rect = Rect2(Vector2(-20.0, -22.0), Vector2(40.0, 44.0))
	elif enemy_type == "warden":
		body_rect = Rect2(Vector2(-25.0, -27.0), Vector2(50.0, 54.0))
	elif _is_boss_type():
		body_rect = Rect2(Vector2(-28.0, -31.0), Vector2(56.0, 62.0))

	var flash_mix: float = 0.0 if _flash_time <= 0.0 else min(_flash_time * 8.0, 1.0)
	var bob_offset := sin(_anim_time * 1.9) * _bob_amount
	var engine_glow := _engine_color
	engine_glow.a = 0.18 + absf(sin(_anim_time * 5.6)) * 0.08
	draw_set_transform(Vector2(0.0, bob_offset), 0.0, Vector2(_visual_scale, _visual_scale))
	draw_circle(Vector2(0.0, 19.0), 16.0, engine_glow)
	draw_circle(Vector2(-10.0, 21.0), 7.0, engine_glow.darkened(0.08))
	draw_circle(Vector2(10.0, 21.0), 7.0, engine_glow.darkened(0.08))
	draw_rect(body_rect, _body_color.lerp(Color.WHITE, flash_mix))
	var turret_height := 28.0 if not _is_boss_type() else 34.0
	var turret_rect := Rect2(Vector2(-8.0, -34.0 + _recoil_time * 6.0), Vector2(16.0, turret_height))
	draw_rect(turret_rect, _turret_color.lerp(Color.WHITE, flash_mix))
	draw_rect(Rect2(Vector2(-18.0, -18.0), Vector2(6.0, 36.0)), _track_color)
	draw_rect(Rect2(Vector2(12.0, -18.0), Vector2(6.0, 36.0)), _track_color)
	draw_circle(Vector2.ZERO, 8.0, _track_color)
	draw_line(Vector2(-9.0, 14.0), Vector2(-14.0, 28.0 + absf(sin(_anim_time * 6.8)) * 4.0), _engine_color, 3.0)
	draw_line(Vector2(9.0, 14.0), Vector2(14.0, 28.0 + absf(sin(_anim_time * 6.8 + 0.7)) * 4.0), _engine_color, 3.0)

	if enemy_type == "warden":
		draw_rect(Rect2(Vector2(-12.0, -12.0), Vector2(24.0, 10.0)), Color("#6b7283"))
	elif _is_boss_type():
		draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 36, Color("#ffcf7d"), 3.0)
		draw_circle(Vector2(0.0, -4.0), 4.0, Color("#ffefc0"))
		draw_arc(Vector2.ZERO, 36.0 + sin(_anim_time * 2.2) * 1.4, 0.0, TAU, 42, Color(1.0, 0.72, 0.38, 0.5), 2.0)

	if health > 1:
		for pip_index in range(mini(health - 1, 5)):
			draw_circle(Vector2(-8.0 + pip_index * 10.0, -32.0), 3.0, Color("#fff3d0"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func get_team() -> String:
	return team


func get_tank_collision_radius() -> float:
	return _collider_radius


func get_damage_hitbox_size() -> Vector2:
	var body_size := Vector2(44.0, 48.0)
	if enemy_type == "brute":
		body_size = Vector2(48.0, 52.0)
	elif enemy_type == "scout":
		body_size = Vector2(40.0, 44.0)
	elif enemy_type == "warden":
		body_size = Vector2(50.0, 54.0)
	elif _is_boss_type():
		body_size = Vector2(56.0, 62.0)
	return body_size * _visual_scale * 0.9


func get_tank_spacing_radius() -> float:
	return maxf(_collider_radius, get_damage_hitbox_size().x * 0.5)


func take_hit(_source_team: String = "", damage: int = 1) -> bool:
	health = max(health - maxi(damage, 1), 0)
	_flash_time = 0.12
	queue_redraw()

	if health <= 0:
		_emit_combat_feedback()
		destroyed.emit(enemy_type, global_position)
		queue_free()

	return true


func configure(new_enemy_type: String) -> void:
	enemy_type = new_enemy_type
	_apply_profile()
	queue_redraw()


func set_replica_mode(enabled: bool) -> void:
	replica_mode = enabled
	set_physics_process(not enabled)


func build_snapshot() -> Dictionary:
	return {
		"id": network_id,
		"type": enemy_type,
		"x": global_position.x,
		"y": global_position.y,
		"rotation": rotation,
		"health": health
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	if enemy_type != String(snapshot.get("type", enemy_type)):
		configure(String(snapshot.get("type", enemy_type)))

	network_id = int(snapshot.get("id", network_id))
	global_position = Vector2(float(snapshot.get("x", global_position.x)), float(snapshot.get("y", global_position.y)))
	rotation = float(snapshot.get("rotation", rotation))
	health = int(snapshot.get("health", health))
	queue_redraw()


func _pick_new_direction() -> void:
	var candidates: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	_lane_lock_time = 0.0

	if _target_player and _rng.randf() < _aggression:
		var delta: Vector2 = _target_player.global_position - global_position
		if absf(delta.x) > absf(delta.y):
			_move_direction = Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT
		else:
			_move_direction = Vector2.DOWN if delta.y > 0.0 else Vector2.UP
	else:
		_move_direction = candidates[_rng.randi_range(0, candidates.size() - 1)]

	_direction_timer = _rng.randf_range(_decision_min, _decision_max)


func _should_hunt_player() -> bool:
	if _target_player == null:
		return false

	var delta: Vector2 = _target_player.global_position - global_position
	return absf(delta.x) < _aim_tolerance or absf(delta.y) < _aim_tolerance


func _face_player_lane() -> void:
	if _target_player == null:
		return

	var delta: Vector2 = _target_player.global_position - global_position
	if absf(delta.x) < _aim_tolerance:
		_move_direction = Vector2.DOWN if delta.y > 0.0 else Vector2.UP
	elif absf(delta.y) < _aim_tolerance:
		_move_direction = Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT


func _fire() -> void:
	_fire_timer = _rng.randf_range(_fire_min, _fire_max) + _rng.randf_range(VOLLEY_RECOVERY_MIN, VOLLEY_RECOVERY_MAX)
	_lane_lock_time = 0.0
	_recoil_time = 1.0
	var burst_center := float(_burst_count - 1) * 0.5
	for burst_index in range(_burst_count):
		var angle_offset := (float(burst_index) - burst_center) * _burst_spread
		_spawn_bullet(angle_offset)


func _spawn_bullet(angle_offset: float) -> void:
	var final_rotation := rotation + angle_offset
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position + Vector2.UP.rotated(final_rotation) * (42.0 * _visual_scale)
	bullet.set_spawn_sweep_origin(global_position)
	bullet.rotation = final_rotation
	bullet.direction = Vector2.UP.rotated(final_rotation)
	bullet.owner_team = team
	bullet.speed = _bullet_speed
	bullet.projectile_color = _turret_color.lightened(0.08)
	bullet.glow_color = _body_color.lightened(0.18)
	bullet.impact_color = _turret_color.lightened(0.15)
	bullet.size_scale = _projectile_scale
	bullet.damage = _damage
	get_tree().current_scene.add_child(bullet)


func _apply_profile() -> void:
	var profile: Dictionary = PROFILES.get(enemy_type, PROFILES["grunt"])

	_speed = profile["speed"]
	health = profile["health"]
	_aggression = profile["aggression"]
	_bullet_speed = profile["bullet_speed"]
	_fire_min = profile["fire_min"]
	_fire_max = profile["fire_max"]
	_decision_min = profile["decision_min"]
	_decision_max = profile["decision_max"]
	_aim_tolerance = profile["aim_tolerance"]
	_body_color = Color(profile["body_color"])
	_turret_color = Color(profile["turret_color"])
	_track_color = Color(profile["track_color"])
	_burst_count = int(profile.get("burst_count", 1))
	_burst_spread = float(profile.get("burst_spread", 0.0))
	_projectile_scale = float(profile.get("projectile_scale", 1.0))
	_damage = int(profile.get("damage", 1))
	_visual_scale = float(profile.get("visual_scale", 1.0))
	_collider_radius = float(profile.get("collider_radius", 18.0))
	_engine_color = Color(profile.get("engine_color", _engine_color))
	_bob_amount = float(profile.get("bob_amount", 0.35))
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape is CircleShape2D:
		var circle_shape := collision_shape.shape as CircleShape2D
		if not circle_shape.resource_local_to_scene:
			circle_shape = circle_shape.duplicate()
			circle_shape.resource_local_to_scene = true
			collision_shape.shape = circle_shape
		circle_shape.radius = _collider_radius
	_configure_damage_hurtbox()


func _configure_damage_hurtbox() -> void:
	var hurtbox_shape: CollisionShape2D = get_node_or_null("Hurtbox/CollisionShape2D")
	if hurtbox_shape == null or not (hurtbox_shape.shape is CapsuleShape2D):
		return
	var capsule := hurtbox_shape.shape as CapsuleShape2D
	if not capsule.resource_local_to_scene:
		capsule = capsule.duplicate()
		capsule.resource_local_to_scene = true
		hurtbox_shape.shape = capsule
	var hitbox_size := get_damage_hitbox_size()
	capsule.radius = hitbox_size.x * 0.5
	capsule.height = maxf(hitbox_size.y, hitbox_size.x)


func _is_boss_type() -> bool:
	return enemy_type.begins_with("boss")


func _emit_combat_feedback() -> void:
	if _arena and _arena.has_method("notify_enemy_destroyed_visual"):
		_arena.notify_enemy_destroyed_visual(global_position, enemy_type)


func _refresh_target_player() -> void:
	_target_refresh_timer = TARGET_REFRESH_INTERVAL
	_target_player = null

	if _arena == null or not _arena.has_method("get_active_player_targets"):
		return

	var candidates: Array = _arena.get_active_player_targets()
	var best_distance := INF

	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue

		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			_target_player = candidate
