## Dungeon Degenerates asset library.
##
## Extends the framework's media-only AssetsLibrary with authored game data that is loaded
## once at startup (DDGameEngine.load_resources) and then looked up by id. Malformed records
## are reported and skipped at load time, so mistakes show up at launch, not mid-game.
##
## Records are read-only after loading: getters return deep copies, so nothing can change
## the shared data by accident. clear_all() clears the records as well as the media.
class_name DDAssetsLibrary
extends AssetsLibrary

const ADVENTURER_DIR: String = "res://game/data/adventurers"

## GP and XP can never exceed 21.
const MAX_COUNTER: int = 21

## adventurer id -> authored record (parsed JSON; numbers are floats, so convert with int())
var _adventurer_records: Dictionary[String, Dictionary] = {}


## —————————————————————————————————————————————
#region Adventurer records
## —————————————————————————————————————————————

## Loads and validates every .json adventurer record in a folder, replacing any records already
## loaded. Invalid records are reported with push_error and skipped. Returns how many loaded.
func load_adventurer_records(dir_path: String = ADVENTURER_DIR) -> int:
	_adventurer_records.clear()

	var files: PackedStringArray = DirAccess.get_files_at(dir_path)
	if files.is_empty():
		push_error("DDAssetsLibrary: no files found in '%s'" % dir_path)
		return 0
	files.sort()

	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var path: String = "%s/%s" % [dir_path, file_name]

		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			push_error("DDAssetsLibrary: %s is not a valid JSON object." % path)
			continue
		var record: Dictionary = parsed

		var problems: Array[String] = _validate_adventurer_record(record)
		if not problems.is_empty():
			for problem in problems:
				push_error("DDAssetsLibrary: %s: %s" % [path, problem])
			continue

		var id: String = str(record["id"])
		if _adventurer_records.has(id):
			push_error("DDAssetsLibrary: %s: duplicate adventurer id '%s'." % [path, id])
			continue
		_adventurer_records[id] = record

	return _adventurer_records.size()


func has_adventurer_record(id: String) -> bool:
	return _adventurer_records.has(id)


## Returns the ids of all loaded adventurer records.
func get_adventurer_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _adventurer_records.keys():
		ids.append(id)
	return ids


## Returns a deep copy of an adventurer record, or an empty Dictionary if there is none.
func get_adventurer_record(id: String, warn_if_missing: bool = true) -> Dictionary:
	if _adventurer_records.has(id):
		return _adventurer_records[id].duplicate(true)
	if warn_if_missing:
		push_warning("DDAssetsLibrary: Adventurer record '%s' not found" % id)
	return {}


## Returns a list of problems with a record. An empty list means it is valid.
func _validate_adventurer_record(record: Dictionary) -> Array[String]:
	var problems: Array[String] = []

	if str(record.get("id", "")).is_empty():
		problems.append("missing id")
	if str(record.get("name", "")).is_empty():
		problems.append("missing name")

	var classes: Variant = record.get("classes", null)
	if not (classes is Array) or (classes as Array).is_empty():
		problems.append("classes must be a non-empty list")
	else:
		for class_key in classes:
			if ClassTags.from_key(str(class_key)) == 0:
				problems.append("unknown class '%s'" % class_key)

	var attributes: Variant = record.get("attributes", null)
	if not (attributes is Dictionary):
		problems.append("attributes must be an object")
	else:
		for key in AttributesComponent.ATTRIBUTE_KEYS:
			var value: Variant = (attributes as Dictionary).get(str(key), null)
			if not _is_whole_number(value):
				problems.append("attribute '%s' must be a whole number" % key)
			else:
				var lowest: int = AttributesComponent.MIN_ATTRIBUTE
				var highest: int = AttributesComponent.MAX_ATTRIBUTE
				if int(value) < lowest or int(value) > highest:
					problems.append("attribute '%s' must be between %d and %d" % [key, lowest, highest])

	# Luck is capped by MAG, which the factory enforces; here it only has to be a sane number.
	for counter in ["luck", "gp", "xp"]:
		var value: Variant = record.get(counter, 0)
		if not _is_whole_number(value) or int(value) < 0:
			problems.append("'%s' must be a whole number, 0 or more" % counter)
		elif counter != "luck" and int(value) > MAX_COUNTER:
			problems.append("'%s' cannot exceed %d" % [counter, MAX_COUNTER])

	for list_key in ["skills", "weaknesses", "starting_items"]:
		if record.has(list_key) and not (record[list_key] is Array):
			problems.append("'%s' must be a list" % list_key)

	# every adventurer has its own script class
	var script_path: String = str(record.get("script", ""))
	if script_path.is_empty():
		problems.append("missing script")
	elif not ResourceLoader.exists(script_path):
		problems.append("script not found: %s" % script_path)
	else:
		var loaded: Script = load(script_path) as Script
		if loaded == null or not _script_extends(loaded, "EntityScript"):
			problems.append("script does not extend EntityScript: %s" % script_path)

	return problems


## Determines if a script has an ancestor with the given global class name.
func _script_extends(script: Script, global_name: String) -> bool:
	var current: Script = script.get_base_script()
	while current != null:
		if current.get_global_name() == global_name:
			return true
		current = current.get_base_script()
	return false


func _is_whole_number(value: Variant) -> bool:
	var t: int = typeof(value)
	if t == TYPE_INT:
		return true
	return t == TYPE_FLOAT and float(value) == floorf(float(value))

#endregion


## —————————————————————————————————————————————
#region Overrides
## —————————————————————————————————————————————

func clear_all() -> void:
	super()
	_adventurer_records.clear()


func get_loaded_asset_counts() -> Dictionary:
	var counts: Dictionary = super()
	counts["adventurer_records"] = _adventurer_records.size()
	return counts

#endregion
