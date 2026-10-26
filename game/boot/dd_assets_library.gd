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
const ITEM_DIR: String = "res://game/data/items"
const MAP_FILE: String = "res://game/data/map/map.json"

## GP and XP can never exceed 21.
const MAX_COUNTER: int = 21

## adventurer id -> authored record (parsed JSON; numbers are floats, so convert with int())
var _adventurer_records: Dictionary[String, Dictionary] = {}

## item id -> authored record (parsed JSON; numbers are floats, so convert with int())
var _item_records: Dictionary[String, Dictionary] = {}

## The validated map document: { territories, locations, connectors, links }. Empty until loaded.
var _map_document: Dictionary = {}


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

	# the biography is a list of paragraphs (it may be empty while a record is being authored)
	if record.has("biography"):
		var biography: Variant = record["biography"]
		if not (biography is Array):
			problems.append("biography must be a list of paragraphs")
		else:
			for paragraph in biography:
				if not (paragraph is String) or (paragraph as String).strip_edges().is_empty():
					problems.append("biography paragraphs must be non-empty text")
					break

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
#region Item records
## —————————————————————————————————————————————

## Loads and validates every .json item record in a folder, replacing any records already
## loaded. Invalid records are reported with push_error and skipped. Returns how many loaded.
##
## A record holds:
##   id, name (required), price (required, whole number, 0 or more)
##   heavy, unique (true or false)
##   tags (ItemTags keys), slot (body, gauntlet, head, jewelry, 1h, lh or 2h)
##   attack_types (AttackTypeTags keys) and attack_attributes (attribute keys), given together
##   requirements ({ "str": 6 }, a minimum for each attribute)
##   modifiers ({ "stats": { "arm": 1 } })
##   text (the printed rule), flavor
##   script (optional; must extend DDItemScript) and script_vars (the script's variables:
##   whole numbers, true or false, or text)
func load_item_records(dir_path: String = ITEM_DIR) -> int:
	_item_records.clear()

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

		var problems: Array[String] = _validate_item_record(record)
		if not problems.is_empty():
			for problem in problems:
				push_error("DDAssetsLibrary: %s: %s" % [path, problem])
			continue

		var id: String = str(record["id"])
		if _item_records.has(id):
			push_error("DDAssetsLibrary: %s: duplicate item id '%s'." % [path, id])
			continue
		_item_records[id] = record

	return _item_records.size()


func has_item_record(id: String) -> bool:
	return _item_records.has(id)


## Returns the ids of all loaded item records.
func get_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _item_records.keys():
		ids.append(id)
	return ids


## Returns a deep copy of an item record, or an empty Dictionary if there is none.
func get_item_record(id: String, warn_if_missing: bool = true) -> Dictionary:
	if _item_records.has(id):
		return _item_records[id].duplicate(true)
	if warn_if_missing:
		push_warning("DDAssetsLibrary: Item record '%s' not found" % id)
	return {}


## Returns a list of problems with a record. An empty list means it is valid.
func _validate_item_record(record: Dictionary) -> Array[String]:
	var problems: Array[String] = []

	if str(record.get("id", "")).is_empty():
		problems.append("missing id")
	if str(record.get("name", "")).is_empty():
		problems.append("missing name")

	var price: Variant = record.get("price", null)
	if not _is_whole_number(price) or int(price) < 0:
		problems.append("price must be a whole number, 0 or more")

	for flag_key in ["heavy", "unique"]:
		if record.has(flag_key) and not (record[flag_key] is bool):
			problems.append("'%s' must be true or false" % flag_key)

	for text_key in ["text", "flavor"]:
		if record.has(text_key) and not (record[text_key] is String):
			problems.append("'%s' must be text" % text_key)

	# classes printed on the card, and the attack types
	problems.append_array(_validate_flag_keys(record, "tags", ItemTags.from_key, "item tag"))
	problems.append_array(
			_validate_flag_keys(record, "attack_types", AttackTypeTags.from_key, "attack type")
	)

	# the slot is the one word printed on the card
	if record.has("slot"):
		var slot_word: Variant = record["slot"]
		if not (slot_word is String) or DDEquipmentSlot.card_slot_to_equip(slot_word).is_empty():
			problems.append("unknown slot '%s'" % str(slot_word))

	# an Attack has both an attack type and the attribute(s) it is tested against
	var has_types: bool = _is_non_empty_list(record.get("attack_types", null))
	var has_attributes: bool = _is_non_empty_list(record.get("attack_attributes", null))
	if has_types and not has_attributes:
		problems.append("attack_types needs attack_attributes")
	elif has_attributes and not has_types:
		problems.append("attack_attributes needs attack_types")
	if record.has("attack_attributes"):
		if not (record["attack_attributes"] is Array):
			problems.append("attack_attributes must be a list")
		else:
			for key in record["attack_attributes"]:
				if not AttributesComponent.ATTRIBUTE_KEYS.has(StringName(str(key))):
					problems.append("attack_attributes: '%s' is not an attribute" % key)

	# requirements: a minimum for each attribute, for example { "str": 6 }
	problems.append_array(_validate_attribute_minimums(record, "requirements"))

	# modifiers: only flat attribute and ARM changes for now, for example { "stats": { "arm": 1 } }
	if record.has("modifiers"):
		var modifiers: Variant = record["modifiers"]
		if not (modifiers is Dictionary):
			problems.append("modifiers must be an object")
		else:
			for key in modifiers:
				if str(key) != "stats":
					problems.append("modifiers: only 'stats' is supported, not '%s'" % key)
			var stats: Variant = (modifiers as Dictionary).get("stats", {})
			if not (stats is Dictionary):
				problems.append("modifiers.stats must be an object")
			else:
				for key in stats:
					var stat: StringName = StringName(str(key))
					if stat != AttributesComponent.ARM \
							and not AttributesComponent.ATTRIBUTE_KEYS.has(stat):
						problems.append("modifiers.stats: '%s' is not an attribute or arm" % key)
					var amount: Variant = stats[key]
					if not _is_whole_number(amount) or int(amount) == 0:
						problems.append("modifiers.stats: '%s' must be a whole number, not 0" % key)

	# a script is optional for an item; when given it must extend DDItemScript
	var script_path: String = str(record.get("script", ""))
	if not script_path.is_empty():
		if not ResourceLoader.exists(script_path):
			problems.append("script not found: %s" % script_path)
		else:
			var loaded: Script = load(script_path) as Script
			if loaded == null or not _script_extends(loaded, "DDItemScript"):
				problems.append("script does not extend DDItemScript: %s" % script_path)

	# script variables: plain values only, because ScriptVariable cannot hold JSON arrays
	if record.has("script_vars"):
		var script_vars: Variant = record["script_vars"]
		if not (script_vars is Dictionary):
			problems.append("script_vars must be an object")
		else:
			if script_path.is_empty() and not (script_vars as Dictionary).is_empty():
				problems.append("script_vars needs a script")
			for key in script_vars:
				var value: Variant = script_vars[key]
				if str(key).is_empty():
					problems.append("script_vars: a name is empty")
				elif not (value is bool or value is String or _is_whole_number(value)):
					problems.append("script_vars: '%s' must be a whole number, true or false, or text" % key)

	return problems


## Returns problems for a list of tag keys. `resolver` maps a key to its bit (0 if unknown).
func _validate_flag_keys(
		record: Dictionary, list_key: String, resolver: Callable, label: String
) -> Array[String]:
	var problems: Array[String] = []
	if not record.has(list_key):
		return problems
	var keys: Variant = record[list_key]
	if not (keys is Array):
		problems.append("'%s' must be a list" % list_key)
		return problems
	for key in keys:
		if int(resolver.call(str(key))) == 0:
			problems.append("unknown %s '%s'" % [label, key])
	return problems


## Returns problems for an object of attribute minimums, such as { "str": 6 }.
func _validate_attribute_minimums(record: Dictionary, object_key: String) -> Array[String]:
	var problems: Array[String] = []
	if not record.has(object_key):
		return problems
	var minimums: Variant = record[object_key]
	if not (minimums is Dictionary):
		problems.append("%s must be an object" % object_key)
		return problems
	var lowest: int = AttributesComponent.MIN_ATTRIBUTE
	var highest: int = AttributesComponent.MAX_ATTRIBUTE
	for key in minimums:
		if not AttributesComponent.ATTRIBUTE_KEYS.has(StringName(str(key))):
			problems.append("%s: '%s' is not an attribute" % [object_key, key])
			continue
		var value: Variant = minimums[key]
		if not _is_whole_number(value) or int(value) < lowest or int(value) > highest:
			problems.append("%s: '%s' must be between %d and %d" % [object_key, key, lowest, highest])
	return problems


func _is_non_empty_list(value: Variant) -> bool:
	return value is Array and not (value as Array).is_empty()

#endregion


## —————————————————————————————————————————————
#region Map records
## —————————————————————————————————————————————

## Loads and validates the map document, replacing any already loaded. The map is a graph, so it
## loads whole: if any problem is found every problem is reported with push_error and nothing is
## loaded. Returns the number of spaces (Locations plus Paths and Roads) loaded, or 0.
##
## The document is one JSON object with four lists:
##   territories: id, name, region (MapRegions key), theme_color, traits (SpaceTags keys)
##   locations:   id, name, kind ("location"), territory, own_level (true or false), traits
##   connectors:  id, kind ("path" or "road"), territory, ends (one or two Location ids)
##   links:       pairs of Location ids joined directly, with no Path or Road between them
## A space's Region is its Territory's, so a record has no region of its own. Levels and
## Explored counters are state, not authored data, so they are not in the document.
func load_map_records(path: String = MAP_FILE) -> int:
	_map_document = {}

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("DDAssetsLibrary: %s is not a valid JSON object." % path)
		return 0
	var document: Dictionary = parsed

	var problems: Array[String] = validate_map_document(document)
	if not problems.is_empty():
		for problem in problems:
			push_error("DDAssetsLibrary: %s: %s" % [path, problem])
		return 0

	_map_document = document
	return (document["locations"] as Array).size() + (document["connectors"] as Array).size()


func has_map_records() -> bool:
	return not _map_document.is_empty()


## Returns a deep copy of the validated map document, or an empty Dictionary if none is loaded.
## MapService is built from it.
func get_map_document() -> Dictionary:
	return _map_document.duplicate(true)


## Returns a list of problems with a map document. An empty list means it is valid.
func validate_map_document(document: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for list_key in ["territories", "locations", "connectors", "links"]:
		if not (document.get(list_key, null) is Array):
			problems.append("'%s' must be a list" % list_key)
	if not problems.is_empty():
		return problems

	# --- Territories ---
	var territory_ids: Dictionary = {}
	for territory in document["territories"]:
		if not (territory is Dictionary):
			problems.append("territories: every entry must be an object")
			continue
		var tid: String = str((territory as Dictionary).get("id", ""))
		if tid.is_empty():
			problems.append("territories: an entry has no id")
			continue
		if territory_ids.has(tid):
			problems.append("territories: duplicate id '%s'" % tid)
		territory_ids[tid] = true
		if str(territory.get("name", "")).is_empty():
			problems.append("territory '%s': missing name" % tid)
		if MapRegions.from_key(str(territory.get("region", ""))) == -1:
			problems.append("territory '%s': unknown region '%s'" % [tid, territory.get("region", "")])
		if str(territory.get("theme_color", "")).is_empty():
			problems.append("territory '%s': missing theme_color" % tid)
		problems.append_array(_validate_space_traits(territory, "territory '%s'" % tid))

	# --- Locations ---
	var location_ids: Dictionary = {}
	var space_ids: Dictionary = {}
	for location in document["locations"]:
		if not (location is Dictionary):
			problems.append("locations: every entry must be an object")
			continue
		var lid: String = str((location as Dictionary).get("id", ""))
		if lid.is_empty():
			problems.append("locations: an entry has no id")
			continue
		if space_ids.has(lid):
			problems.append("duplicate space id '%s'" % lid)
		space_ids[lid] = true
		location_ids[lid] = true
		var label: String = "location '%s'" % lid
		if str(location.get("name", "")).is_empty():
			problems.append("%s: missing name" % label)
		if str(location.get("kind", "")) != "location":
			problems.append("%s: kind must be \"location\"" % label)
		if not territory_ids.has(str(location.get("territory", ""))):
			problems.append("%s: unknown territory '%s'" % [label, location.get("territory", "")])
		if not (location.get("own_level", null) is bool):
			problems.append("%s: own_level must be true or false" % label)
		problems.append_array(_validate_space_traits(location, label))

	# --- Paths and Roads ---
	for connector in document["connectors"]:
		if not (connector is Dictionary):
			problems.append("connectors: every entry must be an object")
			continue
		var cid: String = str((connector as Dictionary).get("id", ""))
		if cid.is_empty():
			problems.append("connectors: an entry has no id")
			continue
		if space_ids.has(cid):
			problems.append("duplicate space id '%s'" % cid)
		space_ids[cid] = true
		var label: String = "connector '%s'" % cid
		var kind: String = str(connector.get("kind", ""))
		if kind != "path" and kind != "road":
			problems.append("%s: kind must be \"path\" or \"road\"" % label)
		if not territory_ids.has(str(connector.get("territory", ""))):
			problems.append("%s: unknown territory '%s'" % [label, connector.get("territory", "")])
		if connector.has("traits"):
			problems.append("%s: a Path or Road has no traits of its own; it shares its Territory's" % label)
		var ends: Variant = connector.get("ends", null)
		if not (ends is Array) or (ends as Array).size() < 1 or (ends as Array).size() > 2:
			problems.append("%s: ends must list one or two Locations" % label)
			continue
		var seen_ends: Dictionary = {}
		for end_id in ends:
			if not location_ids.has(str(end_id)):
				problems.append("%s: end '%s' is not a Location" % [label, end_id])
			if seen_ends.has(str(end_id)):
				problems.append("%s: both ends are '%s'" % [label, end_id])
			seen_ends[str(end_id)] = true

	# --- direct links between Locations ---
	var seen_links: Dictionary = {}
	for link in document["links"]:
		if not (link is Array) or (link as Array).size() != 2:
			problems.append("links: every link must be a pair of Location ids")
			continue
		var a: String = str(link[0])
		var b: String = str(link[1])
		if not location_ids.has(a) or not location_ids.has(b):
			problems.append("links: '%s' and '%s' must both be Locations" % [a, b])
			continue
		if a == b:
			problems.append("links: '%s' is linked to itself" % a)
		var pair: Array = [a, b]
		pair.sort()
		var pair_key: String = "|".join(pair)
		if seen_links.has(pair_key):
			problems.append("links: '%s' and '%s' are linked twice" % [a, b])
		seen_links[pair_key] = true

	return problems


## Returns problems for the "traits" list of a Location or Territory record.
func _validate_space_traits(record: Dictionary, label: String) -> Array[String]:
	var problems: Array[String] = []
	var keys: Variant = record.get("traits", [])
	if not (keys is Array):
		problems.append("%s: traits must be a list" % label)
		return problems
	for key in keys:
		var tag: int = SpaceTags.from_key(str(key))
		if tag == 0:
			problems.append("%s: unknown trait '%s'" % [label, key])
		elif (tag & SpaceTags.DERIVED_ONLY) != 0:
			problems.append("%s: '%s' is derived, so it cannot be authored" % [label, key])
	return problems

#endregion


## —————————————————————————————————————————————
#region Overrides
## —————————————————————————————————————————————

func clear_all() -> void:
	super()
	_adventurer_records.clear()
	_item_records.clear()
	_map_document = {}


func get_loaded_asset_counts() -> Dictionary:
	var counts: Dictionary = super()
	counts["adventurer_records"] = _adventurer_records.size()
	counts["item_records"] = _item_records.size()
	counts["map_spaces"] = (
		(_map_document["locations"] as Array).size() + (_map_document["connectors"] as Array).size()
		if has_map_records() else 0
	)
	return counts

#endregion
