class_name Draft
extends RefCounted
## The Prepare screen's rules (spec §1): the player picks exactly four of the eleven powers, and the order they
## pick them in is the order of slots 1-4. Picking a card again takes it back out, and the later picks move up
## a slot to close the gap.

const SLOTS := 4

## The picked power keys, in slot order.
var picks := PackedStringArray()


func toggle(key: String) -> void:
	var at := picks.find(key)
	if at >= 0:
		picks.remove_at(at)
	elif picks.size() < SLOTS and not PowerBook.get_power(key).is_empty():
		picks.append(key)


## The slot a power sits in, 1 to 4, or 0 when it is not picked.
func slot_of(key: String) -> int:
	return picks.find(key) + 1


func is_full() -> bool:
	return picks.size() == SLOTS


## Start from a saved loadout, in its own order: keys that are not powers, repeats and anything past the
## fourth are dropped.
func preselect(keys: PackedStringArray) -> Draft:
	picks = PackedStringArray()
	for key in keys:
		if not picks.has(key):
			toggle(key)
	return self
