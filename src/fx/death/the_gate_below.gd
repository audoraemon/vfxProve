class_name TheGateBelowFx
extends FxTimeline
## The Gate Below (Death, Tier IV; spec 5.5): a click, and the ground itself tears open there: a dark rift that fills the
## ring (its jagged lip about EDGE, R33), cracked out to PIT_R (the reach) and strewn with bone, drawn in ground units on the
## ground layer (Rift; ruling R8), so it keeps its proportions at every zoom. It opens out of a slit over T_OPEN and closes
## back into one over CLOSE. ARMS grasping hands (the grave_hand sheet, R34) reach up out of the ground all over the ring,
## over the rift too, while it is open (Arm, looping). It is not a door to elsewhere (that is Passage's Doors of the Dead):
## the ground takes them down.
## - From T_OPEN, every GRAB_EVERY, a hand takes the nearest living person within REACH who is out in the open, not guised
##   (Person.guised()), not a decoy (Mirrorfold's glass twin) and not caught yet -- a tie goes to the lower instance id; no
##   luck. A caught one is held where they stand (hold_pace 0) and dragged in a straight line to the lip (EDGE) over DRAG --
##   one already inside it is held where he stands -- then pulled under: killed as &"pit", a kind that leaves no body
##   (Remains.BODY_KINDS). Each one taken is a soul. No hand reaches out once a drag could not finish before the close
##   (SPAN - DRAG), so every soul taken is counted by then.
## - At SPAN the pit closes, and every soul it took climbs back out of it as a wraith (DeathParts.wraith(), R35, R37): with
##   n souls, wraith k owns sector_of(k, n), flies out along its middle to WRAITH_FAR from the pit, then hunts the nearest
##   anyone, citizen or soldier, whose bearing from the pit lies in its sector. Its touch withers (the crowd's Withering: grey,
##   slowed, panicked, dead as &"wither" 6 s later, a body left); after DeathParts.WRAITH_TOUCHES it is spent, and it slows
##   whoever it passes through. `withered` counts its curses. They are this effect's own Visitors pack, and the ones left go
##   back into the ground WRAITH_LIFE later.
## Level 5, Graves Answer (twist): at open the GRAVES nearest bodies (Remains) within GRAVE_R of the rift each sprout a grave
##   hand; each, on the pit's own grab clock, takes the nearest fair living person within GRAVE_GRAB of its body, once, held
##   where they stand for DRAG and then pulled under (&"pit"), and the body sinks with them. Each is a soul for the close.
## Loud (PowerBook.REACH): the danger counts from the first soul under (IMPACT = T_OPEN + DRAG). From then, while the pit is
## open, everyone within FRIGHT_R of it flees afresh every FRIGHT_EVERY, and the first soul taken raises the alarm (as Hound
## Gate's first bite). Cut short or over, every hold is let go and the wraiths are gone (_finish(); _exit_tree() when torn down).

## The ground cracks and opens over T_OPEN; the hands reach out from then.
const T_OPEN := 1.0
## How far the hands reach, and the pit's cracks and bone with them (R33: the rift fills the ring).
const REACH := 6.0
const PIT_R := REACH
## How long the pit stays open, counted from the cast; it closes over CLOSE.
const SPAN := 12.0
const CLOSE := 1.0
## One more taken every GRAB_EVERY; each is dragged to the edge over DRAG.
const GRAB_EVERY := 0.5
const DRAG := 1.5
## The edge they are dragged to and go under at: the rift's lip (its mean radius; it is jagged by JAG either way, R33).
const EDGE := 4.2
const JAG := 0.20
## The rift (rulings R8, R33): its jagged lip of RIFT_POINTS, CRACKS hairline cracks out toward PIT_R, BONES chips of bone
## strewn between the lip and PIT_R. PX is about one screen pixel in ground units (a ground unit is 32-36 px across).
const RIFT_POINTS := 28
const CRACKS := 16
const BONES := 40
const PX := 0.03
## The ambient hands (R34): ARMS of them on a golden-angle spiral from ARM_IN out to REACH (over the rift too), each rising,
## clawing and sinking over ARM_LOOP, its loop offset by index * ARM_PHASE.
const ARMS := 36
const ARM_IN := 0.6
const ARM_LOOP := 2.4
const ARM_PHASE := 0.37
const GOLDEN := 2.39996
## The wraiths: how long they hunt, how far out they climb from the middle, how far they fly out along their sector's
## middle before they hunt (R35), how long they take to sink back in at the end.
const WRAITH_LIFE := 20.0
const WRAITH_SPREAD := 0.6
const WRAITH_FAR := REACH + 2.0
const FADE := 0.6
## The town's fright while the pit is open: past the arms' reach, renewed as a spirit's is.
const FRIGHT_R := REACH + 2.0
const FRIGHT_EVERY := Visitors.FRIGHT_EVERY
## The first soul taken: the alarm it adds (Hound Gate's first bite).
const TAKE_ALARM := 0.6

## The hand sheet (R34, grave_hand.json): ARM_FRAMES frames of ARM_CELL, its foot at ARM_FOOT -- 0-1 rising, 2-3 clawing,
## 4-5 closing and pulling down -- drawn 1:1 (ARM_SCALE): the hand and forearm about 48 px tall, the hand about 20 px across.
const ARM_SHEET := "res://assets/pixellab/fx/grave_hand/grave_hand.png"
const ARM_CELL := Vector2(64, 64)
const ARM_FOOT := Vector2(32, 62)
const ARM_FRAMES := 6
const ARM_SCALE := 1.0
## How far (screen px) a hand stands from its victim, toward the pit.
const ARM_SIDE := 10.0
## An arm's moments: up out of the ground over ARM_RISE, the pull down over ARM_PULL, then gone into it over ARM_SINK.
const ARM_RISE := 0.3
const ARM_PULL := 0.45
const ARM_SINK := 0.25
## Graves Answer (level 5): how many bodies sprout a hand, how far from the rift they may lie, how near a body its hand reaches.
const GRAVES := 8
const GRAVE_R := 12.0
const GRAVE_GRAB := 1.5
## The cold glow out of the hole: faint, so the hole stays dark.
const LIGHT := 0.25
## The rift's dark, its deepest middle, its lip of broken ground, its cracks.
const RIFT_DARK := Color(0.02, 0.02, 0.03, 0.92)
const RIFT_DEEP := Color(0.0, 0.0, 0.0, 0.6)
const RIFT_LIP := Color(0.16, 0.15, 0.14, 0.7)
const CRACK := Color(0.05, 0.05, 0.06, 0.85)
## Death's palette: bone white, ash grey, pale-white fire; grave green for glows only.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
const PALE := [Color("eaf4ff"), Color("c8f0dc"), Color(0.5, 0.9, 0.7, 0.5), Color(0.2, 0.4, 0.35, 0.0)]

## The wraiths' pack; the people taken, in the order they were caught; the souls the pit took; when the first went under.
var visitors: Visitors
var grabbed: Array[Person] = []
var souls := 0
var first_soul_at := -1.0
## Whether the pit has closed.
var closed := false
## The wraiths' curses: everyone a wraith of this cast has withered (Visitors.bitten: a withering laid).
var withered := 0

## The drags under way: {p: Person, from: Vector2, to: Vector2, at: float (the grab's tick), arm: Arm or null}.
var _drags: Array[Dictionary] = []
## Instance ids of everyone ever caught by this cast.
var _caught := {}
var _next_grab := T_OPEN
var _next_fright := T_OPEN + DRAG
var _ended := false
var _light: QuadFx
## This cast's numbers at its ability level (the consts at level 1): the arms' reach (the cracks, the frighten and the wraiths' flight
## follow it), the rift's lip, the time open, and the touches a wraith has.
var lv_reach := REACH
var lv_edge := EDGE
var lv_span := SPAN
var lv_wraith_touches := DeathParts.WRAITH_TOUCHES
## Graves Answer: whether the level-5 twist is on; the hands still waiting to grab: {r: Remains.Remain, arm: Arm or null}.
var _twist := false
var graves: Array[Dictionary] = []


func _build() -> void:
	lv_reach = float(PowerBook.stat(extra, "gatebelow", "REACH", REACH))
	lv_edge = float(PowerBook.stat(extra, "gatebelow", "EDGE", EDGE))
	lv_span = float(PowerBook.stat(extra, "gatebelow", "SPAN", SPAN))
	lv_wraith_touches = int(PowerBook.stat(extra, "gatebelow", "WRAITH_TOUCHES", DeathParts.WRAITH_TOUCHES))
	duration = lv_span + WRAITH_LIFE + FADE + 1.0  # a ceiling: _close() and _end_wraiths() set the real end
	busy = T_OPEN
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	_twist = PowerBook.twist_at(extra, "gatebelow")
	if _twist:
		_pick_graves()
	visitors.bitten.connect(_on_withered)
	visitors.spent.connect(_on_spent)
	ctx.play(&"gatebelow_open", origin, 0.0)
	if not DominionParts.staged(self):
		return
	var rift := Rift.new()
	rift.fx = self
	rift.position = origin
	track(rift, ctx.ground)
	# The hands reaching up all over the ring: only out of open ground (none stands on a roof or a wall).
	var i := 0
	for spot in arm_spots(origin, lv_reach):
		if grid == null or grid.walkable(spot):
			var arm := Arm.new()
			arm.fx = self
			arm.born = T_OPEN
			arm.loop = true
			arm.phase = float(i) * ARM_PHASE
			arm.facing = -1 if Iso.ground_to_screen(origin).x > Iso.ground_to_screen(spot).x else 1
			arm.position = Iso.ground_to_screen(spot).round()
			track(arm, stand_layer())
		i += 1
	for g in graves:
		var arm := Arm.new()
		arm.fx = self
		arm.born = T_OPEN
		arm.facing = -1 if Iso.ground_to_screen(origin).x > Iso.ground_to_screen((g.r as Remains.Remain).pos).x else 1
		arm.position = Iso.ground_to_screen((g.r as Remains.Remain).pos).round()
		track(arm, stand_layer())
		g["arm"] = arm
	# Cold light out of the hole, ground dust thrown up as it cracks open, the ground shaking.
	_light = FxParts.ground_light(self, origin, lv_reach * 0.8, DeathParts.GRAVE_GREEN, 0.0)
	_light.tween_param("intensity", 0.0, LIGHT, T_OPEN, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var sp := Iso.ground_to_screen(origin)
	FxParts.smoke(self, sp, 60.0, 30.0, T_OPEN, Vector2(8, 22), Vector2(3, 6), Vector2(0.8, 1.6), Color(0, 0, 0, 0), DUST)
	FxParts.debris(self, sp, 18, 50.0, Vector2(20, 90), BONE_CHIPS, Vector2(1.0, 2.5), true)
	if ctx.shake != null:
		ctx.shake.add_trauma(0.25)


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	# The arms run on the pit's own clock, a tick at a time, so a long frame misses none (Door to the Deep's way).
	while not closed and _next_grab <= lv_span - DRAG + 0.0001 and t >= _next_grab:
		_grab(_next_grab)
		_next_grab += GRAB_EVERY
	while not closed and _next_fright < lv_span and t >= _next_fright:
		_next_fright += FRIGHT_EVERY
		if ctx.crowd != null:
			ctx.crowd.fright(origin, lv_reach + 2.0, 0.8, 2.0, 10.0, 14.0, &"beast")
	_drag()
	if not closed and t >= lv_span:
		_close()
	if closed and souls > 0 and not _ended and t >= lv_span + WRAITH_LIFE:
		_end_wraiths()


## One reach of the arms (the tick at `when`): the pit's own, then (level 5) one grave hand's.
func _grab(when: float) -> void:
	_grab_pit(when)
	if _twist:
		_grab_grave(when)


## Graves Answer (DL8): the GRAVES remains nearest the rift within GRAVE_R, not hidden or taken (a tie by age), each with a hand.
func _pick_graves() -> void:
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	if rem == null:
		return
	var near := rem.near(origin, GRAVE_R)
	var order := {}
	for i in near.size():
		order[near[i]] = i
	near.sort_custom(func(a: Remains.Remain, b: Remains.Remain) -> bool:
		var da := a.pos.distance_squared_to(origin)
		var db := b.pos.distance_squared_to(origin)
		if da != db:
			return da < db
		return order[a] < order[b])
	for i in mini(GRAVES, near.size()):
		graves.append({"r": near[i], "arm": null})


## One grave hand's grab on the pit's tick: the first waiting hand with a fair living person within GRAVE_GRAB of its body takes
## them, once -- held where they stand for DRAG, then under -- and its body sinks with them. A hand whose body was taken meanwhile
## (another power) lets go.
func _grab_grave(when: float) -> void:
	var rem: Remains = ctx.crowd.remains
	var left: Array[Dictionary] = []
	var done := false
	for g in graves:
		var r: Remains.Remain = g.r
		var arm = g.arm
		if not rem.near(r.pos, 0.001).has(r):
			if is_instance_valid(arm):
				(arm as Arm).let_go(t)
			continue
		var victim: Person = null if done else _grave_victim(r.pos)
		if victim == null:
			left.append(g)
			continue
		done = true
		rem.take(r)
		_caught[victim.get_instance_id()] = true
		grabbed.append(victim)
		victim.hold_pace(get_instance_id(), 0.0)
		var hand: Arm = arm if is_instance_valid(arm) else null
		if hand != null:
			hand.position = _arm_at(victim.ground_pos)
		_drags.append({"p": victim, "from": victim.ground_pos, "to": victim.ground_pos, "at": when, "arm": hand})
	graves = left


## The nearest fair living person within GRAVE_GRAB of `at` (a tie to the lower instance id), or null.
func _grave_victim(at: Vector2) -> Person:
	var best: Person = null
	var best_d := INF
	for e in ctx.field.in_radius(at, GRAVE_GRAB):
		var p := e as Person
		if p == null or p.inside or p.guised() or p.has_meta(&"decoy") or _caught.has(p.get_instance_id()):
			continue
		var d := p.ground_pos.distance_squared_to(at)
		if d < best_d or (d == best_d and p.get_instance_id() < best.get_instance_id()):
			best_d = d
			best = p
	return best


## The pit's own reach: the nearest fair one within REACH is caught and held.
func _grab_pit(when: float) -> void:
	var best: Person = null
	var best_d := INF
	for e in ctx.field.in_radius(origin, lv_reach):
		var p := e as Person
		if p == null or p.inside or p.guised() or p.has_meta(&"decoy") or _caught.has(p.get_instance_id()):
			continue
		var d := p.ground_pos.distance_squared_to(origin)
		if d < best_d or (d == best_d and p.get_instance_id() < best.get_instance_id()):
			best_d = d
			best = p
	if best == null:
		return
	_caught[best.get_instance_id()] = true
	grabbed.append(best)
	best.hold_pace(get_instance_id(), 0.0)
	var rel := best.ground_pos - origin
	var to := origin + rel.limit_length(lv_edge)
	var drag := {"p": best, "from": best.ground_pos, "to": to, "at": when, "arm": null}
	if DominionParts.staged(self):
		var arm := Arm.new()
		arm.fx = self
		arm.born = when
		arm.facing = -1 if Iso.ground_to_screen(origin).x > Iso.ground_to_screen(best.ground_pos).x else 1
		arm.position = _arm_at(best.ground_pos)
		track(arm, stand_layer())
		drag["arm"] = arm
	_drags.append(drag)


## Every caught one is drawn toward the edge; at DRAG they go under. One who fell to something else first is let go.
func _drag() -> void:
	var still: Array[Dictionary] = []
	for d in _drags:
		# Untyped until checked: one who left the town (Crowd.escape) or was taken "gone" by another power is freed, and
		# assigning a freed one to a Person errors.
		var held = d.p
		var hand = d.arm
		var arm: Arm = hand if is_instance_valid(hand) else null
		if not is_instance_valid(held) or not (held as Person).is_alive() or (held as Person).inside:
			# Fallen to something else first, freed, or put indoors by the night (a shelter's count): the arm lets go.
			if is_instance_valid(held):
				(held as Person).free_pace(get_instance_id())
			if arm != null:
				arm.let_go(t)
			continue
		var p: Person = held
		var k := clampf((t - float(d.at)) / DRAG, 0.0, 1.0)
		p.ground_pos = (d.from as Vector2).lerp(d.to, k)
		p._sync_position()
		if arm != null and is_instance_valid(arm):
			arm.position = _arm_at(p.ground_pos)
		if k < 1.0:
			still.append(d)
			continue
		_take(p, arm, float(d.at) + DRAG)
	_drags = still


## Where an arm stands for one caught at `g` (screen): beside them on the pit's side, a pixel behind them in the stand layer's
## sort, so it grips them from the pit instead of hiding them.
func _arm_at(g: Vector2) -> Vector2:
	var sp := Iso.ground_to_screen(g)
	var side := (Iso.ground_to_screen(origin) - sp).normalized() * ARM_SIDE
	return (sp + side + Vector2(0, -1)).round()


## `p` is pulled under at the edge (their drag's end, `when`, on the pit's clock): a pit death (no body), one more soul.
func _take(p: Person, arm: Arm, when: float) -> void:
	p.free_pace(get_instance_id())
	if arm != null and is_instance_valid(arm):
		arm.let_go(t)
	if not ctx.field.kill(p, &"pit", origin):
		return
	souls += 1
	if souls == 1:
		first_soul_at = when
		if ctx.crowd != null:
			ctx.crowd.add_alarm(TAKE_ALARM)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(p.ground_pos)
	FxParts.smoke(self, sp, 6.0, 30.0, 0.3, Vector2(8, 20), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)
	FxParts.debris(self, sp, 5, 4.0, Vector2(20, 60), BONE_CHIPS, Vector2(1.0, 2.0), true)


## SPAN: the pit closes, and every soul it took climbs back out as a wraith: wraith k climbs out along its sector's
## middle and flies out along it to WRAITH_FAR, then hunts in its own sector (R35).
func _close() -> void:
	closed = true
	ctx.play(&"gatebelow_close", origin, 0.0)
	for g in graves:
		if is_instance_valid(g.arm):
			(g.arm as Arm).let_go(t)
	graves.clear()
	for k in souls:
		var sector := sector_of(k, souls, origin)
		var dir := Vector2.from_angle(sector.z + sector.w * 0.5)
		var w := DeathParts.wraith(visitors, origin + dir * WRAITH_SPREAD, sector, origin + dir * (lv_reach + 2.0))
		visitors.give(w, {"touches_most": lv_wraith_touches})
	if souls == 0:
		duration = t + CLOSE + 0.1
	if not DominionParts.staged(self):
		return
	if is_instance_valid(_light):
		_light.tween_param("intensity", LIGHT, 0.0, CLOSE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	var sp := Iso.ground_to_screen(origin)
	FxParts.smoke(self, sp, 50.0, 30.0, CLOSE, Vector2(8, 22), Vector2(3, 6), Vector2(0.8, 1.6), Color(0, 0, 0, 0), DUST)
	if souls > 0:
		var burst := FxParts.bloom(self, sp + Vector2(0, -10), 40.0, DeathParts.PALE_FIRE, 1.0, 0.6)
		burst.tween_param("intensity", 1.0, 0.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		burst.life = 0.85
		FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 8 + 4 * souls, PALE, Vector2(20, 90), Vector2(40, 140))
	if ctx.shake != null:
		ctx.shake.add_trauma(0.15)


## A wraith of this cast laid its withering on someone (the pack's bitten: emitted only for a curse laid).
func _on_withered(_wraith: Animal, _victim: Person, _first: bool) -> void:
	withered += 1


## A wraith of this cast was spent (its WRAITH_TOUCHES-th touch): staged, it goes in a pale puff, not a pop.
func _on_spent(_wraith: Animal, at: Vector2) -> void:
	if DominionParts.staged(self):
		_puff(at)


## WRAITH_LIFE after the close: the wraiths go back into the ground.
func _end_wraiths() -> void:
	_ended = true
	if DominionParts.staged(self):
		for a in visitors.living():
			_puff(a.ground_pos)
	visitors.recall(FADE)
	duration = t + FADE + 0.1


## A wraith's going (staged): a pale puff where it is.
func _puff(at: Vector2) -> void:
	FxParts.smoke(self, Iso.ground_to_screen(at), 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), PALE)


## Over or cut short: everyone still held is let go, the wraiths are gone.
func _finish() -> void:
	_let_all_go()
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): the same -- every hold let go, the wraiths gone -- the pack
## only queued for freeing (its parents may be mid-teardown). After _finish there is nothing left to do here.
func _exit_tree() -> void:
	_let_all_go()
	if visitors != null:
		visitors.clear(true)
	super()


## Every caught one still held is let go (a freed one is skipped: read untyped until checked).
func _let_all_go() -> void:
	for d in _drags:
		var held = d.p
		if is_instance_valid(held):
			(held as Person).free_pace(get_instance_id())
	_drags.clear()


## 0..1 how far open the pit is at `now`: out of a crack over T_OPEN, back into one over CLOSE from SPAN.
func open_k(now: float) -> float:
	if now < lv_span:
		return clampf(now / T_OPEN, 0.0, 1.0)
	return 1.0 - clampf((now - lv_span) / CLOSE, 0.0, 1.0)


## Wraith `k` of `n`'s sector (R35): (centre x, centre y, from angle, width) -- from 0.4 + TAU (k - 0.5) / n, TAU / n wide,
## so the n of them share the circle about `centre` evenly; one alone has the whole circle.
static func sector_of(k: int, n: int, centre: Vector2) -> Vector4:
	var m := maxi(n, 1)
	return Vector4(centre.x, centre.y, 0.4 + TAU * (float(k) - 0.5) / float(m), TAU / float(m))


## The rift's lip: RIFT_POINTS points about `centre`, at EDGE give or take JAG by a fixed hash of the index (no rng).
static func rift_points(centre: Vector2, edge := EDGE) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in RIFT_POINTS:
		var a := TAU * float(i) / float(RIFT_POINTS)
		out.append(centre + Vector2.from_angle(a) * edge * (1.0 + JAG * sin(float(i) * 2.3 + 0.7)))
	return out


## Where the ambient hands stand about `centre`: ARMS points on a golden-angle spiral, evenly spread over the whole ring,
## the first at ARM_IN and the last at REACH (the square root keeps the outer ring as full as the inner one).
static func arm_spots(centre: Vector2, reach := REACH) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in ARMS:
		var r := lerpf(ARM_IN, reach, sqrt(float(i) / float(ARMS - 1)))
		out.append(centre + Vector2.from_angle(float(i) * GOLDEN) * r)
	return out


## The cracks out of the lip: CRACKS jagged lines, each from inside the lip out to between 0.7 and 1 of PIT_R, in ground
## units about the middle.
static func crack_lines(edge := EDGE, pit_r := PIT_R) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for i in CRACKS:
		var a := TAU * (float(i) + 0.5) / float(CRACKS) + 0.3 * sin(float(i) * 1.7)
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal()
		var from := edge * 0.95
		var to := pit_r * (0.85 + 0.15 * sin(float(i) * 3.1 + 0.4))
		var line := PackedVector2Array()
		for j in 5:
			var k := float(j) / 4.0
			var wob := 0.0 if j == 0 else 0.14 * sin(float(i) * 5.3 + float(j) * 2.1)
			line.append(dir * lerpf(from, to, k) + side * wob)
		out.append(line)
	return out


## The rift: drawn on the ground layer in ground units about the cast point, so it lies flat and keeps its shape at every
## zoom. A lip of broken ground, the dark of the hole (deepest at its middle) edged by one faint grave-green pixel, hairline
## cracks out to PIT_R and chips of bone. It opens out of a slit (wide across the screen, thin down it) as the pit opens,
## its cracks running out with it, and closes back into one.
class Rift extends Node2D:
	var fx: TheGateBelowFx
	var _lip := PackedVector2Array()
	var _cracks: Array[PackedVector2Array] = []
	## Each chip: [where (ground units about the middle), its colour index, its length in PX].
	var _chips: Array = []

	func _ready() -> void:
		_lip = TheGateBelowFx.rift_points(Vector2.ZERO, fx.lv_edge)
		_cracks = TheGateBelowFx.crack_lines(fx.lv_edge, fx.lv_reach)
		for i in BONES:
			var a := float(i) * GOLDEN + 0.9
			var r := lerpf(fx.lv_edge * 1.15, fx.lv_reach, 0.5 + 0.5 * sin(float(i) * 4.7 + 1.3))
			_chips.append([Vector2.from_angle(a) * r, i % BONE_CHIPS.size(), 1.0 + float(i % 3)])

	func _process(_delta: float) -> void:
		queue_redraw()

	## `p` as the rift stands at openness `e`: along the screen's width it opens from 0.3 of its size, down it from 0.05.
	static func _at(p: Vector2, e: float) -> Vector2:
		var along := Vector2(1, -1).normalized()
		var across := Vector2(1, 1).normalized()
		return along * p.dot(along) * lerpf(0.3, 1.0, e) + across * p.dot(across) * lerpf(0.05, 1.0, e)

	func _draw() -> void:
		if not is_instance_valid(fx):
			return
		var k := fx.open_k(fx.t)
		if k <= 0.0:
			return
		var e := 1.0 - pow(1.0 - k, 3.0)
		var lip := PackedVector2Array()
		var hole := PackedVector2Array()
		var deep := PackedVector2Array()
		var edge := PackedVector2Array()
		for p in _lip:
			lip.append(_at(p * 1.1, e))
			hole.append(_at(p, e))
			deep.append(_at(p * 0.55, e))
			edge.append(_at(p * (1.0 - PX / fx.lv_edge), e))
		edge.append(edge[0])
		# The cracks first, under the lip, run out as it opens.
		for line in _cracks:
			var shown := PackedVector2Array()
			for j in line.size():
				if float(j) / float(line.size() - 1) > e + 0.001:
					break
				shown.append(_at(line[j], e))
			if shown.size() >= 2:
				draw_polyline(shown, Color(CRACK, CRACK.a * k), PX * 1.5)
		draw_colored_polygon(lip, Color(RIFT_LIP, RIFT_LIP.a * k))
		draw_colored_polygon(hole, Color(RIFT_DARK, RIFT_DARK.a * k))
		draw_colored_polygon(deep, Color(RIFT_DEEP, RIFT_DEEP.a * k))
		draw_polyline(edge, Color(DeathParts.GRAVE_GREEN, 0.35 * k), PX)
		# The bone thrown out of the hole: a chip shows once the opening has reached it.
		var reach := fx.lv_edge * 1.15 + (fx.lv_reach - fx.lv_edge * 1.15) * e
		for c in _chips:
			var at: Vector2 = c[0]
			if at.length() > reach:
				continue
			var col: Color = BONE_CHIPS[c[1]]
			var size := Vector2(PX * float(c[2]), PX)
			# A pixel of shadow under each (down the screen is ground (1, 1)), so it reads on pale paving too.
			draw_rect(Rect2(at + Vector2(PX, PX) * 0.7, size), Color(CRACK, 0.6 * k))
			draw_rect(Rect2(at, size), Color(col, col.a * k))


## One grasping hand (grave_hand sheet) at a caught one's feet: it rises out of the ground, grips while they are dragged, then
## pulls down as they go under, and sinks back in. Stands in the effect's y-sorted stand layer, just in front of its victim.
## A `loop` arm is one of the ambient arms reaching up all over the reach: from `born` (T_OPEN), after its `phase` (folded
## into one loop, so every arm is up within ARM_LOOP), it rises, claws and sinks over ARM_LOOP again and again; with the
## close it sinks into the ground over CLOSE and is gone.
class Arm extends Node2D:
	var fx: TheGateBelowFx
	## When it reached out (the grab's tick), and when it began pulling down (-1: still gripping).
	var born := 0.0
	var pull_at := -1.0
	## An ambient arm: looping, its loop offset by `phase` seconds.
	var loop := false
	var phase := 0.0
	## 1, or -1 to mirror it (it leans toward the pit).
	var facing := 1
	var _tex: Texture2D

	func _ready() -> void:
		if ResourceLoader.exists(ARM_SHEET):
			_tex = load(ARM_SHEET)

	## The victim is under (or gone): the arm pulls down from `now`.
	func let_go(now: float) -> void:
		if pull_at < 0.0:
			pull_at = now

	func _process(_delta: float) -> void:
		if not is_instance_valid(fx):
			return
		if (pull_at >= 0.0 and fx.t > pull_at + ARM_PULL + ARM_SINK) or (loop and fx.t > fx.lv_span + CLOSE):
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if _tex == null or not is_instance_valid(fx):
			return
		if loop:
			_draw_loop()
			return
		var u := fx.t - born
		var frame := 2 + int(u / 0.15) % 2  # the grip, clenching
		var shown := 1.0  # the share of the arm above the ground
		if u < ARM_RISE:
			frame = 0 if u < ARM_RISE * 0.5 else 1
			shown = clampf(u / ARM_RISE, 0.0, 1.0)
		if pull_at >= 0.0:
			var v := fx.t - pull_at
			frame = 4 if v < ARM_PULL * 0.5 else 5
			if v >= ARM_PULL:
				shown = 1.0 - clampf((v - ARM_PULL) / ARM_SINK, 0.0, 1.0)
		_draw_frame(frame, shown)

	## An ambient arm's moment in its loop: up over ARM_RISE, clawing, then the pull down and the sink, all over ARM_LOOP;
	## from SPAN it goes down with the rift over CLOSE.
	func _draw_loop() -> void:
		var u := fx.t - born - fposmod(phase, ARM_LOOP)
		if u < 0.0:
			return
		var v := fposmod(u, ARM_LOOP)
		var claw_end := ARM_LOOP - ARM_PULL - ARM_SINK
		var frame := 2 + int(v / 0.15) % 2  # the claw, clenching
		var shown := 1.0
		if v < ARM_RISE:
			frame = 0 if v < ARM_RISE * 0.5 else 1
			shown = v / ARM_RISE
		elif v >= claw_end:
			var w := v - claw_end
			frame = 4 if w < ARM_PULL * 0.5 else 5
			if w >= ARM_PULL:
				shown = 1.0 - clampf((w - ARM_PULL) / ARM_SINK, 0.0, 1.0)
		if fx.t >= fx.lv_span:
			shown *= fx.open_k(fx.t)
		_draw_frame(frame, shown)

	## Frame `frame` of the sheet, `shown` (0..1) of it out of the ground above its foot.
	func _draw_frame(frame: int, shown: float) -> void:
		if shown <= 0.0:
			return
		var rows := ARM_FOOT.y * shown  # rows of the cell above its foot line still out of the ground
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(ARM_SCALE * float(facing), ARM_SCALE))
		draw_texture_rect_region(_tex, Rect2(-ARM_FOOT.x, -rows, ARM_CELL.x, rows),
			Rect2(frame * ARM_CELL.x, ARM_FOOT.y - rows, ARM_CELL.x, rows))
		draw_set_transform(Vector2.ZERO)
