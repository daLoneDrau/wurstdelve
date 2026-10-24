## Class tags shared by adventurers, monsters, encounters, items, skills and weaknesses.
## Used as bitmask FlagSets (for example AdventurerComponent.classes).
## Add classes here as card data is reviewed. GDScript ints give 63 usable bits.
class_name ClassTags


enum Tag {
	HUMAN  = 1 << 0,  # Hinterlander, Vermin Hunter
	HUNTER = 1 << 1,  # Hinterlander, Vermin Hunter
	WILD   = 1 << 2,  # Hinterlander
	ROGUE  = 1 << 3,  # Vermin Hunter
}


## Returns every Tag value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Tag.values():
		out.append(int(v))
	return out


## Gets the Tag value for an enum key such as "HUMAN" (case-insensitive).
## Returns 0 if the key is unknown.
static func from_key(key: String) -> int:
	var k: String = key.strip_edges().to_upper()
	if Tag.has(k):
		return int(Tag[k])
	return 0


## Gets the enum key for a single Tag value, or "UNKNOWN".
static func to_key(value: int) -> String:
	var key: Variant = Tag.find_key(value)
	if key == null:
		return "UNKNOWN"
	return str(key)


static func display_name(value: int) -> String:
	return to_key(value).capitalize()
