extends CanvasLayer

const STYLE_ANALOG := "analog"
const STYLE_BUTTONS := "buttons"

var _controls_enabled := true
var _local_player_count := 1
var _primary_slot := 1
var _control_style := STYLE_ANALOG
var _joystick_pointer_by_slot := {}
var _fire_pointer_by_slot := {}
var _button_pointer_to_button := {}

@onready var player_one_root: Control = $Root/PlayerOneControls
@onready var player_one_shell: Control = $Root/PlayerOneControls/JoystickShell
@onready var player_one_joystick = $Root/PlayerOneControls/JoystickShell/JoystickArea
@onready var player_one_button_pad: Control = $Root/PlayerOneControls/ButtonPad
@onready var player_one_up = $Root/PlayerOneControls/ButtonPad/UpButton
@onready var player_one_left = $Root/PlayerOneControls/ButtonPad/LeftButton
@onready var player_one_right = $Root/PlayerOneControls/ButtonPad/RightButton
@onready var player_one_down = $Root/PlayerOneControls/ButtonPad/DownButton
@onready var player_one_fire = $Root/PlayerOneControls/FireButton
@onready var player_two_root: Control = $Root/PlayerTwoControls
@onready var player_two_shell: Control = $Root/PlayerTwoControls/JoystickShell
@onready var player_two_joystick = $Root/PlayerTwoControls/JoystickShell/JoystickArea
@onready var player_two_button_pad: Control = $Root/PlayerTwoControls/ButtonPad
@onready var player_two_up = $Root/PlayerTwoControls/ButtonPad/UpButton
@onready var player_two_left = $Root/PlayerTwoControls/ButtonPad/LeftButton
@onready var player_two_right = $Root/PlayerTwoControls/ButtonPad/RightButton
@onready var player_two_down = $Root/PlayerTwoControls/ButtonPad/DownButton
@onready var player_two_fire = $Root/PlayerTwoControls/FireButton
@onready var hint_label: Label = $Root/HintLabel


func _ready() -> void:
	add_to_group("mobile_controls")
	set_process_input(true)
	$Root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_one_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_one_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_one_shell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	player_one_joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_one_button_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_one_up.mouse_filter = Control.MOUSE_FILTER_STOP
	player_one_left.mouse_filter = Control.MOUSE_FILTER_STOP
	player_one_right.mouse_filter = Control.MOUSE_FILTER_STOP
	player_one_down.mouse_filter = Control.MOUSE_FILTER_STOP
	player_one_fire.mouse_filter = Control.MOUSE_FILTER_STOP
	player_two_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_two_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_two_shell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	player_two_joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_two_button_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_two_up.mouse_filter = Control.MOUSE_FILTER_STOP
	player_two_left.mouse_filter = Control.MOUSE_FILTER_STOP
	player_two_right.mouse_filter = Control.MOUSE_FILTER_STOP
	player_two_down.mouse_filter = Control.MOUSE_FILTER_STOP
	player_two_fire.mouse_filter = Control.MOUSE_FILTER_STOP
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.visible = false
	player_two_root.visible = false
	_control_style = GameSession.get_control_style() if GameSession.has_method("get_control_style") else STYLE_ANALOG
	configure_layout(1, 1)
	get_viewport().size_changed.connect(_clear_touch_state)


func _notification(what: int) -> void:
	if is_node_ready() and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_clear_touch_state()


func configure_player_count(count: int) -> void:
	configure_layout(count, 1)


func configure_layout(local_player_count: int, primary_slot: int = 1) -> void:
	_clear_touch_state()
	_local_player_count = clampi(local_player_count, 1, 2)
	_primary_slot = clampi(primary_slot, 1, 2)
	player_two_root.visible = _local_player_count > 1
	_apply_layout()
	_apply_style_visibility()
	_apply_enabled_state()

	if player_one_fire.has_method("set_label_text"):
		player_one_fire.set_label_text("ATES" if _local_player_count == 1 else "P1")
	if player_two_fire.has_method("set_label_text"):
		player_two_fire.set_label_text("P2")


func set_control_style(style: String, persist: bool = false) -> void:
	_control_style = STYLE_ANALOG
	_apply_style_visibility()
	_apply_enabled_state()

	if persist and GameSession.has_method("set_control_style"):
		GameSession.set_control_style(STYLE_ANALOG)


func get_control_style() -> String:
	return _control_style


func get_move_vector(player_slot: int = 1) -> Vector2:
	if not _controls_enabled or _control_style != STYLE_ANALOG:
		return Vector2.ZERO

	return _shape_analog_axis(_get_joystick_axis(player_slot))


func get_turn_axis(player_slot: int = 1) -> float:
	if not _controls_enabled:
		return 0.0

	if _control_style == STYLE_BUTTONS:
		return _get_button_turn(player_slot)

	var shaped_axis := _shape_analog_axis(_get_joystick_axis(player_slot))
	if absf(shaped_axis.x) > absf(shaped_axis.y) * 0.82:
		return shaped_axis.x
	return 0.0


func get_move_axis(player_slot: int = 1) -> float:
	if not _controls_enabled:
		return 0.0

	if _control_style == STYLE_BUTTONS:
		return _get_button_move(player_slot)

	var shaped_axis := _shape_analog_axis(_get_joystick_axis(player_slot))
	if absf(shaped_axis.y) >= absf(shaped_axis.x):
		return maxf(-shaped_axis.y, 0.0)
	return 0.0


func is_fire_pressed(player_slot: int = 1) -> bool:
	if not _controls_enabled:
		return false

	if _local_player_count > 1 and player_slot == 2:
		return player_two_fire.is_pressed()

	if _local_player_count == 1 and player_slot != _primary_slot:
		return false

	return player_one_fire.is_pressed()


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	visible = enabled
	if not enabled:
		_clear_touch_state()
	_apply_enabled_state()


func _input(event: InputEvent) -> void:
	if not _controls_enabled or not visible:
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _apply_layout() -> void:
	if _local_player_count > 1:
		player_one_root.anchor_left = 0.0
		player_one_root.anchor_top = 1.0
		player_one_root.anchor_right = 0.0
		player_one_root.anchor_bottom = 1.0
		player_one_root.offset_left = 0.0
		player_one_root.offset_top = -282.0
		player_one_root.offset_right = 430.0
		player_one_root.offset_bottom = 0.0
		player_one_shell.offset_left = 12.0
		player_one_shell.offset_top = 18.0
		player_one_shell.offset_right = 276.0
		player_one_shell.offset_bottom = 258.0
		player_one_joystick.offset_left = 6.0
		player_one_joystick.offset_top = 6.0
		player_one_joystick.offset_right = 258.0
		player_one_joystick.offset_bottom = 234.0
		player_one_button_pad.offset_left = 16.0
		player_one_button_pad.offset_top = 24.0
		player_one_button_pad.offset_right = 252.0
		player_one_button_pad.offset_bottom = 244.0
		player_one_fire.anchor_left = 0.0
		player_one_fire.anchor_right = 0.0
		player_one_fire.offset_left = 286.0
		player_one_fire.offset_top = 70.0
		player_one_fire.offset_right = 420.0
		player_one_fire.offset_bottom = 210.0

		player_two_root.anchor_left = 1.0
		player_two_root.anchor_top = 1.0
		player_two_root.anchor_right = 1.0
		player_two_root.anchor_bottom = 1.0
		player_two_root.offset_left = -430.0
		player_two_root.offset_top = -282.0
		player_two_root.offset_right = 0.0
		player_two_root.offset_bottom = 0.0
		player_two_fire.offset_left = 10.0
		player_two_fire.offset_top = 70.0
		player_two_fire.offset_right = 154.0
		player_two_fire.offset_bottom = 210.0
		player_two_shell.offset_left = 164.0
		player_two_shell.offset_top = 18.0
		player_two_shell.offset_right = 424.0
		player_two_shell.offset_bottom = 258.0
		player_two_joystick.offset_left = 6.0
		player_two_joystick.offset_top = 6.0
		player_two_joystick.offset_right = 254.0
		player_two_joystick.offset_bottom = 234.0
		player_two_button_pad.offset_left = 178.0
		player_two_button_pad.offset_top = 24.0
		player_two_button_pad.offset_right = 414.0
		player_two_button_pad.offset_bottom = 244.0
		return

	player_one_root.anchor_left = 0.0
	player_one_root.anchor_top = 1.0
	player_one_root.anchor_right = 1.0
	player_one_root.anchor_bottom = 1.0
	player_one_root.offset_left = 0.0
	player_one_root.offset_top = -286.0
	player_one_root.offset_right = 0.0
	player_one_root.offset_bottom = 0.0
	player_one_shell.offset_left = 18.0
	player_one_shell.offset_top = 16.0
	player_one_shell.offset_right = 284.0
	player_one_shell.offset_bottom = 264.0
	player_one_joystick.offset_left = 7.0
	player_one_joystick.offset_top = 8.0
	player_one_joystick.offset_right = 259.0
	player_one_joystick.offset_bottom = 240.0
	player_one_button_pad.offset_left = 18.0
	player_one_button_pad.offset_top = 20.0
	player_one_button_pad.offset_right = 254.0
	player_one_button_pad.offset_bottom = 240.0
	player_one_fire.anchor_left = 1.0
	player_one_fire.anchor_right = 1.0
	player_one_fire.offset_left = -200.0
	player_one_fire.offset_top = 48.0
	player_one_fire.offset_right = -28.0
	player_one_fire.offset_bottom = 220.0


func _apply_style_visibility() -> void:
	player_one_shell.visible = true
	player_one_button_pad.visible = false
	player_two_shell.visible = _local_player_count > 1
	player_two_button_pad.visible = false


func _apply_enabled_state() -> void:
	if player_one_joystick and player_one_joystick.has_method("set_enabled"):
		player_one_joystick.set_enabled(_controls_enabled and _control_style == STYLE_ANALOG)
	if player_two_joystick and player_two_joystick.has_method("set_enabled"):
		player_two_joystick.set_enabled(_controls_enabled and _control_style == STYLE_ANALOG and _local_player_count > 1)

	_set_button_group_enabled(1, _controls_enabled and _control_style == STYLE_BUTTONS)
	_set_button_group_enabled(2, _controls_enabled and _control_style == STYLE_BUTTONS and _local_player_count > 1)

	if player_one_fire and player_one_fire.has_method("set_enabled"):
		player_one_fire.set_enabled(_controls_enabled)
	if player_two_fire and player_two_fire.has_method("set_enabled"):
		player_two_fire.set_enabled(_controls_enabled and _local_player_count > 1)


func _set_button_group_enabled(player_slot: int, enabled: bool) -> void:
	var buttons := _get_direction_buttons(player_slot)
	for button in buttons.values():
		if button and button.has_method("set_enabled"):
			button.set_enabled(enabled)


func _get_joystick_axis(player_slot: int) -> Vector2:
	if _local_player_count > 1 and player_slot == 2:
		return player_two_joystick.get_axis()

	if _local_player_count == 1 and player_slot != _primary_slot:
		return Vector2.ZERO

	return player_one_joystick.get_axis()


func _shape_analog_axis(axis: Vector2) -> Vector2:
	var length := axis.length()
	if length < 0.08:
		return Vector2.ZERO

	var normalized := axis / length
	var mapped_strength := pow(clampf((length - 0.08) / 0.92, 0.0, 1.0), 1.08)
	var shaped := normalized * mapped_strength

	return shaped


func _get_button_turn(player_slot: int) -> float:
	var buttons := _get_direction_buttons(player_slot)
	var left_pressed: bool = buttons["left"].is_pressed()
	var right_pressed: bool = buttons["right"].is_pressed()

	if left_pressed == right_pressed:
		return 0.0
	return -1.0 if left_pressed else 1.0


func _get_button_move(player_slot: int) -> float:
	var buttons := _get_direction_buttons(player_slot)
	var up_pressed: bool = buttons["up"].is_pressed()
	var down_pressed: bool = buttons["down"].is_pressed()

	if up_pressed == down_pressed:
		return 0.0
	return 1.0 if up_pressed else -0.75


func _get_direction_buttons(player_slot: int) -> Dictionary:
	if _local_player_count > 1 and player_slot == 2:
		return {
			"up": player_two_up,
			"left": player_two_left,
			"right": player_two_right,
			"down": player_two_down
		}

	return {
		"up": player_one_up,
		"left": player_one_left,
		"right": player_one_right,
		"down": player_one_down
	}


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _try_bind_fire_pointer(event.index, event.position):
			return
		if _control_style == STYLE_ANALOG:
			_try_bind_joystick_pointer(event.index, event.position)
		else:
			_try_bind_button_pointer(event.index, event.position)
		return

	_release_touch_pointer(event.index)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	_update_pointer_position(event.index, event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var pointer_id := 999
	if event.pressed:
		if _try_bind_fire_pointer(pointer_id, event.position):
			return
		if _control_style == STYLE_ANALOG:
			_try_bind_joystick_pointer(pointer_id, event.position)
		else:
			_try_bind_button_pointer(pointer_id, event.position)
		return

	_release_touch_pointer(pointer_id)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	_update_pointer_position(999, event.position)


func _update_pointer_position(pointer_id: int, position: Vector2) -> void:
	for slot in _joystick_pointer_by_slot.keys():
		if _joystick_pointer_by_slot[slot] == pointer_id:
			var joystick = _get_joystick_control(int(slot))
			if joystick and joystick.has_method("apply_external_screen_position"):
				joystick.apply_external_screen_position(position)
			return

	for slot in _fire_pointer_by_slot.keys():
		if _fire_pointer_by_slot[slot] == pointer_id:
			var fire_button = _get_fire_button(int(slot))
			if fire_button and fire_button.has_method("set_external_pressed"):
				fire_button.set_external_pressed(_is_point_inside_control(fire_button, position, 34.0))
			return

	if _button_pointer_to_button.has(pointer_id):
		var active_button: Control = _button_pointer_to_button[pointer_id]
		if active_button and active_button.has_method("set_external_pressed"):
			active_button.set_external_pressed(_is_point_inside_control(active_button, position, 28.0))


func _try_bind_fire_pointer(pointer_id: int, position: Vector2) -> bool:
	for slot in _get_available_slots():
		if _fire_pointer_by_slot.has(slot):
			continue
		var fire_button = _get_fire_button(slot)
		if fire_button and _is_point_inside_control(fire_button, position, 26.0):
			_fire_pointer_by_slot[slot] = pointer_id
			fire_button.set_external_pressed(true)
			return true
	return false


func _try_bind_joystick_pointer(pointer_id: int, position: Vector2) -> bool:
	for slot in _get_available_slots():
		if _joystick_pointer_by_slot.has(slot):
			continue
		var joystick = _get_joystick_control(slot)
		var viewport_size := get_viewport().get_visible_rect().size
		var movement_zone := Rect2(Vector2(0, viewport_size.y * 0.32), Vector2(viewport_size.x * 0.48, viewport_size.y * 0.68))
		var inside := movement_zone.has_point(position) if _local_player_count == 1 else _is_point_inside_control(joystick, position, 42.0)
		if joystick and inside:
			_joystick_pointer_by_slot[slot] = pointer_id
			joystick.apply_external_screen_position(position)
			return true
	return false


func _try_bind_button_pointer(pointer_id: int, position: Vector2) -> bool:
	for slot in _get_available_slots():
		for button in _get_direction_buttons(slot).values():
			if button and _is_point_inside_control(button, position, 24.0):
				_button_pointer_to_button[pointer_id] = button
				button.set_external_pressed(true)
				return true
	return false


func _release_touch_pointer(pointer_id: int) -> void:
	for slot in _joystick_pointer_by_slot.keys():
		if _joystick_pointer_by_slot[slot] == pointer_id:
			var joystick = _get_joystick_control(int(slot))
			if joystick and joystick.has_method("release_external_touch"):
				joystick.release_external_touch()
			_joystick_pointer_by_slot.erase(slot)
			return

	for slot in _fire_pointer_by_slot.keys():
		if _fire_pointer_by_slot[slot] == pointer_id:
			var fire_button = _get_fire_button(int(slot))
			if fire_button and fire_button.has_method("set_external_pressed"):
				fire_button.set_external_pressed(false)
			_fire_pointer_by_slot.erase(slot)
			return

	if _button_pointer_to_button.has(pointer_id):
		var active_button: Control = _button_pointer_to_button[pointer_id]
		if active_button and active_button.has_method("set_external_pressed"):
			active_button.set_external_pressed(false)
		_button_pointer_to_button.erase(pointer_id)


func _clear_touch_state() -> void:
	for slot in _get_available_slots():
		var joystick = _get_joystick_control(slot)
		if joystick and joystick.has_method("release_external_touch"):
			joystick.release_external_touch()
		var fire_button = _get_fire_button(slot)
		if fire_button and fire_button.has_method("set_external_pressed"):
			fire_button.set_external_pressed(false)
		for button in _get_direction_buttons(slot).values():
			if button and button.has_method("set_external_pressed"):
				button.set_external_pressed(false)

	_joystick_pointer_by_slot.clear()
	_fire_pointer_by_slot.clear()
	_button_pointer_to_button.clear()


func _get_available_slots() -> Array:
	if _local_player_count > 1:
		return [1, 2]
	return [_primary_slot]


func _get_joystick_control(player_slot: int) -> Control:
	if _local_player_count > 1 and player_slot == 2:
		return player_two_joystick
	return player_one_joystick


func _get_fire_button(player_slot: int) -> Control:
	if _local_player_count > 1 and player_slot == 2:
		return player_two_fire
	return player_one_fire


func _is_point_inside_control(control: Control, screen_position: Vector2, margin: float = 0.0) -> bool:
	var rect := control.get_global_rect()
	rect.position -= Vector2.ONE * margin
	rect.size += Vector2.ONE * margin * 2.0
	return rect.has_point(screen_position)
