extends RefCounted

const SEPARATION_RESPONSE := 8.0
const MAX_SEPARATION_SPEED := 72.0


static func apply_soft_separation(body: CharacterBody2D, radius: float, delta: float) -> void:
	var separation := Vector2.ZERO
	for other in body.get_tree().get_nodes_in_group("tanks"):
		if other == body or not is_instance_valid(other) or not other.has_method("get_tank_collision_radius"):
			continue

		var offset: Vector2 = body.global_position - other.global_position
		var distance := offset.length()
		var minimum_distance := radius + float(other.get_tank_collision_radius())
		if distance >= minimum_distance:
			continue

		var direction := offset / distance if distance > 0.01 else Vector2.RIGHT.rotated(float(body.get_instance_id() % 16) * TAU / 16.0)
		separation += direction * (minimum_distance - distance)

	if separation == Vector2.ZERO:
		return

	var correction := separation * minf(delta * SEPARATION_RESPONSE, 0.32)
	correction = correction.limit_length(MAX_SEPARATION_SPEED * delta)
	body.move_and_collide(correction)
