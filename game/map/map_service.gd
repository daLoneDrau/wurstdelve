## The one way the rest of the game reads and changes the map.
##
## It is built once from the validated map document (DDAssetsLibrary.get_map_document) and owns
## the MapState. Authored data is indexed here at build time and never changes. Changing data
## lives in MapState, and this class is the only writer.
##
## Spaces and Territories are always named by id.
##
## Graph shape (see the Map Design Notes):
## - A Path or Road has one or two ends, and every end is a Location. It never touches another
##   Path or Road. A one-ended connector is a dead end.
## - A Location's neighbours are the connectors that end at it, plus the few Locations linked to
##   it directly.
## - A connector's neighbours are its ends.
##
## Not here yet: Lake and River Port travel, Void Travel, large counters, and the rules that
## move levels around (raising the Danger Level of a Town lowers its Town Level, and so on).
## Those belong to rules systems that call the setters below.
class_name MapService
extends RefCounted

## The highest Danger Level or Town Level.
const MAX_LEVEL: int = 6

## The changing data. Read it through this class, and connect to its signals to redraw a view.
var state: MapState = null

# --- authored data, indexed at build time and never changed ---
var _space_order: Array[String] = []
var _names: Dictionary[String, String] = {}
var _kinds: Dictionary[String, int] = {}
var _territory_of: Dictionary[String, String] = {}
## Locations only: whether the Location has its own Danger Level or Town Level.
var _own_level: Dictionary[String, bool] = {}
var _authored_traits: Dictionary[String, int] = {}
## Connectors only: the Location ids at the ends.
var _ends: Dictionary[String, Array] = {}
var _neighbors: Dictionary[String, Array] = {}

var _territory_order: Array[String] = []
var _territory_names: Dictionary[String, String] = {}
var _territory_regions: Dictionary[String, int] = {}
var _territory_traits: Dictionary[String, int] = {}
## theme colour names from the Rules Reference table
var _territory_colors: Dictionary[String, String] = {}


## Builds the service from a document that DDAssetsLibrary has already validated. Pass an
## existing MapState to resume from it, otherwise every level starts at 0 and no traits are added.
func _init(document: Dictionary, existing_state: MapState = null) -> void:
	for territory in document.get("territories", []):
		var tid: String = str(territory["id"])
		_territory_order.append(tid)
		_territory_names[tid] = str(territory["name"])
		_territory_regions[tid] = MapRegions.from_key(str(territory["region"]))
		_territory_traits[tid] = _mask_from_keys(territory.get("traits", []))
		_territory_colors[tid] = str(territory.get("theme_color", ""))

	for location in document.get("locations", []):
		var lid: String = str(location["id"])
		_register_space(lid, str(location["name"]), SpaceKind.Kind.LOCATION, str(location["territory"]))
		_own_level[lid] = bool(location.get("own_level", false))
		_authored_traits[lid] = _mask_from_keys(location.get("traits", []))
		_neighbors[lid] = []

	for connector in document.get("connectors", []):
		var cid: String = str(connector["id"])
		var kind: int = SpaceKind.from_key(str(connector["kind"]))
		_register_space(cid, cid, kind, str(connector["territory"]))
		_own_level[cid] = false
		_authored_traits[cid] = 0
		var ends: Array[String] = []
		for end_id in connector["ends"]:
			ends.append(str(end_id))
			_neighbors[str(end_id)].append(cid)
		_ends[cid] = ends
		_neighbors[cid] = ends.duplicate()

	for link in document.get("links", []):
		var a: String = str(link[0])
		var b: String = str(link[1])
		_neighbors[a].append(b)
		_neighbors[b].append(a)

	state = existing_state if existing_state != null else MapState.new()
	for sid in _space_order:
		if not state.spaces.has(sid):
			state.spaces[sid] = SpaceState.new()
	for tid in _territory_order:
		if not state.territories.has(tid):
			state.territories[tid] = TerritoryState.new()


func _register_space(id: String, display_name: String, kind: int, territory_id: String) -> void:
	_space_order.append(id)
	_names[id] = display_name
	_kinds[id] = kind
	_territory_of[id] = territory_id


func _mask_from_keys(keys: Array) -> int:
	var mask: int = 0
	for key in keys:
		mask |= SpaceTags.from_key(str(key))
	return mask


## —————————————————————————————————————————————
#region Structure (never changes)
## —————————————————————————————————————————————

func has_space(space_id: String) -> bool:
	return _kinds.has(space_id)


func has_territory(territory_id: String) -> bool:
	return _territory_names.has(territory_id)


## Every space id, Locations first, then connectors, in record order.
func space_ids() -> Array[String]:
	return _space_order.duplicate()


func location_ids() -> Array[String]:
	return _ids_where(func(id: String) -> bool: return _kinds[id] == SpaceKind.Kind.LOCATION)


## Every Path and Road id.
func connector_ids() -> Array[String]:
	return _ids_where(func(id: String) -> bool: return SpaceKind.is_connector(_kinds[id]))


func territory_ids() -> Array[String]:
	return _territory_order.duplicate()


## The display name. A Path or Road has no printed name, so its id is returned.
func name_of(space_id: String) -> String:
	return _names.get(space_id, "")


## A SpaceKind.Kind value, or -1 for an unknown id.
func kind_of(space_id: String) -> int:
	return _kinds.get(space_id, -1)


func is_location(space_id: String) -> bool:
	return kind_of(space_id) == SpaceKind.Kind.LOCATION


func is_connector(space_id: String) -> bool:
	return SpaceKind.is_connector(kind_of(space_id))


## The id of the Territory a space is in. Every space is in exactly one.
func territory_of(space_id: String) -> String:
	return _territory_of.get(space_id, "")


## A MapRegions.Region value, or -1 for an unknown id. A space's Region is its Territory's.
func region_of(space_id: String) -> int:
	return _territory_regions.get(territory_of(space_id), -1)


func territory_name(territory_id: String) -> String:
	return _territory_names.get(territory_id, "")


func territory_region(territory_id: String) -> int:
	return _territory_regions.get(territory_id, -1)


func territory_theme_color(territory_id: String) -> String:
	return _territory_colors.get(territory_id, "")


## The Location ids at the ends of a Path or Road (one or two). Empty for a Location.
func ends_of(connector_id: String) -> Array[String]:
	return _as_strings(_ends.get(connector_id, []))


## True for a Path or Road with only one end.
func is_dead_end(connector_id: String) -> bool:
	return _ends.has(connector_id) and _ends[connector_id].size() == 1


## The spaces next to this one. For a Location: its Paths and Roads, then the Locations linked to
## it directly. For a Path or Road: its end Locations.
func neighbors(space_id: String) -> Array[String]:
	return _as_strings(_neighbors.get(space_id, []))


## The Paths and Roads that end at a Location.
func connectors_at(location_id: String) -> Array[String]:
	var out: Array[String] = []
	for n in _neighbors.get(location_id, []):
		if is_connector(n):
			out.append(n)
	return out

#endregion


## —————————————————————————————————————————————
#region Traits
## —————————————————————————————————————————————

## The traits printed on the space itself: a Location's own traits. A Path or Road prints none.
func authored_traits(space_id: String) -> int:
	return _authored_traits.get(space_id, 0)


## The traits of a Territory.
func territory_traits(territory_id: String) -> int:
	return _territory_traits.get(territory_id, 0)


## The traits added during play (SpaceTags bits).
func added_traits(space_id: String) -> int:
	if not state.spaces.has(space_id):
		return 0
	return state.spaces[space_id].added_traits.get_mask()


## Every trait the space has right now: its own, its Territory's if it is a Path or Road (a
## Location does not share its Territory's traits), the added traits, and the derived ones.
## Derived: Town (a Settlement with Town Level 1 or more) and Perilous (the Hand of Doom is here).
func effective_traits(space_id: String) -> int:
	if not has_space(space_id):
		return 0
	var mask: int = authored_traits(space_id) | added_traits(space_id)
	if is_connector(space_id):
		mask |= territory_traits(territory_of(space_id))
	if (mask & SpaceTags.Tag.SETTLEMENT) != 0 and town_level(space_id) >= 1:
		mask |= SpaceTags.Tag.TOWN
	if state.hand_of_doom_space == space_id:
		mask |= SpaceTags.Tag.PERILOUS
	return mask


## True if the space currently has the trait. Pass one SpaceTags.Tag.
func has_trait(space_id: String, tag: int) -> bool:
	return (effective_traits(space_id) & tag) != 0


## Adds a trait during play. Returns false for an unknown space, a value that is not exactly one
## trait, or a derived-only trait.
func add_trait(space_id: String, tag: int) -> bool:
	if not _can_change_trait(space_id, tag):
		return false
	var traits: FlagSet = state.spaces[space_id].added_traits
	if (traits.get_mask() & tag) == 0:
		traits.add(tag)
		state.space_changed.emit(space_id, &"added_traits")
	return true


## Removes an added trait. It cannot remove an authored trait. Returns false as add_trait does.
func remove_trait(space_id: String, tag: int) -> bool:
	if not _can_change_trait(space_id, tag):
		return false
	var traits: FlagSet = state.spaces[space_id].added_traits
	if (traits.get_mask() & tag) != 0:
		traits.remove(tag)
		state.space_changed.emit(space_id, &"added_traits")
	return true


func _can_change_trait(space_id: String, tag: int) -> bool:
	if not has_space(space_id):
		push_error("MapService: unknown space '%s'." % space_id)
		return false
	if not SpaceTags.is_single_tag(tag):
		push_error("MapService: %d is not exactly one SpaceTags value." % tag)
		return false
	if (tag & SpaceTags.DERIVED_ONLY) != 0:
		push_error("MapService: %s is derived, never added." % SpaceTags.to_key(tag))
		return false
	return true

#endregion


## —————————————————————————————————————————————
#region Danger Level and Town Level
## —————————————————————————————————————————————
## A level of 0 means none. A space has a Danger Level or a Town Level, never both. Levels start
## at 0 until a mission sets them.

## True if the space is a Location with its own Danger Level or Town Level. Every other space
## shares its Territory's Danger Level.
func has_own_level(space_id: String) -> bool:
	return _own_level.get(space_id, false)


## The id whose level counts for this space: the space itself if it has its own level, otherwise
## its Territory. Changing the level of a space without its own level changes the Territory.
func level_holder(space_id: String) -> String:
	if not has_space(space_id):
		return ""
	return space_id if has_own_level(space_id) else territory_of(space_id)


## True if the level of this space is held by its Territory.
func level_is_territory(space_id: String) -> bool:
	return has_space(space_id) and not has_own_level(space_id)


## The Danger Level that applies to the space, or 0 if it has none (a Town).
func danger_level(space_id: String) -> int:
	if not has_space(space_id):
		return 0
	if has_own_level(space_id):
		return state.spaces[space_id].danger_level
	return state.territories[territory_of(space_id)].danger_level


## The Town Level of a Settlement with its own level, or 0.
func town_level(space_id: String) -> int:
	if not has_own_level(space_id):
		return 0
	return state.spaces[space_id].town_level


## Sets the Danger Level that applies to the space (0 to 6). For a space without its own level
## that sets its Territory's level. Returns false, and changes nothing, for an unknown space, a
## level out of range, or a Location that currently has a Town Level.
func set_danger_level(space_id: String, level: int) -> bool:
	if not has_space(space_id):
		push_error("MapService: unknown space '%s'." % space_id)
		return false
	if level < 0 or level > MAX_LEVEL:
		push_error("MapService: Danger Level %d is outside 0 to %d." % [level, MAX_LEVEL])
		return false
	if has_own_level(space_id):
		var space: SpaceState = state.spaces[space_id]
		if level > 0 and space.town_level > 0:
			push_error("MapService: %s has a Town Level, so it cannot have a Danger Level." % space_id)
			return false
		if space.danger_level != level:
			space.danger_level = level
			state.space_changed.emit(space_id, &"danger_level")
	else:
		var territory_id: String = territory_of(space_id)
		var territory: TerritoryState = state.territories[territory_id]
		if territory.danger_level != level:
			territory.danger_level = level
			state.territory_changed.emit(territory_id, &"danger_level")
	return true


## Sets the Town Level (0 to 6) of a Settlement that has its own level. Returns false, and
## changes nothing, for anything else, a level out of range, or a Settlement that currently has
## a Danger Level.
func set_town_level(space_id: String, level: int) -> bool:
	if not has_own_level(space_id):
		push_error("MapService: '%s' has no level of its own." % space_id)
		return false
	if ((authored_traits(space_id) | added_traits(space_id)) & SpaceTags.Tag.SETTLEMENT) == 0:
		push_error("MapService: only a Settlement can have a Town Level (%s)." % space_id)
		return false
	if level < 0 or level > MAX_LEVEL:
		push_error("MapService: Town Level %d is outside 0 to %d." % [level, MAX_LEVEL])
		return false
	var space: SpaceState = state.spaces[space_id]
	if level > 0 and space.danger_level > 0:
		push_error("MapService: %s has a Danger Level, so it cannot have a Town Level." % space_id)
		return false
	if space.town_level != level:
		space.town_level = level
		state.space_changed.emit(space_id, &"town_level")
	return true

#endregion


## —————————————————————————————————————————————
#region Hand of Doom
## —————————————————————————————————————————————

## The space with the Hand of Doom counter, or "" if it is not on the board.
func hand_of_doom_space() -> String:
	return state.hand_of_doom_space


## Moves the Hand of Doom counter. Pass "" to take it off the board. Returns false for an unknown
## space.
func set_hand_of_doom_space(space_id: String) -> bool:
	if not space_id.is_empty() and not has_space(space_id):
		push_error("MapService: unknown space '%s'." % space_id)
		return false
	var old: String = state.hand_of_doom_space
	if old != space_id:
		state.hand_of_doom_space = space_id
		state.hand_of_doom_changed.emit(old, space_id)
	return true

#endregion


## —————————————————————————————————————————————
#region Travel
## —————————————————————————————————————————————

## Where Foot Travel can go from a space: its neighbours, except Destroyed spaces. Detained and
## the other conditions that stop travel are not checked here.
func foot_travel_targets(from_id: String) -> Array[String]:
	var out: Array[String] = []
	for n in _neighbors.get(from_id, []):
		if not has_trait(n, SpaceTags.Tag.DESTROYED):
			out.append(n)
	return out


## The Location on the far side of a Force March, or "" if it is not legal. From a Location, a
## Force March goes through a Road, or through a Path that has the Explored trait, to the
## Location at its other end. It cannot go through a dead end or a Destroyed space. Stance,
## Fatigue and Epic Monster counters are not checked here.
func force_march_destination(from_id: String, via_id: String) -> String:
	if not is_location(from_id) or not is_connector(via_id):
		return ""
	var ends: Array = _ends.get(via_id, [])
	if ends.size() != 2 or not ends.has(from_id):
		return ""
	if kind_of(via_id) == SpaceKind.Kind.PATH and not has_trait(via_id, SpaceTags.Tag.EXPLORED):
		return ""
	var far: String = str(ends[1] if str(ends[0]) == from_id else ends[0])
	if far == from_id:
		return ""
	if has_trait(via_id, SpaceTags.Tag.DESTROYED) or has_trait(far, SpaceTags.Tag.DESTROYED):
		return ""
	return far


## Every legal Force March from a Location, as { connector id: far Location id }.
func force_march_routes(from_id: String) -> Dictionary:
	var routes: Dictionary = {}
	for via_id in connectors_at(from_id):
		var far: String = force_march_destination(from_id, via_id)
		if not far.is_empty():
			routes[via_id] = far
	return routes

#endregion


func _ids_where(predicate: Callable) -> Array[String]:
	var out: Array[String] = []
	for id in _space_order:
		if predicate.call(id):
			out.append(id)
	return out


func _as_strings(values: Array) -> Array[String]:
	var out: Array[String] = []
	for v in values:
		out.append(str(v))
	return out
