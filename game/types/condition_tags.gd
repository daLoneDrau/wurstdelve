## Adventurer status conditions (Rules Reference, "Condition list").
## Each condition is one bit. An adventurer holds three FlagSets of these, one per
## sheet zone (see Duration), and a condition appears at most once across the three.
## Stacking, cancelling and lengthening rules belong in a system, not here.
class_name ConditionTags


enum Tag {
	SLIMED      = 1 << 0,   # -1 AGI
	POISONED    = 1 << 1,   # -1 CON
	EXALTED     = 1 << 2,   # +1 MAG
	SUPPRESSED  = 1 << 3,   # -1 MAG
	BLESSED     = 1 << 4,   # +1 MRL
	DEMORALIZED = 1 << 5,   # -1 MRL
	FOCUSED     = 1 << 6,   # +1 PER
	BLINDED     = 1 << 7,   # -1 PER
	INVIGORATED = 1 << 8,   # +1 STR
	WEAKENED    = 1 << 9,   # -1 STR
	FATIGUED    = 1 << 10,  # cannot Force March
	DETAINED    = 1 << 11,  # must Rest, cannot travel
	INFECTED    = 1 << 12,  # no Wounds recovered
	STUNNED     = 1 << 13,  # roll no Power dice
}

## The three durations on an adventurer's sheet. (UntilNextTurn exists only for monsters.)
enum Duration {
	FIGHT_ROUND,
	END_OF_FIGHT,
	RECOVERY,
}


## Returns the condition that cancels the given one when both would apply, or 0 if none.
static func opposite(tag: int) -> int:
	match tag:
		Tag.EXALTED:     return Tag.SUPPRESSED
		Tag.SUPPRESSED:  return Tag.EXALTED
		Tag.BLESSED:     return Tag.DEMORALIZED
		Tag.DEMORALIZED: return Tag.BLESSED
		Tag.FOCUSED:     return Tag.BLINDED
		Tag.BLINDED:     return Tag.FOCUSED
		Tag.INVIGORATED: return Tag.WEAKENED
		Tag.WEAKENED:    return Tag.INVIGORATED
		_:               return 0


## Returns every Tag value.
static func all_values() -> Array[int]:
	var out: Array[int] = []
	for v in Tag.values():
		out.append(int(v))
	return out


## Gets the Tag value for an enum key such as "POISONED" (case-insensitive).
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
