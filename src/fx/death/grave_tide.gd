class_name GraveTideFx
extends FxTimeline
## Grave Tide (Death, Tier V; spec 5.8): a click, once a descent. The more the town has lost tonight, the bigger the tide.
## - Every unused body in town (Remains.all(): the unhidden remains, the oldest first), MOST at most, gets up at T_RISE as a
##   zombie (DeathParts.zombie: its own look, greyed, eyes alight) in this effect's own Visitors pack, and the body is used
##   up (Remains.take hides the corpse). Rules refuses a cast with no body anywhere in town ("needs": "any_body": "NO DEAD
##   THERE"), so nothing is spent.
## - The horde walks toward the click first (the Visitors `march` trait: by the streets, turning only on whoever comes
##   within Visitors.MARCH_SEEK on the way, MARCH_FOR at most), then hunts as any zombie does (the nearest within
##   DeathParts.ZOMBIE_SEEK; a citizen's first bite knocks them down, a second kills, frenzy).
## - Where the most of those bodies lie close -- the biggest group within CLUSTER_R of one of them (cluster(): a fixed sweep,
##   oldest first, a tie to the older; no luck) -- and there are CLUSTER_MIN or more, a giant of bones bursts up at their
##   middle like a fountain (Animal.Breed.BONE_GIANT, the Task 1 sheet). It walks to the click with the horde, then walks the
##   streets after the soldiers (prey "soldiers"): one within its reach it hunts; else every GIANT_LOOK it marches on, by the
##   streets, toward the nearest soldier out in the open anywhere in town; with none left it holds at the click. Its blow
##   (`bite` HEALTH_KNIGHT) fells any soldier at once; it takes GIANT_BLOWS blows and does not flinch; it claws down the walls
##   in its way (`wreck`), and never leaves the street to go at a building (`wreck_idle` false).
## - Death's undead within GIANT_AURA of the giant -- this tide's and any other power's (every Visitors pack in
##   Crowd.visitors, the Animal.UNDEAD breeds only: never a hellhound, demon or ghost) -- move AURA_SPEED times as fast:
##   Animal.speed_mul over their own, read as they first come within reach (every AURA_EVERY) and given back when they leave,
##   when the giant falls, and at the end.
## - At LIFE every one still up falls to ash (the pack cleared); cut short, or freed without its end, the same.
## Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead stand; the giant's rise frightens the street round it,
## and the horde's first bite is the town's outcry, as a hellhound's.

## The brief's numbers: the most that rise, how long they stand, the cluster (CLUSTER_MIN within CLUSTER_R), the giant's
## blows, its aura and the speed it lends.
const MOST := 30
const LIFE := 40.0
const CLUSTER_R := 4.0
const CLUSTER_MIN := 5
const GIANT_BLOWS := 12
const GIANT_AURA := 6.0
const AURA_SPEED := 1.2
## The ground breaks over T_RISE, and the dead stand (the power's impact); at the end they fall to ash over FADE.
const T_RISE := 1.2
const FADE := 0.6
## The march to the click takes this long at most; then they hunt from wherever they are.
const MARCH_FOR := 20.0
## The giant: its pace (ground units a second: a heavy walk, under a man's run), how far it looks for soldiers, its reach,
## a blow every GIANT_BITE_EVERY; its claws on a wall (GIANT_WRECK every GIANT_WRECK_EVERY, within GIANT_WRECK_REACH: a
## wide reach, its arms are long).
const GIANT_PACE := 1.1
const GIANT_SEEK := 10.0
const GIANT_BITE_R := 0.9
const GIANT_BITE_EVERY := 1.4
const GIANT_WRECK := 30.0
const GIANT_WRECK_EVERY := 1.5
const GIANT_WRECK_REACH := 1.0
## After its march it looks for the nearest soldier this often; the aura is read this often.
const GIANT_LOOK := 0.5
const AURA_EVERY := 0.1
## Its rise frightens the street within GIANT_FRIGHT_R; a heavy step sounds every STEP_EVERY while it walks.
const GIANT_FRIGHT_R := 4.0
const STEP_EVERY := 1.1
## The horde's first bite: the town's outcry (Hound Gate's and Raise the Dead's).
const BITE_FRIGHT_R := 2.0
const BITE_ALARM := 0.6
## Death's palette: bone white, ash grey, pale-white fire; grave green for glows only. No blood.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
const BONE_SPRAY := [Color("f2eedc"), Color("d8d2bf"), Color("b8b2a0"), Color(0.54, 0.54, 0.55, 0.0)]

## The tide's pack; how many rose; the giant (null when there is none, or none any more) and where it rose (INF: none);
## how often its claws struck a building.
var visitors: Visitors
var raised := 0
var giant: Animal
var giant_at := Vector2.INF
var wrecks := 0

## The bodies picked at the cast (the oldest first, MOST at most), raised at T_RISE.
var _rising: Array[Remains.Remain] = []
## Animal (untyped: another power may free it) -> its own speed_mul, while the aura quickens it.
var _sped := {}
var _aura_in := 0.0
var _look_in := 0.0
## Whether the giant is still on its first march, to the click.
var _to_click := true
var _bitten := false
var _step_in := 0.0
var _step_from := Vector2.INF
var _see: SeeThrough


## The biggest group of `points` within CLUSTER_R of one of them, as indices in order: a sweep over the points in order,
## each counting those within CLUSTER_R of it; the most wins, a tie to the earlier point. Empty when there are none.
## (The reading of "within 4 of each other", a ruling: within CLUSTER_R of one centre body -- the members may lie up to
## twice that apart -- not every pair within CLUSTER_R.)
static func cluster(points: Array[Vector2]) -> Array[int]:
	var best: Array[int] = []
	var r2 := CLUSTER_R * CLUSTER_R + 0.0001
	for i in points.size():
		var group: Array[int] = []
		for j in points.size():
			if points[j].distance_squared_to(points[i]) <= r2:
				group.append(j)
		if group.size() > best.size():
			best = group
	return best


func _build() -> void:
	duration = LIFE + FADE
	busy = T_RISE
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	visitors.wrecked.connect(_on_wreck)
	if rem != null:
		var all := rem.all()
		for i in mini(all.size(), MOST):
			_rising.append(all[i])
	if _rising.is_empty():
		duration = 0.1  # no body in town: Rules refuses such a cast before it comes here
		return
	var pts: Array[Vector2] = []
	for r in _rising:
		pts.append(r.pos)
	var group := cluster(pts)
	if group.size() >= CLUSTER_MIN:
		var sum := Vector2.ZERO
		for i in group:
			sum += pts[i]
		giant_at = sum / float(group.size())
	at(T_RISE, _rise)
	at(LIFE, _end_life)
	ctx.play(&"gravetide_rise", origin, 0.0)
	if not DominionParts.staged(self):
		return
	# The graves breathe: ash dust lifts off every body, and the ground glows cold under the giant's heap.
	for r in _rising:
		FxParts.smoke(self, Iso.ground_to_screen(r.pos), 6.0, 8.0, T_RISE, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0),
			Color(DeathParts.GRAVE_GREEN, 0.12), DUST)
	if giant_at != Vector2.INF:
		var light := FxParts.ground_light(self, giant_at, CLUSTER_R * 0.6, DeathParts.GRAVE_GREEN, 0.0)
		light.tween_param("intensity", 0.0, 0.8, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
		light.tween_param("intensity", 0.8, 0.0, 1.2, T_RISE)
		light.life = T_RISE + 1.3
	if ctx.shake != null:
		ctx.shake.add_trauma(0.25)


## The dead stand: each body as a zombie that walks to the click, then the giant where the most lay.
func _rise() -> void:
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	if rem == null:
		return
	var still := rem.all()  # a body another power took meanwhile is not raised twice
	var grid: WalkGrid = ctx.crowd._grid
	for r in _rising:
		if not still.has(r):
			continue
		var a := DeathParts.zombie(visitors, r, false)
		rem.take(r)
		if grid != null and not grid.walkable(a.ground_pos):
			# A body that fell indoors gets up at the nearest open ground.
			var w := grid.nearest_walkable(a.ground_pos, 4)
			if w != Vector2.INF:
				a.ground_pos = w
				a.sync_position()
		visitors.give(a, {"march": origin, "march_for": MARCH_FOR})
		raised += 1
		if DominionParts.staged(self):
			var sp := Iso.ground_to_screen(a.ground_pos)
			FxParts.debris(self, sp, 4, 5.0, Vector2(20, 60), BONE_CHIPS, Vector2(1.0, 2.0), true)
	_rising.clear()
	if giant_at != Vector2.INF:
		_raise_giant()


## The giant bursts up at the heap's middle like a fountain of bones.
func _raise_giant() -> void:
	var spot := giant_at
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	if grid != null and not grid.walkable(spot):
		var w := grid.nearest_walkable(spot, 6)
		if w != Vector2.INF:
			spot = w
	giant = visitors.summon(spot, Animal.Breed.BONE_GIANT, GIANT_BLOWS, GIANT_PACE / (Animal.DOG_SPEED * Animal.RUN), GIANT_SEEK,
		GIANT_BITE_R, GIANT_BITE_EVERY, false)
	visitors.give(giant, {"prey": "soldiers", "bite": Person.HEALTH_KNIGHT, "wreck": GIANT_WRECK, "wreck_every": GIANT_WRECK_EVERY,
		"wreck_reach": GIANT_WRECK_REACH, "wreck_idle": false, "march": origin, "march_for": MARCH_FOR})
	_to_click = true
	_look_in = GIANT_LOOK
	_step_in = STEP_EVERY
	_step_from = spot
	ctx.play(&"giant_step", spot, 0.0)
	if ctx.crowd != null:
		ctx.crowd.fright(spot, GIANT_FRIGHT_R, 0.8, 3.0, 12.0, 14.0, &"beast")
		ctx.crowd.threats.register(spot, 1.5, 0.8, 4.0, 10.0, 12.0, &"beast")
	if not DominionParts.staged(self):
		return
	_see = SeeThrough.new()
	var sp := Iso.ground_to_screen(spot)
	# A fountain: bone shards thrown high and falling back for a moment, a burst of chips, ash and a flash of pale fire.
	var spray := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.CHUNK, BONE_SPRAY, 90.0, 0.8,
		{"radius": 8.0, "speed": Vector2(10, 50), "alt": Vector2(0, 8), "alt_speed": Vector2(180, 340), "life": Vector2(0.9, 1.6),
			"size": Vector2(1.0, 2.5)})
	spray.gravity = 420.0
	spray.bounce = true
	spray.shadows = true
	FxParts.debris(self, sp, 24, 14.0, Vector2(30, 110), BONE_CHIPS, Vector2(1.5, 3.0), true)
	FxParts.smoke(self, sp, 16.0, 40.0, 0.6, Vector2(16, 40), Vector2(3, 6), Vector2(0.8, 1.5), Color(0, 0, 0, 0), DUST)
	var burst := FxParts.bloom(self, sp + Vector2(0, -40), 46.0, DeathParts.PALE_FIRE, 1.0, 0.9)
	burst.tween_param("intensity", 0.9, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.65
	if ctx.shake != null:
		ctx.shake.add_trauma(0.4)


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	_aura_in -= delta
	if _aura_in <= 0.0:
		_aura_in = AURA_EVERY
		_aura()
	if giant == null or not is_instance_valid(giant):
		return
	_look_in -= delta
	if _look_in <= 0.0:
		_look_in = GIANT_LOOK
		_walk_on()
	_step_in -= delta
	if _step_in <= 0.0:
		_step_in = STEP_EVERY
		if giant.ground_pos.distance_to(_step_from) > 0.3:
			ctx.play(&"giant_step", giant.ground_pos, -4.0)
		_step_from = giant.ground_pos
	if _see != null and ctx.env != null:
		var sp := Iso.ground_to_screen(giant.ground_pos)
		_see.step(ctx.env.near(giant.ground_pos, 8.0), Rect2(sp.x - 28.0, sp.y - 84.0, 56.0, 84.0), sp.y, delta)


## After its march to the click: with a soldier in reach the Visitors hunt him; else it marches on toward the nearest
## soldier out in the open anywhere in town (the point renewed every GIANT_LOOK, as he moves); with none, back to the click.
func _walk_on() -> void:
	if _to_click:
		if visitors.marching(giant):
			return
		_to_click = false
	if giant.target != null and is_instance_valid(giant.target):
		return  # one within its reach: the hunt has him
	var to := origin
	var soldier := _nearest_soldier(giant.ground_pos)
	if soldier != null:
		to = soldier.ground_pos
	elif giant.ground_pos.distance_to(origin) <= Visitors.MARCH_NEAR:
		return  # none left: it holds at the click
	visitors.give(giant, {"march": to, "march_for": LIFE})


## The nearest living soldier out in the open anywhere in town, or null.
func _nearest_soldier(at_ground: Vector2) -> Person:
	if ctx.crowd == null:
		return null
	var best: Person = null
	var best_d := INF
	var soldiers: Array = ctx.crowd.soldiers  # untyped, so each is checked before a typed use (one who left the town is freed)
	for e in soldiers:
		if not is_instance_valid(e):
			continue
		var p := e as Person
		if p == null or not p.is_alive() or p.inside:
			continue
		var d := p.ground_pos.distance_squared_to(at_ground)
		if d < best_d:
			best_d = d
			best = p
	return best


## Death's undead within GIANT_AURA of the giant, in every pack in town, run AURA_SPEED times their own pace; one that
## leaves the aura (or every one, the giant fallen) has its own back.
func _aura() -> void:
	var has_giant := giant != null and is_instance_valid(giant) and giant.is_alive()
	if not has_giant:
		_unspeed_all()
		return
	var g := giant.ground_pos
	var r2 := GIANT_AURA * GIANT_AURA
	var packs: Array = ctx.crowd.visitors if ctx.crowd != null else [visitors]
	var now := {}
	for pack in packs:
		for a in (pack as Visitors).living():
			if a == giant or not (a.breed in Animal.UNDEAD) or a.ground_pos.distance_squared_to(g) > r2:
				continue
			now[a] = true
			if not _sped.has(a):
				_sped[a] = a.speed_mul
				a.speed_mul *= AURA_SPEED
	for a in _sped.keys():
		if now.has(a):
			continue
		if is_instance_valid(a):
			(a as Animal).speed_mul = float(_sped[a])
		_sped.erase(a)


## Every quickened one has its own pace back (skipping any another power freed).
func _unspeed_all() -> void:
	for a in _sped.keys():
		if is_instance_valid(a):
			(a as Animal).speed_mul = float(_sped[a])
	_sped.clear()


## The horde's first bite is the town's outcry.
func _on_bite(_a: Animal, victim: Person, first: bool) -> void:
	if first and not _bitten and ctx.crowd != null and is_instance_valid(victim):
		_bitten = true
		ctx.crowd.fright(victim.ground_pos, BITE_FRIGHT_R, 0.6, 3.0, 6.0, 8.0, &"bite", true)
		ctx.crowd.add_alarm(BITE_ALARM)


## Cut down: it falls to bones and ash (the Visitors free its node). The giant gone, the aura goes with it.
func _on_cut_down(a: Animal, at_ground: Vector2) -> void:
	if _sped.has(a):
		_sped.erase(a)  # it is freed right after: nothing to give back
	if a == giant:
		giant = null
		_unspeed_all()
		ctx.play(&"gravetide_rise", at_ground, -6.0)
		_release_see()
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at_ground)
	var big := a.breed == Animal.Breed.BONE_GIANT
	FxParts.debris(self, sp, 18 if big else 6, 12.0 if big else 5.0, Vector2(30, 90), BONE_CHIPS, Vector2(1.0, 2.5), true)
	FxParts.smoke(self, sp, 14.0 if big else 7.0, 36.0, 0.25, Vector2(14, 36), Vector2(2, 5), Vector2(0.6, 1.1), Color(0, 0, 0, 0), DUST)


## The giant's claws on a wall: dust and splinters.
func _on_wreck(a: Animal, s: Structure) -> void:
	wrecks += 1
	ctx.play(&"jg_crumble", a.ground_pos, -10.0)
	if not DominionParts.staged(self):
		return
	var hit := a.ground_pos.clamp(s.footprint.position, s.footprint.end)
	var sp := Iso.ground_to_screen(hit) + Vector2(0, -12)
	FxParts.debris(self, sp, 6, 6.0, Vector2(30, 110), FxParts.ROCK, Vector2(1.5, 2.5), true)
	FxParts.smoke(self, sp, 8.0, 30.0, 0.2, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)


## LIFE: every one still up falls to ash.
func _end_life() -> void:
	if visitors == null:
		return
	if DominionParts.staged(self):
		for a in visitors.living():
			FxParts.smoke(self, Iso.ground_to_screen(a.ground_pos), 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4),
				Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)
	_clear_all(false)


func _clear_all(deferred: bool) -> void:
	_unspeed_all()
	giant = null
	_rising.clear()
	if visitors != null:
		visitors.clear(deferred)
	_release_see()


func _release_see() -> void:
	if _see != null:
		_see.release()
	_see = null


## Over, or cut short: the tide gone.
func _finish() -> void:
	_clear_all(false)
	super()


## Freed without _finish (a mission torn down mid-tide): the same, the pack only queued for freeing (its parents may be
## mid-teardown).
func _exit_tree() -> void:
	_clear_all(true)
	super()
