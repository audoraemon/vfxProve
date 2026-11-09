class_name SaintFx
extends FxTimeline
## Saint or Sinner (Dominion, Tier III): one person is chosen (the nearest to the click, PICK_R -- any role), and
## everyone within RADIUS of them -- any role, up to MAX_PEOPLE -- is given one mind about them, for SPAN. The wheel
## at the click picks which (extra "mode"):
##   SAINT   they guard the chosen at all cost: they close round them in a ring (a compulsion of WILL_FIRM that follows
##           the chosen as they move) and whoever goes for the chosen -- a frenzied neighbour, a soldier, a mob -- is
##           set on by the nearest guards (Person.fight(), TARGET_ONLY) until they are down.
##   SINNER  they kill the chosen: every one of them goes for them (Person.fight(), TARGET_ONLY), citizens and soldiers
##           alike, until the chosen is dead or the span is out.
## The chosen wears the halo or the noose; the people the mark. Quiet when cast, but for the book entry's "alarm":
## what follows is seen for what it is. The cast locks the other slots until it takes.

const PICK_R := 1.0
const RADIUS := 6.0
const MAX_PEOPLE := 40
const SPAN := 30.0
const T_CAST := 0.9
const WILL := 0.8
const GUARD_RING := Vector2(0.9, 1.6)
const GUARD_SIGHT := 12.0
const GUARD_R := 4.0
const GUARDS_PER_THREAT := 3
const CIVIL_BLOW := 0.34
const RETHINK := 0.5
const HALO := Color("ffe9a8")
const NOOSE := Color("ff4040")
## Passed Mark (level 5): where a fallen chosen's mark may land.
const PASS_R := 3.0

var mode := "saint"
## The chosen, and the people given a mind about them.
var chosen: Person
var people: Array[Person] = []
## How many threats the guards have been set on; how many went for the chosen.
var repelled := 0
var hunters := 0
## Level 5 (Passed Mark): who took the mark when the chosen fell, if anyone did.
var passed_to: Person

var _rethink_in := 0.0
var _links: DominionParts.Links
## This cast's circle and span at its ability level (RADIUS and SPAN at level 1).
var lv_radius := RADIUS
var lv_span := SPAN
var _twist := false
var _passed := false


## Whom a click at `at` would choose: the nearest within PICK_R, or null.
static func target_at(field: EnemyField, at: Vector2) -> Person:
	var near := DominionParts.near(field, at, PICK_R, 1)
	return near[0] if not near.is_empty() else null


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "saint", "RADIUS", RADIUS))
	lv_span = float(PowerBook.stat(extra, "saint", "SPAN", SPAN))
	_twist = PowerBook.twist_at(extra, "saint")
	mode = String(extra.get("mode", "saint"))
	if not mode in ["saint", "sinner"]:
		mode = "saint"
	duration = T_CAST + lv_span + 0.5
	busy = T_CAST
	chosen = target_at(ctx.field, origin)
	if chosen == null:
		duration = 1.0
		return
	at(T_CAST, _decide)
	ctx.play(&"q_saint", origin)
	if not DominionParts.staged(self):
		return
	var col := HALO if mode == "saint" else NOOSE
	DominionParts.sky_sigil(self, chosen.ground_pos, 110.0, 110.0, col, T_CAST, 1.8)
	var glyph: Array[int] = []
	glyph.assign(DominionParts.HALO if mode == "saint" else DominionParts.NOOSE)
	var icon := DominionParts.icon(self, chosen, glyph, Color("fff6d8") if mode == "saint" else Color("ffd0d0"), T_CAST + 2.5, 110.0)
	icon.px = 4


func _decide() -> void:
	if chosen == null or not is_instance_valid(chosen) or not chosen.is_alive():
		duration = minf(duration, t + 0.5)
		return
	var col := HALO if mode == "saint" else NOOSE
	var glyph: Array[int] = []
	glyph.assign(DominionParts.HALO if mode == "saint" else DominionParts.NOOSE)
	chosen.set_badge(glyph, col, lv_span)
	for p in DominionParts.near(ctx.field, chosen.ground_pos, lv_radius, MAX_PEOPLE + 1):
		if p == chosen or p.resists_mind():
			continue
		if people.size() >= MAX_PEOPLE:
			break
		people.append(p)
	match mode:
		"saint":
			_ring()
		"sinner":
			for p in people:
				p.fight(chosen, lv_span, Person.SOLDIER_BLOW if p.soldier else CIVIL_BLOW, Person.FightRule.TARGET_ONLY, GUARD_SIGHT, &"sinner")
				p.set_badge(DominionParts.BLADE, NOOSE, lv_span)
				hunters += 1
	ctx.play(&"jg_rise", chosen.ground_pos, -8.0)
	if not DominionParts.staged(self):
		return
	_links = DominionParts.links(self)
	for p in people:
		_links.add(p, chosen, col)
		DominionParts.motes(self, p.ground_pos, DominionParts.GOLD_LIFE if mode == "saint" else [Color("ffd0d0"), NOOSE, Color("8a1010"), Color(0.3, 0.05, 0.05, 0.5)], 5)
	DominionParts.pulse(self, chosen.ground_pos, lv_radius, col, 0.7, 1.5)
	var wave := FxParts.shockwave(self, chosen.ground_pos, lv_radius, VoiceOfGodFx.SOLAR if mode == "saint" else FxParts.FIRE)
	wave.set_param("thickness", 0.06)
	wave.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.25, 0.4)
	wave.life = 0.7


## The guards' places round the chosen, as they stand now; a guard not fighting is set (or set again) on its place.
func _ring() -> void:
	var left := maxf(T_CAST + lv_span - t, 0.5)
	var n := people.size()
	for i in n:
		var p := people[i]
		if not is_instance_valid(p) or not p.is_alive() or p.mind == Person.Mind.FIGHT:
			continue
		var a := TAU * float(i) / float(maxi(n, 1)) + t * 0.1
		var r := GUARD_RING.x + (GUARD_RING.y - GUARD_RING.x) * float(i % 2)
		var spot := chosen.ground_pos + Vector2(cos(a), sin(a)) * r
		if p.grid != null:
			var w := p.grid.nearest_walkable(spot)
			if w != Vector2.INF:
				spot = w
		if p.mind == Person.Mind.COMPELLED and p.anchor.distance_to(spot) < 0.4:
			continue
		if p.mind == Person.Mind.COMPELLED:
			p.anchor = spot
			p.set_goal(spot)
		else:
			p.compel(spot, left, WILL, HALO, chosen.mind == Person.Mind.PANIC or chosen.mind == Person.Mind.FLEE, &"", DominionParts.HALO)


## Whoever goes for the chosen is set on by the nearest guards.
func _guard() -> void:
	var guard_cap := people.size() if _twist else GUARDS_PER_THREAT
	for e in ctx.field.in_radius(chosen.ground_pos, GUARD_R):
		var foe := e as Person
		if foe == null or foe == chosen or not foe.is_alive() or foe.inside or people.has(foe):
			continue
		if not (foe.mind == Person.Mind.FIGHT and foe.fight_target == chosen):
			continue
		var set := 0
		var guards := people.duplicate()
		guards.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(foe.ground_pos) < b.ground_pos.distance_squared_to(foe.ground_pos))
		for g in guards:
			if set >= guard_cap:
				break
			if not is_instance_valid(g) or not g.is_alive() or g.mind == Person.Mind.FIGHT:
				continue
			g.fight(foe, 10.0, Person.SOLDIER_BLOW if g.soldier else CIVIL_BLOW, Person.FightRule.TARGET_ONLY, GUARD_SIGHT, &"saint")
			set += 1
		if set > 0:
			repelled += 1
			if DominionParts.staged(self):
				DominionParts.pulse(self, foe.ground_pos, 1.0, NOOSE, 0.5, 0.8)


func _fx_process(delta: float) -> void:
	if t < T_CAST or chosen == null or not is_instance_valid(chosen):
		return
	if mode == "sinner" and _twist and not _passed and not chosen.is_alive():
		_pass_mark()
	if mode != "saint":
		return
	if not chosen.is_alive():
		# The chosen is dead: the guards are released to their day.
		for p in people:
			if is_instance_valid(p):
				p.release_compulsion()
		duration = minf(duration, t + 0.5)
		return
	_rethink_in -= delta
	if _rethink_in <= 0.0:
		_rethink_in = RETHINK
		_guard()
		_ring()


## Passed Mark (SINNER, level 5): the first frame the chosen is dead, the mark goes to the nearest living person in the
## open within PASS_R of where they fell who is not of the mob; every living hunter is set on the new chosen. Once.
func _pass_mark() -> void:
	_passed = true
	var fell := chosen.ground_pos
	var best: Person = null
	var best_d := INF
	for e in ctx.field.in_radius(fell, PASS_R):
		var p := e as Person
		if p == null or p == chosen or not p.is_alive() or p.inside or people.has(p):
			continue
		var d := p.ground_pos.distance_squared_to(fell)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		return
	passed_to = best
	chosen = best
	var left := maxf(T_CAST + lv_span - t, 0.5)
	chosen.set_badge(DominionParts.NOOSE, NOOSE, left)
	for p in people:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		p.fight(chosen, left, Person.SOLDIER_BLOW if p.soldier else CIVIL_BLOW, Person.FightRule.TARGET_ONLY, GUARD_SIGHT, &"sinner")
		p.set_badge(DominionParts.BLADE, NOOSE, left)
	if DominionParts.staged(self):
		if _links != null:
			for p in people:
				_links.add(p, chosen, NOOSE)
		DominionParts.pulse(self, chosen.ground_pos, 2.0, NOOSE, 0.6, 1.2)
