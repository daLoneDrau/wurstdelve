## Item class tags: the classes printed on an Item card (Rules Reference, "Card classes").
## Used as a bitmask FlagSet in ItemComponent.item_type.
##
## What is deliberately not a tag:
## - Equipment slots (Body, Gauntlet, Head, Jewelry, 1H, LH, 2H) live in ItemComponent.equip_slots.
## - Heavy is DDItemComponent.heavy.
## - Unique is EntityTags.Tag.UNIQUE on the item entity.
## - Attack types (Melee, Range, Reach) are AttackTypeTags in ItemComponent.weapon_type_flags.
##
## Every bit below comes from the Rules Reference text, not yet from a card. Add or remove bits
## as cards are reviewed. GDScript ints give 63 usable bits.
class_name ItemTags


enum Tag {
	LOOT_ONLY   = 1 << 0,  # cannot be bought while Trading, only found
	TOWN_ONLY   = 1 << 1,  # cannot be drawn while looting, only offered while Trading in a Town
	FOOD        = 1 << 2,
	AMMO        = 1 << 3,  # an Ammo Item; combined with SHOT or ARROWS
	SHOT        = 1 << 4,  # Ammo type, on the Ammo Item
	ARROWS      = 1 << 5,  # Ammo type, on the Ammo Item
	USES_SHOT   = 1 << 6,  # a weapon that can load SHOT Ammo
	USES_ARROWS = 1 << 7,  # a weapon that can load ARROWS Ammo
}


## Returns every Tag value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Tag.values():
		out.append(int(v))
	return out


## Gets the Tag value for an enum key such as "FOOD" (case-insensitive).
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
