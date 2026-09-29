extends RefCounted

# Each packet carries its own columns. No previous packet or entity cache is needed.
const ENTITY_FIELDS := ["players", "enemies", "bullets", "pickups", "walls"]


static func encode(snapshot: Dictionary) -> Dictionary:
	var packed := snapshot.duplicate(false)
	packed["wire_format"] = 1
	for field in ENTITY_FIELDS:
		var entries: Array = snapshot.get(field, [])
		if entries.is_empty():
			continue
		var columns: Array = entries[0].keys()
		var rows: Array = []
		var uniform := true
		for entry in entries:
			if entry.keys() != columns:
				uniform = false
				break
			rows.append(entry.values())
		if uniform:
			packed[field] = {"columns": columns, "rows": rows}
	return packed


static func decode(packed: Dictionary) -> Dictionary:
	if not packed.has("wire_format"):
		return packed
	if packed["wire_format"] != 1:
		return {}
	var snapshot := packed.duplicate(false)
	snapshot.erase("wire_format")
	for field in ENTITY_FIELDS:
		var table = packed.get(field, [])
		if table is Array:
			continue
		if not table is Dictionary or not table.get("columns") is Array or not table.get("rows") is Array:
			return {}
		var columns: Array = table["columns"]
		if columns.size() > 64:
			return {}
		var seen := {}
		for column in columns:
			if not column is String or seen.has(column):
				return {}
			seen[column] = true
		var entries: Array = []
		for row in table["rows"]:
			if not row is Array or row.size() != columns.size():
				return {}
			var entry := {}
			for index in range(columns.size()):
				entry[columns[index]] = row[index]
			entries.append(entry)
		snapshot[field] = entries
	return snapshot
