extends Control

const MobileFeedback := preload("res://src/scripts/mobile_feedback.gd")

@export var label_text := "ATES"
@export var base_color: Color = Color("#b96e34")
@export var active_color: Color = Color("#ffd27c")
@export var label_font_size := 18

var _pressed := false
var _pointer_id := -1
var _enabled := true
var _feedback_time := 0.0

@onready var label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.add_theme_font_size_override("font_size", label_font_size)
	set_process(true)
	queue_redraw()


func is_pressed() -> bool:
	return _pressed and _enabled


func set_label_text(value: String) -> void:
	label_text = value
	if label:
		label.text = label_text


func set_enabled(enabled: bool) -> void:
	_enabled = enabled

	if not enabled:
		_reset_state()

	label.visible = enabled


func set_external_pressed(pressed: bool) -> void:
	if not _enabled:
		_reset_state()
		return

	_set_pressed(pressed)


func _gui_input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed and _pointer_id == -1 and _contains_point(event.position):
			_pointer_id = event.index
			_set_pressed(true)
			accept_event()
		elif not event.pressed and event.index == _pointer_id:
			_reset_state()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		_set_pressed(_contains_point(event.position, 28.0))
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _contains_point(event.position):
			_pointer_id = 0
			_set_pressed(true)
			accept_event()
		elif not event.pressed and _pointer_id == 0:
			_reset_state()
			accept_event()
	elif event is InputEventMouseMotion and _pointer_id == 0:
		_set_pressed(_contains_point(event.position, 20.0))
		accept_event()


func _process(delta: float) -> void:
	if _feedback_time <= 0.0:
		return

	_feedback_time = maxf(_feedback_time - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var pulse := clampf(_feedback_time / 0.18, 0.0, 1.0)
	var radius: float = minf(size.x, size.y) * (0.37 if _pressed else 0.4)
	var ring_color := active_color if _pressed else base_color.lightened(0.12)
	var fill_color := base_color
	fill_color.a = 0.86 if _pressed else 0.72

	draw_circle(center, radius, fill_color)
	draw_arc(center, radius + 1.0, 0.0, TAU, 36, ring_color, 2.0)
	draw_circle(center, radius * 0.38, ring_color.darkened(0.06))

	if pulse > 0.0:
		var ripple := active_color
		ripple.a = 0.3 * pulse
		draw_arc(center, radius + 12.0 * (1.0 - pulse), 0.0, TAU, 36, ripple, 4.0)


func _reset_state() -> void:
	_set_pressed(false)
	_pointer_id = -1
	queue_redraw()


func _set_pressed(pressed: bool) -> void:
	if _pressed == pressed:
		return

	_pressed = pressed
	if pressed:
		_feedback_time = 0.18
		MobileFeedback.tap()
	queue_redraw()


func _contains_point(point: Vector2, margin: float = 0.0) -> bool:
	return Rect2(Vector2(-margin, -margin), size + Vector2.ONE * margin * 2.0).has_point(point)
