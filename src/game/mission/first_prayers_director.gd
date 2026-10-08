class_name FirstPrayersDirector
extends MirasHouseDirector
## First Prayers (v0.11 M2, Tier 1, spec §4 and §8 row 5), Mira's House's Convert generalised: lead three of the poor to the
## old well shrine unseen. The shrine is a drawn stone post (Broken Lanterns' shrine) at the market's west edge, which a blow
## only shakes. A poor citizen whispered to its door (or lured to a light by it) goes down the well's steps to pray, hidden,
## PRAY_SECONDS, one at a time, and comes out a Believer; NEED out win. Few Faithful -- the clergy nearest the Temple and a few
## lay -- and no Inquisitor; but the shrine sits by the market: at MARKET_AT the market fills and Faithful stand at its door,
## and at PRIESTS_AT the priests come to the well. Mira's rules otherwise: a Faithful who sees runs to the Temple, a report
## delivered fills the Gaze, a seen death adds to it, the bell fills it. Its tags are Mira's own, the shrine named for the well.

## Where the shrine stands (v0.11 M2; moved to free ground), and its role (not a building in the tally: Rules.BUILDING_ROLES).
const SHRINE_AT := Vector2(-4.4, 2.8)
const ROLE := &"well_shrine"
## The poor (v0.11 M2): the POOR lay citizens nearest POOR_SPOT (the south-west quarter); NEED of them must pray.
const POOR_SPOT := Vector2(-11.0, 12.0)
const POOR := 8
const NEED := 3
## The night's numbers (v0.11 M2, spec §4). PRAY_SECONDS was tuned from the first guess of 25 so the scripted clear lands in 3-4 minutes;
## the rest are the first guesses, to be tuned in this order if it misses again.
const PRAY_SECONDS := 32.0
const MARKET_AT := 75.0
const MARKET_SECONDS := 40.0
const PRIESTS_AT := 150.0
const PRIESTS_SECONDS := 40.0
const FAITHFUL_CLERGY := 3
const FAITHFUL_LAY := 3
## Where the priests stand by the door (v0.11 M2; offsets from it).
const PRIEST_SPOTS := [Vector2(-1.0, 1.2), Vector2(1.0, 1.2)]
## How hard a blow shakes the shrine (v0.11 M2).
const SHRINE_SHAKE := 2.0


func _begin() -> void:
	need = NEED
	read_seconds = PRAY_SECONDS
	one_at_a_time = true
	super()


## The night's opening banner (v0.11 M2).
func _opening_banner() -> String:
	return "LEAD THE POOR TO THE OLD WELL"


## What the shrine's tag says (v0.11 M2).
func _house_label() -> String:
	return "OLD WELL SHRINE"


## The old well shrine, raised at the market's edge (v0.11 M2): a shrine post a blow only shakes. The town takes it away with
## its own buildings (Town.teardown()).
func _find_house() -> Structure:
	var at := _walkable(SHRINE_AT)
	var size := BrokenLanternsDirector.SHRINE_SIZE
	var s := crowd._env.add_structure(Rect2(at - size * 0.5, size), BrokenLanternsDirector.SHRINE_H, Structure.Kind.SHRINE, ROLE)
	s.damage_filter = func(st: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void: st.shake(SHRINE_SHAKE)
	town._built.append(s)
	return s


## The POOR lay citizens nearest POOR_SPOT are the poor; the FAITHFUL_CLERGY clergy nearest the Temple's door and FAITHFUL_LAY
## lay citizens spread through the rest are Halcyon's Faithful (v0.11 M2). No Inquisitor.
func _choose_people() -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	lay.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_to(POOR_SPOT) < b.ground_pos.distance_to(POOR_SPOT))
	for i in mini(POOR, lay.size()):
		lay[i].profile.faith = CitizenProfile.Faith.GRIEVING
		grieving.append(lay[i])
	clergy.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	for p in clergy.slice(0, FAITHFUL_CLERGY):
		_make_faithful(p)
	var rest: Array[Person] = []
	rest.assign(lay.slice(POOR))
	_spread_faithful(rest, FAITHFUL_LAY)
	venn = null


## The night's two windows (v0.11 M2): the market fills; the priests come to the well.
func _add_events() -> void:
	timeline.add(MARKET_AT, "market", "The market fills", _market_fills, func() -> bool: return not _free_faithful().is_empty())
	timeline.add(PRIESTS_AT, "priests", "The priests come to the well", _priests_come,
		func() -> bool: return not _free_clergy().is_empty())


## The market fills (v0.11 M2): the free Faithful nearest the door stand by it (Mira's LINE_SPOTS) for MARKET_SECONDS.
func _market_fills() -> void:
	_line_door(_free_faithful(), MirasHouseDirector.LINE_SPOTS, MARKET_SECONDS)


## The priests come (v0.11 M2): the free clergy among the Faithful stand by the door (PRIEST_SPOTS) for PRIESTS_SECONDS.
func _priests_come() -> void:
	_line_door(_free_clergy(), PRIEST_SPOTS, PRIESTS_SECONDS)


## The free Faithful who are clergy (v0.11 M2).
func _free_clergy() -> Array[Person]:
	var out: Array[Person] = []
	for f in _free_faithful():
		if f.profile.role == CitizenProfile.Role.CLERGY:
			out.append(f)
	return out


## The nearest of `pool` stand at the door's `spots` for `seconds` (v0.11 M2; Mira's liners: _liners_step() lets them go); any
## line still standing is let go first.
func _line_door(pool: Array[Person], spots: Array, seconds: float) -> void:
	for f: Variant in liners:
		if _alive(f) and f.mind == Person.Mind.DUTY:
			f.leave_shelter(false)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	liners = []
	for i in mini(spots.size(), pool.size()):
		pool[i].go_duty(_walkable(door + (spots[i] as Vector2)))
		liners.append(pool[i])
	_liners_left = seconds


## The hint's phase (v0.11 M2): "watched" while a Faithful watches the shrine's door, else "".
func hint_phase() -> String:
	return "watched" if faithful_seeing(door, SIGHT) != null else ""


## The tour (v0.11 M2, spec §4): the shrine, the first of the poor still standing, the Temple.
func tour() -> Array:
	var out := []
	if door != Vector2.INF:
		out.append([door, "The old well shrine, by the market. Lead the poor here."])
	for p: Variant in grieving:
		if _alive(p):
			out.append([(p as Person).ground_pos, "The poor of the south-west quarter. Three must pray at the well."])
			break
	if temple_door != Vector2.INF:
		out.append([temple_door, "The Temple. A Faithful who sees you runs here."])
	return out
