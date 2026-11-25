class_name SilentDoom
extends FxTimeline
## Silent Doom (v0.05): a quiet death. A dark wisp gathers over everyone within RADIUS of the aim (v0.07.1; before,
## the nearest three), and they fall without a sound past a whisper and with no danger for the town to see -- no threat
## is registered and no alarm raised (Crowd.on_cast() skips quiet powers). The victims are fixed at the cast and fall
## T_STRIKE later, except anyone who has gone inside by then (a boat, a shelter). Whether anyone saw it, Crowd decides
## once they have all fallen (Crowd.DOOM_WITNESS): a witness panics, and then each death counts like any other.
## Level 5, No Witness (Veil ability levels, A1): each victim's nearest witness, named by Crowd._settle_doom() through answer_doom() (VL8),
## is eyed (the Pale Eye, "doom") and silenced too (killed &"doom", so his own death is judged at the next settle: one hop), unless the
## god's believers or the mission's keeps spare him (eyed only). A sleeper or a shadow who counts as a witness today is answerable (R4).

const RADIUS := 0.8
const T_STRIKE := 0.45
## Level 5's answer is registered with the crowd at the strike and taken back in teardown.
const KEY := "doom"
const WISP := [Color("0e0b12"), Color("231c2c"), Color("3a3048"), Color("4d4060")]


## Who the doom would take at `at`: every living person within `r` (RADIUS in the light, twice that in the dark; v0.07.1: no
## cap), nearest first.
static func victims_at(field: EnemyField, at: Vector2, r := RADIUS) -> Array[DummyEnemy]:
	var near := field.in_radius(at, r)
	near.sort_custom(func(a: DummyEnemy, b: DummyEnemy) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return near


var _twist := false
var _answer_cb := Callable()


func _build() -> void:
	duration = 1.4
	_twist = PowerBook.twist_at(extra, "doom")
	var victims := victims_at(ctx.field, origin, VeilParts.size(self, "doom", "RADIUS"))
	ctx.play(&"q_doom", origin)
	for v in victims:
		_wisp(Iso.ground_to_screen(v.ground_pos))
	if victims.is_empty():
		_wisp(Iso.ground_to_screen(origin))
	at(T_STRIKE, func() -> void:
		var struck := 0
		for v in victims:
			if not is_instance_valid(v):
				continue
			var person := v as Person
			if person != null and person.inside:
				continue  # boarded a boat or took shelter since the cast: out of reach, hidden away
			if _twist and ctx.crowd != null:
				if not _answer_cb.is_valid():
					_answer_cb = _answer
				ctx.crowd.answer_doom(person, _answer_cb)
			ctx.field.kill(v, &"doom", origin)
			struck += 1
		if struck > 0:
			ctx.play(&"q_doom_hit", origin)
		VeilParts.land(self, origin))


## A dark wisp: smoke that curls down onto the spot, then a faint puff as it takes them.
func _wisp(screen: Vector2) -> void:
	var down := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, WISP)
	down.drag = 1.2
	down.gravity = 60.0
	down.burst(14, {"radius": 7.0, "speed": Vector2(4, 14), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(18, 30),
		"alt_speed": Vector2(-30, -10), "life": Vector2(0.4, 0.7), "size": Vector2(2, 4), "size_end_mul": 0.4})
	at(T_STRIKE, func() -> void:
		var puff := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, WISP)
		puff.drag = 2.0
		puff.gravity = -25.0
		puff.burst(10, {"radius": 3.0, "speed": Vector2(6, 20), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(2, 8),
			"alt_speed": Vector2(4, 16), "life": Vector2(0.5, 0.9), "size": Vector2(2, 3), "size_end_mul": 1.6}))


## No Witness (level 5): the witness the settle named for a victim is eyed, then silenced unless the town spares him. One answer may
## already have killed a man another answer was handed (R10).
func _answer(w: Person) -> void:
	if not is_instance_valid(w) or not w.is_alive() or ctx == null:
		return
	PaleEye.mark(self, w, KEY)
	if ctx.crowd != null and ctx.crowd.spared(w):
		return
	if ctx.field != null:
		ctx.field.kill(w, &"doom", origin)


func _undo() -> void:
	if _answer_cb.is_valid() and ctx != null and ctx.crowd != null and is_instance_valid(ctx.crowd):
		ctx.crowd.unanswer_doom(_answer_cb)
	_answer_cb = Callable()


func _finish() -> void:
	_undo()
	super._finish()


func _exit_tree() -> void:
	_undo()
	super._exit_tree()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_undo()
