class_name GraveTideFx
extends FxTimeline
## Grave Tide (Death, Tier V; the second review's city-wide grave burst, rulings R41-R45): a click, once a descent. The
## graves of the whole city burst, and the dead storm every district. Always castable: no body is needed.
## - The graves (grave_spots(), R41: by rule, no luck): every district's centre, then its points a quarter and three
##   quarters in, each snapped to open ground and kept GRAVE_GAP from every grave kept before, GRAVES_MOST at most, spread.
##   Grave `i` bursts at T_RISE + i * BURST_STEP (soil, bone chips, dust and a dark pit, staged only) and raises one
##   skeleton warrior and one ghoul (DeathParts.skeleton/ghoul) in this effect's own Visitors pack.
## - The town's bodies (Remains.all(): the unhidden remains, the oldest first, MOST at most) rise at T_RISE as zombies on
##   top (DeathParts.zombie: their own look, greyed, eyes alight), and each body is used up. The cap (R44): at most
##   LIVING_CAP living undead in the pack, the giant not counted. The graves rise first: the bodies take only the room the
##   graves leave (picked at the cast), and a grave whose two would pass the cap raises none.
## - Nobody marches to the click: each hunts from where it rose (its kind's seek; the skeleton takes the nearest soldier
##   first), and claws at buildings (the Visitors `wreck` trait, `wreck_idle`: with nobody near it goes at the nearest):
##   a skeleton SKELETON_WRECK every SKELETON_WRECK_EVERY, a ghoul GHOUL_WRECK every GHOUL_WRECK_EVERY, a zombie ZOMBIE_WRECK
##   every ZOMBIE_WRECK_EVERY. A building the night needs standing is never theirs (the `spare` trait: MissionKeeps.spared(),
##   R45: the Citadel, the temple, the hallowed, a mission's own; a building the night wants down is never spared).
## - The giant always comes (R43): a giant of bones (Animal.Breed.BONE_GIANT) assembles at the grave nearest the click (a
##   tie to the lower index; giant_grave): from T_RISE its BONES bones fly up out of that grave, one by one, over ASSEMBLE;
##   at T_RISE + ASSEMBLE it stands and lands with a slam (_slam: soldiers out in the open within SLAM_R die, in instance-id
##   order, frenzy; the rest within it are knocked back and the street frightened; every wreckable building within SLAM_R
##   not spared takes SLAM_WRECK, a house falls to one slam; a shockwave, cracks, dust), and it slams again every SLAM_EVERY
##   while it stands. It walks the graves: by the streets to the nearest grave it has not visited (a `march`, GIANT_LEG at
##   most), then the next; all visited, the tour starts again. A soldier out in the open within GIANT_SEEK ends the leg, and
##   the hunt takes him (prey "soldiers"); then the tour goes on. Its blow (`bite` HEALTH_KNIGHT) fells any soldier at once; it
##   takes GIANT_BLOWS blows and does not flinch; it claws down the walls in its way (`wreck`), and never leaves the street to
##   go at a building (`wreck_idle` false).
## - Death's undead within GIANT_AURA of the giant -- this tide's and any other power's (every Visitors pack in
##   Crowd.visitors, the Animal.UNDEAD breeds only: never a hellhound, demon or ghost) -- move AURA_SPEED times as fast:
##   Animal.speed_mul scaled by AURA_SPEED as they first come within reach (every AURA_EVERY) and by 1 / AURA_SPEED when they
##   leave, when the giant falls, and at the end -- a ratio, once each way, so another scale laid on meanwhile (Walking Corpse's
##   attack pace, R18) survives it (R27); one whose pace nothing else touched gets exactly its own back.
## - At LIFE every one of the horde still up falls to ash; the giant stands on to GIANT_LIFE after its landing, then falls to
##   ash too (the pack cleared); cut short, or freed without its end, all of them at once (cut short mid-burst: no more graves
##   burst, and no giant).
## Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead stand; the giant's slams frighten the street round it,
## and the horde's first bite is the town's outcry, as a hellhound's.

## The brief's numbers: the most bodies that rise, how long the horde stands, the giant's blows, its aura and the speed it
## lends.
const MOST := 30
const LIFE := 40.0
const GIANT_BLOWS := 12
const GIANT_AURA := 6.0
const AURA_SPEED := 1.2
## The graves (R41): GRAVES_MOST at most, GRAVE_GAP apart at least, one bursting every BURST_STEP from T_RISE; a candidate
## snaps to open ground within GRAVE_SNAP cells.
const GRAVES_MOST := 24
const GRAVE_GAP := 2.5
const BURST_STEP := 0.08
const GRAVE_SNAP := 6
## The cap on the living undead in the pack, the giant not counted (R44).
const LIVING_CAP := 60
## The claws (R42): what each kind's blow takes off a building, and how often it strikes.
const SKELETON_WRECK := 6.0
const SKELETON_WRECK_EVERY := 1.5
const GHOUL_WRECK := 3.0
const GHOUL_WRECK_EVERY := 1.0
const ZOMBIE_WRECK := 3.0
const ZOMBIE_WRECK_EVERY := 1.5
## The ground breaks over T_RISE, and the dead stand (the power's impact); at the end they fall to ash over FADE.
const T_RISE := 1.2
const FADE := 0.6
## The giant: its pace (ground units a second: a heavy walk, under a man's run), how far it looks for soldiers, its reach,
## a blow every GIANT_BITE_EVERY; its claws on a wall (GIANT_WRECK every GIANT_WRECK_EVERY, within GIANT_WRECK_REACH: a
## wide reach, its arms are long); one leg of its tour (to the next grave) takes GIANT_LEG at most (R43).
const GIANT_PACE := 1.1
const GIANT_SEEK := 10.0
const GIANT_BITE_R := 0.9
const GIANT_BITE_EVERY := 1.4
const GIANT_WRECK := 30.0
const GIANT_WRECK_EVERY := 1.5
const GIANT_WRECK_REACH := 1.0
const GIANT_LEG := 25.0
## A leg cut for a soldier the hunt could not take: it walks on this long before another soldier may cut one.
const GIANT_RESEEK := 2.0
## The giant looks about this often (the next leg, a soldier near); the aura is read this often.
const GIANT_LOOK := 0.5
const AURA_EVERY := 0.1
## A heavy step sounds every STEP_EVERY while it walks.
const STEP_EVERY := 1.1
## The horde's first bite: the town's outcry (Hound Gate's and Raise the Dead's).
const BITE_FRIGHT_R := 2.0
const BITE_ALARM := 0.6
## Ruling R12: the giant stands GIANT_LIFE from its landing (the horde keeps LIFE). It assembles over ASSEMBLE from T_RISE:
## BONES bones fly one by one, up out of its grave, into its spot. Its landing is the first slam, and it slams the ground
## every SLAM_EVERY while it stands: soldiers out in the open within SLAM_R die (frenzy, a body), everyone else within it is
## knocked back SLAM_KNOCK and the street within SLAM_R + 1 frightened; every building within SLAM_R not spared takes
## SLAM_WRECK (R43). SLAM_EVERY 4 -> 3 and SLAM_R 3 -> 3.5 by the R46 bar ruling (the final review: the counter-blow
## thinned the horde, so the giant slams harder to keep the tide level with Heaven's Door).
const GIANT_LIFE := 60.0
const ASSEMBLE := 1.2
const BONES := 18
const SLAM_EVERY := 3.0
const SLAM_R := 3.5
const SLAM_KNOCK := 5.5
const SLAM_WRECK := 60.0
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
## The horde's claws on walls (dozens a second across the town): their crumble and dust at most once every HORDE_WRECK_FX.
const HORDE_WRECK_FX := 0.25
## A grave's burst (staged only): its pit is PIT_R ground units across at most and lies to the end of the horde; the two
## that climb out stand CLIMB_OUT either side of it.
const PIT_R := 0.45
const CLIMB_OUT := 0.25
## Death's palette: bone white, ash grey, pale-white fire; grave green for glows only. No blood. Soil for the graves.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
const SOIL := [Color("5a4634"), Color("3f3226"), Color("2c241c")]
## A slam's cracks (dark, a hairline about PX * 1.5 wide: PX is about one screen pixel in ground units) and its ring; a pit.
const CRACK := Color(0.1, 0.09, 0.08, 0.8)
const PIT := Color(0.07, 0.06, 0.05, 0.85)
const PX := 0.03
## Level 5, Scattered Bones (DL11): when the giant falls (cut down, or its GIANT_LIFE over) SCATTER_MOST skeleton warriors rise
## where it fell, on a ring SCATTER_R wide, as many as LIVING_CAP leaves room for; they hunt and stand SCATTER_LIFE, then go.
const SCATTER_MOST := 18
const SCATTER_LIFE := 20.0
const SCATTER_R := 0.9

## The tide's pack; how many rose (graves and bodies); the giant (null when there is none, or none any more) and where it
## rose (INF: not yet); how often the horde's and the giant's claws struck a building.
var visitors: Visitors
var raised := 0
var giant: Animal
var giant_at := Vector2.INF
var wrecks := 0
## The graves (R41), how many have burst, the one the giant rose from (-1: none, the click itself), the graves its tour has
## visited (giant_grave first), and how many buildings its slams struck.
var graves: Array[Vector2] = []
var burst := 0
var giant_grave := -1
var visited: Array[int] = []
var slam_wrecks := 0
## The assembly: how many bones have flown in (on the effect clock, staged or not); how often the giant has slammed the
## ground; when it landed (-1: not yet).
var bones_in := 0
var slams := 0
var landed_at := -1.0

## The bodies picked at the cast (the oldest first, MOST at most, the room the graves leave), raised at T_RISE.
var _rising: Array[Remains.Remain] = []
## Animal (untyped: another power may free it) -> [its speed_mul before the aura, its speed_mul quickened], while the aura quickens it.
var _sped := {}
var _aura_in := 0.0
var _look_in := 0.0
## The grave the giant's leg goes to (-1: none under way); whether its last leg was cut for a soldier, and when another may
## be; the horde's next wreck dust (staged), on the effect clock's countdown.
var _leg := -1
var _cut := false
var _cut_rest := 0.0
var _wreck_fx_in := 0.0
var _bitten := false
var _step_in := 0.0
var _step_from := Vector2.INF
var _see: SeeThrough
## The giant's spot (walkable), the next slam on the effect clock, and the flying bones (staged only).
var _spot := Vector2.INF
var _next_slam := INF
var _bones: Bones
## Level 5 (Scattered Bones): this cast's twist gate, the skeletons the giant's fall left (they carry no claws and raise
## nothing: this tide has no on-kill rise), and whether the fall has been seen.
var _twist := false
var _scattered: Array[Animal] = []
var _fell_once := false
## Heard (skill-tree sound pass): the horde's groaning while it walks (faded over HUSH), and the clocks a bite, a cut and a
## fall to ash may be heard again at (RaiseTheDeadFx's quiet gaps).
const HUSH := 1.0
var _groan: Node
var _bite_heard := 0.0
var _cut_heard := 0.0
var _ash_heard := 0.0


## The grave spots of a town (R41), by rule: the candidates are every district's centre (in `districts` order), then each
## district's points at (0.25, 0.25) and (0.75, 0.75) of its rect; each snaps to open ground with a way to the streets
## (grid.nearest_walkable within GRAVE_SNAP cells, a walled-in pocket counted solid: the dead of a grave there could reach
## nobody; none there: skipped) and is kept only GRAVE_GAP or more from every spot kept before. Past GRAVES_MOST,
## spot floor(i * n / GRAVES_MOST) is kept for i in 0..GRAVES_MOST - 1: spread over the whole list, not its head.
static func grave_spots(grid: WalkGrid, districts: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if grid == null:
		return out
	var candidates: Array[Vector2] = []
	for d: Rect2 in districts:
		candidates.append(d.get_center())
	for d: Rect2 in districts:
		candidates.append(d.position + d.size * 0.25)
		candidates.append(d.position + d.size * 0.75)
	for c in candidates:
		var p := grid.nearest_walkable(c, GRAVE_SNAP, true)
		if p == Vector2.INF:
			continue
		var apart := true
		for k in out:
			if k.distance_to(p) < GRAVE_GAP:
				apart = false
				break
		if apart:
			out.append(p)
	var n := out.size()
	if n <= GRAVES_MOST:
		return out
	var kept: Array[Vector2] = []
	for i in GRAVES_MOST:
		kept.append(out[i * n / GRAVES_MOST])
	return kept


## The index of the grave in `spots` nearest `at` (a tie to the lower index), or -1 with none.
static func nearest_grave(spots: Array[Vector2], at: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in spots.size():
		var d := spots[i].distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = i
	return best


## The living undead of the tide's pack, the giant not counted (the cap's count, R44).
func undead_up() -> int:
	if visitors == null:
		return 0
	var n := 0
	for a in visitors.living():
		if a != giant:
			n += 1
	return n


## This cast's numbers at its ability level (the consts at level 1): the giant's time, its blows and its slam's reach and blow on
## buildings. The undead's own numbers do not change.
var lv_giant_life := GIANT_LIFE
var lv_giant_blows := GIANT_BLOWS
var lv_slam_r := SLAM_R
var lv_slam_wreck := SLAM_WRECK


func _build() -> void:
	_twist = PowerBook.twist_at(extra, "gravetide")
	lv_giant_life = float(PowerBook.stat(extra, "gravetide", "GIANT_LIFE", GIANT_LIFE))
	lv_giant_blows = int(PowerBook.stat(extra, "gravetide", "GIANT_BLOWS", GIANT_BLOWS))
	lv_slam_r = float(PowerBook.stat(extra, "gravetide", "SLAM_R", SLAM_R))
	lv_slam_wreck = float(PowerBook.stat(extra, "gravetide", "SLAM_WRECK", SLAM_WRECK))
	# The giant outlives the horde: the tide lasts to its end (cut down sooner, _giant_gone() brings the end back).
	duration = maxf(LIFE, T_RISE + ASSEMBLE + lv_giant_life) + FADE
	busy = T_RISE
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	visitors.wrecked.connect(_on_wreck)
	graves = grave_spots(grid, City.current().districts())
	giant_grave = nearest_grave(graves, origin)
	giant_at = graves[giant_grave] if giant_grave >= 0 else origin
	# The graves first: the town's bodies take the room they leave under the cap.
	var room := maxi(0, LIVING_CAP - 2 * graves.size())
	if rem != null:
		var all := rem.all()
		for i in mini(all.size(), mini(MOST, room)):
			_rising.append(all[i])
	for i in graves.size():
		at(T_RISE + float(i) * BURST_STEP, _burst.bind(i))
	at(T_RISE, _rise)
	at(T_RISE + ASSEMBLE, _land)
	at(LIFE, _end_life)
	ctx.play(&"gravetide_rise", origin, 0.0)
	if not DominionParts.staged(self):
		return
	# The graves breathe: ash dust lifts off every grave and every body, and the ground glows cold over the giant's grave.
	for g in graves:
		FxParts.smoke(self, Iso.ground_to_screen(g), 6.0, 5.0, T_RISE, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0),
			Color(DeathParts.GRAVE_GREEN, 0.1), DUST)
	for r in _rising:
		FxParts.smoke(self, Iso.ground_to_screen(r.pos), 6.0, 8.0, T_RISE, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0),
			Color(DeathParts.GRAVE_GREEN, 0.12), DUST)
	var light := FxParts.ground_light(self, giant_at, 2.4, DeathParts.GRAVE_GREEN, 0.0)
	light.tween_param("intensity", 0.0, 0.8, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.tween_param("intensity", 0.8, 0.0, 1.2, T_RISE + ASSEMBLE)
	light.life = T_RISE + ASSEMBLE + 1.3
	if ctx.shake != null:
		ctx.shake.add_trauma(0.25)


## Grave `i` bursts: a skeleton warrior and a ghoul climb out, one either side of it -- none when the two would pass the cap.
## Staged: soil and bone thrown up, dust, and the open pit left behind.
func _burst(i: int) -> void:
	burst += 1
	var g := graves[i]
	if undead_up() + 2 <= LIVING_CAP:
		_up_skeleton(_beside(g, -CLIMB_OUT))
		_up_ghoul(_beside(g, CLIMB_OUT))
	if i % 4 == 0:
		ctx.play(&"gravetide_rise", g, -8.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(g)
	FxParts.debris(self, sp, 7, 6.0, Vector2(30, 90), SOIL, Vector2(1.5, 3.0), true)
	FxParts.debris(self, sp, 3, 4.0, Vector2(20, 60), BONE_CHIPS, Vector2(1.0, 2.0), true)
	FxParts.smoke(self, sp, 8.0, 24.0, 0.2, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)
	var pit := GravePit.new()
	pit.turn = float(i) * 1.3
	pit.life = LIFE - t + FADE
	pit.position = g
	track(pit, ctx.ground)


## The open ground `dx` across from grave `g`, on the streets' side (the grave itself where that is not).
func _beside(g: Vector2, dx: float) -> Vector2:
	var p := g + Vector2(dx, 0.0)
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	return p if grid == null or grid.on_streets(p) else g


## A skeleton warrior up at `at`, armed for the tide: its claws (R42) and the buildings it spares (R45).
func _up_skeleton(at_ground: Vector2) -> Animal:
	var a := DeathParts.skeleton(visitors, at_ground)
	visitors.give(a, {"wreck": SKELETON_WRECK, "wreck_every": SKELETON_WRECK_EVERY, "spare": _spared})
	raised += 1
	return a


## A ghoul up at `at`, armed for the tide.
func _up_ghoul(at_ground: Vector2) -> Animal:
	var a := DeathParts.ghoul(visitors, at_ground)
	visitors.give(a, {"wreck": GHOUL_WRECK, "wreck_every": GHOUL_WRECK_EVERY, "spare": _spared})
	raised += 1
	return a


## Whether the tide spares building `s` (R45): one the night needs standing, asked live (MissionKeeps.spared()).
func _spared(s: Structure) -> bool:
	var d: MissionDirector = null
	if ctx.rules != null and is_instance_valid(ctx.rules):
		d = ctx.rules.director
	return MissionKeeps.spared(s, ctx.crowd, d)


## T_RISE: the town's bodies stand too, each as a zombie that hunts from where it lay, under the cap.
func _rise() -> void:
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	if rem != null:
		var still := rem.all()  # a body another power took meanwhile is not raised twice
		var grid: WalkGrid = ctx.crowd._grid
		for r in _rising:
			if not still.has(r) or undead_up() >= LIVING_CAP:
				continue
			var a := DeathParts.zombie(visitors, r, false)
			rem.take(r)
			if grid != null and not grid.on_streets(a.ground_pos):
				# A body that fell indoors (or in a walled-in pocket) gets up at the nearest open ground with a way out.
				var w := grid.nearest_walkable(a.ground_pos, 4, true)
				if w != Vector2.INF:
					a.ground_pos = w
					a.sync_position()
			visitors.give(a, {"wreck": ZOMBIE_WRECK, "wreck_every": ZOMBIE_WRECK_EVERY, "spare": _spared})
			raised += 1
			if DominionParts.staged(self):
				var sp := Iso.ground_to_screen(a.ground_pos)
				FxParts.debris(self, sp, 4, 5.0, Vector2(20, 60), BONE_CHIPS, Vector2(1.0, 2.0), true)
	_rising.clear()
	_groan = ctx.play(&"horde_groan", origin, 0.0)
	_assemble()


## The giant's spot (its grave, or the nearest open ground to the click); from T_RISE its bones fly up out of the grave.
func _assemble() -> void:
	_spot = giant_at
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	if grid != null and not grid.on_streets(_spot):
		var w := grid.nearest_walkable(_spot, GRAVE_SNAP, true)
		if w != Vector2.INF:
			_spot = w
	if not DominionParts.staged(self):
		return
	_bones = Bones.new()
	_bones.fx = self
	for i in 6:
		_bones.from.append(Iso.ground_to_screen(_spot + Vector2.from_angle(TAU * float(i) / 6.0) * PIT_R))
	_bones.to = Iso.ground_to_screen(_spot)
	track(_bones, stand_layer())
	# Its grave breaks open first, whenever its turn in the bursts comes.
	var sp := Iso.ground_to_screen(_spot)
	FxParts.debris(self, sp, 10, 8.0, Vector2(30, 100), SOIL, Vector2(1.5, 3.0), true)


## The time bone `i` (0 first) lands in the giant's frame: BONE_FLY after it leaves, the last at T_RISE + ASSEMBLE.
static func bone_lands(i: int) -> float:
	return T_RISE + BONE_FLY + float(i) * (ASSEMBLE - BONE_FLY) / float(BONES - 1)


## T_RISE + ASSEMBLE: every bone in, the giant stands, and its landing is the first slam.
func _land() -> void:
	if is_instance_valid(_bones):
		_bones.queue_free()
	_bones = null
	if _spot == Vector2.INF:
		return  # the dead never rose: no giant
	bones_in = BONES
	_raise_giant()
	landed_at = t
	_next_slam = landed_at + SLAM_EVERY
	at(landed_at + lv_giant_life, _end_giant)
	_slam(giant.ground_pos)


## The giant stands where its bones came together; its grave is the first of its tour.
func _raise_giant() -> void:
	var spot := _spot
	giant = visitors.summon(spot, Animal.Breed.BONE_GIANT, lv_giant_blows, GIANT_PACE / (Animal.DOG_SPEED * Animal.RUN), GIANT_SEEK,
		GIANT_BITE_R, GIANT_BITE_EVERY, false)
	visitors.give(giant, {"prey": "soldiers", "bite": Person.HEALTH_KNIGHT, "wreck": GIANT_WRECK, "wreck_every": GIANT_WRECK_EVERY,
		"wreck_reach": GIANT_WRECK_REACH, "wreck_idle": false, "spare": _spared})
	visited.clear()
	if giant_grave >= 0:
		visited.append(giant_grave)
	_leg = -1
	_look_in = GIANT_LOOK
	_step_in = STEP_EVERY
	_step_from = spot
	if not DominionParts.staged(self):
		return
	_see = SeeThrough.new()
	# The bones lock together in a flash of pale fire.
	var flash_at := FxParts.bloom(self, Iso.ground_to_screen(spot) + Vector2(0, -40), 46.0, DeathParts.PALE_FIRE, 1.0, 0.9)
	flash_at.tween_param("intensity", 0.9, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	flash_at.life = 0.65


## The giant slams the ground at `at_ground` (ruling R12): every soldier out in the open within SLAM_R dies (frenzy: a body
## lies there), in instance-id order -- no luck in who dies; everyone else within it is knocked back, and the street within
## SLAM_R + 1 frightened; every wreckable building within SLAM_R that the tide does not spare (R45) takes SLAM_WRECK (R43: a
## house falls to one slam), counted in slam_wrecks. Staged: a shockwave ring out to SLAM_R, cracks, a burst of dust, the
## ground shaking.
func _slam(at_ground: Vector2) -> void:
	slams += 1
	ctx.play(&"giant_step", at_ground, SLAM_DB)
	var doomed: Array[Person] = []
	for e in ctx.field.in_radius(at_ground, lv_slam_r):
		var p := e as Person
		if p != null and p.soldier and not p.inside:
			doomed.append(p)
	doomed.sort_custom(func(a: Person, b: Person) -> bool: return a.get_instance_id() < b.get_instance_id())
	for p in doomed:
		ctx.field.kill(p, &"frenzy", at_ground)
	ctx.field.knock_from(at_ground, 0.0, lv_slam_r, SLAM_KNOCK)
	if ctx.crowd != null:
		ctx.crowd.fright(at_ground, lv_slam_r + 1.0, SLAM_FRIGHT[0], SLAM_FRIGHT[1], SLAM_FRIGHT[2], SLAM_FRIGHT[3], &"beast")
	var env: EnvironmentField = ctx.env if ctx.env != null else ctx.field.env
	if env != null:
		var struck: Array[Structure] = []
		for s in env.near(at_ground, lv_slam_r):
			if Visitors._wreckable(s) and s.distance_to(at_ground) <= lv_slam_r and not _spared(s):
				struck.append(s)
		struck.sort_custom(func(a: Structure, b: Structure) -> bool: return a.get_instance_id() < b.get_instance_id())
		for s in struck:
			s.damage(lv_slam_wreck, at_ground, &"frenzy")
			slam_wrecks += 1
	if not DominionParts.staged(self):
		return
	var mark := SlamMark.new()
	mark.turn = float(slams) * 0.7
	mark.reach = lv_slam_r
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
	_wreck_fx_in -= delta
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


## The giant's tour (R43), every GIANT_LOOK. On a leg: a soldier out in the open within GIANT_SEEK ends it (on a march a
## visitor turns only on prey within Visitors.MARCH_SEEK), and the hunt takes him; the grave is not counted visited (one the
## hunt could not take leaves it walking GIANT_RESEEK before another soldier may cut a leg). A leg
## over (there, blocked or out of time): that grave is visited. Hunting: the hunt goes on. Otherwise the next leg, by the
## streets, to the nearest grave not yet visited (a tie to the lower index); all visited, the tour starts again from where
## it stands.
func _walk_on() -> void:
	if visitors.marching(giant):
		if t >= _cut_rest and _soldier_near():
			visitors.end_march(giant)
			_leg = -1
			_cut = true
		return
	if _leg >= 0:
		if not visited.has(_leg):
			visited.append(_leg)
		_leg = -1
	if giant.target != null and is_instance_valid(giant.target):
		_cut = false
		return  # one within its reach: the hunt has him
	if _cut:
		# The leg was cut for a soldier the hunt could not take (no way to him): it walks on a while before another cuts it.
		_cut = false
		_cut_rest = t + GIANT_RESEEK
	var left: Array[Vector2] = []
	var index: Array[int] = []
	for i in graves.size():
		if not visited.has(i):
			left.append(graves[i])
			index.append(i)
	if left.is_empty():
		if graves.size() < 2:
			return  # nowhere else to go: it stands and hunts
		var last := visited[-1] if not visited.is_empty() else -1
		visited.clear()
		if last >= 0:
			visited.append(last)
		_walk_on()
		return
	_leg = index[nearest_grave(left, giant.ground_pos)]
	visitors.give(giant, {"march": graves[_leg], "march_for": GIANT_LEG})


## Whether a living soldier stands out in the open within GIANT_SEEK of the giant (one the hunt could take).
func _soldier_near() -> bool:
	for e in ctx.field.in_radius(giant.ground_pos, GIANT_SEEK):
		var p := e as Person
		if p != null and p.soldier and p.is_alive() and not p.inside:
			return true
	return false


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
	if is_instance_valid(victim) and t >= _bite_heard:
		_bite_heard = t + RaiseTheDeadFx.BITE_QUIET
		ctx.play(&"undead_bite", victim.ground_pos, 0.0)
	if first and not _bitten and ctx.crowd != null and is_instance_valid(victim):
		_bitten = true
		ctx.crowd.fright(victim.ground_pos, BITE_FRIGHT_R, 0.6, 3.0, 6.0, 8.0, &"bite", true)
		ctx.crowd.add_alarm(BITE_ALARM)


## Cut down: it falls to bones and ash (the Visitors free its node). The giant gone, the aura goes with it.
func _on_cut_down(a: Animal, at_ground: Vector2) -> void:
	if _sped.has(a):
		_sped.erase(a)  # it is freed right after: nothing to give back
	if a == giant:
		_scatter(at_ground)
		_giant_gone()
		_bones_hold()
		ctx.play(&"giant_fall", at_ground, 0.0)
	elif t >= _cut_heard:
		_cut_heard = t + RaiseTheDeadFx.CUT_QUIET
		ctx.play(&"undead_cut", at_ground, 0.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at_ground)
	var big := a.breed == Animal.Breed.BONE_GIANT
	FxParts.debris(self, sp, 18 if big else 6, 12.0 if big else 5.0, Vector2(30, 90), BONE_CHIPS, Vector2(1.0, 2.5), true)
	FxParts.smoke(self, sp, 14.0 if big else 7.0, 36.0, 0.25, Vector2(14, 36), Vector2(2, 5), Vector2(0.6, 1.1), Color(0, 0, 0, 0), DUST)


## Claws on a wall: dust and splinters -- every blow of the giant's; the horde's (dozens a second across the town) at most
## once every HORDE_WRECK_FX.
func _on_wreck(a: Animal, s: Structure) -> void:
	wrecks += 1
	if a != giant:
		if _wreck_fx_in > 0.0:
			return
		_wreck_fx_in = HORDE_WRECK_FX
	ctx.play(&"gt_wreck", a.ground_pos, 0.0 if a == giant else -4.0)
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


## LIFE: every one of the horde still up falls to ash; the giant stands on (GIANT_LIFE from its landing).
func _end_life() -> void:
	_hush(HUSH)
	if visitors == null:
		return
	var standing := giant != null and is_instance_valid(giant) and giant.is_alive()
	if not standing and _bones_up().is_empty():
		_ash_sound(visitors.living())
		_ash(visitors.living())
		_clear_all(false)
		return
	var horde := visitors.living().filter(func(a: Animal) -> bool: return a != giant and not _scattered.has(a))
	_ash_sound(horde)
	_ash(horde)
	for a in horde:
		_sped.erase(a)  # freed right after: nothing to give back
		visitors.take(a)


## landed_at + GIANT_LIFE: the giant falls to ash, and the tide with it.
func _end_giant() -> void:
	if visitors == null:
		return
	if _twist and _fell_once and (giant == null or not is_instance_valid(giant)):
		return  # the giant fell earlier: this is its stale end, and the skeletons it left keep their 20.0 s
	if giant != null and is_instance_valid(giant) and giant.is_alive():
		ctx.play(&"giant_fall", giant.ground_pos, 0.0)
	if _twist and giant != null and is_instance_valid(giant):
		_scatter(giant.ground_pos)
		if not _scattered.is_empty():
			# Scattered Bones: the giant and the horde fall to ash, the skeletons its fall left stand on.
			var rest := visitors.living().filter(func(a: Animal) -> bool: return not _scattered.has(a))
			_ash(rest)
			_unspeed_all()
			for a in rest:
				visitors.take(a)
			giant = null
			_next_slam = INF
			_rising.clear()
			_release_see()
			duration = maxf(LIFE, t) + FADE
			_bones_hold()
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


## Scattered Bones (level 5, DL11): the giant has fallen at `at_ground`: up to SCATTER_MOST skeleton warriors rise round it,
## as many as the cap leaves room for (the giant not counted), in this pack, each for SCATTER_LIFE. Once per cast, no luck.
func _scatter(at_ground: Vector2) -> void:
	if not _twist or _fell_once:
		return
	_fell_once = true
	var n := mini(SCATTER_MOST, LIVING_CAP - undead_up())
	if n <= 0:
		return
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	for i in n:
		var p := at_ground + Vector2.from_angle(TAU * float(i) / float(n)) * SCATTER_R
		if grid != null and not grid.on_streets(p):
			var w := grid.nearest_walkable(p, 3, true)
			p = w if w != Vector2.INF else at_ground
		_scattered.append(_up_skeleton(p))  # as the tide's own: claws (R42) and the spared buildings (R45), counted in raised
	at(t + SCATTER_LIFE, _bones_leave)
	if DominionParts.staged(self):
		FxParts.debris(self, Iso.ground_to_screen(at_ground), 8, 6.0, Vector2(30, 90), BONE_CHIPS, Vector2(1.0, 2.0), true)


## The skeletons of the fall still up.
func _bones_up() -> Array[Animal]:
	var out: Array[Animal] = []
	for a in _scattered:
		if is_instance_valid(a) and a.is_alive() and not a.is_queued_for_deletion():
			out.append(a)
	return out


## The tide stands on while they do.
func _bones_hold() -> void:
	if not _scattered.is_empty():
		duration = maxf(duration, t + SCATTER_LIFE + FADE)


## SCATTER_LIFE after the fall: the skeletons still up fall to ash.
func _bones_leave() -> void:
	if visitors == null:
		return
	var left := _bones_up()
	_ash_sound(left)
	_ash(left)
	for a in left:
		_sped.erase(a)
		visitors.take(a)
	_scattered.clear()


## Heard: `who` falling to ash at once -- one crumble at their middle, at most every RaiseTheDeadFx.ASH_QUIET.
func _ash_sound(who: Array) -> void:
	if who.is_empty() or t < _ash_heard:
		return
	_ash_heard = t + RaiseTheDeadFx.ASH_QUIET
	var mid := Vector2.ZERO
	for a in who:
		mid += (a as Animal).ground_pos
	ctx.play(&"undead_ash", mid / float(who.size()), 0.0)


## The horde's groaning fades over `seconds` (stops at 0), if it is still this tide's to fade (sound only).
func _hush(seconds: float) -> void:
	if _groan != null and is_instance_valid(_groan) and _groan.get_meta(&"cue", &"") == &"horde_groan":
		if seconds > 0.0:
			ctx.fade_out(_groan, seconds)
		elif _groan is AudioStreamPlayer2D:
			(_groan as AudioStreamPlayer2D).stop()
	_groan = null


func _clear_all(deferred: bool) -> void:
	_scattered.clear()
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
	_hush(HUSH)
	_clear_all(false)
	super()


## Freed without _finish (a mission torn down mid-tide): the same, the pack only queued for freeing (its parents may be
## mid-teardown).
func _exit_tree() -> void:
	_hush(0.0)
	_clear_all(true)
	super()


## A slam's cracks: SLAM_CRACKS jagged lines out of its middle to most of SLAM_R, in ground units, turned by `turn` (each
## slam's its own way; a fixed pattern, no luck).
static func slam_cracks(turn: float, reach := SLAM_R) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for i in SLAM_CRACKS:
		var a := turn + TAU * (float(i) + 0.5) / float(SLAM_CRACKS) + 0.35 * sin(float(i) * 1.9 + turn)
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal()
		var to := reach * (0.55 + 0.3 * (0.5 + 0.5 * sin(float(i) * 3.7 + turn * 2.0)))
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
	## How far the ring runs out (the slam's reach at the tide's level).
	var reach := SLAM_R
	var age := 0.0
	var _cracks: Array[PackedVector2Array] = []

	func _ready() -> void:
		_cracks = GraveTideFx.slam_cracks(turn, reach)

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
			var r := reach * (1.0 - pow(1.0 - k, 2.0))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(DeathParts.BONE, 0.75 * (1.0 - k)), PX * 4.0)
			draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 40, Color(DeathParts.ASH, 0.35 * (1.0 - k)), PX * 2.0)


## A burst grave's pit (staged only), drawn in ground units on the ground layer so it lies flat: a dark, ragged hole about
## PIT_R across with a rim of thrown soil, turned by `turn` (each its own way; a fixed shape, no luck). It lies `life`
## seconds, fading over its last FADE.
class GravePit extends Node2D:
	var turn := 0.0
	var life := 40.0
	var age := 0.0

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		if age > life - FADE:
			modulate.a = clampf((life - age) / FADE, 0.0, 1.0)

	func _draw() -> void:
		var hole := PackedVector2Array()
		var rim := PackedVector2Array()
		for i in 12:
			var a := turn + TAU * float(i) / 12.0
			var wob := 0.75 + 0.25 * (0.5 + 0.5 * sin(float(i) * 2.7 + turn))
			hole.append(Vector2.from_angle(a) * PIT_R * wob * Vector2(1.0, 0.8))
			rim.append(Vector2.from_angle(a) * PIT_R * (wob + 0.35) * Vector2(1.0, 0.8))
		draw_colored_polygon(rim, Color(SOIL[0], 0.75))
		draw_colored_polygon(hole, PIT)
