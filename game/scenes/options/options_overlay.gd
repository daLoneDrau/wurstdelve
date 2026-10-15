class_name OptionsOverlay
extends Scene

func _ready() -> void:
	register_action("Escape", "close")   # overlays don't get on_enter, so register here

func do_action(action: GameAction) -> void:
	if action.is_pressed() and action.name == "close":
		_game_engine.close_overlay("options")
