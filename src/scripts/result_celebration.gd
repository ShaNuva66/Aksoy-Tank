extends Control

const WIN_COLORS := [Color("#ffd76a"), Color("#fff0ad"), Color("#72e6a1"), Color("#75cfff"), Color("#ff8f70")]
const LOSS_COLORS := [Color("#ff7b72"), Color("#bd4f58"), Color("#743942"), Color("#d99a86")]

var _mode := ""
var _elapsed := 0.0
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _intensity := 1.0
var _reduced_motion := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func play_result(won: bool, draw_result: bool = false, intensity: float = 1.0, reduced_motion: bool = false) -> void:
	_mode = "draw" if draw_result else ("win" if won else "loss")
	_intensity = clampf(intensity, 0.0, 1.0)
	_reduced_motion = reduced_motion
	_elapsed = 0.0
	_rng.randomize()
	_particles.clear()
	var base_count := 76 if _mode == "win" else 46
	var count := roundi(float(base_count) * _intensity * (0.35 if _reduced_motion else 1.0))
	for index in range(count):
		_particles.append(_make_particle(index, true))
	visible = true
	set_process(not _reduced_motion)
	queue_redraw()


func _process(delta: float) -> void:
	if _reduced_motion:
		return
	_elapsed += delta
	var viewport_size := _safe_size()
	for index in range(_particles.size()):
		var particle: Dictionary = _particles[index]
		var position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		if _mode == "win":
			velocity.y += 150.0 * delta
			position += velocity * delta
			particle["rotation"] = float(particle["rotation"]) + float(particle["spin"]) * delta
			if position.y > viewport_size.y + 40.0:
				particle = _make_particle(index, false)
				position = particle["position"]
		else:
			position += velocity * delta
			if position.y > viewport_size.y + 60.0:
				position.y = -_rng.randf_range(20.0, 180.0)
				position.x = _rng.randf_range(0.0, viewport_size.x)
		particle["position"] = position
		particle["velocity"] = velocity
		_particles[index] = particle
	queue_redraw()


func _draw() -> void:
	var viewport_size := _safe_size()
	var center := viewport_size * 0.5
	if _mode == "win":
		var pulse := 0.5 + 0.5 * sin(_elapsed * 3.2)
		draw_circle(center, 250.0 + pulse * 34.0, Color(1.0, 0.78, 0.25, 0.025 + pulse * 0.025))
		draw_arc(center, 285.0 + pulse * 18.0, 0.0, TAU, 72, Color(1.0, 0.84, 0.4, 0.18), 5.0)
		draw_arc(center, 330.0 - pulse * 14.0, 0.0, TAU, 72, Color(0.45, 0.92, 0.65, 0.11), 3.0)
	elif _mode == "loss":
		var warning_alpha := 0.06 + 0.025 * sin(_elapsed * 2.4)
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.42, 0.025, 0.04, warning_alpha))
	elif _mode == "draw":
		draw_arc(center, 300.0, _elapsed, _elapsed + PI * 1.35, 64, Color(0.7, 0.78, 0.88, 0.16), 5.0)

	for particle in _particles:
		var position: Vector2 = particle["position"]
		var particle_size: Vector2 = particle["size"]
		var color: Color = particle["color"]
		if _mode == "win":
			draw_set_transform(position, float(particle["rotation"]), Vector2.ONE)
			draw_rect(Rect2(-particle_size * 0.5, particle_size), color)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_line(position, position - Vector2(12.0, 36.0), color, particle_size.x)


func _make_particle(index: int, initial: bool) -> Dictionary:
	var viewport_size := _safe_size()
	if _mode == "win":
		return {
			"position": Vector2(
				_rng.randf_range(0.0, viewport_size.x),
				_rng.randf_range(-viewport_size.y, viewport_size.y * 0.2) if initial else _rng.randf_range(-180.0, -30.0)
			),
			"velocity": Vector2(_rng.randf_range(-75.0, 75.0), _rng.randf_range(80.0, 220.0)),
			"size": Vector2(_rng.randf_range(7.0, 16.0), _rng.randf_range(12.0, 26.0)),
			"rotation": _rng.randf_range(0.0, TAU),
			"spin": _rng.randf_range(-5.0, 5.0),
			"color": WIN_COLORS[index % WIN_COLORS.size()]
		}
	return {
		"position": Vector2(_rng.randf_range(0.0, viewport_size.x), _rng.randf_range(-60.0, viewport_size.y)),
		"velocity": Vector2(_rng.randf_range(-35.0, -10.0), _rng.randf_range(150.0, 310.0)),
		"size": Vector2(_rng.randf_range(2.0, 6.0), 30.0),
		"rotation": 0.0,
		"spin": 0.0,
		"color": LOSS_COLORS[index % LOSS_COLORS.size()]
	}


func _safe_size() -> Vector2:
	return Vector2(maxf(size.x, 1280.0), maxf(size.y, 720.0))
