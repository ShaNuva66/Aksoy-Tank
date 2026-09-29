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
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var game_session := tree.root.get_node_or_null("GameSession")
		if game_session and game_session.has_method("is_haptics_enabled") and not game_session.is_haptics_enabled():
			return
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms)
