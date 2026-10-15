extends Node

func _ready() -> void:
	GameEngine_auto.run.call_deferred()