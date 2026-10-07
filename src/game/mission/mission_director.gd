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

## Minds a Faithful does not see from (v0.10): the god's own holds.
const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]


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


## Virtual (v0.10 M6, spec §5): the stops of the camera's tour before the clock starts, as [ground point, caption] pairs;
## none by default, and then the intro is the sweep. A stop with no one to show is left out.
func tour() -> Array:
	return []


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


## Whether `p` still stands in the world: neither freed nor dead.
static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


## Sorts the living citizens a Night 2 director may cast, into `clergy` and `lay`, in the crowd's order. Left out are the
## bell's keeper, anyone inside, and (from `lay`) the engineers and the bellkeeper.
func _sort_citizens(clergy: Array[Person], lay: Array[Person]) -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper:
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
	if _carrying(seer):
		return
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
