## Attack types shown in parentheses on an Attack: Melee, Range or Reach.
## Used as a bitmask FlagSet in ItemComponent.weapon_type_flags. An Item grants an Attack
## exactly when that FlagSet is not empty.
##
## Attack types have no rules of their own; other abilities and effects refer to them
## (Evade helps against Melee but not against Reach or Range).
class_name AttackTypeTags


enum Tag {
	MELEE = 1 << 0,
	RANGE = 1 << 1,
	REACH = 1 << 2,
}


## Returns every Tag value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Tag.values():
		out.append(int(v))
	return out


## Gets the Tag value for an enum key such as "MELEE" (case-insensitive).
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
