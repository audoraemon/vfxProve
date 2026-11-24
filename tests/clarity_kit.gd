extends RefCounted
## The kit every Mission clarity test shares (spec 6.4; pre-flight B1, B2, I6, I8, I9, I10): a Kit world, the way to land each of the
## twelve verbs on a target through the same entry points the game uses (so a verb the copy names is proved by the path the game takes,
## never by a shortcut such as Person.panic()), the read-only check on why_not(), the coverage check (every verb a step or hint names has
## a case) and the colour check. Preloaded by the tests (`const ClarityKit := preload("res://tests/clarity_kit.gd")`), no class_name.
## It is the one place that knows how a verb lands: a group's test file adds its own helpers only, never edits this one.

const Kit := preload("res://tests/test_tier2_groundwork.gd")

## The power each verb is tried with (spec 6.4). "scare" and "strike" share Smite: a scare case casts it KILL_R + 0.5 from the target.
const DEFAULT_KEY := {"kill": "doom", "scare": "smite", "lead": "whisper", "lure": "wisp", "confuse": "discord", "hold": "oath",
	"burn": "ember", "strike": "smite", "rot": "blight", "seal": "noleave", "banish": "skylift", "calm": "belllies"}

## The tag colours the copy names (LegendPanel's), and how far a tag's colour may be from one (0-255 per channel, Euclidean) to be it.
const COLOURS := {"gold": LegendPanel.TARGET, "orange": LegendPanel.PLACE, "red": LegendPanel.DANGER, "blue": LegendPanel.CHARGE,
	"grey": LegendPanel.NOT_YET}
const COLOUR_TOLERANCE := 40.0

static var _colour_re: RegEx = null
## Every def the game plays, built once (building them all is slow): defs_for() reads it.
static var _pool: Array = []
## The keys of the casts the Rules refused while a test ran (_cast()): check_coverage() fails the case that made one.
static var refused_casts := PackedStringArray()


## A world for `def` (test_tier2_groundwork.world()'s dictionary), with a list `_made` for what apply() builds.
static func world(def: MissionDef, made: MissionDirector = null, before := Callable()) -> Dictionary:
	var s := Kit.world(def, made, before)
	s["_made"] = []
	return s


## Lets the world go, and what apply() built with it.
static func done(s: Dictionary) -> void:
	if s.get("hud") != null and is_instance_valid(s.hud):
		(s.hud as Object).free()
	for fx: Variant in s.get("_made", []):
		if is_instance_valid(fx):
			(fx as Object).free()
	Kit.done(s)


## The ground point past the walls that a Banish sets `from` down at: where Walls.way_off() leads, pushed on to the first point
## Walls.outside() holds (pre-flight B2: Walls.outside() is a predicate, not a point finder).
static func outside_point(from: Vector2) -> Vector2:
	var e := Walls.way_off(from)
	if e == Vector2.INF:
		e = from
	var dir := (e - from).normalized() if e != from else Vector2.RIGHT
	for i in 40:
		if Walls.outside(e):
			return e
		e += dir * 1.0
	return e


## The centre of `v`, a Person's feet or a Structure's middle, or the point itself.
static func point_of(v: Variant) -> Vector2:
	if v is Person:
		return (v as Person).ground_pos
	if v is Structure:
		return (v as Structure).center()
	return v as Vector2


## Lands `verb` on `target` as its power does, through the entry points the game reads, then lets the cast be made
## (Rules.cast(): cast_made, as the directors and the HUD hear it); returns the power's key. `s.took` says whether the effect took
## (lure() and compel() can refuse, a whisper too), `s.at` where the cast was aimed.
##  - Person: kill `field.kill`; scare `Crowd.on_cast` for Smite KILL_R + 0.5 from him (never p.panic(): a soldier would run from it and
##    an ordinary cast does not frighten one), run past the impact; lead `whisper` to s.to; lure a light at s.light (default 1.5 from
##    him) and the case reads s.took; confuse `confuse`; hold `compel`; banish set down at outside_point(); seal a sealed NoLeaveFx
##    centred on s.door (or him) that binds him; calm The Bell Lies' ALL IS WELL (the keeper's lie, the bell unrung).
##  - Structure: burn `FireManager.ignite`; strike `damage_radius` as Smite's; rot `director.blighted`.
static func apply(s: Dictionary, verb: String, target: Variant, key := "") -> String:
	var k := key if key != "" else String(DEFAULT_KEY.get(verb, ""))
	var crowd: Crowd = s.crowd
	var at := point_of(target)
	var fx: Object = null
	var effect := Callable()
	s["took"] = true
	match verb:
		"kill":
			if not s.get("cast_first", false):
				s["took"] = crowd._field.kill(target as Person, StringName(k), at)
		"scare":
			var kill_r := float(PowerBook.level_stat("smite", 1, "KILL_R", 0.6))
			at = at + Vector2(kill_r + 0.5, 0.0)
			crowd.on_cast(at, Vector2.ZERO, 0.0, k)
		"lead":
			# The whisper lands inside the cast, after the Rules have judged who can hear it (the game's own order: the effect is built, then
			# cast_made); a whisper the Rules refuse (a bound prisoner, one still shaking the last off) never lands.
			var to: Vector2 = s.get("to", at + Vector2(2.0, 0.0))
			s["took"] = false
			effect = func() -> void: s["took"] = (target as Person).whisper(to, MindWhisperFx.LINGER)
		"lure":
			at = s.get("light", at + Vector2(1.5, 0.0))
			s["took"] = (target as Person).lure(at, 6.0, at)
		"confuse":
			(target as Person).confuse(DiscordFx.DISCORD_TIME)
			s["took"] = (target as Person).mind == Person.Mind.CONFUSED
		"hold":
			s["took"] = (target as Person).compel(at, 6.0, 1.0, Color.WHITE)
		"burn":
			if not s.get("cast_first", false):
				crowd.fires.ignite(target as Structure, 0.6)
		"strike":
			if not s.get("cast_first", false):
				(s.env as EnvironmentField).damage_radius(at, SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")
		"rot":
			s["took"] = (s.d as MissionDirector).blighted(at)
		"banish":
			var out := outside_point(at)
			var p := target as Person
			Kit.arrive(p, out)
			at = out
		"seal":
			var law := NoLeaveFx.new()
			s["_made"].append(law)
			s["fx"] = law
			at = s.get("door", at)
			fx = law
		"calm":
			var bell := BellLiesFx.new()
			s["_made"].append(bell)
			s["fx"] = bell
			fx = bell
	_cast(s, k, at, fx, effect)
	if s.get("cast_first", false):
		# The effect lands after the cast was made (a bolt falls, a fire takes hold): the game's own order.
		match verb:
			"kill":
				s["took"] = crowd._field.kill(target as Person, StringName(k), at)
			"burn":
				crowd.fires.ignite(target as Structure, 0.6)
			"strike":
				(s.env as EnvironmentField).damage_radius(at, SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")
	match verb:
		"seal":
			var law: NoLeaveFx = fx
			law.origin = at
			law.sealed = true
			if target is Person:
				law.bound[target] = 0.0
		"calm":
			crowd.bell_lies(BellLiesFx.LIE_TIME)
			crowd.unring_bell()
			crowd.false_bell(City.current().landmark(&"bell_tower").get_center())
		"scare":
			Kit.run_for(s, PowerBook.impact(k) + 0.3)
			if target is Person:
				s["took"] = (target as Person).mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]
	s["at"] = at
	return k


## Rules.cast() for `key` at `at`, the effect `fx` handed back by the caster (null for a power with no state a director reads), so
## cast_made, Rules.last_fx() and the cooldowns are the game's own. The key joins the loadout when it is not there; a cast the Rules
## refuse reaches no director (`s.refused` says so) and fails the case (refused_casts, read by check_coverage()).
static func _cast(s: Dictionary, key: String, at: Vector2, fx: Object, effect := Callable(), extra := {}) -> void:
	var rules: Rules = s.rules
	var slot := rules.loadout.find(key)
	if slot < 0:
		var l := rules.loadout
		l.append(key)
		rules.loadout = l
		var c := rules._cooldowns
		c.append(0.0)
		rules._cooldowns = c
		slot = l.size() - 1
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		if effect.is_valid():
			effect.call()
		return fx as FxTimeline
	var count := [0]
	var tally := func(_a: int, _b: String, _c: Vector2) -> void: count[0] += 1
	rules.cast_made.connect(tally)
	rules.cast(slot, at, extra)
	rules.cast_made.disconnect(tally)
	s["refused"] = count[0] == 0
	if count[0] == 0:
		# The Rules turned the cast away: no director heard it in the game, so none hears it here. The case fails (check_coverage()).
		refused_casts.append(key)


## A test that proves the Rules turn a cast away (a whisper on a bound prisoner) says so: the last refused cast was `key`'s, and it is taken off
## the list check_coverage() fails on.
static func refusal(t, key: String, what: String) -> void:
	var at := refused_casts.rfind(key)
	t.check(at >= 0, "%s: the Rules refuse the cast of %s" % [what, key])
	if at >= 0:
		refused_casts.remove_at(at)


## The HUD of the world (the one the game shows banners with), set up on its rules: the why-not banners a real cast makes land in
## hud.banners(). Freed by done().
static func attach_hud(s: Dictionary) -> Hud:
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	s["hud"] = hud
	return hud


## Like apply(), and returns what `d.why_not()` said at the moment the cast was made (Rules.cast_made, as the HUD hears it, connected after the
## director's own handler): a bolt has not struck, a loud power has not landed, a kill has not yet been done. The effect then lands as apply() does it
## (a kill after the cast, as the game's Doom falls after it). `s.key`'s banner words, "" for none.
static func apply_asked(s: Dictionary, verb: String, target: Variant, key := "") -> String:
	var rules: Rules = s.rules
	var said := [""]
	var ask := func(_slot: int, k: String, at: Vector2) -> void: said[0] = (s.d as MissionDirector).why_not(k, at)
	rules.cast_made.connect(ask)
	s["cast_first"] = true
	apply(s, verb, target, key)
	s.erase("cast_first")
	rules.cast_made.disconnect(ask)
	return said[0]


## Rules.cast() for `key` at `at` with the power's own effect (an FxContext of the world's own pieces), the caster the game gives Rules:
## the real Discord, Mind Whisper, Skylift ... Freed by done(). Returns the effect.
static func cast_real(s: Dictionary, key: String, at: Vector2, extra := {}) -> FxTimeline:
	var rules: Rules = s.rules
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rules = rules
	ctx.world = s.world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 7
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	s["_made"].append(ctx.overhead)
	s["_made"].append(ctx.ground)
	var slot := rules.loadout.find(key)
	if slot < 0:
		var l := rules.loadout
		l.append(key)
		rules.loadout = l
		var c := rules._cooldowns
		c.append(0.0)
		rules._cooldowns = c
		slot = l.size() - 1
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	var made := [null]
	rules.caster = func(script: GDScript, ground: Vector2, e: Dictionary) -> FxTimeline:
		made[0] = FxTimeline.cast(script, ctx, ground, e)
		return made[0]
	rules.cast(slot, at, extra)
	return made[0]


## Everything a why_not() could move if it wrote (pre-flight I8): every person's place, mind, door state, goal and anchor; the crowd's
## rng state (the one way a reader moves a checksum unseen); the director's report, phase, tags and timeline (its seconds and what
## has fired); and how many banners the Rules sent.
static func snapshot(s: Dictionary) -> Dictionary:
	var crowd: Crowd = s.crowd
	var d: MissionDirector = s.d
	var people := []
	for list: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in list:
			if is_instance_valid(p):
				people.append([p.ground_pos, p.mind, p.inside, p._goal, p.anchor, p.fearless_left, p.statuses.duplicate(true)])
	var tags := []
	for m in d.tags():
		tags.append([m.at, m.label, m.color, m.edge])
	# Buildings and the power cooldowns too: a why_not() that burns, breaks or spends a cast must fail here (Task 1+2 review).
	var built := []
	if s.get("env") != null:
		for st: Structure in (s.env as EnvironmentField).structures():
			if is_instance_valid(st):
				built.append([st.footprint, st.hp, st.destroyed, st.scorch])
	var cooldowns: Variant = (s.rules as Rules)._cooldowns if s.get("rules") != null else null
	# Every plain variable the director keeps (its lists and flags: _broke, _visited, _alight ...): a why_not() that writes one fails here too.
	var kept := {}
	for pr: Dictionary in d.get_property_list():
		if (int(pr.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var v: Variant = d.get(pr.name)
		if v is Object:
			continue
		kept[pr.name] = str(v)  # (as text: a NaN in a list is never equal to itself)
	return {"people": people, "kept": kept, "built": built, "cooldowns": cooldowns, "rng": crowd._rng.state, "report": d.report(), "phase": d.hint_phase(), "tags": tags,
		"elapsed": d.timeline.elapsed() if d.timeline != null else -1.0,
		"fired": d.timeline.fired_ids() if d.timeline != null else PackedStringArray(),
		"banners": (s.banners as Array).size()}


## `d.why_not()` for the key of every verb at every tag's ground point (and the origin) changes nothing snapshot() sees.
static func assert_read_only(t, s: Dictionary, label: String) -> void:
	var d: MissionDirector = s.d
	var before := snapshot(s)
	var asked := 0
	var points: Array[Vector2] = [Vector2.ZERO]
	for m in d.tags():
		points.append(m.at)
	for verb: String in DEFAULT_KEY:
		for g in points:
			d.why_not(DEFAULT_KEY[verb], g)
			asked += 1
	var after := snapshot(s)
	t.check(before == after and asked > 0, "%s: why_not() only reads (%d asked)" % [label, asked])


## Every MissionDef that plays `id` (a mission, an act, the board's twin): the union a key-resolution test reads.
static func defs_for(id: String) -> Array[MissionDef]:
	var out: Array[MissionDef] = []
	if _pool.is_empty():
		_pool.append_array(MissionBook.all())
		_pool.append_array(MissionBook.campaign_missions())
		_pool.append_array(MissionBook.tier_missions())
		_pool.append_array(MissionBook.dev_missions())
		_pool.append_array(MissionBook.rite_missions())
		_pool.append_array(MissionBook.hunt_missions())
		_pool.append(MissionBook.remembrance())
		_pool.append(MissionBook.feast("festival"))
		_pool.append(MissionBook.feast("procession"))
	for m: MissionDef in _pool:
		if m.id == id:
			out.append(m)
			if m.director == null and m.has_acts():
				out.append_array(m.acts)  # a Feast plays its act's director
		if m.has_acts():
			for a in m.acts:
				if a.id == id:
					out.append(a)
	var board := TierBook.board(id)
	if board != null:
		out.append(board)
	return out


## The phases of mission `id`: the union of hint_phases() over every def that plays it (pre-flight I11). A city twin plays the same
## director class (its overrides only set fields), and its steps are the base's (test_mission_steps checks that), so one list serves both.
static func phases_of(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for def in defs_for(MissionBook.split_city(id)[0]):
		var d := def.make_director()
		if d == null:
			continue
		for ph in d.hint_phases():
			if not out.has(ph):
				out.append(ph)
	if out.is_empty():
		out.append("")
	return out


## The step label and the how-to-win line a player reads in `phase` of `id`.
static func texts(id: String, phase: String) -> PackedStringArray:
	var list := MissionSteps.steps(id)
	var out := PackedStringArray()
	var i := MissionSteps.index_for(list, phase)
	if i >= 0:
		out.append(String(list[i]["t"]))
	out.append(MissionHints.line(id, phase))
	return out


## Every verb a step or hint of `ids` names (per phase) has a case {"id", "phase", "verb"}, and every label fits MAX_LABEL.
static func check_coverage(t, ids: PackedStringArray, cases: Array) -> void:
	var missing := PackedStringArray()
	var long := PackedStringArray()
	var checked := 0
	for id in ids:
		for step: Dictionary in MissionSteps.steps(id):
			if String(step["t"]).length() > MissionSteps.MAX_LABEL:
				long.append("%s: %s" % [id, step["t"]])
		for phase in phases_of(id):
			for text in texts(id, phase):
				for verb in MissionVerbs.named_in(text):
					checked += 1
					var found := false
					for c: Dictionary in cases:
						if c.id == id and c.phase == phase and c.verb == verb:
							found = true
							break
					if not found:
						missing.append("%s/%s/%s" % [id, phase, verb])
	t.check(missing.is_empty(), "every named verb has a case (%d checked; missing %s)" % [checked, ", ".join(missing)])
	t.check(long.is_empty(), "every step fits %d characters (%s)" % [MissionSteps.MAX_LABEL, "; ".join(long)])
	t.check(refused_casts.is_empty(), "the Rules took every cast the kit made (refused: %s)" % ", ".join(refused_casts))
	refused_casts = PackedStringArray()


## The colour name of `c` (gold, orange, red, blue, grey), or "" when no LegendPanel colour is within COLOUR_TOLERANCE of it.
static func colour_name(c: Color) -> String:
	var best := ""
	var best_d := COLOUR_TOLERANCE
	for n: String in COLOURS:
		var k: Color = COLOURS[n]
		var d := Vector3(c.r - k.r, c.g - k.g, c.b - k.b).length() * 255.0
		if d < best_d:
			best_d = d
			best = n
	return best


## Each "(gold)", "(orange)", "(red)", "(blue)" or "(grey)" in `text` is the colour of some tag `d` draws now.
static func colours_ok(t, d: MissionDirector, text: String, label: String) -> void:
	if _colour_re == null:
		_colour_re = RegEx.create_from_string("\\((gold|orange|red|blue|grey)\\)")
	var drawn := PackedStringArray()
	for m in d.tags():
		var n := colour_name(m.color)
		if n != "" and not drawn.has(n):
			drawn.append(n)
	var bad := PackedStringArray()
	for hit in _colour_re.search_all(text):
		if not drawn.has(hit.get_string(1)):
			bad.append(hit.get_string(1))
	t.check(bad.is_empty(), "%s: every colour named is a tag drawn (%s; drawn %s)" % [label, ", ".join(bad), ", ".join(drawn)])
