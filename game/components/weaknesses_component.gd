## The Weaknesses an adventurer holds, as a list of Weakness ids.
##
## Weakness definitions are authored, shared data and are not stored here. Weaknesses are passive
## and have no state of their own. How many an adventurer may hold is enforced by a system.
class_name WeaknessesComponent
extends EntityComponent

const IS_SLOT_ROOT: bool = true

@export var weakness_ids: Array[StringName] = []


func has_weakness(id: StringName) -> bool:
	return weakness_ids.has(id)


## Adds a Weakness. Returns false if the adventurer already holds it.
func add_weakness(id: StringName) -> bool:
	if weakness_ids.has(id):
		return false
	weakness_ids.append(id)
	_notify_changed()
	return true


## Removes a Weakness. Returns false if the adventurer did not hold it.
func remove_weakness(id: StringName) -> bool:
	var index: int = weakness_ids.find(id)
	if index < 0:
		return false
	weakness_ids.remove_at(index)
	_notify_changed()
	return true


func _notify_changed() -> void:
	if _lifecycle_initialized:
		emit_update_signal()
