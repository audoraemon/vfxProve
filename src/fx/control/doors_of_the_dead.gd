class_name DoorsOfTheDeadFx
extends FxTimeline
## Doors of the Dead (Passage, Tier V; Discord #ideas "New T5 Passage Ability"): every door in a district opens onto
## the other side. One click; for everyone within RADIUS of it the air turns cold over T_CHILL -- frost creeps over the
## ground from the click outward, a pale fog settles, ash-white flakes fall -- and from then on whoever stands in the
## cold walks at COLD_SLOW of their pace (Person.statuses "slow"; their own pace back when they leave it or it lifts).
## Then the doors open, nearest first, over WAVE: the MAX_DOORS nearest buildings with a door (EveryDoorFx.DOOR_ROLES)
## within RADIUS. As a door opens, whoever shelters in that building is thrown out into the street, knocked down
## (ShelterManager.throw_out_of()), the building takes DOOR_HIT, frost runs up its walls, and for the rest of the span
## it is cursed (Crowd.mark_structure(): nobody takes shelter in it), and the town sees a danger at its door. Out of
## every open door the other side keeps coming for the whole SPAN, one every OUT_EVERY a door (the first OUT_FIRST after
## it opens) -- a flood that fills back what the guard cuts down: never more than LIVE_CAP on their feet at once, and
## MAX_SPIRITS through in all -- in a fixed turn (ORDER -- no luck): hellhounds, ghosts and demons, Visitors all:
##   hellhound  Hound Gate's hound: fast, four blows, bites through the guard's blows.
##   ghost      slow, half seen, drifts straight through walls and houses to its prey ("phase"); every FRIGHT_EVERY
##              whoever is near it is frightened; three blows, and a blow makes it begin its touch again.
##   demon      a head taller than a man; eight blows, bites through them, and claws at buildings ("wreck"): the house
##              it runs past or, with nobody near, the nearest it can reach.
## A citizen falls to one bite or touch, a soldier to two (damage kind frenzy). SPAN after the last door opens the
## other side calls them back: every spirit runs back to its own door (RECALL at most, then it is gone), the doors
## close, and the cold lifts over THAW. Loud (PowerBook.REACH): the first spirit through is the first danger.
## Once a descent.
##
## Ability levels (PowerBook "deaddoors" levels; level 1 is the numbers above): the district (RADIUS), the doors
## (MAX_DOORS), the span (SPAN) and the spirits in all (MAX_SPIRITS) grow, read once a cast into the lv_ numbers;
## LIVE_CAP stays at every level. Level 5's twist, Rise Again: whoever the horde kills rises RISE_AFTER later where they
## fell, a ghost of the other side (KINDS' ghost: through walls, frightening), and hunts with it. A risen ghost stands in
## the shared LIVE_CAP (none rises while it is full: one whose moment comes at the cap stays down) but is no spirit
## through a door (`spirits` and MAX_SPIRITS count the doors' only; `risen` counts these). Those they kill rise too,
## until the span ends: then the doors call every one of them back to the open door nearest where they rose.

const RADIUS := 12.0
const T_CHILL := 2.0
const WAVE := 2.4
const SPAN := 45.0
const RECALL := 5.0
const THAW := 2.0
const COLD_SLOW := 0.55
const COLD_TICK := 0.25
const MAX_DOORS := 18
const LIVE_CAP := 70
const MAX_SPIRITS := 160
const OUT_FIRST := 0.6
const OUT_EVERY := 2.5
const DOOR_HIT := 15.0
const THROW := 1.0
## The turn the other side comes through in, over every door: hounds and ghosts most, a demon every few.
const ORDER: Array[Animal.Breed] = [Animal.Breed.HELLHOUND, Animal.Breed.GHOST, Animal.Breed.DEMON, Animal.Breed.HELLHOUND,
	Animal.Breed.GHOST, Animal.Breed.HELLHOUND, Animal.Breed.GHOST, Animal.Breed.DEMON]
## Each kind: [blows, pace (ground units a second), seek reach, bite reach, seconds a bite, flinches].
const KINDS := {
	Animal.Breed.HELLHOUND: [4, 2.4, 12.0, 0.5, 1.0, false],
	Animal.Breed.GHOST: [3, 1.2, 12.0, 0.45, 1.6, true],
	Animal.Breed.DEMON: [8, 1.5, 10.0, 0.6, 1.2, false],
}
const DEMON_WRECK := 20.0
const DEMON_WRECK_EVERY := 1.5
const DEMON_WRECK_REACH := 0.6
const FRIGHT_EVERY := 1.0
## Spirits that trail embers or mist at once, at most: a horde of emitters costs more than it shows.
const TRAILS := 30
const FRIGHT_R := 1.8
## The other side's light: a cold green-white spirit glow; the ember of the hounds and demons; the cold of the zone.
const SPIRIT := Color("8dffd8")
const SPIRIT_DEEP := Color(0.08, 0.02, 0.16)
const EMBER := Color(1.0, 0.45, 0.1)
const COLD := Color(0.62, 0.78, 0.95)
const MIST := [Color(0.85, 0.95, 1.0, 0.5), Color(0.7, 0.85, 0.95, 0.35), Color(0.55, 0.7, 0.85, 0.2), Color(0.4, 0.5, 0.65, 0.0)]
const WISP := [Color("e8fff6"), Color("8dffd8"), Color(0.3, 0.8, 0.65, 0.5), Color(0.1, 0.3, 0.3, 0.0)]
## Rise Again (level 5): seconds from the kill to the ghost.
const RISE_AFTER := 2.0
const PITCH := [Color("1a1418"), Color("16121a"), Color("120f14"), Color(0.07, 0.06, 0.08, 0.8), Color(0.05, 0.04, 0.06, 0.4)]

## One door of the other side.
class Door extends RefCounted:
	var building: Structure
	var at := Vector2.ZERO
	var out := Vector2.DOWN
	var opens := 0.0
	var released := 0
	var next_out := 0.0
	var open := false
	var glow: DoorGlow

## The doors, the spirits, how many have come through, and who was thrown out of a door.
var doors: Array[Door] = []
var visitors: Visitors
## What comes through heard while it roams, and its bites, claws and touches.
var voices := VisitorVoices.new()
var spirits := 0
var thrown := 0
## Buildings the demons struck, and the blows.
var wrecks := 0
## This cast's numbers at its ability level (the constants at level 1): the district, the doors, the span, the spirits.
var lv_radius := RADIUS
var lv_max_doors := MAX_DOORS
var lv_span := SPAN
var lv_max_spirits := MAX_SPIRITS
## Rise Again (level 5): whether the horde's dead rise; how many have; the risen ghosts, in the order they rose.
var rise_again := false
var risen := 0
var raised: Array[Animal] = []

## Who is in the cold, by instance id -> [Person, the "slow" they had before it (or null)].
var _cold := {}
var _cold_in := 0.0
var _trails := {}
var _fright_in := {}
var _recalled := false
## Rise Again: the dead waiting to rise -- [the moment, where they fell] -- and who has been counted (instance ids).
var _rising: Array = []
var _fallen := {}
var _fog: QuadFx
var _frost: QuadFx
var _chill: QuadFx


func t_end() -> float:
	return T_CHILL + WAVE + lv_span


func closed_at() -> float:
	return t_end() + RECALL


## When the first spirit comes through (the first door opens at T_CHILL).
static func first_out() -> float:
	return T_CHILL + OUT_FIRST


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "deaddoors", "RADIUS", RADIUS))
	lv_max_doors = int(PowerBook.stat(extra, "deaddoors", "MAX_DOORS", MAX_DOORS))
	lv_span = float(PowerBook.stat(extra, "deaddoors", "SPAN", SPAN))
	lv_max_spirits = int(PowerBook.stat(extra, "deaddoors", "MAX_SPIRITS", MAX_SPIRITS))
	rise_again = PowerBook.twist_at(extra, "deaddoors")
	duration = closed_at() + THAW + 0.1
	busy = T_CHILL
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, _grid(), parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	visitors.wrecked.connect(_on_wreck)
	if rise_again:
		visitors.bitten.connect(_on_kill)
	_pick_doors()
	ctx.play(&"dead_chill", origin, -2.0)
	for d in doors:
		at(d.opens, _open.bind(d))
	at(t_end(), _call_back)
	at(closed_at(), _close_all)
	if not DominionParts.staged(self):
		return
	# The cold comes in from the click: frost over the ground, a pale fog, the light gone grey-blue, flakes falling.
	_frost = FxParts.frost_ground(self, origin, lv_radius)
	_frost.set_param("progress", 0.0)
	_frost.tween_param("progress", 0.0, 1.0, T_CHILL, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_fog = FxParts.fog(self, origin, lv_radius * 1.05, Color(COLD, 0.42))
	_fog.set_param("fade", 0.0)
	_fog.tween_param("fade", 0.0, 1.0, T_CHILL, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_chill = FxParts.ground_light(self, origin, lv_radius, Color(0.35, 0.5, 0.75), 0.0)
	_chill.tween_param("intensity", 0.0, 0.35, T_CHILL, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var sp := Iso.ground_to_screen(origin)
	var px := Iso.radius_to_screen(lv_radius)
	var flakes := FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -60), PixelParticles.Shape.SQUARE,
		[Color(0.95, 0.98, 1.0, 0.9), Color(0.85, 0.92, 1.0, 0.7), Color(0.7, 0.8, 0.95, 0.0)], 40.0, closed_at(),
		{"radius": px.x * 0.85, "speed": Vector2(2, 8), "alt": Vector2(30, 90), "alt_speed": Vector2(-22, -10),
			"life": Vector2(2.0, 3.5), "size": Vector2(1, 1)})
	flakes.gravity = 6.0
	flakes.drag = 0.4
	ctx.shake.add_trauma(0.15)


## The walk grid the spirits keep to: the town's, by way of anyone in it.
func _grid() -> WalkGrid:
	for e in ctx.field.alive():
		var p := e as Person
		if p != null and p.grid != null:
			return p.grid
	return null


## The MAX_DOORS nearest buildings with a door within RADIUS (at the cast's level), nearest first, each opening in turn
## over WAVE.
func _pick_doors() -> void:
	var near: Array = []
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.destroyed or not (s.role in EveryDoorFx.DOOR_ROLES):
			continue
		var d := s.distance_to(origin)
		if d <= lv_radius:
			near.append([d, s])
	near.sort_custom(func(a, b) -> bool: return float(a[0]) < float(b[0]))
	var grid := _grid()
	var n := mini(near.size(), lv_max_doors)
	for i in n:
		var door := Door.new()
		door.building = near[i][1]
		door.at = EveryDoorFx.door_of(door.building, grid)
		var away := door.at - door.building.center()
		door.out = away.normalized() if away.length() > 0.01 else Vector2.DOWN
		door.opens = T_CHILL + (WAVE * float(i) / float(maxi(n - 1, 1)) if n > 1 else 0.0)
		door.next_out = door.opens + OUT_FIRST
		doors.append(door)


## A door opens on the other side: those sheltering there are thrown out, the house is struck and frosted, no one
## shelters in it while it stands open, and the town sees a danger at it.
func _open(d: Door) -> void:
	if not is_instance_valid(d.building) or d.building.destroyed:
		return
	d.open = true
	var left := t_end() - t + RECALL
	if ctx.crowd != null:
		if ctx.crowd.shelters != null:
			thrown += ctx.crowd.shelters.throw_out_of(d.building, THROW).size()
		ctx.crowd.mark_structure(d.building, &"cursed", left)
		ctx.crowd.threats.register(d.at, 1.2, 0.7, left, 6.0, 8.0, &"beast")
	d.building.damage(DOOR_HIT, d.at, &"frenzy")
	if d == doors[0]:
		ctx.play(&"dead_door", d.at, 4.0)  # the first door breaks open: the power's main cue
	else:
		ctx.play(&"dead_creak", d.at, -8.0)
	if not DominionParts.staged(self):
		return
	d.building.mark_hit(0.35, &"ice")
	d.glow = DoorGlow.new()
	d.glow.fx = self
	d.glow.door = d
	d.glow.size = Vector2(11, 17) if d.building.role == &"house" else Vector2(15, 23)
	d.glow.position = Iso.ground_to_screen(d.at)
	track(d.glow, ctx.world if ctx.world != null else ctx.overhead)
	var light := FxParts.ground_light(self, d.at + d.out * 0.6, 1.4, SPIRIT, 0.0)
	light.tween_param("intensity", 0.0, 0.7, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.tween_param("intensity", 0.7, 0.0, 1.0, closed_at() - t)
	light.life = closed_at() - t + 1.1
	var sp := Iso.ground_to_screen(d.at) + Vector2(0, -8)
	# The doorway burns with the other side's light while it stands open: a glow over it, breathing (DoorGlow).
	var halo := FxParts.bloom(self, sp, 34.0, SPIRIT, 0.0, 1.1)
	halo.tween_param("intensity", 0.0, 0.55, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	halo.tween_param("intensity", 0.55, 0.0, 0.6, closed_at() - t)
	halo.life = closed_at() - t + 0.65
	var burst := FxParts.bloom(self, sp, 40.0, SPIRIT, 1.1, 0.9)
	burst.tween_param("intensity", 0.9, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.55
	FxParts.smoke(self, Iso.ground_to_screen(d.at + d.out * 0.3), 6.0, 10.0, left, Vector2(4, 12), Vector2(2, 4),
		Vector2(0.8, 1.4), Color(SPIRIT, 0.15), MIST)
	ctx.shake.kick(Vector2(0, 1.2))


func _fx_process(delta: float) -> void:
	visitors.step(delta)
	voices.step(delta, visitors.living(), ctx.play)
	_tick_cold(delta)
	if t < t_end():
		_release_due()
		if not _rising.is_empty():
			_rise_due()
	_frighten(delta)
	if not DominionParts.staged(self):
		return
	for a in _trails.keys():
		if not is_instance_valid(a) or not a.is_alive():
			_stop_trail(a)
			continue
		var e: PixelParticles = _trails[a]
		if is_instance_valid(e):
			e.position = Iso.ground_to_screen(a.ground_pos) + Vector2(0, -8)


## Every open door whose turn is up lets one through, while fewer than LIVE_CAP are on their feet and the other side
## has sent fewer than MAX_SPIRITS; a turn missed at the cap is not made up.
func _release_due() -> void:
	var alive := visitors.living().size()
	for d in doors:
		if not d.open or t < d.next_out:
			continue
		d.next_out += OUT_EVERY
		if not is_instance_valid(d.building) or d.building.destroyed:
			d.open = false  # a fallen house is no door
			continue
		if alive >= LIVE_CAP or spirits >= lv_max_spirits:
			continue
		d.released += 1
		alive += 1
		_release(d, ORDER[spirits % ORDER.size()])


func _release(d: Door, breed: Animal.Breed) -> void:
	spirits += 1
	var spec: Array = KINDS[breed]
	var spot := d.at + d.out * 0.45
	var grid := _grid()
	if grid != null and not grid.walkable(spot):
		var w := grid.nearest_walkable(spot, 4)
		if w != Vector2.INF:
			spot = w
	var a := visitors.summon(spot, breed, int(spec[0]), float(spec[1]) / (Animal.DOG_SPEED * Animal.RUN), float(spec[2]),
		float(spec[3]), float(spec[4]), bool(spec[5]))
	a.facing = 1 if d.out.x - d.out.y >= 0.0 else -1
	match breed:
		Animal.Breed.GHOST:
			visitors.give(a, {"phase": true})
			_fright_in[a] = FRIGHT_EVERY
			ctx.play(&"ghost_moan", spot, -4.0)
		Animal.Breed.DEMON:
			visitors.give(a, {"wreck": DEMON_WRECK, "wreck_every": DEMON_WRECK_EVERY, "wreck_reach": DEMON_WRECK_REACH})
			ctx.play(&"demon_snarl", spot, -2.0)
		_:
			ctx.play(&"hound_howl", spot, -5.0)
	if not DominionParts.staged(self):
		return
	if d.glow != null and is_instance_valid(d.glow):
		d.glow.flare = 1.0
	var sp := Iso.ground_to_screen(spot)
	var ghost := breed == Animal.Breed.GHOST
	FxParts.smoke(self, sp, 5.0, 18.0, 0.2, Vector2(10, 26), Vector2(2, 4), Vector2(0.35, 0.7),
		Color(SPIRIT, 0.4) if ghost else Color(EMBER, 0.4), MIST if ghost else PITCH)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 8, WISP if ghost else FxParts.EMBER_LIFE, Vector2(30, 110), Vector2(30, 110))
	if _trails.size() >= TRAILS:
		return
	var trail := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, WISP if ghost else FxParts.EMBER_LIFE,
		6.0 if ghost else 4.0, duration - t + 8.0,  # stopped by hand (_stop_trail()): its own stop falls after the end
		{"radius": 4.0, "speed": Vector2(2, 8), "alt": Vector2(2, 10), "alt_speed": Vector2(6, 20), "life": Vector2(0.4, 0.8),
			"size": Vector2(1, 1)})
	trail.gravity = -14.0
	trail.drag = 1.0
	_trails[a] = trail


## Ghosts fill whoever is near them with dread, every FRIGHT_EVERY.
func _frighten(delta: float) -> void:
	if ctx.crowd == null:
		return
	for a in _fright_in.keys():
		if not is_instance_valid(a) or not a.is_alive():
			_fright_in.erase(a)
			continue
		var left := float(_fright_in[a]) - delta
		if left > 0.0:
			_fright_in[a] = left
			continue
		_fright_in[a] = FRIGHT_EVERY
		ctx.crowd.fright(a.ground_pos, FRIGHT_R, 0.5, 2.0, 3.0, 3.0, &"beast")


## The cold: everyone out in it walks at COLD_SLOW; whoever leaves it, or when it lifts, has their pace back.
func _tick_cold(delta: float) -> void:
	_cold_in -= delta
	if _cold_in > 0.0:
		return
	_cold_in = COLD_TICK
	var cold := t >= T_CHILL and t < closed_at()
	var now := {}
	if cold:
		for e in ctx.field.in_radius(origin, lv_radius):
			var p := e as Person
			if p == null or not p.is_alive():
				continue
			var id := p.get_instance_id()
			now[id] = true
			if not _cold.has(id):
				_cold[id] = [p, null]
				p.hold_pace(get_instance_id(), COLD_SLOW)
	for id in _cold.keys():
		if now.has(id):
			continue
		_warm(id)


func _warm(id: int) -> void:
	var held: Array = _cold[id]
	_cold.erase(id)
	var p: Person = held[0]
	if not is_instance_valid(p):
		return
	p.free_pace(get_instance_id())


## Whether `p` is in the cold now.
func chilled(p: Person) -> bool:
	return _cold.has(p.get_instance_id())


## The span is over: the other side calls its own back, each to the door it came out of.
func _call_back() -> void:
	_recalled = true
	_rising.clear()  # the span is over: whoever has not risen yet stays down
	visitors.recall(RECALL)
	ctx.play(&"dead_recall", origin, -4.0)


## The doors close; whoever of the other side has not made it back is gone anyway; the cold begins to lift.
func _close_all() -> void:
	for a in visitors.living():
		_burn(a)
	visitors.clear()
	for d in doors:
		d.open = false
	for id in _cold.keys():
		_warm(id)
	ctx.play(&"dead_close", origin, -6.0)
	if not DominionParts.staged(self):
		return
	if is_instance_valid(_frost):
		_frost.tween_param("fade", 1.0, 0.0, THAW, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	if is_instance_valid(_fog):
		_fog.tween_param("fade", 1.0, 0.0, THAW, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	if is_instance_valid(_chill):
		_chill.tween_param("intensity", 0.35, 0.0, THAW, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)


func _burn(a: Animal) -> void:
	_stop_trail(a)
	if not DominionParts.staged(self) or not is_instance_valid(a):
		return
	var sp := Iso.ground_to_screen(a.ground_pos)
	var ghost := a.breed == Animal.Breed.GHOST
	FxParts.smoke(self, sp, 6.0, 30.0, 0.4, Vector2(16, 40), Vector2(2, 5), Vector2(0.5, 1.0),
		Color(SPIRIT if ghost else EMBER, 0.5), MIST if ghost else PITCH)


## A bite or a touch: the first one's outcry is the town's (a danger there, the alarm up), every one a shout.
func _on_bite(a: Animal, victim: Person, first: bool) -> void:
	voices.bite(a, ctx.play)
	ctx.play(&"cit_shout", victim.ground_pos, 0.0)
	if first and ctx.crowd != null:
		ctx.crowd.fright(victim.ground_pos, 2.0, 0.6, 3.0, 6.0, 8.0, &"bite", true)
		ctx.crowd.add_alarm(0.6)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(a.ground_pos) + Vector2(0, -8)
	FxParts.sparks(self, ctx.overhead, sp, 5, WISP if a.breed == Animal.Breed.GHOST else FxParts.EMBER_LIFE,
		Vector2(30, 90), Vector2(20, 80))


## Rise Again (level 5): the horde's kill. One the bite left dead rises RISE_AFTER on where they fell, while the span
## lasts; the body pales as it waits, in the other side's mist.
func _on_kill(_a: Animal, victim: Person, _first: bool) -> void:
	if not is_instance_valid(victim) or victim.is_alive() or _recalled or t >= t_end():
		return
	var id := victim.get_instance_id()
	if _fallen.has(id):
		return
	_fallen[id] = true
	var spot := victim.ground_pos
	_rising.append([t + RISE_AFTER, spot])
	if not DominionParts.staged(self):
		return
	# The body pales: a cold green-white light gathers on it and the mist of the other side rises off it.
	var sp := Iso.ground_to_screen(spot)
	var pale := FxParts.bloom(self, sp + Vector2(0, -3), 12.0, SPIRIT, 0.0, 0.6)
	pale.tween_param("intensity", 0.0, 0.8, RISE_AFTER, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	pale.tween_param("intensity", 0.8, 0.0, 0.4, RISE_AFTER)
	pale.life = RISE_AFTER + 0.45
	var lit := FxParts.ground_light(self, spot, 0.9, SPIRIT, 0.0)
	lit.tween_param("intensity", 0.0, 0.6, RISE_AFTER, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	lit.tween_param("intensity", 0.6, 0.0, 0.5, RISE_AFTER)
	lit.life = RISE_AFTER + 0.55
	FxParts.smoke(self, sp, 5.0, 8.0, RISE_AFTER, Vector2(4, 14), Vector2(2, 4), Vector2(0.6, 1.1), Color(SPIRIT, 0.2), MIST)


## Rise Again: the dead whose moment has come rise, while there is room under LIVE_CAP; one whose moment finds it full
## stays down (no waiting, no luck).
func _rise_due() -> void:
	while not _rising.is_empty() and t >= float(_rising[0][0]):
		var spot: Vector2 = _rising.pop_front()[1]
		if visitors.living().size() >= LIVE_CAP:
			continue
		_rise(spot)


## A ghost of the other side stands up where one fell. Its gate is the open door nearest it (summoned there, then set
## where the body lies), so the call back at the span's end takes it home through a door.
func _rise(spot: Vector2) -> void:
	var gate := spot
	var best := INF
	for d in doors:
		if not d.open or not is_instance_valid(d.building) or d.building.destroyed:
			continue
		var dist := d.at.distance_to(spot)
		if dist < best:
			best = dist
			gate = d.at + d.out * 0.45
	var spec: Array = KINDS[Animal.Breed.GHOST]
	var a := visitors.summon(gate, Animal.Breed.GHOST, int(spec[0]), float(spec[1]) / (Animal.DOG_SPEED * Animal.RUN),
		float(spec[2]), float(spec[3]), float(spec[4]), bool(spec[5]))
	a.ground_pos = spot
	a.sync_position()
	visitors.give(a, {"phase": true})
	_fright_in[a] = FRIGHT_EVERY
	risen += 1
	raised.append(a)
	ctx.play(&"q_wisp", spot, -2.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(spot)
	var burst := FxParts.bloom(self, sp + Vector2(0, -8), 22.0, SPIRIT, 1.0, 1.0)
	burst.tween_param("intensity", 1.0, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.55
	FxParts.smoke(self, sp, 6.0, 20.0, 0.25, Vector2(12, 30), Vector2(2, 4), Vector2(0.4, 0.8), Color(SPIRIT, 0.4), MIST)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 10, WISP, Vector2(30, 110), Vector2(40, 130))
	if _trails.size() >= TRAILS:
		return
	var trail := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, WISP, 6.0, duration - t + 8.0,
		{"radius": 4.0, "speed": Vector2(2, 8), "alt": Vector2(2, 10), "alt_speed": Vector2(6, 20), "life": Vector2(0.4, 0.8),
			"size": Vector2(1, 1)})
	trail.gravity = -14.0
	trail.drag = 1.0
	_trails[a] = trail


func _on_cut_down(a: Animal, at_ground: Vector2) -> void:
	_stop_trail(a)
	_fright_in.erase(a)
	ctx.play(&"dead_fall", at_ground, -8.0)
	if not DominionParts.staged(self):
		return
	var ghost := a.breed == Animal.Breed.GHOST
	var sp := Iso.ground_to_screen(at_ground)
	FxParts.smoke(self, sp, 7.0, 40.0, 0.2, Vector2(18, 44), Vector2(3, 6), Vector2(0.6, 1.2),
		Color(SPIRIT if ghost else EMBER, 0.5), MIST if ghost else PITCH)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 12, WISP if ghost else FxParts.EMBER_LIFE, Vector2(50, 160), Vector2(30, 140))


## A demon's claws on a wall: splinters, dust and a knock.
func _on_wreck(a: Animal, s: Structure) -> void:
	wrecks += 1
	voices.bite(a, ctx.play)
	ctx.play(&"debris_small", a.ground_pos, -6.0)
	if not DominionParts.staged(self):
		return
	var hit := a.ground_pos.clamp(s.footprint.position, s.footprint.end)
	var sp := Iso.ground_to_screen(hit) + Vector2(0, -10)
	FxParts.debris(self, sp, 4, 4.0, Vector2(30, 110), FxParts.ROCK, Vector2(1.5, 2.5), true)
	FxParts.sparks(self, ctx.overhead, sp, 4, FxParts.EMBER_LIFE, Vector2(30, 90), Vector2(20, 70))


## Untyped: a spirit called back is freed by the Visitors before its trail is stopped.
func _stop_trail(a: Variant) -> void:
	if _trails.has(a):
		var e: PixelParticles = _trails[a]
		if is_instance_valid(e):
			e.emitting = false
		_trails.erase(a)


func kills() -> int:
	return visitors.kills if visitors != null else 0


## Over, or cut short (end_now()): the spirits go back, the cold lifts, the doors are only doors again.
func _finish() -> void:
	if visitors != null:
		visitors.clear()
	for id in _cold.keys():
		_warm(id)
	super()


## A door onto the other side, standing on the building's face: a dark doorway `size` px with the spirit light
## turning in it, a cold rim, light spilled on the street before it. It opens from a slit as the door opens, flares
## (`flare`) as one comes through, breathes while it stands, and shuts to a slit when the doors close.
class DoorGlow extends Node2D:
	var fx: DoorsOfTheDeadFx
	var door: Door
	var size := Vector2(8, 13)
	var flare := 0.0

	func _process(delta: float) -> void:
		flare = maxf(flare - delta * 3.0, 0.0)
		if fx.t > fx.closed_at() + 0.6:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var age := fx.t - door.opens
		if age < 0.0:
			return
		if not is_instance_valid(door.building) or door.building.destroyed:
			queue_free()  # its house is down: no door left to burn
			return
		var k := clampf(age / 0.5, 0.0, 1.0)
		if fx.t > fx.closed_at():
			k *= 1.0 - clampf((fx.t - fx.closed_at()) / 0.6, 0.0, 1.0)
		if k <= 0.01:
			return
		var w := size.x * (0.2 + 0.8 * k)
		var h := size.y
		var breathe := 0.8 + 0.2 * sin(fx.t * 4.0 + door.at.x)
		var r := Rect2(-w * 0.5, -h, w, h)
		# Light spilled on the street before it: a flat pool.
		draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 18.0 * k, Color(SPIRIT, 0.12 * breathe + 0.2 * flare))
		draw_circle(Vector2.ZERO, 10.0 * k, Color(SPIRIT, 0.2 * breathe + 0.2 * flare))
		draw_set_transform(Vector2.ZERO)
		# The halo, the dark beyond, the turning light, the rim.
		draw_rect(r.grow(3.0 + 2.0 * flare), Color(SPIRIT, (0.14 + 0.3 * flare) * k * breathe))
		draw_rect(r.grow(1.5 + 2.0 * flare), Color(SPIRIT, (0.3 + 0.4 * flare) * k))
		draw_rect(r, Color(SPIRIT_DEEP, 0.95 * k))
		for j in 3:
			var y := -h * (0.25 + 0.25 * float(j)) + sin(fx.t * (2.0 + float(j)) + float(j) * 2.1) * 1.5
			var x := sin(fx.t * (3.0 + float(j)) + door.at.y + float(j)) * w * 0.25
			draw_rect(Rect2(x - 1.0, y - 1.0, 2.0, 2.0), Color(SPIRIT, 0.55 * k * breathe))
		draw_rect(r, Color(SPIRIT, 0.9 * k), false, 1.0)
		if flare > 0.0:
			draw_rect(r, Color(1, 1, 1, 0.7 * flare))
