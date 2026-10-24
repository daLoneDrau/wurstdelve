## The six adventurer attributes plus Luck, stored as base values.
##
## Base values are authored and do not change permanently. Effective values (conditions,
## equipment, skills, weaknesses) are computed by PlayerSystem, which writes them onto each
## AbilityScore as modifier sources, then clamps to MIN_ATTRIBUTE..MAX_ATTRIBUTE.
##
## Luck is stored as an ability so it lives with the other sheet numbers, but it is a spendable
## counter, not an attribute: it has no Test, no 2..11 range, and no modifiers. Its cap is the
## effective MAG, enforced by a system. Loop over ATTRIBUTE_KEYS, never ability_set.keys(),
## when you mean "the attributes".
class_name AttributesComponent
extends AbilitiesComponent

const IS_SLOT_ROOT: bool = true

const AGI: StringName = &"agi"
const CON: StringName = &"con"
const MAG: StringName = &"mag"
const MRL: StringName = &"mrl"
const PER: StringName = &"per"
const STR: StringName = &"str"
const LUCK: StringName = &"luck"

## The six attributes in sheet order. Excludes Luck.
const ATTRIBUTE_KEYS: Array[StringName] = [AGI, CON, MAG, MRL, PER, STR]

const MIN_ATTRIBUTE: int = 2
const MAX_ATTRIBUTE: int = 11
## 7 is the average attribute value in the rules.
const DEFAULT_ATTRIBUTE: int = 7


func _init() -> void:
	super()
	for key in ATTRIBUTE_KEYS:
		add(key, DEFAULT_ATTRIBUTE)
	add(LUCK, 0)


## Determines if a key is one of the six attributes (so not Luck).
static func is_attribute(key: StringName) -> bool:
	return ATTRIBUTE_KEYS.has(key)
