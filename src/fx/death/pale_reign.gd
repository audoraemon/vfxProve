class_name PaleReignFx
extends FxTimeline
## Pale Reign (Death, Tier IV; spec 5.6): a click, and the colour drains out of a district of RADIUS for SPAN -- it turns
## grey and silent.
## - Everyone inside out in the open crawls at CRAWL of their pace (hold_pace under this effect's id), let go as they leave
##   and when the span ends.
## - Every second the fires inside gutter (FireManager.douse, Door to the Deep's way), and the district is hushed for the
##   span (Crowd.hush_at: nobody in it shouts or cries out, and a bell tower in it makes no sound -- the bell is never
##   silenced, so it rings on after if the night still calls). The rest of the town hears as ever; frights, the alarm and
##   the town coming to look go on as for any loud power.
## - Every EVERY the weakest one still inside out in the open dies without a sound, killed as &"pale" (a whole body; a quiet
##   kind, DeathVoices.QUIET_KINDS). Weakest: the sick, then the hurt (health under their own full: a knight's is
##   HEALTH_KNIGHT), then the frail (Death Mark's), then the nearest the middle; a tie to the lower instance id. No luck.
##   The guised (Corpse Guise hides the faithful) and decoys (Mirrorfold's glass twins) are passed over.
## - Every whole-body death in the district during the span (any kind the Remains ledger keeps: the reign's own, a
##   servant's bite) rises at once as the god's pale servant, MAX_RISEN a cast at most: a zombie in their own look with
##   ash-grey eyes (DeathParts.zombie, eyes ASH), in this effect's own Visitors pack, for SERVANT_LIFE from its rising; the
##   body is taken off the ledger (Remains.take hides the corpse). The ledger is on for a Pale night (Remains.wants); were
##   it off (a test, the sandbox), the reign keeps it on for itself and puts it back as it was at its end.
## - The horde (R10): with the reign's first tick (its first death) HORDE_START pale ghosts pour out of the middle
##   (DeathParts.pale_ghost: wraiths in a pale tint, through walls, at PALE_GHOST_PACE of a walk, in this effect's own
##   `horde` pack). They run the district for the nearest living person inside it -- never one outside RADIUS, never a
##   guised one -- and a ghost's touch kills as &"pale" (a whole body, so it rises as above). Every death inside the
##   district during the span (anyone's: the reign's, a ghost's, a servant's) adds one more ghost where the body fell,
##   while fewer than HORDE_CAP are up and the horde has killed fewer than HORDE_KILLS: it snowballs to a cap that holds
##   the frame rate. At its HORDE_KILLS-th kill, or at SPAN, the horde sinks (recalled, gone within FADE).
## Loud (PowerBook.REACH): the danger counts from the first death (IMPACT = EVERY). Over, or cut short, or freed without its
## end (_exit_tree), every pace is let go and the servants and the ghosts are gone.

## The district, how long it reigns, the pace it leaves, a death every EVERY, a servant's 20 s.
const RADIUS := 10.0
const SPAN := 16.0
const CRAWL := 0.3
const EVERY := 1.5
const SERVANT_LIFE := 20.0
## At most this many of the dead rise in one reign.
const MAX_RISEN := 16
## The horde: how many pour out at the first death; at most this many up at once, and its kills before it sinks.
const HORDE_START := 4
const HORDE_CAP := 24
const HORDE_KILLS := 24
## The first ghosts pour out on a ring this far round the middle.
const POUR_R := 1.0
## How often the fires inside are doused.
const DOUSE_EVERY := 1.0
## The colour drains out over T_DRAIN and comes back over FADE once the span is over.
const T_DRAIN := 1.0
const FADE := 1.0
## The grey the veil multiplies the district by (Yesterday's Door's veil, in ash instead of sepia).
const GREY := Color(0.8, 0.82, 0.86)
const SHADER := preload("res://shaders/pale_reign.gdshader")
## Death's palette: bone white, ash grey; no blood.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const ASH_FALL := [Color("d8d8d8"), Color("a8a8aa"), Color(0.55, 0.55, 0.57, 0.6), Color(0.4, 0.4, 0.42, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]

## The servants' pack; the dead, in the order they fell; when the first fell; the fires put out.
var visitors: Visitors
## The horde's own pack, how many it has killed (its touch kills), and how many ghosts were made in all.
var horde: Visitors
var horde_kills := 0
var ghosts_made := 0
var taken: Array[Person] = []
var first_kill_at := -1.0
var doused := 0
## How many of the dead have risen.
var risen := 0
## Whether the span is over (the district has its colour, pace and fires back).
var over := false

## Instance id -> Person: everyone this effect holds at CRAWL.
var _held := {}
## The servants up: {a: Animal, until: float (on this effect's clock)}.
var _servants: Array[Dictionary] = []
var _next_kill := EVERY
var _next_douse := 0.0
## Whether this effect turned the town's ledger on (it was off), to put it back.
var _lit_ledger := false
## The reign's own death being dealt now: its tick (a servant's 20 s count from it), else -1.
var _reaping_at := -1.0
## Whether the first ghosts have poured out, and whether the horde has been sent down (its kills spent, or the span over).
var _poured := false
var _sunk := false
var _drain: QuadFx


func _build() -> void:
	duration = SPAN + SERVANT_LIFE + FADE + 1.0  # a ceiling: _lift() and _expire() set the real end
	busy = T_DRAIN
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	horde = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	horde.bitten.connect(_on_touch)
	ctx.field.enemy_killed.connect(_on_killed)
	if ctx.crowd != null:
		ctx.crowd.hush_at(origin, RADIUS, SPAN)
		if ctx.crowd.remains != null and not ctx.crowd.remains.enabled:
			ctx.crowd.remains.enabled = true
			_lit_ledger = true
	ctx.play(&"pale_drone", origin, 0.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	# Multiplied in over everything standing in the circle (the node's material): the street goes a cold ash grey.
	var veil := Veil.new()
	veil.fx = self
	veil.position = sp
	veil.z_index = 1
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	veil.material = mul
	track(veil, ctx.overhead_back)
	# And its colour drained: the ground, the houses and the people inside go to the grey of their own light.
	if ctx.distort != null:
		_drain = FxParts.quad(self, SHADER, Iso.radius_to_screen(RADIUS) * 2.0, ctx.distort)
		_drain.position = sp
		_drain.set_param("amount", 0.0)
	# Ash drifting down over the district for the span.
	var ash := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, ASH_FALL, 14.0, SPAN - 1.0,
		{"radius": FxParts.particle_radius(RADIUS) * 0.8, "speed": Vector2(1, 4), "alt": Vector2(20, 50),
		"alt_speed": Vector2(-8, -3), "life": Vector2(2.0, 3.5), "size": Vector2(1, 1)})
	ash.gravity = 2.0


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	horde.step(delta)
	if is_instance_valid(_drain):
		var k := shown()
		_drain.set_param("amount", k)
		_drain.visible = k > 0.0  # past the fade: no screen copy for nothing
	if not over:
		_crawl()
		# The fires and the deaths run on the reign's own clock, a tick at a time, so a long frame misses none.
		while _next_douse <= SPAN and t >= _next_douse:
			_douse()
			_next_douse += DOUSE_EVERY
		while _next_kill <= SPAN + 0.0001 and t >= _next_kill:
			_reap(_next_kill)
			if not _poured:
				_pour()
			_next_kill += EVERY
		if t >= SPAN:
			_lift()
	_expire()


## 0..1 how grey the district is now: drained over T_DRAIN, its colour back over FADE from SPAN.
func shown() -> float:
	return clampf(minf(t / T_DRAIN, 1.0 - (t - SPAN) / FADE), 0.0, 1.0)


## Everyone inside out in the open crawls; whoever left (or went in, or fell) is let go.
func _crawl() -> void:
	var inside := {}
	for e in ctx.field.in_radius(origin, RADIUS):
		var p := e as Person
		if p == null or p.inside:
			continue
		var id := p.get_instance_id()
		inside[id] = true
		if not _held.has(id):
			_held[id] = p
			p.hold_pace(get_instance_id(), CRAWL)
	for id in _held.keys():
		if not inside.has(id):
			_let_go(id)


func _let_go(id: int) -> void:
	# Untyped until checked: one who left the town (Crowd.escape) is freed, and assigning a freed one to a Person errors.
	var p = _held.get(id)
	_held.erase(id)
	if is_instance_valid(p):
		(p as Person).free_pace(get_instance_id())


func _let_all_go() -> void:
	for id in _held.keys():
		_let_go(id)


## The fires within the district gutter.
func _douse() -> void:
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	if fires == null or ctx.env == null:
		return
	for s in ctx.env.near(origin, RADIUS):
		if not is_instance_valid(s) or s.destroyed or s.distance_to(origin) > RADIUS or not fires.is_burning(s):
			continue
		fires.douse(s)
		if fires.is_burning(s):
			continue
		doused += 1
		if DominionParts.staged(self):
			FxParts.smoke(self, Iso.ground_to_screen(s.center()), 14.0, 20.0, 0.8, Vector2(12, 30), Vector2(3, 6), Vector2(1.0, 2.0), Color(0, 0, 0, 0), DUST)


## The weakest one still inside out in the open: the sick, then the hurt, then the frail, then the nearest the middle; a tie
## to the lower instance id. null if nobody is left.
func weakest() -> Person:
	var best: Person = null
	var best_rank := 0
	var best_d := INF
	for e in ctx.field.in_radius(origin, RADIUS):
		var p := e as Person
		if p == null or p.inside or p.guised() or p.has_meta(&"decoy"):
			continue
		var rank := _rank(p)
		var d := p.ground_pos.distance_squared_to(origin)
		if best == null or rank < best_rank or (rank == best_rank and (d < best_d
				or (d == best_d and p.get_instance_id() < best.get_instance_id()))):
			best = p
			best_rank = rank
			best_d = d
	return best


## 0 sick, 1 hurt, 2 frail, 3 none of these.
static func _rank(p: Person) -> int:
	if p.sick_left > 0.0:
		return 0
	if p.health < full_health(p):
		return 1
	if p.statuses.has(&"frail"):
		return 2
	return 3


## A person's full health: a knight's (HEALTH_KNIGHT), a soldier's, a citizen's.
static func full_health(p: Person) -> float:
	if p.soldier and p.corps == Person.Corps.KNIGHT:
		return Person.HEALTH_KNIGHT
	return Person.HEALTH_SOLDIER if p.soldier else Person.HEALTH_CITIZEN


## One death (the tick at `when`): the weakest dies without a sound (and rises: _on_killed()).
func _reap(when: float) -> void:
	var p := weakest()
	if p == null:
		return
	_let_go(p.get_instance_id())
	_reaping_at = when
	var killed := ctx.field.kill(p, &"pale", origin)
	_reaping_at = -1.0
	if not killed:
		return
	taken.append(p)
	if first_kill_at < 0.0:
		first_kill_at = when
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(p.ground_pos), 5.0, 24.0, 0.3, Vector2(6, 16), Vector2(2, 4), Vector2(0.6, 1.2), Color(0, 0, 0, 0), DUST)


## Every death in the district during the span adds a ghost to the horde where the body fell (_ghost_at()), and every
## whole-body one rises (the Remains ledger heard it first: it was connected at the crowd's setup, before this): the
## reign's own, a ghost's touch, a servant's bite, anything that leaves a body; MAX_RISEN at most.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if over:
		return
	var p := e as Person
	if p == null or p.ground_pos.distance_to(origin) > RADIUS:
		return
	# A pale death not of the reign's own reaping is a ghost's touch: the horde counts it only after this (Visitors.kills, then
	# _on_touch()), so it is counted here first -- the touch that is its HORDE_KILLS-th kill adds no ghost (it sinks then).
	_ghost_at(p.ground_pos, kind == &"pale" and _reaping_at < 0.0)
	if p.inside or risen >= MAX_RISEN or not Remains.BODY_KINDS.has(kind):
		return
	_rise(p, _reaping_at if _reaping_at >= 0.0 else t)


## The reign's first tick: HORDE_START ghosts pour out of the middle.
func _pour() -> void:
	_poured = true
	for i in HORDE_START:
		_ghost_at(origin + Vector2.from_angle(TAU * float(i) / float(HORDE_START)) * POUR_R)


## One more ghost at `at`, while fewer than HORDE_CAP are up, the horde has killed fewer than HORDE_KILLS and the span runs. `touch`: the
## death is a ghost's touch the horde has not counted yet, so it counts here.
func _ghost_at(at: Vector2, touch := false) -> void:
	var kills := horde_kills + (1 if touch else 0)
	if horde == null or not (horde.living().size() < HORDE_CAP and kills < HORDE_KILLS and t < SPAN):
		return
	DeathParts.pale_ghost(horde, at, origin, RADIUS)
	ghosts_made += 1
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(at), 5.0, 20.0, 0.3, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)


## A ghost touched someone (Visitors.bitten): its kills are counted (Visitors.kills: only a touch that killed); at the
## HORDE_KILLS-th the horde sinks.
func _on_touch(_a: Animal, _who: Person, _first: bool) -> void:
	horde_kills = horde.kills
	if horde_kills >= HORDE_KILLS:
		_sink()


## The horde sinks: every ghost goes back where it came up and is gone within FADE (a puff of dust where each stood).
func _sink() -> void:
	if _sunk or horde == null:
		return
	_sunk = true
	if DominionParts.staged(self):
		for a in horde.living():
			FxParts.smoke(self, Iso.ground_to_screen(a.ground_pos), 4.0, 20.0, 0.3, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)
	horde.recall(FADE)


## `p`'s body gets up where it fell: a zombie in their own look, ash-grey eyes, for SERVANT_LIFE from `when`.
func _rise(p: Person, when: float) -> void:
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	var r := DeathParts.fresh_remain(rem, p)
	if r == null:
		return
	var a := DeathParts.zombie(visitors, r, false, DeathParts.ASH)
	rem.take(r)
	risen += 1
	_servants.append({"a": a, "until": when + SERVANT_LIFE})
	if DominionParts.staged(self):
		var sp := Iso.ground_to_screen(r.pos)
		FxParts.debris(self, sp, 5, 5.0, Vector2(20, 60), BONE_CHIPS, Vector2(1.0, 2.0), true)


## SPAN: the district has its colour and pace back, and the horde sinks. The servants stay up out their own 20 s.
func _lift() -> void:
	over = true
	_let_all_go()
	_sink()


## A servant whose 20 s are up falls to ash; one cut down is gone already. The reign ends with the last of them.
func _expire() -> void:
	var still: Array[Dictionary] = []
	for s in _servants:
		# Untyped until checked: one cut down by the guard is freed by the Visitors.
		if not is_instance_valid(s.a) or not (s.a as Animal).is_alive():
			continue
		var a: Animal = s.a
		if t < float(s.until):
			still.append(s)
			continue
		if DominionParts.staged(self):
			FxParts.smoke(self, Iso.ground_to_screen(a.ground_pos), 6.0, 24.0, 0.3, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)
		visitors.take(a)
	_servants = still
	if over and _servants.is_empty():
		duration = minf(duration, maxf(SPAN + FADE, t) + 0.05)


## Over or cut short: every pace let go, the servants and the ghosts gone, the ledger as it was.
func _finish() -> void:
	_unhear()
	_let_all_go()
	_servants.clear()
	if visitors != null:
		visitors.clear()
	if horde != null:
		horde.clear()
	_put_ledger_back()
	super()


## Freed without _finish (a mission torn down mid-reign): the same, the pack only queued for freeing (its parents may be
## mid-teardown).
func _exit_tree() -> void:
	_unhear()
	_let_all_go()
	_servants.clear()
	if visitors != null:
		visitors.clear(true)
	if horde != null:
		horde.clear(true)
	_put_ledger_back()
	super()


func _unhear() -> void:
	if is_instance_valid(ctx.field) and ctx.field.enemy_killed.is_connected(_on_killed):
		ctx.field.enemy_killed.disconnect(_on_killed)


func _put_ledger_back() -> void:
	if _lit_ledger and is_instance_valid(ctx.crowd) and is_instance_valid(ctx.crowd.remains):
		ctx.crowd.remains.enabled = false
	_lit_ledger = false


## The grey veil: stacked iso discs multiplied in (the node's material) -- white changes nothing, GREY ashes it -- so the
## grey deepens toward the middle and fades out at the rim (Yesterday's Door's veil).
class Veil extends Node2D:
	var fx: PaleReignFx

	func _process(_delta: float) -> void:
		if not is_instance_valid(fx) or (fx.over and fx.shown() <= 0.0):
			visible = false  # past the fade: nothing left to draw, nothing to redraw
			set_process(false)
			return
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(fx):
			return
		var a := fx.shown()
		if a <= 0.0:
			return
		var major := RADIUS * FxParts.PX_PER_UNIT_MAJOR
		var step := Color.WHITE.lerp(GREY, a * 0.4)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		for k in 4:
			draw_circle(Vector2.ZERO, major * (1.0 - k * 0.18), step)
		draw_set_transform(Vector2.ZERO)
