class_name DDEntityManager
extends EntityManager


## Entity tags for DD-specific entities
# const TAG_PLAYER: int = 1 << 0


## Determines if an Entity is tagged as a PC
func is_pc(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.PC)


## Determines if an Entity is tagged as an item
func is_item(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.ITEM)


func is_unique(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.UNIQUE)


## Kill all active combat effects/spells on an entity
func kill_spells_on(e_id: String) -> void:
	var entity := get_entity_by_id(e_id)
	if not entity:
		return

	var effects_comp: EffectsComponent = entity.get_component("EffectsComponent") as EffectsComponent
	if effects_comp:
		# Remove all combat-duration effects
		effects_comp.on_combat_end()

func unequip_from_inventory(_player_entity: Entity, _item_entity: Entity) -> bool:
	return false

func send_init_script_event(_entity: Entity) -> void:
	pass