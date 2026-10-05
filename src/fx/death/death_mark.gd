class_name DeathMarkFx
extends FxTimeline
## Death Mark (Death, Tier I): one person is marked. The one nearest the click (PICK_R) -- any role -- grows frail and
## slow for MARK_TIME (Person.statuses: "frail", any blow kills it; "slow", SLOW of its pace), wearing the mark, and then
## dies where it stands (damage kind deathmark), unless it is inside somewhere by then. The body lies where it fell for
## DummyEnemy.BODY_HOLD, and the town finds it: the death is an ordinary one -- it counts, the alarm hears of it, soldiers
## come to look -- and every LOOK_EVERY up to GAWKERS people going about their day within LOOK_R walk over and stand
## staring (Person.lure()) for LOOK_SECONDS. Quiet when cast: a frail man walking is nothing to see. The cast locks the
## other slots for 0.8 s.

const PICK_R := 1.0
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


## Whom a click at `at` would mark: the nearest within PICK_R, or null.
static func target_at(field: EnemyField, at: Vector2) -> Person:
	var near := DominionParts.near(field, at, PICK_R, 1)
	return near[0] if not near.is_empty() else null


func _build() -> void:
	duration = MARK_TIME + DummyEnemy.BODY_HOLD
	busy = 0.8
	marked = target_at(ctx.field, origin)
	if marked == null:
		duration = 1.0
		return
	marked.statuses[&"frail"] = 1.0
	marked.statuses[&"slow"] = SLOW
	marked.walk_speed = marked._mind_speed()
	marked.set_badge(SKULL, PALE, MARK_TIME)
	at(MARK_TIME, _die)
	ctx.play(&"grav_suction", origin, -14.0)
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
	_look_in = 0.5
	if DominionParts.staged(self):
		DominionParts.motes(self, body_at, SHADE, 10)
		DominionParts.pulse(self, body_at, 1.2, Color(0.6, 0.5, 0.8), 0.4, 1.5)


func _fx_process(delta: float) -> void:
	if body_at == Vector2.INF:
		return
	_look_in -= delta
	if _look_in > 0.0:
		return
	_look_in = LOOK_EVERY
	var came := 0
	for p in DominionParts.near(ctx.field, body_at, LOOK_R):
		if came >= GAWKERS:
			break
		var a := ctx.rng.randf() * TAU
		if p.lure(body_at + Vector2(cos(a), sin(a)) * ctx.rng.randf_range(RING.x, RING.y), LOOK_SECONDS):
			came += 1
	gawked += came
