class_name ActionButton
extends Button

## The key name the scene registered for this action, e.g. "Enter".
@export var key_name: String = ""

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE   # keys go through the engine, not Godot's focus system
	pressed.connect(func() -> void: GameEngine_auto.route_key(key_name))
