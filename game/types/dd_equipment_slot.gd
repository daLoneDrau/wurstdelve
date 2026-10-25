## Dungeon Degenerates equipment slots (Rules Reference, "Equipment slots").
##
## Extends the framework's EquipmentSlot and leaves its Enum untouched, because that base class
## is shared by other projects. GDScript cannot add values to an inherited enum, so DD reuses
## the base values it can and adds the rest as constants outside the base range. Every value is
## a plain int, so it works anywhere the framework expects an EquipmentSlot.Enum value
## (ItemComponent.equip_slots, EquipmentComponent.slots, EquipmentSystem.HAND_SLOTS).
##
## DD slot            Value
## Head               EquipmentSlot.Enum.HEAD
## Body               EquipmentSlot.Enum.CHEST (the base slot for the upper body)
## Gauntlet           GAUNTLET (new)
## Right/Left Hand    EquipmentSlot.Enum.MAIN_HAND / OFF_HAND
## Jewelry 1 to 4     JEWELRY_1 to JEWELRY_4 (new)
##
## Hand classes are properties of the Item, not slots:
## - 1H (either hand): equip_slots [RIGHT_HAND, LEFT_HAND]
## - LH (left hand only): equip_slots [LEFT_HAND]
## - 2H (both hands): equip_slots [RIGHT_HAND] and two_handed = true
## Jewelry has four interchangeable slots, so a Jewelry Item lists all four.
##
## An item record names its slot with the one word printed on the card (body, gauntlet, head,
## jewelry, 1h, lh or 2h). card_slot_to_equip() expands that word into equip_slots and two_handed.
##
## The base class's string lookups (from_string, value_or_minus_one) know nothing of DD slots,
## so use key_of and from_key here instead.
class_name DDEquipmentSlot
extends EquipmentSlot

const BODY: int = EquipmentSlot.Enum.CHEST
const RIGHT_HAND: int = EquipmentSlot.Enum.MAIN_HAND
const LEFT_HAND: int = EquipmentSlot.Enum.OFF_HAND

## New DD slots. These sit well above the base enum's values (0 to 9) so that a future base
## slot can never collide with them.
const GAUNTLET: int = 100
const JEWELRY_1: int = 101
const JEWELRY_2: int = 102
const JEWELRY_3: int = 103
const JEWELRY_4: int = 104

const _KEYS: Dictionary = {
	EquipmentSlot.Enum.HEAD: "HEAD",
	BODY: "BODY",
	GAUNTLET: "GAUNTLET",
	RIGHT_HAND: "RIGHT_HAND",
	LEFT_HAND: "LEFT_HAND",
	JEWELRY_1: "JEWELRY_1",
	JEWELRY_2: "JEWELRY_2",
	JEWELRY_3: "JEWELRY_3",
	JEWELRY_4: "JEWELRY_4",
	}


## Returns every DD slot value, in sheet order.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in _KEYS.keys():
		out.append(int(v))
	return out


## Expands the slot word printed on an Item card ("body", "gauntlet", "head", "jewelry", "1h",
## "lh" or "2h", case-insensitive) into {"equip_slots": Array[int], "two_handed": bool} for
## ItemComponent. Returns an empty Dictionary if the word is not a card slot. An Item with no
## slot is not handled here: the caller leaves equip_slots empty.
static func card_slot_to_equip(word: String) -> Dictionary:
	var equip_slots: Array[int] = []
	var two_handed: bool = false
	match word.strip_edges().to_lower():
		"body":
			equip_slots = [BODY]
		"gauntlet":
			equip_slots = [GAUNTLET]
		"head":
			equip_slots = [EquipmentSlot.Enum.HEAD]
		"jewelry":
			equip_slots = [JEWELRY_1, JEWELRY_2, JEWELRY_3, JEWELRY_4]
		"1h":
			equip_slots = [RIGHT_HAND, LEFT_HAND]
		"lh":
			equip_slots = [LEFT_HAND]
		"2h":
			equip_slots = [RIGHT_HAND]
			two_handed = true
		_:
			return {}
	return {"equip_slots": equip_slots, "two_handed": two_handed}


## Gets the slot value for a key such as "body" or "left hand" (case-insensitive; spaces and
## hyphens count as underscores). Returns -1 if the key is unknown.
static func from_key(key: String) -> int:
	var k: String = key.strip_edges().to_upper().replace("-", "_").replace(" ", "_")
	for v in _KEYS.keys():
		if _KEYS[v] == k:
			return int(v)
	return -1


## Gets the key for a DD slot value, or "UNKNOWN".
static func key_of(value: int) -> String:
	return str(_KEYS.get(value, "UNKNOWN"))


## Determines if a value is one of the DD slots.
static func is_dd_slot(value: int) -> bool:
	return _KEYS.has(value)


## Determines if a value is one of the four jewelry slots.
static func is_jewelry(value: int) -> bool:
	return value >= JEWELRY_1 and value <= JEWELRY_4


## Determines if a value is one of the two hand slots.
static func is_hand(value: int) -> bool:
	return value == RIGHT_HAND or value == LEFT_HAND


## Gets the display name for a DD slot value, or "Unknown Slot".
static func name_of(value: int) -> String:
	if not _KEYS.has(value):
		return "Unknown Slot"
	return str(_KEYS[value]).capitalize()
