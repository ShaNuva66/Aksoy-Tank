extends SceneTree

const STAGE_CATALOG := preload("res://src/scripts/stage_catalog.gd")
const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"
const WALL_SCENE := "res://src/scenes/wall_block.tscn"

var _failed := false
var _game_session: Node = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("REGRESSION: gameplay rules started")
	_game_session = root.get_node_or_null("GameSession")
	_require(_game_session != null, "GameSession autoload is missing")
	if _game_session == null:
		quit(1)
		return
	_audit_catalog_rules()
	_audit_wall_geometry()
	await _audit_core_stage()
	await _audit_boss_stage()
	await _audit_vs_stage()
	_game_session.set_session_mode("solo")
	if _failed:
		print("REGRESSION: FAIL")
		quit(1)
	else:
		print("REGRESSION: PASS")
		quit(0)


func _audit_catalog_rules() -> void:
	var core_stage_count := 0
	var coreless_stage_count := 0
	for index in range(STAGE_CATALOG.get_stage_count()):
		var stage := STAGE_CATALOG.get_stage(index)
		var number := int(stage.get("number", 0))
		if bool(stage.get("core_enabled", true)):
			core_stage_count += 1
		else:
			coreless_stage_count += 1
		_require(int(stage.get("wave_count", 0)) in [2, 3, 4], "Stage %d has invalid waves" % number)
		_require(int(stage.get("max_alive", 0)) <= 7, "Stage %d exceeds the smooth pressure cap" % number)
		if number % 5 == 0:
			_require(String(stage.get("objective_type", "")) == "boss_hunt", "Stage %d is not a boss hunt" % number)
			_require(String(stage.get("objective_target_type", "")).begins_with("boss"), "Stage %d has no main boss" % number)
	_require(core_stage_count > 0, "Campaign has no core-defense stages")
	_require(coreless_stage_count > 0, "Campaign has no coreless missions")
	_require(_game_session.SESSION_MODES == ["solo", "online_coop", "online_vs"], "Online mode catalog is incomplete")


func _audit_wall_geometry() -> void:
	var wall = load(WALL_SCENE).instantiate()
	root.add_child(wall)
	var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
	var rectangle := shape_node.shape as RectangleShape2D
	_require(rectangle != null and rectangle.size == Vector2(48.0, 48.0), "Wall collider does not close cell seams")
	wall.queue_free()


func _audit_core_stage() -> void:
	_game_session.set_session_mode("solo")
	_game_session.unlocked_stage_count = STAGE_CATALOG.get_stage_count()
	_game_session.selected_stage_index = 0
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	var core = arena.get_node_or_null("Wall_12_12")
	_require(core != null and int(core.durability) == 5, "Core durability should be 5")
	for cell in [Vector2i(11, 12), Vector2i(13, 12), Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11)]:
		var fort = arena.get_node_or_null("Wall_%d_%d" % [cell.x, cell.y])
		_require(fort != null and String(fort.block_type) == "fortified" and int(fort.durability) == 7, "Core fort is not 7-hit fortified at %s" % cell)
	_require(arena.get_node_or_null("Hud/ShieldHud/VBox/Bar") != null, "Shield duration bar is missing")
	await _free_arena(arena)


func _audit_boss_stage() -> void:
	_game_session.set_session_mode("solo")
	_game_session.selected_stage_index = 4
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	_require(arena.get_node_or_null("Wall_12_12") == null, "Boss mission unexpectedly spawned a core")
	await _free_arena(arena)


func _audit_vs_stage() -> void:
	_game_session.set_session_mode("online_vs")
	_game_session.selected_stage_index = 0
	var arena = load(ARENA_SCENE).instantiate()
	root.add_child(arena)
	current_scene = arena
	await _wait_frames(3)
	var p1 = arena.get_node_or_null("PlayerTank1")
	var p2 = arena.get_node_or_null("PlayerTank2")
	_require(p1 != null and p2 != null, "VS mode did not create two tanks")
	if p1 != null and p2 != null:
		_require(p1.get_team() == "player_1" and p2.get_team() == "player_2", "VS tanks are not on opposing teams")
	_require(arena.get_node_or_null("Wall_12_12") == null, "VS mode unexpectedly spawned a core")
	await _free_arena(arena)


func _free_arena(arena: Node) -> void:
	arena.queue_free()
	current_scene = null
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("REGRESSION FAIL: " + message)
