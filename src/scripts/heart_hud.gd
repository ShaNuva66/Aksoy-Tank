extends Control

var current_health := 4
var max_health := 4
var _hit_time := 0.0
var _lost_index := -1
var _low_health_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func set_health(current: int, maximum: int) -> void:
	var previous := current_health
	max_health = maxi(maximum, 1)
	current_health = clampi(current, 0, max_health)

	if current_health < previous:
		_lost_index = max(current_health, 0)
		_hit_time = 0.48

	queue_redraw()


func pulse_damage() -> void:
	_hit_time = maxf(_hit_time, 0.42)
	queue_redraw()


func _process(delta: float) -> void:
	if current_health <= 1:
		_low_health_time += delta

	if _hit_time <= 0.0 and current_health > 1:
		return

	_hit_time = maxf(_hit_time - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var spacing := 34.0
	for index in range(max_health):
		var center := Vector2(22.0 + float(index) * spacing, 22.0)
		var filled := index < current_health
		var scale := 1.0
		var offset := Vector2.ZERO

		if _hit_time > 0.0 and index == _lost_index:
			var wave := sin(_hit_time * 48.0)
			scale = 1.0 + _hit_time * 0.22
			offset = Vector2(wave * 3.5, -absf(wave) * 2.0)
		elif filled and current_health <= 1:
			scale = 1.0 + sin(_low_health_time * 7.2) * 0.08

		_draw_heart(center + offset, scale, filled)


func _draw_heart(center: Vector2, scale_value: float, filled: bool) -> void:
	var fill := Color("#ff5365") if filled else Color(0.28, 0.18, 0.2, 0.7)
	var outline := Color("#ffd3d7") if filled else Color(0.75, 0.62, 0.64, 0.55)
	var s := scale_value

	draw_circle(center + Vector2(-6.0, -4.0) * s, 7.2 * s, fill)
	draw_circle(center + Vector2(6.0, -4.0) * s, 7.2 * s, fill)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-14.0, -2.0) * s,
			center + Vector2(14.0, -2.0) * s,
			center + Vector2(0.0, 15.0) * s
		]),
		PackedColorArray([fill, fill, fill])
	)

	draw_arc(center + Vector2(-6.0, -4.0) * s, 7.5 * s, PI * 0.72, PI * 2.1, 16, outline, 2.0)
	draw_arc(center + Vector2(6.0, -4.0) * s, 7.5 * s, PI * 0.9, PI * 2.28, 16, outline, 2.0)
	draw_line(center + Vector2(-14.0, -2.0) * s, center + Vector2(0.0, 16.0) * s, outline, 2.0)
	draw_line(center + Vector2(14.0, -2.0) * s, center + Vector2(0.0, 16.0) * s, outline, 2.0)
