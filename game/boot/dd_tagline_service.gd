class_name DDTaglineService
extends Node

## Autoload (registered as TaglineService_auto). Hands out the game's taglines in
## shuffled order, using every tagline once before reshuffling. Because it is an
## autoload, the shuffle state lives for the whole run and is shared by every screen.
##
##     var tag: String = TaglineService_auto.next()
##
## The list itself lives in game/data/taglines.gd.

var _bag: ShuffleBag


func _init() -> void:
	_bag = ShuffleBag.new(Taglines.LIST)


## The next tagline, reshuffling first when all have been used. "" if the list is empty.
func next() -> String:
	return _bag.next()


## How many taglines there are in total.
func size() -> int:
	return _bag.size()
