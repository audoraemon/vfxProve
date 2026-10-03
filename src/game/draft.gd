class_name Draft
extends RefCounted
## The Prepare screen's rules (spec §1): the player picks exactly as many powers as the mission has slots (four in
## v0.07), and the order they pick them in is the order of the slots. Picking a card again takes it back out, and
## the later picks move up a slot to close the gap. Since v0.08 the mission sets the slots and the powers allowed.

## How many powers make a loadout (v0.08: the mission's).
var slots := 4
## How much Divine Power the picks may cost in all; 0 for no budget (v0.08 M1; M2 spends it).
var capacity := 0
## The power keys the mission allows; empty for every power.
var pool := PackedStringArray()
## The picked power keys, in slot order.
var picks := PackedStringArray()


## The draft for a mission: its slots, its DP capacity and the powers it allows.
func for_mission(def: MissionDef) -> Draft:
	slots = def.slots
	capacity = def.dp_capacity
	pool = def.powers()
	return self


func toggle(key: String) -> void:
	var at := picks.find(key)
	if at >= 0:
		picks.remove_at(at)
	elif picks.size() < slots and not PowerBook.get_power(key).is_empty() and (pool.is_empty() or pool.has(key)):
		picks.append(key)


## The slot a power sits in, from 1, or 0 when it is not picked.
func slot_of(key: String) -> int:
	return picks.find(key) + 1


func is_full() -> bool:
	return picks.size() == slots


## Start from a saved loadout, in its own order: keys that are not powers (or not the mission's), repeats and
## anything past the last slot are dropped.
func preselect(keys: PackedStringArray) -> Draft:
	picks = PackedStringArray()
	for key in keys:
		if not picks.has(key):
			toggle(key)
	return self
