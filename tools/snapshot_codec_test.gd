extends SceneTree

const CODEC = preload("res://src/scripts/snapshot_codec.gd")
var failed := false


func _init() -> void:
	var snapshot := {"meta": {"round_id": 3}, "players": [], "bullets": [], "walls": [], "walls_changed": true}
	for index in range(40):
		snapshot["bullets"].append({"id": index, "x": index * 1.25, "y": 100.0, "rotation": 0.5, "team": "player", "projectile_color": "ffeeaa", "glow_color": "ffffff", "impact_color": "ffaa00", "size_scale": 1.0, "damage": 2, "velocity_x": 200.0, "velocity_y": 0.0})
	var original_text := JSON.stringify(snapshot)
	var packed_text := JSON.stringify(CODEC.encode(snapshot))
	var decoded := CODEC.decode(JSON.parse_string(packed_text))
	check(decoded == JSON.parse_string(original_text), "Wire roundtrip changed entity data")
	check(JSON.stringify(snapshot) == original_text, "Encoding mutated caller state")
	check(packed_text.length() < original_text.length() * 0.7, "Dense packet reduction below 30 percent")
	# Different schemas (dead/alive player) must remain intact without a cache.
	snapshot["players"] = [{"slot": 1, "alive": false}, {"slot": 2, "alive": true, "x": 42}]
	check(CODEC.decode(CODEC.encode(snapshot)) == snapshot, "Mixed schemas lost fields")
	check(CODEC.decode(snapshot) == snapshot, "Legacy full snapshot compatibility failed")
	for invalid in [{"wire_format": 2}, {"wire_format": 1, "bullets": {"columns": ["id", "id"], "rows": [[1, 2]]}}, {"wire_format": 1, "players": {"columns": ["slot"], "rows": [[]]}}, {"wire_format": 1, "walls": {"columns": [42], "rows": [[1]]}}]:
		check(CODEC.decode(invalid).is_empty(), "Malformed table was accepted")
	print("SNAPSHOT_CODEC: bytes_before=", original_text.length(), " bytes_after=", packed_text.length())
	print("SNAPSHOT_CODEC: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
