class_name PartySlot
extends PanelContainer

## One slot in Party Setup's party strip: a face frame, "N NAME" and a remove button, or a dimmed
## "N EMPTY SLOT". It only shows what it is given. The scene owns the party and tells the slot
## through `highlighted`.

## Emitted when the player clicks the slot (anywhere except the remove button).
signal clicked(slot: PartySlot)
## Emitted when the player clicks the remove button.
signal remove_requested(slot: PartySlot)

const FRAME_NORMAL: StringName = &"SnesSmallFrame"
const FRAME_HIGHLIGHTED: StringName = &"SnesSmallFrameSelected"
const NAME_COLOR: Color = Color(0.94, 0.93, 0.98, 1.0)
const HIGHLIGHT_COLOR: Color = Color(0.97, 0.83, 0.42, 1.0)
const EMPTY_COLOR: Color = Color(0.45, 0.47, 0.58, 1.0)

## The adventurer record in this slot ("" when the slot is empty).
var adventurer_id: String = ""

## True while this slot's adventurer is the one selected in the list. Set by the scene.
var highlighted: bool = false:
	set(value):
		highlighted = value
		_sync()

@onready var _face: Control = %Face
@onready var _face_texture: TextureRect = %FaceTexture
@onready var _face_label: Label = %FaceLabel
@onready var _name_label: Label = %NameLabel
@onready var _remove_button: Button = %RemoveButton


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_remove_button.pressed.connect(func() -> void: remove_requested.emit(self))
	_sync()


## Shows an adventurer in the slot. `number` is the slot's position, starting at 1.
func show_adventurer(number: int, record: Dictionary) -> void:
	adventurer_id = str(record.get("id", ""))
	_name_label.text = "%d %s" % [number, str(record.get("name", "")).to_upper()]
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_face.visible = true
	# the face is a baked 2D image (the record's `face`); without one the frame says FACE
	var face_path: String = str(record.get("face", ""))
	var face: Texture2D = load(face_path) as Texture2D if not face_path.is_empty() else null
	_face_texture.texture = face
	_face_label.visible = face == null
	_remove_button.visible = true
	_sync()


## Shows the slot as empty.
func show_empty(number: int) -> void:
	adventurer_id = ""
	_name_label.text = "%d EMPTY SLOT" % number
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_face.visible = false
	_remove_button.visible = false
	highlighted = false
	_sync()


func _sync() -> void:
	if _name_label == null:
		return   # not ready yet; _ready syncs again
	var filled: bool = not adventurer_id.is_empty()
	theme_type_variation = FRAME_HIGHLIGHTED if highlighted else FRAME_NORMAL
	var color: Color = EMPTY_COLOR
	if filled:
		color = HIGHLIGHT_COLOR if highlighted else NAME_COLOR
	_name_label.add_theme_color_override("font_color", color)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if filled else Control.CURSOR_ARROW


func _on_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if (
			not adventurer_id.is_empty()
			and mouse_event != null
			and mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
	):
		clicked.emit(self)
