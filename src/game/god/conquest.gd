class_name Conquest
extends RefCounted
## The conquer arithmetic (World Map + Conquer Progress, Task 1): believers per town on the god's save, the percent they make of a
## town's people, which towns are open, which are conquered, and what one night's roll banks. All static; town ids are Strings.

## The town every god starts in; always open.
const HOME := "aldermere"
## The percent of the opener at which the next town opens.
const UNLOCK_PERCENT := 60
## Faith one conquered town gives.
const CONQUER_FAITH := 5
## Believers a night fills when the god is caught (a main night, not ascended).
const FILL_CAUGHT := 3
## Believers a night fills when the god ascends clean.
const FILL_CLEAN := 6
## The town whose percent opens the next: opener -> opened.
const OPENS := {"aldermere": "capital"}
## Display names.
const TOWN_NAMES := {"aldermere": "Aldermere", "capital": "The Capital"}


## The game's towns as Strings (City.IDS; test cities are not included).
static func towns() -> PackedStringArray:
	var out := PackedStringArray()
	for id: Variant in City.IDS:
		out.append(String(id))
	return out


static func is_town(town: String) -> bool:
	return towns().has(town)


static func town_name(town: String) -> String:
	return str(TOWN_NAMES.get(town, town))


## The people of `town`; 0 for an unknown one.
static func population(town: String) -> int:
	if not is_town(town):
		return 0
	return City.by_id(StringName(town)).citizens()


static func percent(believers: int, pop: int) -> int:
	if pop <= 0:
		return 0
	return int(floor(100.0 * clampi(believers, 0, pop) / pop))


static func count_of(slot: GodSlot, town: String) -> int:
	var v: Variant = slot.believers.get(town, 0)
	return clampi(int(v) if v is int or v is float else 0, 0, population(town))


static func percent_of(slot: GodSlot, town: String) -> int:
	return percent(count_of(slot, town), population(town))


static func is_open(slot: GodSlot, town: String) -> bool:
	return town == HOME or slot.opened.has(town)


## The town whose percent opens `town`, or "".
static func opener_of(town: String) -> String:
	for key: String in OPENS:
		if OPENS[key] == town:
			return key
	return ""


static func conquered(slot: GodSlot, town: String) -> bool:
	return population(town) > 0 and percent_of(slot, town) == 100


static func conquered_towns(slot: GodSlot) -> PackedStringArray:
	var out := PackedStringArray()
	for town in towns():
		if conquered(slot, town):
			out.append(town)
	return out


## Faith the conquered towns give.
static func bonus(slot: GodSlot) -> int:
	return CONQUER_FAITH * conquered_towns(slot).size()


## Believers a night fills: 0 off the main night, FILL_CAUGHT when caught, FILL_CLEAN when ascended.
static func fill_target(main: bool, ascended: bool) -> int:
	if not main:
		return 0
	return FILL_CLEAN if ascended else FILL_CAUGHT


## Banks one night's roll (`BelieverRoll.report()`: {"town", "carried_alive", "named", "fill", "lost"}) onto `slot`: the town's
## count becomes the carried who lived plus, on a main night, the named and the fill; then every town whose opener is at or above
## UNLOCK_PERCENT opens (an open town is never closed). An unknown town returns {} and changes nothing.
static func bank(slot: GodSlot, roll: Dictionary, main: bool) -> Dictionary:
	var town := str(roll.get("town", ""))
	if not is_town(town):
		return {}
	var pop := population(town)
	var before := count_of(slot, town)
	var named := int(roll.get("named", 0))
	var fill := int(roll.get("fill", 0))
	var count := clampi(int(roll.get("carried_alive", 0)) + (named + fill if main else 0), 0, pop)
	slot.believers[town] = count
	var newly := PackedStringArray()
	for opener: String in OPENS:
		var target: String = OPENS[opener]
		if not slot.opened.has(target) and percent_of(slot, opener) >= UNLOCK_PERCENT:
			slot.opened.append(target)
			newly.append(target)
	return {
		"town": town, "before": before, "count": count, "percent": percent(count, pop),
		"named": named, "fill": fill, "converts": maxi(count - clampi(int(roll.get("carried_alive", 0)), 0, pop), 0) if main else 0,
		"lost": int(roll.get("lost", 0)), "opened": newly, "conquered": count >= pop and pop > 0,
	}
