class_name BoundFx
extends FxTimeline
## Bound in Law (Decree, Tier II; spec 5.4): two people share one fate. Two clicks: the living person out of doors nearest
## each click within PICK_R (a tie to the earlier instance, never a roll) -- the first click's is `a`, the second's `b`, who
## must stand within REACH of him (Rules refuses the cast before it is made, and no cooldown starts: refusal()). For SPAN a
## thin brass chain of light joins them, and both are BOUND by law (LawMark, under this effect's own owner id: the badge and
## the cleanup; it changes no sight).
## There is no event for most of what befalls a person, so the bond polls both every frame and lays the ONSET of each state
## on one onto the other, once:
##   struck      the same amount of health (any blow, bite or wound: the drop in health since the last frame)
##   knocked down, stunned (the same seconds), asleep (the same seconds)
##   seized      while one is held by a seizure (a mission's seizer, MissionDirector.is_seized(); a rite's chain), the other is
##               held where he stands (a hold on his pace, lifted when the first is let go)
##   dead        the other dies too (kind bound); a blow the other cannot take kills him by the bond, kind bound
## The onsets of both are read before either is laid on the other, and both are read again after: a mirrored state is
## never mistaken for a new one, so nothing passes back (a.hurt(30) leaves both down 30, once).
## At SPAN the law is lifted and harm no longer passes; cut short or out of the tree the same. A partner freed mid-link
## (gone from the town) drops the link without a word. Quiet: its own q_bound cue (a chain's ring), no alarm.

## How near a click a person must stand to be taken.
const PICK_R := 0.8
## How far apart the two may stand.
const REACH := 10.0
const SPAN := 20.0
## Death by the bond.
const KIND := &"bound"
## The chain is drawn in from the first to the second (look; the cast's busy lock).
const FORGE := 0.45
## The chain fades out once the bond is over (look only).
const FADE := 0.6
const BRASS := Color("d9a441")
const BRASS_LIGHT := Color("ffd77a")
## Changes smaller than this are no onset (float noise).
const EPS := 0.0001

## The two bound (Persons; either may since have been freed, so untyped); null when the cast found no pair.
var a: Variant = null
var b: Variant = null
## The bond holds.
var linked := false
## How many onsets were laid across (look: the chain flares; and the tests).
var mirrored := 0
## The effect clock when the bond ended (-1 while it holds).
var ended_at := -1.0
## The chain flares when a fate passes along it (1 at the moment, decaying; look only).
var flare := 0.0

var _sa := BondEnd.new()
var _sb := BondEnd.new()


## One end of the bond: what was seen of him at the end of the last frame, what began on him since, and whether the bond
## holds him for the other's seizure.
class BondEnd:
	var p: Variant = null
	var hp := 0.0
	var down := false
	var wait := 0.0
	var asleep := false
	## Onsets this frame.
	var hurt := 0.0
	var fell := false
	var stunned := 0.0
	var slept := 0.0
	## Seized now (the state, not the onset: the other is held while it holds).
	var seized := false
	## The bond holds his pace (the other is seized).
	var holding := false


## The living person out of doors nearest `at` within `r`, not `skip`: nearest first, a tie to the earlier instance.
static func nearest(field: EnemyField, at: Vector2, r: float, skip: Variant = null) -> Person:
	if field == null or at == Vector2.INF:
		return null
	var best: Person = null
	var best_d := INF
	for e in field.in_radius(at, r):
		var p := e as Person
		if p == null or p == skip or not p.is_alive() or p.inside:
			continue
		var d := p.ground_pos.distance_squared_to(at)
		if d < best_d or (d == best_d and best != null and p.get_instance_id() < best.get_instance_id()):
			best = p
			best_d = d
	return best


## Whom two clicks would bind: [a, b], or [] when either click finds no one (or the same man). With no second click
## (`to` INF: a scripted route, a clip) the one nearest `a` within REACH.
static func pair_at(field: EnemyField, first: Vector2, to: Vector2) -> Array:
	var one := nearest(field, first, PICK_R)
	if one == null:
		return []
	var two := nearest(field, one.ground_pos, REACH, one) if to == Vector2.INF else nearest(field, to, PICK_R, one)
	return [] if two == null else [one, two]


## Why two clicks cannot bind (Rules.cast asks before the cast is made): "unbound" when either finds no one, "far" when
## the two stand farther than REACH apart; "" when they can.
static func refusal(field: EnemyField, first: Vector2, to: Vector2) -> String:
	var pair := pair_at(field, first, to)
	if pair.is_empty():
		return "unbound"
	if (pair[0] as Person).ground_pos.distance_to((pair[1] as Person).ground_pos) > REACH:
		return "far"
	return ""


func _build() -> void:
	busy = FORGE
	var to: Vector2 = extra.get("to", Vector2.INF)
	if refusal(ctx.field, origin, to) != "":
		duration = 0.1  # cast round Rules on no pair: nothing is bound
		return
	var pair := pair_at(ctx.field, origin, to)
	a = pair[0]
	b = pair[1]
	_sa.p = a
	_sb.p = b
	linked = true
	duration = SPAN + FADE
	for p: Variant in [a, b]:
		LawMark.set_law(p, LawMark.BOUND, SPAN, get_instance_id())
	_see(_sa)
	_see(_sb)
	at(SPAN, _unlink)
	ctx.play(&"q_bound", (a as Person).ground_pos.lerp((b as Person).ground_pos, 0.5))
	if DominionParts.staged(self):
		_show()


func _fx_process(delta: float) -> void:
	flare = maxf(flare - delta * 2.5, 0.0)
	if not linked:
		return
	if not is_instance_valid(a) or not is_instance_valid(b):
		_unlink()  # gone from the town: the bond has nothing to hold
		return
	_read(_sa)
	_read(_sb)
	_lay(_sa, _sb)
	_lay(_sb, _sa)
	var pa := a as Person
	var pb := b as Person
	# One fate: one dead, the other dies too.
	if not pa.is_alive() and pb.is_alive():
		_kill(pb, pa)
	elif not pb.is_alive() and pa.is_alive():
		_kill(pa, pb)
	if not pa.is_alive() or not pb.is_alive():
		_unlink()
		return
	_see(_sa)
	_see(_sb)


## What is seen of `s` now: the baseline the next frame's onsets are read against.
func _see(s: BondEnd) -> void:
	var p := s.p as Person
	s.hp = p.health
	s.down = p.is_down()
	s.wait = p.wait
	s.asleep = p.is_asleep()


## What began on `s` since the last frame.
func _read(s: BondEnd) -> void:
	var p := s.p as Person
	var alive := p.is_alive()
	s.hurt = maxf(s.hp - p.health, 0.0) if alive else 0.0
	s.fell = alive and p.is_down() and not s.down
	s.stunned = p.wait if alive and p.wait > s.wait + EPS else 0.0
	s.slept = p.sleep_left() if alive and p.is_asleep() and not s.asleep else 0.0
	s.seized = alive and _seized(p)


## Lay what began on `from` onto `to`, and hold `to` where he stands while `from` is seized.
func _lay(from: BondEnd, to: BondEnd) -> void:
	var q := to.p as Person
	if not q.is_alive():
		return
	var before := mirrored
	if from.hurt > EPS:
		mirrored += 1
		if q.statuses.has(&"frail") or q.health <= from.hurt + EPS:
			_kill(q, from.p as Person)
			return
		q.hurt(from.hurt, null)
	if from.fell:
		mirrored += 1
		q.knock_down()
	if from.stunned > 0.0:
		mirrored += 1
		q.stun(from.stunned)
	if from.slept > 0.0:
		mirrored += 1
		q.sleep(from.slept)
	if from.seized != to.holding:
		to.holding = from.seized
		if to.holding:
			mirrored += 1
			q.hold_pace(get_instance_id(), 0.0)
		else:
			q.free_pace(get_instance_id())
	if mirrored > before:
		flare = 1.0


## Held by a seizure: a rite's chain, or a mission's seizer.
func _seized(p: Person) -> bool:
	if p.chained:
		return true
	return ctx.rules != null and ctx.rules.director != null and ctx.rules.director.is_seized(p)


## `q` dies by the bond (`by` is the other end).
func _kill(q: Person, by: Person) -> void:
	if ctx.field != null:
		ctx.field.kill(q, KIND, by.ground_pos)
	elif q.is_alive():
		q.die(KIND, by.ground_pos)


## The bond is over: the law is lifted from both and any hold it laid is let go (only its own; a freed one is skipped).
func _unlink() -> void:
	if not linked:
		return
	linked = false
	ended_at = t
	for s: BondEnd in [_sa, _sb]:
		if not is_instance_valid(s.p):
			continue
		LawMark.lift(s.p, get_instance_id())
		if s.holding:
			(s.p as Person).free_pace(get_instance_id())
			s.holding = false


## Cut short (an act of the night ends): the bond with it.
func end_now() -> void:
	if not finished:
		_unlink()
	super()


func _exit_tree() -> void:
	_unlink()
	super()


## How much of the chain shows: drawn in over FORGE, whole while the bond holds, gone over FADE once it ends.
func shown() -> float:
	if not linked:
		return clampf(1.0 - (t - ended_at) / FADE, 0.0, 1.0) if ended_at >= 0.0 else 0.0
	return 1.0


## How far along from a to b the chain is drawn yet (0..1).
func forged() -> float:
	return clampf(t / FORGE, 0.0, 1.0)


## The binding: a flick of gilt and ink off each, a faint brass ring at each one's feet, and the chain.
func _show() -> void:
	for p: Variant in [a, b]:
		DecreeParts.scatter(self, (p as Person).ground_pos, 6, Chain.WAIST)
	var chain := Chain.new()
	chain.fx = self
	chain.z_index = 7
	track(chain, ctx.overhead)


## A thin brass chain of light between the two, at their waists, sagging a little: a soft brass glow under links drawn
## alternately face-on and edge-on, a shackle ring at each one's feet. It flares when a fate passes along it. Nothing is
## made per frame: it only draws.
class Chain extends Node2D:
	## How high over a person's feet the chain is fastened.
	const WAIST := 10.0
	## Screen pixels per link.
	const LINK := 5.0
	const SAG := 0.12
	var fx: BoundFx

	func _process(_delta: float) -> void:
		if fx == null or not is_instance_valid(fx) or fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var alpha := fx.shown()
		if alpha <= 0.0 or not is_instance_valid(fx.a) or not is_instance_valid(fx.b):
			return
		var pa := fx.a as Person
		var pb := fx.b as Person
		var from := Iso.ground_to_screen(pa.ground_pos) + Vector2(0.0, -WAIST)
		var to := Iso.ground_to_screen(pb.ground_pos) + Vector2(0.0, -WAIST)
		var span := from.distance_to(to)
		if span < 1.0:
			return
		var reach := fx.forged()
		var lit := 0.8 + 0.2 * fx.flare
		var pulse := 0.85 + 0.15 * sin(fx.t * 5.0)
		var n := clampi(int(span / LINK), 2, 200)
		var sag := minf(span * SAG, 24.0)
		var dir := (to - from) / span
		var side := Vector2(-dir.y, dir.x)
		var prev := from
		for i in range(1, n + 1):
			var k := float(i) / float(n)
			if k > reach + 0.0001:
				break
			var at := from.lerp(to, k) + Vector2(0.0, sag * 4.0 * k * (1.0 - k))
			# An ink edge under it so it reads on any ground, the brass glow, then the link: face-on (an open loop, ink
			# showing through) and edge-on (a bright bar) by turns.
			draw_line(prev, at, Color(BRASS, 0.4 * alpha * lit), 8.0)
			draw_line(prev, at, Color(DecreeParts.INK, 0.55 * alpha), 4.0)
			if i % 2 == 0:
				var mid := (prev + at) * 0.5
				draw_line(prev + side * 1.2, at + side * 1.2, Color(BRASS_LIGHT, alpha * pulse), 1.0)
				draw_line(prev - side * 1.2, at - side * 1.2, Color(BRASS_LIGHT, alpha * pulse), 1.0)
				draw_line(mid - side * 1.2, mid + side * 1.2, Color(DecreeParts.INK, alpha), 1.0)
			else:
				draw_line(prev, at, Color(BRASS_LIGHT, alpha), 2.0)
			prev = at
		_shackle(pa, alpha, lit)
		_shackle(pb, alpha, lit)
		if fx.flare > 0.0:
			# A fate passing: a bright bead runs the chain's length.
			var bead := from.lerp(to, 1.0 - fx.flare) + Vector2(0.0, sag * 4.0 * (1.0 - fx.flare) * fx.flare)
			draw_circle(bead, 3.5, Color(BRASS_LIGHT, fx.flare * alpha))

	## A shackle ring at `p`'s feet, flat on the ground.
	func _shackle(p: Person, alpha: float, lit: float) -> void:
		draw_set_transform(Iso.ground_to_screen(p.ground_pos), 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 18, Color(DecreeParts.INK, 0.75 * alpha), 4.0)
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 18, Color(BRASS, alpha * lit), 2.0)
		draw_set_transform(Vector2.ZERO)
