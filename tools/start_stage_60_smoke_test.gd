extends SceneTree

const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"
const MAIN_MENU_SCENE := "res://src/scenes/main_menu.tscn"

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("STAGE60: smoke started")
	var main_menu: PackedScene = load(MAIN_MENU_SCENE)
	if main_menu == null:
		_fail("Main menu could not be loaded")
		return

	var menu := main_menu.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait_frames(30)

	if current_scene == null:
		_fail("No current scene")
		return

	if current_scene.scene_file_path != ARENA_SCENE:
		_fail("Expected arena scene, got " + current_scene.scene_file_path)
		return

	var game_session := root.get_node_or_null("GameSession")
	if game_session == null:
		_fail("GameSession not found")
		return

	if int(game_session.selected_stage_index) != 59:
		_fail("Expected selected stage index 59, got %d" % int(game_session.selected_stage_index))
		return

	var info_label = current_scene.get_node_or_null("Hud/Header/VBox/InfoLabel")
	if info_label == null:
		_fail("InfoLabel not found")
		return

	if not String(info_label.text).begins_with("S60"):
		_fail("Expected HUD to start with S60, got " + String(info_label.text))
		return

	print("STAGE60: PASS " + String(info_label.text))
	quit(0)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _fail(message: String) -> void:
	_failed = true
	push_error("STAGE60 FAIL: " + message)
	print("STAGE60: FAIL - " + message)
	quit(1)
