extends StaticBody2D

signal destroyed(block_type: String)

@export var block_type: String = "brick"
@export var durability: int = 1
var theme_palette: Dictionary = {}
var _flash_time := 0.0
var _max_durability := 1


func _ready() -> void:
	add_to_group("blocks")
	collision_layer = 2
	collision_mask = 1
	_max_durability = maxi(durability, 1)
	set_process(true)
	queue_redraw()


func take_hit(_source_team: String = "", damage: int = 1) -> bool:
	_flash_time = 0.12
	queue_redraw()

	if block_type == "steel":
		return false

	var applied_damage := 1 if block_type == "fortified" else maxi(damage, 1)
	durability -= applied_damage

	if durability <= 0:
		destroyed.emit(block_type)
		queue_free()
		return true

	queue_redraw()
	return true


func _process(delta: float) -> void:
	if _flash_time <= 0.0:
		return

	_flash_time = max(_flash_time - delta, 0.0)
	queue_redraw()


func apply_theme(new_theme_palette: Dictionary) -> void:
	theme_palette = Dictionary(new_theme_palette.duplicate(true))
	queue_redraw()


func _draw() -> void:
	var body_color := _get_theme_color("brick_body", Color("#8c5e3c"))
	var line_color := _get_theme_color("brick_line", Color("#d9b38c"))

	if block_type == "steel":
		body_color = _get_theme_color("steel_body", Color("#6f7c89"))
		line_color = _get_theme_color("steel_line", Color("#cad3dd"))
	elif block_type == "fortified":
		body_color = _get_theme_color("brick_body", Color("#8c5e3c")).darkened(0.12)
		line_color = _get_theme_color("base_line", Color("#fff1b2")).lerp(Color("#cad3dd"), 0.42)
	elif block_type == "base":
		var accent := _get_theme_color("base_body", Color("#d3ad58"))
		var base_core := _get_theme_color("base_core", Color("#121820"))
		body_color = base_core.darkened(0.18)
		line_color = accent.lerp(base_core, 0.58)

	var flash_mix: float = 0.0 if _flash_time <= 0.0 else min(_flash_time * 9.0, 1.0)
	body_color = body_color.lerp(Color.WHITE, flash_mix * 0.7)
	line_color = line_color.lerp(Color.WHITE, flash_mix)

	draw_rect(Rect2(Vector2(-23.0, -23.0), Vector2(46.0, 46.0)), body_color)
	draw_rect(Rect2(Vector2(-23.0, -23.0), Vector2(46.0, 46.0)), line_color, false, 3.0)

	if block_type == "brick":
		draw_line(Vector2(-23.0, 0.0), Vector2(23.0, 0.0), line_color, 2.0)
		draw_line(Vector2(-7.0, -23.0), Vector2(-7.0, 0.0), line_color, 2.0)
		draw_line(Vector2(7.0, 0.0), Vector2(7.0, 23.0), line_color, 2.0)
	elif block_type == "steel":
		draw_line(Vector2(-16.0, -16.0), Vector2(16.0, 16.0), line_color, 2.0)
		draw_line(Vector2(16.0, -16.0), Vector2(-16.0, 16.0), line_color, 2.0)
	elif block_type == "fortified":
		draw_line(Vector2(-18.0, -12.0), Vector2(18.0, -12.0), line_color, 3.0)
		draw_line(Vector2(-18.0, 0.0), Vector2(18.0, 0.0), line_color, 3.0)
		draw_line(Vector2(-18.0, 12.0), Vector2(18.0, 12.0), line_color, 3.0)
	elif block_type == "base":
		_draw_cat_emblem(
			_get_theme_color("base_core", Color("#121820")).darkened(0.26),
			_get_theme_color("base_line", Color("#fff1b2")).lerp(_get_theme_color("base_body", Color("#d3ad58")), 0.42)
		)

	if block_type in ["fortified", "base"] and _max_durability > 1:
		var durability_ratio := clampf(float(durability) / float(_max_durability), 0.0, 1.0)
		draw_rect(Rect2(Vector2(-18.0, 18.0), Vector2(36.0, 3.0)), Color(0.02, 0.03, 0.04, 0.75))
		draw_rect(Rect2(Vector2(-18.0, 18.0), Vector2(36.0 * durability_ratio, 3.0)), line_color)


func _get_theme_color(key: String, fallback: Color) -> Color:
	if theme_palette.has(key):
		return theme_palette[key]

	return fallback


func _draw_cat_emblem(cat_color: Color, eye_color: Color) -> void:
	draw_circle(Vector2(0.0, 6.0), 11.0, cat_color)
	draw_circle(Vector2(0.0, -8.0), 9.0, cat_color)
	draw_polygon(
		PackedVector2Array([
			Vector2(-8.0, -10.0),
			Vector2(-4.0, -19.0),
			Vector2(-1.5, -10.5)
		]),
		PackedColorArray([cat_color, cat_color, cat_color])
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(8.0, -10.0),
			Vector2(4.0, -19.0),
			Vector2(1.5, -10.5)
		]),
		PackedColorArray([cat_color, cat_color, cat_color])
	)
	draw_arc(Vector2(7.0, 8.0), 8.5, -0.45, 1.15, 16, cat_color, 3.0)
	draw_circle(Vector2(-4.8, -7.0), 2.2, eye_color)
	draw_circle(Vector2(4.8, -7.0), 2.2, eye_color)
	draw_line(Vector2(-5.2, -9.0), Vector2(-5.2, -4.0), cat_color.lightened(0.18), 1.0)
	draw_line(Vector2(5.2, -9.0), Vector2(5.2, -4.0), cat_color.lightened(0.18), 1.0)
