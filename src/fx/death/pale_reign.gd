class_name PaleReignFx
extends FxTimeline
## Pale Reign (Death, Tier IV; spec 5.6): a click, and the colour drains out of a district of RADIUS for SPAN -- it turns
## grey and silent.
## - Everyone inside out in the open crawls at CRAWL of their pace (hold_pace under this effect's id), let go as they leave
##   and when the span ends.
## - Every second the fires inside gutter (FireManager.douse, Door to the Deep's way), and the town is hushed for the span
##   (Crowd.hush: no shout, no alarm, no bell -- the bell is never silenced, so it rings on after if the night still calls).
## - Every EVERY the weakest one still inside out in the open dies without a sound, killed as &"pale" (a whole body).
##   Weakest: the sick, then the hurt (health under its full), then the frail (Death Mark's), then the nearest the middle;
##   a tie to the lower instance id. No luck.
## - Each of its dead rises at once as the god's pale servant: a zombie in their own look with ash-grey eyes
##   (DeathParts.zombie, eyes ASH), in this effect's own Visitors pack, for SERVANT_LIFE from its rising; the body is taken
##   off the ledger (Remains.take hides the corpse). The ledger is on for a Pale night (Remains.wants); were it off (a test,
##   the sandbox), the reign keeps it on for itself and puts it back as it was at its end.
## Loud (PowerBook.REACH): the danger counts from the first death (IMPACT = EVERY). Over, or cut short, or freed without its
## end (_exit_tree), every pace is let go and the servants are gone.

## The district, how long it reigns, the pace it leaves, a death every EVERY, a servant's 20 s.
const RADIUS := 10.0
const SPAN := 12.0
const CRAWL := 0.3
const EVERY := 2.0
const SERVANT_LIFE := 20.0
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
var taken: Array[Person] = []
var first_kill_at := -1.0
var doused := 0
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
var _drain: QuadFx


func _build() -> void:
	duration = SPAN + SERVANT_LIFE + FADE + 1.0  # a ceiling: _lift() and _expire() set the real end
	busy = T_DRAIN
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	if ctx.crowd != null:
		ctx.crowd.hush(SPAN)
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
	if is_instance_valid(_drain):
		_drain.set_param("amount", shown())
	if not over:
		_crawl()
		# The fires and the deaths run on the reign's own clock, a tick at a time, so a long frame misses none.
		while _next_douse <= SPAN and t >= _next_douse:
			_douse()
			_next_douse += DOUSE_EVERY
		while _next_kill <= SPAN + 0.0001 and t >= _next_kill:
			_reap(_next_kill)
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
	var p: Person = _held.get(id)
	if is_instance_valid(p):
		p.free_pace(get_instance_id())
	_held.erase(id)


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
		if p == null or p.inside:
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
	if p.health < (Person.HEALTH_SOLDIER if p.soldier else Person.HEALTH_CITIZEN):
		return 1
	if p.statuses.has(&"frail"):
		return 2
	return 3


## One death (the tick at `when`): the weakest dies without a sound, and rises at once as a servant.
func _reap(when: float) -> void:
	var p := weakest()
	if p == null:
		return
	_let_go(p.get_instance_id())
	if not ctx.field.kill(p, &"pale", origin):
		return
	taken.append(p)
	if first_kill_at < 0.0:
		first_kill_at = when
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(p.ground_pos), 5.0, 24.0, 0.3, Vector2(6, 16), Vector2(2, 4), Vector2(0.6, 1.2), Color(0, 0, 0, 0), DUST)
	_rise(p, when)


## `p`'s body gets up where it fell: a zombie in their own look, ash-grey eyes, for SERVANT_LIFE from `when`.
func _rise(p: Person, when: float) -> void:
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	var r := DeathParts.fresh_remain(rem, p)
	if r == null:
		return
	var a := DeathParts.zombie(visitors, r, false, DeathParts.ASH)
	rem.take(r)
	_servants.append({"a": a, "until": when + SERVANT_LIFE})
	if DominionParts.staged(self):
		var sp := Iso.ground_to_screen(r.pos)
		FxParts.debris(self, sp, 5, 5.0, Vector2(20, 60), BONE_CHIPS, Vector2(1.0, 2.0), true)


## SPAN: the district has its colour and pace back. The servants stay up out their own 20 s.
func _lift() -> void:
	over = true
	_let_all_go()


## A servant whose 20 s are up falls to ash; one cut down is gone already. The reign ends with the last of them.
func _expire() -> void:
	var still: Array[Dictionary] = []
	for s in _servants:
		var a: Animal = s.a
		if not is_instance_valid(a) or not a.is_alive():
			continue
		if t < float(s.until):
			still.append(s)
			continue
		if DominionParts.staged(self):
			FxParts.smoke(self, Iso.ground_to_screen(a.ground_pos), 6.0, 24.0, 0.3, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)
		visitors.take(a)
	_servants = still
	if over and _servants.is_empty():
		duration = minf(duration, maxf(SPAN + FADE, t) + 0.05)


## Over or cut short: every pace let go, the servants gone, the ledger as it was.
func _finish() -> void:
	_let_all_go()
	_servants.clear()
	if visitors != null:
		visitors.clear()
	_put_ledger_back()
	super()


## Freed without _finish (a mission torn down mid-reign): the same, the pack only queued for freeing (its parents may be
## mid-teardown).
func _exit_tree() -> void:
	_let_all_go()
	_servants.clear()
	if visitors != null:
		visitors.clear(true)
	_put_ledger_back()
	super()


func _put_ledger_back() -> void:
	if _lit_ledger and is_instance_valid(ctx.crowd) and is_instance_valid(ctx.crowd.remains):
		ctx.crowd.remains.enabled = false
	_lit_ledger = false


## The grey veil: stacked iso discs multiplied in (the node's material) -- white changes nothing, GREY ashes it -- so the
## grey deepens toward the middle and fades out at the rim (Yesterday's Door's veil).
class Veil extends Node2D:
	var fx: PaleReignFx

	func _process(_delta: float) -> void:
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
