class_name CurfewFx
extends FxTimeline
## Curfew (Decree, Tier IV): "It is night. Sleep." T_CAST after the cast, everyone within RADIUS of the click -- any
## role, up to MAX_PEOPLE, nearest first -- falls asleep where they stand for SLEEP_TIME (Person.sleep(): down on the
## ground, thinking nothing, going nowhere). A sleeper is woken early by a loud blow close enough to hear
## (Crowd._react(): a power's impact, a collapse), by a hurt, or by anything that takes the mind; the rest wake when
## the time is up and take up their day. Those inside a building do not hear the decree. Quiet when cast, but for the
## book entry's "alarm": a street asleep is a strange thing to pass. The cast locks the other slots until it lands.

const RADIUS := 4.0
const SLEEP_TIME := 30.0
const T_CAST := 1.0
const MAX_PEOPLE := 80
const NIGHT := Color("1a1030")
const NIGHT_LIFE := [Color("c8b8e8"), Color("7a6aa8"), Color("3a2a60"), Color(0.08, 0.04, 0.15, 0.5)]

## How many fell asleep.
var asleep := 0


func _build() -> void:
	duration = T_CAST + SLEEP_TIME + 1.0
	busy = T_CAST + 0.3
	at(T_CAST, _night)
	ctx.play(&"q_curfew", origin)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, origin, 90.0, 100.0, T_CAST, 1.6)
		var plate := DecreeParts.seal(self, origin, DecreeParts.MOON, T_CAST + SLEEP_TIME, 100.0, 4)
		plate.shrink_at = T_CAST + 2.5
		plate.shrink_px = 2
		var mark := FxParts.rings(self, origin, RADIUS, DecreeParts.GILT, 2, 30.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_CAST, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_CAST + 0.1


func _night() -> void:
	var staged := DominionParts.staged(self)
	for p in DominionParts.near(ctx.field, origin, RADIUS, MAX_PEOPLE):
		if p.sleep(SLEEP_TIME):
			asleep += 1
			if staged:
				DominionParts.motes(self, p.ground_pos, NIGHT_LIFE, 5)
	if not staged:
		return
	# Night falls on the circle: a dark ring out to its edge, and the ground stays in dusk while they sleep.
	var w := FxParts.shockwave(self, origin, RADIUS, FxParts.VOID)
	w.set_param("thickness", 0.1)
	w.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	w.tween_param("fade", 1.0, 0.0, 0.3, 0.4)
	w.life = 0.75
	var dusk := Dusk.new()
	dusk.fx = self
	dusk.position = origin
	dusk.z_index = 2
	track(dusk, ctx.ground)
	DecreeParts.scatter(self, origin, 10, 40.0)
	ctx.flash.call(Color(0.05, 0.02, 0.12, 0.25), 0.8)


## How much of the night shows: in as it falls, out as the sleep ends.
func shown() -> float:
	return clampf(minf((t - T_CAST) / 0.6, (T_CAST + SLEEP_TIME + 0.8 - t) / 0.8), 0.0, 1.0)


## The dusk on the ground: a dark disc, breathing slowly, with a faint gilt rim.
class Dusk extends Node2D:
	var fx: CurfewFx

	func _process(_delta: float) -> void:
		if fx.t > T_CAST + SLEEP_TIME + 0.9:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var breathe := 0.9 + 0.1 * sin(fx.t * 0.9)
		draw_circle(Vector2.ZERO, RADIUS * breathe, Color(NIGHT, 0.5 * a))
		draw_circle(Vector2.ZERO, RADIUS * 0.6 * breathe, Color(NIGHT, 0.3 * a))
		draw_arc(Vector2.ZERO, RADIUS * breathe, 0.0, TAU, 72, Color(DecreeParts.GILT, 0.6 * a), 0.08)
