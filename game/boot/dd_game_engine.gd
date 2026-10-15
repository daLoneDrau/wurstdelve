class_name DDGameEngine
extends GameEngine

func _initialize_systems() -> void:
	assets = AssetsLibrary.new()
	add_child(assets)

func load_resources() -> void:
	pass   # fonts, sounds and textures get loaded here later

func _setup_window() -> void:
	# 960x540, viewport stretch and integer scaling come from project settings.
	# The minimum size stops a desktop window from going below 1x.
	window.min_size = Vector2i(960, 540)

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