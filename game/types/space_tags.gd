## Space traits (Rules Reference, "Space traits").
## Used as bitmask FlagSets: the authored traits on a Location or Territory record, and the added
## traits on a SpaceState.
##
## A space's effective traits are worked out by MapService from three layers, and the result is
## never stored:
## - authored: printed on the Location's record, or on its Territory for a Path or Road
## - added: put there during play by cards and missions, held in SpaceState.added_traits
## - derived: TOWN (a Settlement with Town Level 1 or more) and PERILOUS (where the Hand of
##   Doom is). A record may not list a derived-only trait.
##
## Bits come from the Rules Reference trait table. GDScript ints give 63 usable bits.
class_name SpaceTags


enum Tag {
	BASE        = 1 << 0,   # the party is established as allies here
	DESTROYED   = 1 << 1,   # impassible
	EXPLORED    = 1 << 2,   # an Explored counter: Force March on a Path, extra Loot when Trading
	FUNGUS      = 1 << 3,
	INSIDE      = 1 << 4,
	LAKE_PORT   = 1 << 5,
	LAW         = 1 << 6,
	METAPHYSICAL = 1 << 7,
	OUTSIDE     = 1 << 8,
	PERILOUS    = 1 << 9,
	RIVER_PORT  = 1 << 10,
	SETTLEMENT  = 1 << 11,
	TOWN        = 1 << 12,  # derived only, never authored or added
	VOID        = 1 << 13,
	WOODLAND    = 1 << 14,
}

## Traits that are only ever derived. Authored data and add_trait() reject them.
const DERIVED_ONLY: int = Tag.TOWN


## Returns every Tag value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Tag.values():
		out.append(int(v))
	return out


## Gets the Tag value for an enum key such as "INSIDE" (case-insensitive).
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


## Returns true if the value is exactly one Tag bit.
static func is_single_tag(value: int) -> bool:
	return value > 0 and (value & (value - 1)) == 0 and Tag.find_key(value) != null
