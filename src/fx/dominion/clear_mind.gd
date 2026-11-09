class_name ClearMindFx
extends FxTimeline
## Clear Mind (Dominion, Tier III): everyone within RADIUS of the click is hypnotized for TRANCE_TIME -- any role, up to
## MAX_PEOPLE, and whoever walks in while it holds (every JOIN_EVERY). They sense nothing special (Person.entrance():
## no danger frightens them, nothing makes them look, no evacuation calls them, no fright is passed on) and go on with
## what they were doing: a merchant trades beside a corpse, the brigade lets the house burn, a soldier stands his post
## while the square empties, the bellkeeper does not go to the rope. Nothing of their day is taken from them (unlike
## Discord's confusion) and nothing is put in its place (unlike a compulsion): the trance only takes the seeing. One
## already frightened is calmed back into its day, and does not pick the fright up again when the trance ends: it never
## knew. Quiet, but for the book entry's "alarm". The cast locks the other slots until it takes.

const RADIUS := 5.0
const TRANCE_TIME := 30.0
const T_CAST := 0.9
const JOIN_EVERY := 0.5
const MAX_PEOPLE := 80
const CALM := Color("b8c8ff")
const CALM_LIFE := [Color("f0f4ff"), Color("b8c8ff"), Color("7a90e0"), Color(0.3, 0.35, 0.6, 0.5)]
## The trance's sign: a spiral.
const TRANCE: Array[int] = [0b11111, 0b00001, 0b11101, 0b10101, 0b11111]

## The entranced: Person -> true. How many have been taken in all.
var entranced := {}
var taken := 0

var _join_in := 0.0
var _pulse_in := 0.0
## This cast's circle and trance at its ability level (RADIUS and TRANCE_TIME at level 1).
var lv_radius := RADIUS
var lv_trance_time := TRANCE_TIME
## Sleepwalk (level 5): whether this cast has it; the people sent to a spot of the click's (person -> spot); how many clicks have been taken.
var walkers := {}
var walks := 0
var _sleepwalk := false
var _walkers_freed := false


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "clearmind", "RADIUS", RADIUS))
	lv_trance_time = float(PowerBook.stat(extra, "clearmind", "TRANCE_TIME", TRANCE_TIME))
	_sleepwalk = PowerBook.twist_at(extra, "clearmind")
	duration = T_CAST + lv_trance_time + 0.5
	busy = T_CAST
	at(T_CAST, _hypnotize)
	ctx.play(&"q_clearmind", origin)
	if not DominionParts.staged(self):
		return
	DominionParts.sky_sigil(self, origin, 100.0, 100.0, CALM, T_CAST, 1.6)
	var icon := DominionParts.icon(self, origin, TRANCE, Color("f0f4ff"), T_CAST + 2.5, 100.0)
	icon.px = 4
	# The circle drawn in, held soft on the ground for as long as the trance holds.
	DominionParts.ground_sigil(self, origin, lv_radius, CALM, T_CAST, lv_trance_time - 0.5)


## Whether the trance holds now.
func holding() -> bool:
	return t >= T_CAST and t < T_CAST + lv_trance_time


## Those entranced who can be sent now: alive, out in the open, and not held by another power's compulsion.
func _sendable() -> Array[Person]:
	var out: Array[Person] = []
	for p in entranced:
		if is_instance_valid(p) and p.is_alive() and not p.inside and (p.mind != Person.Mind.COMPELLED or (walkers.has(p) and p.anchor == walkers[p])):
			out.append(p)
	return out


## Sleepwalk: true at level 5 while the trance holds and someone entranced can be sent.
func can_follow_up() -> bool:
	return _sleepwalk and not finished and holding() and not _sendable().is_empty()


## Sleepwalk: everyone entranced now walks calmly to a spot of their own at the click (nearest first; no rng), and stands there until the
## trance ends. The trance itself (fearless_left) is untouched, so they still sense nothing. Any number of clicks; later joiners wait for the next.
func follow_up(at_pos: Vector2, _extra: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var list := _sendable()
	list.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at_pos) < b.ground_pos.distance_squared_to(at_pos))
	var place := CongregationFx.place_for(ctx.env, at_pos)
	var spots := CongregationFx.spots_for(list[0].grid, place, list.size())
	var left := maxf(T_CAST + lv_trance_time - t, 0.5)
	for i in list.size():
		var p := list[i]
		var spot: Vector2 = spots[i] if i < spots.size() else place.at
		if p.compel(spot, left, Person.WILL_ABSOLUTE, CALM, false, &"", TRANCE):
			walkers[p] = spot
	walks += 1
	return true


## Sleepwalk's preview: the single spot the click names.
func follow_up_area() -> Dictionary:
	return {"shape": "circle", "r": 1.0}


## The trance ends (or is cut short): whoever it still walks or holds is let go.
func _release_walkers() -> void:
	for p in walkers:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.COMPELLED and p.anchor == walkers[p]:
			p.release_compulsion()
	walkers.clear()


func end_now() -> void:
	_release_walkers()
	super.end_now()


func _hypnotize() -> void:
	_join()
	ctx.play(&"grav_shimmer", origin, -8.0)
	if not DominionParts.staged(self):
		return
	var spiral := Spiral.new()
	spiral.fx = self
	spiral.position = origin
	spiral.z_index = 4
	track(spiral, ctx.ground)
	DominionParts.pulse(self, origin, lv_radius, CALM, 0.6, 1.5)
	var wave := FxParts.shockwave(self, origin, lv_radius, VoiceOfGodFx.SOLAR)
	wave.set_param("thickness", 0.05)
	wave.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	wave.tween_param("fade", 0.9, 0.0, 0.3, 0.45)
	wave.life = 0.8


## Whoever stands inside and is not yet entranced is taken, for what is left of the trance.
func _join() -> void:
	var left := maxf(T_CAST + lv_trance_time - t, 0.5)
	for p in DominionParts.near(ctx.field, origin, lv_radius, MAX_PEOPLE):
		if entranced.has(p):
			continue
		if p.entrance(left):
			entranced[p] = true
			taken += 1
			p.set_badge(TRANCE, CALM, left)
			if DominionParts.staged(self):
				DominionParts.motes(self, p.ground_pos, CALM_LIFE, 6)


func _fx_process(delta: float) -> void:
	if not holding():
		if t >= T_CAST + lv_trance_time and not walkers.is_empty():
			_release_walkers()
		return
	_join_in -= delta
	if _join_in <= 0.0:
		_join_in = JOIN_EVERY
		_join()
	if not DominionParts.staged(self):
		return
	_pulse_in -= delta
	if _pulse_in <= 0.0:
		_pulse_in = 4.0
		DominionParts.pulse(self, origin, lv_radius * 0.8, CALM, 0.3, 2.0)


## The hypnotist's wheel on the ground: three thin arcs turning slowly, one way and the other, while the trance holds.
class Spiral extends Node2D:
	var fx: ClearMindFx

	func _process(_delta: float) -> void:
		if fx.t > T_CAST + fx.lv_trance_time + 0.4:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(minf((fx.t - T_CAST) / 0.6, (T_CAST + fx.lv_trance_time + 0.3 - fx.t) / 0.8), 0.0, 1.0)
		if a <= 0.0:
			return
		for i in 3:
			var r := fx.lv_radius * (0.35 + 0.3 * float(i))
			var turn := fx.t * (0.3 if i % 2 == 0 else -0.22) + float(i) * 1.3
			for k in 3:
				var a0 := turn + TAU * float(k) / 3.0
				draw_arc(Vector2.ZERO, r, a0, a0 + 1.3, 12, Color(CALM, (0.45 - 0.1 * float(i)) * a), 0.07)
