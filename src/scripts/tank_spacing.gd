extends RefCounted

const CONTACT_BUFFER := 2.0
const ANTICIPATION_DISTANCE := 8.0
const SEPARATION_RESPONSE := 18.0
const MAX_SEPARATION_SPEED := 180.0
const MIN_ESCAPE_SPEED := 84.0
const CONTACT_GLIDE_SPEED := 72.0
const MIN_GLIDE_INPUT := 18.0


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
			var proximity := 1.0 - clampf((distance - minimum_distance) / ANTICIPATION_DISTANCE, 0.0, 1.0)
			var tangent := direction.orthogonal()
			var desired_tangent := desired_velocity.dot(tangent)
			if absf(desired_tangent) >= MIN_GLIDE_INPUT:
				tangent *= signf(desired_tangent)
			adjusted += tangent * CONTACT_GLIDE_SPEED * proximity
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
	var start_position := body.global_position
	var collision := body.move_and_collide(correction)
	if collision == null:
		return

	var slide_motion := collision.get_remainder().slide(collision.get_normal())
	if slide_motion.length_squared() > 0.0001:
		body.move_and_collide(slide_motion)
	if body.global_position.distance_squared_to(start_position) > 0.04:
		return

	# A wall can block the ideal outward correction. Try both wall tangents so
	# tightly packed tanks still gain a route instead of remaining glued.
	var wall_tangent := collision.get_normal().orthogonal()
	var tangent_step := wall_tangent * minf(MAX_SEPARATION_SPEED * delta, correction.length())
	if separation.dot(wall_tangent) < 0.0:
		tangent_step = -tangent_step
	var tangent_collision := body.move_and_collide(tangent_step)
	if tangent_collision != null and body.global_position.distance_squared_to(start_position) <= 0.04:
		body.move_and_collide(-tangent_step)


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
