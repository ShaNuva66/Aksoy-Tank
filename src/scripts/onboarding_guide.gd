extends Control

var _time := 0.0
var _duration := 7.5
var _joystick_rect := Rect2()
var _fire_rect := Rect2()
var _player_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func configure(joystick_rect: Rect2, fire_rect: Rect2, player_position: Vector2) -> void:
	_joystick_rect = joystick_rect
	_fire_rect = fire_rect
	_player_position = player_position
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _time > _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade_in := clampf(_time / 0.45, 0.0, 1.0)
	var fade_out := clampf((_duration - _time) / 1.0, 0.0, 1.0)
	var alpha := fade_in * fade_out
	if alpha <= 0.0:
		return

	var accent := Color("#f2d48f")
	accent.a = 0.55 * alpha
	var soft := Color("#8ff9b5")
	soft.a = 0.42 * alpha

	if _joystick_rect.size.length() > 0.0:
		var center := _joystick_rect.get_center()
		var hand := center + Vector2(sin(_time * 2.8) * 36.0, -18.0 + cos(_time * 2.8) * 18.0)
		draw_arc(center, 62.0 + sin(_time * 4.0) * 5.0, 0.0, TAU, 42, accent, 3.0)
		draw_circle(hand, 12.0, soft)
		draw_circle(hand + Vector2(5.0, 8.0), 7.0, soft)
		_draw_label(center + Vector2(-28.0, -86.0), "SUR", alpha)

	if _fire_rect.size.length() > 0.0:
		var fire_center := _fire_rect.get_center()
		draw_arc(fire_center, 64.0 + sin(_time * 5.6) * 7.0, 0.0, TAU, 42, accent, 4.0)
		_draw_label(fire_center + Vector2(-34.0, -92.0), "ATES", alpha)

	if _player_position != Vector2.ZERO:
		var path := PackedVector2Array([
			_player_position + Vector2(0.0, -44.0),
			_player_position + Vector2(0.0, -108.0),
			_player_position + Vector2(42.0, -148.0)
		])
		draw_polyline(path, soft, 5.0)
		draw_circle(path[path.size() - 1], 8.0 + sin(_time * 5.0) * 2.0, soft)


func _draw_label(position: Vector2, text: String, alpha: float) -> void:
	var color := Color("#fff2bf")
	color.a = 0.72 * alpha
	var font := get_theme_default_font()
	if font:
		draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, color)
