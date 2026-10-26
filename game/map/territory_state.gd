## The changing data of one Territory. Authored data (name, Region, traits) lives in the map
## records.
##
## Only MapService writes to this.
class_name TerritoryState
extends Resource

## The Danger Level shared by every Path, Road and Location in the Territory that has no level
## of its own, 1 to 6, or 0 until a mission sets it.
@export var danger_level: int = 0
