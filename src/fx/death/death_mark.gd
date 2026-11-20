class_name DeathMarkFx
extends FxTimeline
## Death Mark (Death, Tier I): one person is marked. The one nearest the click (PICK_R) -- any role -- grows frail and
## slow for MARK_TIME (Person.statuses: "frail", any blow kills it; "slow", SLOW of its pace), wearing the mark, and then
## dies where it stands (damage kind deathmark), unless it is inside somewhere by then. The body lies where it fell for
## DummyEnemy.BODY_HOLD, and the town finds it: the death is an ordinary one -- it counts, the alarm hears of it, soldiers
## come to look -- and every LOOK_EVERY up to GAWKERS people going about their day within LOOK_R walk over and stand
## staring (Person.lure()) for LOOK_SECONDS. Quiet when cast: a frail man walking is nothing to see. The cast locks the
## other slots for 0.8 s.
## Level 5, The Wake: the first of the gawkers to stand within PICK_R of the body sees it get up as a Raise the Dead zombie (at
## Raise's level-1 numbers; the body is used up) in the middle of the crowd it drew. Its kills raise at most CHAIN - 1 more. Quiet
## as the rest of the power: no fright, alarm or danger of the rising's own.

const PICK_R := 1.0
## How near the body's own remain must be for the wake to find it.
const WAKE_R := 0.2
## The meta key on the Remains that counts the Wakes holding the ledger on.
const HOLDERS_META := &"wake_ledger_holders"
const MARK_TIME := 10.0
const SLOW := 0.6
const LOOK_R := 4.0
const GAWKERS := 8
const LOOK_EVERY := 6.0
const LOOK_SECONDS := 5.0
## Where the gawkers stand, round the body.
const RING := Vector2(0.6, 1.2)
const SKULL: Array[int] = [0b01110, 0b10101, 0b11111, 0b01110, 0b01010]
const PALE := Color("d8d0e8")
const SHADE := [Color("d8d0e8"), Color("8a7aa8"), Color("4a3a60"), Color(0.12, 0.08, 0.18, 0.6)]

## The marked, where it fell (Vector2.INF while it lives), and how many have come to look.
var marked: Person
var body_at := Vector2.INF
var gawked := 0

var _look_in := 0.0
## The Wake (level 5 only): the people the mark lured, the zombie's pack, how many more of its kills may rise, whether the body has
## been dealt with, and when the luring ends (the mark's own span; the zombie outlasts it).
var visitors: Visitors
var raised := 0
var _twist := false
var _looked: Array[Person] = []
var _woke := false
var _left := 0
var _lure_end := 0.0
## True when this cast turned the remains ledger on (it puts it back off at its end).
var _lit_ledger := false
## The clock the risen's bite and cut may be heard again at (sound only; RaiseTheDeadFx's quiet gaps).
var _bite_heard := 0.0
var _cut_heard := 0.0
## This cast's numbers at its ability level (the consts at level 1): the time to death, who comes to look, and from how far.
var lv_mark_time := MARK_TIME
var lv_gawkers := GAWKERS
var lv_look_r := LOOK_R


## Whom a click at `at` would mark: the nearest within PICK_R, or null.
static func target_at(field: EnemyField, at: Vector2) -> Person:
	var near := DominionParts.near(field, at, PICK_R, 1)
	return near[0] if not near.is_empty() else null


func _build() -> void:
	lv_mark_time = float(PowerBook.stat(extra, "deathmark", "MARK_TIME", MARK_TIME))
	lv_gawkers = int(PowerBook.stat(extra, "deathmark", "GAWKERS", GAWKERS))
	lv_look_r = float(PowerBook.stat(extra, "deathmark", "LOOK_R", LOOK_R))
	duration = lv_mark_time + DummyEnemy.BODY_HOLD
	busy = 0.8
	_lure_end = duration
	marked = target_at(ctx.field, origin)
	if marked == null:
		duration = 1.0
		return
	_twist = PowerBook.twist_at(extra, "deathmark")
	if _twist and ctx.crowd != null and ctx.crowd.remains != null:
		# The body must be written down to rise. A ledger this power lights is shared by every Wake running (a count on the Remains
		# itself, so separate worlds never leak): it goes back off only when the last of them ends. One already on for
		# another reason is left alone.
		var rem: Remains = ctx.crowd.remains
		var holders := int(rem.get_meta(HOLDERS_META, 0))
		if not rem.enabled:
			rem.enabled = true
			rem.set_meta(HOLDERS_META, 1)
			_lit_ledger = true
		elif holders > 0:
			rem.set_meta(HOLDERS_META, holders + 1)
			_lit_ledger = true
	marked.statuses[&"frail"] = 1.0
	marked.statuses[&"slow"] = SLOW
	marked.walk_speed = marked._mind_speed()
	marked.set_badge(SKULL, PALE, lv_mark_time)
	at(lv_mark_time, _die)
	ctx.play(&"q_deathmark", origin)
	if DominionParts.staged(self):
		# The mark settles on them: pale motes drawn down, and the skull shown large for a moment.
		var down := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(marked.ground_pos), PixelParticles.Shape.PUFF, SHADE)
		down.drag = 1.2
		down.gravity = 50.0
		down.burst(12, {"radius": 7.0, "speed": Vector2(4, 12), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(18, 30),
			"alt_speed": Vector2(-26, -8), "life": Vector2(0.5, 0.8), "size": Vector2(2, 3), "size_end_mul": 0.4})
		DominionParts.icon(self, marked, SKULL, PALE, 1.6, 40.0)


## The mark comes due.
func _die() -> void:
	if marked == null or not is_instance_valid(marked):
		duration = minf(duration, t + 0.5)
		return
	marked.statuses.erase(&"frail")
	marked.statuses.erase(&"slow")
	if not marked.is_alive() or marked.inside:
		# Already dead of something else, or behind a door: the mark has nothing to do, and no body to show.
		duration = minf(duration, t + 0.5)
		return
	body_at = marked.ground_pos
	ctx.field.kill(marked, &"deathmark", body_at)
	ctx.play(&"q_deathmark_hit", body_at)
	_look_in = 0.5
	if DominionParts.staged(self):
		DominionParts.motes(self, body_at, SHADE, 10)
		DominionParts.pulse(self, body_at, 1.2, Color(0.6, 0.5, 0.8), 0.4, 1.5)


func _fx_process(delta: float) -> void:
	if visitors != null:
		visitors.step(delta)
	if body_at == Vector2.INF:
		return
	if _twist and not _woke:
		_watch_wake()
	_look_in -= delta
	if _look_in > 0.0:
		return
	_look_in = LOOK_EVERY
	if _twist and t >= _lure_end:
		return  # the zombie outlasts the mark; the luring does not
	var came := 0
	for p in DominionParts.near(ctx.field, body_at, lv_look_r):
		if came >= lv_gawkers:
			break
		var a := ctx.rng.randf() * TAU
		if p.lure(body_at + Vector2(cos(a), sin(a)) * ctx.rng.randf_range(RING.x, RING.y), LOOK_SECONDS, body_at):
			came += 1
			if _twist:
				_looked.append(p)
	gawked += came


## The Wake: the first gawker (the nearest, then the lower instance id) standing within PICK_R of the body raises it.
func _watch_wake() -> void:
	var best: Person = null
	var best_d := 0.0
	for p in _looked:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		var d := p.ground_pos.distance_to(body_at)
		if d > PICK_R:
			continue
		if best == null or d < best_d or (d == best_d and p.get_instance_id() < best.get_instance_id()):
			best = p
			best_d = d
	if best == null:
		return
	_woke = true
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	if rem == null:
		return
	var r := rem.pick(body_at, false, false, WAKE_R)
	if r == null or r.kind != &"deathmark":
		return  # taken by another power first (or the ledger lost it): nothing rises
	rem.take(r)
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, ctx.crowd._grid, parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	DeathParts.zombie(visitors, r, r.sick)
	raised = 1
	_left = RaiseTheDeadFx.CHAIN - 1
	var end := t + RaiseTheDeadFx.ZOMBIE_LIFE + RaiseTheDeadFx.FADE
	duration = maxf(duration, end)
	at(end - RaiseTheDeadFx.FADE, _end_life)
	ctx.play(&"raise_rise", body_at, -3.0)
	if DominionParts.staged(self):
		var sp := Iso.ground_to_screen(body_at)
		FxParts.debris(self, sp, 6, 5.0, Vector2(20, 70), RaiseTheDeadFx.BONE_CHIPS, Vector2(1.0, 2.0), true)
		FxParts.smoke(self, sp, 6.0, 30.0, 0.25, Vector2(8, 20), Vector2(2, 4), Vector2(0.5, 1.0), Color(DeathParts.GRAVE_GREEN, 0.25), RaiseTheDeadFx.DUST)


## A zombie's bite that kills raises the dead one while the chain lasts (no outcry of the cast's own: Death Mark is quiet).
func _on_bite(_a: Animal, victim: Person, _first: bool) -> void:
	if is_instance_valid(victim) and t >= _bite_heard:
		_bite_heard = t + RaiseTheDeadFx.BITE_QUIET
		ctx.play(&"undead_bite", victim.ground_pos, 0.0)
	if not is_instance_valid(victim) or victim.is_alive() or ctx.crowd == null:
		return
	var before := _left
	_left = DeathParts.on_kill_rise(visitors, ctx.crowd.remains, victim, _left)
	if _left != before:
		raised += 1
		ctx.play(&"raise_rise", victim.ground_pos, -6.0)


## Heard only: a soldier cuts one of the risen down (the Visitors free it).
func _on_cut_down(_a: Animal, at_ground: Vector2) -> void:
	if t >= _cut_heard:
		_cut_heard = t + RaiseTheDeadFx.CUT_QUIET
		ctx.play(&"undead_cut", at_ground, 0.0)


## The zombie's time is up: it falls to ash.
func _end_life() -> void:
	if visitors != null:
		var left := visitors.living()
		if not left.is_empty():
			var mid := Vector2.ZERO
			for a in left:
				mid += a.ground_pos
			ctx.play(&"undead_ash", mid / float(left.size()), 0.0)
		visitors.clear()


func _finish() -> void:
	if visitors != null:
		visitors.clear()
	_put_ledger_back()
	super()


## The ledger goes back as this cast found it.
func _put_ledger_back() -> void:
	if _lit_ledger and ctx != null and is_instance_valid(ctx.crowd) and is_instance_valid(ctx.crowd.remains):
		var rem: Remains = ctx.crowd.remains
		var holders := int(rem.get_meta(HOLDERS_META, 1)) - 1
		rem.set_meta(HOLDERS_META, maxi(holders, 0))
		if holders <= 0 and not rem.always:
			rem.enabled = false
	_lit_ledger = false


## Freed without _finish (a restart): the risen are gone, the pack only queued for freeing.
func _exit_tree() -> void:
	if visitors != null:
		visitors.clear(true)
	_put_ledger_back()
	super()
