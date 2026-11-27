class_name SlumberFx
extends FxTimeline
## Slumber (Veil, Tier 2): a hush that settles on the click. T_FALL after the cast everyone out in the open within the circle
## (VeilRules: 1.5 light / 3.5 dark) -- citizens, watchmen, soldiers -- sleeps where they stand for SLEEP_TIME (Person.sleep()). In the
## light a loud blow or a hurt wakes a sleeper, as with Curfew; in the dark it is a deep sleep that noise does not wake, only a hurt.
## Quiet: no danger, no fright, no alarm. Its dusk is laid at the cast, under the settling hush (VeilParts.land(); VB0). The sleep is the sleeper's own timer,
## so the effect holds nothing to undo: ending it early wakes nobody, and a second cast on a sleeper only runs the sleep to the later end.

const SLEEP_TIME := 20.0
const T_FALL := 0.6
const LID := [Color("b98cff"), Color("5a2aa8"), Color("2a1050"), Color(0.04, 0.02, 0.09, 0.5)]

## The cast's look (Veil review): how long the mist wave lies at the edge after the landing and fades; the eye's life and height
## over the click; how long the dust takes to sink.
const WAVE_HOLD := 0.35
const WAVE_FADE := 0.75
const EYE_LIFE := 1.6
const EYE_UP := -30.0
const DUST_LIFE := 1.1
## Heavy Air polls the circle this often (seconds).
const TICK := 0.25

## How many fell asleep.
var asleep := 0
## The look's pieces while they play (tests): the mist wave, the eye, the dust.
var waves: Array[Node2D] = []
var glyph: Node2D
var dust: Node2D
var _dark := false
var _r := 0.0
## Heavy Air (level 5, Veil ability levels B1): the cast keeps its circle to T_FALL + the sleep; whoever walks in after the fall sleeps
## the rest of it. The twist's gate, the polling accumulator, the people already in the circle at the fall (noted: VL15), the ones this
## cast caught (instance ids), how many it caught and the ring that stays drawn (staged only).
var _twist := false
var _tick := 0.0
var _noted := {}
var _caught := {}
## The spared walkers this cast has eyed (instance ids: once each): eyed, never slept (VL68).
var _eyed_spared := {}
var caught := 0
var heavy_ring: Node2D
## This cast's sleep, at its level (SLEEP_TIME at level 1).
var lv_sleep_time := SLEEP_TIME


func _build() -> void:
	lv_sleep_time = PowerBook.stat(extra, "slumber", "SLEEP_TIME", SLEEP_TIME)
	_dark = VeilParts.dark(self)
	_r = VeilParts.size(self, "slumber", "RADIUS")
	_twist = PowerBook.twist_at(extra, "slumber")
	duration = T_FALL + 1.2
	busy = T_FALL
	if _twist:
		duration = T_FALL + lv_sleep_time
	at(T_FALL, _fall)
	VeilParts.land(self, origin, _r)
	ctx.play(&"v_slumber", origin)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, _r, VeilParts.VEIL, 2, 30.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_FALL, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	mark.life = T_FALL + 0.1
	# Dusk settles from above, slowly.
	var down := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -34), PixelParticles.Shape.PUFF, LID)
	down.drag = 1.4
	down.gravity = 18.0
	down.burst(14, {"radius": _r * 12.0, "speed": Vector2(2, 8), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 6),
		"alt_speed": Vector2(-8, 0), "life": Vector2(0.6, 0.9), "size": Vector2(2, 3), "size_end_mul": 0.4})
	_cast_look()
	if _twist:
		var ring := HeavyRing.new()
		ring.r = _r
		ring.dark = _dark
		ring.fx_id = get_instance_id()
		ring.position = origin
		ring.z_index = 1
		heavy_ring = track(ring, ctx.ground) as Node2D


## The cast's look (Veil review, spec 5): a low wave of violet mist rolls out from the click to the edge of the reach (the true
## reach, light or dark), and an eye over the middle that blinks shut at the landing. The dust onto each sleeper is _fall()'s.
func _cast_look() -> void:
	var wave := VeilCastLooks.Wave.new()
	wave.r = _r
	wave.rim = Color(VeilParts.VEIL, 0.6)
	wave.fill = Color(VeilParts.DUSK, 0.18)
	wave.edge = Color(VeilParts.SILVER, 0.35)
	wave.grow = T_FALL
	wave.hold = WAVE_HOLD
	wave.fade = WAVE_FADE
	wave.position = origin
	wave.z_index = 2
	waves.append(track(wave, ctx.ground) as Node2D)
	var eye := VeilCastLooks.EyeGlyph.new()
	eye.shut_at = T_FALL
	eye.life = EYE_LIFE
	eye.position = Iso.ground_to_screen(origin) + Vector2(0, EYE_UP)
	glyph = track(eye, ctx.overhead) as Node2D


## The living out in the open within `r` of `at`, nearest first and then by instance id (no luck): who Slumber puts to sleep.
static func sleepers_at(field: EnemyField, at: Vector2, r: float) -> Array[Person]:
	var out := DominionParts.near(field, at, r)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if is_equal_approx(da, db):
			return a.get_instance_id() < b.get_instance_id()
		return da < db)
	return out


func _fall() -> void:
	var staged := DominionParts.staged(self)
	if _twist and ctx.field != null:
		for e in ctx.field.in_radius(origin, _r):
			var q := e as Person
			if q != null and q.is_alive():
				_noted[q.get_instance_id()] = true
	var spots: Array[Vector2] = []
	if ctx.field != null:
		for p in sleepers_at(ctx.field, origin, _r):
			if p.sleep(lv_sleep_time, _dark):
				asleep += 1
				if staged:
					DominionParts.motes(self, p.ground_pos, LID, 4)
					spots.append(Iso.ground_to_screen(p.ground_pos))
	if not staged:
		return
	if not spots.is_empty():
		# Heavy silver dust sinks onto each sleeper.
		var d := VeilCastLooks.DustFall.new()
		d.spots = spots
		d.life = DUST_LIFE
		dust = track(d, ctx.overhead) as Node2D
	# A slow violet hush: a soft ring settles to the edge. No flash.
	var w := FxParts.shockwave(self, origin, _r, FxParts.VOID)
	w.set_param("thickness", 0.1)
	w.tween_param("progress", 0.05, 1.0, 0.9, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	w.tween_param("fade", 1.0, 0.0, 0.5, 0.5)
	w.life = 1.05


## Heavy Air (level 5): from the fall to the end of the sleep, whoever walks into the circle sleeps the rest of it, is eyed and is caught
## (once per cast). Not those who stood in it at the fall, not a man another power holds (asleep, a shadow, dreaded), nobody twice.
func _fx_process(delta: float) -> void:
	if not _twist or t < T_FALL or ctx == null or ctx.field == null:
		return
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	var left := T_FALL + lv_sleep_time - t
	if left <= 0.0:
		return
	for p in sleepers_at(ctx.field, origin, _r):
		var id := p.get_instance_id()
		if not p.is_alive() or _noted.has(id) or _caught.has(id) or VeilParts.held(p):
			continue
		if ctx.crowd != null and ctx.crowd.spared(p):
			# The god's believers and whom the mission keeps alive: eyed once, never slept (VL68).
			if not _eyed_spared.has(id):
				_eyed_spared[id] = true
				PaleEye.mark(self, p, "slumber")
			continue
		if p.sleep(left, _dark):
			_caught[id] = true
			caught += 1
			PaleEye.mark(self, p, "slumber")


## The ring Heavy Air keeps drawn on the ground for the whole cast: a slow breathing violet line at the circle's edge and a faint dusk
## over it. Drawn only; it ends with its cast.
class HeavyRing extends Node2D:
	var r := 1.5
	var dark := false
	var fx_id := 0
	var _clock := 0.0

	func _process(delta: float) -> void:
		if instance_from_id(fx_id) == null:
			queue_free()
			return
		_clock += delta
		queue_redraw()

	func _draw() -> void:
		var breath := 0.5 + 0.5 * sin(_clock * 1.6)
		draw_circle(Vector2.ZERO, r, Color(VeilParts.DUSK, 0.10 + 0.04 * breath))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 72, Color(VeilParts.VEIL, 0.35 + 0.2 * breath), 0.07)
		draw_arc(Vector2.ZERO, maxf(r - 0.12, 0.01), 0.0, TAU, 72, Color(VeilParts.SILVER, 0.12 + 0.08 * breath), 0.04)
