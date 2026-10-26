## The three kinds of space on the board (Rules Reference, "Map structure").
##
## Whether a Location is a Settlement is a trait (SpaceTags.Tag.SETTLEMENT), not a kind.
## Paths and Roads are the two kinds of connector. Each has one or two Location ends and never
## touches another Path or Road.
class_name SpaceKind


enum Kind {
	LOCATION,
	PATH,
	ROAD,
}


## Returns every Kind value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Kind.values():
		out.append(int(v))
	return out


## Gets the Kind for an enum key such as "road" (case-insensitive).
## Returns -1 if the key is unknown.
static func from_key(key: String) -> int:
	var k: String = key.strip_edges().to_upper()
	if Kind.has(k):
		return int(Kind[k])
	return -1


## Gets the enum key for a Kind value, or "UNKNOWN".
static func to_key(value: int) -> String:
	var key: Variant = Kind.find_key(value)
	if key == null:
		return "UNKNOWN"
	return str(key)


static func display_name(value: int) -> String:
	return to_key(value).capitalize()


## True for a Path or a Road.
static func is_connector(value: int) -> bool:
	return value == Kind.PATH or value == Kind.ROAD
