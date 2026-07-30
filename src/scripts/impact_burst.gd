extends Node2D

var color: Color = Color("#ffd79b")
var lifetime: float = 0.22
var radius: float = 10.0
var ring_radius: float = 18.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta
	radius += delta * 42.0
	ring_radius += delta * 58.0
	modulate.a = clamp(lifetime / 0.22, 0.0, 1.0)
	queue_redraw()

	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, color.lightened(0.15), 3.0)
