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
##   TUMULT         no sides: each one the wave reaches is struck mad (fights anyone), frozen where it stands or panicked
##                  (runs wildly, a new far point every PANIC_REPICK) for the rest of DURATION; a caregiver is never mad.
## For T_BREAK the sigil stands whole over the town, straining; then it breaks, and the sides are laid as a wave sweeps
## out from the click (WAVE_SPEED), so their first paths are not all asked for in
## one frame. The town sees it (the book's REACH): those on no side run. The cast locks the other slots for 2 s.

const REGION := 14.0
const MAX_FIGHTERS := 140
const DURATION := 25.0
## Seconds the sigil stands whole, straining, before it breaks and the sides are laid.
const T_BREAK := 1.8
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
## Turn the Tide (level 5): how many fighters may be turned in all, and how near the click a fighter must stand to be the one.
const MAX_TURNS := 10
const TURN_PICK := 1.0
## Who is set on a side but runs rather than fights.
const FLEEING_ROLES := [CitizenProfile.Role.CAREGIVER]
const GOLD := Color("ffe9a8")
const CRIMSON := Color("ff4040")
const SIDE_COLORS: Array[Color] = [Color.WHITE, GOLD, CRIMSON]
## The sides' marks: a sun for the first, a blade-cross for the second; the condemned wear the judged's blade.
const GLYPH_SIDES: Array = [[], [0b00100, 0b10101, 0b01110, 0b10101, 0b00100], [0b10001, 0b01010, 0b00100, 0b01010, 0b10001]]
const GLYPH_CONDEMNED: Array[int] = [0b00100, 0b00100, 0b00100, 0b01110, 0b00100]
## Tumult: what the wave does to each one (the order of counts_tumult), the odds, how often the panicked pick a new far
## point, and each state's mark: a red blade, a white bar, a yellow zig-zag.
const MAD := 0
const FROZEN := 1
const PANIC := 2
const MAD_CHANCE := 0.4
const FROZEN_CHANCE := 0.3
const PANIC_REPICK := Vector2(3.0, 4.0)
## A panicked one this close to its point has arrived and picks the next at once.
const PANIC_ARRIVED := 0.5
## A panicked one's next point is at least this far from where it stands.
const PANIC_MIN_RUN := 6.0
const MAD_RED := Color("e02828")
const FROZEN_WHITE := Color.WHITE
const PANIC_YELLOW := Color("ffd23a")
const COLORS_TUMULT: Array[Color] = [MAD_RED, FROZEN_WHITE, PANIC_YELLOW]
const GLYPHS_TUMULT: Array = [[0b00011, 0b00110, 0b01100, 0b10100, 0b11000], [0b00000, 0b11111, 0b11111, 0b11111, 0b00000],
	[0b00110, 0b01100, 0b00110, 0b01100, 0b00110]]
const SH_SIGIL := preload("res://shaders/schism_sigil.gdshader")
const SIGIL_R := 9.0
const FIRE := [Color(0.5, 0.06, 0.05, 0.5), Color("b01818"), Color("ff4030"), Color("ffb060"), Color("fff0d0")]

var mode := "faction"
## Everyone set on a side, and how many on each.
var members: Array[Person] = []
var counts := [0, 0, 0]
## Tumult: what each one was struck with (MAD, FROZEN or PANIC), and how many of each.
var states := {}
var counts_tumult := [0, 0, 0]

## Those the wave has not reached yet: [person, side], nearest the click first.
var _pending: Array = []
var _recruit_in := RECRUIT_EVERY
## Tumult: the panicked, [person, effect time of their next new point].
var _panicked: Array = []
var _debug: Debug
## This cast's region, fighter cap and length at its ability level (REGION, MAX_FIGHTERS and DURATION at level 1).
var lv_region := REGION
var lv_max_fighters := MAX_FIGHTERS
var lv_duration := DURATION
## Turn the Tide: whether this cast has it, and how many it has turned.
var turns := 0
var _tide := false
## When each was set on its side (the effect's clock), for its thread; the sides' sparkles, by side.
var _joined := {}
var _sparkles: Array = [null, null, null]
var _sky: QuadFx
var _ground: QuadFx


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
	lv_region = float(PowerBook.stat(extra, "schism", "REGION", REGION))
	lv_max_fighters = int(PowerBook.stat(extra, "schism", "MAX_FIGHTERS", MAX_FIGHTERS))
	lv_duration = float(PowerBook.stat(extra, "schism", "DURATION", DURATION))
	_tide = PowerBook.twist_at(extra, "schism")
	mode = String(extra.get("mode", "faction"))
	duration = T_BREAK + lv_duration + 0.5
	busy = T_BREAK + 1.0
	match mode:
		"purge":
			var condemned := condemned_at(ctx.field, origin)
			for p in _near(ctx.field, origin, lv_region).slice(0, lv_max_fighters):
				_pending.append([p, 2 if p in condemned else 1])
		"custom":
			var other: Vector2 = extra.get("to", origin + Vector2(CUSTOM_R * 2.0, 0.0))
			for p in _near(ctx.field, origin, CUSTOM_R):
				if p.ground_pos.distance_to(origin) <= p.ground_pos.distance_to(other):
					_pending.append([p, 1])
			for p in _near(ctx.field, other, CUSTOM_R):
				if p.ground_pos.distance_to(other) < p.ground_pos.distance_to(origin):
					_pending.append([p, 2])
			_pending = _pending.slice(0, lv_max_fighters)
		"spreading":
			var k := 0
			for p in _near(ctx.field, origin, SEED_R):
				_pending.append([p, 1 + k % 2])
				k += 1
		"tumult":
			for p in _near(ctx.field, origin, lv_region).slice(0, lv_max_fighters):
				_pending.append([p, 0])
		_:
			mode = "faction"
			for p in _near(ctx.field, origin, lv_region).slice(0, lv_max_fighters):
				_pending.append([p, 2 if p.soldier else 1])
	at(T_BREAK, _break)
	at(T_BREAK + lv_duration, _end)
	ctx.play(&"dom_strain", origin)
	if _staged():
		_strain_show()


## Turn the Tide: true at level 5 while the sides fight (after the busy lock, before the schism lifts), in any mode but TUMULT, until MAX_TURNS.
func can_follow_up() -> bool:
	return _tide and not finished and mode != "tumult" and turns < MAX_TURNS and t >= T_BREAK + 1.0 and t < T_BREAK + lv_duration


## Turn the Tide: the member of a side nearest the click (within TURN_PICK; a tie goes to the first set on a side) goes over to the other side.
func follow_up(at_pos: Vector2, _extra: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var best: Person = null
	var best_d := TURN_PICK
	for p in members:
		if not is_instance_valid(p) or p.side == 0 or not p.is_alive() or p.inside:
			continue
		var d := p.ground_pos.distance_to(at_pos)
		if d <= best_d and (best == null or d < best_d):
			best = p
			best_d = d
	if best == null:
		return false
	var to := 3 - best.side
	counts[best.side] -= 1
	counts[to] += 1
	best.side = to
	best.stop_fighting()
	_lay_side(best, to, maxf(lv_duration - (t - T_BREAK), 0.5))
	turns += 1
	return true


## Turn the Tide's preview: the one fighter the click picks.
func follow_up_area() -> Dictionary:
	return {"shape": "circle", "r": TURN_PICK}


func _staged() -> bool:
	return ctx.impact != null and is_inside_tree()


## The sigil breaks: from now the wave lays the sides.
func _break() -> void:
	ctx.play(&"dom_break", origin)
	if _staged():
		_break_show()


func _fx_process(delta: float) -> void:
	if t < T_BREAK:
		return
	var reach := (t - T_BREAK) * WAVE_SPEED
	while not _pending.is_empty():
		var p: Person = _pending[0][0] if is_instance_valid(_pending[0][0]) else null
		if p != null and p.ground_pos.distance_to(origin) > reach:
			break
		var s: int = _pending[0][1]
		_pending.remove_at(0)
		if p != null and p.is_alive() and not p.inside:
			if mode == "tumult":
				_strike(p)
			else:
				_enlist(p, s)
	if mode == "tumult" and t < T_BREAK + lv_duration:
		_repick_panicked()
	if mode == "spreading" and t < T_BREAK + lv_duration:
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
	if p.side != 0 or p.resists_mind():
		return
	var left := maxf(lv_duration - (t - T_BREAK), 0.5)
	p.side = s
	members.append(p)
	_joined[p] = t
	counts[s] += 1
	_lay_side(p, s, left)


## `p` (already on side `s` and counted) takes up its side: the mark, and the fight (or, for the condemned citizen and the one who cannot fight, the run).
func _lay_side(p: Person, s: int, left: float) -> void:
	var sparkle: PixelParticles = _sparkles[s]
	if is_instance_valid(sparkle):
		sparkle.burst(4, {"offset": Iso.ground_to_screen(p.ground_pos) - sparkle.position + Vector2(0, -8), "radius": 4.0,
			"speed": Vector2(6, 18), "alt": Vector2(0, 6), "alt_speed": Vector2(12, 36), "life": Vector2(0.4, 0.8),
			"size": Vector2(1, 1)})
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


## Tumult: the wave reaches `p` -- mad, frozen where it stands, or panicked, rolled with the cast's rng. A caregiver is
## never mad: it freezes or panics, half and half.
func _strike(p: Person) -> void:
	if p.resists_mind():
		return
	var left := maxf(lv_duration - (t - T_BREAK), 0.5)
	var state := FROZEN
	if not fights(p):
		state = FROZEN if ctx.rng.randf() < 0.5 else PANIC
	else:
		var roll := ctx.rng.randf()
		if roll < MAD_CHANCE:
			state = MAD
		elif roll < MAD_CHANCE + FROZEN_CHANCE:
			state = FROZEN
		else:
			state = PANIC
	var glyph: Array[int] = []
	glyph.assign(GLYPHS_TUMULT[state])
	match state:
		MAD:
			p.fight(null, left, Person.SOLDIER_BLOW if p.soldier else CIVIL_BLOW, Person.FightRule.ANYONE, SIGHT)
		FROZEN:
			if not p.compel(p.ground_pos, left, Person.WILL_ABSOLUTE, FROZEN_WHITE, false, &"", glyph):
				return
		_:
			if not p.compel(_panic_point(p), left, Person.WILL_ABSOLUTE, PANIC_YELLOW, true, &"", glyph):
				return
			_panicked.append([p, t + ctx.rng.randf_range(PANIC_REPICK.x, PANIC_REPICK.y)])
	p.set_badge(glyph, COLORS_TUMULT[state], left)
	states[p] = state
	counts_tumult[state] += 1
	var sparkle: PixelParticles = _sparkles[2 if state == MAD else 1]
	if is_instance_valid(sparkle):
		sparkle.burst(4, {"offset": Iso.ground_to_screen(p.ground_pos) - sparkle.position + Vector2(0, -8), "radius": 4.0,
			"speed": Vector2(6, 18), "alt": Vector2(0, 6), "alt_speed": Vector2(12, 36), "life": Vector2(0.4, 0.8),
			"size": Vector2(1, 1)})


## Where a panicked `p` runs next: a point within REGION of the click and at least PANIC_MIN_RUN from where it stands,
## on the field and on walkable ground.
func _panic_point(p: Person) -> Vector2:
	var to := p.ground_pos
	for attempt in 6:
		var a := ctx.rng.randf() * TAU
		to = origin + Vector2(cos(a), sin(a)) * lv_region * sqrt(ctx.rng.randf())
		to = to.clamp(p.bounds.position, p.bounds.end)
		if to.distance_to(p.ground_pos) >= PANIC_MIN_RUN:
			break
	if p.grid != null:
		var free := p.grid.nearest_walkable(to, 8)
		to = free if free != Vector2.INF else p.ground_pos
	return to


## Tumult: those running wildly pick a new far point every PANIC_REPICK seconds, or as soon as they reach the last one
## (within PANIC_ARRIVED), so they never stand still until the end.
func _repick_panicked() -> void:
	for entry: Array in _panicked:
		var p: Person = entry[0] if is_instance_valid(entry[0]) else null
		if p == null or not p.is_alive() or p.mind != Person.Mind.COMPELLED:
			continue
		if t < float(entry[1]) and p.ground_pos.distance_to(p.anchor) > PANIC_ARRIVED:
			continue
		var left := maxf(T_BREAK + lv_duration - t, 0.5)
		var glyph: Array[int] = []
		glyph.assign(GLYPHS_TUMULT[PANIC])
		p.compel(_panic_point(p), left, Person.WILL_ABSOLUTE, PANIC_YELLOW, true, &"", glyph)
		entry[1] = t + ctx.rng.randf_range(PANIC_REPICK.x, PANIC_REPICK.y)


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
	_panicked.clear()
	for p: Person in states:
		if not is_instance_valid(p):
			continue
		p.clear_badge()
		if not p.is_alive():
			continue
		if states[p] == MAD:
			p.stop_fighting()
		else:
			p.release_compulsion()
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

const SKY_UP := 150.0
const SKY_R := 150.0
const SKY_SQUASH := 0.42
const THREAD_SECONDS := 0.9
const GOLD_LIFE := [Color("fffdf0"), Color("ffe9a8"), Color("e8c070"), Color(0.8, 0.6, 0.3, 0.5)]
const CRIMSON_LIFE := [Color("fff0d0"), Color("ff8050"), Color("ff4040"), Color("b01818"), Color(0.4, 0.05, 0.05, 0.5)]
const SOLAR := [Color(0.9, 0.75, 0.4, 0.35), Color("e8c070"), Color("ffe09a"), Color("fff2c8"), Color("fffdf0")]
## How long the fissure on the ground takes to cool and close at the end.
const FISSURE_FADE := 2.5


## Where the sky sigil hangs, on screen; and where each side's half ends up once it has broken.
func sky_point() -> Vector2:
	return Iso.ground_to_screen(origin) + Vector2(0, -SKY_UP)


func half_point(s: int) -> Vector2:
	return sky_point() + Vector2(SKY_R * 0.55 * (1.0 if s == 2 else -1.0), 0.0)


## The strain: the sky darkens and the Dominion sigil stands whole over the town and on the ground under it, gold;
## it beats twice, and crimson creeps into one half.
func _strain_show() -> void:
	var sp := Iso.ground_to_screen(origin)
	ctx.impact.dim(0.85, 0.6)
	_sky = FxParts.quad(self, SH_SIGIL, Vector2(SKY_R * 2.0, SKY_R * 2.0 * SKY_SQUASH), ctx.overhead)
	_sky.position = sky_point()
	_sky.z_index = 6
	_sky.set_param("screen", true)
	_sky.set_param("px", 1.0 / (SKY_R * 0.62))
	_sky.set_param("sundered", 0.0)
	_sky.tween_param("reveal", 0.0, 1.0, T_BREAK * 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_sky.tween_param("sundered", 0.0, 0.55, T_BREAK * 0.45, T_BREAK * 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
	_ground = FxParts.quad(self, SH_SIGIL, Vector2.ONE * SIGIL_R * 2.0, ctx.ground)
	_ground.position = origin
	_ground.z_index = 3
	_ground.set_param("px", FxParts.px_for_radius(SIGIL_R))
	_ground.set_param("sundered", 0.0)
	_ground.tween_param("reveal", 0.0, 1.0, T_BREAK * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_ground.tween_param("sundered", 0.0, 0.55, T_BREAK * 0.45, T_BREAK * 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
	var halo := FxParts.bloom(self, sky_point(), SKY_R * 1.3, GOLD, 0.0, SKY_SQUASH * 1.3)
	halo.tween_param("intensity", 0.0, 0.45, T_BREAK, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	halo.tween_param("intensity", 0.6, 0.0, 1.2, T_BREAK)
	halo.life = T_BREAK + 1.25
	# Two beats, the second redder: a pulse of light on the ground and a shudder.
	for k in 2:
		at(T_BREAK * (0.4 + 0.3 * float(k)), _beat.bind(k))
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, GOLD_LIFE, 60.0, T_BREAK, {
		"radius": FxParts.particle_radius(7.0), "speed": Vector2(20, 60), "dir": PixelParticles.Dir.INWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(60, 150), "life": Vector2(0.7, 1.2), "size": Vector2(1, 2)})
	motes.gravity = -90.0
	motes.streak_len = 0.05
	for s in [1, 2]:
		var sparkle := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, GOLD_LIFE if s == 1 else CRIMSON_LIFE)
		sparkle.gravity = -20.0
		sparkle.auto_free = false
		sparkle.z_index = 7
		_sparkles[s] = sparkle
	var threads := Threads.new()
	threads.fx = self
	threads.z_index = 5
	track(threads, ctx.overhead)
	_debug = Debug.new()
	_debug.fx = self
	_debug.visible = BehaviourOverlay.shown
	track(_debug, ctx.overhead)


func _beat(k: int) -> void:
	var beat := FxParts.ground_light(self, origin, SIGIL_R * 1.2, GOLD if k == 0 else Color(1.0, 0.5, 0.35), 0.9)
	beat.tween_param("intensity", 0.9, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	beat.life = 0.42
	ctx.shake.add_trauma(0.2 + 0.1 * float(k))
	ctx.play(&"jg_punch", origin, -10.0 if k == 0 else -7.0)  # the same two levels as -10 + 3k, literal for the loudness measure


## The break: lightning down the middle, the sigil torn in two and the halves driven apart -- one white-gold, one
## crimson -- shards of both thrown out, a fissure burned into the ground, and each half's light and embers left
## hanging over its own side.
func _break_show() -> void:
	var sp := Iso.ground_to_screen(origin)
	var sky := sky_point()
	ctx.flash.call(Color(1.0, 0.7, 0.55, 0.3), 0.45)
	ctx.impact.impact_frame(0.06, ctx.impact.focus_of(sp), Color(1.0, 0.92, 0.8), Color(0.3, 0.02, 0.02))
	ctx.impact.hitstop(0.09)
	ctx.impact.aberration(3.5, 0.55)
	ctx.shake.add_trauma(0.9)
	ctx.shake.kick(Vector2(0, 5))
	ctx.impact.dim(0.45, 1.2)
	at(t + 4.5, func() -> void: ctx.impact.dim(0.0, 0.5))
	for q: QuadFx in [_sky, _ground]:
		if is_instance_valid(q):
			q.set_param("sundered", 1.0)
			q.tween_param("split", 0.0, 1.0, 0.45, 0.0, Tween.TRANS_BACK, Tween.EASE_OUT)
	if is_instance_valid(_sky):
		_sky.tween_param("alpha", 1.0, 0.0, 2.2, 3.4, Tween.TRANS_QUAD, Tween.EASE_IN)
		_sky.life = _sky.age + 5.7
	if is_instance_valid(_ground):
		_ground.tween_param("alpha", 1.0, 0.0, 2.2, 1.6, Tween.TRANS_QUAD, Tween.EASE_IN)
		_ground.life = _ground.age + 3.9
	# The stroke that breaks it: two bolts from above the sigil to the ground, and a line of fire where they land.
	for k in 2:
		var bolt := LightningBolt.new()
		bolt.rng.seed = ctx.rng.randi()
		bolt.from = sky + Vector2(0, -SKY_R * SKY_SQUASH - 40.0)
		bolt.to = sp
		bolt.life = 0.55 - 0.15 * float(k)
		bolt.thickness = 2.4 - 0.9 * float(k)
		bolt.branches = 3
		bolt.glow = Color("ff5038") if k == 0 else Color("ffd27a")
		bolt.z_index = 7
		track(bolt, ctx.overhead)
	var crack := FxParts.beam(self, ctx.overhead, sp, 14.0, SKY_UP + 40.0, FIRE)
	crack.set_param("taper", 0.0)
	crack.z_index = 5
	crack.tween_param("intensity", 1.0, 0.0, 1.3, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN)
	crack.life = 1.45
	FxParts.sparks(self, ctx.overhead, sp, 50, FxParts.FIRE_LIFE, Vector2(80, 280), Vector2(30, 240))
	# Two rings across the region, one of each colour, and the air bending under them.
	for k in 2:
		var ring := FxParts.shockwave(self, origin, lv_region, SOLAR if k == 0 else FIRE)
		ring.set_param("thickness", 0.05)
		if k == 1:
			ring.set_param("progress", 0.0)
		ring.tween_param("progress", 0.03, 1.0, 0.7, 0.12 * float(k), Tween.TRANS_CUBIC, Tween.EASE_OUT)
		ring.tween_param("fade", 1.0, 0.0, 0.3, 0.45 + 0.12 * float(k))
		ring.life = 0.9
	var bend := FxParts.refract_ring(self, origin, lv_region * 0.8, CRIMSON)
	bend.set_param("strength", 9.0)
	bend.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	bend.life = 0.52
	# Each half: rays from where it hangs, shards thrown its own way, its light on its own ground, and what drifts
	# off it afterwards -- gold dust falling on one side, embers rising on the other.
	for s in [1, 2]:
		var way := 1.0 if s == 2 else -1.0
		var col: Color = SIDE_COLORS[s]
		var life: Array = GOLD_LIFE if s == 1 else CRIMSON_LIFE
		var rays := FxParts.screen_rays(self, half_point(s), 230.0, col, 48.0, 0.75)
		rays.set_param("inner", 0.2)
		rays.tween_param("reach", 0.25, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
		rays.tween_param("intensity", 0.5, 0.0, 2.6, 0.4)
		rays.life = 3.05
		var shards := FxParts.particles(self, ctx.overhead, sky, PixelParticles.Shape.STREAK, life)
		shards.gravity = 220.0
		shards.drag = 0.8
		shards.streak_len = 0.06
		shards.z_index = 7
		var mid := 0.0 if s == 2 else PI
		shards.burst(46, {"radius": 10.0, "speed": Vector2(120, 340), "angle": Vector2(mid - 0.9, mid + 0.9), "alt": Vector2(0, 10),
			"alt_speed": Vector2(-20, 160), "life": Vector2(0.5, 1.1), "size": Vector2(1, 3)})
		var off: Vector2 = Vector2(0.70710678, -0.70710678) * 3.0 * way
		var light := FxParts.ground_light(self, origin + off, SIGIL_R * 0.8, col, 0.6)
		light.tween_param("intensity", 0.6, 0.2, 2.5)
		light.tween_param("intensity", 0.2, 0.0, 2.0, 5.0)
		light.life = 7.05
		var drift := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin + off * 1.4), PixelParticles.Shape.SQUARE, life,
			26.0, 7.0, {"radius": FxParts.particle_radius(5.0), "speed": Vector2(2, 10),
			"alt": Vector2(0, 60) if s == 1 else Vector2(0, 8), "alt_speed": Vector2(-50, -15) if s == 1 else Vector2(15, 55),
			"life": Vector2(1.2, 2.2), "size": Vector2(1, 1)})
		drift.drag = 0.4
	var fissure := Fissure.new()
	fissure.fx = self
	fissure.z_index = 2
	fissure.build(ctx.rng)
	track(fissure, ctx.ground)


## The fissure the break burns into the ground: a jagged line through the click, down the screen, glowing while the
## schism lasts and cooling shut at its end. Drawn in ground units on the ground plane.
class Fissure extends Node2D:
	var fx: DivineSchismFx
	var points := PackedVector2Array()

	func build(rng: RandomNumberGenerator) -> void:
		var along := Vector2(0.70710678, 0.70710678)
		var across := Vector2(0.70710678, -0.70710678)
		var steps := 22
		for i in steps + 1:
			var k := float(i) / float(steps) * 2.0 - 1.0
			points.append(fx.origin + along * k * SIGIL_R + across * rng.randf_range(-0.35, 0.35) * (1.0 - absf(k) * 0.6))

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var since := fx.t - T_BREAK
		var a := clampf(minf(since / 0.15, (fx.duration - fx.t) / FISSURE_FADE), 0.0, 1.0)
		if a <= 0.0:
			return
		var heat := clampf(1.0 - since / 6.0, 0.0, 1.0)
		var flick := 0.85 + 0.15 * sin(fx.t * 9.0)
		draw_polyline(points, Color(0.25, 0.02, 0.02, 0.8 * a), 0.3)
		draw_polyline(points, Color(1.0, 0.25, 0.15, (0.5 + 0.4 * heat) * a * flick), 0.14)
		draw_polyline(points, Color(1.0, 0.85, 0.55, heat * a), 0.05)


## Loyalty threads: as each is set on a side, a thread to its side's half of the sigil, fading on its own.
class Threads extends Node2D:
	var fx: DivineSchismFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		for p: Variant in fx._joined:
			var k := 1.0 - (fx.t - float(fx._joined[p])) / THREAD_SECONDS
			if k <= 0.0 or not is_instance_valid(p) or not (p as Person).is_alive() or (p as Person).side == 0:
				continue
			draw_line(Iso.ground_to_screen((p as Person).ground_pos) + Vector2(0, -14), fx.half_point((p as Person).side),
				Color(SIDE_COLORS[(p as Person).side], 0.55 * k), 1.0)


## F4: the region, the sides' numbers and the seconds left.
class Debug extends Node2D:
	var fx: DivineSchismFx

	func _draw() -> void:
		var c := Iso.ground_to_screen(fx.origin)
		var axes := Iso.radius_to_screen(fx.lv_region)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * axes.x, sin(a) * axes.y))
		draw_polyline(pts, Color(1.0, 0.4, 0.3, 0.7), 1.0)
		if fx.mode == "tumult":
			var left := [0, 0, 0]
			for p: Person in fx.states:
				if is_instance_valid(p) and p.is_alive():
					left[fx.states[p]] += 1
			UiTheme.text(self, c + Vector2(10, -60), "Schism (tumult): %d mad, %d frozen, %d panicked standing of %d / %d / %d, %.0f s" % [
				left[0], left[1], left[2], fx.counts_tumult[0], fx.counts_tumult[1], fx.counts_tumult[2],
				maxf(T_BREAK + fx.lv_duration - fx.t, 0.0)], UiTheme.SIZE_SMALL, CRIMSON)
			return
		var alive := [0, 0, 0]
		for p in fx.members:
			if is_instance_valid(p) and p.is_alive():
				alive[p.side] += 1
		UiTheme.text(self, c + Vector2(10, -60), "Schism (%s): %d gold, %d crimson standing of %d / %d, %.0f s" % [fx.mode,
			alive[1], alive[2], fx.counts[1], fx.counts[2], maxf(T_BREAK + fx.lv_duration - fx.t, 0.0)], UiTheme.SIZE_SMALL, CRIMSON)
