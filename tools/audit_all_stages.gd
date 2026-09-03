extends SceneTree

const STAGE_CATALOG := preload("res://src/scripts/stage_catalog.gd")
const ENEMY_TANK_SCRIPT := preload("res://src/scripts/enemy_tank.gd")
const ARENA_SCENE := "res://src/scenes/prototype_arena.tscn"
const GRID_SIZE := Vector2i(26, 15)
const SPAWN_POINTS := [Vector2i(3, 1), Vector2i(8, 1), Vector2i(17, 1), Vector2i(22, 1)]
const PLAYER_CELL := Vector2i(12, 13)
const BASE_RESERVED_CELLS := [
	Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11),
	Vector2i(11, 12), Vector2i(12, 12), Vector2i(13, 12)
]

var _failed := false
var _warnings := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("AUDIT: Aksoy Tank stage audit started")
	_audit_catalog()
	await _audit_scene_loads()
	if _failed:
		print("AUDIT: FAIL")
		quit(1)
	else:
		print("AUDIT: PASS warnings=%d" % _warnings)
		quit(0)


func _audit_catalog() -> void:
	var stage_count := STAGE_CATALOG.get_stage_count()
	if stage_count != 60:
		_fail("Expected 60 stages, found %d" % stage_count)

	var profiles: Dictionary = ENEMY_TANK_SCRIPT.PROFILES
	for index in range(stage_count):
		var stage := STAGE_CATALOG.get_stage(index)
		var label := _stage_label(stage)
		var queue: Array = stage.get("enemy_queue", [])
		var brick_cells: Array = stage.get("brick_cells", [])
		var steel_cells: Array = stage.get("steel_cells", [])

		_require(stage.has("name"), label + " missing name")
		_require(stage.has("tagline"), label + " missing tagline")
		_require(stage.has("theme"), label + " missing theme")
		_require(not STAGE_CATALOG.get_theme(String(stage.get("theme", ""))).is_empty(), label + " has unknown theme")
		_require(not queue.is_empty(), label + " has empty enemy queue")
		_require(float(stage.get("spawn_interval_min", 0.0)) > 0.0, label + " has invalid spawn_interval_min")
		_require(float(stage.get("spawn_interval_max", 0.0)) >= float(stage.get("spawn_interval_min", 0.0)), label + " has invalid spawn interval range")
		_require(int(stage.get("max_alive", 0)) > 0, label + " has invalid max_alive")
		_require(typeof(stage.get("core_enabled", null)) == TYPE_BOOL, label + " missing core_enabled")
		_require(int(stage.get("wave_count", 0)) >= 2 and int(stage.get("wave_count", 0)) <= 4, label + " has invalid wave_count")
		if int(stage.get("number", 0)) % 5 == 0:
			_require(String(stage.get("objective_type", "")) == "boss_hunt", label + " should be a boss hunt")
		if String(stage.get("objective_type", "eliminate")) != "eliminate":
			_require(not bool(stage.get("core_enabled", true)), label + " hunt mission should not spawn a core")

		for enemy_type in queue:
			_require(profiles.has(String(enemy_type)), "%s references unknown enemy type: %s" % [label, enemy_type])

		_audit_objective(stage, queue, label)
		_audit_cells(brick_cells, steel_cells, label, bool(stage.get("core_enabled", true)))
		_audit_spawn_bays(brick_cells, steel_cells, label)
		_audit_boss_pressure(stage, queue, profiles, label)


func _audit_objective(stage: Dictionary, queue: Array, label: String) -> void:
	var objective_type := String(stage.get("objective_type", "eliminate"))
	var target_type := String(stage.get("objective_target_type", ""))
	if objective_type == "eliminate":
		return

	var found := 0
	for enemy_type in queue:
		var enemy_name := String(enemy_type)
		if target_type == "boss":
			if enemy_name.begins_with("boss"):
				found += 1
		elif enemy_name == target_type:
			found += 1

	_require(found > 0, "%s objective %s has no matching target %s" % [label, objective_type, target_type])


func _audit_cells(brick_cells: Array, steel_cells: Array, label: String, core_enabled: bool) -> void:
	var occupied := {}
	for cell in brick_cells:
		_audit_cell(cell, label, "brick", core_enabled)
		_require(not occupied.has(cell), "%s duplicate cell in bricks: %s" % [label, cell])
		occupied[cell] = "brick"

	for cell in steel_cells:
		_audit_cell(cell, label, "steel", core_enabled)
		_require(not occupied.has(cell), "%s steel overlaps brick: %s" % [label, cell])
		occupied[cell] = "steel"


func _audit_cell(cell: Vector2i, label: String, block_type: String, core_enabled: bool) -> void:
	_require(cell.x > 0 and cell.x < GRID_SIZE.x - 1 and cell.y > 0 and cell.y < GRID_SIZE.y - 1, "%s %s cell outside interior: %s" % [label, block_type, cell])

	if SPAWN_POINTS.has(cell):
		_fail("%s %s blocks enemy spawn: %s" % [label, block_type, cell])

	if cell == PLAYER_CELL:
		_fail("%s %s blocks player spawn: %s" % [label, block_type, cell])

	if core_enabled and BASE_RESERVED_CELLS.has(cell):
		_warn("%s %s uses base reserved cell, arena will override it: %s" % [label, block_type, cell])


func _audit_spawn_bays(brick_cells: Array, steel_cells: Array, label: String) -> void:
	for spawn_cell in SPAWN_POINTS:
		for x_offset in range(-1, 2):
			for spawn_y in range(1, 4):
				var bay_cell := Vector2i(spawn_cell.x + x_offset, spawn_y)
				_require(not brick_cells.has(bay_cell) and not steel_cells.has(bay_cell), "%s blocks large-tank spawn bay at %s" % [label, bay_cell])


func _audit_boss_pressure(stage: Dictionary, queue: Array, profiles: Dictionary, label: String) -> void:
	var boss_count := 0
	var boss_health := 0
	var boss_damage := 0
	var boss_types := []

	for enemy_type in queue:
		var enemy_name := String(enemy_type)
		if not enemy_name.begins_with("boss"):
			continue

		boss_count += 1
		if not boss_types.has(enemy_name):
			boss_types.append(enemy_name)

		var profile: Dictionary = profiles.get(enemy_name, {})
		boss_health += int(profile.get("health", 0))
		boss_damage += int(profile.get("damage", 1))

	if boss_count > 0:
		print("AUDIT: %s bosses=%d types=%s total_health=%d total_damage=%d" % [label, boss_count, ", ".join(boss_types), boss_health, boss_damage])


func _audit_scene_loads() -> void:
	var packed: PackedScene = load(ARENA_SCENE)
	if packed == null:
		_fail("Arena scene could not be loaded")
		return

	var stage_count := STAGE_CATALOG.get_stage_count()
	var game_session := root.get_node_or_null("GameSession")
	if game_session == null:
		_fail("GameSession autoload is not available")
		return

	game_session.unlocked_stage_count = stage_count
	game_session.session_mode = "solo"

	for index in range(stage_count):
		game_session.selected_stage_index = index
		var arena := packed.instantiate()
		root.add_child(arena)
		current_scene = arena
		await _wait_frames(5)

		if current_scene == null:
			_fail("Stage %02d scene did not become current_scene" % [index + 1])
		elif current_scene.scene_file_path != ARENA_SCENE:
			_fail("Stage %02d loaded wrong scene: %s" % [index + 1, current_scene.scene_file_path])
		elif current_scene.get_node_or_null("MobileControls") == null:
			_fail("Stage %02d missing MobileControls" % [index + 1])
		elif current_scene.get_node_or_null("Hud") == null:
			_fail("Stage %02d missing Hud" % [index + 1])

		await physics_frame
		var large_tank_spawn: Vector2 = arena._choose_enemy_spawn_position(42.0)
		_require(large_tank_spawn.x >= 0.0, "Stage %02d has no collision-safe large boss spawn" % [index + 1])
		if large_tank_spawn.x >= 0.0:
			_require(arena._is_enemy_spawn_position_clear(large_tank_spawn, 42.0), "Stage %02d large boss spawn overlaps a wall or tank" % [index + 1])

		arena.queue_free()
		current_scene = null
		await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _stage_label(stage: Dictionary) -> String:
	return "Stage %02d %s" % [int(stage.get("number", 0)), String(stage.get("name", "Unnamed"))]


func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failed = true
	push_error("AUDIT FAIL: " + message)
	print("AUDIT: FAIL - " + message)


func _warn(message: String) -> void:
	_warnings += 1
	push_warning("AUDIT WARN: " + message)
	print("AUDIT: WARN - " + message)
