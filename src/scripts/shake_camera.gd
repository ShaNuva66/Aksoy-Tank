extends Camera2D

var _shake_time := 0.0
var _shake_strength := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func add_shake(duration: float, strength: float) -> void:
	_shake_time = max(_shake_time, duration)
	_shake_strength = max(_shake_strength, strength)


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time = max(_shake_time - delta, 0.0)
		offset = Vector2(
			_rng.randf_range(-_shake_strength, _shake_strength),
			_rng.randf_range(-_shake_strength, _shake_strength)
		)

		if _shake_time <= 0.0:
			offset = Vector2.ZERO
