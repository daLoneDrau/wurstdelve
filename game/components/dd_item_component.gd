## Dungeon Degenerates item data, extending ItemComponent.
##
## ItemComponent is a slot root, so this component is still stored and found under the name
## "ItemComponent" (entity.get_component("ItemComponent")), which is where EquipmentSystem and
## InventorySystem look for it.
##
## Inherited fields DD uses:
## - item_type: ItemTags bits (the classes printed on the card).
## - weapon_type_flags: AttackTypeTags bits. Not empty means the Item grants an Attack.
## - equip_slots, two_handed: where it is equipped. A non-empty equip_slots means it must be
##   equipped for its effects to apply.
## - price: GP value.
## - modifiers: an ItemModifierBundle holding the printed numbers, such as +1 ARM.
## - requirements: only the "attributes" key is used, for example {"attributes": {&"str": 6}}.
##   The adventurer's effective attribute must be at least the value.
##
## Inherited fields DD ignores and leaves at their defaults: stackable, max_stack, max_count,
## quantity, nested_inventory_id, weight, rarity, durability, durability_max, set_id,
## set_bonuses, bound_to_entity, cursed, unique_instance, and the other requirements keys.
## Uniqueness is EntityTags.Tag.UNIQUE on the item entity.
##
## Data only. Rules (who counts as Heavy, the two-Heavy carry limit, equip checks) belong in
## systems or the item's script.
class_name DDItemComponent
extends ItemComponent

## The printed Heavy value. It counts toward the limit of two Heavy Items carried.
## Whether an Item is Heavy for a particular owner is computed on demand: some Items change it
## (the Studded Vest is not Heavy if its owner's STR is 8 or more).
@export var heavy: bool = false

## Attribute keys (AttributesComponent constants such as &"per") the Attack is tested against.
## One key means a fixed attribute, and several mean the player chooses. Empty for Items that
## grant no Attack.
@export var attack_attributes: Array[StringName] = []


## Determines if the item has an ItemTags bit (a single Tag value).
func has_tag(tag: int) -> bool:
	return item_type.has(tag)


## Determines if the item grants an Attack.
func is_weapon() -> bool:
	return not weapon_type_flags.is_empty()
