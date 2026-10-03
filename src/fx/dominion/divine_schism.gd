class_name DivineSchismFx
extends FxTimeline
## Divine Schism (Dominion, Tier 5): the god rewrites loyalty. The people of a region REGION round the click, nearest
## first up to MAX_FIGHTERS, are set on two sides (Person.side: 1 white-gold, 2 crimson), each wearing its mark, and
## each sure the other is the enemy: they fight it (Person.fight(), FightRule.OTHER_SIDE) as what they are -- a
## soldier strikes like a soldier, a citizen with CIVIL_BLOW, and those who cannot fight (FLEEING_ROLES) run. Nobody
## is mad: only the side is laid on them, and when DURATION is up only that layer is lifted. The dead stay dead.
## How they are divided is the cast's mode (Targeting's Q and E):
##   FACTION SPLIT  citizens against soldiers.
##   PURGE          the few nearest the click (PURGE_R, PURGE_MAX) are condemned; everyone else hunts them.
##   CUSTOM         two clicks: those round the first against those round the second (CUSTOM_R each).
##   SPREADING      a few round the click (SEED_R) split in two, and every RECRUIT_EVERY each fighter draws the people
##                  beside it (RECRUIT_R, RECRUIT_CHANCE) onto its own side, up to SPREAD_MAX.
## The sides are laid as a wave sweeps out from the click (WAVE_SPEED), so their first paths are not all asked for in
## one frame. The town sees it (the book's REACH): those on no side run. The cast locks the other slots for 2 s.

const REGION := 14.0
const MAX_FIGHTERS := 140
const DURATION := 25.0
const CIVIL_BLOW := 0.25
## How far a fighter looks for the other side.
const SIGHT := 8.0
const WAVE_SPEED := 30.0
const PURGE_R := 1.5
const PURGE_MAX := 8
const CUSTOM_R := 5.0
const SEED_R := 3.0
const RECRUIT_EVERY := 1.0
const RECRUIT_R := 1.5
const RECRUIT_CHANCE := 0.35
const SPREAD_MAX := 120
## Who is set on a side but runs rather than fights.
const FLEEING_ROLES := [CitizenProfile.Role.CAREGIVER]
const GOLD := Color("ffe9a8")
const CRIMSON := Color("ff4040")
const SIDE_COLORS: Array[Color] = [Color.WHITE, GOLD, CRIMSON]
## The sides' marks: a sun for the first, a blade-cross for the second; the condemned wear the judged's blade.
const GLYPH_SIDES: Array = [[], [0b00100, 0b10101, 0b01110, 0b10101, 0b00100], [0b10001, 0b01010, 0b00100, 0b01010, 0b10001]]
const GLYPH_CONDEMNED: Array[int] = [0b00100, 0b00100, 0b00100, 0b01110, 0b00100]
const SH_SIGIL := preload("res://shaders/schism_sigil.gdshader")
const SIGIL_R := 9.0
const FIRE := [Color(0.5, 0.06, 0.05, 0.5), Color("b01818"), Color("ff4030"), Color("ffb060"), Color("fff0d0")]

var mode := "faction"
## Everyone set on a side, and how many on each.
var members: Array[Person] = []
var counts := [0, 0, 0]

## Those the wave has not reached yet: [person, side], nearest the click first.
var _pending: Array = []
var _recruit_in := RECRUIT_EVERY
var _debug: Debug


## Whom Purge would condemn at `at`: the few nearest it.
static func condemned_at(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, PURGE_R):
		var p := e as Person
		if p != null and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, PURGE_MAX)


## The living out in the open within `r` of `at`, nearest first.
static func _near(field: EnemyField, at: Vector2, r: float) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, r):
		var p := e as Person
		if p != null and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out


func _build() -> void:
	mode = String(extra.get("mode", "faction"))
	duration = DURATION + 0.5
	busy = 2.0
	match mode:
		"purge":
			var condemned := condemned_at(ctx.field, origin)
			for p in _near(ctx.field, origin, REGION).slice(0, MAX_FIGHTERS):
				_pending.append([p, 2 if p in condemned else 1])
		"custom":
			var other: Vector2 = extra.get("to", origin + Vector2(CUSTOM_R * 2.0, 0.0))
			for p in _near(ctx.field, origin, CUSTOM_R):
				if p.ground_pos.distance_to(origin) <= p.ground_pos.distance_to(other):
					_pending.append([p, 1])
			for p in _near(ctx.field, other, CUSTOM_R):
				if p.ground_pos.distance_to(other) < p.ground_pos.distance_to(origin):
					_pending.append([p, 2])
			_pending = _pending.slice(0, MAX_FIGHTERS)
		"spreading":
			var k := 0
			for p in _near(ctx.field, origin, SEED_R):
				_pending.append([p, 1 + k % 2])
				k += 1
		_:
			mode = "faction"
			for p in _near(ctx.field, origin, REGION).slice(0, MAX_FIGHTERS):
				_pending.append([p, 2 if p.soldier else 1])
	at(DURATION, _end)
	ctx.play(&"hs_strike", origin)
	ctx.play(&"nova_crack", origin, -4.0)
	if ctx.impact != null and is_inside_tree():
		_show()


func _fx_process(delta: float) -> void:
	var reach := t * WAVE_SPEED
	while not _pending.is_empty():
		var p: Person = _pending[0][0] if is_instance_valid(_pending[0][0]) else null
		if p != null and p.ground_pos.distance_to(origin) > reach:
			break
		var s: int = _pending[0][1]
		_pending.remove_at(0)
		if p != null and p.is_alive() and not p.inside:
			_enlist(p, s)
	if mode == "spreading" and t < DURATION:
		_recruit_in -= delta
		if _recruit_in <= 0.0:
			_recruit_in = RECRUIT_EVERY
			_recruit()
	if is_instance_valid(_debug):
		_debug.visible = BehaviourOverlay.shown
		if _debug.visible:
			_debug.queue_redraw()


## Whether `p` fights for its side, or only runs.
static func fights(p: Person) -> bool:
	return p.soldier or p.profile == null or not p.profile.role in FLEEING_ROLES


## Set `p` on side `s`.
func _enlist(p: Person, s: int) -> void:
	if p.side != 0:
		return
	var left := maxf(DURATION - t, 0.5)
	p.side = s
	members.append(p)
	counts[s] += 1
	var condemned := mode == "purge" and s == 2
	var glyph: Array[int] = []
	glyph.assign(GLYPH_CONDEMNED if condemned else GLYPH_SIDES[s])
	p.set_badge(glyph, SIDE_COLORS[s], left)
	if condemned and not p.soldier:
		# The condemned citizen does not stand and fight a town: it runs.
		p.mind = Person.Mind.CALM
		p.panic(origin, 0.5, &"schism")
	elif fights(p):
		p.fight(null, left, Person.SOLDIER_BLOW if p.soldier else CIVIL_BLOW, Person.FightRule.OTHER_SIDE, SIGHT)
	else:
		p.mind = Person.Mind.CALM
		p.panic(origin, 0.5, &"schism")


## Spreading Conflict: each fighter draws the people beside it onto its own side.
func _recruit() -> void:
	var fresh: Array = []
	for p in members:
		if members.size() + fresh.size() >= SPREAD_MAX:
			break
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		for e in ctx.field.in_radius(p.ground_pos, RECRUIT_R):
			var q := e as Person
			if q != null and q.side == 0 and not q.inside and ctx.rng.randf() < RECRUIT_CHANCE:
				fresh.append([q, p.side])
	for f: Array in fresh:
		if members.size() < SPREAD_MAX:
			_enlist(f[0], f[1])


## The schism lifts: the sides are gone, and those still fighting come round.
func _end() -> void:
	_pending.clear()
	for p in members:
		if not is_instance_valid(p):
			continue
		p.side = 0
		p.clear_badge()
		if p.is_alive() and p.mind == Person.Mind.FIGHT:
			p.stop_fighting()
	members.clear()


func _exit_tree() -> void:
	# Cut short (the mission restarted): nobody keeps a side.
	for p in members:
		if is_instance_valid(p):
			p.side = 0
	super()


# --- The show ----------------------------------------------------------------

func _show() -> void:
	var sp := Iso.ground_to_screen(origin)
	ctx.flash.call(Color(1.0, 0.6, 0.45, 0.6), 0.5)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(sp), Color(1.0, 0.9, 0.8), Color(0.3, 0.02, 0.02))
	ctx.impact.hitstop(0.07)
	ctx.impact.aberration(3.0, 0.5)
	ctx.impact.dim(0.5, 2.0)
	at(3.0, func() -> void: ctx.impact.dim(0.0, 0.5))
	ctx.shake.add_trauma(0.7)
	# The sigil, whole for a breath, then broken in two and the halves driven apart.
	var sigil := FxParts.quad(self, SH_SIGIL, Vector2.ONE * SIGIL_R * 2.0, ctx.ground)
	sigil.position = origin
	sigil.z_index = 3
	sigil.set_param("px", FxParts.px_for_radius(SIGIL_R))
	sigil.tween_param("reveal", 0.0, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	sigil.tween_param("split", 0.0, 1.0, 0.5, 0.55, Tween.TRANS_BACK, Tween.EASE_OUT)
	sigil.tween_param("alpha", 1.0, 0.0, 2.2, 2.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	sigil.life = 4.3
	# Each half's light on its own ground.
	for s in [1, 2]:
		var off: Vector2 = Vector2(0.70710678, -0.70710678) * (2.5 if s == 2 else -2.5)
		var light := FxParts.ground_light(self, origin + off, SIGIL_R * 0.7, SIDE_COLORS[s], 0.0)
		light.tween_param("intensity", 0.9, 0.0, 3.5, 0.5)
		light.life = 4.1
	# The crack itself: a line of fire down the middle, and sparks thrown from it.
	var crack := FxParts.beam(self, ctx.overhead, sp, 10.0, 420.0, FIRE)
	crack.set_param("intensity", 0.0)
	crack.tween_param("intensity", 0.0, 1.0, 0.12, 0.5)
	crack.tween_param("intensity", 1.0, 0.0, 0.9, 0.7, Tween.TRANS_QUAD, Tween.EASE_IN)
	crack.life = 1.65
	at(0.55, func() -> void:
		FxParts.sparks(self, ctx.overhead, sp, 40, FxParts.FIRE_LIFE, Vector2(80, 260), Vector2(30, 220))
		ctx.shake.add_trauma(0.5))
	var threads := Threads.new()
	threads.fx = self
	threads.z_index = 3
	track(threads, ctx.overhead)
	_debug = Debug.new()
	_debug.fx = self
	_debug.visible = BehaviourOverlay.shown
	track(_debug, ctx.overhead)


## Loyalty threads: for a moment after the split, each of a side tied to its side's half of the sigil.
class Threads extends Node2D:
	var fx: DivineSchismFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - (fx.t - 0.6) / 1.8, 0.0, 1.0)
		if k <= 0.0 or fx.t < 0.5:
			return
		for p in fx.members:
			if not is_instance_valid(p) or not p.is_alive() or p.side == 0:
				continue
			var off := Vector2(0.70710678, -0.70710678) * (2.5 if p.side == 2 else -2.5)
			draw_line(Iso.ground_to_screen(p.ground_pos) + Vector2(0, -14), Iso.ground_to_screen(fx.origin + off) + Vector2(0, -30),
				Color(SIDE_COLORS[p.side], 0.35 * k), 1.0)


## F4: the region, the sides' numbers and the seconds left.
class Debug extends Node2D:
	var fx: DivineSchismFx

	func _draw() -> void:
		var c := Iso.ground_to_screen(fx.origin)
		var axes := Iso.radius_to_screen(REGION)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * axes.x, sin(a) * axes.y))
		draw_polyline(pts, Color(1.0, 0.4, 0.3, 0.7), 1.0)
		var alive := [0, 0, 0]
		for p in fx.members:
			if is_instance_valid(p) and p.is_alive():
				alive[p.side] += 1
		UiTheme.text(self, c + Vector2(10, -60), "Schism (%s): %d gold, %d crimson standing of %d / %d, %.0f s" % [fx.mode,
			alive[1], alive[2], fx.counts[1], fx.counts[2], maxf(DURATION - fx.t, 0.0)], UiTheme.SIZE_SMALL, CRIMSON)
