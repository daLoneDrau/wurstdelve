class_name CampaignCard
extends PanelContainer

## One mission card on Campaign Select: art, name, tag line and blurb. It only shows what it is
## given. The scene owns which card is selected and tells the card through `selected`.

## Emitted when the player clicks the card.
signal clicked(card: CampaignCard)

const FRAME_NORMAL: StringName = &"SnesSmallFrame"
const FRAME_SELECTED: StringName = &"SnesSmallFrameSelected"
const ART_PLACEHOLDER_TEXT: String = "MISSION ART · 294×210"

## The mission shown on this card (its record id).
var mission_id: String = ""

## True while this is the selected card. Set by the scene, not by the card.
var selected: bool = false:
	set(value):
		selected = value
		_sync_selected()

@onready var _art: TextureRect = %Art
@onready var _art_placeholder: Label = %ArtPlaceholder
@onready var _arrow: Label = %SelectionArrow
@onready var _name_label: Label = %NameLabel
@onready var _tag_label: Label = %TagLabel
@onready var _blurb_label: Label = %BlurbLabel


func _ready() -> void:
	_ignore_mouse_on_children(self)
	gui_input.connect(_on_gui_input)
	_sync_selected()


## Fills the card from a mission record (see DDAssetsLibrary.load_mission_records).
func show_mission(record: Dictionary) -> void:
	mission_id = str(record.get("id", ""))
	_name_label.text = str(record.get("name", "")).to_upper()
	_tag_label.text = _tag_text(record)
	_blurb_label.text = "\n".join(PackedStringArray(record.get("blurb", [])))
	var art_path: String = str(record.get("art", ""))
	var art: Texture2D = load(art_path) as Texture2D if not art_path.is_empty() else null
	_art.texture = art
	_art_placeholder.visible = art == null
	_art_placeholder.text = ART_PLACEHOLDER_TEXT


## "TAG · 1-4 ADVENTURERS", or just the adventurer range when there is no tag.
func _tag_text(record: Dictionary) -> String:
	var min_count: int = int(record.get("min_adventurers", 1))
	var max_count: int = int(record.get("max_adventurers", 4))
	var range_text: String = str(min_count)
	if min_count != max_count:
		range_text = "%d-%d" % [min_count, max_count]
	var noun: String = "ADVENTURER" if max_count == 1 else "ADVENTURERS"
	var parts: Array[String] = []
	var tag: String = str(record.get("tag", ""))
	if not tag.is_empty():
		parts.append(tag.to_upper())
	parts.append("%s %s" % [range_text, noun])
	return " · ".join(parts)


func _sync_selected() -> void:
	if _arrow == null:
		return   # not ready yet; _ready syncs again
	theme_type_variation = FRAME_SELECTED if selected else FRAME_NORMAL
	_arrow.visible = selected


func _on_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


## Children must not swallow the click, so the card itself receives it anywhere inside it.
func _ignore_mouse_on_children(node: Node) -> void:
	for child in node.get_children():
		var control := child as Control
		if control != null:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_on_children(child)
