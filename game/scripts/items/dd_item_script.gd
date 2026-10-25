## Base class for the scripts of Dungeon Degenerates Items.
##
## Besides the on_<event> handlers every EntityScript can have, an Item script may answer
## queries. A query is a plain method that a system calls directly, because an event cannot
## hand an answer back to whoever raised it. Each query has a default that a script overrides
## only when its Item breaks the usual rule.
##
## A script has no entity manager of its own, so every query is given one.
class_name DDItemScript
extends EntityScript


## Determines if the Item is Heavy for an owner. printed_heavy is the value printed on the card.
## The default is the printed value. Override it on an Item whose Heavy status depends on its
## owner, such as the Studded Vest.
func heavy_for(_owner_id: StringName, printed_heavy: bool, _entity_manager: EntityManager) -> bool:
	return printed_heavy
