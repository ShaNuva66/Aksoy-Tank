extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var controls = load("res://src/scenes/mobile_controls.tscn").instantiate()
	root.add_child(controls)
	await process_frame
	var viewport_size: Vector2 = root.get_visible_rect().size
	for fraction in [Vector2(0.05, 0.45), Vector2(0.33, 0.6), Vector2(0.12, 0.82)]:
		var origin: Vector2 = viewport_size * fraction
		touch(controls, 1, origin, true)
		check(controls.get_move_vector().is_zero_approx(), "Touch-down caused unwanted movement")
		drag(controls, 1, origin + Vector2(100, 0))
		check(controls.get_move_vector().x > 0.9, "Floating origin did not steer right")
		touch(controls, 2, origin + Vector2(0, 80), true)
		drag(controls, 2, origin - Vector2(100, 0))
		check(controls.get_move_vector().x > 0.9, "Second finger stole the analog")
		touch(controls, 3, controls.player_one_fire.get_global_rect().get_center(), true)
		check(controls.is_fire_pressed(), "Fire did not work alongside movement")
		drag(controls, 1, origin - Vector2(100, 0))
		check(controls.get_move_vector().x < -0.9, "Direction could not change without lifting")
		touch(controls, 3, Vector2.ZERO, false)
		check(not controls.is_fire_pressed() and controls.get_move_vector().x < -0.9, "Fire release interrupted movement")
		touch(controls, 1, Vector2.ZERO, false)
		touch(controls, 2, Vector2.ZERO, false)
		check(controls.get_move_vector().is_zero_approx(), "Release left movement stuck")
	var center := viewport_size * Vector2(0.24, 0.6)
	touch(controls, 1, center, true)
	drag(controls, 1, center + Vector2(100, 0))
	controls.set_controls_enabled(false)
	controls.set_controls_enabled(true)
	check(controls.get_move_vector().is_zero_approx(), "Pause retained a held analog")
	controls.configure_layout(1, 2)
	touch(controls, 4, center, true)
	drag(controls, 4, center + Vector2(100, 0))
	check(controls.get_move_vector(2).x > 0.9 and controls.get_move_vector(1).is_zero_approx(), "Guest slot routing failed")
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(controls.get_move_vector(2).is_zero_approx(), "Focus loss retained input")
	controls.queue_free()
	await process_frame
	print("FLOATING_ANALOG: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)


func touch(controls: Node, id: int, position: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = position
	event.pressed = down
	controls._handle_screen_touch(event)


func drag(controls: Node, id: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = position
	controls._handle_screen_drag(event)


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
