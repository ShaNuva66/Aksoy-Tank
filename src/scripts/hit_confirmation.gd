extends Node2D

const EFFECT_DURATION := 0.72

var scored_by_local := false
var damage_amount := 1
var destroyed_target := false
var blocked_hit := false
var feedback_text := "İSABET!"
var _elapsed := 0.0
var _accent := Color("#ffd166")
var _label: Label
var _intensity := 1.0
var _reduced_motion := false


func configure(local_score: bool, damage: int = 1, destroyed: bool = false, blocked: bool = false, intensity: float = 1.0, reduced_motion: bool = false) -> void:
	scored_by_local = local_score
	damage_amount = maxi(damage, 1)
	destroyed_target = destroyed
	blocked_hit = blocked
	_intensity = clampf(intensity, 0.0, 1.0)
	_reduced_motion = reduced_motion
	_refresh_style()


func _ready() -> void:
	add_to_group("hit_confirmations")
	z_index = 60
	_refresh_style()
	_create_label()
	scale = Vector2.ONE * 0.72
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / EFFECT_DURATION, 0.0, 1.0)
	position.y -= (8.0 if _reduced_motion else 24.0) * delta
	var pop_strength := 0.04 if _reduced_motion else 0.24 * _intensity
	var pop := 1.0 + sin(minf(progress * 2.2, 1.0) * PI) * pop_strength
	scale = Vector2.ONE * pop
	modulate.a = 1.0 if progress < 0.58 else 1.0 - ((progress - 0.58) / 0.42)
	queue_redraw()
	if _elapsed >= EFFECT_DURATION:
		queue_free()


func _refresh_style() -> void:
	if blocked_hit:
		feedback_text = "KALKAN!"
		_accent = Color("#78d7ff")
	elif destroyed_target:
		feedback_text = "İMHA!"
		_accent = Color("#ffb347")
	elif scored_by_local:
		feedback_text = "İSABET!  -%d" % damage_amount
		_accent = Color("#ffe27a")
	else:
		feedback_text = "HASAR!  -%d" % damage_amount
		_accent = Color("#ff786e")
	if is_instance_valid(_label):
		_label.text = feedback_text
		_label.add_theme_color_override("font_color", _accent)


func _create_label() -> void:
	_label = Label.new()
	_label.position = Vector2(-80.0, -58.0)
	_label.size = Vector2(160.0, 30.0)
	_label.text = feedback_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18 if not destroyed_target else 21)
	_label.add_theme_color_override("font_color", _accent)
	_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.03, 0.95))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _draw() -> void:
	if _intensity <= 0.01:
		return
	var pulse := sin(clampf(_elapsed / 0.22, 0.0, 1.0) * PI)
	var ring_radius := 22.0 + pulse * 9.0
	draw_circle(Vector2.ZERO, 10.0 + pulse * 4.0, Color(_accent, 0.2 * _intensity))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, _accent, 3.0, true)
	for index in range(8):
		var direction := Vector2.RIGHT.rotated(float(index) * TAU / 8.0)
		draw_line(direction * 15.0, direction * (29.0 + pulse * 8.0), _accent, 3.0, true)
	if scored_by_local:
		var marker_color := Color("#fff8d1")
		for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var inner := Vector2(direction.x * 8.0, direction.y * 8.0)
			var outer := Vector2(direction.x * 16.0, direction.y * 16.0)
			draw_line(inner, outer, marker_color, 3.5, true)
