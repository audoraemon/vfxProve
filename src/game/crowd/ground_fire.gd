class_name GroundFire
extends RefCounted
## A patch of burning ground (Dragonfire Parade): a fire on the ground, not on a building. Plain state plus the rules that
## need no town -- the burn-down rate and the harm to who stays in it. The FireManager keeps the patches of a town (lay
## order), frightens the town with them, and lets them catch buildings; with no town the patch's sprite steps it itself.
## It never grows, never moves and never spreads over ground.

## Burning radius (ground units).
const RADIUS := 0.7
## Strength lost a second untended (1.0 to 0 in 40 s), and per beater (the beaters replace the burning-down).
const BURN_DOWN := 0.025
const BEAT := 0.06
## "Full strength" is strength above this; beaters wait a step back until it has burned down to it.
const BEAT_FROM := 0.9
## Beaters per patch, at most.
const CREW := 3
## Seconds inside that kill, how often the fire looks for who is in it, how fast heat leaves a person once out.
const BURN_KILL := 1.5
const HARM_TICK := 0.1
const COOL := 0.5
## How long a scorched person shows soot.
const SCORCH_SHOW := 8.0
## The danger's radius is RADIUS + THREAT_PAD; a building touches a patch within RADIUS + TOUCH.
const THREAT_PAD := 0.3
const TOUCH := 0.3
## The beat ring and the wait ring lie at radius + gap from the centre; a beater swings this often.
const BEAT_GAP := 0.35
const WAIT_GAP := 1.0
const BEAT_SWING := 0.6
## Float drift: forty seconds of quarter-second subtractions leave a residue of about 1e-16, not 0.
const END_BELOW := 1e-9

var id := 0
var at := Vector2.ZERO
var radius := RADIUS
var strength := 1.0
var out := false
## Out with at least one beater beating (else it burned out).
var beaten := false
## True while a FireManager keeps it (it renews its danger and catches buildings); false: its sprite steps it.
var owned := false
var crew: Array[Person] = []
var threat_id := -1
var renew_in := 0.0
## The angle from the centre to the first beater (the ring's first slot); INF until a crew is picked.
var base_angle := INF


func _init(p_at := Vector2.ZERO, p_radius := RADIUS, p_id := 0) -> void:
	at = p_at
	radius = p_radius
	id = p_id


## The rate rule: `strength -= dt * maxf(BURN_DOWN, beaters * BEAT)`. At 0 it is out, beaten when someone was beating.
func burn_down(dt: float, beaters: int) -> void:
	if out:
		return
	strength -= dt * maxf(BURN_DOWN, float(beaters) * BEAT)
	if strength <= END_BELOW:
		strength = 0.0
		out = true
		beaten = beaters > 0


func full() -> bool:
	return strength > BEAT_FROM


## Whether the ground point `g` lies in the fire.
func over(g: Vector2) -> bool:
	return g.distance_to(at) <= radius


## The harm rule, shared by the town and the no-town path. Every living unit within a burning patch's radius (a person
## inside a building is safe) is in the fire this tick, once however many patches overlap; its `heat` (a dictionary
## `{DummyEnemy: {"heat": seconds, "in": bool}}`, insertion order) rises by `dt`, and at BURN_KILL it dies. A person
## entering is frightened (no startle) and shows soot; one out of the fire cools. Returns how many died.
static func scorch(field: EnemyField, patches: Array, heat: Dictionary, dt: float) -> int:
	var burning: Array = []
	var first := {}
	for p: GroundFire in patches:
		if p.out:
			continue
		for e in field.in_radius(p.at, p.radius):
			if e is Person and (e as Person).inside:
				continue
			if first.has(e):
				continue
			first[e] = p
			burning.append(e)
	var deaths := 0
	for e: DummyEnemy in burning:
		var patch: GroundFire = first[e]
		var entry: Dictionary = heat.get(e, {})
		var entering := entry.is_empty() or not bool(entry.get("in", false))
		var h := float(entry.get("heat", 0.0)) + dt
		heat[e] = {"heat": h, "in": true}
		if e is Person:
			var person := e as Person
			if entering:
				person.panic(patch.at, patch.radius + THREAT_PAD, &"fire", false)
			person.scorched_left = SCORCH_SHOW
		if h >= BURN_KILL - 0.001:
			heat.erase(e)
			if field.kill(e, &"fire", patch.at):
				deaths += 1
	for e in heat.keys():
		if first.has(e):
			continue
		if not is_instance_valid(e) or not (e as DummyEnemy).is_alive():
			heat.erase(e)
			continue
		var entry: Dictionary = heat[e]
		var h := float(entry.heat) - COOL * dt
		if h <= 0.0:
			heat.erase(e)
		else:
			heat[e] = {"heat": h, "in": false}
	return deaths
