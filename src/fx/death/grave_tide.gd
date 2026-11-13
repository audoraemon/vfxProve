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
##   oldest first, a tie to the older; no luck) -- and there are CLUSTER_MIN or more, a giant of bones (Animal.Breed.BONE_GIANT,
##   the Task 1 sheet) assembles at their middle (ruling R12): from T_RISE its BONES bones fly in one by one, from those
##   bodies, over ASSEMBLE; at T_RISE + ASSEMBLE it stands and lands with a slam (_slam: soldiers out in the open within SLAM_R
##   die, in instance-id order, frenzy; the rest within it are knocked back and the street frightened; a shockwave, cracks,
##   dust), and it slams the ground again every SLAM_EVERY while it stands. It walks to the click with the horde, then walks the
##   streets after the soldiers (prey "soldiers"): one within its reach it hunts; else every GIANT_LOOK it marches on, by the
##   streets, toward the nearest soldier out in the open anywhere in town; with none left it holds at the click. Its blow
##   (`bite` HEALTH_KNIGHT) fells any soldier at once; it takes GIANT_BLOWS blows and does not flinch; it claws down the walls
##   in its way (`wreck`), and never leaves the street to go at a building (`wreck_idle` false).
## - Death's undead within GIANT_AURA of the giant -- this tide's and any other power's (every Visitors pack in
##   Crowd.visitors, the Animal.UNDEAD breeds only: never a hellhound, demon or ghost) -- move AURA_SPEED times as fast:
##   Animal.speed_mul scaled by AURA_SPEED as they first come within reach (every AURA_EVERY) and by 1 / AURA_SPEED when they
##   leave, when the giant falls, and at the end -- a ratio, once each way, so another scale laid on meanwhile (Walking Corpse's
##   attack pace, R18) survives it (R27); one whose pace nothing else touched gets exactly its own back.
## - At LIFE every zombie still up falls to ash; the giant stands on to GIANT_LIFE after its landing, then falls to ash too
##   (the pack cleared); cut short, or freed without its end, all of them at once (a tide cut short mid-assembly: no giant).
## Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead stand; the giant's slams frighten the street round it,
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
## A heavy step sounds every STEP_EVERY while it walks.
const STEP_EVERY := 1.1
## The horde's first bite: the town's outcry (Hound Gate's and Raise the Dead's).
const BITE_FRIGHT_R := 2.0
const BITE_ALARM := 0.6
## Ruling R12: the giant stands GIANT_LIFE from its landing (the zombies keep LIFE). It assembles over ASSEMBLE from T_RISE:
## BONES bones fly one by one, from the cluster's remains, into its spot. Its landing is the first slam, and it slams the
## ground every SLAM_EVERY while it stands: soldiers out in the open within SLAM_R die (frenzy, a body), everyone else
## within it is knocked back SLAM_KNOCK and the street within SLAM_R + 1 frightened.
const GIANT_LIFE := 60.0
const ASSEMBLE := 1.2
const BONES := 18
const SLAM_EVERY := 4.0
const SLAM_R := 3.0
const SLAM_KNOCK := 5.5
## The slam's fright (R12: Crowd.fright(at, SLAM_R + 1.0, 0.8, 3.0, 8.0, 12.0, &"beast")) and its blow (giant_step, +4 dB).
const SLAM_FRIGHT := [0.8, 3.0, 8.0, 12.0]
const SLAM_DB := 4.0
## The look of it (staged only): each bone flies BONE_FLY, the last landing at T_RISE + ASSEMBLE, in an arc BONE_ARC px high,
## and settles into the giant's frame, BONE_STACK px tall; the slam's ring runs out to SLAM_R over SLAM_RING_FOR, its
## SLAM_CRACKS cracks lie SLAM_CRACK_FOR, and its dust is SLAM_DUST puffs at most.
const BONE_FLY := 0.25
const BONE_ARC := 26.0
const BONE_STACK := 64.0
const SLAM_RING_FOR := 0.35
const SLAM_CRACKS := 7
const SLAM_CRACK_FOR := 3.0
const SLAM_DUST := 16
## Death's palette: bone white, ash grey, pale-white fire; grave green for glows only. No blood.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
## A slam's cracks (dark, a hairline about PX * 1.5 wide: PX is about one screen pixel in ground units) and its ring.
const CRACK := Color(0.1, 0.09, 0.08, 0.8)
const PX := 0.03

## The tide's pack; how many rose; the giant (null when there is none, or none any more) and where it rose (INF: none);
## how often its claws struck a building.
var visitors: Visitors
var raised := 0
var giant: Animal
var giant_at := Vector2.INF
var wrecks := 0
## The assembly: how many bones have flown in (on the effect clock, staged or not); how often the giant has slammed the
## ground; when it landed (-1: not yet).
var bones_in := 0
var slams := 0
var landed_at := -1.0

## The bodies picked at the cast (the oldest first, MOST at most), raised at T_RISE.
var _rising: Array[Remains.Remain] = []
## Animal (untyped: another power may free it) -> [its speed_mul before the aura, its speed_mul quickened], while the aura quickens it.
var _sped := {}
var _aura_in := 0.0
var _look_in := 0.0
## Whether the giant is still on its first march, to the click.
var _to_click := true
var _bitten := false
var _step_in := 0.0
var _step_from := Vector2.INF
var _see: SeeThrough
## Where the cluster's bodies lay (the bones fly from them), the giant's spot (walkable), the next slam on the effect clock,
## and the flying bones (staged only).
var _group: Array[Vector2] = []
var _spot := Vector2.INF
var _next_slam := INF
var _bones: Bones


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
			_group.append(pts[i])
		giant_at = sum / float(group.size())
		# The giant outlives the horde: the tide lasts to its end (cut down sooner, _giant_gone() brings the end back).
		duration = maxf(LIFE, T_RISE + ASSEMBLE + GIANT_LIFE) + FADE
		at(T_RISE + ASSEMBLE, _land)
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
		light.tween_param("intensity", 0.8, 0.0, 1.2, T_RISE + ASSEMBLE)
		light.life = T_RISE + ASSEMBLE + 1.3
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
		_assemble()


## The giant's spot (the heap's middle, or the nearest open ground to it); from T_RISE its bones fly in from the bodies.
func _assemble() -> void:
	_spot = giant_at
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	if grid != null and not grid.walkable(_spot):
		var w := grid.nearest_walkable(_spot, 6)
		if w != Vector2.INF:
			_spot = w
	if not DominionParts.staged(self):
		return
	_bones = Bones.new()
	_bones.fx = self
	for g in _group:
		_bones.from.append(Iso.ground_to_screen(g))
	_bones.to = Iso.ground_to_screen(_spot)
	track(_bones, stand_layer())


## The time bone `i` (0 first) lands in the giant's frame: BONE_FLY after it leaves, the last at T_RISE + ASSEMBLE.
static func bone_lands(i: int) -> float:
	return T_RISE + BONE_FLY + float(i) * (ASSEMBLE - BONE_FLY) / float(BONES - 1)


## T_RISE + ASSEMBLE: every bone in, the giant stands, and its landing is the first slam.
func _land() -> void:
	if is_instance_valid(_bones):
		_bones.queue_free()
	_bones = null
	if _spot == Vector2.INF:
		return  # the dead never rose (no ledger): no giant
	bones_in = BONES
	_raise_giant()
	landed_at = t
	_next_slam = landed_at + SLAM_EVERY
	at(landed_at + GIANT_LIFE, _end_giant)
	_slam(giant.ground_pos)


## The giant stands where its bones came together.
func _raise_giant() -> void:
	var spot := _spot
	giant = visitors.summon(spot, Animal.Breed.BONE_GIANT, GIANT_BLOWS, GIANT_PACE / (Animal.DOG_SPEED * Animal.RUN), GIANT_SEEK,
		GIANT_BITE_R, GIANT_BITE_EVERY, false)
	visitors.give(giant, {"prey": "soldiers", "bite": Person.HEALTH_KNIGHT, "wreck": GIANT_WRECK, "wreck_every": GIANT_WRECK_EVERY,
		"wreck_reach": GIANT_WRECK_REACH, "wreck_idle": false, "march": origin, "march_for": MARCH_FOR})
	_to_click = true
	_look_in = GIANT_LOOK
	_step_in = STEP_EVERY
	_step_from = spot
	if not DominionParts.staged(self):
		return
	_see = SeeThrough.new()
	# The bones lock together in a flash of pale fire.
	var burst := FxParts.bloom(self, Iso.ground_to_screen(spot) + Vector2(0, -40), 46.0, DeathParts.PALE_FIRE, 1.0, 0.9)
	burst.tween_param("intensity", 0.9, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.65


## The giant slams the ground at `at_ground` (ruling R12): every soldier out in the open within SLAM_R dies (frenzy: a body
## lies there), in instance-id order -- no luck in who dies; everyone else within it is knocked back, and the street within
## SLAM_R + 1 frightened. Staged: a shockwave ring out to SLAM_R, cracks, a burst of dust, the ground shaking.
func _slam(at_ground: Vector2) -> void:
	slams += 1
	ctx.play(&"giant_step", at_ground, SLAM_DB)
	var doomed: Array[Person] = []
	for e in ctx.field.in_radius(at_ground, SLAM_R):
		var p := e as Person
		if p != null and p.soldier and not p.inside:
			doomed.append(p)
	doomed.sort_custom(func(a: Person, b: Person) -> bool: return a.get_instance_id() < b.get_instance_id())
	for p in doomed:
		ctx.field.kill(p, &"frenzy", at_ground)
	ctx.field.knock_from(at_ground, 0.0, SLAM_R, SLAM_KNOCK)
	if ctx.crowd != null:
		ctx.crowd.fright(at_ground, SLAM_R + 1.0, SLAM_FRIGHT[0], SLAM_FRIGHT[1], SLAM_FRIGHT[2], SLAM_FRIGHT[3], &"beast")
	if not DominionParts.staged(self):
		return
	var mark := SlamMark.new()
	mark.turn = float(slams) * 0.7
	mark.position = at_ground
	track(mark, ctx.ground)
	var dust := FxParts.particles(self, ctx.overhead_back, Iso.ground_to_screen(at_ground), PixelParticles.Shape.PUFF, DUST)
	dust.drag = 0.5
	dust.burst(SLAM_DUST, {"radius": 18.0, "speed": Vector2(40, 110), "alt": Vector2(0, 4), "alt_speed": Vector2(10, 40),
		"life": Vector2(0.7, 1.3), "size": Vector2(3, 6), "size_end_mul": 1.8, "dir": PixelParticles.Dir.OUTWARD})
	if ctx.shake != null:
		ctx.shake.add_trauma(0.4 if slams == 1 else 0.3)
	ctx.impact.aberration(1.5, 0.2)


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	_aura_in -= delta
	if _aura_in <= 0.0:
		_aura_in = AURA_EVERY
		_aura()
	if landed_at < 0.0 and _spot != Vector2.INF:
		var n := 0
		while n < BONES and bone_lands(n) <= t:
			n += 1
		bones_in = n
	if giant == null:
		return
	if not is_instance_valid(giant):
		_giant_gone()  # another power carried it off (freed, no cut_down)
		return
	if giant.is_alive() and not giant.is_queued_for_deletion() and t >= _next_slam:  # not one carried off this frame
		_next_slam += SLAM_EVERY
		_slam(giant.ground_pos)
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
				var own := a.speed_mul
				a.speed_mul *= AURA_SPEED
				_sped[a] = [own, a.speed_mul]
	for a in _sped.keys():
		if now.has(a):
			continue
		_unspeed(a)
		_sped.erase(a)


## Every quickened one has its own pace back (skipping any another power freed).
func _unspeed_all() -> void:
	for a in _sped.keys():
		_unspeed(a)
	_sped.clear()


## The aura's share taken off `a` (untyped: it may be freed; then nothing). Its pace untouched since the aura quickened it: exactly
## its own back (bit for bit, as before R27). Scaled meanwhile by another power (Walking Corpse's attack pace, R18): only
## AURA_SPEED divided out, so that other scale survives.
func _unspeed(a: Variant) -> void:
	if not is_instance_valid(a):
		return
	var an := a as Animal
	var was: Array = _sped[a]
	an.speed_mul = float(was[0]) if an.speed_mul == float(was[1]) else an.speed_mul / AURA_SPEED


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
		_giant_gone()
		ctx.play(&"gravetide_rise", at_ground, -6.0)
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


## The giant is gone (cut down, carried off, or its GIANT_LIFE over): no more slams or aura, and the tide ends with the
## horde (at LIFE), or FADE from now when the horde has already fallen.
func _giant_gone() -> void:
	giant = null
	_next_slam = INF
	_unspeed_all()
	_release_see()
	duration = maxf(LIFE, t) + FADE


## LIFE: every zombie still up falls to ash; the giant stands on (GIANT_LIFE from its landing).
func _end_life() -> void:
	if visitors == null:
		return
	var standing := giant != null and is_instance_valid(giant) and giant.is_alive()
	if not standing:
		_ash(visitors.living())
		_clear_all(false)
		return
	var horde := visitors.living().filter(func(a: Animal) -> bool: return a != giant)
	_ash(horde)
	for a in horde:
		_sped.erase(a)  # freed right after: nothing to give back
		visitors.take(a)


## landed_at + GIANT_LIFE: the giant falls to ash, and the tide with it.
func _end_giant() -> void:
	if visitors == null:
		return
	_ash(visitors.living())
	_clear_all(false)
	duration = maxf(LIFE, t) + FADE


## Staged: ash dust where each of `who` stood.
func _ash(who: Array) -> void:
	if not DominionParts.staged(self):
		return
	for a in who:
		FxParts.smoke(self, Iso.ground_to_screen((a as Animal).ground_pos), 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4),
			Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)


func _clear_all(deferred: bool) -> void:
	_unspeed_all()
	giant = null
	_next_slam = INF
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


## A slam's cracks: SLAM_CRACKS jagged lines out of its middle to most of SLAM_R, in ground units, turned by `turn` (each
## slam's its own way; a fixed pattern, no luck).
static func slam_cracks(turn: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for i in SLAM_CRACKS:
		var a := turn + TAU * (float(i) + 0.5) / float(SLAM_CRACKS) + 0.35 * sin(float(i) * 1.9 + turn)
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal()
		var to := SLAM_R * (0.55 + 0.3 * (0.5 + 0.5 * sin(float(i) * 3.7 + turn * 2.0)))
		var line := PackedVector2Array()
		for j in 5:
			var k := float(j) / 4.0
			var wob := 0.0 if j == 0 else 0.16 * sin(float(i) * 5.3 + float(j) * 2.1 + turn)
			line.append(dir * lerpf(0.3, to, k) + side * wob)
		out.append(line)
	return out


## The bones flying in (staged only): bone `i` leaves one of the cluster's bodies BONE_FLY before bone_lands(i), spinning
## in an arc, and settles into the giant's frame -- from its feet up, BONE_STACK px tall -- so the giant is built bone by
## bone. Screen space, in the effect's stand layer at the giant's spot.
class Bones extends Node2D:
	var fx: GraveTideFx
	## Screen points the bones leave from (the bodies), and the giant's feet.
	var from: Array[Vector2] = []
	var to := Vector2.ZERO

	func _ready() -> void:
		position = to.round()

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(fx) or from.is_empty():
			return
		for i in BONES:
			var leaves := GraveTideFx.bone_lands(i) - BONE_FLY
			if fx.t < leaves:
				break  # they leave in order
			var src: Vector2 = from[i % from.size()] - position + Vector2(5.0 * sin(float(i) * 1.7), 2.0 * cos(float(i) * 2.9))
			var dst := Vector2(7.0 * sin(float(i) * 2.3), -4.0 - BONE_STACK * float(i) / float(BONES - 1))
			var k := clampf((fx.t - leaves) / BONE_FLY, 0.0, 1.0)
			var settled := PI * 0.5 if i % 3 == 0 else 0.3 * sin(float(i) * 1.1)
			var turn := settled + (1.0 - k) * TAU * 1.5
			var pos := _along(src, dst, k)
			if k < 1.0:
				# A short pale trail behind it, so it reads at speed.
				draw_line(_along(src, dst, maxf(0.0, k - 0.2)), pos, Color(DeathParts.GRAVE_GREEN, 0.35), 1.0)
			_bone(pos.round(), turn)

	## Where a bone is `k` of the way from `src` to `dst`: fast off the body, easing in, in an arc BONE_ARC px high.
	static func _along(src: Vector2, dst: Vector2, k: float) -> Vector2:
		return src.lerp(dst, 1.0 - pow(1.0 - k, 2.0)) + Vector2(0.0, -BONE_ARC * sin(PI * k))

	## One bone: a shaft with a knob at each end, a pixel of shadow under it so it reads on pale paving.
	func _bone(at: Vector2, turn: float) -> void:
		for pass_i in 2:
			var col := Color(CRACK, 0.6) if pass_i == 0 else DeathParts.BONE
			draw_set_transform(at + (Vector2(1, 1) if pass_i == 0 else Vector2.ZERO), turn)
			draw_rect(Rect2(-3.0, -0.5, 6.0, 1.0), col)
			draw_rect(Rect2(-4.0, -1.5, 2.0, 3.0), col)
			draw_rect(Rect2(2.0, -1.5, 2.0, 3.0), col)
		draw_set_transform(Vector2.ZERO)


## A slam's mark on the ground (staged only), drawn in ground units on the ground layer so it lies flat: a shockwave ring
## out to SLAM_R over SLAM_RING_FOR, and cracks that run out at once and lie SLAM_CRACK_FOR, fading over their last second.
class SlamMark extends Node2D:
	var turn := 0.0
	var age := 0.0
	var _cracks: Array[PackedVector2Array] = []

	func _ready() -> void:
		_cracks = GraveTideFx.slam_cracks(turn)

	func _process(delta: float) -> void:
		age += delta
		if age >= SLAM_CRACK_FOR:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(SLAM_CRACK_FOR - age, 0.0, 1.0)
		var run := clampf(age / 0.12, 0.0, 1.0)
		for line in _cracks:
			var shown := PackedVector2Array()
			for j in line.size():
				if float(j) / float(line.size() - 1) > run + 0.001:
					break
				shown.append(line[j])
			if shown.size() >= 2:
				draw_polyline(shown, Color(CRACK, CRACK.a * fade), PX * 1.5)
		if age < SLAM_RING_FOR:
			var k := age / SLAM_RING_FOR
			var r := SLAM_R * (1.0 - pow(1.0 - k, 2.0))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(DeathParts.BONE, 0.75 * (1.0 - k)), PX * 4.0)
			draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 40, Color(DeathParts.ASH, 0.35 * (1.0 - k)), PX * 2.0)
