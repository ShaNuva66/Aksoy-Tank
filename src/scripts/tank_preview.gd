extends Control

const TankRenderer := preload("res://src/scripts/tank_renderer.gd")

var _profile: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile = GameSession.get_network_profile()
	queue_redraw()


func set_profile(profile: Dictionary) -> void:
	_profile = Dictionary(profile.duplicate(true))
	queue_redraw()


func _draw() -> void:
	draw_set_transform(size * 0.5 + Vector2(0.0, 4.0), 0.0, Vector2(1.32, 1.32))
	TankRenderer.draw_player_tank(self, _profile)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
