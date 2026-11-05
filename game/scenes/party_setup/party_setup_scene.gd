class_name PartySetupScene
extends Scene

## Party Setup: the player builds the party from the adventurer list. A strip of party slots sits
## on top and the list runs down the left. On the right are the selected adventurer's details
## (stage, classes, HP, attributes, Luck), the starting kit and suggested skills, and a bottom row
## with the Weaknesses panel (layout only for now) and the party buttons. Back returns to Campaign
## Select and clears the party,
## since a party is picked for one mission. Confirm Party creates the adventurer entities and
## goes on to the Map.
##
## While browsing, the scene holds only the chosen adventurer ids. Entities are created once, on
## Confirm. The party size limits come from the selected mission (`min_adventurers` and
## `max_adventurers`, default 1 to 4). The list shows the authored adventurers sorted by name,
## then dimmed placeholders up to the full roster of 52.
##
## Keys: Up and Down move the selection, Left and Right change page, Enter adds or removes the
## selected adventurer, C confirms the party, Escape goes back. Clicking a row selects it and
## clicking a filled party slot selects its adventurer.

const CAMPAIGN_SELECT_KEY: String = "campaign_select"
const CAMPAIGN_SELECT_PATH: String = "res://game/scenes/campaign_select/campaign_select.tscn"
const MAP_KEY: String = "map"
const MAP_PATH: String = "res://game/scenes/map/map.tscn"

const SLOT_SCENE: PackedScene = preload("res://game/scenes/party_setup/party_slot.tscn")

## The whole roster of the finished game; the list pages through all of it.
const ROSTER_SIZE: int = 52
const ROWS_PER_PAGE: int = 12
const SLOT_COUNT: int = 4
const DEFAULT_MIN_PARTY: int = 1
const NONE_TEXT: String = "NONE"
const ADD_TEXT: String = "ADD TO PARTY"
const REMOVE_TEXT: String = "REMOVE"
const ATTRIBUTE_KEYS: Array[String] = ["agi", "con", "mag", "mrl", "per", "str"]
## The most rows a kit column shows (starting skills, starting items, suggested skills).
const MAX_KIT_ROWS: int = 3
const TEXT_COLOR: Color = Color(0.94, 0.93, 0.98, 1.0)
const DIM_COLOR: Color = Color(0.45, 0.47, 0.58, 1.0)
const GOLD_COLOR: Color = Color(0.97, 0.83, 0.42, 1.0)
const PIP_SIZE: Vector2 = Vector2(10, 10)
## The card's slot word, as shown beside an Item in the starting kit.
const SLOT_TEXT: Dictionary = {
	"body": "BODY", "gauntlet": "GAUNTLET", "head": "HEAD", "jewelry": "JEWELRY",
	"1h": "1H", "lh": "LH", "2h": "2H",
	}

## The authored adventurer records, sorted by name.
var _records: Array[Dictionary] = []
var _rows: Array[AdventurerRow] = []
var _slots: Array[PartySlot] = []
## The record ids in the party, in the order they were added.
var _party: Array[String] = []
var _page: int = 0
## Index into `_records` of the selected adventurer, or -1 when there are none.
var _selected_index: int = -1
var _min_party: int = DEFAULT_MIN_PARTY
var _max_party: int = SLOT_COUNT
## The model path now on the stage ("" for none, "<unset>" before the first), so the same model
## is not reloaded.
var _shown_model_path: String = "<unset>"

@onready var _party_title_label: Label = %PartyTitleLabel
@onready var _tag_line_label: Label = %TagLineLabel
@onready var _slot_row: HBoxContainer = %SlotRow
@onready var _list_title_label: Label = %ListTitleLabel
@onready var _row_list: VBoxContainer = %RowList
@onready var _prev_button: ArrowButton = %PrevButton
@onready var _next_button: ArrowButton = %NextButton
@onready var _page_label: Label = %PageLabel
@onready var _details_title_label: Label = %DetailsTitleLabel
@onready var _stage_view: SubViewportContainer = %StageView
@onready var _stage_viewport: SubViewport = %StageViewport
@onready var _stage_camera: Camera3D = %StageCamera
@onready var _model_anchor: Node3D = %ModelAnchor
@onready var _stage_placeholder: Label = %StagePlaceholder
@onready var _classes_label: Label = %ClassesLabel
@onready var _hp_label: Label = %HpLabel
@onready var _attribute_values: Dictionary = {
	"agi": %AgiValue, "con": %ConValue, "mag": %MagValue,
	"mrl": %MrlValue, "per": %PerValue, "str": %StrValue,
	}
@onready var _luck_pips: HBoxContainer = %LuckPips
@onready var _luck_count_label: Label = %LuckCountLabel
@onready var _luck_rule_label: Label = %LuckRuleLabel
@onready var _skills_grid: GridContainer = %SkillsGrid
@onready var _items_grid: GridContainer = %ItemsGrid
@onready var _suggested_skills_grid: GridContainer = %SuggestedSkillsGrid
@onready var _suggested_weakness_label: Label = %SuggestedWeaknessLabel
@onready var _add_button: ArrowButton = %AddButton
@onready var _confirm_button: ArrowButton = %ConfirmButton


func _ready() -> void:
	_tag_line_label.text = TaglineService_auto.next()


func on_enter() -> void:
	register_action("Up", "up")
	register_action("Down", "down")
	register_action("Left", "previous_page")
	register_action("Right", "next_page")
	register_action("Enter", "toggle")
	register_action("C", "confirm")
	register_action("Escape", "back")
	_load_mission_limits()
	_load_records()
	_build_rows()
	_build_slots()
	_restore_party()
	_select(0 if not _records.is_empty() else -1)


func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return
	if not _game_engine.scene_stack.is_empty():
		return   # an overlay is open; keys belong to it
	match action.name:
		"up": _move_selection(-1)
		"down": _move_selection(1)
		"previous_page": _change_page(-1)
		"next_page": _change_page(1)
		"toggle": _toggle_selected()
		"confirm": _confirm_party()
		"back": _go_back()


func _dd_engine() -> DDGameEngine:
	return _game_engine as DDGameEngine


## Reads the party size limits from the selected mission.
func _load_mission_limits() -> void:
	var engine: DDGameEngine = _dd_engine()
	var mission: Dictionary = engine.dd_assets().get_mission_record(
			engine.selected_mission_id, false
	)
	_min_party = clampi(int(mission.get("min_adventurers", DEFAULT_MIN_PARTY)), 1, SLOT_COUNT)
	_max_party = clampi(int(mission.get("max_adventurers", SLOT_COUNT)), _min_party, SLOT_COUNT)


func _load_records() -> void:
	_records.clear()
	var assets: DDAssetsLibrary = _dd_engine().dd_assets()
	for id in assets.get_adventurer_ids():
		_records.append(assets.get_adventurer_record(id))
	_records.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]) < str(b["name"])
	)


## Builds the list rows once. They are refilled whenever the page changes.
func _build_rows() -> void:
	for row in _rows:
		row.queue_free()
	_rows.clear()
	for i in ROWS_PER_PAGE:
		var row := AdventurerRow.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.pressed.connect(_on_row_pressed.bind(row))
		_row_list.add_child(row)
		_rows.append(row)


## Builds one slot per place in the strip. Slots beyond the mission's maximum are hidden.
func _build_slots() -> void:
	for slot in _slots:
		slot.queue_free()
	_slots.clear()
	for i in SLOT_COUNT:
		var slot: PartySlot = SLOT_SCENE.instantiate() as PartySlot
		_slot_row.add_child(slot)
		slot.visible = i < _max_party
		slot.clicked.connect(_on_slot_clicked)
		slot.remove_requested.connect(_on_slot_remove_requested)
		_slots.append(slot)


## Brings back the party confirmed on an earlier visit (such as returning from the Map). Back
## clears it, so a visit that came from Campaign Select starts with an empty party.
func _restore_party() -> void:
	_party.clear()
	for id in _dd_engine().party_ids:
		if _record_index(id) >= 0 and _party.size() < _max_party:
			_party.append(id)


# ---------------------------------------------------------------------------------------------
# selection and paging

func _record_index(id: String) -> int:
	for i in _records.size():
		if str(_records[i]["id"]) == id:
			return i
	return -1


func _page_count() -> int:
	return ceili(maxf(ROSTER_SIZE, _records.size()) / float(ROWS_PER_PAGE))


func _selected_id() -> String:
	return str(_records[_selected_index]["id"]) if _selected_index >= 0 else ""


## Selects an authored adventurer by index and shows the page it is on.
func _select(index: int) -> void:
	_selected_index = index
	if index >= 0:
		_page = floori(index / float(ROWS_PER_PAGE))
	_refresh()


func _move_selection(step: int) -> void:
	if _records.is_empty():
		return
	_select(posmod(maxi(_selected_index, 0) + step, _records.size()))


## Shows the previous or next page. On a page with authored adventurers, the first of them is
## selected. A page with none (the rest of the roster) leaves the selection where it was.
func _change_page(step: int) -> void:
	var new_page: int = clampi(_page + step, 0, _page_count() - 1)
	if new_page == _page:
		return
	_page = new_page
	var first_index: int = _page * ROWS_PER_PAGE
	if first_index < _records.size():
		_selected_index = first_index
	_refresh()


func _on_row_pressed(row: AdventurerRow) -> void:
	var index: int = _record_index(row.adventurer_id)
	if index >= 0:
		_select(index)


func _on_slot_clicked(slot: PartySlot) -> void:
	var index: int = _record_index(slot.adventurer_id)
	if index >= 0:
		_select(index)


# ---------------------------------------------------------------------------------------------
# the party

func _toggle_selected() -> void:
	var id: String = _selected_id()
	if id.is_empty():
		return
	if _party.has(id):
		_party.erase(id)
	elif _party.size() < _max_party:
		_party.append(id)
	_refresh()


func _on_slot_remove_requested(slot: PartySlot) -> void:
	_party.erase(slot.adventurer_id)
	_refresh()


## Creates the adventurer entities for the party and goes on to the Map. An adventurer already
## created on an earlier Confirm is kept, and one no longer in the party is removed.
func _confirm_party() -> void:
	if _party.size() < _min_party or _party.size() > _max_party:
		return
	var engine: DDGameEngine = _dd_engine()
	var manager: DDEntityManager = engine.entity_manager as DDEntityManager
	if manager == null:
		push_error("PartySetupScene: GameEngine has no entity manager")
		return
	for entity in manager.get_entities_by_tag(EntityTags.Tag.PC):
		var id: String = entity.id.trim_prefix("adv_")
		if not _party.has(id):
			manager.remove_entity(entity.id)
	for id in _party:
		if manager.get_entity_by_id("adv_%s" % id) == null:
			manager.create_adventurer(engine.dd_assets().get_adventurer_record(id), true)
	engine.party_ids = _party.duplicate()
	if not ResourceLoader.exists(MAP_PATH):
		push_warning("PartySetupScene: the Map is not built yet (%s)" % MAP_PATH)
		return
	engine.change_scene(MAP_KEY, MAP_PATH)


## Forgets the party: the picks here, the ids kept on the engine, and any adventurer entities
## that an earlier Confirm created.
func _clear_party() -> void:
	_party.clear()
	var engine: DDGameEngine = _dd_engine()
	engine.party_ids.clear()
	var manager: DDEntityManager = engine.entity_manager as DDEntityManager
	if manager == null:
		return
	for entity in manager.get_entities_by_tag(EntityTags.Tag.PC):
		manager.remove_entity(entity.id)


func _go_back() -> void:
	_clear_party()
	_game_engine.change_scene(CAMPAIGN_SELECT_KEY, CAMPAIGN_SELECT_PATH)


# ---------------------------------------------------------------------------------------------
# showing the state

## Redraws everything from the current party, page and selection.
func _refresh() -> void:
	_party_title_label.text = "PARTY · %d OF %d · MIN %d" % [_party.size(), _max_party, _min_party]
	var selected_id: String = _selected_id()

	for i in _slots.size():
		if i < _party.size():
			_slots[i].show_adventurer(i + 1, _records[_record_index(_party[i])])
			_slots[i].highlighted = _party[i] == selected_id
		else:
			_slots[i].show_empty(i + 1)

	var first_number: int = _page * ROWS_PER_PAGE + 1
	var last_number: int = mini(first_number + ROWS_PER_PAGE - 1, maxi(ROSTER_SIZE, _records.size()))
	_list_title_label.text = "ADVENTURERS %d-%d OF %d" % [
		first_number, last_number, maxi(ROSTER_SIZE, _records.size())
	]
	for i in _rows.size():
		var index: int = _page * ROWS_PER_PAGE + i
		var row: AdventurerRow = _rows[i]
		if index < _records.size():
			row.show_adventurer(index + 1, _records[index])
			row.selected = index == _selected_index
			row.in_party = _party.has(str(_records[index]["id"]))
		else:
			row.show_placeholder(index + 1)
	_page_label.text = "%d/%d" % [_page + 1, _page_count()]
	_prev_button.disabled = _page <= 0
	_next_button.disabled = _page >= _page_count() - 1

	_show_details(_records[_selected_index] if _selected_index >= 0 else {})

	var in_party: bool = _party.has(selected_id)
	_add_button.text = REMOVE_TEXT if in_party else ADD_TEXT
	_add_button.disabled = selected_id.is_empty() or (not in_party and _party.size() >= _max_party)
	_confirm_button.disabled = _party.size() < _min_party


## Fills the details and kit panels from an adventurer record (an empty one clears them).
func _show_details(record: Dictionary) -> void:
	_show_model(str(record.get("model", "")))
	if record.is_empty():
		_details_title_label.text = "NO ADVENTURER"
		_classes_label.text = ""
		_hp_label.text = ""
		for key in ATTRIBUTE_KEYS:
			(_attribute_values[key] as Label).text = ""
		_show_luck(0, 0)
		_luck_rule_label.text = ""
		_fill_grid(_skills_grid, [])
		_fill_grid(_items_grid, [])
		_fill_grid(_suggested_skills_grid, [])
		_suggested_weakness_label.text = NONE_TEXT
		return
	var attributes: Dictionary = record["attributes"]
	_details_title_label.text = str(record["name"]).to_upper()
	_classes_label.text = " · ".join(PackedStringArray(record["classes"]))
	# HP is double CON; a new adventurer has no Wounds
	var hp: int = 2 * int(attributes["con"])
	_hp_label.text = "HP %d / %d" % [hp, hp]
	for key in ATTRIBUTE_KEYS:
		(_attribute_values[key] as Label).text = str(int(attributes[key]))
	# Luck can never exceed MAG, so MAG is the number of places
	_show_luck(int(record.get("luck", 0)), int(attributes["mag"]))
	_luck_rule_label.text = str(record.get("luck_rule", "")).to_upper()
	_fill_grid(_skills_grid, _kit_entries(record.get("skills", []), false))
	_fill_grid(_items_grid, _kit_entries(record.get("starting_items", []), true))
	_fill_grid(_suggested_skills_grid, _kit_entries(record.get("suggested_skills", []), false))
	_suggested_weakness_label.text = _names_text(record.get("suggested_weaknesses", []))


## Draws one pip per place of Luck (up to MAG), the filled ones first, and the "n / max" count.
func _show_luck(luck: int, max_luck: int) -> void:
	for pip in _luck_pips.get_children():
		_luck_pips.remove_child(pip)
		pip.queue_free()
	for i in max_luck:
		var pip := ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE
		pip.color = GOLD_COLOR if i < luck else DIM_COLOR
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_luck_pips.add_child(pip)
	_luck_count_label.text = "%d / %d" % [luck, max_luck] if max_luck > 0 else ""


## Shows the adventurer's 3D model on the stage, or the placeholder text if it has none. The
## stage renders only while there is a model. A model may carry its own Camera3D (the first one
## found is used, with the stage's environment) to frame itself. Otherwise the default view is
## used, which suits a model about 2 units tall standing at the origin.
func _show_model(path: String) -> void:
	if path == _shown_model_path:
		return
	_shown_model_path = path
	for child in _model_anchor.get_children():
		child.queue_free()
	var packed: PackedScene = load(path) as PackedScene if not path.is_empty() else null
	var model: Node3D = packed.instantiate() as Node3D if packed != null else null
	_stage_camera.make_current()
	if model != null:
		_model_anchor.add_child(model)
		var cameras: Array[Node] = model.find_children("*", "Camera3D", true, false)
		if not cameras.is_empty():
			var camera: Camera3D = cameras[0] as Camera3D
			if camera.environment == null:
				camera.environment = _stage_camera.environment
			camera.make_current()
	_stage_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if model != null else SubViewport.UPDATE_DISABLED
	)
	_stage_view.visible = model != null
	_stage_placeholder.visible = model == null


## The display name for an id. Items use their record's name when there is one. Skills and
## Weaknesses have no definitions yet, so their names are made from the ids.
func _display_name(id: String, are_item: bool) -> String:
	var display: String = id.replace("_", " ")
	var assets: DDAssetsLibrary = _dd_engine().dd_assets()
	if are_item and assets.has_item_record(id):
		display = str(assets.get_item_record(id).get("name", display))
	return display.to_upper()


## One name per line, or NONE. Used for Weaknesses.
func _names_text(ids: Array) -> String:
	if ids.is_empty():
		return NONE_TEXT
	var names: PackedStringArray = PackedStringArray()
	for id in ids:
		names.append(_display_name(str(id), false))
	return "\n".join(names)


## The rows for one kit column: [name, detail] pairs. Skills have no definitions yet, so their
## detail is empty. An Item's detail comes from its record (its slot, and WEAPON if it attacks).
func _kit_entries(ids: Array, are_items: bool) -> Array:
	var entries: Array = []
	var assets: DDAssetsLibrary = _dd_engine().dd_assets()
	for id in ids:
		var detail: String = ""
		if are_items and assets.has_item_record(str(id)):
			var record: Dictionary = assets.get_item_record(str(id))
			var slot_text: String = str(SLOT_TEXT.get(str(record.get("slot", "")), ""))
			var weapon_text: String = "WEAPON" if record.has("attack_types") else ""
			detail = " ".join(PackedStringArray([slot_text, weapon_text])).strip_edges()
		entries.append([_display_name(str(id), are_items), detail])
	return entries


## Rebuilds a kit column's rows: a name that clips if it is long, and a dim detail beside it.
func _fill_grid(grid: GridContainer, entries: Array) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	if entries.is_empty():
		entries = [[NONE_TEXT, ""]]
	for i in mini(entries.size(), MAX_KIT_ROWS):
		var name_label := Label.new()
		name_label.text = str(entries[i][0])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_color_override("font_color", TEXT_COLOR)
		grid.add_child(name_label)
		var detail_label := Label.new()
		detail_label.text = str(entries[i][1])
		detail_label.add_theme_color_override("font_color", DIM_COLOR)
		grid.add_child(detail_label)
