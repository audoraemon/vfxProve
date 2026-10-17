extends RefCounted
## v0.11 M6 The Lantern's Eye (mission spec §1, LanternEyeDirector on the Hunt type): three mirror towers -- the standing wall towers
## nearest the north, east and south-west points, never the bell tower, a wish's or another's -- each with a party of three watchmen
## on posts along its town-side face and two wrights waiting inside; the mirrors go up on the chain (0:50, then each at its time or
## CHAIN after the one before is gone for good); a guarded mirror only shakes its tower, an open one takes two Smites on its glass and
## shatters; its wrights come out and hang a new glass in 10 s of one wright's work, or it is gone for good after DRAIN; the
## Searchlight lit from 0:00 hunts the god's casts only while a mirror stands, and a cast in a lit pool adds 20 to the Gaze; all three
## standing together for EYE_OPENS loses. The town's regroup and evacuation pass everyone by, at the start and mid-mission; freed
## bodies are borne; the towers' own filters come back at teardown; the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const HEAVEN_FX := preload("res://src/fx/set2/heaven_splitter.gd")
## The live keepout: the kit's stack grown by the HUD's pad (v0.11 M6, the controller's ruling for M6's camera checks).
const ZONE := Rect2(0.0, 0.0, 240.0 + Hud.STACK_PAD, 165.0 + Hud.STACK_PAD)


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_not_yet(t)
	_guarded(t)
	_shatter(t)
	_blight_mirror(t)
	_heaven(t)
	_rehang(t)
	_gone(t)
	_light(t)
	_seen_cast(t)
	_seen_death(t)
	_eye(t)
	_won(t)
	_relief(t)
	_reserved_tower(t)
	_evacuated(t)
	_tagged(t)
	_teardown(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.lantern_eye())


## Step `i`'s guards moved well off the tower (v0.11 M6 tests): off guard, still alive.
static func _clear(d: LanternEyeDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + (g.post - d.towers[i].center()).normalized() * 6.0)


## A Smite on tower `i`'s outer face (v0.11 M6 tests).
static func _smite(s: Dictionary, d: LanternEyeDirector, i: int) -> void:
	(s.env as EnvironmentField).damage_radius(d.outer_face(i), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")


static func _setup(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var ok := d.towers.size() == 3 and d.steps.size() == 3 and d.standards.is_empty() and d.wrights.size() == 3
	var people := {}
	for i in 3:
		var tw := d.towers[i]
		ok = ok and RuinWish.fits(tw, "tower") and tw.damage_filter.is_valid() and d.steps[i].party.size() == LanternEyeDirector.PARTY
		for j in range(i + 1, 3):
			var gap := tw.center().distance_to(d.towers[j].center())
			ok = ok and gap >= 20.0 and gap <= 35.0
		for k in d.steps[i].party.size():
			var g: HuntDirector.Guard = d.steps[i].party[k]
			var p := g.man as Person
			ok = ok and p.mind == Person.Mind.DUTY and p.profile.role == CitizenProfile.Role.WATCHMAN and not p.soldier
			people[p] = true
			for m in range(k + 1, d.steps[i].party.size()):
				ok = ok and g.post.distance_to((d.steps[i].party[m] as HuntDirector.Guard).post) > Crowd.DOOM_WITNESS
		ok = ok and d.party_on(i).size() == LanternEyeDirector.PARTY
		for w: HuntDirector.Guard in d.wrights[i]:
			var p := w.man as Person
			ok = ok and p.inside and p.mind == Person.Mind.DUTY and p.profile.role == CitizenProfile.Role.ENGINEER
			people[p] = true
		var a: HuntDirector.Guard = d.wrights[i][0]
		var b: HuntDirector.Guard = d.wrights[i][1]
		ok = ok and a.post.distance_to(b.post) > Crowd.DOOM_WITNESS
	t.check(ok and people.size() == 15, "three towers 20-35 apart, stone tonight; three watchmen on guard at each, one witness apart; two wrights inside each; fifteen lay citizens")
	var quiet := true
	for w: HuntDirector.Guard in d.wrights[2]:
		var out := (d.towers[2].center() - d.feet[2]).normalized()
		quiet = quiet and (w.post - d.towers[2].center()).dot(out) > d.towers[2].footprint.size.y * 0.5 + LanternEyeDirector.WRIGHT_OUT - 0.5
	for w: HuntDirector.Guard in d.wrights[0]:
		quiet = quiet and d.towers[0].distance_to(w.post) <= LanternEyeDirector.POST_REACH
	t.check(LanternEyeDirector.QUIET_SIDE == [false, false, true] and quiet,
		"the south-west tower's wrights work from its quiet side, %.1f beyond its outer face, out of the busy street at its foot; the others at their feet" % LanternEyeDirector.WRIGHT_OUT)
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["step_0", "step_1", "step_2"] and d.searchlight.on and d.searchlight.beams() == 2 and d.searchlight.hold == LanternEyeDirector.HOLD
		and not d.searchlight.hunt and d.gaze != null and not (d.gaze is Descent.TierGaze),
		"the strip: three mirrors; the light lit, both beams, quiet; its own Gaze (%s)" % [ids])
	var cam := LanternEyeDirector.CAMERA_AT
	var clear := Kit.clear_of_stack(LanternEyeDirector.SPIRE, cam, ZONE) and ZONE.encloses(Kit.STACK)
	for i in 3:
		clear = clear and Kit.clear_of_stack(d.feet[i], cam, ZONE) and Kit.clear_of_stack(d.towers[i].center(), cam, ZONE)
	t.check(clear, "the camera keeps the spire and the three towers (or their arrows) clear of the padded HUD stack")
	var m := MissionBook.lantern_eye()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 5 and is_equal_approx(m.clock, 420.0) and reasons == ["eye_blind", "gaze", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "whisper", "wisp", "heaven"] and MissionBook.get_mission("lantern_eye").id == "lantern_eye",
		"the mission: Tier 5's numbers; the Eye blind, the Gaze, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := true
	for i in 3:
		for g: HuntDirector.Guard in d.steps[i].party:
			held = held and (g.man as Person).mind == Person.Mind.DUTY
		for w: HuntDirector.Guard in d.wrights[i]:
			held = held and (w.man as Person).inside
	t.check(held, "the town's regroup and evacuation pass the parties by; the wrights stay inside (review focus 2)")
	Kit.done(s)


static func _not_yet(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	_clear(d, 0)
	_smite(s, d, 0)
	var tw := d.towers[0]
	t.check(not d.steps[0].raised and is_equal_approx(tw.hp, tw.max_hp) and is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP),
		"before its time a mirror does not exist: a Smite on its unguarded tower only shakes it")
	Kit.done(s)


static func _guarded(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	Kit.run_for(s, float(LanternEyeDirector.STEP_AT[0]) + DT)
	t.check(d.steps[0].raised and d.standard(0) == d.towers[0] and (s.banners as Array).has("A MIRROR GOES UP ON THE NORTH TOWER")
		and d.guarded(0) and d.hint_phase() == "guarded" and d.searchlight.hunt,
		"at %s the first mirror goes up on the north tower, guarded; the light hunts" % UiTheme.clock(float(LanternEyeDirector.STEP_AT[0])))
	_smite(s, d, 0)
	var tw := d.towers[0]
	t.check(is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP) and is_equal_approx(tw.hp, tw.max_hp),
		"guarded, a Smite only shakes the tower: the glass whole, the tower's health unmoved")
	Kit.done(s)


static func _shatter(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	_clear(d, 0)
	var hits := [0]
	d.towers[0].hit.connect(func(_s: Structure, _a: float, _k: StringName) -> void: hits[0] += 1)
	_smite(s, d, 0)
	t.check(is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP - SmiteFx.DAMAGE) and not d.shattered[0] and d.hint_phase() == "open"
		and hits[0] == 1 and is_equal_approx(d.towers[0].hp, d.towers[0].max_hp), "open, a Smite strikes the glass; the tower is heard but its health never moves")
	_smite(s, d, 0)
	var out := true
	for w: HuntDirector.Guard in d.wrights[0]:
		var p := w.man as Person
		out = out and not p.inside and p.mind == Person.Mind.DUTY and p.anchor == w.post
	t.check(d.shattered[0] and is_equal_approx(d.drain_left[0], LanternEyeDirector.DRAIN) and out and (s.banners as Array).has("THE MIRROR SHATTERS")
		and d.hint_phase() == "shattered" and not d.searchlight.hunt, "two Smites shatter it; its two wrights come out to their posts; the light goes quiet")
	Kit.done(s)


## v0.11.1 (spec §7.3, Task 12): Blight clouds an unguarded mirror's glass at once and it shatters as after the last blow -- its wrights come
## out, the drain starts, the light goes quiet, the town hears one Blight's alarm and the banner is "BLIGHT - THE MIRROR CLOUDS"; a guarded
## one stands whole, no alarm, only "THEIR GUARD KEEPS IT"; a mirror not yet up, or a spot away from any tower, gives Blight nothing; a cast
## aimed in a lit pool adds SEEN_CAST like any other.
static func _blight_mirror(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var banners: Array = s.banners
	var fxc := FxContext.new()
	fxc.env = s.env
	fxc.field = s.field
	fxc.rng = RandomNumberGenerator.new()
	fxc.overhead = Node2D.new()
	fxc.ground = Node2D.new()
	fxc.rules = rules
	var face := d.outer_face(0)
	t.check(d.blight_target(face) == Vector2.INF and not d.blighted(face), "no mirror up: Blight finds nothing of the director's")
	d._raise(0)
	Kit.run_for(s, DT)
	t.check(d.blight_target(face) == d.towers[0].center() and d.blight_target(face + Vector2(6.0, 6.0)) == Vector2.INF,
		"a mirror up: Blight within %.0f of its tower finds the tower's middle; farther, nothing" % BlightFx.REACH)
	t.check(d.guarded(0) and not d.blight_takes(face), "its party stands guard: Blight would not take it")
	var alarm := crowd.alarm
	var fx: FxTimeline = FxTimeline.cast(load("res://src/fx/quiet/blight.gd"), fxc, face)
	fx._process(1.0)
	t.check(is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP) and not d.shattered[0] and banners.back() == "THEIR GUARD KEEPS IT"
		and crowd.alarm == alarm, "guarded, Blight lands and does nothing: the glass whole, no alarm, the banner THEIR GUARD KEEPS IT")
	fx.end_now()
	_clear(d, 0)
	t.check(not d.guarded(0) and d.blight_takes(face), "its guards walked off: Blight takes it")
	var before := banners.size()
	fx = FxTimeline.cast(load("res://src/fx/quiet/blight.gd"), fxc, face)
	fx._process(1.0)
	Kit.run_for(s, DT)
	var out := true
	for w: HuntDirector.Guard in d.wrights[0]:
		var p := w.man as Person
		out = out and not p.inside and p.mind == Person.Mind.DUTY and p.anchor == w.post
	t.check(d.shattered[0] and is_zero_approx(d.glass[0]) and absf(d.drain_left[0] - LanternEyeDirector.DRAIN) < 0.5 and out
		and is_equal_approx(d.towers[0].hp, d.towers[0].max_hp) and d.hint_phase() == "shattered" and not d.searchlight.hunt,
		"unguarded, Blight clouds the glass: shattered, its two wrights out to their posts, the tower unharmed, the light quiet")
	t.check(is_equal_approx(crowd.alarm - alarm, Crowd.BLIGHT_ALARM) and banners.slice(before).has("BLIGHT - THE MIRROR CLOUDS")
		and banners.slice(before).has("THE MIRROR SHATTERS"), "the town hears one Blight's alarm; the banners say the mirror clouds and shatters")
	fx.end_now()
	t.check(d.blight_target(face) == Vector2.INF, "a shattered mirror gives Blight nothing more")
	fxc.overhead.free()
	fxc.ground.free()
	Kit.done(s)
	# A Blight aimed inside a lit pool is a seen cast (the Eye's own rule for every cast) and, a mirror standing, a heard one.
	var w := _world()
	var e: LanternEyeDirector = w.d
	e._raise(0)
	Kit.run_for(w, DT)
	(w.rules as Rules).cast_made.emit(0, "blight", e.searchlight.aim(0))
	t.check(is_equal_approx(e.gaze.value, LanternEyeDirector.SEEN_CAST) and (w.banners as Array).has("THE EYE SEES YOUR HAND"),
		"a Blight cast in a lit pool adds %d to the Gaze" % roundi(LanternEyeDirector.SEEN_CAST))
	Kit.done(w)


## The controller's ruling: a mirror needs a Heaven Splitter and a Smite -- every stroke of one Heaven Splitter (its core, its line, its
## eruptions) is one blow of at most a Smite's worth, so alone it never shatters the glass (v0.11 M6).
static func _heaven(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var env: EnvironmentField = s.env
	d._raise(0)
	_clear(d, 0)
	var at := d.outer_face(0)
	var dir := d.along(0)
	env.damage_radius(at, HEAVEN_FX.CORE_KILL, 99999.0, &"lightning")
	env.damage_lane(at, dir, HEAVEN_FX.LINE_HALF_WIDTH, -HEAVEN_FX.LINE_LENGTH * 0.5, HEAVEN_FX.LINE_LENGTH * 0.5, &"lightning")
	Kit.run_for(s, 3.0)
	env.damage_radius(at, HEAVEN_FX.ERUPT_KILL, 60.0, &"lightning")
	var tw := d.towers[0]
	t.check(LanternEyeDirector.MIRROR_HP > LanternEyeDirector.BLOW_MAX and LanternEyeDirector.MIRROR_HP <= 2.0 * LanternEyeDirector.BLOW_MAX
		and is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP - LanternEyeDirector.BLOW_MAX) and not d.shattered[0]
		and is_equal_approx(tw.hp, tw.max_hp), "one Heaven Splitter alone takes one blow off the glass (%.0f left): the mirror stands" % d.glass[0])
	Kit.run_for(s, LanternEyeDirector.HEAVEN_GAP)
	_smite(s, d, 0)
	t.check(d.shattered[0], "a Smite after it shatters the mirror")
	Kit.done(s)
	# The final review: a Smite inside HEAVEN_GAP is no Heaven stroke -- it lands as the second blow at once.
	s = _world()
	d = s.d
	env = s.env
	d._raise(0)
	_clear(d, 0)
	env.damage_radius(d.outer_face(0), HEAVEN_FX.CORE_KILL, 99999.0, &"lightning")
	Kit.run_for(s, 1.0)
	_smite(s, d, 0)
	t.check(d.shattered[0], "a Smite 1 s after a Heaven Splitter's first stroke, inside HEAVEN_GAP, shatters the mirror")
	Kit.done(s)


static func _rehang(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	_clear(d, 0)
	d._shatter(0)
	Kit.run_for(s, LanternEyeDirector.REHANG * 0.5 + 0.2)
	var inside := true
	for w: HuntDirector.Guard in d.wrights[0]:
		inside = inside and (w.man as Person).inside
	t.check(not d.shattered[0] and not d.broken(0) and is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP) and inside
		and (s.banners as Array).has("THE MIRROR IS HUNG AGAIN"), "two wrights at work hang a new glass in 5 s: the mirror stands again, its wrights back inside")
	Kit.done(s)
	# The final review: the south-west tower's quiet-side wrights through a whole cycle -- out to their posts beyond the outer face, the
	# glass hung again, back inside, the mirror ready to shatter once more.
	s = _world()
	d = s.d
	d._raise(2)
	_clear(d, 2)
	d._shatter(2)
	var posted := true
	for w: HuntDirector.Guard in d.wrights[2]:
		var p := w.man as Person
		posted = posted and not p.inside and p.mind == Person.Mind.DUTY and p.anchor == w.post
		Kit.arrive(p, w.post)
	t.check(LanternEyeDirector.QUIET_SIDE[2] and d.shattered[2] and posted, "the south-west mirror shattered: its wrights out to their quiet-side posts")
	Kit.run_for(s, LanternEyeDirector.REHANG * 0.5 + 0.2)
	inside = true
	for w: HuntDirector.Guard in d.wrights[2]:
		inside = inside and (w.man as Person).inside
	t.check(not d.shattered[2] and is_equal_approx(d.glass[2], LanternEyeDirector.MIRROR_HP) and inside,
		"they hang a new glass from the quiet side and go back inside")
	d._shatter(2)
	posted = true
	for w: HuntDirector.Guard in d.wrights[2]:
		posted = posted and not (w.man as Person).inside and (w.man as Person).anchor == w.post
	t.check(d.shattered[2] and posted, "shattered again: the same wrights come out to the same posts")
	Kit.done(s)


static func _gone(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	_clear(d, 0)
	d._shatter(0)
	for w: HuntDirector.Guard in d.wrights[0]:
		Kit.free_body(s, w.man)
	Kit.run_for(s, LanternEyeDirector.DRAIN + DT)
	var released := true
	for g: HuntDirector.Guard in d.steps[0].party:
		released = released and (g.man as Person).mind != Person.Mind.DUTY
	var left := d.timeline.seconds_to("step_1")
	t.check(d.broken(0) and (s.banners as Array).has("THE MIRROR IS GONE") and released and not d.steps[1].raised
		and absf(left - LanternEyeDirector.CHAIN) < 1.0, "left shattered %d s it is gone for good; its party goes home; the strip shows the next at the chain (%.1f s)" % [roundi(LanternEyeDirector.DRAIN), left])
	Kit.done(s)


static func _light(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var rules: Rules = s.rules
	var far := Vector2(10.0, 10.0)
	rules.cast_made.emit(0, "smite", far)
	Kit.run_for(s, DT)
	t.check(not d.searchlight.hunt and not d.searchlight.searching and d.last_cast == Vector2.INF, "quiet: a cast before any mirror stands draws no beam")
	d._raise(0)
	Kit.run_for(s, DT)
	rules.cast_made.emit(0, "smite", far)
	Kit.run_for(s, DT)
	t.check(d.searchlight.hunt and d.searchlight.searching and d.last_cast == far, "a mirror standing, a heard cast draws the nearest beam")
	Kit.run_for(s, LanternEyeDirector.HOLD + 0.5)
	t.check(not d.searchlight.searching, "the beam goes back to its sweep after %d s" % roundi(LanternEyeDirector.HOLD))
	rules.cast_made.emit(0, "whisper", Vector2(-10.0, 5.0))
	t.check(d.last_cast == far, "a whisper is not heard")
	rules.cast_made.emit(0, "wisp", Vector2(-10.0, 5.0))
	t.check(d.searchlight.decoy == Vector2(-10.0, 5.0) and d.searchlight.decoy_beam >= 0, "a Wisp is a decoy")
	Kit.done(s)


static func _seen_cast(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var rules: Rules = s.rules
	rules.cast_made.emit(0, "doom", d.searchlight.aim(0))
	t.check(is_equal_approx(d.gaze.value, LanternEyeDirector.SEEN_CAST) and (s.banners as Array).has("THE EYE SEES YOUR HAND"),
		"a cast aimed inside a lit pool adds %d, the light quiet or not" % roundi(LanternEyeDirector.SEEN_CAST))
	rules.cast_made.emit(0, "whisper", d.searchlight.aim(1))
	t.check(is_equal_approx(d.gaze.value, 2.0 * LanternEyeDirector.SEEN_CAST), "a whisper in the light too, though it is not heard")
	d._raise(0)
	Kit.run_for(s, DT)
	var dark := d.searchlight.aim(0) + Vector2(3.0 * Searchlight.POOL_R + 6.0, 0.0)
	if d.searchlight.touches(dark):
		dark = d.searchlight.aim(0) - Vector2(3.0 * Searchlight.POOL_R + 6.0, 0.0)
	rules.cast_made.emit(0, "smite", dark)
	Kit.run_for(s, 5.0)
	t.check(is_equal_approx(d.gaze.value, 2.0 * LanternEyeDirector.SEEN_CAST) and d.searchlight.touches(dark),
		"a cast made in the dark is not counted when the beam it draws arrives on it (review focus 3)")
	Kit.done(s)


static func _seen_death(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var crowd: Crowd = s.crowd
	var victim: Person = null
	var witness: Person = null
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p.profile.role != CitizenProfile.Role.WATCHMAN:
			if victim == null:
				victim = p
			elif witness == null:
				witness = p
	Kit.arrive(witness, victim.ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(victim, &"doom")
	Kit.run_for(s, DT)
	t.check(is_equal_approx(d.gaze.value, GazeMeter.SEEN_DEATH) and (s.banners as Array).has(LanternEyeDirector.SEEN_DEATH_BANNER),
		"a seen death adds 10 of 100 to the Eye's own Gaze (Decision 208), with its banner (the controller's ruling)")
	Kit.done(s)


static func _eye(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	for i in 3:
		d._raise(i)
	Kit.run_for(s, DT)
	var first: String = Kit.labels(d)[0]
	t.check(d.hint_phase() == "eye" and first.begins_with("THE EYE OPENS IN") and Kit.edged(d, first)
		and String(d.timeline.upcoming(1)[0].id).begins_with("eye_"), "all three standing: the countdown on the spire's tag, the hint and the strip (%s)" % first)
	Kit.run_for(s, LanternEyeDirector.EYE_OPENS - 2.0)
	t.check(not d.found and d.eye_left() > 1.0, "not yet open two seconds short")
	d._shatter(2)
	Kit.run_for(s, DT)
	t.check(d.hint_phase() == "shattered" and is_equal_approx(d.eye_left(), LanternEyeDirector.EYE_OPENS), "a mirror shattered stops it")
	d._rehang(2)
	Kit.run_for(s, LanternEyeDirector.EYE_OPENS - 2.0)
	t.check(not d.found, "hung again, the count starts afresh")
	Kit.run_for(s, 2.5)
	var main: Objective = (s.rules as Rules).objectives[0]
	var opens := 0
	for b: String in s.banners:
		opens += 1 if b == "THE EYE OPENS" else 0
	t.check(d.found and d.eye_open and d.lost_reason() == "eye_open" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "eye_open"
		and opens == 1, "thirty seconds all standing: THE EYE OPENS, once; the night is lost")
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	for i in 3:
		d._raise(i)
		d._gone(i)
	Kit.run_for(s, DT)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.broken_all() and main.check(s.rules) == Objective.Status.DONE and main.reason == "eye_blind" and not d.searchlight.on
		and d.tags().is_empty() and d.hint_phase() == "" and main.hud_text(s.rules) == "Blind the Eye: mirrors 3 / 3",
		"the third gone for good: the Eye is blind, the light out")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var g: HuntDirector.Guard = d.steps[0].party[0]
	var dead: Variant = g.man
	Kit.free_body(s, dead)
	Kit.run_for(s, LanternEyeDirector.RELIEF_AFTER + HuntDirector.TICK + DT)
	var p: Variant = g.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and (p as Person).anchor == g.post
		and g.relief and (s.banners as Array).has("A NEW GUARD TAKES THE POST"), "a fallen guard is replaced %d s later by a lay citizen made a watchman" % roundi(LanternEyeDirector.RELIEF_AFTER))
	Kit.done(s)


static func _reserved_tower(t) -> void:
	var a := _world()
	var north_ix := (a.town as Town)._built.find((a.d as LanternEyeDirector).towers[0])
	Kit.done(a)
	var b := Kit.world(MissionBook.lantern_eye(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved_places.append(rules.town()._built[north_ix]))
	var d: LanternEyeDirector = b.d
	var north := (b.town as Town)._built[north_ix]
	t.check(d.towers.size() == 3 and not d.towers.has(north) and RuinWish.fits(d.towers[0], "tower")
		and d.towers[0].art_tag != &"bell_tower", "a watchtower wish's tower is passed over: the mirror takes the next nearest (Decision 214)")
	Kit.done(b)


static func _evacuated(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	d._gone(0)
	d._raise(1)
	Kit.run_for(s, 1.0)
	var g1: HuntDirector.Guard = d.steps[1].party[0]
	var g2: HuntDirector.Guard = d.steps[1].party[1]
	var whispered := g1.man as Person
	var recovering := g2.man as Person
	whispered.whisper(whispered.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	recovering._recover(1.0)
	Kit.evacuate(s)
	t.check(recovering.mind == Person.Mind.FLEE and whispered._whisper_fled, "(set-up) the evacuation runs the recovering guard and owes the whispered one a flight")
	Kit.run_for(s, 2.0 * HuntDirector.TICK + DT)
	var inside := true
	for i in [1, 2]:
		for w: HuntDirector.Guard in d.wrights[i]:
			inside = inside and (w.man as Person).inside
	t.check(recovering.mind == Person.Mind.DUTY and recovering.anchor == g2.post and whispered.mind == Person.Mind.WHISPERED
		and not whispered._whisper_fled and inside, "the second mirror standing: both guards kept at their posts; the wrights inside stay inside")
	Kit.done(s)
	var s2 := _world()
	var d2: LanternEyeDirector = s2.d
	d2._raise(0)
	_clear(d2, 0)
	d2._shatter(0)
	var w0: HuntDirector.Guard = d2.wrights[0][0]
	var w1: HuntDirector.Guard = d2.wrights[0][1]
	(w1.man as Person)._recover(1.0)
	Kit.evacuate(s2)
	t.check((w1.man as Person).mind == Person.Mind.FLEE, "(set-up) during a drain the evacuation runs the recovering wright")
	Kit.run_for(s2, 2.0 * HuntDirector.TICK + DT)
	t.check((w0.man as Person).mind == Person.Mind.DUTY and (w1.man as Person).mind == Person.Mind.DUTY and (w1.man as Person).anchor == w1.post
		and d2.hang_work[0] > 0.0 and (s2.crowd as Crowd).citizens.has(w1.man), "during a drain: the wrights hold their posts and work on")
	Kit.done(s2)


static func _tagged(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var labels := Kit.labels(d)
	var next := "NEXT MIRROR %s" % UiTheme.clock(float(LanternEyeDirector.STEP_AT[0]))
	t.check(labels[0] == next and Kit.edged(d, next) and labels.has("GUARD") and d.hint_phase() == "",
		"at the start: the next mirror's tower with its time, pointed at; GUARD on each guard (%s)" % [labels])
	d._raise(0)
	t.check(Kit.labels(d)[0] == "MIRROR - GUARDED" and Kit.edged(d, "MIRROR - GUARDED"), "the current mirror, guarded, gold, pointed at")
	_clear(d, 0)
	d._shatter(0)
	labels = Kit.labels(d)
	t.check(labels[0] == "MIRROR - SHATTERED %d" % roundi(LanternEyeDirector.DRAIN) and labels.has("WRIGHT") and absf(d.hint_seconds() - LanternEyeDirector.DRAIN) < 0.1,
		"shattered: its drain on its tag and in the hint's seconds; WRIGHT on each wright (%s)" % [labels])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The north tower. A mirror goes up here at %s: shatter it and keep it shattered %d s." % [
		UiTheme.clock(float(LanternEyeDirector.STEP_AT[0])), roundi(LanternEyeDirector.DRAIN)]
		and String(tour[1][1]) == "Halcyon's Searchlight. While a mirror stands, its beams hunt your casts. A cast in the light is seen."
		and String(tour[2][1]) == "The east and south-west towers: the next mirrors. If all three stand at once, the Eye opens.", "the tour")
	t.check(ResultsScreen.ACT_TITLES.get("eye_blind") == "THE LANTERN'S EYE IS BLIND" and ResultsScreen.ACT_TITLES.get("eye_open") == "THE EYE OPENS"
		and MissionHints.line("lantern_eye", "eye").contains(MissionHints.SECONDS) and MissionHints.line("lantern_eye", "shattered").contains(MissionHints.SECONDS),
		"its results under its own keys; its counting hints carry the seconds' mark")
	Kit.done(s)


static func _teardown(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	var towers := d.towers.duplicate()
	var own := d._own_filters.duplicate()
	d.teardown()
	var back := true
	for i in towers.size():
		back = back and (towers[i] as Structure).damage_filter == own[i]
	t.check(back and not d.searchlight.on, "teardown gives every tower its own filter back and puts the light out")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	for i in 3:
		d._raise(i)
	_clear(d, 0)
	d._shatter(0)
	Kit.run_for(s, 0.2)
	for i in 3:
		for g: HuntDirector.Guard in d.steps[i].party:
			if MissionDirector._alive(g.man):
				Kit.free_body(s, g.man)
		for w: HuntDirector.Guard in d.wrights[i]:
			if MissionDirector._alive(w.man) and not (w.man as Person).inside:
				Kit.free_body(s, w.man)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.shattered[0] and d.hang_work[0] < LanternEyeDirector.REHANG and d.hint_phase() == "shattered", "every guard and the working wrights freed: borne (review focus 4)")
	Kit.done(s)
