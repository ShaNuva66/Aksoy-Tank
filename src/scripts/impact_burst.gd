extends Node2D

var color: Color = Color("#ffd79b")
var lifetime: float = 0.22
var radius: float = 10.0
var ring_radius: float = 18.0
var intensity: float = 1.0
var reduced_motion := false


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta
	var expansion := 0.35 if reduced_motion else 1.0
	radius += delta * 42.0 * expansion
	ring_radius += delta * 58.0 * expansion
	modulate.a = clamp(lifetime / 0.22, 0.0, 1.0)
	queue_redraw()

	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var draw_color := color
	draw_color.a *= clampf(intensity, 0.0, 1.0)
	if draw_color.a <= 0.01:
		return
	draw_circle(Vector2.ZERO, radius, draw_color)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, draw_color.lightened(0.15), 3.0)
