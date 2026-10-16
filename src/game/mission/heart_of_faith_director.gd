class_name HeartOfFaithDirector
extends RazeDirector
## The Heart of Faith (v0.11 M6, Tier 5, mission spec §3; Raze + Assassinate, Decision 231): put out Halcyon's Great Flame, then kill the
## High Priest who comes to rekindle it. Stage one is the Raze type's staged rule (M4's, as The Armoury's ruling has it): the oil-house
## (the dwelling nearest OIL_AT whose door the street reaches) and the Great Temple come into use on the chain (STAGE_AT, or CHAIN after
## the one before is razed -- at once for a target already down, M5's horn rule -- _spoilable()); before its time a target's fire goes
## out and its fall counts only at its time; in use it is razed burned _spoil_for() seconds in all (SPOIL) or fallen. Lantern Knights --
## soldiers MissionDirector._knight() adds, corps KNIGHT -- stand STANDING at each from the start along its quiet face (_face()) and
## ARRIVING come out of its door there at its time; while one stands guard (within GUARD_REACH) the target is sealed (seal()). A fallen Knight is replaced RELIEF_AFTER later
## from the Citadel's gate (RELIEFS a night; backing off while no road leads to his post). The Temple razed puts the flame out: Halcyon
## looks harder (FURY a seen death, HeartGaze, each rise bannered), BEARERS Knights come out at the Citadel's gate as a litter's bearers
## and Odran -- the cleric nearest the Citadel's gate, waiting inside it -- follows ODRAN_CHAIN later: hidden in his litter while two
## bearers live (MissionDirector's shared ride, _ride_in() / _ride_step() / _ride_out(), as Pip rides M5's relic cart), on foot below two
## with LAST_GUARD behind him; the litter at the Temple's steps sets him down there, its bearers his guard (plan decision 291). At the
## steps, on foot and not held, he rekindles for RITE, started again by a whisper, Discord or a fright. His death, any way, wins once
## the flame is out (StagesObjective); the flame still burning at BLESSED_AT, or rekindled, loses. Odran and every Knight are kept from
## the town's flight by MissionDirector._hold_all(); the Knights are soldiers besides, whom the evacuation and the rally never take.

## One Knight's post (v0.11 M6): a plain record, so the director holds no cycle.
class Post:
	extends RefCounted
	## The Knight, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## The target he guards (0 the oil-house, 1 the Temple), or -1 for a bearer or a last guard.
	var target := -1
	## Where he stands.
	var spot := Vector2.INF
	## Of the pair that comes out at the target's time.
	var arriving := false
	## Seconds since he fell (counted every frame).
	var fallen := 0.0
	## He is a relief walking in, until he first stands guard.
	var relief := false
	## He has gone home.
	var done := false


## Halcyon's Gaze at the Heart (v0.11 M6, plan decision 293): SEEN a seen death, FURY once the flame is out.
class HeartGaze:
	extends GazeMeter
	## Halcyon looks harder: the flame is out (v0.11 M6).
	var fury := false

	## A seen death (v0.11 M6): FURY once the flame is out, else SEEN.
	func seen_death() -> void:
		add(FURY if fury else SEEN)


## The oil-house's point; the Citadel's gate; the foot of its lane; the Temple's steps (v0.11 M6, mission spec §3). OIL_AT is the quiet
## row behind the Temple, west of it (the gate's ruling: the spec's (-3.5, -9.5) stands in a street never clear of passers-by and the
## town's patrols, so no Knight there could ever be Doomed unseen).
const OIL_AT := Vector2(-2.5, -12.5)
const CITADEL_GATE := HarvestDirector.CITADEL_GATE
const LANE_FOOT := Vector2(-10.5, -5.1)
const STEPS_AT := Vector2(0.8, -5.0)
## The quiet yards behind the Temple, the oil-house's west of the Temple's (v0.11 M6): each target's Knights stand along its face nearest
## its own, where few pass (_face()).
const QUIET_AT := [Vector2(-3.5, -14.0), Vector2(2.0, -14.0)]
## The targets' names on the tags and in words; the strip's words as each comes into use; the next target's tag's words (v0.11 M6).
const NAMES := ["OIL-HOUSE", "TEMPLE"]
const WORDS := ["oil-house", "Temple"]
const STAGE_LABELS := ["The keepers draw the flame's oil", "The Great Flame blazes"]
const NEXT_WORDS := ["IN USE BY", "THE FLAME BLAZES BY"]
## Mission spec §3's numbers (v0.11 M6), first guesses, tuned by the gate in this order: CHAIN (35-45), STAGE_AT[0] (40-60), SPOIL[1]
## (15-25), ODRAN_CHAIN (20-30), ARRIVING (1-3); ODRAN_PACE (0.25-0.5, plan decision 292). Stage one: each target's time at the latest,
## the chain, the Knights standing and arriving, their spacing (wanted, and the least, beyond a witness's 2.0), their reach, each
## target's burning, reliefs, the blessing.
const STAGE_AT := [45.0, 110.0]
const CHAIN := 45.0
const STANDING := 2
const ARRIVING := 2
const POST_GAP := 2.4
const POST_APART := 2.1
const GUARD_REACH := 2.5
const SPOIL := [12.0, 20.0]
const RELIEF_AFTER := 30.0
const RELIEFS := 4
const BLESSED_AT := 300.0
## Stage two (v0.11 M6): the bearers and their square; the last guard and his gap; Odran's chain, pace, rite and the altar's reach.
const BEARERS := 4
const LITTER_SIDE := 2.1
const LAST_GUARD := 1
const GUARD_GAP := 2.5
const ODRAN_CHAIN := 30.0
const ODRAN_PACE := 0.5
const RITE := 20.0
const ALTAR_REACH := 1.5
## The Gaze (v0.11 M6): a seen death, and once the flame is out.
const SEEN := 10.0
const FURY := 20.0
## How near its time a target not yet in use puts the hint on "not_yet" (the spec's last 25 s); how many dwellings the oil-house's choice
## weighs; seconds between looks; how near a point counts as reached; how far a place must move before someone is sent again; how far
## the litter goes each look; how far to the side of Odran's track each guard behind him walks (v0.11 M6).
const WORK_AHEAD := 25.0
const HOUSE_TRIES := 12
const TICK := 0.5
const ARRIVE := 0.8
const MOVE := 0.3
const LITTER_STEP := 1.5
const SIDE_STEP := 1.2
## The step of the grid a walled-in target's posts are looked for on (v0.11 M6, _spread()).
const SCAN := 0.25
## How far a Knight's post or a bearer's place keeps from the town's soldiers' posts where it can (v0.11 M6): a witness's 2.0 and the
## little a soldier at his post wanders.
const QUIET := 2.5
## Where the camera rests (v0.11 M6, Decision 247): the oil-house up and right of the centre, the Temple at the right, the Citadel's gate
## above the centre.
const CAMERA_AT := Vector2(-6.0, -4.0)
## The map tags' colours the Raze type does not name (v0.11 M6): not yet grey, the altar orange.
const MARK_NOT_YET := Color("9a948a")
const MARK_PLACE := Color("ff9a3a")

## The oil-house, the Temple and each one's door; the Citadel's gate and the Temple's steps on walkable ground (v0.11 M6).
var oil_house: Structure
var temple: Structure
var doors: Array[Vector2] = []
var citadel_door := Vector2.INF
var steps_at := Vector2.INF
## Each target in use yet; the second it was razed (-1 until then) (v0.11 M6).
var in_use: Array[bool] = []
var razed_at: Array[float] = []
## Stage one's Knights, the bearers, and the guards walking behind Odran (Post records); reliefs this night (v0.11 M6).
var posts: Array = []
var bearers: Array = []
var guards: Array = []
var reliefs := 0
## Odran (a Variant: he may be freed); the flame is out, and when; Odran out of the Citadel; riding his litter; dead or gone; the
## blessing came; the flame rekindled; his rite runs, and its seconds left; the litter's middle (v0.11 M6).
var odran: Variant = null
var flame_out := false
var flame_out_at := -1.0
var odran_out := false
var riding := false
var odran_dead := false
var blessed := false
var kindled := false
var rite_on := false
var rite_left := RITE
var litter_at := Vector2.INF
## Odran's road (the Citadel's gate, the lane's foot, the Temple's steps) and the point of it he makes for; Knights walking home
## (v0.11 M6).
var _road: Array[Vector2] = []
var _road_at := 1
var _homeward: Array = []
## Seconds into the night, and to the next look (v0.11 M6).
var _clock := 0.0
var _tick_in := 0.0
## Odran fell with the flame out since the Gaze was last judged: his strike's deaths go unjudged (v0.11 M6, _judge_gaze()).
var _spare_win := false


## The night's setup (v0.11 M6): the Heart's Gaze; the two targets, kept from the town's engineers; at each, its standing Knights at
## their posts and its arriving pair inside it; Odran inside the Citadel; the stages and the blessing on the strip.
func _begin() -> void:
	gaze = HeartGaze.new()
	citadel_door = _walkable(CITADEL_GATE)
	steps_at = _walkable(STEPS_AT)
	for at: Vector2 in [CITADEL_GATE, LANE_FOOT, STEPS_AT]:
		_road.append(_walkable(at))
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple" and not s.destroyed:
			temple = s
			break
	oil_house = _oil_house()
	if oil_house == null or temple == null:
		push_warning("HeartOfFaithDirector: no oil-house or Temple")
	for s: Variant in [oil_house, temple]:
		if s != null:
			targets.append(s as Structure)
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(targets)
	for i in targets.size():
		in_use.append(false)
		razed_at.append(-1.0)
		doors.append(_face(targets[i], QUIET_AT[mini(i, QUIET_AT.size() - 1)]))
	var placed: Array = []  # the Temple's posts first, so the bigger target keeps its quiet yard; each apart from every one before
	var spots := {}
	for i in range(targets.size() - 1, -1, -1):
		var before := placed.duplicate()
		var mine: Array[Vector2] = []
		for k in STANDING + ARRIVING:
			var q := Post.new()
			q.spot = _post(i, k, placed)
			placed.append(q)
			mine.append(q.spot)
		if not _apart_all(mine):  # packed in by its neighbours: spread the four as far apart as its yard allows
			mine = _far_posts(i, before)
			placed = before.duplicate()
			for at in mine:
				var q := Post.new()
				q.spot = at
				placed.append(q)
		for k in mine.size():
			spots[Vector2i(i, k)] = mine[k]
	for i in targets.size():
		for k in STANDING + ARRIVING:
			var p := Post.new()
			p.target = i
			p.arriving = k >= STANDING
			p.spot = spots[Vector2i(i, k)]
			if p.arriving:
				p.man = _knight(doors[i])
				_take_inside(p.man as Person, targets[i])
			else:
				p.man = _knight(p.spot)
			posts.append(p)
	odran = _citizen_near(citadel_door, CitizenProfile.Role.CLERGY)
	if _alive(odran):
		var o := odran as Person
		_set_down(o, citadel_door)
		o.go_duty(citadel_door)
		_take_inside(o, null)
	crowd._field.enemy_killed.connect(_on_killed)
	crowd.escaped.connect(_on_escaped)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		timeline.add(float(STAGE_AT[i]), "stage_%d" % i, String(STAGE_LABELS[i]), _open.bind(i),
			func() -> bool: return not in_use[i] and not razed(targets[i]))
	timeline.add(BLESSED_AT, "blessed", "The Great Flame is blessed", _bless, func() -> bool: return not flame_out)
	rules.banner.emit("THE HEART OF FAITH")


## Target `s`'s face (v0.11 M6): of its doors the street from the Citadel's gate reaches (_open_door()'s four), the one nearest `quiet`
## (its QUIET_AT); its front when none is reached.
func _face(s: Structure, quiet: Vector2) -> Vector2:
	var half := s.footprint.size * 0.5 + Vector2(0.5, 0.5)
	var best := Vector2.INF
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(s.center() + off)
		if (crowd._grid == null or not crowd._grid.path(citadel_door, door).is_empty()) 				and (best == Vector2.INF or door.distance_to(quiet) < best.distance_to(quiet)):
			best = door
	return best if best != Vector2.INF else _front_of(s)


## The oil-house (v0.11 M6, plan decision 295): the dwelling nearest OIL_AT whose door the street from the Citadel's gate reaches, never a
## wish's; null for none.
func _oil_house() -> Structure:
	var skip: Array = []
	for k in HOUSE_TRIES:
		var h := _house_near(OIL_AT, skip)
		if h == null:
			return null
		skip.append(h)
		if _open_door(h, citadel_door) != Vector2.INF:
			return h
	return null


## The `k`th Knight's post at target `i` (v0.11 M6): along its door's face, the standing pair POST_GAP apart about the door, the arriving
## pair POST_GAP beyond them, out from the face (deeper into its quiet yard) -- each spread (_spread()) within GUARD_REACH of the target
## and beyond POST_APART of every post in `mates`.
func _post(i: int, k: int, mates: Array) -> Vector2:
	var face := doors[i]
	var out := face - targets[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	var want := face + along * side * POST_GAP * 0.5 + (out * POST_GAP if k >= STANDING else Vector2.ZERO)
	return _spread(i, want, mates)


## A post at or near `want` for target `i` (v0.11 M6, The Crown's Bread's _spread() with POST_APART; a fourth copy, noted for a later
## hoist): walkable, within GUARD_REACH of the target, reached on foot from its door, and beyond POST_APART of every post in `mates`; the
## nearest such point on rings of POST_GAP / 2 steps round `want`, else (a small house walled in by its neighbours, whose posts along
## its face fall out of reach) the nearest to `want` on a SCAN grid round the target -- first among points QUIET of the town's soldiers'
## posts (_quiet(): a Knight standing among the watch could never be Doomed unseen), then among any; with none apart, the point of that
## grid in reach farthest from every post in `mates`; `want` made walkable when there is not even that.
func _spread(i: int, want: Vector2, mates: Array) -> Vector2:
	var first := _walkable(want)
	var box := targets[i].footprint.grow(GUARD_REACH)
	var near: Array[Vector2] = []
	var y := box.position.y
	while y <= box.end.y:
		var x := box.position.x
		while x <= box.end.x:
			var at := Vector2(x, y)
			if (crowd._grid == null or crowd._grid.walkable(at)) and targets[i].distance_to(at) <= GUARD_REACH:
				near.append(at)
			x += SCAN
		y += SCAN
	near.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(want) < b.distance_squared_to(want))
	for quiet: bool in [true, false]:
		for ring in 5:
			var r := POST_GAP * 0.5 * float(ring)
			var n := 1 if ring == 0 else 12
			for k in n:
				var at := first if ring == 0 else _walkable(want + Vector2.from_angle(TAU * float(k) / float(n)) * r)
				if (not quiet or _quiet(at)) and _post_fits(i, at, mates):
					return at
		for at in near:
			if (not quiet or _quiet(at)) and _post_fits(i, at, mates):
				return at
	var far := first
	var gap := -1.0
	for at in near:
		var least := INF
		for m: Post in mates:
			least = minf(least, m.spot.distance_to(at))
		if least > gap and _post_fits(i, at, []):
			far = at
			gap = least
	return far


## Every two of `spots` stand beyond POST_APART (v0.11 M6). Only reads.
static func _apart_all(spots: Array[Vector2]) -> bool:
	for a in spots.size():
		for b in range(a + 1, spots.size()):
			if spots[a].distance_to(spots[b]) <= POST_APART:
				return false
	return true


## Target `i`'s STANDING + ARRIVING posts spread as far apart as its yard allows (v0.11 M6, when _post()'s nearest-first choice packs them
## in): each the point of a SCAN grid round it that serves (_post_fits() but for the spacing) farthest from every post so far and from
## `others` (the other target's), a QUIET one while one stands beyond POST_APART.
func _far_posts(i: int, others: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var box := targets[i].footprint.grow(GUARD_REACH)
	var near: Array[Vector2] = []
	var y := box.position.y
	while y <= box.end.y:
		var x := box.position.x
		while x <= box.end.x:
			var at := Vector2(x, y)
			if _post_fits(i, at, []):
				near.append(at)
			x += SCAN
		y += SCAN
	near.sort_custom(func(u: Vector2, v: Vector2) -> bool: return u.distance_squared_to(doors[i]) < v.distance_squared_to(doors[i]))
	while out.size() < STANDING + ARRIVING:
		var pick := Vector2.INF
		for quiet: bool in [true, false]:
			var gap := -1.0
			for at in near:
				if quiet and not _quiet(at):
					continue
				var least := INF
				for o in out:
					least = minf(least, o.distance_to(at))
				for m: Post in others:
					least = minf(least, m.spot.distance_to(at))
				least = minf(least, 2.0 * GUARD_REACH)  # past this all are alike: the nearest the door wins
				if least > gap:
					gap = least
					pick = at
			if gap > POST_APART:
				break
		out.append(pick if pick != Vector2.INF else _walkable(doors[i]))
	return out


## `at` serves as a post of target `i` (v0.11 M6): walkable, within GUARD_REACH of it and no nearer the other target (each guards his own
## yard), reached on foot from its door, and beyond POST_APART of every post in `mates`.
func _post_fits(i: int, at: Vector2, mates: Array) -> bool:
	var reach := targets[i].distance_to(at)
	if reach > GUARD_REACH:
		return false
	for other in targets:
		if other != targets[i] and other.distance_to(at) < reach:
			return false
	for m: Post in mates:
		if m.spot.distance_to(at) <= POST_APART:
			return false
	return crowd._grid == null or (crowd._grid.walkable(at) and (at.distance_to(doors[i]) <= 0.1 or not crowd._grid.path(doors[i], at).is_empty()))


## No post of the town's own soldiers lies within QUIET of `at` (v0.11 M6): the Knights' own are left out. Only reads.
func _quiet(at: Vector2) -> bool:
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps != Person.Corps.KNIGHT and p.post.distance_to(at) <= QUIET:
			return false
	return true


## Target `s` can be razed: it is in use (v0.11 M6; RazeDirector._spoilable()).
func _spoilable(s: Structure) -> bool:
	var i := targets.find(s)
	return i >= 0 and in_use[i]


## The seconds of burning that raze `s` (v0.11 M6, Task 4's hook): the oil-house's SPOIL[0], the Temple's SPOIL[1].
func _spoil_for(s: Structure) -> float:
	var i := targets.find(s)
	return float(SPOIL[clampi(i, 0, SPOIL.size() - 1)]) if i >= 0 else spoil_seconds


## The second target `i` comes into use at the latest (v0.11 M6): its own time, or CHAIN after the one before is razed if sooner -- at
## once for a target already down then (M5's horn rule, the controller's ruling: a fast player never waits out a chain with nothing left
## to do).
func stage_due(i: int) -> float:
	var at := float(STAGE_AT[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and razed_at[i - 1] >= 0.0:
		at = minf(at, razed_at[i - 1] + (0.0 if _down(i) else CHAIN))
	return at


## Target `i`'s building is gone (v0.11 M6, The Armoury's _down()): fallen, or freed with it.
func _down(i: int) -> bool:
	return not is_instance_valid(targets[i]) or targets[i].destroyed


## Target `i` comes into use (v0.11 M6): its arriving pair comes out of its door to their posts.
func _open(i: int) -> void:
	if in_use[i]:
		return
	in_use[i] = true
	for p: Post in posts:
		if p.target == i and p.arriving and not p.done and _alive(p.man) and (p.man as Person).inside:
			var k := p.man as Person
			_bring_out(k, p.spot)
			_keep_from_flight(k, true)
			k.send_to_post(p.spot)


## Each target not in use whose chained time has come comes into use (v0.11 M6); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, targets.size()):
		if not in_use[i] and not razed(targets[i]) and razed_at[i - 1] >= 0.0 and _clock >= stage_due(i):
			rules.banner.emit(String(STAGE_LABELS[i]).to_upper())
			_open(i)


## One step (v0.11 M6): each target sealed while guarded, the Raze type's (the timeline, each target judged), the Gaze's deaths (each rise
## bannered), the chain, Odran's carrying or his rite every frame, and every TICK a look: everyone held by the one rule, the Knights
## tended, the litter or his walk.
func step(delta: float) -> void:
	_clock += delta
	_guard_seals()
	super(delta)
	_judge_gaze()
	_chain()
	if riding:
		_carry()
	elif odran_out and not odran_down():
		_step_rite(delta)
	for p: Post in posts:
		if not p.done and not _alive(p.man):
			p.fallen += delta
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	_hold_all(_held(), _evacuation_began())
	_tend()
	if not odran_out or odran_down():
		return
	if riding:
		_step_litter()
	else:
		_step_on_foot()


## The Gaze's seen deaths judged (v0.11 M6, the controller's ruling: every rise has a banner), "HALCYON SEES A DEATH", and its FURY once the
## flame is out. The deaths waiting when Odran fell -- his own and his strike's -- are let go unjudged: the kill that wins the night is done
## before the Gaze is judged, so a winning strike never also loses (nor, on the board, ends the held night).
func _judge_gaze() -> void:
	if _spare_win:  # the strike that ended Odran won the night first: its deaths are never judged (the controller's ruling)
		_spare_win = false
		gaze._deaths.clear()
		return
	var was := gaze.value
	gaze.judge_deaths(crowd)
	if gaze.value > was:
		rules.banner.emit("HALCYON SEES A DEATH: +%d" % roundi(FURY) if (gaze as HeartGaze).fury else "HALCYON SEES A DEATH")


## Everyone the night holds (v0.11 M6, the carried ruling): Odran and every Knight still at work. Untyped: any may be a body freed after
## its death fade.
func _held() -> Array:
	var out: Array = [odran]
	for list: Array in [posts, bearers, guards]:
		for p: Post in list:
			if not p.done:
				out.append(p.man)
	return out


## Each standing target not razed is sealed while a Knight stands guard, open while none does (v0.11 M6, The Armoury's ruling).
func _guard_seals() -> void:
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s) or s.destroyed:
			continue
		var held := not guards_at(i).is_empty()
		if held and not is_sealed(s):
			seal(s)
		elif not held and is_sealed(s):
			unseal(s)


## Post `p`'s Knight stands guard (v0.11 M6): not gone home, alive, out of doors, within GUARD_REACH of his target.
func _on_guard(p: Post) -> bool:
	if p.done or p.target < 0 or not _alive(p.man):
		return false
	var k := p.man as Person
	var s := targets[p.target]
	return not k.inside and is_instance_valid(s) and s.distance_to(k.ground_pos) <= GUARD_REACH


## Target `i`'s Knights on guard now (v0.11 M6). Only reads.
func guards_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if p.target == i and _on_guard(p):
			out.append(p.man as Person)
	return out


## Target `i`'s living Knights out of doors, on guard or not (v0.11 M6, for the scripted player). Only reads.
func standing_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if p.target == i and not p.done and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## A relief walking in to a target not razed, or null (v0.11 M6, for the scripted player). Only reads.
func relief_walking() -> Person:
	for p: Post in posts:
		if p.relief and not p.done and _alive(p.man) and not _on_guard(p) and not (p.man as Person).inside:
			return p.man as Person
	return null


## Stage one's Knights at their posts (v0.11 M6): a fallen one replaced RELIEF_AFTER after he fell from the Citadel's gate while his
## target stands unrazed (RELIEFS at most); one off his post sent back to it; those going home taken in at the Citadel's gate.
func _tend() -> void:
	for p: Post in posts:
		if p.done:
			continue
		if not _alive(p.man):
			if p.fallen >= RELIEF_AFTER and reliefs < RELIEFS and not razed(targets[p.target]):
				_relieve(p)
			continue
		p.fallen = 0.0
		var k := p.man as Person
		if k.inside:
			continue
		if _on_guard(p):
			p.relief = false
		if k.mind == Person.Mind.POST and k.anchor.distance_to(p.spot) > MOVE:
			k.send_to_post(p.spot, false, true)
	for v: Variant in _homeward.duplicate():
		if not _alive(v) or (v as Person).inside:
			_homeward.erase(v)
		elif (v as Person).ground_pos.distance_to(citadel_door) <= ARRIVE:
			_take_inside(v as Person, null)
			_homeward.erase(v)


## A new Knight for post `p` (v0.11 M6, The Bishop's _relieve()): added at the Citadel's gate, walking to the post; one added once the
## town is running is kept from its flight first. With no road from the gate to the post, the relief backs off and is tried again
## RELIEF_AFTER later (the carried ruling: not at every look).
func _relieve(p: Post) -> void:
	if not _reaches(p.spot):
		p.fallen = 0.0
		return
	var k := _knight(citadel_door)
	if crowd._fled_all:
		_keep_from_flight(k, true)  # added once the town is running: never one of the flight
	k.send_to_post(p.spot, false, true)
	p.man = k
	p.fallen = 0.0
	p.relief = true
	reliefs += 1
	rules.banner.emit("A NEW KNIGHT COMES FROM THE CITADEL")


## A Knight walking from the Citadel's gate can reach `at` (v0.11 M6): the town's walk grid has a road there (always, with none).
func _reaches(at: Vector2) -> bool:
	return crowd._grid == null or at.distance_to(citadel_door) <= 0.1 or not crowd._grid.path(citadel_door, at).is_empty()


## Post `p`'s Knight goes home (v0.11 M6): to the Citadel's gate, taken in there; one still inside stays inside.
func _go_home(p: Post) -> void:
	p.done = true
	if _alive(p.man) and not (p.man as Person).inside:
		(p.man as Person).send_to_post(citadel_door, false, false)
		_homeward.append(p.man)


## Razed (v0.11 M6): unsealed for good, its Knights home; the oil-house brings the Temple on the chain; the Temple puts the flame out.
func _on_razed(s: Structure) -> void:
	var i := targets.find(s)
	unseal(s)
	razed_at[i] = _clock
	for p: Post in posts:
		if p.target == i and not p.done:
			_go_home(p)
	if i + 1 < targets.size():
		rules.banner.emit("THE %s IS RAZED" % String(NAMES[i]))
		if timeline != null:
			timeline.expect("stage_%d" % (i + 1), stage_due(i + 1))
	else:
		_flame_goes_out()


## The Great Flame goes out (v0.11 M6): Halcyon looks harder; the litter's four bearers come out at its square below the Citadel's gate;
## Odran's chain on the strip.
func _flame_goes_out() -> void:
	if flame_out:
		return
	flame_out = true
	flame_out_at = _clock
	(gaze as HeartGaze).fury = true
	rules.banner.emit("THE GREAT FLAME GOES OUT")
	rules.banner.emit("HALCYON LOOKS HARDER")
	litter_at = _litter_spot()
	var taken: Array[Vector2] = []
	for k in BEARERS:
		var p := Post.new()
		p.spot = _apart(litter_at + _corner(k), taken)
		taken.append(p.spot)
		p.man = _knight(p.spot)
		if crowd._fled_all:
			_keep_from_flight(p.man as Person, true)
		bearers.append(p)
	rules.banner.emit("THE HIGH PRIEST'S LITTER WAITS")
	if timeline != null:
		timeline.add(timeline.elapsed() + ODRAN_CHAIN / timeline.stretch_factor(), "odran", "The High Priest comes to rekindle the flame",
			_odran_comes, func() -> bool: return not odran_out and not odran_down())


## A bearer's place at or near `want` (v0.11 M6): walkable, reached on foot from the Citadel's gate and beyond POST_APART of every place in
## `taken` -- a witness apart, so one Doom takes one bearer unseen; the nearest such point on rings of a quarter LITTER_SIDE round `want`,
## first among points QUIET of the town's soldiers' posts, then among any; `want` made walkable when there is none.
func _apart(want: Vector2, taken: Array[Vector2]) -> Vector2:
	for quiet: bool in [true, false]:
		for ring in 5:
			var n := 1 if ring == 0 else 12
			for k in n:
				var at := _walkable(want + Vector2.from_angle(TAU * float(k) / float(n)) * LITTER_SIDE * 0.25 * float(ring))
				if (quiet and not _quiet(at)) or (crowd._grid != null and (not crowd._grid.walkable(at) or not _reaches(at))):
					continue
				var clear := true
				for o in taken:
					clear = clear and o.distance_to(at) > POST_APART
				if clear:
					return at
	return _walkable(want)


## The `k`th corner of the litter's square, from its middle (v0.11 M6): LITTER_SIDE a side.
func _corner(k: int) -> Vector2:
	var h := LITTER_SIDE * 0.5
	return [Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)][k % 4]


## The litter's first middle (v0.11 M6, plan decision 290): the first point down Odran's road from the Citadel's gate where all four
## corners are walkable; the lane's foot when none is.
func _litter_spot() -> Vector2:
	for at: Vector2 in [citadel_door + Vector2(0.0, LITTER_SIDE), _road[1], _road[1] + Vector2(LITTER_SIDE, 0.0)]:
		var ok := true
		for k in 4:
			ok = ok and (crowd._grid == null or crowd._grid.walkable(at + _corner(k)))
		if ok:
			return at
	return _road[1]


## Odran comes out (v0.11 M6): with two or more bearers alive he climbs into the litter, hidden (MissionDirector._ride_in()); else he
## walks his road on foot, LAST_GUARD more Knights behind him, with any bearer left.
func _odran_comes() -> void:
	if odran_out:
		return
	odran_out = true
	if not _alive(odran):
		return
	var o := odran as Person
	o.pace *= ODRAN_PACE
	_road_at = 1
	if bearers_standing().size() >= 2:
		riding = true
		for b in bearers_standing():
			b.pace *= ODRAN_PACE
		_ride_in(o)
		_ride_step(o, litter_at)
		return
	_set_on_foot(citadel_door)
	for k in LAST_GUARD:
		var p := Post.new()
		p.man = _knight(citadel_door)
		if crowd._fled_all:
			_keep_from_flight(p.man as Person, true)
		guards.append(p)
	_bearers_guard()


## Every living bearer not yet his guard walks behind Odran as one (v0.11 M6): the litter fallen, set down, or never climbed into.
func _bearers_guard() -> void:
	for p: Post in bearers:
		if not p.done and _alive(p.man) and not guards.has(p):
			guards.append(p)


## Odran steps out at `at` (v0.11 M6): on foot, killable (MissionDirector._ride_out()), on duty down his road.
func _set_on_foot(at: Vector2) -> void:
	riding = false
	var o := odran as Person
	if o.inside:
		_ride_out(o, _walkable(at))
	o.go_duty(_road[mini(_road_at, _road.size() - 1)])


## The litter's bearers standing (v0.11 M6). Only reads.
func bearers_standing() -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in bearers:
		if not p.done and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## The Knights walking behind Odran (v0.11 M6). Only reads.
func last_guards() -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in guards:
		if not p.done and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## The litter's middle, every frame while he rides (v0.11 M6): its bearers' places less their corners, averaged; Odran carried on it
## (MissionDirector._ride_step()).
func _carry() -> void:
	var sum := Vector2.ZERO
	var n := 0
	for k in bearers.size():
		var p: Post = bearers[k]
		if not p.done and _alive(p.man):
			sum += (p.man as Person).ground_pos - _corner(k)
			n += 1
	if n > 0:
		litter_at = sum / float(n)
	if _alive(odran):
		_ride_step(odran as Person, litter_at)


## The litter, each look (v0.11 M6): below two bearers it falls; at the Temple's steps it sets him down, its bearers his guard (plan
## decision 291); else its bearers walk on duty to the corners of a square LITTER_STEP further down his road.
func _step_litter() -> void:
	var alive := bearers_standing()
	if alive.size() < 2:
		rules.banner.emit("THE LITTER FALLS")
		_set_on_foot(litter_at)
		_bearers_guard()
		return
	if _road_at < _road.size() and litter_at.distance_to(_road[_road_at]) <= ARRIVE:
		_road_at += 1
	if _road_at >= _road.size() or litter_at.distance_to(steps_at) <= ALTAR_REACH:
		_road_at = _road.size() - 1
		_set_on_foot(litter_at)
		_bearers_guard()
		return
	var to := litter_at.move_toward(_road[_road_at], LITTER_STEP)
	for k in bearers.size():
		var p: Post = bearers[k]
		if p.done or not _alive(p.man):
			continue
		var b := p.man as Person
		p.spot = _walkable(to + _corner(k))
		if b.mind != Person.Mind.DUTY or b.anchor.distance_to(p.spot) > MOVE:
			b.go_duty(p.spot)


## Odran on foot, each look (v0.11 M6): a fright stops him a moment (plan decision 296); on duty he walks his road point by point and holds
## at the Temple's steps; back on his feet he takes his road up again; a whisper is the god's. His guards walk GUARD_GAP behind him.
func _step_on_foot() -> void:
	var o := odran as Person
	if o.inside:
		return
	if o.mind == Person.Mind.PANIC:
		o.go_duty(o.ground_pos)
		return
	var goal := _road[mini(_road_at, _road.size() - 1)]
	if o.mind == Person.Mind.DUTY:
		if _road_at < _road.size() - 1 and o.ground_pos.distance_to(goal) <= ARRIVE:
			_road_at += 1
			o.go_duty(_road[_road_at])
		elif o.anchor.distance_to(goal) > MOVE:
			o.go_duty(goal)
	elif o.mind in RECALL_MINDS:
		o.go_duty(goal)
	var dir := goal - o.ground_pos
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var side := Vector2(-dir.y, dir.x)
	var k := 0
	for p: Post in guards:
		if p.done or not _alive(p.man) or (p.man as Person).inside:
			continue
		var g := p.man as Person
		var off := 0.0 if k == 0 else SIDE_STEP * (-1.0 if k % 2 == 1 else 1.0) * float((k + 1) / 2)
		var spot := _walkable(o.ground_pos - dir * GUARD_GAP + side * off)
		if g.mind != Person.Mind.POST or g.anchor.distance_to(spot) > 0.5:
			g.send_to_post(spot, false, false)
		k += 1


## The rekindling, every frame (v0.11 M6, Decision 237): on foot, on duty and within ALTAR_REACH of the steps, its seconds run; anything
## else starts it again from RITE; finished, the flame is kindled anew.
func _step_rite(delta: float) -> void:
	var o := odran as Person
	var at_altar := not o.inside and o.mind == Person.Mind.DUTY and o.ground_pos.distance_to(steps_at) <= ALTAR_REACH
	if not at_altar:
		if rite_on:
			rite_on = false
			rite_left = RITE
			rules.banner.emit("THE REKINDLING IS BROKEN")
		return
	if not rite_on:
		rite_on = true
		rite_left = RITE
		rules.banner.emit("ODRAN REKINDLES THE FLAME")
	rite_left -= delta
	if rite_left <= 0.0:
		kindled = true


## The flame still burning at BLESSED_AT (v0.11 M6, plan decision 294): blessed, the night lost.
func _bless() -> void:
	blessed = true


## A death (v0.11 M6): noted for the Gaze; Odran's ends him -- his Knights go home.
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)
	if odran != null and is_instance_valid(odran) and e == odran and not odran_dead:
		odran_dead = true
		_spare_win = flame_out
		_knights_home()


## Odran leaving the town ends him as his death would (v0.11 M6): at once.
func _on_escaped(p: Person) -> void:
	if odran != null and is_instance_valid(odran) and p == odran and not odran_dead:
		odran_dead = true
		_knights_home()


## Every Knight still at work goes home (v0.11 M6).
func _knights_home() -> void:
	riding = false
	for list: Array in [posts, bearers, guards]:
		for p: Post in list:
			if not p.done:
				_go_home(p)


## Odran is down (v0.11 M6): killed, gone, or his body freed.
func odran_down() -> bool:
	return odran_dead or not _alive(odran)


## The stages are done (v0.11 M6): the flame out and Odran down -- StagesObjective's win.
func stages_done() -> bool:
	return flame_out and odran_down()


## Why the night is lost now (v0.11 M6): the flame kindled anew; the flame blessed; else "".
func lost_reason() -> String:
	if kindled:
		return "kindled"
	if blessed:
		return "blessed"
	return ""


## The HUD's main row (v0.11 M6): "Put out the flame 1 / 2: blessed in 2:10"; once it is out "Kill Odran", or "Kill Odran: in his litter".
func hud_line() -> String:
	if not flame_out:
		return "Put out the flame %d / %d: blessed in %s" % [razed_count(), targets.size(),
			UiTheme.clock(timeline.seconds_to("blessed") if timeline != null else 0.0)]
	return "Kill Odran: in his litter" if riding else "Kill Odran"


## The current target: the first in use and not razed, or -1 (v0.11 M6).
func current() -> int:
	for i in targets.size():
		if in_use[i] and not razed(targets[i]):
			return i
	return -1


## The next target: the first not razed and not yet in use, or -1 (v0.11 M6).
func next_target() -> int:
	for i in targets.size():
		if not razed(targets[i]) and not in_use[i]:
			return i
	return -1


## The map tags, most important first (v0.11 M6, mission spec §3). Stage one: the target in use, gold and pointed at ("- GUARDED",
## "- SET IT ALIGHT", or "- BURNING n" orange); the next one, grey and pointed at, with its sooner time, or once fallen "- DOWN" and it
## (M5's wording: "DOWN, COUNTS AT" dropped a plate); KNIGHT on each Knight on guard, a red diamond on a relief walking in, a small red
## mark on one away. Stage two: Odran in the Citadel (grey, pointed at, his chain's seconds once the flame is out), in his litter, on
## foot or rekindling (gold, pointed at); BEARER on each bearer and KNIGHT on his guards, red and pointed at (moving targets); the ALTAR
## at the steps, orange, pointed at, once he is out.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if lost_reason() != "" or stages_done():
		return out
	if not flame_out:
		var cur := current()
		if cur >= 0 and is_instance_valid(targets[cur]) and not targets[cur].destroyed:
			var s := targets[cur]
			var label := "%s - SET IT ALIGHT" % NAMES[cur]
			var col := MARK_TARGET
			if not guards_at(cur).is_empty():
				label = "%s - GUARDED" % NAMES[cur]
			elif burning(s):
				label = "%s - BURNING %d" % [NAMES[cur], ceili(maxf(_spoil_for(s) - burned(s), 0.0))]
				col = MARK_BURNING
			out.append(MapTag.place(s.center(), col, label, s.height, true))
		var n := next_target()
		if n >= 0 and is_instance_valid(targets[n]):
			var s := targets[n]
			var when := UiTheme.clock(stage_due(n))
			var label := ("%s - DOWN %s" % [NAMES[n], when]) if s.destroyed else ("%s - %s %s" % [NAMES[n], NEXT_WORDS[n], when])
			out.append(MapTag.place(s.center(), MARK_NOT_YET, label, 0.0 if s.destroyed else s.height, true))
	if not odran_out:
		var words := "ODRAN - COMES OUT IN %d" % ceili(timeline.seconds_to("odran")) if flame_out and timeline != null else "ODRAN - IN THE CITADEL"
		out.append(MapTag.place(citadel_door, MARK_NOT_YET, words, 0.0, true))
	elif riding:
		out.append(MapTag.person(litter_at, MARK_TARGET, "ODRAN - IN HIS LITTER", true))
	elif _alive(odran) and not (odran as Person).inside:
		out.append(MapTag.person((odran as Person).ground_pos, MARK_TARGET, "ODRAN - REKINDLING %d" % ceili(rite_left) if rite_on else "ODRAN", true))
	if odran_out:
		out.append(MapTag.place(steps_at, MARK_PLACE, "ALTAR", 0.0, true))
	if flame_out and (riding or not odran_out):
		for b in bearers_standing():
			out.append(MapTag.person(b.ground_pos, MARK_WATCHED, "BEARER", true))
	for g in last_guards():
		out.append(MapTag.person(g.ground_pos, MARK_WATCHED, "KNIGHT", true))
	if not flame_out:
		for p: Post in posts:
			if p.done or not _alive(p.man) or (p.man as Person).inside:
				continue
			var k := p.man as Person
			if _on_guard(p):
				out.append(MapTag.person(k.ground_pos, MARK_WATCHED, "KNIGHT"))
			elif p.relief:
				out.append(MapTag.person(k.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(k.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M6, plan decision 303): stage two "coming", "litter", "rite", "on_foot"; stage one "guarded", "burning", "open"
## for the target in use, "not_yet" for the next one fallen or within WORK_AHEAD of its time; else "".
func hint_phase() -> String:
	if lost_reason() != "" or stages_done():
		return ""
	if flame_out:
		if not odran_out:
			return "coming"
		if riding:
			return "litter"
		return "rite" if rite_on else "on_foot"
	var cur := current()
	if cur >= 0:
		if not guards_at(cur).is_empty():
			return "guarded"
		return "burning" if burning(targets[cur]) else "open"
	var n := next_target()
	if n >= 0 and (_down(n) or stage_due(n) - _clock <= WORK_AHEAD):
		return "not_yet"
	return ""


## The seconds the hint counts down (v0.11 M6): Odran's chain in "coming", the rite's in "rite"; else 0.
func hint_seconds() -> float:
	match hint_phase():
		"coming":
			return timeline.seconds_to("odran") if timeline != null else 0.0
		"rite":
			return maxf(rite_left, 0.0)
	return 0.0


## The tour (v0.11 M6, mission spec §3): the oil-house, the Temple, the Citadel.
func tour() -> Array:
	var out := []
	if oil_house != null:
		out.append([oil_house.center(), "The oil-house. Its Knights guard it. It feeds the flame from %s: burn it." % UiTheme.clock(float(STAGE_AT[0]))])
	if temple != null:
		out.append([temple.center(), "The Great Temple. The flame blazes here by %s. Burn it down to put the flame out." % UiTheme.clock(float(STAGE_AT[1]))])
	out.append([citadel_door, "The Citadel. High Priest Odran waits here. Once the flame is out he comes to rekindle it: kill him."])
	return out


## What the results show (v0.11 M6): targets razed, the flame out, Odran down, the losses, the reliefs, the Gaze.
func report() -> Dictionary:
	return {"razed": razed_count(), "flame_out": flame_out, "odran_dead": odran_down(), "kindled": kindled, "blessed": blessed,
		"reliefs": reliefs, "gaze": gaze.value}


## Lets go of the kills, the crowd's exits, the targets on the engineers' list, then the Raze type's (every seal, the timeline) (v0.11 M6).
## Safe to call twice.
func teardown() -> void:
	_unhook_kills(_on_killed)
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s in targets:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
	super()
