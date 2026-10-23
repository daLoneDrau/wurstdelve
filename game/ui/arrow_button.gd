class_name ArrowButton
extends ActionButton

## NES/SNES-style menu row: text only, no box, with a selection arrow on the left.
##
## The arrow shows while this row is the selected one (chosen by keyboard, or by
## mouse hover, which asks the menu to select it) and the row is enabled.
## Disabled rows never show an arrow, so the arrow always means "Enter will do this".
##
## Selection is owned by the menu (see TitleScene). This node only draws the arrow
## and reports hover. Give the row a theme variation whose styles are empty boxes with a
## left content margin wider than the arrow (the title scene's "MenuItem" does this).

## Emitted when the mouse enters an enabled row. The menu responds by selecting it.
signal hovered(button: ArrowButton)

## Pixel-art arrow. Leave empty to use a generated placeholder triangle.
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
	draw.connect(_sync_arrow)   # a Button redraws when `disabled` changes, so the arrow follows it
	_sync_arrow()


func _on_mouse_entered() -> void:
	if not disabled:
		hovered.emit(self)


func _sync_arrow() -> void:
	if _arrow != null:
		_arrow.visible = selected and not disabled


func _apply_arrow_texture() -> void:
	var tex: Texture2D = arrow_texture if arrow_texture != null else _make_placeholder_arrow()
	_arrow.texture = tex
	_arrow.size = tex.get_size()
	_arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)


## A small right-pointing triangle, used until the real arrow art is assigned.
static func _make_placeholder_arrow() -> Texture2D:
	var img: Image = Image.create(8, 10, false, Image.FORMAT_RGBA8)
	for y in 10:
		for x in 8:
			if float(x) <= (1.0 - absf(y - 4.5) / 5.0) * 7.0:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)
