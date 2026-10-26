## All the changing data of the map, in one Resource: a SpaceState for every space, a
## TerritoryState for every Territory, and where the Hand of Doom is.
##
## It holds no authored data. Read it, and write it, only through MapService, which keeps the
## rules (Danger Level and Town Level exclusive, traits layered) in one place and emits the
## signals below after a change, so a view can redraw just what moved.
class_name MapState
extends Resource

## A field of a space changed. field is &"added_traits", &"danger_level" or &"town_level".
signal space_changed(space_id: String, field: StringName)

## A field of a Territory changed. field is &"danger_level".
signal territory_changed(territory_id: String, field: StringName)

## The Hand of Doom moved. An empty id means it is not on the board.
signal hand_of_doom_changed(old_space_id: String, new_space_id: String)

## space id -> its changing data
@export var spaces: Dictionary[String, SpaceState] = {}

## Territory id -> its changing data
@export var territories: Dictionary[String, TerritoryState] = {}

## The space holding the Hand of Doom counter, or "" if it is not on the board. A space with the
## Hand is Perilous.
@export var hand_of_doom_space: String = ""
