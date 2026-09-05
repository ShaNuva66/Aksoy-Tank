extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func run() -> void:
	var session = root.get_node("GameSession")
	var old_mode: String = session.session_mode
	session.session_mode = "solo"
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	var player = arena._get_player_by_slot(1)
	require(not quit_on_go_back, "Android back must not terminate the match")
	arena._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	require(paused and arena.pause_overlay.visible, "Solo focus loss must pause")
	require(not player.local_input_enabled, "Focus loss must block input")
	arena._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	require(paused, "Focus return must wait for explicit resume")
	arena._on_pause_resume_button_pressed()
	require(not paused and player.local_input_enabled, "Resume must restore controls")
	for mode in ["online_coop", "online_vs"]:
		arena._session_mode = mode
		arena._refresh_pause_button_visibility()
		require(arena.pause_button.visible, mode + " needs a menu button")
		arena._on_pause_button_pressed()
		require(not paused and arena.pause_overlay.visible, mode + " menu must not freeze simulation")
		require(arena.pause_resume_button.can_process(), "Online resume must receive input")
		require(not bool(player.capture_local_input_state().fire), "Menu must block fire")
		require(not player.local_input_enabled, "Menu must block keyboard as well as touch")
		arena._on_pause_resume_button_pressed()
		require(player.local_input_enabled and not arena.pause_overlay.visible, "Online resume failed")
		arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		require(arena.pause_overlay.visible and not paused, "Android back must open the online menu")
		arena._on_pause_resume_button_pressed()
		arena._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		require(not paused and arena.pause_overlay.visible, "Online background must preserve network processing")
		arena._on_pause_resume_button_pressed()
	arena._session_mode = "solo"
	arena.queue_free()
	await process_frame
	session.session_mode = old_mode
	print("LIFECYCLE: FAIL" if failed else "LIFECYCLE: PASS")
	quit(1 if failed else 0)
