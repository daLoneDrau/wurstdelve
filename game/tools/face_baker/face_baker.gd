class_name FaceBaker
extends Control

## Face Baker: a tool that bakes each adventurer's head from their 3D model into a small
## transparent PNG, the "face" shown on Party Setup's party slots. It is not part of the game.
##
## Run it on its own: open face_baker.tscn in the editor and press F6 (Run Current Scene).
## Pick an adventurer, frame the head with the sliders, and press Bake. The PNG is saved to
## res://assets/faces/<id>.png. Then add this line to the adventurer's record, which BAKE
## copies for you with COPY JSON LINE:
##   "face": "res://assets/faces/<id>.png",
## The editor imports the new PNG when its window next gets focus.
##
## Each adventurer's frame (size and shift) is remembered in face_frames.json beside this
## script, so BAKE ALL can redo every face the same way, for example after the output size or
## the lighting changes. To redo them without the window:
##   godot --path <project> res://game/tools/face_baker/face_baker.tscn -- --bake-all
##
## How the head is framed: the camera is orthographic and looks at the model from the front
## (the model faces +Z). The frame is a window as tall as `size` times the model's height,
## starting at the top of the model, as wide as the output's shape needs. `x` and `y` shift it,
## also in model heights, with positive y moving it up. The lighting copies Party Setup's stage.
##
## Only adventurers whose record has a `model` can be baked.

const FACE_DIR: String = "res://assets/faces"
const FRAMES_PATH: String = "res://game/tools/face_baker/face_frames.json"

## The size of the face frame on Party Setup's party slots, inside its 2 px border.
const DEFAULT_WIDTH: int = 46
const DEFAULT_HEIGHT: int = 40
const MIN_OUTPUT: int = 8
const MAX_OUTPUT: int = 512

## How far in front of the model the camera sits. The camera is orthographic, so this only has to
## clear the model.
const CAMERA_DISTANCE: float = 10.0

## The frame an adventurer gets until it is changed: a little over a head tall, with a hair of
## headroom.
const DEFAULT_FRAME: Dictionary = { "size": 0.2, "x": 0.0, "y": 0.01 }

const BAKE_ALL_ARGUMENT: String = "--bake-all"

## adventurer id -> { size, x, y }, only for adventurers whose frame was changed or saved.
var _frames: Dictionary = {}
var _assets: DDAssetsLibrary
## The authored adventurer records, sorted by name.
var _records: Array[Dictionary] = []
var _output_size: Vector2i = Vector2i(DEFAULT_WIDTH, DEFAULT_HEIGHT)
var _selected_id: String = ""
var _model: Node3D = null
## The model's bounds in the bake world, used to place the camera.
var _bounds: AABB = AABB()
## True while a bake is running, so nothing can change under it.
var _busy: bool = false

@onready var _viewport: SubViewport = %BakeViewport
@onready var _camera: Camera3D = %BakeCamera
@onready var _model_anchor: Node3D = %ModelAnchor
@onready var _list: ItemList = %AdventurerList
@onready var _preview_title_label: Label = %PreviewTitleLabel
@onready var _preview_rect: TextureRect = %PreviewRect
@onready var _actual_rect: TextureRect = %ActualRect
@onready var _width_spin: SpinBox = %WidthSpin
@onready var _height_spin: SpinBox = %HeightSpin
@onready var _size_slider: HSlider = %SizeSlider
@onready var _size_value: Label = %SizeValue
@onready var _x_slider: HSlider = %XSlider
@onready var _x_value: Label = %XValue
@onready var _y_slider: HSlider = %YSlider
@onready var _y_value: Label = %YValue
@onready var _reset_button: Button = %ResetButton
@onready var _bake_button: Button = %BakeButton
@onready var _bake_all_button: Button = %BakeAllButton
@onready var _copy_button: Button = %CopyButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_assets = DDAssetsLibrary.new()
	_assets.load_adventurer_records()
	_load_frames()

	_width_spin.set_value_no_signal(_output_size.x)
	_height_spin.set_value_no_signal(_output_size.y)
	_width_spin.value_changed.connect(_on_output_size_changed)
	_height_spin.value_changed.connect(_on_output_size_changed)
	_size_slider.value_changed.connect(_on_frame_changed)
	_x_slider.value_changed.connect(_on_frame_changed)
	_y_slider.value_changed.connect(_on_frame_changed)
	_list.item_selected.connect(_on_list_item_selected)
	_reset_button.pressed.connect(_on_reset_pressed)
	_bake_button.pressed.connect(_on_bake_pressed)
	_bake_all_button.pressed.connect(_on_bake_all_pressed)
	_copy_button.pressed.connect(_on_copy_pressed)

	# both previews show the bake viewport as it renders
	_preview_rect.texture = _viewport.get_texture()
	_actual_rect.texture = _viewport.get_texture()
	_apply_output_size()

	_load_records()
	_build_list()
	var first: int = _next_with_model(-1)
	if first >= 0:
		_list.select(first)
		_select(str(_records[first]["id"]))
	else:
		_say("NO ADVENTURER HAS A MODEL YET.")
		_sync_enabled()

	if OS.get_cmdline_user_args().has(BAKE_ALL_ARGUMENT):
		_bake_all_and_quit.call_deferred()


func _exit_tree() -> void:
	# the library is a Node that was never added to the tree
	if is_instance_valid(_assets):
		_assets.free()


# ---------------------------------------------------------------------------------------------
# framing

## The camera for a frame, as { "position": Vector3, "size": float }. `bounds` is the model's
## bounds. The frame's top edge sits at the top of the model, then `frame.y` and `frame.x`
## move it, in model heights. `size` is the camera's vertical extent in world units.
static func frame_camera(bounds: AABB, frame: Dictionary) -> Dictionary:
	var height: float = bounds.size.y
	var frame_height: float = height * float(frame["size"])
	var center_x: float = bounds.get_center().x + height * float(frame["x"])
	var center_y: float = bounds.end.y - frame_height * 0.5 + height * float(frame["y"])
	return {
		"position": Vector3(center_x, center_y, bounds.end.z + CAMERA_DISTANCE),
		"size": frame_height,
		}


## The bounds of every piece of geometry under `root`, itself included, in world space.
## `root` has to be in the tree. An empty AABB means there was no geometry.
static func model_bounds(root: Node3D) -> AABB:
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "GeometryInstance3D", true, false))
	var merged: AABB = AABB()
	var found: bool = false
	for node in nodes:
		var geometry := node as GeometryInstance3D
		if geometry == null:
			continue
		var box: AABB = geometry.global_transform * geometry.get_aabb()
		merged = box if not found else merged.merge(box)
		found = true
	return merged


## The frame an adventurer will be baked with.
func _frame_for(id: String) -> Dictionary:
	if _frames.has(id):
		return (_frames[id] as Dictionary).duplicate()
	return DEFAULT_FRAME.duplicate()


func _apply_camera() -> void:
	if _model == null or _bounds.size.y <= 0.0:
		return
	var placement: Dictionary = frame_camera(_bounds, _frame_for(_selected_id))
	_camera.position = placement["position"]
	_camera.size = placement["size"]


func _apply_output_size() -> void:
	_output_size = Vector2i(int(_width_spin.value), int(_height_spin.value))
	_viewport.size = _output_size
	# the "actual size" preview is the face as it would sit inside a slot's frame
	_actual_rect.custom_minimum_size = Vector2(_output_size)
	_update_title()


func _on_output_size_changed(_value: float) -> void:
	_apply_output_size()


func _on_frame_changed(_value: float) -> void:
	if _selected_id.is_empty():
		return
	_frames[_selected_id] = {
		"size": _size_slider.value, "x": _x_slider.value, "y": _y_slider.value,
		}
	_update_value_labels()
	_apply_camera()


func _on_reset_pressed() -> void:
	if _selected_id.is_empty():
		return
	_frames.erase(_selected_id)
	_sync_sliders()
	_apply_camera()


## Puts the selected adventurer's frame on the sliders without reacting to the change.
func _sync_sliders() -> void:
	var frame: Dictionary = _frame_for(_selected_id)
	_size_slider.set_value_no_signal(float(frame["size"]))
	_x_slider.set_value_no_signal(float(frame["x"]))
	_y_slider.set_value_no_signal(float(frame["y"]))
	_update_value_labels()


func _update_value_labels() -> void:
	_size_value.text = "%.3f" % _size_slider.value
	_x_value.text = "%+.3f" % _x_slider.value
	_y_value.text = "%+.3f" % _y_slider.value


# ---------------------------------------------------------------------------------------------
# adventurers and the model

func _load_records() -> void:
	_records.clear()
	for id in _assets.get_adventurer_ids():
		_records.append(_assets.get_adventurer_record(id))
	_records.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]) < str(b["name"])
	)


func _model_path_of(record: Dictionary) -> String:
	return str(record.get("model", ""))


func _record_index(id: String) -> int:
	for i in _records.size():
		if str(_records[i]["id"]) == id:
			return i
	return -1


## The first index after `from_index` that has a model, or -1.
func _next_with_model(from_index: int) -> int:
	for i in range(from_index + 1, _records.size()):
		if not _model_path_of(_records[i]).is_empty():
			return i
	return -1


## Fills the list from the records. An adventurer without a model is listed but can't be picked,
## and one with a baked face says so.
func _build_list() -> void:
	_list.clear()
	for i in _records.size():
		var record: Dictionary = _records[i]
		var id: String = str(record["id"])
		var text: String = str(record["name"]).to_upper()
		var has_model: bool = not _model_path_of(record).is_empty()
		if not has_model:
			text += " · NO MODEL"
		elif FileAccess.file_exists(_face_path(id)):
			text += " · BAKED"
		_list.add_item(text)
		_list.set_item_disabled(i, not has_model)
	var selected_index: int = _record_index(_selected_id)
	if selected_index >= 0:
		_list.select(selected_index)


func _on_list_item_selected(index: int) -> void:
	if _busy:
		_list.select(maxi(_record_index(_selected_id), 0))
		return
	_select(str(_records[index]["id"]))


## Shows an adventurer's model with their frame.
func _select(id: String) -> void:
	_selected_id = id
	var record: Dictionary = _records[_record_index(id)]
	_show_model(_model_path_of(record))
	_sync_sliders()
	_apply_camera()
	_update_title()
	_sync_enabled()
	if _model == null:
		_say("COULD NOT LOAD THE MODEL: %s" % _model_path_of(record))
	else:
		_say("")


## Replaces the model on the stage. Leaves `_model` null if it can't be loaded or has no geometry.
func _show_model(path: String) -> void:
	if _model != null:
		_model_anchor.remove_child(_model)
		_model.queue_free()
		_model = null
	_bounds = AABB()
	var packed: PackedScene = load(path) as PackedScene if not path.is_empty() else null
	var model: Node3D = packed.instantiate() as Node3D if packed != null else null
	if model == null:
		return
	_model_anchor.add_child(model)
	# a camera that came with the model must not take over the bake
	for camera in model.find_children("*", "Camera3D", true, false):
		(camera as Camera3D).current = false
	_camera.make_current()
	var bounds: AABB = model_bounds(model)
	if bounds.size.y <= 0.0:
		_model_anchor.remove_child(model)
		model.queue_free()
		return
	_model = model
	_bounds = bounds


func _update_title() -> void:
	if _selected_id.is_empty():
		_preview_title_label.text = "NO ADVENTURER"
		return
	var record: Dictionary = _records[_record_index(_selected_id)]
	_preview_title_label.text = "%s · %d×%d" % [
		str(record["name"]).to_upper(), _output_size.x, _output_size.y
	]


## Enables the buttons that can be used right now.
func _sync_enabled() -> void:
	var can_bake: bool = _model != null and not _busy
	_bake_button.disabled = not can_bake
	_bake_all_button.disabled = _busy or _next_with_model(-1) < 0
	_reset_button.disabled = not can_bake
	_copy_button.disabled = _busy or _selected_id.is_empty() or not FileAccess.file_exists(
			_face_path(_selected_id)
	)
	for control: Control in [_width_spin, _height_spin, _size_slider, _x_slider, _y_slider]:
		if control is SpinBox:
			(control as SpinBox).editable = not _busy
		elif control is HSlider:
			(control as HSlider).editable = can_bake


# ---------------------------------------------------------------------------------------------
# baking

func _face_path(id: String) -> String:
	return "%s/%s.png" % [FACE_DIR, id]


func _on_bake_pressed() -> void:
	if _busy or _model == null:
		return
	_set_busy(true)
	var problem: String = await _bake_current()
	_save_frames()
	_build_list()
	if problem.is_empty():
		_say("SAVED %s (%d×%d)\nADD THIS TO THE RECORD, OR PRESS COPY JSON LINE:\n%s" % [
			_face_path(_selected_id), _output_size.x, _output_size.y, _json_line(_selected_id)
		])
	else:
		_say("BAKE FAILED: %s" % problem)
	_set_busy(false)


func _on_bake_all_pressed() -> void:
	if _busy:
		return
	_set_busy(true)
	var summary: String = await _bake_all()
	_say(summary)
	_set_busy(false)


## Bakes every adventurer that has a model, each with their own frame. Returns a summary.
func _bake_all() -> String:
	var baked: int = 0
	var problems: PackedStringArray = PackedStringArray()
	for i in _records.size():
		if _model_path_of(_records[i]).is_empty():
			continue
		var id: String = str(_records[i]["id"])
		_list.select(i)
		_select(id)
		if _model == null:
			problems.append("%s: no model" % id)
			continue
		var problem: String = await _bake_current()
		if problem.is_empty():
			baked += 1
		else:
			problems.append("%s: %s" % [id, problem])
	_save_frames()
	_build_list()
	var summary: String = "BAKED %d FACE%s INTO %s" % [
		baked, "" if baked == 1 else "S", FACE_DIR
	]
	if not problems.is_empty():
		summary += "\nPROBLEMS:\n" + "\n".join(problems)
	return summary


func _bake_all_and_quit() -> void:
	_set_busy(true)
	var summary: String = await _bake_all()
	print("FaceBaker: ", summary)
	get_tree().quit(1 if summary.contains("PROBLEMS") else 0)


## Renders the model that is on the stage and saves it as the selected adventurer's face.
## Returns "" if it worked, or what went wrong.
func _bake_current() -> String:
	# remember the frame this face was baked with, even if it is still the default one
	_frames[_selected_id] = _frame_for(_selected_id)
	await _wait_for_render()
	var image: Image = _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return "nothing was rendered"
	image.convert(Image.FORMAT_RGBA8)
	var folder: String = ProjectSettings.globalize_path(FACE_DIR)
	var folder_error: Error = DirAccess.make_dir_recursive_absolute(folder)
	if folder_error != OK:
		return "could not make %s (%s)" % [FACE_DIR, error_string(folder_error)]
	var save_error: Error = image.save_png(ProjectSettings.globalize_path(_face_path(_selected_id)))
	if save_error != OK:
		return "could not save the PNG (%s)" % error_string(save_error)
	return ""


## Waits until what was just changed has been drawn.
func _wait_for_render() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _json_line(id: String) -> String:
	return "\"face\": \"%s\"," % _face_path(id)


func _on_copy_pressed() -> void:
	if _selected_id.is_empty():
		return
	DisplayServer.clipboard_set(_json_line(_selected_id))
	_say("COPIED: %s" % _json_line(_selected_id))


func _set_busy(busy: bool) -> void:
	_busy = busy
	_sync_enabled()


func _say(text: String) -> void:
	_status_label.text = text


# ---------------------------------------------------------------------------------------------
# remembered frames

## Reads the output size and every adventurer's frame from face_frames.json, if it exists.
func _load_frames() -> void:
	if not FileAccess.file_exists(FRAMES_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FRAMES_PATH))
	if not (parsed is Dictionary):
		push_error("FaceBaker: %s is not a valid JSON object." % FRAMES_PATH)
		return
	var data: Dictionary = parsed
	var output: Dictionary = data.get("output", {})
	_output_size = Vector2i(
		clampi(int(output.get("width", DEFAULT_WIDTH)), MIN_OUTPUT, MAX_OUTPUT),
		clampi(int(output.get("height", DEFAULT_HEIGHT)), MIN_OUTPUT, MAX_OUTPUT)
	)
	var frames: Dictionary = data.get("frames", {})
	for id in frames:
		var frame: Dictionary = frames[id]
		_frames[str(id)] = {
			"size": float(frame.get("size", DEFAULT_FRAME["size"])),
			"x": float(frame.get("x", DEFAULT_FRAME["x"])),
			"y": float(frame.get("y", DEFAULT_FRAME["y"])),
		}


func _save_frames() -> void:
	var data: Dictionary = {
		"output": { "width": _output_size.x, "height": _output_size.y },
		"frames": _frames,
	}
	var file: FileAccess = FileAccess.open(FRAMES_PATH, FileAccess.WRITE)
	if file == null:
		push_error("FaceBaker: could not write %s (%s)" % [
			FRAMES_PATH, error_string(FileAccess.get_open_error())
		])
		return
	file.store_string(JSON.stringify(data, "\t") + "\n")
