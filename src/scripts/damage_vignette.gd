extends Control

var _flash_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func flash() -> void:
	_flash_time = 0.48
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_time <= 0.0:
		return

	_flash_time = maxf(_flash_time - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if _flash_time <= 0.0:
		return

	var strength := clampf(_flash_time / 0.48, 0.0, 1.0)
	var red := Color("#ff3f4f")
	red.a = 0.08 + strength * 0.18
	var edge := 16.0 + strength * 18.0

	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, edge)), red)
	draw_rect(Rect2(Vector2(0.0, size.y - edge), Vector2(size.x, edge)), red)
	draw_rect(Rect2(Vector2.ZERO, Vector2(edge, size.y)), red)
	draw_rect(Rect2(Vector2(size.x - edge, 0.0), Vector2(edge, size.y)), red)

	var vein := Color("#ff6b6b")
	vein.a = 0.25 * strength
	var branches := [
		[Vector2(18, 64), Vector2(56, 96), Vector2(82, 118)],
		[Vector2(32, size.y - 72), Vector2(72, size.y - 108), Vector2(108, size.y - 126)],
		[Vector2(size.x - 26, 86), Vector2(size.x - 72, 116), Vector2(size.x - 118, 138)],
		[Vector2(size.x - 38, size.y - 64), Vector2(size.x - 82, size.y - 98), Vector2(size.x - 136, size.y - 118)]
	]
	for branch in branches:
		draw_polyline(PackedVector2Array(branch), vein, 3.0)
		draw_line(branch[1], branch[1] + (branch[1] - branch[0]).rotated(0.65) * 0.36, vein, 2.0)
		draw_line(branch[1], branch[1] + (branch[1] - branch[0]).rotated(-0.65) * 0.28, vein, 2.0)
