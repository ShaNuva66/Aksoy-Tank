extends SceneTree

var failed := false

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func run() -> void:
	var session = root.get_node("GameSession")
	session.session_mode = "solo"
	session.unlocked_stage_count = 3
	session.set_selected_stage(2)
	var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena._finish_match(true, "ZAFER", "")
	check(session.selected_stage_index == 3 and session.unlocked_stage_count == 4, "Stage 3 victory must select and unlock stage 4")
	session._load_progress()
	check(session.selected_stage_index == 3, "Stage 4 selection must survive reload before countdown ends")
	check(arena._auto_advance_remaining > 0.0, "Solo victory needs automatic progression")
	arena._application_active = false
	arena._process(4.0)
	check(not arena._scene_transition_started, "Background must not advance the stage")
	arena._application_active = true
	arena._process(4.0)
	await process_frame
	await process_frame
	arena = current_scene
	check(int(arena._stage_data.index) == 3, "Automatic transition must open stage 4 without skipping")
	arena._finish_match(false, "KAYIP", "")
	check(arena._auto_advance_remaining < 0.0, "Defeat must not advance")
	arena.queue_free()
	await process_frame
	session.set_selected_stage(2)
	arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena._finish_match(true, "ZAFER", "")
	arena._go_to_next_stage()
	arena._go_to_next_stage()
	await process_frame
	await process_frame
	arena = current_scene
	check(int(arena._stage_data.index) == 3, "Double tap must not skip stage 4")
	arena._finish_match(true, "ZAFER", "")
	arena._restart_level()
	await process_frame
	await process_frame
	arena = current_scene
	check(int(arena._stage_data.index) == 3, "Retry must replay completed stage, not next selection")
	arena._session_mode = "online_coop"
	arena._finish_match(true, "ZAFER", "")
	check(arena._auto_advance_remaining < 0.0, "Online coop must wait for both players")
	arena.queue_free()
	await process_frame
	session.unlocked_stage_count = session.get_stage_count()
	session.set_selected_stage(session.get_stage_count() - 1)
	arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena._finish_match(true, "ZAFER", "")
	check(not arena.next_stage_button.visible and arena._auto_advance_remaining < 0.0, "Final stage must not loop or advance")
	arena.queue_free()
	await process_frame
	var menu = load("res://src/scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._open_settings()
	await process_frame
	await process_frame
	check(root.get_visible_rect().encloses(menu._settings_panel.get_global_rect()), "Settings must fit viewport")
	check(menu._haptics_toggle.get_theme_font_size("font_size") == 26, "Settings text size")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://settings-readable.png")
	menu.queue_free()
	await process_frame
	await create_timer(0.8).timeout
	print("CAMPAIGN_PROGRESSION: FAIL" if failed else "CAMPAIGN_PROGRESSION: PASS")
	quit(1 if failed else 0)
