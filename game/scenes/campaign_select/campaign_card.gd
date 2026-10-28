class_name CampaignCard
extends PanelContainer

## One mission card on Campaign Select: 3D diorama, name, tag line and blurb. It only shows
## what it is given. The scene owns which card is selected and tells the card through `selected`.

## Emitted when the player clicks the card.
signal clicked(card: CampaignCard)

const FRAME_NORMAL: StringName = &"SnesSmallFrame"
const FRAME_SELECTED: StringName = &"SnesSmallFrameSelected"
const ART_PLACEHOLDER_TEXT: String = "MISSION DIORAMA · 294×210"
const LOCKED_TINT: Color = Color(0.5, 0.5, 0.55, 1.0)

## The mission shown on this card (its record id).
var mission_id: String = ""

## False for a mission that cannot be chosen yet (the record's `available` field). The card is
## dimmed, shows no hand cursor, and never reports a click.
var available: bool = true

## True while this is the selected card. Set by the scene, not by the card.
var selected: bool = false:
	set(value):
		selected = value
		_sync_selected()

@onready var _model_stage: SubViewportContainer = %ModelStage
@onready var _viewport: SubViewport = %SubViewport
@onready var _default_camera: Camera3D = %Camera3D
@onready var _model_anchor: Node3D = %ModelAnchor
@onready var _art_placeholder: Label = %ArtPlaceholder
@onready var _arrow: TextureRect = %SelectionArrow
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
	available = bool(record.get("available", true))
	_sync_available()
	_name_label.text = str(record.get("name", "")).to_upper()
	_tag_label.text = _tag_text(record)
	_blurb_label.text = "\n".join(PackedStringArray(record.get("blurb", [])))
	_art_placeholder.text = ART_PLACEHOLDER_TEXT
	_show_diorama(str(record.get("diorama", "")))


## Shows the mission's 3D diorama in the art frame, or the placeholder text if it has none.
## The diorama renders in its own SubViewport, and only while there is one to render.
## A diorama frames itself: put a Camera3D in the diorama scene and it is used instead of the
## card's default view. Without one, the default view is used.
func _show_diorama(path: String) -> void:
	for child in _model_anchor.get_children():
		child.queue_free()
	var packed: PackedScene = load(path) as PackedScene if not path.is_empty() else null
	var model: Node3D = packed.instantiate() as Node3D if packed != null else null
	_default_camera.make_current()
	if model != null:
		_model_anchor.add_child(model)
		_use_diorama_camera(model)
	_model_stage.visible = model != null
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if model != null else SubViewport.UPDATE_DISABLED
	)
	_art_placeholder.visible = model == null


## Makes the diorama's own Camera3D (the first one found) the view, if it has one. The camera
## takes the card's environment when it has none, so the background and light match the card.
func _use_diorama_camera(model: Node) -> void:
	var cameras: Array[Node] = model.find_children("*", "Camera3D", true, false)
	if cameras.is_empty():
		return
	var camera: Camera3D = cameras[0] as Camera3D
	if camera.environment == null:
		camera.environment = _default_camera.environment
	camera.make_current()


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


func _sync_available() -> void:
	modulate = Color.WHITE if available else LOCKED_TINT
	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	)


func _sync_selected() -> void:
	if _arrow == null:
		return   # not ready yet; _ready syncs again
	theme_type_variation = FRAME_SELECTED if selected else FRAME_NORMAL
	# the arrow keeps its space when hidden, so the name doesn't shift when selected
	_arrow.self_modulate.a = 1.0 if selected else 0.0


func _on_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if (
			available
			and mouse_event != null
			and mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
	):
		clicked.emit(self)


## Children must not swallow the click, so the card itself receives it anywhere inside it.
func _ignore_mouse_on_children(node: Node) -> void:
	for child in node.get_children():
		var control := child as Control
		if control != null:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_on_children(child)
