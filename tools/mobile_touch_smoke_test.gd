extends SceneTree

const MAIN_MENU_SCENE := "res://src/scenes/main_menu.tscn"
const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SMOKE: mobile touch flow started")
	await _load_scene(MAIN_MENU_SCENE)
	await _wait_frames(4)

	if current_scene == null or current_scene.scene_file_path != MAIN_MENU_SCENE:
		_fail("Main menu could not load")
		return

	var start_button := current_scene.get_node_or_null("CenterContainer/Panel/Margin/VBox/StartButton")
	if start_button == null:
		_fail("Start button not found")
		return
	var settings_button = current_scene.get_node_or_null("SettingsButton")
	var settings_overlay = current_scene.get_node_or_null("SettingsOverlay")
	var quick_match_button = current_scene.get_node_or_null("CenterContainer/Panel/Margin/VBox/OnlineConfig/QuickMatchButton")
	if settings_button == null or settings_overlay == null or quick_match_button == null:
		_fail("Settings, accessibility, or quick-match UI is missing")
		return
	settings_button.pressed.emit()
	await _wait_frames(2)
	if not settings_overlay.visible or current_scene._effects_slider == null or current_scene._reduced_motion_toggle == null:
		_fail("Settings overlay did not expose effect accessibility controls")
		return
	var panel_rect: Rect2 = current_scene._settings_panel.get_global_rect()
	var viewport_size := Vector2(current_scene.get_viewport_rect().size)
	if panel_rect.position.x < 0.0 or panel_rect.position.y < 0.0 or panel_rect.end.x > viewport_size.x or panel_rect.end.y > viewport_size.y:
		_fail("Settings panel does not fit inside the mobile viewport")
		return
	current_scene._settings_close_button.pressed.emit()
	await _wait_frames(2)

	start_button.pressed.emit()
	await _wait_frames(12)

	if current_scene == null or current_scene.scene_file_path != ARENA_SCENE:
		_fail("Arena scene did not load after start button")
		return

	print("SMOKE: arena loaded")
	var pause_overlay := current_scene.get_node_or_null("Hud/PauseOverlay")
	var pause_button := current_scene.get_node_or_null("Hud/PauseButton")
	if pause_overlay == null or pause_button == null:
		_fail("Pause UI not found")
		return
	if not pause_button.visible or pause_overlay.visible:
		_fail("Compact mobile pause control is not in its resting state")
		return

	var mobile_controls := current_scene.get_node_or_null("MobileControls")
	if mobile_controls == null:
		_fail("Mobile controls not found")
		return

	var joystick := mobile_controls.get_node_or_null("Root/PlayerOneControls/JoystickShell/JoystickArea")
	var fire_button := mobile_controls.get_node_or_null("Root/PlayerOneControls/FireButton")
	if joystick == null or fire_button == null:
		_fail("Joystick or fire button not found")
		return

	var joystick_center: Vector2 = joystick.get_global_rect().get_center()
	var fire_center: Vector2 = fire_button.get_global_rect().get_center()
	await _drag_and_assert_axis(joystick_center, joystick_center + Vector2(42.0, -46.0), 2)
	await _press_fire_and_assert(fire_center, 3)
	await _wait_frames(18)

	if mobile_controls.has_method("get_move_vector"):
		var axis: Vector2 = mobile_controls.get_move_vector(1)
		print("SMOKE: final axis=", axis)

	if not _failed:
		print("SMOKE: PASS")
	quit(0 if not _failed else 1)


func _load_scene(path: String) -> void:
	var scene := load(path)
	if scene == null:
		_fail("Scene could not be loaded: " + path)
		return

	var instance: Node = scene.instantiate()
	root.add_child(instance)
	current_scene = instance
	await process_frame


func _tap(position: Vector2, pointer_id: int) -> void:
	var down := InputEventScreenTouch.new()
	down.index = pointer_id
	down.position = position
	down.pressed = true
	_send_input(down)
	await _wait_frames(2)

	var up := InputEventScreenTouch.new()
	up.index = pointer_id
	up.position = position
	up.pressed = false
	_send_input(up)
	await _wait_frames(2)


func _tap_arena(position: Vector2, pointer_id: int) -> void:
	var down := InputEventScreenTouch.new()
	down.index = pointer_id
	down.position = position
	down.pressed = true
	_send_input(down)
	await _wait_frames(2)

	var up := InputEventScreenTouch.new()
	up.index = pointer_id
	up.position = position
	up.pressed = false
	Input.parse_input_event(up)
	await _wait_frames(2)


func _drag(from_position: Vector2, to_position: Vector2, pointer_id: int) -> void:
	var down := InputEventScreenTouch.new()
	down.index = pointer_id
	down.position = from_position
	down.pressed = true
	Input.parse_input_event(down)
	await _wait_frames(2)

	for step in range(1, 8):
		var drag := InputEventScreenDrag.new()
		drag.index = pointer_id
		drag.position = from_position.lerp(to_position, float(step) / 7.0)
		drag.relative = drag.position - from_position
		_send_input(drag)
		await process_frame

	var up := InputEventScreenTouch.new()
	up.index = pointer_id
	up.position = to_position
	up.pressed = false
	_send_input(up)
	await _wait_frames(2)


func _drag_and_assert_axis(from_position: Vector2, to_position: Vector2, pointer_id: int) -> void:
	var mobile_controls := current_scene.get_node_or_null("MobileControls")
	if mobile_controls == null:
		_fail("Mobile controls not found before drag")
		return

	var down := InputEventScreenTouch.new()
	down.index = pointer_id
	down.position = from_position
	down.pressed = true
	_send_input(down)
	await _wait_frames(2)

	var previous := from_position
	for step in range(1, 8):
		var drag := InputEventScreenDrag.new()
		drag.index = pointer_id
		drag.position = from_position.lerp(to_position, float(step) / 7.0)
		drag.relative = drag.position - previous
		previous = drag.position
		_send_input(drag)
		await process_frame

	var axis: Vector2 = mobile_controls.get_move_vector(1)
	if axis.length() <= 0.05:
		_fail("Joystick axis did not react to touch drag")
		return

	var up := InputEventScreenTouch.new()
	up.index = pointer_id
	up.position = to_position
	up.pressed = false
	_send_input(up)
	await _wait_frames(2)


func _press_fire_and_assert(position: Vector2, pointer_id: int) -> void:
	var mobile_controls := current_scene.get_node_or_null("MobileControls")
	if mobile_controls == null:
		_fail("Mobile controls not found before fire")
		return

	var down := InputEventScreenTouch.new()
	down.index = pointer_id
	down.position = position
	down.pressed = true
	_send_input(down)
	await _wait_frames(2)

	if not mobile_controls.is_fire_pressed(1):
		_fail("Fire button did not react to touch")
		return

	var up := InputEventScreenTouch.new()
	up.index = pointer_id
	up.position = position
	up.pressed = false
	_send_input(up)
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _send_input(event: InputEvent) -> void:
	root.push_input(event, true)
	if event is InputEventScreenTouch:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = event.position
		mouse.global_position = event.position
		mouse.pressed = event.pressed
		root.push_input(mouse, true)
	elif event is InputEventScreenDrag:
		var motion := InputEventMouseMotion.new()
		motion.position = event.position
		motion.global_position = event.position
		motion.relative = event.relative
		root.push_input(motion, true)


func _fail(message: String) -> void:
	_failed = true
	push_error("SMOKE FAIL: " + message)
	print("SMOKE: FAIL - " + message)
	quit(1)
