extends SceneTree

const FRAMES_PER_STAGE := 1800
var failed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var session = root.get_node("GameSession")
	var previous := [session.session_mode, session.selected_stage_index, session.unlocked_stage_count, session.onboarding_completed]
	session.session_mode = "solo"
	session.onboarding_completed = true
	var rows: Array = []
	for stage in range(session.get_stage_count()):
		session.selected_stage_index = stage
		var arena = load("res://src/scenes/prototype_arena.tscn").instantiate()
		root.add_child(arena)
		current_scene = arena
		await physics_frame
		var player = arena._get_player_by_slot(1)
		player.set_control_mode("network_input")
		var frames := 0
		var peak_bullets := 0
		var peak_enemies := 0
		while frames < FRAMES_PER_STAGE and not arena._match_over:
			frames += 1
			if is_instance_valid(player):
				var aim: float = player.rotation
				var nearest := INF
				for enemy in get_nodes_in_group("enemy_tanks"):
					var distance: float = player.global_position.distance_squared_to(enemy.global_position)
					if distance < nearest:
						nearest = distance
						aim = (enemy.global_position - player.global_position).angle() + PI * 0.5
				player.set_external_input({"aim_rotation": aim, "drive": 0.4 if nearest > 62500 else -0.25, "fire": true})
				if not player.global_position.is_finite():
					failed = true
					push_error("Non-finite player position in stage %d" % (stage + 1))
			peak_bullets = maxi(peak_bullets, get_nodes_in_group("bullets").size())
			peak_enemies = maxi(peak_enemies, get_nodes_in_group("enemy_tanks").size())
			await physics_frame
		var row := {"stage": stage + 1, "seconds": frames / 60.0, "outcome": arena._status_text if arena._match_over else "time_limit", "destroyed": arena._destroyed_enemies, "peak_enemies": peak_enemies, "peak_bullets": peak_bullets}
		rows.append(row)
		print("COMBAT: ", JSON.stringify(row))
		await process_frame
		arena.process_mode = Node.PROCESS_MODE_DISABLED
		arena.queue_free()
		await process_frame
		await process_frame
	session.session_mode = previous[0]
	session.selected_stage_index = previous[1]
	session.unlocked_stage_count = previous[2]
	session.onboarding_completed = previous[3]
	session._save_progress()
	var report := FileAccess.open("user://combat-soak-report.json", FileAccess.WRITE)
	if report == null:
		failed = true
	else:
		report.store_string(JSON.stringify({"scope": "30-second scripted combat per stage; not human balance certification", "stages": rows}, "\t"))
		report.close()
	print("COMBAT_REPORT: ", ProjectSettings.globalize_path("user://combat-soak-report.json"))
	print("COMBAT: FAIL" if failed else "COMBAT: PASS")
	quit(1 if failed else 0)
