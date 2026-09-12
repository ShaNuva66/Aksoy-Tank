extends RefCounted

const WINS_REQUIRED := 3
const MAP_NAMES := ["CAPRAZ SIPER", "IKIZ KALE", "MERKEZ HATTI"]


static func fresh() -> Dictionary:
	return {"round": 1, "p1": 0, "p2": 0, "winner": 0, "resolved": false}


static func finish(state: Dictionary, winner: int) -> Dictionary:
	var result := state.duplicate(true)
	if result.get("resolved", false):
		return result
	result["resolved"] = true
	if winner in [1, 2]:
		var key := "p%d" % winner
		result[key] = int(result.get(key, 0)) + 1
		if result[key] >= WINS_REQUIRED:
			result["winner"] = winner
	return result


static func advance(state: Dictionary) -> Dictionary:
	if int(state.get("winner", 0)) > 0:
		return fresh()
	var result := state.duplicate(true)
	result["round"] = int(result.get("round", 1)) + 1
	result["resolved"] = false
	return result


static func layout(round_number: int) -> Dictionary:
	var index := posmod(round_number - 1, MAP_NAMES.size())
	var bricks: Array[Vector2i] = []
	var steel: Array[Vector2i] = []
	var seeds: Array = [
		[Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(6, 8), Vector2i(7, 8)],
		[Vector2i(8, 3), Vector2i(8, 4), Vector2i(9, 4), Vector2i(8, 9), Vector2i(9, 9)],
		[Vector2i(6, 5), Vector2i(7, 5), Vector2i(10, 3), Vector2i(10, 4), Vector2i(10, 10)]
	]
	for cell in seeds[index]:
		bricks.append(cell)
		bricks.append(Vector2i(25 - cell.x, 14 - cell.y))
	for cell in [Vector2i(11, 5), Vector2i(11, 6)]:
		steel.append(cell)
		steel.append(Vector2i(25 - cell.x, 14 - cell.y))
	return {"name": MAP_NAMES[index], "brick_cells": bricks, "steel_cells": steel}
