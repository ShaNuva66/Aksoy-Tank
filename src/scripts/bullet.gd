extends Area2D

const IMPACT_BURST_SCENE := preload("res://src/scenes/impact_burst.tscn")

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


func _ready() -> void:
	add_to_group("bullets")
	collision_layer = 4
	collision_mask = 3
	monitoring = not replica_mode
	direction = direction.normalized()
	_travel_velocity = direction * speed
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if replica_mode:
		return

	lifetime -= delta
	var next_position := global_position + _travel_velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, collision_mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body: Node = hit.get("collider")
		if body and (not body.has_method("get_team") or body.get_team() != owner_team):
			global_position = Vector2(hit.get("position", global_position))
			_resolve_body_hit(body)
			return

	global_position = next_position

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


func _on_body_entered(body: Node) -> void:
	_resolve_body_hit(body)


func _resolve_body_hit(body: Node) -> void:
	if _spent or not is_instance_valid(body):
		return

	if body.has_method("get_team") and body.get_team() == owner_team:
		return
	_spent = true

	_spawn_impact_burst(global_position, body)

	if body.has_method("take_hit"):
		body.take_hit(owner_team, damage)

	if body.has_method("get_team") and String(body.get_team()).begins_with("player"):
		var arena = get_tree().current_scene
		if arena and arena.has_method("notify_player_hit_visual"):
			arena.notify_player_hit_visual(global_position)

	queue_free()


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

	get_tree().current_scene.add_child(burst)


func set_replica_mode(enabled: bool) -> void:
	replica_mode = enabled
	monitoring = not enabled
	set_physics_process(not enabled)


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
		"damage": damage
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	network_id = int(snapshot.get("id", network_id))
	global_position = Vector2(float(snapshot.get("x", global_position.x)), float(snapshot.get("y", global_position.y)))
	rotation = float(snapshot.get("rotation", rotation))
	owner_team = String(snapshot.get("team", owner_team))
	projectile_color = Color(String(snapshot.get("projectile_color", projectile_color.to_html())))
	glow_color = Color(String(snapshot.get("glow_color", glow_color.to_html())))
	impact_color = Color(String(snapshot.get("impact_color", impact_color.to_html())))
	size_scale = float(snapshot.get("size_scale", size_scale))
	damage = int(snapshot.get("damage", damage))
	queue_redraw()
