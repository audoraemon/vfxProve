extends RefCounted
## Mission clarity, the hook and its gate (spec 6.1, 6.4): the base director says nothing, WhyNotGate rate-limits, the HUD shows one quiet
## banner per cast that a director will not count (and none with no director, in free play, in the intro, at the end or with a banner
## queued), and ClarityKit.apply() lands each verb through the game's own paths (pre-flight B1, B2: a scare frightens a citizen and never a
## soldier; a lure answers to its light; a seal binds; a banish sets down outside the walls).

const ClarityKit := preload("res://tests/clarity_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


## A director with a why-not of its own: says `text` for every cast.
class WhyStub extends MissionDirector:
	var text := ""
	var asked := 0

	func why_not(_key: String, _at: Vector2) -> String:
		asked += 1
		return text


static func run(t) -> void:
	_base(t)
	_gate(t)
	_hud(t)
	_flood(t)
	_whispered(t)
	_kit(t)
	_read_only(t)
	_storm(t)
	Hud.reset_session()


static func _base(t) -> void:
	var d := MissionDirector.new()
	t.check(d.why_not("smite", Vector2.ZERO) == "", "the base director says nothing")
	t.check(d.hint_phases() == PackedStringArray([""]), "the base director has the one phase")
	t.check(d._cast_reaches("smite", Vector2.ZERO, Vector2(Crowd._cast_radius("smite") + MissionDirector.WHY_MARGIN - 0.01, 0.0))
		and not d._cast_reaches("smite", Vector2.ZERO, Vector2(Crowd._cast_radius("smite") + MissionDirector.WHY_MARGIN + 0.5, 0.0)),
		"a cast reaches what stands within its radius and the margin")
	t.check(not d._may_kill("whisper", Vector2.ZERO, Vector2.ZERO) and d._may_kill("smite", Vector2.ZERO, Vector2(0.3, 0.0))
		and not d._may_kill("smite", Vector2.ZERO, Vector2(2.0, 0.0)), "only a Kill power within its kill radius kills")


static func _gate(t) -> void:
	var g := WhyNotGate.new()
	t.check(not g.allow("", 0.0), "no words, no banner")
	t.check(g.allow("A", 0.0), "the first shows")
	t.check(not g.allow("A", 10.0), "the same words again within REPEAT: no")
	t.check(not g.allow("B", 2.0), "another within GAP: no")
	t.check(g.allow("B", 5.0), "another after GAP: yes")
	t.check(g.allow("A", 31.0), "the first after REPEAT: yes")
	t.check(not g.allow("A", 40.0) and not g.allow("B", 33.0), "and each repeats only after its own REPEAT (B was shown at 5)")


static func _hud_world(stub: WhyStub) -> Dictionary:
	var s := ClarityKit.world(MissionBook.tax_collector(), stub)
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	s["hud"] = hud
	return s


static func _cast(s: Dictionary) -> void:
	(s.rules as Rules).cast_made.emit(0, "smite", Vector2.ZERO)


static func _hud(t) -> void:
	var stub := WhyStub.new()
	var s := _hud_world(stub)
	var hud: Hud = s.hud
	var rules: Rules = s.rules
	stub.text = ""
	_cast(s)
	t.check(hud.banners().is_empty() and stub.asked == 1, "a director with nothing to say adds no banner")
	stub.text = "NOPE"
	_cast(s)
	t.check(hud.banners() == PackedStringArray(["NOPE"]), "a why-not is one banner (%s)" % [hud.banners()])
	hud.advance(1.0)
	_cast(s)
	t.check(hud.banners() == PackedStringArray(["NOPE"]), "the same cause a second later: still the one")
	t.check((s.banners as Array).is_empty(), "it goes to the HUD, not through Rules.banner (the Kit's list)")
	hud.advance(31.0)
	t.check(hud.banners().is_empty(), "it ages out")
	_cast(s)
	t.check(hud.banners() == PackedStringArray(["NOPE"]), "after REPEAT the HUD's own clock lets it show again (%s)" % [hud.banners()])

	# The gates: free play, no director, the intro, a finished night, a banner already queued.
	hud.advance(31.0)
	stub.text = "LATER"
	rules.free_play = true
	_cast(s)
	t.check(hud.banners().is_empty(), "free play shows none")
	rules.free_play = false
	hud.intro = true
	_cast(s)
	t.check(hud.banners().is_empty(), "the intro shows none")
	hud.intro = false
	rules.finished = true
	_cast(s)
	t.check(hud.banners().is_empty(), "a finished night shows none")
	rules.finished = false
	hud.push_banner("ONE")
	hud.push_banner("TWO")
	_cast(s)
	t.check(hud.banners() == PackedStringArray(["ONE", "TWO"]), "two banners already waiting: it waits out (%s)" % [hud.banners()])
	for i in 4:
		hud.advance(31.0)
	rules.director = null
	_cast(s)
	t.check(hud.banners().is_empty(), "no director, no banner, no error")
	rules.director = stub
	hud.free()
	ClarityKit.done(s)


## Review focus 2: two causes a second apart show one banner.
static func _flood(t) -> void:
	var stub := WhyStub.new()
	var s := _hud_world(stub)
	var hud: Hud = s.hud
	stub.text = "A"
	_cast(s)
	hud.advance(1.0)
	stub.text = "B"
	_cast(s)
	t.check(hud.banners() == PackedStringArray(["A"]), "two causes a second apart: one banner (%s)" % [hud.banners()])
	hud.advance(4.0)
	_cast(s)
	t.check(hud.banners().has("B"), "the second shows once GAP has passed (%s)" % [hud.banners()])
	hud.free()
	ClarityKit.done(s)


## MissionDirector._whispered_at(): the person a whisper just sent, and nobody else.
static func _whispered(t) -> void:
	var s := ClarityKit.world(MissionBook.tax_collector())
	var d: MissionDirector = s.d
	var crowd: Crowd = s.crowd
	var p: Person = crowd.citizens[0]
	var q: Person = crowd.citizens[1]
	Kit.arrive(q, p.ground_pos + Vector2(30.0, 0.0))
	t.check(d._whispered_at(p.ground_pos) == null, "nobody whispered: null")
	var to := p.ground_pos + Vector2(2.0, 0.0)
	ClarityKit.apply(s, "lead", p)
	t.check(bool(s.took) and d._whispered_at(p.ground_pos) == p, "the whispered one is found at the click")
	t.check(d._whispered_at(p.ground_pos + Vector2(MindWhisperFx.PICK_R + 0.5, 0.0)) == null, "and not from beyond the pick radius")
	t.check(to.distance_to(p._goal) < 6.0 or p._goal != Vector2.INF, "his goal is where he was sent")
	Kit.run_for(s, 0.1)
	t.check(d._whispered_at(p.ground_pos) == p, "still found while the whole linger is left")
	ClarityKit.done(s)


## apply() lands each verb through the game's entry points.
static func _kit(t) -> void:
	var s := ClarityKit.world(MissionBook.first_prayers())
	var crowd: Crowd = s.crowd
	var d: MissionDirector = s.d
	var citizen: Person = crowd.citizens[0]
	var soldier: Person = crowd.soldiers[0]
	for p: Person in crowd.citizens + crowd.soldiers:
		if p != citizen and p != soldier:
			Kit.arrive(p, Vector2(60.0, 60.0) + Vector2(p.get_instance_id() % 7, 0.0) * 3.0)
	Kit.arrive(citizen, Vector2(5.0, 5.0))
	Kit.arrive(soldier, Vector2(20.0, 5.0))
	# Scare: a citizen runs from a loud power KILL_R + 0.5 away and lives; a soldier stands fast (B1).
	var key := ClarityKit.apply(s, "scare", citizen)
	t.check(key == "smite" and citizen.is_alive() and bool(s.took), "scare: the citizen runs from a Smite that missed him (mind %s)" % [citizen.mind])
	ClarityKit.apply(s, "scare", soldier)
	t.check(soldier.is_alive() and not bool(s.took), "scare: a soldier is not frightened by an ordinary loud cast (mind %s)" % [soldier.mind])
	# Lead, Confuse, Hold, Lure.
	var a: Person = crowd.citizens[1]
	Kit.arrive(a, Vector2(10.0, 10.0))
	ClarityKit.apply(s, "lead", a)
	t.check(a.mind == Person.Mind.WHISPERED, "lead: a walk whisper")
	var b: Person = crowd.citizens[2]
	Kit.arrive(b, Vector2(14.0, 10.0))
	ClarityKit.apply(s, "confuse", b)
	t.check(b.mind == Person.Mind.CONFUSED, "confuse")
	var c: Person = crowd.citizens[3]
	Kit.arrive(c, Vector2(18.0, 10.0))
	ClarityKit.apply(s, "hold", c)
	t.check(c.mind == Person.Mind.COMPELLED and bool(s.took), "hold: an oath's compulsion")
	var e: Person = crowd.citizens[4]
	Kit.arrive(e, Vector2(22.0, 10.0))
	ClarityKit.apply(s, "lure", e)
	t.check(bool(s.took) and e.lured(), "lure: drawn to a light 1.5 away, and the case can read that it took")
	var duty := e
	duty.go_duty(Vector2(22.0, 10.0))
	s["light"] = duty.ground_pos
	ClarityKit.apply(s, "lure", duty)
	t.check(not duty.lured() or bool(s.took), "lure: the case reads s.took when a man on duty refuses it")
	# Banish: set down outside the walls.
	var f: Person = crowd.citizens[5]
	Kit.arrive(f, Vector2(26.0, 10.0))
	ClarityKit.apply(s, "banish", f)
	t.check(Walls.outside(f.ground_pos), "banish: outside the walls (%s)" % [f.ground_pos])
	# Kill.
	var k: Person = crowd.citizens[6]
	ClarityKit.apply(s, "kill", k)
	t.check(not k.is_alive(), "kill")
	# Seal: a sealed law that binds him, as the Tax Collector's mob reads it; the Rules' own last_fx().
	var g: Person = crowd.citizens[7]
	Kit.arrive(g, Vector2(30.0, 10.0))
	ClarityKit.apply(s, "seal", g)
	var law := s.rules.last_fx() as NoLeaveFx
	t.check(law != null and law.sealed and law.bound.has(g), "seal: Rules.last_fx() is the sealed law that binds him")
	# Burn, strike.
	var house := d._house_near(Vector2(0.0, 8.0))
	ClarityKit.apply(s, "burn", house)
	t.check(crowd.fires.is_burning(house), "burn: the building burns")
	var hp := house.hp
	ClarityKit.apply(s, "strike", house)
	t.check(house.hp < hp, "strike: the building is hurt")
	# Calm: the bell lies.
	ClarityKit.apply(s, "calm", Vector2.ZERO)
	t.check(crowd.is_bell_lying(), "calm: the bell lies")
	# Every cast went through Rules.cast (cast_made) and joined the loadout.
	t.check(not (s.rules as Rules).loadout.is_empty() and (s.rules as Rules).loadout.has("noleave") and (s.rules as Rules).loadout.has("belllies"),
		"the keys joined the loadout")
	ClarityKit.done(s)


static func _read_only(t) -> void:
	var s := ClarityKit.world(MissionBook.tax_collector())
	ClarityKit.assert_read_only(t, s, "the Tax Collector's base")
	ClarityKit.done(s)


## A Gathered Storm (Smite level 5, dragged) kills up to 2.5x as wide as its level-1 bolt: the cast just made is judged by its own effect's
## kill radius and growth, so a kill it makes never banners. A cast only asked about (another spot) keeps the level-1 radius.
static func _storm(t) -> void:
	var s := ClarityKit.world(MissionBook.first_prayers())
	var d: MissionDirector = s.d
	var at := Vector2(40.0, 40.0)
	var fx := ClarityKit.cast_real(s, "smite", at, {"level": 5, "to": at + Vector2(1.5, 0.0)})
	var grow := float(fx.get("grow")) if fx != null and "grow" in fx else 0.0
	var kill_r := float(fx.get("lv_kill_r")) * grow if fx != null else 0.0
	t.check(grow > 1.5 and kill_r > 1.2, "the storm grew (grow %.2f, kill radius %.2f)" % [grow, kill_r])
	var near := at + Vector2(kill_r - 0.05, 0.0)
	t.check(d._may_kill("smite", at, near) and not d._may_kill("smite", at, at + Vector2(kill_r + 0.3, 0.0)),
		"the storm just cast kills within its own grown radius, not beyond it")
	t.check(d._cast_reaches("smite", at, at + Vector2(Crowd._cast_radius("smite") * grow + MissionDirector.WHY_MARGIN - 0.05, 0.0)),
		"and reaches as far as it grew")
	var other := at + Vector2(10.0, 0.0)
	t.check(not d._may_kill("smite", other, other + Vector2(kill_r - 0.05, 0.0)) and d._cast_grow("smite", other) == 1.0,
		"a cast only asked about, elsewhere, keeps the level-1 radius")
	ClarityKit.done(s)
