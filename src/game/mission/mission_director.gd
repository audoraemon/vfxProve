class_name MissionDirector
extends RefCounted
## A mission's own actors and setup (v0.08): Rules steps it every frame of the mission, just before the objectives are
## checked, so it pauses and freezes with the mission. The Warning's runs the omen, the watchman and the relay
## (WarningDirector); Last Judgement's only points out the Citadel and the town's ways out (LastJudgementDirector).

var rules: Rules
var crowd: Crowd
var town: Town
## The battlefield's effect context, for the director's own effects (null in tests).
var ctx: FxContext
## The night this act belongs to (v0.09), or null for a single mission.
var night: NightState
## The act's timed events (v0.09), or null.
var timeline: EventTimeline
## Halcyon's Gaze (v0.10), for the campaign's Night 2 missions; null elsewhere.
var gaze: GazeMeter
## Halcyon's Faithful (v0.10), for the campaign's Night 2 missions: the people the director chose with _make_faithful().
var faithful: Array[Person] = []
## Reports of the god at work on their way to the Temple (v0.10: Mira's House, the Vigil Flame), and how many began.
var reports: Array[TempleReport] = []
var reports_started := 0
## How much slower the director's timeline runs (v0.11 M1, spec §7.2): MissionDef.stretch, set before setup(); 1 off the
## board.
var stretch := 1.0
## People the night has set aside (v0.11 M1, spec §5): every wisher and wish target, and the runners of the stars already
## falling. A director that appoints someone mid-night skips them (StarfallDirector's later watchmen). Empty off the board.
var reserved: Array[Person] = []

## Buildings the night has set aside (v0.11 M2): every wish's target building (Wish.places()). A director choosing a building
## for its own use -- a granary, a debtor's house -- skips them (_house_near()). Empty off the board.
var reserved_places: Array[Structure] = []

## The town was evacuating at this director's last look (v0.11 M3 final review): see _evacuation_began().
var _saw_evacuation := false

## Minds a Faithful does not see from (v0.10): the god's own holds.
const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]

## The minds one of a director's own people is called back to his place from (v0.11 M4): back on his feet -- going about his day,
## recovering, looking on or regrouping. WarningDirector.RESUMABLE's four, named here so the base names no subclass.
const RECALL_MINDS := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## How many of the lay citizens nearest a post _lay_reaching() weighs (v0.11 M4, Market Panic's RELIEF_PICKS).
const REACH_PICKS := 12


func setup(r: Rules, c: Crowd, t: Town, x: FxContext, n: NightState = null) -> MissionDirector:
	rules = r
	crowd = c
	town = t
	ctx = x
	night = n
	_begin()
	return self


## Virtual: the mission's setup, once the town and its people exist.
func _begin() -> void:
	pass


## Virtual: one step of the mission.
func step(_delta: float) -> void:
	pass


## What the HUD points out on the map (v0.10 M6, spec §2.2): MapTags, the most important first -- a label that would
## overlap one before it is left out. None by default. Only reads: it changes nothing and draws no random numbers.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	return out


## Virtual (v0.10 M6, spec §3): the phase whose how-to-win line the HUD shows (MissionHints), "" for the mission's own.
func hint_phase() -> String:
	return ""


## Virtual (v0.11 M5, the final review): the HUD's words for a cast refused for `reason` from `slot`, in place of its own plain ones
## ("" keeps them): The Sermon's "THEY HEAR ONLY HIM". Rules.refused_who names the one a refused whisper was meant for.
func refused_words(_slot: int, _reason: String) -> String:
	return ""


## Virtual (v0.11 M4): the seconds a phase's line counts down, put in place of MissionHints.SECONDS (The Heretic Hunt's captain
## coming out); 0 by default, for the lines that count nothing.
func hint_seconds() -> float:
	return 0.0


## Virtual (v0.10 M6, spec §5): the stops of the camera's tour before the clock starts, as [ground point, caption] pairs;
## none by default, and then the intro is the sweep. A stop with no one to show is left out.
func tour() -> Array:
	return []


## Virtual (v0.11 M3 final review): how many of the night's warnings are stopped, and how many it has in all, for StarsObjective
## (the board Warning's stars, The Bell-Ringers' posts). None by default.
func stars_stopped() -> int:
	return 0


## Virtual (v0.11 M3 final review): see stars_stopped().
func stars_total() -> int:
	return 0


## Virtual (v0.11 M6, mission spec §6.5): the night's stages are done -- StagesObjective's win (The Heart of Faith: the flame out and its
## High Priest dead). False by default.
func stages_done() -> bool:
	return false


## Virtual (v0.11 M6): why the night is lost now, "" while it is not. RazeDirector, EscortDirector, HuntDirector, AssassinateDirector
## and their subclasses override it as before; named here so StagesObjective reads any director (plan decision 272).
func lost_reason() -> String:
	return ""


## Virtual (v0.11 M6): the HUD's line for the main objective in place of its own, "" for its own. Named here for StagesObjective, as
## lost_reason() is.
func hud_line() -> String:
	return ""


## Virtual (v0.11.1, spec §7.3): a thing of this director's own that Blight can ruin within BlightFx.REACH of `at` -- an unguarded
## standard, an unguarded mirror -- as the ground point Blight rots (Vector2.INF for none, the default). Only reads. BlightFx asks
## the director before it looks for a structure.
func blight_target(_at: Vector2) -> Vector2:
	return Vector2.INF


## Virtual (v0.11.1): whether Blight can ruin this director's thing at `at` (blight_target()) -- false for a guarded standard or
## mirror (spec §7.3, Decision 29: no route round the opposition). True by default.
func blight_takes(_at: Vector2) -> bool:
	return true


## Virtual (v0.11.1): Blight landed on this director's thing at `at` (blight_target()). True when it took: the base then adds the
## town's alarm (Crowd.BLIGHT_ALARM) that env.blight() adds for a structure (I12). A guarded one (blight_takes() false) costs no
## alarm and returns false -- only its banner (blight_words()) shows. Subclasses call `super(at)` and break their standard or cloud
## their mirror only if it returned true.
func blighted(at: Vector2) -> bool:
	if not blight_takes(at):
		return false
	if crowd != null:
		crowd.add_alarm(Crowd.BLIGHT_ALARM)
	return true


## Virtual (v0.11.1): the banner for a Blight that landed on this director's thing at `at`, taken or not ("BLIGHT - THE STANDARD ROTS",
## "THEIR GUARD KEEPS IT"). "" says nothing; Mission.blight_banner() is for structures only and is not reached on this path.
func blight_words(_at: Vector2) -> String:
	return ""


## Virtual (v0.11.2, spec 4.2): the bell tolled and the Lantern turned (LanternWatch.on_toll(), after it has lit its beam and added a gaze
## night's GAZE_TOLL). A night's director that has something to do at the toll does it here (The Warning's messenger runs for the Temple).
## Nothing by default.
func on_toll() -> void:
	pass


## Virtual (v0.11.2, spec 4.6): `p` is one of this director's own heralds -- a warning's messenger who runs for the Temple after the toll --
## so the Lantern does not make a second Herald of him when he is the keeper who rang. False by default.
func claims_herald(_p: Person) -> bool:
	return false


## Virtual (v0.11.2, spec 4.5): `p` is one of this director's own actors on an errand the Lantern-Bearer must not take him from (Mira's
## Venn, the Sermon's preacher, a warden, a contact). A report's carrier and a Herald are found by the Lantern itself. False by default.
func busy(_p: Person) -> bool:
	return false


## The walkable point at the Temple's door, 0.6 south of its south face (v0.11.2): where a Herald runs to and the Lantern-Bearer sets out
## from. Named for the Lantern because several directors keep a `temple_door` variable of their own (Mira's, the Vigil Flame, Broken
## Lanterns, Exodus), which a method of that name would clash with; it is the same point.
func lantern_door() -> Vector2:
	return lantern_door_in(crowd)


## lantern_door() for a town with no director (LanternWatch on a night whose mission has none).
static func lantern_door_in(c: Crowd) -> Vector2:
	var g := Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6)
	var w := c._grid.nearest_walkable(g) if c != null and c._grid != null else g
	return w if w != Vector2.INF else g


## Virtual (v0.11.2, spec 4.6): one of this director's warnings runs for the Temple as a Herald and has been neither stopped nor got in
## (WarningDirector.herald_open(); Starfall's and The Bell-Ringers' ask each of theirs). LanternWatch.herald_running() reads it, so a
## night's main objective is not DONE while one runs. False by default.
func herald_open() -> bool:
	return false


## Virtual (v0.11.2, spec 4.5): the soonest of this director's Heralds reaches the Temple in this many MISSION seconds (the remaining real
## walk times the clock's rate), INF for none. The strip's `The Herald reaches the Temple` row reads it.
func herald_eta() -> float:
	return INF


## What the director adds to the results (The Warning's "solved_by").
func report() -> Dictionary:
	return {}


## Virtual: what this act hands the next one, written into the night before the director is let go (v0.09).
func carry(_n: NightState) -> void:
	pass


## Virtual: let go of the world's signals.
func teardown() -> void:
	pass


## Cael speaks (v0.10 M5, spec §5.2): his line for `event` in this mission (CampaignText.CAEL_LINES), shown under the
## banners; nothing when he has none for it.
func _say(event: String) -> void:
	if rules == null or rules.mission == null:
		return
	var text := CampaignText.cael_line(rules.mission.id, event)
	if text != "":
		rules.subtitle.emit(text)


## A point of walkable ground at or near `g` (`g` itself when the town has no walk grid, or none is free).
func _walkable(g: Vector2) -> Vector2:
	var w := crowd._grid.nearest_walkable(g) if crowd._grid != null else g
	return w if w != Vector2.INF else g


## A fresh timeline for the director's events (v0.11 M1): stretched by `stretch`, so a board mission's windows fall inside
## its longer night. Off the board it is EventTimeline.new()'s own.
func _new_timeline() -> EventTimeline:
	var tl := EventTimeline.new().stretched(stretch)
	tl.clock = rules  # v0.11.2: the timeline runs on the mission clock's rate (null rules: rate 1)
	return tl


## `delta` real seconds as mission seconds (v0.11.2): what a Lantern night's director adds to a schedule clock of its own.
func mission_delta(delta: float) -> float:
	return delta * rules.clock_rate if is_instance_valid(rules) else delta


## `p` may be gathered or appointed by this director (v0.11 M2): standing (_alive()), out of doors and not reserved. A Variant,
## as `p` may be a body already freed after its death fade.
func _eligible(p: Variant) -> bool:
	return _alive(p) and not (p as Person).inside and not reserved.has(p)


## The `count` free soldiers nearest `at`, nearest first (v0.11 M2): eligible, of no corps, none of `exclude`; fewer when the
## town has fewer.
func _free_soldiers(at: Vector2, count: int, exclude: Array = []) -> Array[Person]:
	var pool: Array[Person] = []
	for s in crowd.soldiers:
		if _eligible(s) and s.corps == Person.Corps.NONE and not exclude.has(s):
			pool.append(s)
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	var out: Array[Person] = []
	out.assign(pool.slice(0, count))
	return out


## The `count` lay citizens nearest `at`, nearest first (v0.11 M2): eligible, of no faith, of no role in Wish.NOT_LAY (the
## town's responders and the directors' own people), none of `exclude`.
func _lay_near(at: Vector2, count: int, exclude: Array = []) -> Array[Person]:
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if _eligible(p) and p.profile != null and p.profile.faith == CitizenProfile.Faith.NONE and not p.profile.role in Wish.NOT_LAY \
				and not exclude.has(p):
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	var out: Array[Person] = []
	out.assign(pool.slice(0, count))
	return out


## The eligible citizen of `role` nearest `at`, none of `exclude` (v0.11 M2: the tax collector, a resident; the acolyte, a
## cleric); null for none.
func _citizen_near(at: Vector2, role: CitizenProfile.Role, exclude: Array = []) -> Person:
	var best: Person = null
	for p in crowd.citizens:
		if _eligible(p) and p.profile != null and p.profile.role == role and not exclude.has(p) \
				and (best == null or p.ground_pos.distance_squared_to(at) < best.ground_pos.distance_squared_to(at)):
			best = p
	return best


## The standing dwelling nearest `at` (v0.11 M2: RuinWish.fits(s, "house")), not reserved and none of `exclude`; null for none.
func _house_near(at: Vector2, exclude: Array = []) -> Structure:
	var best: Structure = null
	for s: Structure in town._built:
		if not is_instance_valid(s) or s.destroyed or not RuinWish.fits(s, "house") or reserved_places.has(s) or exclude.has(s):
			continue
		if best == null or s.center().distance_squared_to(at) < best.center().distance_squared_to(at):
			best = s
	return best


## A building's front (v0.11 M2): free ground just off its +y face, where Mira's door is.
func _front_of(s: Structure) -> Vector2:
	return _walkable(s.center() + Vector2(0.0, s.footprint.size.y * 0.5 + 0.5))


## A door of `s` someone at `from` can walk to (v0.11 M2; moved up from AssassinateDirector in v0.11 M3 for The Bell-Ringers' posts):
## its front (_front_of()), else its back, else a side -- the first with a route from `from`; Vector2.INF for none (a house
## walled in by its neighbours, whose front is a closed yard).
func _open_door(s: Structure, from: Vector2) -> Vector2:
	var half := s.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(s.center() + off)
		if crowd._grid == null or not crowd._grid.path(from, door).is_empty():
			return door
	return Vector2.INF


## `p` goes indoors at `s` (v0.11 M2, as Mira's readers do): hidden, out of the field and untouchable until brought out. With
## `s` null (a Citadel's gate), where `p` stands.
func _take_inside(p: Person, s: Structure) -> void:
	p.inside = true
	p.visible = false
	if s != null:
		p.ground_pos = s.center()
	crowd._field.remove(p)


## `p` comes out at `at` (v0.11 M2), back in the field.
func _bring_out(p: Person, at: Vector2) -> void:
	p.inside = false
	p.visible = true
	p.ground_pos = at
	crowd._field.add(p)


## `p` set down at `at` before the first frame, with whatever walk its routine gave it dropped, and kept there (v0.11 M2, the
## Procession's way with its Prince).
func _set_down(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.anchor = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.last_place = RoutineManager.Place.LEISURE
	p.stay_left = 1000.0


## The `i`th of `n` places on a ring of `radius` round `center`, on walkable ground; `turn` offsets the ring (v0.11 M2, the
## Procession's ring).
func _ring_spot(center: Vector2, radius: float, i: int, n: int, turn := 0.0) -> Vector2:
	return _walkable(center + Vector2.from_angle(turn + TAU * float(i) / float(maxi(n, 1))) * radius)


## `v` goes back to `at` on duty (v0.11 M4, M3's duty-recall idiom, "abstract at a fifth"): when he stands out of doors back on his
## feet (RECALL_MINDS), or on duty somewhere else. One frightened, held by the god, fighting or indoors is left be. First he is kept
## from the town's flight, by the one shared rule (_keep_from_flight(): `evacuating`, true at the director's first look after the
## evacuation began -- _evacuation_began() -- calls back one it sent running; a whisper it found him under ends with him on his
## feet), so a held man is never lost to the evacuation. A Variant: he may be a body freed after its death fade. Spoiled Harvest,
## Market Panic and The Informer keep their own copies (Decision 89).
func _recall_to(v: Variant, at: Vector2, evacuating := false) -> void:
	if not _alive(v):
		return
	var p := v as Person
	if p.inside:
		return
	_keep_from_flight(p, evacuating)
	if p.soldier and p.held_by_god():
		return  # a soldier lured, whispered or confused (v0.11.1) is not taken back: the hold ends and he goes to his place himself
	if p.mind in RECALL_MINDS or (p.mind == Person.Mind.DUTY and p.anchor.distance_to(at) > 0.3):
		p.go_duty(at)


## The lay citizen nearest `at` with a way on foot to it (v0.11 M4: a relief, by Market Panic's rule -- one shut in a yard behind
## the houses would stand there for good), of the REACH_PICKS nearest, none of `exclude`; null for none.
func _lay_reaching(at: Vector2, exclude: Array = []) -> Person:
	for p in _lay_near(at, REACH_PICKS, exclude):
		if crowd._grid == null or not crowd._grid.path(p.ground_pos, at).is_empty():
			return p
	return null


## A Lantern Knight added at `at` (v0.11 M5, the final review: hoisted from The Bishop and Broken Lanterns for M6): a soldier of corps
## KNIGHT with three times a soldier's health, on walkable ground at or near `at`, and at his post there unless `post` is false (Broken
## Lanterns sends its Knights to their shrines itself).
func _knight(at: Vector2, post := true) -> Person:
	var k := crowd.add_soldier(_walkable(at))
	k.corps = Person.Corps.KNIGHT
	k.health = Person.HEALTH_KNIGHT
	if post:
		k.send_to_post(k.ground_pos)
	return k


## `p` rides hidden (v0.11 M5, The Relic Run's ride named for M6 by the final review): put on duty where he stands first -- a man
## taken out of the field must not be left to his own mind -- then indoors at no building, carried by _ride_step() each frame. The
## caller's _hold_all() keeps covering him while he rides.
func _ride_in(p: Person) -> void:
	p.go_duty(p.ground_pos)
	_take_inside(p, null)


## The hidden rider `p` is carried to `at` (v0.11 M5): called each frame he rides.
func _ride_step(p: Person, at: Vector2) -> void:
	p.ground_pos = at


## The hidden rider `p` slips out at `at` (v0.11 M5): back in the field and kept from the town's flight, as an evacuation may have
## begun while he rode; the caller then gives him his duty.
func _ride_out(p: Person, at: Vector2) -> void:
	_bring_out(p, at)
	_keep_from_flight(p, true)


## Whether `p` still stands in the world: neither freed nor dead.
static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


## Sorts the living citizens a Night 2 director may cast, into `clergy` and `lay`, in the crowd's order. Left out are the
## bell's keeper, anyone inside, anyone reserved (v0.11 M1: a wisher or a wish target), and (from `lay`) the engineers and the
## bellkeeper.
func _sort_citizens(clergy: Array[Person], lay: Array[Person]) -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper or reserved.has(p):
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			clergy.append(p)
		elif not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)


## Makes `p` one of Halcyon's Faithful.
func _make_faithful(p: Person) -> void:
	p.profile.faith = CitizenProfile.Faith.FAITHFUL
	faithful.append(p)


## Makes `count` of `pool` Faithful, spread evenly through it by stride (the middle of each stretch, from the front).
func _spread_faithful(pool: Array[Person], count: int) -> void:
	if pool.is_empty() or count <= 0:
		return
	var stride := maxi(1, pool.size() / count)
	var i := stride / 2
	var added := 0
	while i < pool.size() and added < count:
		_make_faithful(pool[i])
		added += 1
		i += stride


## Makes every cleric, and `count` of the other lay citizens spread through the rest, Halcyon's Faithful (v0.10: Broken
## Lanterns, the Vigil Flame).
func _choose_faithful(count: int) -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in clergy:
		_make_faithful(p)
	_spread_faithful(lay, count)


## The Vigil's walkers (v0.10): sorts `pool` in place, the clergy first and each nearest the Temple's door `door` first,
## and returns the first three: the flame-bearer, then his two acolytes (fewer if the pool is short, none if empty).
func _vigil_walkers(pool: Array[Person], door: Vector2) -> Array[Person]:
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		var ca := a.profile.role == CitizenProfile.Role.CLERGY
		var cb := b.profile.role == CitizenProfile.Role.CLERGY
		if ca != cb:
			return ca
		return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	var out: Array[Person] = []
	out.assign(pool.slice(0, 3))
	return out


## Lets go of `handler` as the field's enemy_killed listener, if it is still one (for teardown()).
func _unhook_kills(handler: Callable) -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(handler):
		crowd._field.enemy_killed.disconnect(handler)


## The nearest Faithful within `reach` of `at` who is out in the open, alive, not held by the god and not `exclude`
## (v0.10: who sees what the god does); else null.
func faithful_seeing(at: Vector2, reach: float, exclude: Variant = null) -> Person:
	var best: Person = null
	for f in faithful:
		if _sees(f, at, reach, exclude) and (best == null or f.ground_pos.distance_to(at) < best.ground_pos.distance_to(at)):
			best = f
	return best


## Every Faithful who would see `at` from within `reach`, as faithful_seeing() judges, but `exclude`, in the order of
## `faithful` (v0.10 M6: the watchers the HUD marks red).
func watchers(at: Vector2, reach: float, exclude: Variant = null) -> Array[Person]:
	var out: Array[Person] = []
	for f in faithful:
		if _sees(f, at, reach, exclude):
			out.append(f)
	return out


## `f` would see `at`: alive, out in the open, not held by the god, not `exclude`, and within `reach` (v0.10 M6). `f` and
## `exclude` are Variants because either may be a body already freed after its death fade, and a freed person passed on
## as a Person aborts the call.
func _sees(f: Variant, at: Vector2, reach: float, exclude: Variant) -> bool:
	return _alive(f) and not f.inside and not (f.mind in BLIND) and f != exclude and f.ground_pos.distance_to(at) <= reach


## `seer` runs to the Temple's door `door` to report what they saw, unless already carrying a report.
func _report(seer: Person, door: Vector2) -> void:
	if _carrying(seer) or (rules != null and rules.lantern != null and rules.lantern.has_errand(seer)):
		return  # (v0.11.2: nor one carrying the Lantern's flame, or escorting it)
	reports.append(TempleReport.new(seer, door))
	reports_started += 1
	rules.banner.emit("A FAITHFUL RUNS TO THE TEMPLE")


## Each report runs on; one delivered fills the Gaze. Reports delivered or ended are let go.
func _step_reports(delta: float) -> void:
	for r in reports:
		r.step(delta, crowd)
		if r.delivered:
			gaze.fill()
	reports.assign(reports.filter(func(r: TempleReport) -> bool: return r.is_open()))


## `p` is carrying a report to the Temple.
func _carrying(p: Person) -> bool:
	for r in reports:
		if r.carrier == p:
			return true
	return false


## True once, at the director's first look after the town began to evacuate (v0.11 M3 final review): a director keeping its own
## people at their places calls back then the ones the evacuation sent running (_keep_from_flight()).
func _evacuation_began() -> bool:
	if _saw_evacuation or crowd == null or not crowd._fled_all:
		return false
	_saw_evacuation = true
	return true


## `p`, one of the director's own people kept at his place for the night, is kept out of the town's flight (v0.11 M3 final review):
## a whisper the evacuation found him under (Person.whisper_resume_flee()) ends with him back on his feet, not running for the
## gates; and, at the first look after the evacuation began (`evacuating`), one it sent running -- he was going about his day,
## recovering or looking on, and Person.go_duty() refuses a fleeing man -- stops, back on his feet, for the caller to put on duty
## again, as Mind Whisper takes a fleeing man (Person.whisper()). A god's own flight (Rewrite Priority's "escape") later is let be.
static func _keep_from_flight(p: Person, evacuating: bool) -> void:
	if p.mind == Person.Mind.WHISPERED:
		p._whisper_fled = false
	elif evacuating and p.mind == Person.Mind.FLEE:
		p.release_from_queue()
		p.passing_gate = null
		p.mind = Person.Mind.CALM


## The one rule for a Tier 3 director's held people (v0.11 M4, the final review's ruling; The Crown's Bread, The Prisoner and the
## Hunt type use it): each living one of `people`, indoors or out, is kept out of the town's flight (_keep_from_flight(), `evacuating`
## at the first look after the evacuation began), and the flight a false calm owes him is let go (Person._reassured_fled: a hold past
## fear puts off an evacuation's flee() until it wears off, when he would run for the gates after that one look had passed). The
## caller then puts each on duty again by its own rules -- one away from his post when the evacuation begins is recalled at once.
## Untyped: any may be a body freed after its death fade. M2's and M3's directors keep their own ways (their references are exact).
static func _hold_all(people: Array, evacuating: bool) -> void:
	for v: Variant in people:
		if _alive(v):
			_keep_from_flight(v as Person, evacuating)
			(v as Person)._reassured_fled = false
