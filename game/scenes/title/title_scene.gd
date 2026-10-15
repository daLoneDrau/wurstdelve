class_name TitleScene
extends Scene

func on_enter() -> void:
	register_action("Enter", "new_game")
	register_action("O", "options")
	register_action("Q", "quit")

func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return
	if not _game_engine.scene_stack.is_empty():
		return   # an overlay is open; see the gotcha below
	match action.name:
		"new_game": print("New Game (placeholder)")
		"options": _game_engine.push_scene("options")
		"quit": _game_engine.quit()
