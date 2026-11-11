class_name TheFarGateFx
extends FxTimeline
## The Far Gate (Passage, Tier V): a door of stars opens on the ground where the click lands -- or where an open passage
## (EnemyField.through) carries it -- and the town walks out of the night through it. A tall arch of night sky stands
## there; it takes T_OPEN to open, and then it stands open SPAN. At the moment it opens, the MAX_PEOPLE living people
## nearest it within RADIUS -- out in the open (not inside a building) and not fighting -- are drawn to it: calm, as if
## of their own mind (a compulsion no danger breaks), each walks to it by the streets at its own pace. A soldier
## resists: he walks at SOLDIER_PACE of his pace, so only a soldier near the door makes it before it shuts. Whoever
## comes within DOOR_R of the door steps through and is gone for the night: counted among the dead (kind gone), with no
## body, no cry and nothing for the town to find -- the figure fades into starlight at the threshold. The town's dogs
## and cats within RADIUS go to it too (by the streets) and through it, and the loose goods there -- the barrels,
## crates, carts, logs and piles (Decor, GOODS) -- slide over the ground to it at GOODS_PACE and are gone into it.
## When it shuts, whoever has not reached it stops where they are, dazed DAZE, and goes on with their own business
## (a soldier back to his post); an animal still on its way goes back to its day. There is no luck in it: who is drawn
## and who makes it follow from distance and pace alone. Quiet, but for the book entry's "alarm": the town sees the
## door. Once in a descent (the book's cooldown). The door folds to a point over CLOSE after it shuts.

const RADIUS := 10.0
const MAX_PEOPLE := 40
const SPAN := 15.0
const T_OPEN := 1.5
const DOOR_R := 0.6
const SOLDIER_PACE := 0.5
## Who did not make it stands dazed this long when the door shuts.
const DAZE := 1.0
## How fast the goods slide to the door, ground units a second.
const GOODS_PACE := 1.2
## The decor that is loose goods the door draws in.
const GOODS: Array[Decor.Kind] = [Decor.Kind.BARREL, Decor.Kind.CRATES, Decor.Kind.CART, Decor.Kind.LOGS, Decor.Kind.PILE]
## One drawn who has lost the way to the door (no path left short of it) looks for it again this often.
const REAIM := 1.0
## After it shuts the door folds to a point over CLOSE.
const CLOSE := 0.8
## The door, on screen: its height and width (px) and the star glyph over the heads of the drawn.
const DOOR_H := 70.0
const DOOR_W := 34.0
const STAR_GLYPH: Array[int] = [0b00100, 0b10101, 0b01110, 0b10101, 0b00100]
const MARK := Color(0.78, 0.84, 1.0)
const RIM := Color(0.72, 0.8, 1.0)
const STAR := Color(0.92, 0.95, 1.0)
const SKY_TOP := Color(0.04, 0.03, 0.16)
const SKY_LOW := Color(0.3, 0.18, 0.56)
const VIOLET := Color(0.55, 0.42, 1.0)
const STAR_LIFE := [Color("ffffff"), Color("e4eaff"), Color("aab6ff"), Color("7a6cf0"), Color(0.3, 0.22, 0.7, 0.4)]

## Where the door stands; whether it is open; the people it drew (and has not yet taken or let go), the animals and
## goods on their way; and what went through.
var door := Vector2.ZERO
var opened := false
var shut := false
var drawn: Array[Person] = []
var animals: Array[Animal] = []
var goods: Array[Decor] = []
var gone_people: Array[Person] = []
var gone_animals := 0
var gone_goods := 0
## Those still drawn when it shut: let go, dazed.
var released: Array[Person] = []

## Soldier -> the slow status he had before the door's (null: none).
var _paced := {}
var _reaim := {}
var _door_node: Door
var _glow: QuadFx
var _halo: QuadFx


## When the door shuts.
func shut_at() -> float:
	return T_OPEN + SPAN


## Whom a door at `at` draws when it opens: the living people within RADIUS of it who are out in the open and not
## fighting, the MAX_PEOPLE nearest (ties by where they stand, so the choice never rests on the order of the list).
static func called(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, RADIUS):
		var p := e as Person
		if p == null or not p.is_alive() or p.inside or p.mind == Person.Mind.FIGHT:
			continue
		out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if da != db:
			return da < db
		if a.ground_pos.x != b.ground_pos.x:
			return a.ground_pos.x < b.ground_pos.x
		return a.ground_pos.y < b.ground_pos.y)
	if out.size() > MAX_PEOPLE:
		out.resize(MAX_PEOPLE)
	return out


## The goods a door at `at` draws in: the loose decor pieces (GOODS) within RADIUS.
static func goods_at(env: EnvironmentField, at: Vector2) -> Array[Decor]:
	var out: Array[Decor] = []
	if env == null:
		return out
	for d in env.decor():
		if is_instance_valid(d) and not d.sprite_only and d.kind in GOODS and d.at.distance_to(at) <= RADIUS:
			out.append(d)
	return out


func _build() -> void:
	door = ctx.field.through(origin)
	var grid := _grid()
	if grid != null and not grid.walkable(door):
		var w := grid.nearest_walkable(door, 4)
		if w != Vector2.INF:
			door = w
	duration = shut_at() + CLOSE + 0.2
	busy = T_OPEN
	at(T_OPEN, _open)
	at(shut_at(), _shut)
	ctx.play(&"q_fargate", origin, 0.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(door)
	_door_node = Door.new()
	_door_node.fx = self
	_door_node.position = sp
	_door_node.seed_value = int(ctx.rng.randi() % 100000)
	track(_door_node, ctx.world if ctx.world != null else ctx.overhead)
	var path := StarPath.new()
	path.fx = self
	path.position = door
	path.z_index = 2
	path.seed_value = int(ctx.rng.randi() % 100000)
	track(path, ctx.ground)
	_glow = FxParts.ground_light(self, door, 2.2, VIOLET, 0.0)
	_glow.tween_param("intensity", 0.0, 0.4, T_OPEN, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	_halo = FxParts.bloom(self, sp + Vector2(0, -DOOR_H * 0.5), 44.0, VIOLET, 0.0, 1.5)
	_halo.tween_param("intensity", 0.0, 0.3, T_OPEN, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	# Starlight gathers where the door will stand: motes drawn up off the paving into a line of light.
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, STAR_LIFE, 18.0, T_OPEN,
		{"radius": 26.0, "speed": Vector2(2, 8), "alt": Vector2(0, 30), "alt_speed": Vector2(20, 60), "life": Vector2(0.6, 1.2),
			"size": Vector2(1, 1)})
	motes.gravity = -10.0
	motes.drag = 1.0


## The walk grid the drawn keep to: the town's, by way of anyone in it.
func _grid() -> WalkGrid:
	if ctx.crowd != null and ctx.crowd._grid != null:
		return ctx.crowd._grid
	for e in ctx.field.alive():
		var p := e as Person
		if p != null and p.grid != null:
			return p.grid
	return null


## 0..1 how far open the door stands now (opening over T_OPEN, folding over CLOSE after it shuts).
func openness(now: float) -> float:
	if now < shut_at():
		return clampf(now / T_OPEN, 0.0, 1.0)
	return 1.0 - clampf((now - shut_at()) / CLOSE, 0.0, 1.0)


## The door is open: the nearest are drawn to it, the animals turn to it, and the goods begin to slide.
func _open() -> void:
	opened = true
	var hold := SPAN + 1.0  # it lets go itself at the shut (_shut); this only outlasts it
	for p in called(ctx.field, door):
		if p.soldier:
			# He resists: SOLDIER_PACE of his pace, on top of whatever slows him already.
			_paced[p] = p.statuses.get(&"slow", null)
			p.statuses[&"slow"] = float(p.statuses.get(&"slow", 1.0)) * SOLDIER_PACE
		if p.compel(door, hold, Person.WILL_ABSOLUTE, MARK, false, &"", STAR_GLYPH):
			drawn.append(p)
		else:
			_unpace(p)
	if ctx.crowd != null and ctx.crowd.animals != null:
		for a in ctx.crowd.animals.in_radius(door, RADIUS):
			if a.cast(Animal.Spell.GATHER, hold, null, door):
				animals.append(a)
	goods = goods_at(ctx.env, door)
	ctx.play(&"q_congregation", door, -3.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(door) + Vector2(0, -DOOR_H * 0.5)
	var flare := FxParts.bloom(self, sp, 60.0, STAR, 0.7, 1.4)
	flare.tween_param("intensity", 0.9, 0.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	flare.life = 0.82
	var ring := FxParts.refract_ring(self, door, 4.0, Color(0.8, 0.85, 1.0))
	ring.tween_param("progress", 0.05, 1.0, 0.9, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ring.life = 0.92
	# The reach of the call, marked once on the ground as it goes out.
	var wave := FxParts.rings(self, door, RADIUS, Color(RIM, 0.5), 2, 24.0)
	wave.set_param("scan", 0.0)
	wave.tween_param("reveal", 0.0, 1.0, 1.0, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	wave.tween_param("alpha", 1.0, 0.0, 0.6, 1.0)
	wave.life = 1.65
	FxParts.sparks(self, ctx.overhead, sp, 20, STAR_LIFE, Vector2(30, 120), Vector2(10, 80))


## A soldier's own pace back.
func _unpace(p: Person) -> void:
	if not _paced.has(p):
		return
	var was = _paced[p]
	_paced.erase(p)
	if not is_instance_valid(p):
		return
	if was == null:
		p.statuses.erase(&"slow")
	else:
		p.statuses[&"slow"] = was
	p.walk_speed = p._mind_speed()


func _fx_process(delta: float) -> void:
	if not opened or shut:
		return
	_step_people(delta)
	_step_animals()
	_step_goods(delta)


## The drawn walk on (Person.compel); whoever reaches the door is gone through it. One the god's hand has left (a
## blow, a death) is drawn no more.
func _step_people(delta: float) -> void:
	var k := drawn.size() - 1
	while k >= 0:
		var p := drawn[k]
		k -= 1
		if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.COMPELLED:
			drawn.erase(p)
			_unpace(p)
			_reaim.erase(p)
			continue
		if p.ground_pos.distance_to(door) <= DOOR_R:
			drawn.erase(p)
			_paced.erase(p)
			_reaim.erase(p)
			var at_ground := p.ground_pos
			if ctx.field.kill(p, &"gone", door):
				gone_people.append(p)
				_through(at_ground)
			continue
		if not p.has_goal():
			# Its path ran out short of the door: it looks for the way again, every REAIM.
			var wait_left: float = _reaim.get(p, 0.0) - delta
			if wait_left <= 0.0:
				p.set_goal(door)
				wait_left = REAIM
			_reaim[p] = wait_left


## The animals walk to the door by the streets (AnimalPack steps them); one at the door goes through.
func _step_animals() -> void:
	var k := animals.size() - 1
	while k >= 0:
		var a := animals[k]
		k -= 1
		if not is_instance_valid(a) or not a.is_alive() or a.state != Animal.State.GATHER:
			animals.erase(a)
			continue
		if a.ground_pos.distance_to(door) <= DOOR_R:
			animals.erase(a)
			var at_ground := a.ground_pos
			if ctx.crowd != null and ctx.crowd.animals != null:
				ctx.crowd.animals.take(a)
			gone_animals += 1
			_through(at_ground)


## The goods slide over the ground to the door, straight, and are gone into it.
func _step_goods(delta: float) -> void:
	var k := goods.size() - 1
	while k >= 0:
		var d := goods[k]
		k -= 1
		if not is_instance_valid(d):
			goods.erase(d)
			continue
		var to := door - d.at
		var step := GOODS_PACE * delta
		if to.length() <= DOOR_R + step:
			goods.erase(d)
			var at_ground := d.at
			ctx.env.remove_decor(d)
			gone_goods += 1
			_through(at_ground)
			continue
		d.shift(to.normalized() * step)


## Something stepped through: the door flares and the figure's starlight scatters at the threshold.
func _through(at_ground: Vector2) -> void:
	ctx.play(&"q_mirror_hit", door, -4.0)
	if not DominionParts.staged(self):
		return
	if _door_node != null and is_instance_valid(_door_node):
		_door_node.flare = 1.0
	var sp := Iso.ground_to_screen(at_ground) + Vector2(0, -8)
	var p := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, STAR_LIFE)
	p.gravity = -40.0
	p.drag = 1.2
	p.burst(10, {"radius": 5.0, "speed": Vector2(4, 18), "alt": Vector2(0, 14), "alt_speed": Vector2(10, 40),
		"life": Vector2(0.5, 1.0), "size": Vector2(1, 1)})


## The door shuts: whoever is still on the way stops, dazed, and goes back to their own business.
func _shut() -> void:
	_let_go()
	ctx.play(&"q_mirror", door, -2.0)
	if not DominionParts.staged(self):
		return
	if is_instance_valid(_glow):
		_glow.tween_param("intensity", 0.4, 0.0, CLOSE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	if is_instance_valid(_halo):
		_halo.tween_param("intensity", 0.3, 0.0, CLOSE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	var sp := Iso.ground_to_screen(door) + Vector2(0, -DOOR_H * 0.45)
	at(shut_at() + CLOSE, func():
		var pop := FxParts.bloom(self, sp, 40.0, STAR, 1.0, 1.0)
		pop.tween_param("intensity", 1.0, 0.0, 0.25, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		pop.life = 0.27
		FxParts.sparks(self, ctx.overhead, sp, 16, STAR_LIFE, Vector2(20, 90), Vector2(10, 60)))


## Lets go of everyone and everything still drawn (at the shut, or when the effect is cut short).
func _let_go() -> void:
	if shut:
		return
	shut = true
	for p in drawn:
		_unpace(p)
		if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.COMPELLED:
			continue
		p.release_compulsion()
		# Dazed: rooted where it stands (nothing thought, nothing walked), looking about.
		p.stun(DAZE)
		p.hesitate(DAZE)
		released.append(p)
	drawn.clear()
	for p in _paced.keys():
		_unpace(p)
	_reaim.clear()
	for a in animals:
		if is_instance_valid(a) and a.is_alive() and a.state == Animal.State.GATHER:
			a.release()
			a.wait = DAZE
	animals.clear()
	goods.clear()


## Over, or cut short (end_now()): nobody is left drawn to a door that is not there.
func _finish() -> void:
	if opened:
		_let_go()
	super()


## The door of stars: a tall arch of night standing on the ground point, drawn in the world layer so the town sorts
## round it. Inside it another sky -- deep blue going violet at the threshold -- with stars drifting slowly up; a rim
## of starlight round it. It opens out of a thread of light over T_OPEN (tall first, then wide), flares as something
## goes through, and folds to a point over CLOSE when it shuts.
class Door extends Node2D:
	const STARS := 46
	var fx: TheFarGateFx
	var flare := 0.0
	var seed_value := 0

	func _process(delta: float) -> void:
		flare = maxf(flare - delta * 2.5, 0.0)
		queue_redraw()

	static func _hash(i: int, salt: int) -> float:
		var h := (i * 73856093) ^ (salt * 19349663)
		h = (h ^ (h >> 13)) * 1274126177
		return float(absi(h) % 10007) / 10007.0

	## The arch's outline at width `w`, height `h`, from its left foot round to its right foot.
	static func outline(w: float, h: float) -> PackedVector2Array:
		var r := w * 0.5
		var spring := -(h - r)
		var pts := PackedVector2Array([Vector2(-r, 0.0), Vector2(-r, spring)])
		for i in range(1, 16):
			var a := PI + PI * float(i) / 16.0
			pts.append(Vector2(cos(a) * r, spring + sin(a) * r))
		pts.append(Vector2(r, spring))
		pts.append(Vector2(r, 0.0))
		return pts

	static func inside(q: Vector2, w: float, h: float) -> bool:
		var r := w * 0.5
		if q.y > 0.0 or absf(q.x) > r:
			return false
		var spring := -(h - r)
		return q.y >= spring or q.distance_to(Vector2(0.0, spring)) <= r

	func _draw() -> void:
		var now := fx.t
		var open := fx.openness(now)
		if open <= 0.0:
			return
		# Opening, it rises as a thread of light first, then widens; shutting, it folds.
		var folding := now >= fx.shut_at()
		var tall := DOOR_H * (clampf(open / 0.45, 0.0, 1.0) if not folding else 1.0)
		var wide := DOOR_W * (clampf((open - 0.3) / 0.7, 0.04, 1.0) if not folding else 1.0)
		tall = maxf(tall, wide + 2.0)  # never shorter than its own round top
		if folding:
			# Folding to a point a little above the ground, the whole arch shrinking into it.
			var s := open * open
			draw_set_transform(Vector2(0, -DOOR_H * 0.45 * (1.0 - s)), 0.0, Vector2(s, s))
		var shape := outline(wide, tall)
		var glow := 1.0 + flare * 0.6
		# A soft halo of starlight round it.
		draw_colored_polygon(outline(wide + 10.0, tall + 6.0), Color(RIM, 0.10 * glow))
		draw_colored_polygon(outline(wide + 5.0, tall + 3.0), Color(RIM, 0.16 * glow))
		# The other sky: deep at the top, violet at the threshold.
		var cols := PackedColorArray()
		for q in shape:
			var k := clampf(-q.y / tall, 0.0, 1.0)
			cols.append(SKY_LOW.lerp(SKY_TOP, pow(k, 0.7)))
		draw_polygon(shape, cols)
		# Its stars, drifting slowly up and across, twinkling; only those within the arch.
		for i in STARS:
			var x := (_hash(i, seed_value) - 0.5) * DOOR_W
			var y := -fposmod(_hash(i, seed_value + 1) * DOOR_H + now * (3.0 + 5.0 * _hash(i, seed_value + 2)), DOOR_H)
			x += sin(now * 0.4 + float(i)) * 2.0
			var q := Vector2(x * wide / DOOR_W, y * tall / DOOR_H)
			if not inside(q, wide - 2.0, tall - 1.0):
				continue
			var tw := 0.55 + 0.45 * sin(now * (1.5 + _hash(i, seed_value + 3) * 3.0) + float(i) * 1.7)
			var big := _hash(i, seed_value + 4) > 0.85
			var c := Color(STAR, tw)
			draw_rect(Rect2(q.round(), Vector2.ONE), c)
			if big:
				draw_rect(Rect2(q.round() + Vector2(-1, 0), Vector2(3, 1)), Color(STAR, tw * 0.5))
				draw_rect(Rect2(q.round() + Vector2(0, -1), Vector2(1, 3)), Color(STAR, tw * 0.5))
		# The threshold: a line of light on the ground, brighter as something goes through.
		draw_line(Vector2(-wide * 0.5, 0.0), Vector2(wide * 0.5, 0.0), Color(STAR, minf(0.6 * glow, 1.0)), 2.0)
		# The rim: a dark line to hold it off the paving, a bright edge of starlight, a fainter one inside it.
		var pulse := 0.85 + 0.15 * sin(now * 3.0)
		draw_polyline(outline(wide + 3.0, tall + 1.5), Color(0.06, 0.05, 0.16, 0.85), 1.0)
		draw_polyline(shape, Color(RIM, minf(0.95 * pulse * glow, 1.0)), 2.0)
		draw_polyline(outline(wide - 4.0, tall - 2.0), Color(STAR, 0.35 * pulse), 1.0)
		draw_set_transform(Vector2.ZERO)


## The starlit way on the ground: a faint ring of stars at RADIUS, threads of star-dust running in from it to the
## door, and a bright step of light before the door. Drawn in ground units on the ground layer, under everyone.
class StarPath extends Node2D:
	const THREADS := 12
	const MOTES := 5
	var fx: TheFarGateFx
	var seed_value := 0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		var a := fx.openness(now)
		if a <= 0.0:
			return
		var spread := clampf((now - T_OPEN * 0.5) / (T_OPEN * 1.5), 0.0, 1.0)
		var rim := lerpf(1.0, RADIUS, spread)
		# The ring at the rim, dotted with stars.
		draw_arc(Vector2.ZERO, rim, 0.0, TAU, 96, Color(RIM, 0.14 * a), 0.06)
		for i in 48:
			var ang := TAU * float(i) / 48.0 + now * 0.03
			var tw := 0.4 + 0.4 * sin(now * 2.0 + float(i) * 2.3)
			draw_circle(Vector2.from_angle(ang) * rim, 0.05, Color(STAR, tw * a))
		# Threads in from the rim, with motes running along them to the door.
		for k in THREADS:
			var ang := TAU * (float(k) + 0.5 * float(seed_value % 7) / 7.0) / float(THREADS)
			var dir := Vector2.from_angle(ang)
			draw_line(dir * 0.6, dir * rim, Color(VIOLET, 0.07 * a), 0.35)
			for m in MOTES:
				var along := 1.0 - fposmod(now * 0.18 + float(m) / float(MOTES) + float(k) * 0.37, 1.0)
				var q := dir * lerpf(0.6, rim, along) + dir.orthogonal() * sin(now * 2.0 + float(m + k)) * 0.08
				draw_circle(q, 0.06, Color(STAR, 0.7 * a * (1.0 - along * 0.5)))
		# The step before the door: a soft pool of light, toward the viewer.
		draw_circle(Vector2(0.35, 0.35), 0.7, Color(VIOLET, 0.12 * a))
		draw_circle(Vector2(0.2, 0.2), 0.4, Color(STAR, 0.14 * a))
