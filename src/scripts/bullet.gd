extends Area2D

const IMPACT_BURST_SCENE := preload("res://src/scenes/impact_burst.tscn")
const WORLD_COLLISION_MASK := 2
const HURTBOX_COLLISION_MASK := 8
const BASE_HIT_RADIUS := 3.0
const CONTACT_PROBE_DISTANCE := 0.75

@export var speed: float = 560.0
@export var owner_team: String = "neutral"
@export var lifetime: float = 2.5
@export var projectile_color: Color = Color("#f9e2af")
@export var glow_color: Color = Color("#fff6cf")
@export var impact_color: Color = Color("#ffd79b")
@export var size_scale: float = 1.0
@export var damage: int = 1
var network_id: int = -1
var replica_mode := false
var direction: Vector2 = Vector2.UP
var _travel_velocity := Vector2.ZERO
var _spent := false
var _network_target_position := Vector2.ZERO
var _network_target_rotation := 0.0
var _network_transform_ready := false
var _sweep_shape := CapsuleShape2D.new()
var _spawn_sweep_origin := Vector2.ZERO
var _has_spawn_sweep := false


func _ready() -> void:
	add_to_group("bullets")
	collision_layer = 4
	collision_mask = WORLD_COLLISION_MASK | HURTBOX_COLLISION_MASK
	monitoring = not replica_mode
	direction = direction.normalized()
	_travel_velocity = direction * speed
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_configure_projectile_shape()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if replica_mode:
		global_position += _travel_velocity * delta
		if _network_transform_ready:
			var correction := _network_target_position - global_position
			if correction.length() > 100.0:
				global_position = _network_target_position
				reset_physics_interpolation()
			else:
				global_position += correction * minf(delta * 8.0, 0.35)
			rotation = lerp_angle(rotation, _network_target_rotation, minf(delta * 18.0, 1.0))
		return

	lifetime -= delta
	var visual_start_position := global_position
	var start_position := _spawn_sweep_origin if _has_spawn_sweep else visual_start_position
	var motion := visual_start_position + _travel_velocity * delta - start_position
	_has_spawn_sweep = false
	var wall_hit := _find_swept_hit(start_position, motion, WORLD_COLLISION_MASK, false)
	var tank_hit := _find_swept_hit(start_position, motion, HURTBOX_COLLISION_MASK, true)
	var hit := _choose_nearest_hit(wall_hit, tank_hit)
	if not hit.is_empty():
		var fraction := clampf(float(hit.get("fraction", 0.0)), 0.0, 1.0)
		global_position = start_position + motion * fraction
		if _resolve_body_hit(hit.get("collider")):
			return

	global_position = start_position + motion

	if lifetime <= 0.0:
		queue_free()
	elif global_position.x < -100.0 or global_position.x > 1400.0:
		queue_free()
	elif global_position.y < -100.0 or global_position.y > 900.0:
		queue_free()


func _draw() -> void:
	var glow_size := Vector2(10.0, 24.0) * size_scale
	var core_size := Vector2(6.0, 16.0) * size_scale
	draw_rect(Rect2(-glow_size * 0.5, glow_size), glow_color)
	draw_rect(Rect2(-core_size * 0.5, core_size), projectile_color)
	draw_circle(Vector2(0.0, -core_size.y * 0.45), 3.0 * size_scale, projectile_color.lightened(0.1))


func set_spawn_sweep_origin(origin: Vector2) -> void:
	_spawn_sweep_origin = origin
	_has_spawn_sweep = true


func _on_body_entered(body: Node) -> void:
	_resolve_body_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_resolve_body_hit(area)


func _resolve_body_hit(collider: Node) -> bool:
	var body := _get_damage_target(collider)
	if _spent or not is_instance_valid(body):
		return false

	if body.has_method("get_team") and body.get_team() == owner_team:
		return false
	_spent = true
	var target_team := String(body.get_team()) if body.has_method("get_team") else ""

	_spawn_impact_burst(global_position, body)

	var damage_applied := false
	if body.has_method("take_hit"):
		damage_applied = bool(body.take_hit(owner_team, damage))

	if target_team.begins_with("player"):
		var arena = get_tree().current_scene
		if arena and arena.has_method("notify_tank_hit_result"):
			var destroyed := damage_applied and int(body.health) <= 0
			arena.notify_tank_hit_result(global_position, owner_team, target_team, damage, damage_applied, destroyed)

	queue_free()
	return true


func _get_damage_target(collider: Node) -> Node:
	if not is_instance_valid(collider):
		return null
	if collider.is_in_group("tank_hurtboxes"):
		var tank := collider.get_parent()
		if is_instance_valid(tank):
			return tank
	return collider


func _find_swept_hit(origin: Vector2, motion: Vector2, mask: int, collide_with_areas: bool) -> Dictionary:
	if motion.length_squared() < 0.000001:
		return {}
	_sweep_shape.radius = BASE_HIT_RADIUS * maxf(size_scale, 0.25)
	_sweep_shape.height = 12.0 * maxf(size_scale, 0.25)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _sweep_shape
	query.transform = Transform2D(global_rotation, origin)
	query.motion = motion
	query.collision_mask = mask
	query.collide_with_bodies = not collide_with_areas
	query.collide_with_areas = collide_with_areas
	if collide_with_areas:
		query.exclude = _get_friendly_hurtbox_rids()
	var direct_state := get_world_2d().direct_space_state
	# cast_motion does not report a shape that already overlaps at the sweep
	# origin. This is exactly what happens when two tanks are point-blank, so
	# resolve that contact before testing the rest of the muzzle path.
	query.motion = Vector2.ZERO
	var initial_overlaps := direct_state.intersect_shape(query, 8)
	for overlap in initial_overlaps:
		var initial_collider: Node = overlap.get("collider")
		if is_instance_valid(initial_collider):
			return {"fraction": 0.0, "collider": initial_collider}
	query.motion = motion
	var travel := direct_state.cast_motion(query)
	if travel.size() < 2 or float(travel[0]) >= 0.99999:
		return {}

	var safe_fraction := clampf(float(travel[0]), 0.0, 1.0)
	var unsafe_fraction := clampf(float(travel[1]), safe_fraction, 1.0)
	var probe_step := minf(CONTACT_PROBE_DISTANCE / maxf(motion.length(), 0.001), 0.05)
	query.motion = Vector2.ZERO
	query.transform = Transform2D(global_rotation, origin + motion * minf(unsafe_fraction + probe_step, 1.0))
	var overlaps := direct_state.intersect_shape(query, 8)
	for overlap in overlaps:
		var collider: Node = overlap.get("collider")
		if is_instance_valid(collider):
			return {"fraction": safe_fraction, "collider": collider}

	# Precision fallback: the ray is only used to identify the collider after
	# the swept capsule has already established the exact contact fraction.
	var ray := PhysicsRayQueryParameters2D.create(origin, origin + motion, mask)
	ray.collide_with_bodies = not collide_with_areas
	ray.collide_with_areas = collide_with_areas
	var ray_hit := direct_state.intersect_ray(ray)
	if not ray_hit.is_empty():
		return {"fraction": safe_fraction, "collider": ray_hit.get("collider")}
	return {}


func _get_friendly_hurtbox_rids() -> Array[RID]:
	var exclusions: Array[RID] = []
	for node in get_tree().get_nodes_in_group("tank_hurtboxes"):
		if not (node is Area2D):
			continue
		var tank := node.get_parent()
		if is_instance_valid(tank) and tank.has_method("get_team") and tank.get_team() == owner_team:
			exclusions.append(node.get_rid())
	return exclusions


func _choose_nearest_hit(first: Dictionary, second: Dictionary) -> Dictionary:
	if first.is_empty():
		return second
	if second.is_empty():
		return first
	# Solid cover wins ties so a tank hurtbox can never be damaged through a wall.
	return first if float(first.get("fraction", 1.0)) <= float(second.get("fraction", 1.0)) + 0.0005 else second


func _configure_projectile_shape() -> void:
	_sweep_shape.radius = BASE_HIT_RADIUS * maxf(size_scale, 0.25)
	_sweep_shape.height = 12.0 * maxf(size_scale, 0.25)
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision_shape == null or not (collision_shape.shape is CapsuleShape2D):
		return
	var capsule := collision_shape.shape as CapsuleShape2D
	if not capsule.resource_local_to_scene:
		capsule = capsule.duplicate()
		capsule.resource_local_to_scene = true
		collision_shape.shape = capsule
	capsule.radius = _sweep_shape.radius
	capsule.height = 12.0 * maxf(size_scale, 0.25)


func _spawn_impact_burst(at_position: Vector2, body: Node) -> void:
	var burst = IMPACT_BURST_SCENE.instantiate()
	burst.global_position = at_position
	burst.color = impact_color

	if body.has_method("get_team") and body.get_team() == "enemy":
		burst.color = Color("#ffd166")
	elif body.has_method("get_team") and body.get_team() == "player":
		burst.color = Color("#ff7b72")
	elif body.is_in_group("blocks"):
		burst.color = Color("#d9b38c") if body.block_type == "brick" else Color("#cad3dd")
	var game_session := get_node_or_null("/root/GameSession")
	if game_session:
		burst.intensity = game_session.get_effects_intensity()
		burst.reduced_motion = game_session.is_reduced_motion_enabled()

	get_tree().current_scene.add_child(burst)


func set_replica_mode(enabled: bool) -> void:
	replica_mode = enabled
	monitoring = not enabled
	set_physics_process(true)


func build_snapshot() -> Dictionary:
	return {
		"id": network_id,
		"x": global_position.x,
		"y": global_position.y,
		"rotation": rotation,
		"team": owner_team,
		"projectile_color": projectile_color.to_html(),
		"glow_color": glow_color.to_html(),
		"impact_color": impact_color.to_html(),
		"size_scale": size_scale,
		"damage": damage,
		"velocity_x": _travel_velocity.x,
		"velocity_y": _travel_velocity.y
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	network_id = int(snapshot.get("id", network_id))
	var snapshot_position := Vector2(float(snapshot.get("x", global_position.x)), float(snapshot.get("y", global_position.y)))
	var snapshot_rotation := float(snapshot.get("rotation", rotation))
	if replica_mode:
		if not _network_transform_ready:
			global_position = snapshot_position
			rotation = snapshot_rotation
			reset_physics_interpolation()
		_network_target_position = snapshot_position
		_network_target_rotation = snapshot_rotation
		_network_transform_ready = true
	else:
		global_position = snapshot_position
		rotation = snapshot_rotation
	owner_team = String(snapshot.get("team", owner_team))
	projectile_color = Color(String(snapshot.get("projectile_color", projectile_color.to_html())))
	glow_color = Color(String(snapshot.get("glow_color", glow_color.to_html())))
	impact_color = Color(String(snapshot.get("impact_color", impact_color.to_html())))
	size_scale = float(snapshot.get("size_scale", size_scale))
	damage = int(snapshot.get("damage", damage))
	_travel_velocity = Vector2(float(snapshot.get("velocity_x", _travel_velocity.x)), float(snapshot.get("velocity_y", _travel_velocity.y)))
	_configure_projectile_shape()
	queue_redraw()
