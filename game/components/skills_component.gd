## The Skills an adventurer holds, as a list of Skill ids.
##
## Skill definitions are authored, shared data and are not stored here. A Mastery has its own id
## and replaces its basic Skill's id in this list (see replace_skill).
class_name SkillsComponent
extends EntityComponent

const IS_SLOT_ROOT: bool = true

@export var skill_ids: Array[StringName] = []


func has_skill(id: StringName) -> bool:
	return skill_ids.has(id)


## Adds a Skill. Returns false if the adventurer already holds it.
func add_skill(id: StringName) -> bool:
	if skill_ids.has(id):
		return false
	skill_ids.append(id)
	_notify_changed()
	return true


## Removes a Skill. Returns false if the adventurer did not hold it.
func remove_skill(id: StringName) -> bool:
	var index: int = skill_ids.find(id)
	if index < 0:
		return false
	skill_ids.remove_at(index)
	_notify_changed()
	return true


## Swaps a basic Skill for its Mastery in place. Returns false if old_id is not held,
## or if new_id is already held.
func replace_skill(old_id: StringName, new_id: StringName) -> bool:
	var index: int = skill_ids.find(old_id)
	if index < 0 or skill_ids.has(new_id):
		return false
	skill_ids[index] = new_id
	_notify_changed()
	return true


func _notify_changed() -> void:
	if _lifecycle_initialized:
		emit_update_signal()
