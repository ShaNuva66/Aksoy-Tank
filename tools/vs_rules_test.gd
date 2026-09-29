extends SceneTree

const RULES = preload("res://src/scripts/vs_rules.gd")
var failed := false


func _init() -> void:
	var state := RULES.fresh()
	for winner in [1, 2, 1, 0, 1]:
		state = RULES.finish(state, winner)
		check(RULES.finish(state, winner) == state, "Duplicate result awarded another point")
		if int(state.winner) == 0:
			state = RULES.advance(state)
	check(state.p1 == 3 and state.p2 == 1 and state.winner == 1, "First-to-three scoring failed")
	check(RULES.advance(state) == RULES.fresh(), "Rematch did not reset the series")
	var names := {}
	for round_number in range(1, 4):
		var layout := RULES.layout(round_number)
		names[layout.name] = true
		var blocked := {}
		for field in ["brick_cells", "steel_cells"]:
			for cell in layout[field]:
				check(Vector2i(25 - cell.x, 14 - cell.y) in layout[field], "Layout is not rotationally symmetric")
				check(not blocked.has(cell), "Overlapping walls")
				blocked[cell] = true
		var reached := {Vector2i(5, 12): true}
		var frontier: Array[Vector2i] = [Vector2i(5, 12)]
		var index := 0
		while index < frontier.size():
			var cell := frontier[index]
			index += 1
			for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = cell + direction
				if next.x < 1 or next.x > 24 or next.y < 1 or next.y > 13 or blocked.has(next) or reached.has(next):
					continue
				reached[next] = true
				frontier.append(next)
		for target in [Vector2i(20, 2), Vector2i(12, 7), Vector2i(13, 7), Vector2i(2, 3), Vector2i(23, 11)]:
			check(reached.has(target), "Spawn or power-up has no route")
	check(names.size() == 3, "Map rotation has duplicate entries")
	print("VS_RULES: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
