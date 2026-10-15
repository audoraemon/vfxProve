extends RefCounted
## v0.11 M5 the groundwork for Tier 4's new missions, each shared change shown to keep today's path when left alone (review focus 1):
## Tier 4's frame; AssassinateDirector's guard hooks (_appoint_guards(), _tends()); MirasHouseDirector.lost_reason() and
## BelieversObjective's label and reasons; VigilFlameDirector.hud_line() and FlameObjective's label and reasons; TempleReport.skip;
## RazeDirector.hud_line() read by RazeObjective.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


## The Tax Collector with a spy on its guard hooks (v0.11 M5): each records what it was handed, then does the base's work.
class GuardSpy:
	extends TaxCollectorDirector
	var appointed: Array = []
	var tended := 0

	func _appoint_guards(q: Quarry, taken: Array) -> Array[Person]:
		appointed.append([q.index, taken.size()])
		return super(q, taken)

	func _tends(p: Person) -> bool:
		tended += 1
		return super(p)


## The Tax Collector whose guards no one tends (v0.11 M5): _tends() says no, so none is ever sent to a place.
class Untended:
	extends TaxCollectorDirector

	func _tends(_p: Person) -> bool:
		return false


## Mira's House with a loss of its own (v0.11 M5): lost_reason() gives `why`.
class Lost:
	extends MirasHouseDirector
	var why := ""

	func lost_reason() -> String:
		return why


## The Vigil Flame with a HUD line of its own (v0.11 M5).
class Lined:
	extends VigilFlameDirector
	var line := ""

	func hud_line() -> String:
		return line


## Spoiled Harvest with a HUD line of its own (v0.11 M5).
class RazeLined:
	extends HarvestDirector
	var line := ""

	func hud_line() -> String:
		return line


static func run(t) -> void:
	_frame(t)
	_guard_hooks(t)
	_believers(t)
	_flame(t)
	_skip(t)
	_raze_line(t)


static func _frame(t) -> void:
	var m := MissionBook._tier4("x", "X", PackedStringArray(["a", "b"]))
	t.check(m.tier == 4 and m.slots == 5 and m.dp_capacity == 13 and is_equal_approx(m.clock, 390.0) and m.profile == ""
		and m.tier_floor == 4 and not m.chooses_difficulty()
		and m.response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "God-Resistant" and m.intro_banner == "X"
		and m.bonuses().is_empty() and m.pool.is_empty() and is_equal_approx(m.stretch, 1.0),
		"a Tier 4 mission's numbers: 6:30, 5 / 13, a God-Resistant town whatever is chosen, no bonuses")
	var cam := Vector2(2.0, -3.0)
	var band := Iso.screen_to_ground((Vector2(100.0, 150.0) - Kit.VIEW * 0.5) / Mission.PLAY_ZOOM + Iso.ground_to_screen(cam))
	t.check(Kit.STACK.size == Vector2(240.0, 165.0) and Kit.clear_of_stack(band, cam) and not Kit.clear_of_stack(band, cam, Kit.STACK)
		and Kit.clear_of_stack(cam, cam, Kit.STACK), "the kit offers the real HUD stack (240 x 165) beside its old dead zone for camera checks")
	t.check(MissionBook.BISHOP == "bishop" and MissionBook.ARMOURY == "armoury" and MissionBook.SERMON == "sermon"
		and MissionBook.RELIC_RUN == "relic_run", "Reckoning's four new ids")


## Each target's guards as indices into the town's soldiers (v0.11 M5 tests).
static func _guard_ix(s: Dictionary) -> Array:
	var out := []
	for q: AssassinateDirector.Quarry in (s.d as AssassinateDirector).quarries:
		var ix := []
		for v: Variant in q.guards:
			ix.append((s.crowd as Crowd).soldiers.find(v))
		out.append(ix)
	return out


static func _guard_hooks(t) -> void:
	var plain := Kit.world(MissionBook.tax_collector())
	var want := _guard_ix(plain)
	Kit.done(plain)
	var s := Kit.world(MissionBook.tax_collector(), GuardSpy.new())
	var d: GuardSpy = s.d
	var calls := []
	var taken := 0
	for q: AssassinateDirector.Quarry in d.quarries:
		calls.append([q.index, taken])
		taken += q.guards.size()
	t.check(d.appointed == calls and _guard_ix(s) == want and taken > 0,
		"_appoint_guards() is handed each target and the guards taken before him, and appoints the soldiers the old code did (%s)" % [d.appointed])
	var sent := false
	for q: AssassinateDirector.Quarry in d.quarries:
		for v: Variant in q.guards:
			sent = sent or (v as Person).anchor.distance_to((v as Person).post) > 0.01
	t.check(d.tended > 0 and sent, "_tends() is asked for each guard, and by default they are sent to their places")
	Kit.done(s)
	var u := Kit.world(MissionBook.tax_collector(), Untended.new())
	Kit.run_for(u, 1.0)
	var kept := true
	for q: AssassinateDirector.Quarry in (u.d as AssassinateDirector).quarries:
		for v: Variant in q.guards:
			kept = kept and (v as Person).anchor.distance_to((v as Person).post) < 0.01
	t.check(kept, "a guard _tends() refuses is never sent (The Bishop's Knights are tended by its own rule)")
	Kit.done(u)


static func _believers(t) -> void:
	var s := Kit.world(MissionBook.miras_house())
	var o := BelieversObjective.new()
	t.check(o.label == "Believers" and o.reason == "believers" and o.hud_text(s.rules) == "Believers 0 / 4"
		and o.check(s.rules) == Objective.Status.PENDING and (s.d as MirasHouseDirector).lost_reason() == "",
		"BelieversObjective by default: Mira's House's label, reason and line; no loss of the director's")
	(s.rules as Rules).time_left = 0.0
	t.check(o.check(s.rules) == Objective.Status.FAILED and o.reason == "few", "dawn with too few: \"few\", as before")
	Kit.done(s)
	var l := Kit.world(MissionBook.miras_house(), Lost.new())
	var d: Lost = l.d
	var c := BelieversObjective.new("Turn the crowd", "sermon", "sermon_over")
	t.check(c.label == "Turn the crowd" and c.reason == "sermon" and c.hud_text(l.rules) == "Turn the crowd 0 / 4"
		and c.check(l.rules) == Objective.Status.PENDING, "given its label and reasons")
	d.why = "flock"
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "flock", "the director's own loss fails it at once, with its reason")
	d.why = ""
	(l.rules as Rules).time_left = 0.0
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "sermon_over", "dawn with too few: its own reason")
	Kit.done(l)


static func _flame(t) -> void:
	var s := Kit.world(MissionBook.vigil_flame())
	var d: VigilFlameDirector = s.d
	var o := FlameObjective.new()
	t.check(o.label == "The flame" and o.reason == "flame" and d.hud_line() == "" and o.hud_text(s.rules) == "The flame: in its lantern",
		"FlameObjective by default: The Vigil Flame's label, reason and line")
	d.kept = true
	t.check(o.check(s.rules) == Objective.Status.FAILED and o.reason == "kept", "kept: \"kept\", as before")
	Kit.done(s)
	var l := Kit.world(MissionBook.vigil_flame(), Lined.new())
	var ld: Lined = l.d
	var c := FlameObjective.new("The relic", "relic", "relic_kept", "pip")
	ld.line = "The relic: in its cart"
	t.check(c.label == "The relic" and c.reason == "relic" and c.hud_text(l.rules) == "The relic: in its cart",
		"the director's HUD line in place of its own")
	ld.no_wren = true
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "pip", "the boy lost: its own reason")
	ld.no_wren = false
	ld.kept = true
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "relic_kept", "kept: its own reason")
	ld.kept = false
	ld.home = true
	t.check(c.check(l.rules) == Objective.Status.DONE and c.reason == "relic", "home: its own reason")
	Kit.done(l)


## Everyone but `keep` within `reach` of `at` moved well away (v0.11 M5 tests; test_temple_report's rule).
static func _clear_round(crowd: Crowd, at: Vector2, reach: float, keep: Array) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + (p.ground_pos - at).normalized() * (reach + 6.0) if p.ground_pos != at \
					else at + Vector2(reach + 6.0, 0.0)


## A report carried by `c` whose carrier is killed with `near` fleeing 0.8 from him and `far` calm 1.5 from him (v0.11 M5 tests);
## `skip` set on it when given. The report, judged (a crowd step settles the kill first, as Crowd._settle_doom() does).
static func _relay(crowd: Crowd, c: Person, near: Person, far: Person, skip: Callable) -> TempleReport:
	var r := TempleReport.new(c, Vector2(0.8, -5.0))
	if skip.is_valid():
		r.skip = skip
	_clear_round(crowd, c.ground_pos, Crowd.DOOM_WITNESS + 1.0, [c])
	near.ground_pos = c.ground_pos + Vector2(0.8, 0.0)
	near.mind = Person.Mind.FLEE
	if far != null:
		far.ground_pos = c.ground_pos + Vector2(1.5, 0.0)
	crowd._field.kill(c, &"doom")
	r.on_killed(c)
	crowd.advance(DT)
	r.step(DT, crowd)
	return r


static func _skip(t) -> void:
	var s := Kit.world(MissionBook.miras_house(), MissionDirector.new())
	var crowd: Crowd = s.crowd
	var out: Array[Person] = []
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside:
			out.append(p)
	var r := _relay(crowd, out[3], out[7], out[11], Callable())
	t.check(not r.skip.is_valid() and r.carrier == out[7] and r.relays == 1,
		"with no skip the nearest witness carries the report on, fleeing or not, as before")
	var fleeing := func(p: Person) -> bool: return p.mind == Person.Mind.FLEE
	var r2 := _relay(crowd, out[15], out[19], out[23], fleeing)
	t.check(r2.carrier == out[23] and r2.is_open(), "with skip the relay passes over the fleeing witness to the next")
	var r3 := _relay(crowd, out[27], out[31], null, fleeing)
	t.check(r3.dead and not r3.is_open(), "only a skipped witness saw it: the report ends")
	Kit.done(s)


static func _raze_line(t) -> void:
	var s := Kit.world(MissionBook.spoiled_harvest())
	var o: Objective = (s.rules as Rules).objectives[0]
	t.check((s.d as RazeDirector).hud_line() == "" and o.hud_text(s.rules) == "Granaries spoiled 0 / 3",
		"RazeObjective by default: its label and count, as before")
	Kit.done(s)
	var l := Kit.world(MissionBook.spoiled_harvest(), RazeLined.new())
	(l.d as RazeLined).line = "Raze the garrison 0 / 3, armed men every 40 s"
	var lo: Objective = (l.rules as Rules).objectives[0]
	t.check(lo.hud_text(l.rules) == "Raze the garrison 0 / 3, armed men every 40 s", "the director's HUD line in place of it")
	Kit.done(l)
