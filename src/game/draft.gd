class_name Draft
extends RefCounted
## The Prepare screen's rules (spec §1, §2): the player picks up to as many powers as the mission has slots, without
## their prices going over the mission's Might, and the order they pick them in is the order of the slots.
## Picking a card again takes it back out, and the later picks move up a slot to close the gap. Since v0.08 the
## mission sets the slots, the Might and the powers allowed, and empty slots are allowed.

## How many powers make a full loadout (v0.08: the mission's).
var slots := 4
## How much Might the picks may cost in all; 0 for no budget.
var capacity := 0
## The power keys the mission allows; empty for every power.
var pool := PackedStringArray()
## The picked power keys, in slot order.
var picks := PackedStringArray()
## Powers the god has not unlocked (v0.11 M1, spec §3.4): the board's draft shows them greyed with their price and refuses
## them; empty off the board.
var locked := PackedStringArray()
## Each picked power's ability level, 1-5 (god P1, spec §5.4): key -> level, absent = 1. A level raises the power's Might
## (PowerBook.might()); the board's level picker sets it, a mission outside the board leaves it empty.
var levels := {}


## The draft for a mission: its slots, its Might capacity and the powers it allows.
func for_mission(def: MissionDef) -> Draft:
	slots = def.slots
	capacity = def.dp_capacity
	pool = def.powers()
	return self


## Pick a power, or give a picked one back. "" when the draft changed, else why the power could not be added
## (refusal()). Giving a power back clears its level, so a later pick starts at level 1 (god P1, ruling C14).
func toggle(key: String) -> String:
	var at := picks.find(key)
	if at >= 0:
		picks.remove_at(at)
		levels.erase(key)
		return ""
	var why := refusal(key)
	if why == "":
		picks.append(key)
	return why


## Why a power that is not picked cannot be added: "pool" (not a power, or not the mission's), "locked" (v0.11 M1: not yet
## unlocked on the board), "slots" (every slot is taken), "dp" (its price at its level would go over the Might), or "" when it fits.
## A picked power gives "".
func refusal(key: String) -> String:
	if picks.has(key):
		return ""
	var p := PowerBook.get_power(key)
	if p.is_empty() or not (pool.is_empty() or pool.has(key)):
		return "pool"
	if locked.has(key):
		return "locked"
	if picks.size() >= slots:
		return "slots"
	if capacity > 0 and spent() + PowerBook.might(key, level_of(key)) > capacity:
		return "dp"
	return ""


## The Might the picks cost in all: each power's price at its level (PowerBook.might()).
func spent() -> int:
	var total := 0
	for key in picks:
		total += PowerBook.might(key, level_of(key))
	return total


## A power's ability level in this draft, 1-5; 1 when none was set.
func level_of(key: String) -> int:
	return clampi(int(levels.get(key, 1)), 1, PowerBook.MAX_LEVEL)


## Set a picked power's level (clamped 1-5). "" when set; "pool" for a power that is not picked; "dp" when its Might at the new
## level would put the picks over the capacity (the level stays as it was). Going down always fits.
func set_level(key: String, level: int) -> String:
	if not picks.has(key):
		return "pool"
	var to := clampi(level, 1, PowerBook.MAX_LEVEL)
	if capacity > 0 and to > level_of(key) \
			and spent() - PowerBook.might(key, level_of(key)) + PowerBook.might(key, to) > capacity:
		return "dp"
	if to == 1:
		levels.erase(key)
	else:
		levels[key] = to
	return ""


## A loadout can go out with at least one power in it (v0.08: empty slots are allowed).
func can_manifest() -> bool:
	return not picks.is_empty()


## The slot a power sits in, from 1, or 0 when it is not picked.
func slot_of(key: String) -> int:
	return picks.find(key) + 1


func is_full() -> bool:
	return picks.size() == slots


## Start from a saved loadout, in its own order: anything refused -- keys that are not powers (or not the mission's),
## repeats, anything past the last slot or over the Might -- is skipped.
func preselect(keys: PackedStringArray) -> Draft:
	picks = PackedStringArray()
	for key in keys:
		if refusal(key) == "" and not picks.has(key):
			picks.append(key)
	return self
