## The map's Regions (Rules Reference, "Territories and Regions").
##
## A Region is static data. It has no state of its own: Voidgate counts and the like are worked
## out from the spaces. A Territory names its Region, and a space's Region is its Territory's.
## The Maze lives in the Void Region.
##
## The colour is the Region's colour on the board. It also names the Monster deck and Doom
## counter for the Region (the Void has neither).
class_name MapRegions


enum Region {
	BADLANDS,
	HIGHLANDS,
	LOWLANDS,
	WETLANDS,
	VOID,
}

const COLORS: Dictionary = {
	Region.BADLANDS:  "red",
	Region.HIGHLANDS: "yellow",
	Region.LOWLANDS:  "blue",
	Region.WETLANDS:  "green",
	Region.VOID:      "black",
}


## Returns every Region value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Region.values():
		out.append(int(v))
	return out


## Gets the Region for an enum key such as "BADLANDS" (case-insensitive).
## Returns -1 if the key is unknown.
static func from_key(key: String) -> int:
	var k: String = key.strip_edges().to_upper()
	if Region.has(k):
		return int(Region[k])
	return -1


## Gets the enum key for a Region value, or "UNKNOWN".
static func to_key(value: int) -> String:
	var key: Variant = Region.find_key(value)
	if key == null:
		return "UNKNOWN"
	return str(key)


static func display_name(value: int) -> String:
	return to_key(value).capitalize()


## The Region's colour on the board, or "" if the value is unknown.
static func color_name(value: int) -> String:
	return str(COLORS.get(value, ""))
