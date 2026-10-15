class_name DDEntityManager
extends EntityManager


## Entity tags for Warlock-specific entities
const TAG_PLAYER: int = 1 << 0
const TAG_MONSTER: int = 1 << 1
const TAG_ITEM: int = 1 << 2
const TAG_JARL: int = 1 << 3
const TAG_LAND: int = 1 << 4
const TAG_SEA: int = 1 << 5
const TAG_AI: int = 1 << 6
const TAG_UNIQUE: int = 1 << 8
const TAG_EQUIPPED: int = 1 << 9


## Determines if an Entity is tagged as a PC
func is_pc(e: Entity) -> bool:
	return e.tags.has(TAG_PLAYER)


## Determines if an Entity is tagged as an item
func is_item(e: Entity) -> bool:
	return e.tags.has(TAG_ITEM)


func is_unique(e: Entity) -> bool:
	return e.tags.has(TAG_UNIQUE)


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