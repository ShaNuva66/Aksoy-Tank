extends CharacterBody2D

signal destroyed
signal health_changed(current_health: int, max_health: int)

const BULLET_SCENE := preload("res://src/scenes/bullet.tscn")
const MobileFeedback := preload("res://src/scripts/mobile_feedback.gd")
const TankSpacing := preload("res://src/scripts/tank_spacing.gd")
const TankRenderer := preload("res://src/scripts/tank_renderer.gd")
const BASE_SPEED := 220.0
const BASE_ROTATION_SPEED := 3.4
const BASE_FIRE_COOLDOWN := 0.48
const BASE_BULLET_SPEED := 620.0
const TURBO_SPEED_MULTIPLIER := 1.28
const TURBO_ROTATION_MULTIPLIER := 1.18
const TACTICAL_SPEED_MULTIPLIER := 1.12
const TACTICAL_ROTATION_MULTIPLIER := 1.08
const OVERDRIVE_COOLDOWN_MULTIPLIER := 0.72
const OVERDRIVE_BULLET_SPEED := 760.0
const DEFAULT_MAX_HEALTH := 3
const ANALOG_ROTATION_RESPONSE := 8.0
const ANALOG_VELOCITY_RESPONSE := 9.0
const WALL_ASSIST_SPEED := 64.0
const WALL_PUSH_OUT_SPEED := 26.0
const NETWORK_REPLICA_RESPONSE := 20.0
const NETWORK_TELEPORT_DISTANCE := 220.0
const LOCAL_RECONCILE_THRESHOLD := 72.0
const LOCAL_RECONCILE_RESPONSE := 5.0
const LOCAL_ROTATION_RECONCILE_RESPONSE := 10.0
const LOCAL_ROTATION_RECONCILE_DELAY := 0.18
const LOCAL_ROTATION_DEADZONE := 0.035
const COLLISION_SAFE_MARGIN := 0.2
const MAX_CORRECTION_SLIDES := 3

var team: String = "player"
var max_health: int = DEFAULT_MAX_HEALTH
var health: int = DEFAULT_MAX_HEALTH
var player_slot: int = 1
var callsign := "P1"
var control_mode := "local"
var spawn_bullets_enabled := true
var _external_input := {
	"turn": 0.0,
	"drive": 0.0,
	"move_x": 0.0,
	"move_y": 0.0,
	"fire": false
}
var _fire_timer: float = 0.0
var _mobile_controls: Node = null
var _flash_time := 0.0
var _shield_time := 0.0
var _shield_capacity := 0.0
var _overdrive_time := 0.0
var _turbo_time := 0.0
var _tactical_time := 0.0
var _fire_cooldown_scale := 1.0
var _wall_assist_time := 0.0
var _body_color := Color("#7fb069")
var _turret_color := Color("#d3ad58")
var _track_color := Color("#2e3945")
var _accent_color := Color("#fff0b0")
var _tank_style_id := "akinci"
var _network_target_position := Vector2.ZERO
var _network_target_rotation := 0.0
var _network_transform_ready := false
var _local_network_correction := Vector2.ZERO
var _local_network_target_rotation := 0.0
var _local_network_rotation_ready := false
var _local_rotation_idle_time := 0.0
var _last_safe_position := Vector2.ZERO
var _safe_position_ready := false
@onready var _nameplate: Label = get_node_or_null("Nameplate")


func _ready() -> void:
	add_to_group("player_tank")
	add_to_group("tanks")
	collision_layer = 1
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = COLLISION_SAFE_MARGIN
	max_slides = 8
	health_changed.emit(health, max_health)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var frame_start_position := global_position
	_remember_safe_position()
	_tick_status_effects(delta)
	_fire_timer = max(_fire_timer - delta, 0.0)

	if control_mode == "replica":
		_apply_replica_smoothing(delta)
		_validate_wall_position(frame_start_position)
		return

	var input_state := capture_local_input_state() if control_mode == "local" else Dictionary(_external_input.duplicate(true))
	var turn_input := float(input_state.get("turn", 0.0))
	var drive_input := float(input_state.get("drive", 0.0))
	var move_vector := Vector2(float(input_state.get("move_x", 0.0)), float(input_state.get("move_y", 0.0)))
	var fire_input := bool(input_state.get("fire", false))
	var intended_velocity := Vector2.ZERO
	var has_authoritative_aim := control_mode == "network_input" and input_state.has("aim_rotation")

	if move_vector.length() > 0.08:
		var desired_direction := move_vector.normalized()
		var desired_rotation := desired_direction.angle() + PI * 0.5
		var rotation_blend := minf(delta * ANALOG_ROTATION_RESPONSE, 1.0)
		var target_velocity := desired_direction * minf(move_vector.length(), 1.0) * _get_move_speed()
		rotation = lerp_angle(rotation, desired_rotation, rotation_blend)
		velocity = velocity.lerp(target_velocity, minf(delta * ANALOG_VELOCITY_RESPONSE, 1.0))
		intended_velocity = target_velocity
	else:
		rotation += turn_input * _get_rotation_speed() * delta
		velocity = Vector2.UP.rotated(rotation) * drive_input * _get_move_speed()
		intended_velocity = velocity
	if has_authoritative_aim:
		rotation = wrapf(float(input_state.get("aim_rotation", rotation)), -PI, PI)
		if move_vector.length() <= 0.08:
			velocity = Vector2.UP.rotated(rotation) * drive_input * _get_move_speed()
			intended_velocity = velocity
	else:
		rotation = wrapf(rotation, -PI, PI)
	velocity = TankSpacing.adjust_velocity_for_tanks(self, velocity, get_tank_spacing_radius())
	move_and_slide()
	_apply_wall_assist(delta, intended_velocity)
	TankSpacing.apply_soft_separation(self, get_tank_spacing_radius(), delta)
	var actively_steering := absf(turn_input) > 0.05 or move_vector.length() > 0.08
	_apply_local_network_correction(delta, actively_steering)
	_validate_wall_position(frame_start_position)

	if fire_input:
		_fire()


func _process(_delta: float) -> void:
	_update_nameplate_transform()


func _draw() -> void:
	var flash_mix: float = 0.0 if _flash_time <= 0.0 else min(_flash_time * 8.0, 1.0)
	TankRenderer.draw_player_tank(self, _get_cosmetic_profile(), flash_mix, _turbo_time > 0.0 or _tactical_time > 0.0, _overdrive_time > 0.0, clampf(_shield_time / maxf(_shield_capacity, 1.0), 0.0, 1.0))


func configure_player(profile: Dictionary) -> void:
	player_slot = int(profile.get("slot", player_slot))
	team = String(profile.get("team", team))
	max_health = maxi(DEFAULT_MAX_HEALTH + int(profile.get("max_health_bonus", 0)), 1)
	health = clampi(int(profile.get("starting_health", max_health)), 1, max_health)
	_fire_cooldown_scale = maxf(float(profile.get("fire_cooldown_scale", 1.0)), 0.45)
	_grant_shield(float(profile.get("spawn_shield_duration", 0.0)))
	apply_cosmetic_profile(profile)
	health_changed.emit(health, max_health)
	queue_redraw()


func apply_cosmetic_profile(profile: Dictionary) -> void:
	callsign = String(profile.get("name", profile.get("callsign", callsign))).strip_edges().substr(0, 18)
	if callsign.is_empty():
		callsign = "Oyuncu"
	_tank_style_id = String(profile.get("style_id", _tank_style_id))
	_body_color = _read_color(profile.get("body_color", _body_color), _body_color)
	_turret_color = _read_color(profile.get("turret_color", _turret_color), _turret_color)
	_track_color = _read_color(profile.get("track_color", _track_color), _track_color)
	_accent_color = _read_color(profile.get("accent_color", _accent_color), _accent_color)
	if _nameplate:
		_nameplate.text = callsign
		_nameplate.add_theme_color_override("font_color", _accent_color.lightened(0.12))
	queue_redraw()


func set_mobile_controls(controls: Node) -> void:
	_mobile_controls = controls


func set_control_mode(mode: String) -> void:
	control_mode = mode
	_network_transform_ready = false
	_local_network_correction = Vector2.ZERO
	_local_network_rotation_ready = false
	_local_rotation_idle_time = 0.0
	_safe_position_ready = false


func set_spawn_bullets_enabled(enabled: bool) -> void:
	spawn_bullets_enabled = enabled


func set_external_input(input_state: Dictionary) -> void:
	_external_input = Dictionary(input_state.duplicate(true))


func capture_local_input_state() -> Dictionary:
	var turn_input := 0.0
	var drive_input := 0.0
	var move_vector := Vector2.ZERO
	var fire_pressed := false

	if player_slot == 1:
		if Input.is_key_pressed(KEY_A):
			turn_input -= 1.0
		if Input.is_key_pressed(KEY_D):
			turn_input += 1.0
		if Input.is_key_pressed(KEY_W):
			drive_input += 1.0
		if Input.is_key_pressed(KEY_S):
			drive_input -= 1.0
		if Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_SPACE):
			fire_pressed = true
		if not GameSession.is_local_coop_enabled() and not GameSession.is_online_mode():
			if Input.is_key_pressed(KEY_LEFT):
				turn_input -= 1.0
			if Input.is_key_pressed(KEY_RIGHT):
				turn_input += 1.0
			if Input.is_key_pressed(KEY_UP):
				drive_input += 1.0
			if Input.is_key_pressed(KEY_DOWN):
				drive_input -= 1.0
	else:
		if Input.is_key_pressed(KEY_LEFT):
			turn_input -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			turn_input += 1.0
		if Input.is_key_pressed(KEY_UP):
			drive_input += 1.0
		if Input.is_key_pressed(KEY_DOWN):
			drive_input -= 1.0
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SLASH):
			fire_pressed = true

	if _mobile_controls and _mobile_controls.has_method("get_turn_axis"):
		turn_input += float(_mobile_controls.get_turn_axis(player_slot))
	if _mobile_controls and _mobile_controls.has_method("get_move_axis"):
		drive_input += float(_mobile_controls.get_move_axis(player_slot))
	if _mobile_controls and _mobile_controls.has_method("get_move_vector"):
		move_vector = _mobile_controls.get_move_vector(player_slot)
	if _mobile_controls and _mobile_controls.has_method("is_fire_pressed"):
		fire_pressed = fire_pressed or bool(_mobile_controls.is_fire_pressed(player_slot))

	return {
		"turn": clampf(turn_input, -1.0, 1.0),
		"drive": clampf(drive_input, -1.0, 1.0),
		"move_x": clampf(move_vector.x, -1.0, 1.0),
		"move_y": clampf(move_vector.y, -1.0, 1.0),
		"aim_rotation": wrapf(rotation, -PI, PI),
		"fire": fire_pressed
	}


func build_snapshot() -> Dictionary:
	return {
		"slot": player_slot,
		"callsign": callsign,
		"style_id": _tank_style_id,
		"body_color": _body_color.to_html(),
		"turret_color": _turret_color.to_html(),
		"track_color": _track_color.to_html(),
		"accent_color": _accent_color.to_html(),
		"x": global_position.x,
		"y": global_position.y,
		"rotation": rotation,
		"health": health,
		"alive": true,
		"team": team,
		"shield": _shield_time,
		"shield_capacity": _shield_capacity,
		"overdrive": _overdrive_time,
		"turbo": _turbo_time,
		"tactical": _tactical_time
	}


func apply_snapshot(snapshot: Dictionary, transform_mode: String = "snap") -> void:
	var snapshot_position := Vector2(float(snapshot.get("x", global_position.x)), float(snapshot.get("y", global_position.y)))
	var snapshot_rotation := float(snapshot.get("rotation", rotation))
	match transform_mode:
		"smooth":
			_set_replica_target(snapshot_position, snapshot_rotation)
		"reconcile":
			_queue_local_reconciliation(snapshot_position, snapshot_rotation)
		_:
			_set_position_if_clear(snapshot_position)
			rotation = snapshot_rotation
			reset_physics_interpolation()

	var previous_health := health
	apply_cosmetic_profile(snapshot)
	health = int(snapshot.get("health", health))
	team = String(snapshot.get("team", team))
	_shield_time = float(snapshot.get("shield", _shield_time))
	_shield_capacity = float(snapshot.get("shield_capacity", maxf(_shield_capacity, _shield_time)))
	_overdrive_time = float(snapshot.get("overdrive", _overdrive_time))
	_turbo_time = float(snapshot.get("turbo", _turbo_time))
	_tactical_time = float(snapshot.get("tactical", _tactical_time))
	if health != previous_health:
		health_changed.emit(health, max_health)
	queue_redraw()


func _set_replica_target(target_position: Vector2, target_rotation: float) -> void:
	var first_snapshot := not _network_transform_ready
	var needs_teleport := global_position.distance_to(target_position) > NETWORK_TELEPORT_DISTANCE
	if first_snapshot or (needs_teleport and _is_direct_wall_path_clear(target_position)):
		if _set_position_if_clear(target_position):
			rotation = target_rotation
			reset_physics_interpolation()
	_network_target_position = target_position
	_network_target_rotation = target_rotation
	_network_transform_ready = true


func _apply_replica_smoothing(delta: float) -> void:
	if not _network_transform_ready:
		return
	var blend := minf(delta * NETWORK_REPLICA_RESPONSE, 1.0)
	var correction_motion := (_network_target_position - global_position) * blend
	_move_collision_safe(correction_motion)
	rotation = lerp_angle(rotation, _network_target_rotation, blend)


func _queue_local_reconciliation(authoritative_position: Vector2, authoritative_rotation: float) -> void:
	var error := authoritative_position - global_position
	if error.length() >= LOCAL_RECONCILE_THRESHOLD:
		# The guest predicts its own movement. Only large divergence is corrected,
		# gradually, so normal network delay never causes visible snap-back.
		_local_network_correction = (error * 0.35).limit_length(96.0)
	_local_network_target_rotation = wrapf(authoritative_rotation, -PI, PI)
	_local_network_rotation_ready = true


func _apply_local_network_correction(delta: float, actively_steering: bool) -> void:
	if _local_network_correction.length_squared() < 0.01:
		_local_network_correction = Vector2.ZERO
	else:
		var step := _local_network_correction * minf(delta * LOCAL_RECONCILE_RESPONSE, 1.0)
		_move_collision_safe(step)
		_local_network_correction -= step

	# Delayed snapshots used to pull the barrel backwards the instant steering
	# stopped, creating visible shake. Wait for the network aim to settle first.
	if actively_steering:
		_local_rotation_idle_time = 0.0
		return
	_local_rotation_idle_time += delta
	if _local_network_rotation_ready and _local_rotation_idle_time >= LOCAL_ROTATION_RECONCILE_DELAY:
		var rotation_error := absf(angle_difference(rotation, _local_network_target_rotation))
		if rotation_error <= LOCAL_ROTATION_DEADZONE:
			return
		else:
			rotation = lerp_angle(rotation, _local_network_target_rotation, minf(delta * LOCAL_ROTATION_RECONCILE_RESPONSE, 1.0))
		rotation = wrapf(rotation, -PI, PI)


func _fire() -> void:
	if not spawn_bullets_enabled or _fire_timer > 0.0:
		return

	_fire_timer = _get_fire_cooldown()
	MobileFeedback.fire()

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position + Vector2.UP.rotated(rotation) * 42.0
	bullet.set_spawn_sweep_origin(global_position)
	bullet.rotation = rotation
	bullet.direction = Vector2.UP.rotated(rotation)
	bullet.owner_team = team

	if _overdrive_time > 0.0:
		bullet.speed = OVERDRIVE_BULLET_SPEED
		bullet.projectile_color = Color("#9cf6ff")
		bullet.glow_color = Color("#e9fdff")
		bullet.impact_color = Color("#7fd7ff")
		bullet.size_scale = 1.15
	else:
		bullet.speed = BASE_BULLET_SPEED
		bullet.projectile_color = _turret_color.lightened(0.28)
		bullet.glow_color = _body_color.lightened(0.18)
		bullet.impact_color = _turret_color.lightened(0.1)

	get_tree().current_scene.add_child(bullet)


func get_team() -> String:
	return team


func get_tank_collision_radius() -> float:
	return 18.0


func get_tank_spacing_radius() -> float:
	return 22.0


func get_callsign() -> String:
	return callsign


func _get_cosmetic_profile() -> Dictionary:
	return {
		"name": callsign,
		"style_id": _tank_style_id,
		"body_color": _body_color.to_html(),
		"turret_color": _turret_color.to_html(),
		"track_color": _track_color.to_html(),
		"accent_color": _accent_color.to_html()
	}


func _read_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	var text := String(value)
	return Color(text) if Color.html_is_valid(text) else fallback


func _update_nameplate_transform() -> void:
	if not _nameplate:
		return
	_nameplate.rotation = -rotation
	_nameplate.position = Vector2(-70.0, -49.0).rotated(-rotation)


func take_hit(_source_team: String = "", damage: int = 1) -> bool:
	if _shield_time > 0.0:
		_flash_time = 0.1
		queue_redraw()
		return false

	health = max(health - maxi(damage, 1), 0)
	_flash_time = 0.16
	health_changed.emit(health, max_health)
	queue_redraw()

	if health <= 0:
		destroyed.emit()
		queue_free()

	return true


func apply_powerup(powerup_type: String) -> Dictionary:
	var result := {
		"title": "Destek Paketi",
		"detail": "Sahaya yeni bir avantaj indi.",
		"tint": Color("#f2d48f")
	}

	match powerup_type:
		"repair":
			if health < max_health:
				health = min(health + 1, max_health)
				health_changed.emit(health, max_health)
				result["title"] = "Saha Onarimi"
				result["detail"] = "+1 zirh plakasi geri yuklendi."
				result["tint"] = Color("#8ce99a")
			else:
				_grant_shield(4.0)
				result["title"] = "Fazla Tamir"
				result["detail"] = "Zirh dolu oldugu icin kisa kalkan saglandi."
				result["tint"] = Color("#8bd3ff")
		"shield":
			_grant_shield(9.0)
			result["title"] = "Plazma Kalkani"
			result["detail"] = "Gelen ilk darbeler enerji perdesinde sonecek."
			result["tint"] = Color("#8bd3ff")
		"overdrive":
			_overdrive_time = max(_overdrive_time, 8.0)
			result["title"] = "Overdrive"
			result["detail"] = "Taret sogutmasi acildi, ates hizi artti."
			result["tint"] = Color("#92e8ff")
		"turbo":
			_turbo_time = max(_turbo_time, 8.0)
			result["title"] = "Turbo Palet"
			result["detail"] = "Donus ve ilerleme hizi yukseliyor."
			result["tint"] = Color("#8ff9b5")
		"tactical":
			_tactical_time = max(_tactical_time, 5.0)
			result["title"] = "Taktik Cekirdek"
			result["detail"] = "5 saniye boyunca kucuk bir hareket avantaji."
			result["tint"] = Color("#d7b4ff")

	queue_redraw()
	return result


func get_powerup_summary() -> String:
	var parts: Array[String] = []

	if _shield_time > 0.0:
		parts.append("Kalkan %ds" % int(ceilf(_shield_time)))

	if _overdrive_time > 0.0:
		parts.append("Overdrive %ds" % int(ceilf(_overdrive_time)))

	if _turbo_time > 0.0:
		parts.append("Turbo %ds" % int(ceilf(_turbo_time)))

	if _tactical_time > 0.0:
		parts.append("Taktik %ds" % int(ceilf(_tactical_time)))

	if parts.is_empty():
		return "Hazir"

	return " | ".join(parts)


func get_max_health() -> int:
	return max_health


func get_shield_remaining() -> float:
	return _shield_time


func get_shield_ratio() -> float:
	if _shield_capacity <= 0.0:
		return 0.0
	return clampf(_shield_time / _shield_capacity, 0.0, 1.0)


func _grant_shield(duration: float) -> void:
	if duration <= 0.0:
		return
	_shield_time = maxf(_shield_time, duration)
	_shield_capacity = maxf(_shield_capacity, _shield_time)


func _tick_status_effects(delta: float) -> void:
	var had_visuals := _flash_time > 0.0 or _shield_time > 0.0 or _overdrive_time > 0.0 or _turbo_time > 0.0 or _tactical_time > 0.0
	_flash_time = max(_flash_time - delta, 0.0)
	_shield_time = max(_shield_time - delta, 0.0)
	_overdrive_time = max(_overdrive_time - delta, 0.0)
	_turbo_time = max(_turbo_time - delta, 0.0)
	_tactical_time = max(_tactical_time - delta, 0.0)

	if had_visuals or _flash_time > 0.0:
		queue_redraw()


func _get_move_speed() -> float:
	if _turbo_time > 0.0:
		return BASE_SPEED * TURBO_SPEED_MULTIPLIER
	if _tactical_time > 0.0:
		return BASE_SPEED * TACTICAL_SPEED_MULTIPLIER

	return BASE_SPEED


func _get_rotation_speed() -> float:
	if _turbo_time > 0.0:
		return BASE_ROTATION_SPEED * TURBO_ROTATION_MULTIPLIER
	if _tactical_time > 0.0:
		return BASE_ROTATION_SPEED * TACTICAL_ROTATION_MULTIPLIER

	return BASE_ROTATION_SPEED


func _get_fire_cooldown() -> float:
	if _overdrive_time > 0.0:
		return BASE_FIRE_COOLDOWN * _fire_cooldown_scale * OVERDRIVE_COOLDOWN_MULTIPLIER

	return BASE_FIRE_COOLDOWN * _fire_cooldown_scale


func _apply_wall_assist(delta: float, intended_velocity: Vector2) -> void:
	if intended_velocity.length() < _get_move_speed() * 0.12 or get_slide_collision_count() <= 0:
		_wall_assist_time = 0.0
		return

	var assist := Vector2.ZERO
	var push_out := Vector2.ZERO
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var normal := collision.get_normal()
		var tangent := intended_velocity.slide(normal)
		if tangent.length() > 1.0:
			assist += tangent.normalized()
		push_out += normal

	if assist == Vector2.ZERO and push_out == Vector2.ZERO:
		_wall_assist_time = 0.0
		return

	_wall_assist_time = minf(_wall_assist_time + delta, 0.2)
	var blend := clampf(_wall_assist_time / 0.2, 0.25, 1.0)
	var offset := Vector2.ZERO
	if assist != Vector2.ZERO:
		offset += assist.normalized() * WALL_ASSIST_SPEED * blend * delta
	if push_out != Vector2.ZERO and velocity.length() < _get_move_speed() * 0.25:
		offset += push_out.normalized() * WALL_PUSH_OUT_SPEED * blend * delta

	_move_collision_safe(offset)


func _move_collision_safe(motion: Vector2) -> Vector2:
	if motion.length_squared() < 0.000001:
		return Vector2.ZERO
	var start_position := global_position
	var remaining := motion
	for _slide in range(MAX_CORRECTION_SLIDES):
		if remaining.length_squared() < 0.000001:
			break
		var collision := move_and_collide(remaining)
		if collision == null:
			break
		remaining = collision.get_remainder().slide(collision.get_normal())
	return global_position - start_position


func _set_position_if_clear(target_position: Vector2) -> bool:
	if _is_wall_position_blocked(target_position):
		return false
	global_position = target_position
	_last_safe_position = target_position
	_safe_position_ready = true
	return true


func _remember_safe_position() -> void:
	if not _is_wall_position_blocked(global_position):
		_last_safe_position = global_position
		_safe_position_ready = true


func _validate_wall_position(frame_start_position: Vector2) -> void:
	if not _is_wall_position_blocked(global_position):
		_last_safe_position = global_position
		_safe_position_ready = true
		return
	var fallback := frame_start_position
	if _is_wall_position_blocked(fallback) and _safe_position_ready:
		fallback = _last_safe_position
	if not _is_wall_position_blocked(fallback):
		global_position = fallback
		reset_physics_interpolation()
	velocity = Vector2.ZERO
	_local_network_correction = Vector2.ZERO


func _is_wall_position_blocked(target_position: Vector2) -> bool:
	if not is_inside_tree():
		return false
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(rotation, target_position)
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _is_direct_wall_path_clear(target_position: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision_shape == null or collision_shape.shape == null:
		return true
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = global_transform
	query.motion = target_position - global_position
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var travel := get_world_2d().direct_space_state.cast_motion(query)
	return travel.is_empty() or float(travel[0]) >= 0.999
