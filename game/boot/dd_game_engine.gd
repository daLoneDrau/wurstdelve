class_name DDGameEngine
extends GameEngine

## The map: its authored graph and its changing state. Built when the map records load, and null
## if they failed to load. Everything outside the map code reads and changes the map through it.
var map_service: MapService = null


func _initialize_systems() -> void:
	assets = DDAssetsLibrary.new()
	add_child(assets)


## The asset library as its Dungeon Degenerates subclass. `assets` is typed as the framework's
## AssetsLibrary, so use this to reach the authored-data methods.
func dd_assets() -> DDAssetsLibrary:
	return assets as DDAssetsLibrary


func load_resources() -> void:
	# fonts, sounds and textures get loaded here later
	var item_count: int = dd_assets().load_item_records()
	print("DDGameEngine: loaded %d item record(s)" % item_count)
	var adventurer_count: int = dd_assets().load_adventurer_records()
	print("DDGameEngine: loaded %d adventurer record(s)" % adventurer_count)
	var map_space_count: int = dd_assets().load_map_records()
	print("DDGameEngine: loaded %d map space(s)" % map_space_count)
	if map_space_count > 0:
		map_service = MapService.new(dd_assets().get_map_document())

func _setup_window() -> void:
	# 960x540, viewport stretch and integer scaling come from project settings.
	# The minimum size stops a desktop window from going below 1x.
	window.min_size = Vector2i(960, 540)
	add_child(PaletteLayer.new())

func _start_game() -> void:
	register_scene("title", "res://game/scenes/title/title.tscn")
	register_scene("options", "res://game/scenes/options/options.tscn")
	change_scene("title")


## Mouse path: runs the action a press of `key_name` would run (e.g. "Enter").
## Reaches scenes in the same order as a real key press (overlays top-down, then the primary scene).
func route_key(key_name: String) -> bool:
	var ev := InputEventKey.new()
	ev.keycode = OS.find_keycode_from_string(key_name)
	ev.pressed = true
	var handled: bool = _dispatch_key(key_name, "START", ev)
	ev.pressed = false
	_dispatch_key(key_name, "END", ev)
	return handled


func _dispatch_key(key_name: String, phase: String, ev: InputEventKey) -> bool:
	for i in range(scene_stack.size() - 1, -1, -1):
		var overlay: Node = scene_stack[i].get("node")
		if is_instance_valid(overlay) and _route_input_to_scene(overlay, key_name, phase, ev):
			return true
		if scene_stack[i].get("blocker") != null:
			return false
	return is_instance_valid(primary_scene) and _route_input_to_scene(primary_scene, key_name, phase, ev)
