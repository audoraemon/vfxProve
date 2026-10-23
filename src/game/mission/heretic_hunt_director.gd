class_name HereticHuntDirector
extends HuntDirector
## The Heretic Hunt (v0.11 M4, Tier 3, mission spec §3; the Hunt type's first night): the Inquisition hunts the god's believers,
## closing on the south-west quarter district by district. Three sweeps -- the north quarter, the west quarter, the south quarter --
## each a party of PARTY watchmen on a ring round its spot from the start, and a lantern-standard planted there at its time on the
## chain (STEP_AT, CHAIN). Then the captain -- the resident nearest the Temple's door, made a noble, waiting inside with ESCORTS
## watchmen -- leads the last sweep at STEP_AT[3] (or HEAD_CHAIN after the third standard breaks; never before the third is raised):
## he searches the CAPTAIN_HOUSES houses nearest the cellar, farthest first, CAPTAIN_STOP at each door, and then the cellar's. The
## cellar -- the dwelling nearest CELLAR_AT in the south-west quarter whose door no soldier's post watches -- is stone tonight. All
## three standards broken and the captain dead wins (HuntObjective); the cellar found loses.

## The three sweeps (v0.11 M4, mission spec §3): each spot (snapped to walkable ground), its words, its district in
## TownLayout.DISTRICTS. The west quarter's spot stands in the open at (-12.0, 3.0), not the spec's (-10.5, 1.5) in a lane, so its
## party keeps its ring and a relief can reach every post.
const SWEEP_SPOTS := [Vector2(-6.0, -10.0), Vector2(-12.0, 3.0), Vector2(-1.5, 12.0)]
const SWEEP_WORDS := ["the north quarter", "the west quarter", "the south quarter"]
const SWEEP_DISTRICTS := [1, 4, 7]
## The cellar's point and quarter; the Temple's door, where the captain comes out (The Lost Lamb's) (v0.11 M4).
const CELLAR_AT := Vector2(-11.0, 12.5)
const CELLAR_DISTRICT := 6
const TEMPLE_DOOR := LostLambDirector.TEMPLE_DOOR
## Mission spec §3's numbers (v0.11 M4), first guesses, tuned by Task 4's gate in this order: CHAIN (30-45), STEP_AT[0] (30-60), PARTY
## (2-3), RELIEF_AFTER (20-30); if doing nothing does not lose before dawn: CAPTAIN_HOUSES, then STEP_AT[3], then HEAD_PACE (decision
## 108). Each sweep's time and the captain's at the latest; the chain, and the captain's own (the controller's ruling: 30 s, so an
## acting player never waits a pure 45 s for the last item); a party, its ring and its reach; return and relief; the escorts and their
## gap; the search.
const STEP_AT := [60.0, 115.0, 185.0, 240.0]
const CHAIN := 45.0
const HEAD_CHAIN := 30.0
const PARTY := 3
const PARTY_R := 1.2
const GUARD_REACH := 1.5
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const ESCORTS := 2
const ESCORT_GAP := 1.4
const CAPTAIN_HOUSES := 5
const CAPTAIN_STOP := 4.0
const HEAD_PACE := 0.5
## A quiet door: no soldier's post within QUIET_R of it (M3's lesson); how many dwellings the choices weigh (v0.11 M4).
const QUIET_R := 2.0
const HOUSE_TRIES := 12
## Where the camera rests (v0.11 M4, Decision 80; moved from (-6, 3) by the photographs): the first spot up and right, the second left of
## the centre below the hint and the wishes' rows (at (-6, 3) it sat under them), the cellar low at the left, the Temple's door at the
## right.
const CAMERA_AT := Vector2(-10.5, -1.5)
## How far apart two doors of his route stand at the least (v0.11 M4): beyond twice the reach at which he counts a door reached.
const DOOR_APART := 2.0 * HuntDirector.ARRIVE
## How hard the stone cellar shakes when struck (v0.11 M4).
const STONE_SHAKE := 2.0

## The cellar and its door; the Temple (v0.11 M4).
var cellar: Structure
var cellar_door := Vector2.INF
var temple: Structure
## The cellar's own damage filter before it was made stone (v0.11 M4, the final review): put back at teardown().
var _cellar_filter := Callable()
## The words of the Blight that last landed (v0.11.1).
var _blight_said := ""


## The hunt's plan (v0.11 M4): the knobs, the three sweeps, the Temple, the cellar (stone tonight) and its door.
func _plan() -> void:
	chain = CHAIN
	head_chain = HEAD_CHAIN
	party_r = PARTY_R
	guard_reach = GUARD_REACH
	return_after = RETURN_AFTER
	relief_after = RELIEF_AFTER
	head_stop = CAPTAIN_STOP
	head_pace = HEAD_PACE
	escort_gap = ESCORT_GAP
	head_at = float(STEP_AT[3])
	head_door = TEMPLE_DOOR
	lost_word = "cellar"
	for i in SWEEP_SPOTS.size():
		steps.append(_step(String(SWEEP_WORDS[i]), SWEEP_SPOTS[i], City.current().districts()[SWEEP_DISTRICTS[i]], float(STEP_AT[i]), PARTY))
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	cellar = _cellar_house()
	if cellar != null:
		cellar_door = _open_door(cellar, _walkable(TEMPLE_DOOR))
		_cellar_filter = cellar.damage_filter
		cellar.damage_filter = _stone
	else:
		push_warning("HereticHuntDirector: no cellar; the captain has nowhere to search")


## The cellar (v0.11 M4, Decision 78): the dwelling nearest CELLAR_AT in its quarter whose door the Temple's street reaches and no
## soldier's post watches; the nearest reachable one there when every one tried is watched; null for none. Never a wish's building
## (_house_near()).
func _cellar_house() -> Structure:
	var area: Rect2 = City.current().districts()[CELLAR_DISTRICT]
	var from := _walkable(TEMPLE_DOOR)
	var skip: Array = []
	var first: Structure = null
	for k in HOUSE_TRIES:
		var h := _house_near(CELLAR_AT, skip)
		if h == null:
			break
		skip.append(h)
		if not area.has_point(h.center()):
			continue
		var door := _open_door(h, from)
		if door == Vector2.INF:
			continue
		if first == null:
			first = h
		if not _watched(door):
			return h
	return first


## Some living soldier's post lies within QUIET_R of `door` (v0.11 M4, The Informer's quiet doors). Only reads.
func _watched(door: Vector2) -> bool:
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.post != Vector2.INF and p.post.distance_to(door) <= QUIET_R:
			return true
	return false


## Structure.damage_filter for the cellar (v0.11 M4): stone tonight, a blow only shakes it, until teardown.
func _stone(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(STONE_SHAKE)


## The captain (v0.11 M4, Decision 77): the resident nearest the Temple's door, made a noble (the purple cape and crown), on duty and
## taken inside the Temple.
func _appoint_head() -> Person:
	var door := _walkable(TEMPLE_DOOR)
	var p := _citizen_near(door, CitizenProfile.Role.RESIDENT, _in_use())
	if p == null:
		return null
	p.profile.role = CitizenProfile.Role.NOBLE
	_set_down(p, door)
	p.go_duty(door)
	_take_inside(p, temple)
	return p


## His escorts (v0.11 M4): the lay citizens nearest the Temple's door, made watchmen, on duty and waiting inside with him.
func _appoint_escorts() -> Array:
	var door := _walkable(TEMPLE_DOOR)
	var out: Array = []
	for k in ESCORTS:
		var crew := _lay_near(door, 1, _in_use() + out)
		if crew.is_empty():
			break
		_dress_guard(crew[0])
		_set_down(crew[0], door)
		crew[0].go_duty(door)
		_take_inside(crew[0], temple)
		out.append(crew[0])
	return out


## Where the `k`th escort comes out (v0.11 M4): ESCORT_GAP to either side of the captain along the Temple's street, beyond one Silent
## Doom of him (the Temple stands behind its door).
func _escort_out(k: int, door: Vector2) -> Vector2:
	return _walkable(door + Vector2(ESCORT_GAP * (-1.0 if k % 2 == 0 else 1.0), 0.0))


## His route (v0.11 M4): the doors of the CAPTAIN_HOUSES dwellings nearest the cellar whose door the cellar's reaches and stands apart
## from the others' (_apart()), the door farthest from the cellar first, then the cellar's door. Empty with no cellar.
func _head_route() -> Array[Vector2]:
	var out: Array[Vector2] = []
	if cellar == null:
		return out
	var skip: Array = [cellar]
	for k in CAPTAIN_HOUSES + HOUSE_TRIES:
		if out.size() >= CAPTAIN_HOUSES:
			break
		var h := _house_near(cellar.center(), skip)
		if h == null:
			break
		skip.append(h)
		var door := _open_door(h, cellar_door)
		if door != Vector2.INF and _apart(door, out + [cellar_door]):
			out.append(door)
	var middle := cellar.center()
	out.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(middle) > b.distance_squared_to(middle))
	out.append(cellar_door)
	return out


## `door` stands DOOR_APART or more from every one of `doors` (v0.11 M4): a house sharing a door with the cellar or a house already on
## his route would end his search, or one stop, early.
func _apart(door: Vector2, doors: Array) -> bool:
	for d: Vector2 in doors:
		if d.distance_to(door) < DOOR_APART:
			return false
	return true


## The quarry: the cellar's door (v0.11 M4).
func _quarry_point() -> Vector2:
	return cellar_door


## The opening banner (v0.11 M4).
func _opening_banner() -> String:
	return "THE HERETIC HUNT"


## The banner when the captain finds the cellar (v0.11 M4).
func _found_banner() -> String:
	return "THE CELLAR IS FOUND"


## Blight's mark (v0.11.1, spec §7.3, Heretic Hunt row 15): a raised standard within BlightFx.REACH of `at`, guarded or not (a guarded one
## is still a mark, so the player is told THEIR GUARD KEEPS IT). Only reads.
func blight_target(at: Vector2) -> Vector2:
	var i := _blight_step(at)
	return standard(i).center() if i >= 0 else Vector2.INF


## An unguarded standard takes the rot (Decision 29: Blight never routes round the opposition).
func blight_takes(at: Vector2) -> bool:
	var i := _blight_step(at)
	return i >= 0 and not _guarded(i)


## Blight on a standard: unguarded, it breaks as a blow that breaks it (its party goes home, the chain runs); guarded, nothing but the
## banner and no alarm (the base).
func blighted(at: Vector2) -> bool:
	var i := _blight_step(at)
	_blight_said = "BLIGHT - THE STANDARD ROTS" if blight_takes(at) else "THEIR GUARD KEEPS IT"
	if not super(at):
		return false
	var s := standard(i)
	if s != null and not s.destroyed:
		s.damage(s.max_hp + s.hp + 1.0, at, &"blight")
	return true


## The banner of the Blight that just landed (blighted() saves it: the standard is down by the time BlightFx asks).
func blight_words(at: Vector2) -> String:
	return _blight_said if _blight_said != "" else ("BLIGHT - THE STANDARD ROTS" if blight_takes(at) else "THEIR GUARD KEEPS IT")


## The raised, unbroken step whose standard stands within BlightFx.REACH of `at`, or -1 (v0.11.1).
func _blight_step(at: Vector2) -> int:
	for i in steps.size():
		var s := standard(i)
		if steps[i].raised and not steps[i].broken and s != null and not s.destroyed and s.distance_to(at) <= BlightFx.REACH:
			return i
	return -1


## The tour (v0.11 M4, mission spec §3): the cellar, the north quarter, the Temple.
func tour() -> Array:
	var out := []
	if cellar_door != Vector2.INF:
		out.append([cellar_door, "Your believers' cellar. If the hunt finds it, the night is lost."])
	if not steps.is_empty():
		out.append([steps[0].spot, "The north quarter. The hunt raises its first standard here at %s." % UiTheme.clock(float(STEP_AT[0]))])
	out.append([_walkable(TEMPLE_DOOR), "The Temple. Its captain leads the last sweep by %s." % UiTheme.clock(float(STEP_AT[3]))])
	return out


## Lets go of the cellar's stone -- its own filter put back, none for most dwellings -- then the Hunt type's (v0.11 M4).
func teardown() -> void:
	if is_instance_valid(cellar) and cellar.damage_filter == _stone:
		cellar.damage_filter = _cellar_filter
	super()
