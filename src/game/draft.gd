class_name Draft
extends RefCounted
## The Prepare screen's rules (spec §1, §2): the player picks up to as many powers as the mission has slots, without
## their prices going over the mission's Divine Power, and the order they pick them in is the order of the slots.
## Picking a card again takes it back out, and the later picks move up a slot to close the gap. Since v0.08 the
## mission sets the slots, the Divine Power and the powers allowed, and empty slots are allowed.

## How many powers make a full loadout (v0.08: the mission's).
var slots := 4
## How much Divine Power the picks may cost in all; 0 for no budget.
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


## Pick a power, or give a picked one back. "" when the draft changed, else why the power could not be added
## (refusal()).
func toggle(key: String) -> String:
	var at := picks.find(key)
	if at >= 0:
		picks.remove_at(at)
		return ""
	var why := refusal(key)
	if why == "":
		picks.append(key)
	return why


## Why a power that is not picked cannot be added: "pool" (not a power, or not the mission's), "slots" (every slot
## is taken), "dp" (its price would go over the Divine Power), or "" when it fits. A picked power gives "".
func refusal(key: String) -> String:
	if picks.has(key):
		return ""
	var p := PowerBook.get_power(key)
	if p.is_empty() or not (pool.is_empty() or pool.has(key)):
		return "pool"
	if picks.size() >= slots:
		return "slots"
	if capacity > 0 and spent() + int(p.dp) > capacity:
		return "dp"
	return ""


## The Divine Power the picks cost in all.
func spent() -> int:
	var total := 0
	for key in picks:
		total += int(PowerBook.get_power(key).get("dp", 0))
	return total


## A loadout can go out with at least one power in it (v0.08: empty slots are allowed).
func can_manifest() -> bool:
	return not picks.is_empty()


## The slot a power sits in, from 1, or 0 when it is not picked.
func slot_of(key: String) -> int:
	return picks.find(key) + 1


func is_full() -> bool:
	return picks.size() == slots


## Start from a saved loadout, in its own order: anything refused -- keys that are not powers (or not the mission's),
## repeats, anything past the last slot or over the Divine Power -- is skipped.
func preselect(keys: PackedStringArray) -> Draft:
	picks = PackedStringArray()
	for key in keys:
		if refusal(key) == "" and not picks.has(key):
			picks.append(key)
	return self
