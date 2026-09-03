extends RefCounted

const THEMES := {
	"dust": {
		"label": "Toz Hatti",
		"background_top": Color("#1f232a"),
		"background_bottom": Color("#10151b"),
		"grid": Color(0.93, 0.88, 0.72, 0.06),
		"ambient_glow": Color("#d9a76c"),
		"spawn_glow": Color("#f7d98c"),
		"base_glow": Color("#f2c572"),
		"hud_accent": Color("#f2d48f"),
		"brick_body": Color("#8c5e3c"),
		"brick_line": Color("#d9b38c"),
		"steel_body": Color("#6f7c89"),
		"steel_line": Color("#cad3dd"),
		"base_body": Color("#d3ad58"),
		"base_line": Color("#fff1b2"),
		"base_core": Color("#121820")
	},
	"crosswind": {
		"label": "Firtina Koridoru",
		"background_top": Color("#18232f"),
		"background_bottom": Color("#0d141c"),
		"grid": Color(0.74, 0.89, 0.97, 0.06),
		"ambient_glow": Color("#5ca9d9"),
		"spawn_glow": Color("#9ce6ff"),
		"base_glow": Color("#8ec7ff"),
		"hud_accent": Color("#c9efff"),
		"brick_body": Color("#6d5d4d"),
		"brick_line": Color("#cfbb9b"),
		"steel_body": Color("#577487"),
		"steel_line": Color("#d8effb"),
		"base_body": Color("#7fb8d6"),
		"base_line": Color("#e8f9ff"),
		"base_core": Color("#122330")
	},
	"canal": {
		"label": "Kanal Agi",
		"background_top": Color("#11252b"),
		"background_bottom": Color("#09171b"),
		"grid": Color(0.7, 0.98, 0.93, 0.06),
		"ambient_glow": Color("#37c8ab"),
		"spawn_glow": Color("#9df6df"),
		"base_glow": Color("#8ee9c7"),
		"hud_accent": Color("#c9ffef"),
		"brick_body": Color("#6a5440"),
		"brick_line": Color("#d8b28c"),
		"steel_body": Color("#48768a"),
		"steel_line": Color("#c5f7ff"),
		"base_body": Color("#6dcfb6"),
		"base_line": Color("#dffff7"),
		"base_core": Color("#0d1e22")
	},
	"ember": {
		"label": "Kor Halka",
		"background_top": Color("#251818"),
		"background_bottom": Color("#110d0d"),
		"grid": Color(0.98, 0.7, 0.58, 0.06),
		"ambient_glow": Color("#ff7c52"),
		"spawn_glow": Color("#ffc078"),
		"base_glow": Color("#ffb06d"),
		"hud_accent": Color("#ffd4a3"),
		"brick_body": Color("#92553d"),
		"brick_line": Color("#ffc29a"),
		"steel_body": Color("#7f6760"),
		"steel_line": Color("#f1d1c8"),
		"base_body": Color("#e39462"),
		"base_line": Color("#ffe1b9"),
		"base_core": Color("#24120e")
	},
	"reactor": {
		"label": "Reaktor Bolgesi",
		"background_top": Color("#171a24"),
		"background_bottom": Color("#0c1015"),
		"grid": Color(0.72, 0.82, 1.0, 0.06),
		"ambient_glow": Color("#7a89ff"),
		"spawn_glow": Color("#b7c2ff"),
		"base_glow": Color("#97a5ff"),
		"hud_accent": Color("#d8dcff"),
		"brick_body": Color("#665870"),
		"brick_line": Color("#d9bce9"),
		"steel_body": Color("#566287"),
		"steel_line": Color("#d7deff"),
		"base_body": Color("#8f96db"),
		"base_line": Color("#eef0ff"),
		"base_core": Color("#15192a")
	},
	"needle": {
		"label": "Igne Labirenti",
		"background_top": Color("#1a1d21"),
		"background_bottom": Color("#0d0f13"),
		"grid": Color(0.9, 0.92, 0.97, 0.05),
		"ambient_glow": Color("#93a0a7"),
		"spawn_glow": Color("#e1e6eb"),
		"base_glow": Color("#c8d0d8"),
		"hud_accent": Color("#f1f5f8"),
		"brick_body": Color("#5f544e"),
		"brick_line": Color("#d4c2b5"),
		"steel_body": Color("#727b84"),
		"steel_line": Color("#edf2f5"),
		"base_body": Color("#a8b1ba"),
		"base_line": Color("#ffffff"),
		"base_core": Color("#15191d")
	},
	"echo": {
		"label": "Yankili Avlu",
		"background_top": Color("#141f28"),
		"background_bottom": Color("#091219"),
		"grid": Color(0.71, 0.93, 1.0, 0.06),
		"ambient_glow": Color("#5dc4ff"),
		"spawn_glow": Color("#b5edff"),
		"base_glow": Color("#86ddff"),
		"hud_accent": Color("#d6f6ff"),
		"brick_body": Color("#6d5a4a"),
		"brick_line": Color("#dfc29f"),
		"steel_body": Color("#4d7389"),
		"steel_line": Color("#d7f5ff"),
		"base_body": Color("#6ebee3"),
		"base_line": Color("#effcff"),
		"base_core": Color("#10202a")
	},
	"iron": {
		"label": "Demir Orgu",
		"background_top": Color("#1d2023"),
		"background_bottom": Color("#0d1012"),
		"grid": Color(0.84, 0.9, 0.92, 0.06),
		"ambient_glow": Color("#b8c0c7"),
		"spawn_glow": Color("#eaf0f5"),
		"base_glow": Color("#cdd7df"),
		"hud_accent": Color("#f6f8fb"),
		"brick_body": Color("#64564b"),
		"brick_line": Color("#d5c1ab"),
		"steel_body": Color("#72808d"),
		"steel_line": Color("#f3f7fa"),
		"base_body": Color("#99a8b5"),
		"base_line": Color("#ffffff"),
		"base_core": Color("#14181c")
	},
	"redoubt": {
		"label": "Kizil Siper",
		"background_top": Color("#231416"),
		"background_bottom": Color("#100a0b"),
		"grid": Color(1.0, 0.73, 0.73, 0.06),
		"ambient_glow": Color("#db5f67"),
		"spawn_glow": Color("#ffb0ab"),
		"base_glow": Color("#ff8e84"),
		"hud_accent": Color("#ffd1c9"),
		"brick_body": Color("#8c4f48"),
		"brick_line": Color("#ffc0ae"),
		"steel_body": Color("#7e6465"),
		"steel_line": Color("#f7d7d4"),
		"base_body": Color("#d9796f"),
		"base_line": Color("#ffe1d9"),
		"base_core": Color("#251112")
	},
	"obsidian": {
		"label": "Obsidyen Cephe",
		"background_top": Color("#16161d"),
		"background_bottom": Color("#07080b"),
		"grid": Color(0.84, 0.79, 0.98, 0.06),
		"ambient_glow": Color("#7f86ff"),
		"spawn_glow": Color("#d5c9ff"),
		"base_glow": Color("#b4a1ff"),
		"hud_accent": Color("#ece8ff"),
		"brick_body": Color("#645270"),
		"brick_line": Color("#dbcdf0"),
		"steel_body": Color("#596174"),
		"steel_line": Color("#edf0ff"),
		"base_body": Color("#9e8fe0"),
		"base_line": Color("#fbf9ff"),
		"base_core": Color("#151523")
	}
}


static func get_stage_count() -> int:
	return _stages().size()


static func get_stage(index: int) -> Dictionary:
	var stages := _stages()
	var safe_index: int = clampi(index, 0, stages.size() - 1)
	var stage: Dictionary = Dictionary(stages[safe_index].duplicate(true))
	stage["index"] = safe_index
	stage["number"] = safe_index + 1
	stage["total_stages"] = stages.size()
	stage["theme_label"] = get_theme(stage.get("theme", "dust")).get("label", "Saha")
	_apply_stage_rules(stage, safe_index + 1)
	_normalize_stage_layout(stage)
	return stage


static func get_theme(theme_name: String) -> Dictionary:
	return Dictionary(THEMES.get(theme_name, THEMES["dust"]).duplicate(true))


static func _apply_stage_rules(stage: Dictionary, stage_number: int) -> void:
	var queue: Array = stage.get("enemy_queue", []).duplicate()
	var objective_type := String(stage.get("objective_type", "eliminate"))

	if stage_number % 5 == 0:
		objective_type = "boss_hunt"
		stage["objective_type"] = objective_type
		stage["objective_target_type"] = "boss"
		if not String(stage.get("objective_label", "")).to_lower().contains("boss"):
			stage["objective_label"] = "Bolum bossunu bul ve imha et."
		var has_boss := false
		for enemy_type in queue:
			if String(enemy_type).begins_with("boss"):
				has_boss = true
				break
		if not has_boss:
			queue.append(_boss_type_for_stage(stage_number, queue.size()))

	stage["enemy_queue"] = queue
	objective_type = String(stage.get("objective_type", objective_type))
	if objective_type == "boss_hunt":
		for queue_index in range(queue.size() - 1, -1, -1):
			var boss_type := String(queue[queue_index])
			if boss_type.begins_with("boss"):
				stage["objective_target_type"] = boss_type
				break
	var core_enabled := objective_type == "eliminate" and stage_number % 4 != 0
	stage["core_enabled"] = core_enabled
	if objective_type == "eliminate" and not core_enabled:
		stage["objective_label"] = "Dusman dalgalarini temizle."

	if stage_number <= 15:
		stage["wave_count"] = 2
	elif stage_number <= 40:
		stage["wave_count"] = 3
	else:
		stage["wave_count"] = 4

	_apply_layout_signature(stage, stage_number)


static func _apply_layout_signature(stage: Dictionary, stage_number: int) -> void:
	var brick_cells: Array = stage.get("brick_cells", []).duplicate()
	var marker_x := 2 + (stage_number * 3) % 7
	var marker_y := 2 + (stage_number % 3) * 3
	brick_cells.append(Vector2i(marker_x, marker_y))
	brick_cells.append(Vector2i(25 - marker_x, 12 - marker_y / 2))
	stage["brick_cells"] = brick_cells


static func _normalize_stage_layout(stage: Dictionary) -> void:
	var reserved_cells := _reserved_cells_for_stage(stage)
	var steel_cells := _unique_cells(stage.get("steel_cells", []), reserved_cells, {})
	var steel_lookup := {}
	for cell in steel_cells:
		steel_lookup[cell] = true

	stage["steel_cells"] = steel_cells
	stage["brick_cells"] = _unique_cells(stage.get("brick_cells", []), reserved_cells, steel_lookup)


static func _reserved_cells_for_stage(stage: Dictionary) -> Dictionary:
	var reserved := {}
	var base_cells := []
	if bool(stage.get("core_enabled", true)):
		base_cells = [
			Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11),
			Vector2i(11, 12), Vector2i(12, 12), Vector2i(13, 12)
		]
	var spawn_cells := [
		Vector2i(3, 1),
		Vector2i(8, 1),
		Vector2i(17, 1),
		Vector2i(22, 1)
	]
	var player_cell: Vector2i = stage.get("player_cell", Vector2i(12, 13))

	for cell in base_cells:
		reserved[cell] = true
	# Keep a 3x3 deployment bay open around row 2. Large bosses have up to a
	# 42 px radius and would overlap the top border or adjacent wall cells when
	# spawned in the original single 48 px cell.
	for spawn_cell in spawn_cells:
		for x_offset in range(-1, 2):
			for spawn_y in range(1, 4):
				reserved[Vector2i(spawn_cell.x + x_offset, spawn_y)] = true
	for cell in [player_cell, player_cell + Vector2i(-2, 0), player_cell + Vector2i(2, 0)]:
		reserved[cell] = true

	return reserved


static func _unique_cells(cells: Array, reserved_cells: Dictionary, blocked_cells: Dictionary) -> Array:
	var result := []
	var seen := {}

	for cell in cells:
		if reserved_cells.has(cell) or blocked_cells.has(cell) or seen.has(cell):
			continue

		result.append(cell)
		seen[cell] = true

	return result


static func _stages() -> Array:
	var stages := [
		_stage_dust_gate(),
		_stage_crosswind_split(),
		_stage_twin_canals(),
		_stage_bastion_ring(),
		_stage_split_reactor(),
		_stage_needle_maze(),
		_stage_echo_yard(),
		_stage_iron_weave(),
		_stage_redoubt_spiral(),
		_stage_final_bastion()
	]

	for stage_number in range(11, 61):
		stages.append(_generated_campaign_stage(stage_number))

	return stages


static func _stage_dust_gate() -> Dictionary:
	return {
		"name": "Dust Gate",
		"tagline": "Acik hatlar ve ortada kirilabilir bir gecit.",
		"theme": "dust",
		"player_cell": Vector2i(12, 13),
		"max_alive": 3,
		"spawn_interval_min": 1.0,
		"spawn_interval_max": 1.6,
		"enemy_queue": ["grunt", "grunt", "scout", "grunt", "grunt", "scout", "grunt", "brute"],
		"brick_cells": _merge([
			_block(4, 4, 3, 2),
			_block(18, 4, 3, 2),
			_h_line(9, 10, 7),
			_h_line(15, 16, 7),
			_h_line(3, 5, 10),
			_h_line(20, 22, 10)
		]),
		"steel_cells": _merge([
			_h_line(11, 14, 3),
			_h_line(11, 14, 5)
		])
	}


static func _stage_crosswind_split() -> Dictionary:
	return {
		"name": "Crosswind Split",
		"tagline": "Uzun koridorlar ve iki taraftan baski.",
		"theme": "crosswind",
		"player_cell": Vector2i(12, 13),
		"max_alive": 3,
		"spawn_interval_min": 0.95,
		"spawn_interval_max": 1.5,
		"enemy_queue": ["grunt", "scout", "grunt", "scout", "grunt", "sniper", "scout", "brute", "grunt"],
		"brick_cells": _merge([
			_v_line(6, 3, 10),
			_v_line(19, 3, 10),
			_h_line(8, 17, 6),
			_h_line(8, 17, 9)
		]),
		"steel_cells": _merge([
			_h_line(11, 14, 4),
			_h_line(11, 14, 8),
			_h_line(2, 4, 12),
			_h_line(21, 23, 12)
		])
	}


static func _stage_twin_canals() -> Dictionary:
	return {
		"name": "Twin Canals",
		"tagline": "Yanal kanallar ve merkez kopruler.",
		"theme": "canal",
		"player_cell": Vector2i(12, 13),
		"max_alive": 4,
		"spawn_interval_min": 0.9,
		"spawn_interval_max": 1.45,
		"enemy_queue": ["grunt", "grunt", "scout", "grunt", "sniper", "scout", "grunt", "brute", "sniper", "scout"],
		"brick_cells": _merge([
			_block(4, 3, 2, 4),
			_block(19, 3, 2, 4),
			_h_line(8, 17, 4),
			_h_line(8, 17, 10),
			_h_line(9, 11, 7),
			_h_line(14, 16, 7)
		]),
		"steel_cells": _merge([
			_v_line(8, 2, 9),
			_v_line(17, 2, 9),
			_h_line(11, 14, 5)
		])
	}


static func _stage_bastion_ring() -> Dictionary:
	return {
		"name": "Bastion Ring",
		"tagline": "Merkezi kusatan halka savaslari yogunlastirir.",
		"theme": "ember",
		"player_cell": Vector2i(12, 13),
		"max_alive": 4,
		"spawn_interval_min": 0.9,
		"spawn_interval_max": 1.4,
		"enemy_queue": ["grunt", "scout", "brute", "grunt", "sniper", "scout", "brute", "grunt", "sniper", "grunt"],
		"brick_cells": _merge([
			_rect_outline(6, 3, 19, 10),
			_h_line(9, 10, 6),
			_h_line(15, 16, 6)
		]),
		"steel_cells": _merge([
			_h_line(11, 14, 3),
			_h_line(11, 14, 10),
			_block(6, 6, 2, 2),
			_block(18, 6, 2, 2)
		])
	}


static func _stage_split_reactor() -> Dictionary:
	return {
		"name": "Split Reactor",
		"tagline": "Iki cekirdek odasi arasinda hizli rota degisimi gerekir.",
		"theme": "reactor",
		"player_cell": Vector2i(12, 13),
		"max_alive": 4,
		"spawn_interval_min": 0.85,
		"spawn_interval_max": 1.35,
		"enemy_queue": ["grunt", "scout", "grunt", "brute", "sniper", "scout", "brute", "grunt", "sniper", "scout", "brute"],
		"brick_cells": _merge([
			_block(3, 3, 4, 3),
			_block(18, 3, 4, 3),
			_block(8, 8, 3, 2),
			_block(15, 8, 3, 2),
			_h_line(10, 14, 5)
		]),
		"steel_cells": _merge([
			_v_line(12, 3, 9),
			_v_line(13, 3, 9),
			_h_line(2, 5, 8),
			_h_line(20, 23, 8)
		])
	}


static func _stage_needle_maze() -> Dictionary:
	return {
		"name": "Needle Maze",
		"tagline": "Dar kolonlar mermileri tehlikeli koridorlara zorluyor.",
		"theme": "needle",
		"player_cell": Vector2i(12, 13),
		"max_alive": 4,
		"spawn_interval_min": 0.8,
		"spawn_interval_max": 1.25,
		"enemy_queue": ["scout", "grunt", "sniper", "scout", "brute", "grunt", "sniper", "scout", "brute", "grunt", "sniper", "brute"],
		"brick_cells": _merge([
			_v_line(5, 2, 11),
			_v_line(10, 4, 10),
			_v_line(15, 4, 10),
			_v_line(20, 2, 11),
			_h_line(7, 18, 7)
		]),
		"steel_cells": _merge([
			_v_line(8, 2, 6),
			_v_line(17, 2, 6),
			_h_line(9, 16, 10)
		])
	}


static func _stage_echo_yard() -> Dictionary:
	return {
		"name": "Echo Yard",
		"tagline": "Aynali acilar oyuncuyu pozisyon degistirmeye zorlar.",
		"theme": "echo",
		"player_cell": Vector2i(12, 13),
		"max_alive": 4,
		"spawn_interval_min": 0.78,
		"spawn_interval_max": 1.2,
		"enemy_queue": ["grunt", "scout", "brute", "sniper", "grunt", "scout", "brute", "sniper", "grunt", "scout", "brute", "sniper"],
		"brick_cells": _merge([
			_h_line(3, 5, 3),
			_h_line(6, 8, 5),
			_h_line(9, 11, 7),
			_h_line(14, 16, 7),
			_h_line(17, 19, 5),
			_h_line(20, 22, 3),
			_h_line(5, 8, 10),
			_h_line(17, 20, 10)
		]),
		"steel_cells": _merge([
			_h_line(11, 14, 3),
			_h_line(11, 14, 9),
			_v_line(3, 8, 11),
			_v_line(22, 8, 11)
		])
	}


static func _stage_iron_weave() -> Dictionary:
	return {
		"name": "Iron Weave",
		"tagline": "Dokuma gibi orulmus savunma hatlari hiz kesiyor.",
		"theme": "iron",
		"player_cell": Vector2i(12, 13),
		"max_alive": 5,
		"spawn_interval_min": 0.76,
		"spawn_interval_max": 1.15,
		"enemy_queue": ["scout", "grunt", "sniper", "brute", "scout", "grunt", "sniper", "brute", "scout", "grunt", "sniper", "brute", "scout"],
		"brick_cells": _merge([
			_h_line(3, 8, 3),
			_h_line(15, 22, 3),
			_h_line(3, 8, 9),
			_h_line(15, 22, 9),
			_v_line(11, 4, 8),
			_v_line(14, 4, 8)
		]),
		"steel_cells": _merge([
			_v_line(6, 4, 8),
			_v_line(19, 4, 8),
			_h_line(9, 16, 6),
			_h_line(10, 14, 11)
		])
	}


static func _stage_redoubt_spiral() -> Dictionary:
	return {
		"name": "Redoubt Spiral",
		"tagline": "Ic ice gecen savunmalar ilerledikce sikisiyor.",
		"theme": "redoubt",
		"player_cell": Vector2i(12, 13),
		"max_alive": 5,
		"spawn_interval_min": 0.72,
		"spawn_interval_max": 1.1,
		"enemy_queue": ["grunt", "scout", "sniper", "brute", "grunt", "scout", "sniper", "brute", "sniper", "grunt", "brute", "scout", "sniper", "brute"],
		"brick_cells": _merge([
			_rect_outline(4, 3, 21, 11),
			_rect_outline(7, 5, 18, 9),
			_h_line(7, 10, 5),
			_v_line(18, 6, 9),
			_h_line(11, 17, 9)
		]),
		"steel_cells": _merge([
			_h_line(11, 14, 3),
			_v_line(18, 5, 7),
			_h_line(7, 10, 9),
			_h_line(13, 15, 7)
		])
	}


static func _stage_final_bastion() -> Dictionary:
	return {
		"name": "Obsidyen Kapisi",
		"tagline": "Kara hatlarda agir zirhlar ve keskin nisancilar yolu kapatir.",
		"theme": "obsidian",
		"player_cell": Vector2i(12, 13),
		"max_alive": 5,
		"spawn_interval_min": 0.68,
		"spawn_interval_max": 1.0,
		"enemy_queue": ["grunt", "scout", "brute", "sniper", "grunt", "scout", "brute", "sniper", "brute", "sniper", "grunt", "brute", "sniper", "scout", "brute"],
		"brick_cells": _merge([
			_rect_outline(3, 2, 22, 10),
			_rect_outline(6, 4, 19, 8),
			_h_line(9, 16, 11),
			_h_line(4, 7, 12),
			_h_line(17, 20, 12)
		]),
		"steel_cells": _merge([
			_v_line(12, 2, 8),
			_v_line(13, 2, 8),
			_h_line(8, 17, 6),
			_block(5, 5, 2, 2),
			_block(18, 5, 2, 2),
			_h_line(10, 15, 3)
		])
	}


static func _generated_campaign_stage(stage_number: int) -> Dictionary:
	var extra_index := stage_number - 11
	var names := [
		"Kum Koridoru",
		"Catlak Vadi",
		"Kedi Gecidi",
		"Sessiz Hat",
		"Demir Meydan",
		"Tozlu Kavsak",
		"Yarim Cember",
		"Reaktor Yolu",
		"Kizil Gecit",
		"Golge Avlusu",
		"Siper Adasi",
		"Kanal Kilidi",
		"Kirlangic Rotasi",
		"Celik Bahce",
		"Son Nobet",
		"Obsidyen Kapan",
		"Kara Kedi Hatti",
		"Uc Kol Baskini",
		"Komuta Duvari",
		"Fetih Cephesi",
		"Demir Pusu",
		"Komutan Avi",
		"Kirik Hat",
		"Kara Baski",
		"Savas Makinesi",
		"Celik Bogum",
		"Saldiri Sefi",
		"Gece Yarigi",
		"Son Karakol",
		"Fetih Taarruzu",
		"Kor Cephe",
		"Cift Namlulu Yol",
		"Demir Dagitim",
		"Av Koridoru",
		"Kara Nobet",
		"Yikim Hatti",
		"Golge Muhafiz",
		"Ates Omurgasi",
		"Kilit Meydani",
		"Komuta Cemberi",
		"Kirik Sancak",
		"Ucuncu Dalga",
		"Sisli Cengel",
		"Zirhli Ucurum",
		"Gece Baskini",
		"Son Emir",
		"Demir Firtina",
		"Taht Kapanisi",
		"Yildirim Kusatma",
		"Kara Taarruz"
	]
	var taglines := [
		"Genis koridorlar hizli manevra icin alan acar.",
		"Parcali bloklar arasinda acik kacis rotalari var.",
		"Cekirdege giden yol iki yandan korunur.",
		"Az duvar, cok hareket ve dikkatli hedef secimi.",
		"Merkez meydan acik; yan hatlar baski kurar.",
		"Capraz yollar dusman akisini boler.",
		"Yarim halka savunmasi genis gecitler birakir.",
		"Reaktor yolunda duvarlar daha sert ama araliklar ferah.",
		"Kizil gecitte hatlar acik, dusmanlar daha cesur.",
		"Golge avlusu genis donuslerle son anda kurtarir.",
		"Siperler adacik adacik; aralardan rahat gecilir.",
		"Kanal kilitleri acik merkezde hizli karar ister.",
		"Uzak kollar merkeze baglanir, duvarlar bogaz yapmaz.",
		"Celik bahcede saglam bloklar ama buyuk gecitler var.",
		"Son nobette dusman ritmi artar, kacis payi korunur.",
		"Obsidyen kapan baskili ama dar bogaz kurmaz.",
		"Kara kedi hatti cekirdegi genis bir savunma cebine alir.",
		"Uc koldan baski gelir; ana yollar acik kalir.",
		"Komuta duvari bolmeli ama manevra alanini kapatmaz.",
		"Son cephede en guclu birlikler genis savas alanina iner.",
		"Ust koridorlardan inen mangalar hizli rota degisimi ister.",
		"Secilmis muhafizlar sahada once avlanmali.",
		"Acik hatlar ustunde gelen baski durmadan artar.",
		"Karanlik zirhli birlikler merkeze baski kurar.",
		"Agir savas tanki sahaya indiginde hat butun agirligini koyar.",
		"Duvar adalari arasinda savrulmadan pozisyon korumak gerekir.",
		"Elit saldiri liderleri temizlenmeden baski dinmez.",
		"Gece yariginda uzun acilar ve keskin atislar cezalandirir.",
		"Son karakolda tek hata butun hattin dusmesine yol acar.",
		"Fetih taarruzunda iki agir komutan ayni anda sahaya iner.",
		"Kor cephede duran tanklar seni ates yagmuruna zorlar.",
		"Cift namlulu saldiri ekipleri dar anlarda sahaya yayilir.",
		"Dagilan hatlarda yon degistirmeden hayatta kalmak zordur.",
		"Av koridorunda oncelikli hedefler seni ustune ceker.",
		"Kara nobette dusman hizi durmadan yukselir.",
		"Yikim hattinda agir birlikler duvarlarin ustunden baski kurar.",
		"Golge muhafizlar cekirdege ulasmak icin sabit hat kurar.",
		"Ates omurgasinda uc eksenden gelen mermiler nefes vermez.",
		"Kilit meydani acik gorunur ama cikislar kolay kapanir.",
		"Komuta cemberi elit tanklari tek tek ayiklamayi ister.",
		"Kirik sancakta savunma cepleri hizla erir.",
		"Ucuncu dalga geldikten sonra saha tamamen sertlesir.",
		"Sisli cengelde keskin tanklari gec fark etmek cezalandirir.",
		"Zirhli ucurumda boss tanklar koridoru agirlastirir.",
		"Gece baskininda saldiri sefleri durmadan rota degistirir.",
		"Son emir bolumunde her hata daha buyuk dalga dogurur.",
		"Demir firtina elitleri dalga dalga getirir.",
		"Taht kapanisinda kumanda katini coken bosslar korur.",
		"Yildirim kusatma birden fazla elitin ust uste indigi bolumdur.",
		"Kara taarruz campaign sonunu tum gucuyle uzerine surer."
	]
	var themes := [
		"dust", "crosswind", "canal", "echo", "iron",
		"ember", "redoubt", "reactor", "redoubt", "obsidian"
	]
	var pressure := float(extra_index) / 49.0
	var objective := _generated_objective(stage_number)
	var stage := {
		"name": names[extra_index],
		"tagline": taglines[extra_index],
		"theme": themes[extra_index % themes.size()],
		"player_cell": Vector2i(12, 13),
		"max_alive": _generated_max_alive(stage_number),
		"spawn_interval_min": lerpf(1.0, 0.72, pressure),
		"spawn_interval_max": lerpf(1.48, 1.02, pressure),
		"enemy_queue": _generated_enemy_queue(stage_number),
		"brick_cells": _generated_brick_cells(extra_index),
		"steel_cells": _generated_steel_cells(extra_index)
	}

	for key in objective.keys():
		stage[key] = objective[key]

	return stage


static func _generated_objective(stage_number: int) -> Dictionary:
	if stage_number == 32:
		return {
			"objective_type": "command_hunt",
			"objective_target_type": "warden",
			"objective_label": "Muhafiz komutanlari indir."
		}

	if stage_number == 35:
		return {
			"objective_type": "boss_hunt",
			"objective_target_type": "boss",
			"objective_label": "Boss tanki imha et."
		}

	if stage_number == 37:
		return {
			"objective_type": "command_hunt",
			"objective_target_type": "volley",
			"objective_label": "Saldiri seflerini avla."
		}

	if stage_number == 40:
		return {
			"objective_type": "boss_hunt",
			"objective_target_type": "boss",
			"objective_label": "Iki fetih komutanini durdur."
		}

	if stage_number == 44:
		return {
			"objective_type": "command_hunt",
			"objective_target_type": "warden",
			"objective_label": "Av komutanlarini ayikla."
		}

	if stage_number == 46:
		return {
			"objective_type": "boss_hunt",
			"objective_target_type": "boss",
			"objective_label": "Yikim bossunu indir."
		}

	if stage_number == 50:
		return {
			"objective_type": "command_hunt",
			"objective_target_type": "warden",
			"objective_label": "Komuta cemberini kir."
		}

	if stage_number == 52:
		return {
			"objective_type": "command_hunt",
			"objective_target_type": "volley",
			"objective_label": "Ucuncu dalga liderlerini avla."
		}

	if stage_number == 54:
		return {
			"objective_type": "boss_hunt",
			"objective_target_type": "boss",
			"objective_label": "Zirhli ucurumdaki bosslari dusur."
		}

	if stage_number == 55:
		return {
			"objective_type": "command_hunt",
			"objective_target_type": "volley",
			"objective_label": "Gece baskini seflerini temizle."
		}

	if stage_number == 58:
		return {
			"objective_type": "boss_hunt",
			"objective_target_type": "boss",
			"objective_label": "Taht komutanlarini tek tek indir."
		}

	if stage_number == 60:
		return {
			"objective_type": "boss_hunt",
			"objective_target_type": "boss",
			"objective_label": "Kara taarruzu durdur."
		}

	return {
		"objective_type": "eliminate",
		"objective_label": "Tum dusmanlari temizle."
	}


static func _generated_enemy_queue(stage_number: int) -> Array:
	var extra_index := stage_number - 11
	var total_count := 10 + int(floor(float(extra_index) * 0.52))
	var queue := []

	for enemy_index in range(total_count):
		if stage_number >= 58 and enemy_index % 8 == 3:
			queue.append(_boss_type_for_stage(stage_number, enemy_index))
		elif stage_number >= 51 and enemy_index % 6 == 1:
			queue.append("warden")
		elif stage_number >= 45 and enemy_index % 4 == 2:
			queue.append("volley")
		elif stage_number == 39 and enemy_index % 9 == 4:
			queue.append(_boss_type_for_stage(stage_number, enemy_index))
		elif stage_number >= 34 and enemy_index % 6 == 0:
			queue.append("warden")
		elif stage_number >= 31 and enemy_index % 5 == 2:
			queue.append("volley")
		elif stage_number >= 27 and enemy_index % 5 == 1:
			queue.append("sniper")
		elif stage_number >= 24 and enemy_index % 4 == 0:
			queue.append("brute")
		elif stage_number >= 20 and enemy_index % 3 == 1:
			queue.append("scout")
		elif stage_number >= 16 and enemy_index % 4 == 2:
			queue.append("sniper")
		elif stage_number >= 13 and enemy_index % 3 == 0:
			queue.append("scout")
		else:
			queue.append("grunt")

	if stage_number >= 29:
		queue.append("brute")
	if stage_number == 30:
		queue.append_array(["scout", "sniper"])
	if stage_number == 32:
		queue.append_array(["warden", "grunt", "warden"])
	if stage_number == 35:
		queue.append_array(["warden", "boss_raider"])
	if stage_number == 37:
		queue.append_array(["volley", "warden", "volley"])
	if stage_number >= 38:
		queue.append("warden")
	if stage_number == 40:
		queue.append_array(["boss_bulwark", "warden", "boss_siege"])
	if stage_number == 44:
		queue.append_array(["warden", "volley", "warden"])
	if stage_number == 46:
		queue.append_array(["boss_needle", "warden"])
	if stage_number == 50:
		queue.append_array(["warden", "warden", "volley"])
	if stage_number == 52:
		queue.append_array(["volley", "volley", "warden"])
	if stage_number == 54:
		queue.append_array(["boss_siege", "warden", "boss_titan", "boss_storm"])
	if stage_number == 55:
		queue.append_array(["volley", "volley", "warden", "volley"])
	if stage_number == 58:
		queue.append_array(["boss_crown", "warden", "boss_storm"])
	if stage_number == 60:
		queue.append_array(["boss_raider", "warden", "boss_final", "volley", "boss_hunter"])

	return queue


static func _boss_type_for_stage(stage_number: int, enemy_index: int = 0) -> String:
	var boss_cycle := [
		"boss_raider",
		"boss_hunter",
		"boss_bulwark",
		"boss_siege",
		"boss_needle",
		"boss_titan",
		"boss_storm",
		"boss_crown"
	]
	var wave_index := int(floor(float(enemy_index) / 8.0))
	var cycle_index := absi(stage_number + wave_index) % boss_cycle.size()

	return boss_cycle[cycle_index]


static func _generated_max_alive(stage_number: int) -> int:
	if stage_number >= 56:
		return 7
	if stage_number >= 48:
		return 7
	if stage_number >= 39:
		return 6
	if stage_number >= 34:
		return 6
	if stage_number >= 26:
		return 5
	if stage_number >= 20:
		return 5
	return 4


static func _generated_brick_cells(extra_index: int) -> Array:
	var cells := []

	match extra_index % 6:
		0:
			cells = _merge([
				_block(4, 4, 3, 2),
				_block(19, 4, 3, 2),
				_h_line(5, 9, 9),
				_h_line(16, 20, 9),
				_h_line(10, 15, 6)
			])
		1:
			cells = _merge([
				_v_line(5, 3, 5),
				_v_line(5, 8, 10),
				_v_line(20, 3, 5),
				_v_line(20, 8, 10),
				_h_line(9, 16, 4),
				_h_line(9, 16, 10)
			])
		2:
			cells = _merge([
				_block(3, 3, 3, 2),
				_block(20, 3, 3, 2),
				_block(7, 8, 3, 2),
				_block(16, 8, 3, 2),
				_h_line(10, 15, 5)
			])
		3:
			cells = _merge([
				_h_line(4, 8, 4),
				_h_line(17, 21, 4),
				_h_line(4, 8, 10),
				_h_line(17, 21, 10),
				_v_line(10, 6, 8),
				_v_line(15, 6, 8)
			])
		4:
			cells = _merge([
				_rect_outline(4, 3, 8, 7),
				_rect_outline(17, 3, 21, 7),
				_h_line(7, 10, 11),
				_h_line(15, 18, 11)
			])
		_:
			cells = _merge([
				_h_line(3, 7, 5),
				_h_line(18, 22, 5),
				_h_line(6, 10, 9),
				_h_line(15, 19, 9),
				_block(11, 3, 4, 2)
			])

	if extra_index >= 6:
		cells = _merge([
			cells,
			_h_line(4 + extra_index % 3, 7 + extra_index % 3, 2),
			_h_line(18 - extra_index % 3, 21 - extra_index % 3, 12)
		])

	if extra_index >= 12:
		cells = _merge([
			cells,
			_v_line(3 + extra_index % 4, 7, 9),
			_v_line(22 - extra_index % 4, 7, 9)
		])

	if extra_index == 19:
		cells = _merge([
			cells,
			_rect_outline(6, 3, 19, 10),
			_h_line(9, 16, 12)
		])

	return _clear_wide_paths(cells)


static func _generated_steel_cells(extra_index: int) -> Array:
	var cells := []

	match extra_index % 5:
		0:
			cells = _merge([
				_h_line(11, 14, 3),
				_h_line(11, 14, 9)
			])
		1:
			cells = _merge([
				_v_line(8, 3, 5),
				_v_line(17, 3, 5),
				_h_line(11, 14, 11)
			])
		2:
			cells = _merge([
				_h_line(9, 11, 6),
				_h_line(14, 16, 6),
				_h_line(11, 14, 10)
			])
		3:
			cells = _merge([
				_block(6, 6, 2, 2),
				_block(18, 6, 2, 2)
			])
		_:
			cells = _merge([
				_v_line(10, 3, 5),
				_v_line(15, 3, 5),
				_h_line(8, 17, 11)
			])

	if extra_index >= 10:
		cells = _merge([
			cells,
			_h_line(3, 5, 11),
			_h_line(20, 22, 11)
		])

	if extra_index == 19:
		cells = _merge([
			cells,
			_h_line(10, 15, 4),
			_v_line(12, 7, 9),
			_v_line(13, 7, 9)
		])

	return _clear_wide_paths(cells)


static func _clear_wide_paths(cells: Array) -> Array:
	var clear_cells := []

	for x in range(2, 24):
		clear_cells.append(Vector2i(x, 7))
	for y in range(2, 13):
		clear_cells.append(Vector2i(12, y))
		clear_cells.append(Vector2i(13, y))
	for x in range(10, 16):
		clear_cells.append(Vector2i(x, 10))
		clear_cells.append(Vector2i(x, 11))
		clear_cells.append(Vector2i(x, 12))

	for spawn_cell in [Vector2i(3, 1), Vector2i(8, 1), Vector2i(17, 1), Vector2i(22, 1), Vector2i(12, 13)]:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				clear_cells.append(spawn_cell + Vector2i(dx, dy))

	var result := []
	for cell in cells:
		if cell.x <= 0 or cell.x >= 25 or cell.y <= 0 or cell.y >= 14:
			continue
		if not clear_cells.has(cell) and not result.has(cell):
			result.append(cell)

	return result


static func _merge(chunks: Array) -> Array:
	var cells := []

	for chunk in chunks:
		for cell in chunk:
			if not cells.has(cell):
				cells.append(cell)

	return cells


static func _h_line(x1: int, x2: int, y: int) -> Array:
	var cells := []

	for x in range(mini(x1, x2), maxi(x1, x2) + 1):
		cells.append(Vector2i(x, y))

	return cells


static func _v_line(x: int, y1: int, y2: int) -> Array:
	var cells := []

	for y in range(mini(y1, y2), maxi(y1, y2) + 1):
		cells.append(Vector2i(x, y))

	return cells


static func _block(x: int, y: int, width: int, height: int) -> Array:
	var cells := []

	for px in range(x, x + width):
		for py in range(y, y + height):
			cells.append(Vector2i(px, py))

	return cells


static func _rect_outline(x1: int, y1: int, x2: int, y2: int) -> Array:
	return _merge([
		_h_line(x1, x2, y1),
		_h_line(x1, x2, y2),
		_v_line(x1, y1, y2),
		_v_line(x2, y1, y2)
	])
