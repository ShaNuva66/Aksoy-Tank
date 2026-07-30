extends CharacterBody2D

signal destroyed
signal health_changed(current_health: int, max_health: int)

const BULLET_SCENE := preload("res://src/scenes/bullet.tscn")
const MobileFeedback := preload("res://src/scripts/mobile_feedback.gd")
const TankSpacing := preload("res://src/scripts/tank_spacing.gd")
const BASE_SPEED := 220.0
const BASE_ROTATION_SPEED := 3.4
const BASE_FIRE_COOLDOWN := 0.48
const BASE_BULLET_SPEED := 620.0
const TURBO_SPEED_MULTIPLIER := 1.28
const TURBO_ROTATION_MULTIPLIER := 1.18
const OVERDRIVE_COOLDOWN_MULTIPLIER := 0.72
const OVERDRIVE_BULLET_SPEED := 760.0
const DEFAULT_MAX_HEALTH := 3
const ANALOG_ROTATION_RESPONSE := 8.0
const ANALOG_VELOCITY_RESPONSE := 9.0
const WALL_ASSIST_SPEED := 64.0
const WALL_PUSH_OUT_SPEED := 26.0

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
var _fire_cooldown_scale := 1.0
var _wall_assist_time := 0.0
var _body_color := Color("#7fb069")
var _turret_color := Color("#d3ad58")
var _track_color := Color("#2e3945")


func _ready() -> void:
	add_to_group("player_tank")
	add_to_group("tanks")
	collision_layer = 1
	collision_mask = 2
	safe_margin = 1.0
	health_changed.emit(health, max_health)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_tick_status_effects(delta)
	_fire_timer = max(_fire_timer - delta, 0.0)

	if control_mode == "replica":
		return

	var input_state := capture_local_input_state() if control_mode == "local" else Dictionary(_external_input.duplicate(true))
	var turn_input := float(input_state.get("turn", 0.0))
	var drive_input := float(input_state.get("drive", 0.0))
	var move_vector := Vector2(float(input_state.get("move_x", 0.0)), float(input_state.get("move_y", 0.0)))
	var fire_input := bool(input_state.get("fire", false))
	var intended_velocity := Vector2.ZERO

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
	move_and_slide()
	_apply_wall_assist(delta, intended_velocity)
	TankSpacing.apply_soft_separation(self, get_tank_collision_radius(), delta)

	if fire_input:
		_fire()


func _draw() -> void:
	var flash_mix: float = 0.0 if _flash_time <= 0.0 else min(_flash_time * 8.0, 1.0)
	var body_color := _body_color
	var turret_color := _turret_color

	if _turbo_time > 0.0:
		body_color = body_color.lerp(Color("#9be58f"), 0.45)

	if _overdrive_time > 0.0:
		turret_color = turret_color.lerp(Color("#92e8ff"), 0.6)

	draw_rect(Rect2(Vector2(-22.0, -24.0), Vector2(44.0, 48.0)), body_color.lerp(Color.WHITE, flash_mix))
	draw_rect(Rect2(Vector2(-8.0, -34.0), Vector2(16.0, 28.0)), turret_color.lerp(Color.WHITE, flash_mix))
	draw_rect(Rect2(Vector2(-18.0, -18.0), Vector2(6.0, 36.0)), _track_color)
	draw_rect(Rect2(Vector2(12.0, -18.0), Vector2(6.0, 36.0)), _track_color)
	draw_circle(Vector2.ZERO, 8.0, _track_color)

	if _turbo_time > 0.0:
		draw_line(Vector2(-10.0, 22.0), Vector2(-16.0, 34.0), Color("#8ff9b5"), 3.0)
		draw_line(Vector2(10.0, 22.0), Vector2(16.0, 34.0), Color("#8ff9b5"), 3.0)

	if _shield_time > 0.0:
		var shield_color := Color("#8bd3ff")
		var shield_fill := shield_color
		shield_fill.a = 0.08 + min(_shield_time * 0.02, 0.12)
		draw_circle(Vector2.ZERO, 34.0, shield_fill)
		draw_arc(Vector2.ZERO, 37.0, 0.0, TAU, 42, shield_color, 3.0)


func configure_player(profile: Dictionary) -> void:
	player_slot = int(profile.get("slot", player_slot))
	callsign = String(profile.get("callsign", callsign))
	team = String(profile.get("team", team))
	max_health = maxi(DEFAULT_MAX_HEALTH + int(profile.get("max_health_bonus", 0)), 1)
	health = clampi(int(profile.get("starting_health", max_health)), 1, max_health)
	_fire_cooldown_scale = maxf(float(profile.get("fire_cooldown_scale", 1.0)), 0.45)
	_grant_shield(float(profile.get("spawn_shield_duration", 0.0)))
	_body_color = Color(profile.get("body_color", _body_color))
	_turret_color = Color(profile.get("turret_color", _turret_color))
	_track_color = Color(profile.get("track_color", _track_color))
	health_changed.emit(health, max_health)
	queue_redraw()


func set_mobile_controls(controls: Node) -> void:
	_mobile_controls = controls


func set_control_mode(mode: String) -> void:
	control_mode = mode


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
		"fire": fire_pressed
	}


func build_snapshot() -> Dictionary:
	return {
		"slot": player_slot,
		"callsign": callsign,
		"x": global_position.x,
		"y": global_position.y,
		"rotation": rotation,
		"health": health,
		"alive": true,
		"team": team,
		"shield": _shield_time,
		"shield_capacity": _shield_capacity,
		"overdrive": _overdrive_time,
		"turbo": _turbo_time
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	global_position = Vector2(float(snapshot.get("x", global_position.x)), float(snapshot.get("y", global_position.y)))
	rotation = float(snapshot.get("rotation", rotation))
	health = int(snapshot.get("health", health))
	team = String(snapshot.get("team", team))
	_shield_time = float(snapshot.get("shield", _shield_time))
	_shield_capacity = float(snapshot.get("shield_capacity", maxf(_shield_capacity, _shield_time)))
	_overdrive_time = float(snapshot.get("overdrive", _overdrive_time))
	_turbo_time = float(snapshot.get("turbo", _turbo_time))
	health_changed.emit(health, max_health)
	queue_redraw()


func _fire() -> void:
	if not spawn_bullets_enabled or _fire_timer > 0.0:
		return

	_fire_timer = _get_fire_cooldown()
	MobileFeedback.fire()

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position + Vector2.UP.rotated(rotation) * 42.0
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


func get_callsign() -> String:
	return callsign


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
	var had_visuals := _flash_time > 0.0 or _shield_time > 0.0 or _overdrive_time > 0.0 or _turbo_time > 0.0
	_flash_time = max(_flash_time - delta, 0.0)
	_shield_time = max(_shield_time - delta, 0.0)
	_overdrive_time = max(_overdrive_time - delta, 0.0)
	_turbo_time = max(_turbo_time - delta, 0.0)

	if had_visuals or _flash_time > 0.0:
		queue_redraw()


func _get_move_speed() -> float:
	if _turbo_time > 0.0:
		return BASE_SPEED * TURBO_SPEED_MULTIPLIER

	return BASE_SPEED


func _get_rotation_speed() -> float:
	if _turbo_time > 0.0:
		return BASE_ROTATION_SPEED * TURBO_ROTATION_MULTIPLIER

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

	global_position += offset
