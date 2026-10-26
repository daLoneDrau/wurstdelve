## The changing data of one space (Location, Path or Road). Authored data lives in the map
## records and is never copied here.
##
## Only MapService writes to this. Everything else reads through MapService, which also works
## out the effective values.
class_name SpaceState
extends Resource

## Traits added during play by cards and missions, such as Explored or Destroyed.
## Never holds a derived-only trait (SpaceTags.DERIVED_ONLY).
@export var added_traits: FlagSet = FlagSet.new()

## The space's own Danger Level, 1 to 6, or 0 for none. Used only by a Location with its own
## level. Any other space shares its Territory's Danger Level.
@export var danger_level: int = 0

## The space's own Town Level, 1 to 6, or 0 for none. Only a Settlement with its own level can
## have one. A space never has both a Danger Level and a Town Level.
@export var town_level: int = 0
