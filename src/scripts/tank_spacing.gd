extends RefCounted

const CONTACT_BUFFER := 2.0
const ANTICIPATION_DISTANCE := 8.0
const SEPARATION_RESPONSE := 18.0
const MAX_SEPARATION_SPEED := 180.0
const MIN_ESCAPE_SPEED := 84.0


static func adjust_velocity_for_tanks(body: CharacterBody2D, desired_velocity: Vector2, radius: float) -> Vector2:
	var adjusted := desired_velocity
	for other in body.get_tree().get_nodes_in_group("tanks"):
		if other == body or not is_instance_valid(other):
			continue
		var other_radius := _get_spacing_radius(other)
		if other_radius <= 0.0:
			continue
		var offset: Vector2 = body.global_position - other.global_position
		var distance := offset.length()
		var minimum_distance := radius + other_radius + CONTACT_BUFFER
		if distance >= minimum_distance + ANTICIPATION_DISTANCE:
			continue
		var direction := _separation_direction(body, other, offset, distance)
		var inward_speed := -adjusted.dot(direction)
		if inward_speed > 0.0:
			adjusted += direction * inward_speed
		if distance < minimum_distance:
			var penetration := minimum_distance - distance
			var escape_speed := minf(MAX_SEPARATION_SPEED, maxf(MIN_ESCAPE_SPEED, penetration * SEPARATION_RESPONSE))
			adjusted += direction * escape_speed
	return adjusted.limit_length(maxf(desired_velocity.length(), MAX_SEPARATION_SPEED))


static func apply_soft_separation(body: CharacterBody2D, radius: float, delta: float) -> void:
	var separation := Vector2.ZERO
	for other in body.get_tree().get_nodes_in_group("tanks"):
		if other == body or not is_instance_valid(other):
			continue

		var offset: Vector2 = body.global_position - other.global_position
		var distance := offset.length()
		var other_radius := _get_spacing_radius(other)
		if other_radius <= 0.0:
			continue
		var minimum_distance := radius + other_radius + CONTACT_BUFFER
		if distance >= minimum_distance:
			continue

		var direction := _separation_direction(body, other, offset, distance)
		separation += direction * (minimum_distance - distance)

	if separation == Vector2.ZERO:
		return

	var correction := separation * minf(delta * SEPARATION_RESPONSE, 0.32)
	correction = correction.limit_length(MAX_SEPARATION_SPEED * delta)
	body.move_and_collide(correction)


static func _get_spacing_radius(body: Node) -> float:
	if body.has_method("get_tank_spacing_radius"):
		return float(body.get_tank_spacing_radius())
	if body.has_method("get_tank_collision_radius"):
		return float(body.get_tank_collision_radius())
	return 0.0


static func _separation_direction(body: Node, other: Node, offset: Vector2, distance: float) -> Vector2:
	if distance > 0.01:
		return offset / distance
	var low_id := mini(body.get_instance_id(), other.get_instance_id())
	var high_id := maxi(body.get_instance_id(), other.get_instance_id())
	var angle_degrees := float(posmod(low_id * 31 + high_id * 17, 360))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))
	return axis if body.get_instance_id() == low_id else -axis
