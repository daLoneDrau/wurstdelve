class_name ShuffleBag
extends RefCounted

## Hands out the items of a list one at a time in random order, using every item once
## before any item comes around again. When the list runs out it is reshuffled.
##
## The first item after a reshuffle is never the item that was handed out last, so the
## same line can't appear twice in a row across the boundary.
##
## Used for taglines, and reusable for any "play them all before repeating" list
## (the character screen's flavor phrases follow the same rule).

var _items: Array[String] = []
var _order: Array[String] = []
var _cursor: int = 0
var _last: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## `seed_value` makes the order repeatable (for tests). The default, -1, is random each run.
func _init(items: Array[String], seed_value: int = -1) -> void:
	_items = items.duplicate()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_cursor = 0
	_order = []   # empty, so the first call to next() shuffles


## How many items are in the bag in total.
func size() -> int:
	return _items.size()


## Returns the next item, reshuffling first when every item has been used.
## Returns "" if the list is empty.
func next() -> String:
	if _items.is_empty():
		return ""
	if _cursor >= _order.size():
		_reshuffle()
	var item: String = _order[_cursor]
	_cursor += 1
	_last = item
	return item


func _reshuffle() -> void:
	_order = _items.duplicate()
	# Fisher-Yates: every ordering is equally likely.
	for i in range(_order.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: String = _order[i]
		_order[i] = _order[j]
		_order[j] = tmp
	# Don't open the new round with the item that closed the last one.
	if _order.size() > 1 and _order[0] == _last:
		var k: int = _rng.randi_range(1, _order.size() - 1)
		var swap: String = _order[0]
		_order[0] = _order[k]
		_order[k] = swap
	_cursor = 0
