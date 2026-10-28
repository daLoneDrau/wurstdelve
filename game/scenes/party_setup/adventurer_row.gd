class_name AdventurerRow
extends Button

## One row in Party Setup's adventurer list: "N NAME". It only shows what it is given. The scene
## owns which row is selected and who is in the party, and tells the row through `selected` and
## `in_party`. A row for an adventurer that has no record yet is a dimmed placeholder that can't
## be selected.

const HIGHLIGHT_COLOR: Color = Color(0.64, 0.13, 0.15, 1.0)
const NAME_COLOR: Color = Color(0.94, 0.93, 0.98, 1.0)
const SELECTED_COLOR: Color = Color(0.97, 0.83, 0.42, 1.0)
const PARTY_COLOR: Color = Color(0.38, 0.85, 0.42, 1.0)
const PLACEHOLDER_COLOR: Color = Color(0.38, 0.4, 0.5, 1.0)
const ARROW: Texture2D = preload("res://assets/ui/icons/snes_arrow.png")

## The adventurer record this row shows ("" for a placeholder).
var adventurer_id: String = ""

## True while this is the selected row. Set by the scene, not by the row.
var selected: bool = false:
	set(value):
		selected = value
		_sync()

## True while this adventurer is in the party. Set by the scene, not by the row.
var in_party: bool = false:
	set(value):
		in_party = value
		_sync()

var _highlight: ColorRect
var _arrow: TextureRect


func _init() -> void:
	theme_type_variation = &"SnesButton"   # text only, with room on the left for the arrow
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_NONE   # keys go through the engine, not Godot's focus system
	custom_minimum_size = Vector2(0, 26)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	# the highlight draws behind the row's text
	_highlight = ColorRect.new()
	_highlight.color = HIGHLIGHT_COLOR
	_highlight.show_behind_parent = true
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_highlight)

	_arrow = TextureRect.new()
	_arrow.texture = ARROW
	_arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_arrow.stretch_mode = TextureRect.STRETCH_KEEP
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.size = ARROW.get_size()
	_arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	add_child(_arrow)
	_sync()


## Shows an authored adventurer. `number` is the position in the whole roster, starting at 1.
func show_adventurer(number: int, record: Dictionary) -> void:
	adventurer_id = str(record.get("id", ""))
	text = "%d %s" % [number, str(record.get("name", "")).to_upper()]
	disabled = false
	_sync()


## Shows a dimmed placeholder for an adventurer that is not authored yet.
func show_placeholder(number: int) -> void:
	adventurer_id = ""
	text = "%d ADVENTURER %d" % [number, number]
	disabled = true
	selected = false
	in_party = false
	_sync()


func _sync() -> void:
	if _highlight == null:
		return   # not ready yet; _ready syncs again
	_highlight.visible = selected
	_arrow.visible = selected
	mouse_default_cursor_shape = (
		Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	)
	var color: Color = NAME_COLOR
	if adventurer_id.is_empty():
		color = PLACEHOLDER_COLOR
	elif selected:
		color = SELECTED_COLOR
	elif in_party:
		color = PARTY_COLOR
	for color_name in [
		"font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
		"font_hover_pressed_color", "font_disabled_color"
	]:
		add_theme_color_override(color_name, color)
