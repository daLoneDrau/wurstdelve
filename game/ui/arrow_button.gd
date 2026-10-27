class_name ArrowButton
extends ActionButton

## NES/SNES-style menu row: text only, no box, with a selection arrow on the left.
##
## The arrow shows while this row is the selected one (chosen by keyboard, or by
## mouse hover, which asks the menu to select it), or while the mouse is over it, and the row
## is enabled. A lone button that no menu manages therefore still shows its arrow on hover.
## Keys go through the engine, so "focused" means `selected`: a scene that wants an arrow on a
## button without the mouse sets `selected` on it.
## Disabled rows never show an arrow, so the arrow always means "Enter will do this".
##
## Selection is owned by the menu (see TitleScene). This node only draws the arrow
## and reports hover. Give the row a theme variation whose styles are empty boxes with a
## left content margin wider than the arrow (the title scene's "MenuItem" does this).

## Emitted when the mouse enters an enabled row. The menu responds by selecting it.
signal hovered(button: ArrowButton)

## The SNES arrow art, used when no `arrow_texture` is assigned.
const DEFAULT_ARROW: Texture2D = preload("res://assets/ui/icons/snes_arrow.png")

## Pixel-art arrow. Leave empty to use the default SNES arrow.
@export var arrow_texture: Texture2D:
	set(value):
		arrow_texture = value
		if is_node_ready():
			_apply_arrow_texture()

## True while this row is the menu's current selection. Set by the menu, not by the row.
var selected: bool = false:
	set(value):
		selected = value
		_sync_arrow()

var _arrow: TextureRect
var _hovering: bool = false


func _ready() -> void:
	super._ready()
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	_arrow = TextureRect.new()
	_arrow.name = "SelectionArrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_arrow.stretch_mode = TextureRect.STRETCH_KEEP
	_arrow.visible = false
	add_child(_arrow)
	_apply_arrow_texture()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	draw.connect(_sync_arrow)   # a Button redraws when `disabled` changes, so the arrow follows it
	_sync_arrow()


func _on_mouse_entered() -> void:
	_hovering = true
	_sync_arrow()
	if not disabled:
		hovered.emit(self)


func _on_mouse_exited() -> void:
	_hovering = false
	_sync_arrow()


func _sync_arrow() -> void:
	if _arrow != null:
		_arrow.visible = (selected or _hovering) and not disabled


func _apply_arrow_texture() -> void:
	var tex: Texture2D = arrow_texture if arrow_texture != null else DEFAULT_ARROW
	_arrow.texture = tex
	_arrow.size = tex.get_size()
	_arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
