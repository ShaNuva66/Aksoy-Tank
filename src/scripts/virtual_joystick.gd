extends Control

var _axis := Vector2.ZERO
var _dragging := false
var _pointer_id := -1
var _knob_offset := Vector2.ZERO
var _enabled := true
var _touch_pulse := 0.0

const PAD_RADIUS := 82.0
const KNOB_RADIUS := 34.0
const DEADZONE := 0.1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed and _pointer_id == -1:
			_pointer_id = event.index
			_dragging = true
			_start_touch_feedback()
			_update_axis_from_position(event.position)
			accept_event()
		elif not event.pressed and event.index == _pointer_id:
			_reset_state()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		_update_axis_from_position(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_id = 0
			_dragging = true
			_start_touch_feedback()
			_update_axis_from_position(event.position)
			accept_event()
		elif not event.pressed and _pointer_id == 0:
			_reset_state()
			accept_event()
	elif event is InputEventMouseMotion and _dragging and _pointer_id == 0:
		_update_axis_from_position(event.position)
		accept_event()


func get_axis() -> Vector2:
	return _axis


func set_enabled(enabled: bool) -> void:
	_enabled = enabled

	if not enabled:
		_reset_state()


func apply_external_screen_position(screen_position: Vector2) -> void:
	var local_position := screen_position - get_global_rect().position
	if not _dragging:
		_start_touch_feedback()
	_dragging = true
	_update_axis_from_position(local_position)


func release_external_touch() -> void:
	_reset_state()


func _update_axis_from_position(position: Vector2) -> void:
	var center := size * 0.5
	var delta := position - center

	if delta.length() > PAD_RADIUS:
		delta = delta.normalized() * PAD_RADIUS

	_knob_offset = delta
	_axis = delta / PAD_RADIUS

	if _axis.length() < DEADZONE:
		_axis = Vector2.ZERO
	else:
		var normalized := _axis.normalized()
		var strength := clampf((_axis.length() - DEADZONE) / (1.0 - DEADZONE), 0.0, 1.0)
		_axis = normalized * strength
	queue_redraw()


func _reset_state() -> void:
	_dragging = false
	_pointer_id = -1
	_axis = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	if _touch_pulse <= 0.0:
		return

	_touch_pulse = maxf(_touch_pulse - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var pulse := clampf(_touch_pulse / 0.2, 0.0, 1.0)

	draw_circle(center, PAD_RADIUS, Color(0.12, 0.18, 0.22, 0.44))
	if _dragging or pulse > 0.0:
		var ring := Color(0.95, 0.82, 0.48, 0.24 + pulse * 0.18)
		draw_arc(center, PAD_RADIUS + 6.0 + (1.0 - pulse) * 8.0, 0.0, TAU, 48, ring, 4.0)
	draw_circle(center + _knob_offset, KNOB_RADIUS * (0.92 if _dragging else 1.0), Color(0.87, 0.67, 0.34, 0.9))


func _start_touch_feedback() -> void:
	_touch_pulse = 0.2
	queue_redraw()
