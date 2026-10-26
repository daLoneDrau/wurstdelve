class_name CampaignSelectScene
extends Scene

## Campaign Select: the player picks a mission from a row of cards (the missions together form
## the campaign) and sees its start, Bounty Level, Doom and objective before committing.
## Back returns to Title. Begin Mission remembers the choice on the engine and goes on to Party
## Setup. The cards are built from the mission records, in their `order`.
##
## Keys: Left and Right move the selection, Enter begins the mission, Escape goes back.
## Clicking a card selects it.

const TITLE_KEY: String = "title"
const PARTY_SETUP_KEY: String = "party_setup"
const PARTY_SETUP_PATH: String = "res://game/scenes/party_setup/party_setup.tscn"

## The layout shows three cards. More missions need paging, which is not built yet.
const CARDS_PER_PAGE: int = 3
const DOOM_TRACK_MAX: int = 5
const UNKNOWN_TEXT: String = "TBD"

const CARD_SCENE: PackedScene = preload("res://game/scenes/campaign_select/campaign_card.tscn")

var _cards: Array[CampaignCard] = []
var _records: Array[Dictionary] = []
var _selected_index: int = 0

@onready var _tag_line_label: Label = %TagLineLabel
@onready var _card_row: HBoxContainer = %CardRow
@onready var _start_value: Label = %StartValue
@onready var _bounty_value: Label = %BountyValue
@onready var _doom_value: Label = %DoomValue
@onready var _objective_value: Label = %ObjectiveValue
@onready var _begin_button: ActionButton = %BeginButton


func _ready() -> void:
	_tag_line_label.text = TaglineService_auto.next()


func on_enter() -> void:
	register_action("Left", "previous")
	register_action("Right", "next")
	register_action("Enter", "begin")
	register_action("Escape", "back")
	_load_cards()
	_select(0)


func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return
	if not _game_engine.scene_stack.is_empty():
		return   # an overlay is open; keys belong to it
	match action.name:
		"previous": _move_selection(-1)
		"next": _move_selection(1)
		"begin": _begin_mission()
		"back": _go_back()


## Builds one card per mission record (up to CARDS_PER_PAGE), replacing any already shown.
func _load_cards() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	_records.clear()

	var assets: DDAssetsLibrary = (_game_engine as DDGameEngine).dd_assets()
	var ids: Array[String] = assets.get_mission_ids()
	if ids.size() > CARDS_PER_PAGE:
		push_warning(
				"CampaignSelectScene: %d missions loaded, only %d fit on screen (paging not built)"
						% [ids.size(), CARDS_PER_PAGE]
		)
	for i in mini(ids.size(), CARDS_PER_PAGE):
		var record: Dictionary = assets.get_mission_record(ids[i])
		var card: CampaignCard = CARD_SCENE.instantiate() as CampaignCard
		_card_row.add_child(card)
		card.show_mission(record)
		card.clicked.connect(_on_card_clicked)
		_cards.append(card)
		_records.append(record)


func _move_selection(step: int) -> void:
	if _cards.is_empty():
		return
	_select(posmod(_selected_index + step, _cards.size()))


func _select(index: int) -> void:
	_selected_index = index
	for i in _cards.size():
		_cards[i].selected = (i == _selected_index)
	_begin_button.disabled = _records.is_empty()
	_show_details(_records[_selected_index] if not _records.is_empty() else {})


func _on_card_clicked(card: CampaignCard) -> void:
	_select(_cards.find(card))


## Fills the bottom panel from the selected mission record.
func _show_details(record: Dictionary) -> void:
	if record.is_empty():
		_start_value.text = UNKNOWN_TEXT
		_bounty_value.text = UNKNOWN_TEXT
		_doom_value.text = UNKNOWN_TEXT
		_objective_value.text = "NO MISSIONS FOUND"
		return
	_start_value.text = _start_text(str(record.get("start", "")))
	_bounty_value.text = "LEVEL %d" % int(record["bounty"]) if record.has("bounty") else UNKNOWN_TEXT
	_doom_value.text = "%d / %d" % [int(record.get("doom", 0)), DOOM_TRACK_MAX]
	_objective_value.text = str(record.get("objective", "")).to_upper()


func _start_text(location_id: String) -> String:
	var map_service: MapService = (_game_engine as DDGameEngine).map_service
	if location_id.is_empty() or map_service == null or not map_service.has_space(location_id):
		return UNKNOWN_TEXT
	return map_service.name_of(location_id).to_upper()


func _begin_mission() -> void:
	if _records.is_empty():
		return
	(_game_engine as DDGameEngine).selected_mission_id = str(_records[_selected_index]["id"])
	if not ResourceLoader.exists(PARTY_SETUP_PATH):
		push_warning("CampaignSelectScene: Party Setup is not built yet (%s)" % PARTY_SETUP_PATH)
		return
	_game_engine.change_scene(PARTY_SETUP_KEY, PARTY_SETUP_PATH)


func _go_back() -> void:
	_game_engine.change_scene(TITLE_KEY)
