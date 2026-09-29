extends Control

signal finished

const MOVE_DISTANCE_REQUIRED := 68.0
const FAILSAFE_SECONDS := 30.0

var _time := 0.0
var _phase := 0
var _phase_time := 0.0
var _joystick_rect := Rect2()
var _fire_rect := Rect2()
var _player: Node2D = null
var _start_position := Vector2.ZERO
var _shot_registered := false
var _completed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func configure(joystick_rect: Rect2, fire_rect: Rect2, player: Node2D) -> void:
	_joystick_rect = joystick_rect
	_fire_rect = fire_rect
	_player = player
	_start_position = player.global_position
	if player.has_signal("shot_fired"):
		player.shot_fired.connect(_on_player_shot_fired)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_phase_time += delta
	if _time >= FAILSAFE_SECONDS:
		_finish()
		return

	if _phase == 0 and is_instance_valid(_player):
		if _player.global_position.distance_to(_start_position) >= MOVE_DISTANCE_REQUIRED:
			_phase = 1
			_phase_time = 0.0
			queue_redraw()
	if _phase == 1 and _shot_registered:
		_phase = 2
		_phase_time = 0.0
	if _phase == 2 and _phase_time >= 0.8:
		_finish()
		return
	queue_redraw()


func _on_player_shot_fired() -> void:
	_shot_registered = true


func _finish() -> void:
	if _completed:
		return
	_completed = true
	finished.emit()
	queue_free()


func _draw() -> void:
	var fade_in := clampf(_phase_time / 0.28, 0.0, 1.0)
	var fade_out := 1.0 - clampf((_phase_time - 0.35) / 0.45, 0.0, 1.0) if _phase == 2 else 1.0
	var alpha := fade_in * fade_out
	var accent := Color("#f2d48f", 0.62 * alpha)
	var soft := Color("#8ff9b5", 0.48 * alpha)
	var pulse_time := 0.0 if GameSession.is_reduced_motion_enabled() else _time

	if _phase == 0 and _joystick_rect.size.length() > 0.0:
		var center := _joystick_rect.get_center()
		var hand := center + Vector2(sin(pulse_time * 2.8) * 36.0, -18.0 + cos(pulse_time * 2.8) * 18.0)
		draw_arc(center, 62.0 + sin(pulse_time * 4.0) * 5.0, 0.0, TAU, 42, accent, 3.0)
		draw_circle(hand, 12.0, soft)
		draw_circle(hand + Vector2(5.0, 8.0), 7.0, soft)
		_draw_label(center + Vector2(-64.0, -86.0), "HAREKET ET", alpha)
		if is_instance_valid(_player):
			var path := PackedVector2Array([
				_player.global_position + Vector2(0.0, -44.0),
				_player.global_position + Vector2(0.0, -108.0),
				_player.global_position + Vector2(42.0, -148.0)
			])
			draw_polyline(path, soft, 5.0)
			draw_circle(path[path.size() - 1], 8.0 + sin(pulse_time * 5.0) * 2.0, soft)
	elif _phase == 1 and _fire_rect.size.length() > 0.0:
		var fire_center := _fire_rect.get_center()
		draw_arc(fire_center, 64.0 + sin(pulse_time * 5.6) * 7.0, 0.0, TAU, 42, accent, 4.0)
		_draw_label(fire_center + Vector2(-52.0, -92.0), "ATES ET", alpha)
	elif _phase == 2:
		_draw_label(Vector2(size.x * 0.5 - 58.0, 104.0), "HAZIRSIN", alpha)


func _draw_label(position: Vector2, text: String, alpha: float) -> void:
	var color := Color("#fff2bf", 0.82 * alpha)
	var font := get_theme_default_font()
	if font:
		draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, color)
