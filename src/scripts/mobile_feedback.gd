extends RefCounted


static func tap() -> void:
	_vibrate(18)


static func fire() -> void:
	_vibrate(24)


static func confirmed_hit() -> void:
	_vibrate(30)


static func reward() -> void:
	_vibrate(36)


static func damage() -> void:
	_vibrate(58)


static func _vibrate(duration_ms: int) -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms)
