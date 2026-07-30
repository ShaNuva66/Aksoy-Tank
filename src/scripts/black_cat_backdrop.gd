extends Control

const SKY_TOP := Color("#06080c")
const SKY_BOTTOM := Color("#0d1218")
const MOON := Color("#f1c45d")
const CAT := Color("#020304")
const CAT_SOFT := Color("#111418")
const EYE := Color("#ffd96c")

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	for band_index in range(18):
		var weight := float(band_index) / 17.0
		var band_color := SKY_TOP.lerp(SKY_BOTTOM, weight)
		var band_height := viewport_size.y / 17.0
		draw_rect(Rect2(Vector2(0.0, band_index * band_height), Vector2(viewport_size.x, band_height + 4.0)), band_color)

	var moon_center := Vector2(viewport_size.x * 0.82, viewport_size.y * 0.18) + Vector2(sin(_time * 0.28) * 8.0, cos(_time * 0.22) * 4.0)
	var moon_glow := 88.0 + sin(_time * 1.2) * 4.0
	draw_circle(moon_center, moon_glow, Color(MOON.r, MOON.g, MOON.b, 0.12 + sin(_time * 1.2) * 0.02))
	draw_circle(moon_center + Vector2(22.0, -8.0), 68.0, SKY_TOP)

	var body_center := Vector2(viewport_size.x * 0.77, viewport_size.y * 0.72) + Vector2(0.0, sin(_time * 1.05) * 4.0)
	var body_radius := minf(viewport_size.x, viewport_size.y) * 0.18
	var head_center := body_center + Vector2(0.0, -body_radius * 1.08)
	var head_radius := body_radius * 0.56
	draw_circle(body_center, body_radius, CAT_SOFT)
	draw_circle(head_center, head_radius, CAT)
	_draw_triangle(head_center + Vector2(-head_radius * 0.7, -head_radius * 0.32), head_center + Vector2(-head_radius * 0.22, -head_radius * 1.34), head_center + Vector2(-head_radius * 0.02, -head_radius * 0.08), CAT)
	_draw_triangle(head_center + Vector2(head_radius * 0.7, -head_radius * 0.32), head_center + Vector2(head_radius * 0.22, -head_radius * 1.34), head_center + Vector2(head_radius * 0.02, -head_radius * 0.08), CAT)
	draw_arc(body_center + Vector2(body_radius * 0.62, body_radius * 0.22), body_radius * 0.9, -PI * 0.18, PI * 1.08, 24, CAT, body_radius * 0.16)

	var eye_offset_x := head_radius * 0.34
	var eye_offset_y := -head_radius * 0.06
	var eye_color := Color(EYE.r, EYE.g, EYE.b, 0.82 + sin(_time * 3.0) * 0.18)
	draw_circle(head_center + Vector2(-eye_offset_x, eye_offset_y), head_radius * 0.12, eye_color)
	draw_circle(head_center + Vector2(eye_offset_x, eye_offset_y), head_radius * 0.12, eye_color)
	draw_line(head_center + Vector2(-eye_offset_x, eye_offset_y - 6.0), head_center + Vector2(-eye_offset_x, eye_offset_y + 7.0), Color("#241d0a"), 2.0)
	draw_line(head_center + Vector2(eye_offset_x, eye_offset_y - 6.0), head_center + Vector2(eye_offset_x, eye_offset_y + 7.0), Color("#241d0a"), 2.0)
	draw_line(head_center + Vector2(-head_radius * 0.74, head_radius * 0.18), head_center + Vector2(-head_radius * 1.24, head_radius * 0.06), Color(1, 1, 1, 0.08), 2.0)
	draw_line(head_center + Vector2(-head_radius * 0.74, head_radius * 0.32), head_center + Vector2(-head_radius * 1.16, head_radius * 0.4), Color(1, 1, 1, 0.06), 2.0)
	draw_line(head_center + Vector2(head_radius * 0.74, head_radius * 0.18), head_center + Vector2(head_radius * 1.24, head_radius * 0.06), Color(1, 1, 1, 0.08), 2.0)
	draw_line(head_center + Vector2(head_radius * 0.74, head_radius * 0.32), head_center + Vector2(head_radius * 1.16, head_radius * 0.4), Color(1, 1, 1, 0.06), 2.0)


func _draw_triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	draw_polygon(PackedVector2Array([a, b, c]), PackedColorArray([color, color, color]))
