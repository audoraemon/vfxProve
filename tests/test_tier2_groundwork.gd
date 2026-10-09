extends RefCounted
## v0.11 M3 the groundwork for Tier 2's new missions, each hook shown to keep today's path when left alone (review focus 1):
## the strip shows a chained item's real time (EventTimeline.expect(), display only), adopted by The Tax Collector and Spoiled
## Harvest; _open_door() on every director; Tier 2's frame; a messenger who rings the bell himself
## (WarningDirector._rings_himself()) and the rope given back (BellNetwork.restore()); the Festival's knobs; the Assassinate
## type's switches. And the kit every M3 test shares: world(), done(), run_for(), arrive(), free_body(), labels(), edged(),
## shown_at(), clear_of_stack().

const DT := 0.05
## The screen, and the left HUD stack's dead zone at its top-left (M2's Task 8 ruling: about 230 x 70 px; a tag's diamond and
## label sit some 30 px over its point, so a key point is kept 100 px down or 240 px right of the corner) (v0.11 M3).
const VIEW := Vector2(640.0, 360.0)
const DEAD := Rect2(0.0, 0.0, 240.0, 100.0)


## A Festival with its knobs turned (v0.11 M3): no Mayor, no fires, one event of its own, no gathering, and no goer may break.
class Knobbed:
	extends FestivalDirector

	func _begin() -> void:
		has_mayor = false
		fire_spots = []
		super()

	func _gather() -> void:
		pass

	func _add_events() -> void:
		timeline.add(30.0, "mine", "Mine")

	func _may_break(_p: Person) -> bool:
		return false


## An Assassinate night of one hidden quarry (v0.11 M3): off the strip, never smoked out, its own HUD line and loss.
class Hidden:
	extends AssassinateDirector
	var lost := ""

	func _plan() -> void:
		hideout = _house_near(Vector2(0.0, 8.0))
		safe_at = TaxCollectorDirector.CITADEL_GATE
		smoke_out = false
		var stops: Array[Structure] = []
		var q := _add_quarry("QUARRY", 30.0, stops, 0)
		q.scheduled = false

	func hud_line() -> String:
		return "Find him"

	func lost_reason() -> String:
		return lost


## A Warning whose messenger rings the bell himself (v0.11 M3), straight for the tower's foot.
class Himself:
	extends WarningDirector

	func _rings_himself() -> bool:
		return true

	func _goal() -> Vector2:
		return crowd.bell.foot


static func run(t) -> void:
	_strip(t)
	_chained(t)
	_door(t)
	_frame(t)
	_rope(t)
	_festival(t)
	_switches(t)
	_kit(t)


## A world for `def` (v0.11 M3, shared by M3's tests): its town at the mission's readiness, its Rules, and `made` -- else the
## mission's own director -- set up, `before.call(director, rules)` first (to reserve people or places, or let a Descent reserve
## its wishes, as Mission._build_act() does). Banners kept.
static func world(def: MissionDef, made: MissionDirector = null, before := Callable()) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, node, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director: MissionDirector = made if made != null else def.make_director()
	if director != null:
		if before.is_valid():
			before.call(director, rules)
		director.setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": node, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


## Lets a world go (v0.11 M3).
static func done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## Runs `seconds` of the night (v0.11 M3): the crowd, then the Rules (and so the director).
static func run_for(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


## `p` stands at `at`, its walk dropped (v0.11 M3).
static func arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## `p` killed (if still alive) and its body freed, as its death fade ends (v0.11 M3: review focus 4).
static func free_body(s: Dictionary, p: Person) -> void:
	var crowd: Crowd = s.crowd
	crowd._field.kill(p, &"fire")
	crowd._field.remove(p)
	crowd.citizens.erase(p)
	crowd.soldiers.erase(p)
	p.free()


## The labels of `d`'s tags, in order (v0.11 M3).
static func labels(d: MissionDirector) -> Array:
	var out := []
	for m in d.tags():
		out.append(m.label)
	return out


## Whether `d`'s first tag labelled `label` is pointed at from the screen's edge (v0.11 M3).
static func edged(d: MissionDirector, label: String) -> bool:
	for m in d.tags():
		if m.label == label:
			return m.edge
	return false


## Where ground point `g` shows on the 640 x 360 screen with the camera resting on `cam` at play zoom -- or, off screen, where
## its edge arrow points from: the screen's border on the line from its centre (v0.11 M3).
static func shown_at(g: Vector2, cam: Vector2) -> Vector2:
	var c := VIEW * 0.5
	var p := (Iso.ground_to_screen(g) - Iso.ground_to_screen(cam)) * Mission.PLAY_ZOOM + c
	if Rect2(Vector2.ZERO, VIEW).has_point(p):
		return p
	var d := p - c
	var k := minf(absf(c.x / d.x) if d.x != 0.0 else INF, absf(c.y / d.y) if d.y != 0.0 else INF)
	return c + d * k


## Ground point `g`, or its edge arrow, is clear of the left HUD stack with the camera on `cam` (v0.11 M3, controller ruling 7).
static func clear_of_stack(g: Vector2, cam: Vector2) -> bool:
	return not DEAD.has_point(shown_at(g, cam))


## EventTimeline.expect() (mission spec §6): the strip and seconds_to() show the sooner time; the event still fires at its own;
## a later time is ignored; a timeline that never calls it lists as before; a stretched one takes the night's real seconds.
static func _strip(t) -> void:
	var tl := EventTimeline.new()
	var fired := []
	tl.add(30.0, "a", "A", func() -> void: fired.append("a"))
	tl.add(90.0, "b", "B", func() -> void: fired.append("b"))
	var plain := [tl.upcoming(2)[0].id, tl.upcoming(2)[1].id]
	tl.step(10.0)
	tl.expect("b", 40.0)
	tl.expect("b", 80.0)
	tl.expect("nowhere", 1.0)
	t.check(plain == ["a", "b"] and is_equal_approx(tl.seconds_to("b"), 30.0) and is_equal_approx(float(tl.upcoming(2)[1]["in"]), 30.0)
		and is_equal_approx(float(tl.upcoming(2)[1]["at"]), 40.0), "the strip shows b at its chained 0:40, the sooner of two (%s)" % [tl.upcoming(2)])
	tl.step(35.0)
	t.check(fired == ["a"] and not tl.has_come("b"), "display only: at 0:45 b has not fired")
	tl.step(50.0)
	t.check(fired == ["a", "b"], "b fires at its own 1:30")
	var slow := EventTimeline.new().stretched(2.0)
	slow.add(60.0, "c", "C")
	slow.expect("c", 60.0)
	t.check(is_equal_approx(slow.seconds_to("c"), 60.0), "on a stretched timeline the chained time is the night's real second")


## The Tax Collector and Spoiled Harvest adopt it (mission spec §6): the strip counts down to the chained time.
static func _chained(t) -> void:
	var s := world(MissionBook.tax_collector())
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	d._set_out(q)
	run_for(s, 2.0)
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	run_for(s, DT)
	var due := d.out_at(1) - d._clock
	t.check(due < float(TaxCollectorDirector.SET_OUT_AT[1]) - d._clock - 1.0 and absf(d.timeline.seconds_to("out_1") - due) < 0.1
		and not d.timeline.has_come("out_1"), "The Tax Collector's strip shows the next collector at the chained time (%.1f s)" % due)
	done(s)
	var h := world(MissionBook.spoiled_harvest())
	var hd: HarvestDirector = h.d
	hd._deliver(hd.targets[0])
	run_for(h, 2.0)
	hd._raze(hd.targets[0])
	var left := hd.grain_due(1) - hd._clock
	t.check(left <= HarvestDirector.CHAIN_AFTER + 0.01 and absf(hd.timeline.seconds_to("grain_1") - left) < 0.1,
		"Spoiled Harvest's strip shows the next grain at the chained time (%.1f s)" % left)
	done(h)


static func _door(t) -> void:
	var s := world(MissionBook.warning(), MissionDirector.new())
	var d: MissionDirector = s.d
	var house := d._house_near(Vector2(0.0, 8.0))
	var door := d._open_door(house, d._walkable(TownLayout.MARKET_SQUARE.get_center()))
	t.check(door != Vector2.INF and door.distance_to(house.center()) <= house.footprint.size.length() + 1.0,
		"any director finds a building's door the street reaches (_open_door(), moved up unchanged)")
	done(s)


static func _frame(t) -> void:
	var m := MissionBook._tier2("x", "X", PackedStringArray(["a", "b"]))
	t.check(m.tier == 2 and m.slots == 3 and m.dp_capacity == 8 and is_equal_approx(m.clock, 330.0) and m.profile == ""
		and m.tier_floor == 2 and not m.chooses_difficulty()
		and m.response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "Organized" and m.intro_banner == "X"
		and m.bonuses().is_empty() and m.pool.is_empty() and is_equal_approx(m.stretch, 1.0),
		"a Tier 2 mission's numbers: 5:30, 3 / 8, an Organized town whatever is chosen, no bonuses")
	t.check(MissionBook.BELL_RINGERS == "bell_ringers" and MissionBook.MARKET_PANIC == "market_panic"
		and MissionBook.INFORMER == "informer", "Omen's three new ids")


static func _rope(t) -> void:
	var a := world(MissionBook.warning())
	var w: WarningDirector = a.d
	var bell := (a.crowd as Crowd).bell
	var keeper := bell.keeper
	arrive(w.messenger, keeper.ground_pos + Vector2(0.3, 0.0))
	w.messenger.mind = Person.Mind.DUTY
	w.phase = WarningDirector.Phase.RUN
	w._run()
	t.check(not w._rings_himself() and w.messenger == keeper and bell.state == BellNetwork.State.CALLED,
		"by default the messenger tells the keeper (The Warning, untouched)")
	done(a)
	var b := world(MissionBook.warning(), Himself.new())
	var h: WarningDirector = b.d
	bell = (b.crowd as Crowd).bell
	keeper = bell.keeper
	var m := h.messenger
	arrive(m, bell.foot)
	m.mind = Person.Mind.DUTY
	h.phase = WarningDirector.Phase.RUN
	h._run()
	t.check(bell.keeper == m and h.phase == WarningDirector.Phase.DELIVERED and MissionDirector._alive(keeper)
		and is_equal_approx(bell.climb, 8.0 * BellNetwork.ESCORT_CLIMB), "one who rings it himself takes the rope at the foot, the keeper alive: 12 s")
	bell.restore(keeper)
	t.check(bell.keeper == keeper and bell.state == BellNetwork.State.IDLE and is_equal_approx(bell.climb, 8.0)
		and is_equal_approx(bell.progress, 0.0), "restore(): the rope back to its own keeper, idle, the town's climb")
	bell.replace_keeper(m)
	t.check(is_equal_approx(bell.climb, 8.0 * BellNetwork.ESCORT_CLIMB), "and the next stand-in climbs slower again")
	bell.state = BellNetwork.State.RUNG
	bell.restore(keeper)
	t.check(bell.state == BellNetwork.State.RUNG, "a bell that has rung stays rung")
	bell.state = BellNetwork.State.CLIMBING
	var gone: Variant = keeper
	free_body(b, keeper)
	bell.restore(gone)
	t.check(bell.keeper == null and bell.state == BellNetwork.State.IDLE, "a keeper whose body is freed leaves nobody on the rope, and no error")
	done(b)


static func _festival(t) -> void:
	var def := TierBook.board("festival")
	var a := world(def, FestivalDirector.new())
	var f: FestivalDirector = a.d
	var ids := []
	for e in f.timeline.upcoming(4):
		ids.append(e.id)
	t.check(f.has_mayor and f.mayor != null and f.fire_spots.size() == 2 and ids == ["bonfire", "address", "address_end", "close"]
		and not f.goers.is_empty(), "the Festival as before: the Mayor, two bonfire spots, its four events (%s)" % [ids])
	var g := f.goers[0]
	g.panic(g.ground_pos + Vector2(1.0, 0.0), 1.0)
	run_for(a, FestivalDirector.SAMPLE + DT)
	t.check(f.broke_list().has(g), "a frightened goer breaks (_may_break() says yes by default)")
	done(a)
	var b := world(def, Knobbed.new())
	var k: FestivalDirector = b.d
	ids = []
	for e in k.timeline.upcoming(4):
		ids.append(e.id)
	t.check(k.mayor == null and ids == ["mine"] and k.goers.is_empty(), "the knobs: no Mayor, its own events (%s)" % [ids])
	var p := (b.crowd as Crowd).citizens[0]
	k.goers.append(p)
	p.panic(p.ground_pos + Vector2(1.0, 0.0), 1.0)
	run_for(b, FestivalDirector.SAMPLE + DT)
	(b.rules as Rules).cast_made.emit(0, "smite", p.ground_pos)
	t.check(k.count() == 0, "a goer it may not break stays unbroken, frightened or in a loud cast's danger")
	t.check(FestivalObjective.new().label == "Break the festival" and FestivalObjective.new().reason == "festival"
		and FestivalObjective.new("Scatter the fair", "fair").reason == "fair", "FestivalObjective's words: the Festival's by default")
	done(b)


static func _switches(t) -> void:
	var a := world(MissionBook.tax_collector())
	var d: AssassinateDirector = a.d
	var main: Objective = (a.rules as Rules).objectives[0]
	t.check(d.smoke_out and d.quarries[0].scheduled and d.hud_line() == "" and d.lost_reason() == ""
		and main.hud_text(a.rules) == "Kill the collectors: 0 / 3" and main.check(a.rules) == Objective.Status.PENDING,
		"The Tax Collector's switches as before: scheduled, smoked out, the objective's own HUD line, no other loss")
	done(a)
	var b := world(MissionBook.tax_collector(), Hidden.new())
	var h: Hidden = b.d
	var q := h.quarries[0]
	var ids := []
	for e in h.timeline.upcoming(4):
		ids.append(e.id)
	(b.rules as Rules).cast_made.emit(0, "smite", h.hide_door)
	run_for(b, q.set_out_at + 5.0)
	t.check(ids.is_empty() and q.state == AssassinateDirector.State.WAITING and q.target.inside,
		"an unscheduled quarry: off the strip, not smoked out by a cast at the door, nor sent by his time (%s)" % [ids])
	var o := AssassinateObjective.new("Kill him", "him", "gone")
	t.check(o.hud_text(b.rules) == "Find him" and o.check(b.rules) == Objective.Status.PENDING, "the director's HUD line in place of the objective's")
	h.lost = "lost"
	t.check(o.check(b.rules) == Objective.Status.FAILED and o.reason == "lost", "a loss of the director's own, with its reason")
	done(b)
	# The objective's running text names the director's safe place, not the Citadel's (controller ruling, M2's deferred minor).
	var c := world(MissionBook.tax_collector())
	var dc: TaxCollectorDirector = c.d
	var qc := dc.quarries[0]
	var words: Objective = (c.rules as Rules).objectives[0]
	dc._set_out(qc)
	dc.hideout.destroy(dc.hideout.center(), &"fire")
	dc._alarm(qc)
	var citadel: String = words.hud_text(c.rules)
	dc.safe_label = "TEMPLE"
	t.check(dc.fleeing_to_safe(qc) and citadel == "Kill the collectors: 0 / 3, he runs for the Citadel"
		and words.hud_text(c.rules) == "Kill the collectors: 0 / 3, he runs for the Temple",
		"running with no hiding place, he runs for the director's safe place: the Citadel's text exact, a Temple's its own (%s)" % [words.hud_text(c.rules)])
	done(c)


static func _kit(t) -> void:
	var c := Vector2(3.0, 4.0)
	t.check(shown_at(c, c) == VIEW * 0.5 and clear_of_stack(c, c), "the camera's own point shows at the screen's centre")
	var west := shown_at(c + Vector2(-30.0, 30.0), c)
	t.check(is_equal_approx(west.x, 0.0) and west.y > 0.0 and west.y < VIEW.y, "a point far off screen is read at its arrow (%s)" % west)
	var corner := Iso.screen_to_ground(Iso.ground_to_screen(c) + (Vector2(60.0, 40.0) - VIEW * 0.5) / Mission.PLAY_ZOOM)
	t.check(not clear_of_stack(corner, c), "a point under the left HUD stack is not clear")
