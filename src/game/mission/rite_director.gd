class_name RiteDirector
extends MissionDirector
## The Awakening rite's base (god P3, mission spec MS §1 "Director", §2, §3.6; plan Task 3): the shrine and its flame, the shard count, the marked
## victims, and Chain of the Forgotten -- the free power the rite grants on key C. One chain at a time takes one marked victim anywhere on the map:
## he kneels for BITE seconds ("the chain bites") and is then dragged on foot along the walk grid's path to Mira's shrine at a pace that keeps
## every drag to DRAG_MAX seconds or less. A BREAKER -- the subclass's list: the Watch, the clergy marchers -- who reaches him (GRIP_REACH) grips
## the chain; a full ring (BREAK_SECONDS) frees him and he runs for the Temple. A breaker the god holds, frightens, wounds with Death Mark or binds
## with a Leaving Is Prohibited law, or one a Yank stuns, grips nothing, and his grip resets. At the shrine (SHRINE_REACH) the captive dies on its
## stone: one shard, the flame grows a step, and the subclass answers (_answer(): Halcyon's clergy march). Only the director's own breakers ever grip
## (MS §0 "no luck": the town's soldiers, the rally and street traffic never do). Every timer runs in real seconds (R5: a toll never shortens a warning).
## It reads no input: Mission and the HUD call chain_key(), chain_at() and yank(); the scripted player and FLOW call chain() and offer(). A rite
## subclasses it and fills the virtuals (FirstTasteDirector).

## Mira's shrine (VigilFlameDirector's), how near the captive must come to be sacrificed on it, and its stone's height / one flame step (world
## pixels, the shrine tag's `rise`: the flame grows one step per shard, P3-14).
const SHRINE := VigilFlameDirector.MIRA_SHRINE
const SHRINE_REACH := VigilFlameDirector.SHRINE_REACH
const FLAME_RISE := 14.0
const FLAME_STEP := 8.0
## Seconds before the chain is ready again after one ends (sacrificed, freed or died); MS §2, *fg* (a rule, not a tuning knob: MS §6 pacing).
const COOLDOWN := 8.0
## How long the captive kneels as the chain bites, the longest a drag may take, and the slowest he is dragged (units a second).
const BITE := 1.0
const DRAG_MAX := 55.0
const PACE_MIN := 0.6
## How far a breaker sees a captive (EscortDirector.SIGHT) and how near he must come to grip (EscortDirector.TAKE_REACH).
const SIGHT := EscortDirector.SIGHT
const GRIP_REACH := EscortDirector.TAKE_REACH
## Seconds of grip that break the chain (*fg*; Task 7 may tune 3 -> 4).
const BREAK_SECONDS := 3.0
## The Yank (MS §2, R9): C again in a drag lurches the captive YANK_STEP units on along his path, resets a grip and stuns its breaker YANK_STUN
## seconds; YANKS a drag (Task 7 may set 0).
const YANK_STEP := 1.5
const YANK_STUN := 1.0
const YANKS := 1
## How near the clicked ground a marked victim must stand to be taken (*my call*), and the seconds between sight checks (the bite, the drag, the grip and
## the cooldown advance every frame).
const PICK_R := 1.0
const TICK := 0.25
## A captive who stands still this long (seconds) within this many units, ungripped, is let go of (_check_stuck()): no way to the shrine from where he is. (A man
## held in a gate's queue behind a jammed gate would be freed too; no Tier 1 power does that.)
const STUCK_SECONDS := 8.0
const STUCK_STEP := 0.3
## A freed captive, running for the Temple's door, is safe within this of it (MS §2).
const SAFE_REACH := 1.0
## How far a person stands from where the drag left him before the director sets him back on it, and how long past each frame a captive is kept
## shaking off a whisper and past fear (more than a frame, so neither lapses between looks).
const MOVE := 0.3
const HOLD := 1.0
## The map tags' colours: a marked victim and his captive gold, the shrine orange (G7: AssassinateDirector.MARK_PLACE's).
const MARK_VICTIM := Color("e8c24a")
const MARK_SHRINE := Color("ff9a3a")

## The words: refusals, banners and tags. The spec's strings are exact; the rest are *my call* (the plan's list).
const NOT_VICTIM := "NOT A %s"
const ONE_CHAIN := "ONE CHAIN AT A TIME"
const NOT_READY := "THE CHAIN IS NOT READY"
const YANK_USED := "THE CHAIN HAS PULLED ONCE"
const CANT_REACH := "THE CHAIN CANNOT REACH HIM"
const SHARD_BANNER := "%s  %d/%d"
const FREED_BANNER := "THE CHAIN BREAKS"
const LOST_BANNER := "THE CAPTIVE IS LOST"
const SHRINE_TAG := "MIRA'S SHRINE  %d/%d"
const CAPTIVE_TAG := "CAPTIVE - SHRINE IN %s"

## The chain's four states: ready, the captive kneeling as it bites, the drag, and the cooldown after.
enum Chain { READY, BITE, DRAG, COOLDOWN }

var chain_state := Chain.READY
## The chained victim (null while READY or in COOLDOWN). A Variant would guard a freed body; every use goes through _alive().
var captive: Person
## How many shards the shrine has taken.
var shards := 0
## The marked victims still in the rite (alive ones; the dead are dropped at each look) and the ones who reached the Temple's door (safe, unmarked).
var marked: Array[Person] = []
var safe: Array[Person] = []
## The breaker gripping the chain, the seconds he has held it and the Yanks left this drag.
var grip_by: Person
var grip := 0.0
var yanks_left := 0
## Seconds until the chain is ready again (COOLDOWN).
var cooldown_left := 0.0
## The shrine's flame has been put out (the clergy's cleanse): a subclass sets it and RiteFlameObjective fails the night with it.
var flame_out := false

## The shrine on walkable ground, set in _begin().
var _shrine := Vector2.ZERO
## Seconds of the bite left; the captive's drag pace (units a second, set once at the bite: R6) and the person's own pace before it.
var _bite_left := 0.0
var _speed := PACE_MIN
## The path length the drag was begun on (the bite's countdown reads it).
var _way := 0.0
var _pace_before := 1.0
## The captive is held still by a grip.
var _stopped := false
## Freed victims running for the Temple's door.
var _runners: Array[Person] = []
## Breakers a Yank has stunned: Person -> seconds left.
var _stunned := {}
var _tick_in := 0.0
## Seconds until a captive whose walk found no way tries again (_step_drag()), and how long he has stood within STUCK_STEP of `_still_at` ungripped.
var _repath_in := 0.0
## Victims _check_stuck() let go of because no way led from where they stood: not counted by left() until chained again (Task 7 review I4).
var _stranded: Array = []
var _still := 0.0
var _still_at := Vector2.INF
var _need := -1


# --- The rite's data (virtuals) ----------------------------------------------------------------

## Virtual: the rite's id in RiteBook ("" in the base).
func rite_id() -> String:
	return ""


## Virtual: the victims' word in upper case, as the tag and the refusal read it ("LAMPLIGHTER").
func victim_word() -> String:
	return "VICTIM"


## Virtual: the people marked at the start of the night (never reserved ones: _eligible()); they are on their errand from 0:00.
func _appoint_victims() -> Array[Person]:
	var out: Array[Person] = []
	return out


## Virtual: who can break a chain now (the Watch, the clergy marching). Only these ever grip (MS §0, P3-11).
func _breakers() -> Array[Person]:
	var out: Array[Person] = []
	return out


## Virtual: where breaker `b` stands when no captive is in sight.
func _post_of(b: Person) -> Vector2:
	return b.ground_pos


## Virtual: breaker `b` walks to the captive at `at`. A soldier of the Watch goes on duty there; a subclass whose breakers keep their own
## errand (marchers) overrides.
func _go_grip(b: Person, at: Vector2) -> void:
	b.go_duty(at)


## Virtual: breaker `b` has no captive in sight and goes back to his post. Skipped for a held breaker (R5): his hold ends by itself.
func _go_back(b: Person) -> void:
	b.send_to_post(_post_of(b))


## Virtual: halcyon's answer after shard `shard` has been sacrificed (a clergy march). Nothing in the base.
func _answer(_shard: int) -> void:
	pass


## Virtual: a new victim sets out because too few are left (MS §3.6); it appends to `marked` through _mark().
func _replace() -> void:
	pass


## Virtual: everyone the director keeps at his errand through an evacuation (MS §0): the victims, the breakers and the captive. A subclass adds
## its marchers and musterers.
func _held_people() -> Array:
	var out: Array = marked.duplicate()
	out.append_array(_breakers())
	out.append(captive)
	return out


# --- Set up ------------------------------------------------------------------------------------

## The shrine on walkable ground, then the subclass's victims marked.
func _begin() -> void:
	_shrine = _walkable(SHRINE)
	for v in _appoint_victims():
		_mark(v)


## `v` is marked for the chain (a new lamplighter added by _replace()).
func _mark(v: Person) -> void:
	if v != null and not marked.has(v):
		marked.append(v)


## How many shards win the rite (the RiteBook row's), 3 for a rite without one.
func need() -> int:
	if _need < 0:
		_need = int(RiteBook.row(rite_id()).get("shards", 3))
	return _need


## The shrine on walkable ground.
func shrine() -> Vector2:
	return _shrine


# --- What the objectives and the HUD read --------------------------------------------------------

## The shards are in (StagesObjective's win).
func stages_done() -> bool:
	return shards >= need()


## The night is never lost by the main objective itself: the flame's loss is its own objective (P3-10).
func lost_reason() -> String:
	return ""


## The main objective's row.
func hud_line() -> String:
	return "Lantern shards %d/%d" % [shards, need()]


## The rite's part of the results: its id, the shards and whether the flame went out (GodNight.bank reads the shards).
func report() -> Dictionary:
	return {"rite": {"id": rite_id(), "shards": shards, "need": need(), "flame_out": flame_out}}


## A person of the rite whom the Lantern-Bearer and his escorts must not take from his errand (G3): a marked victim, the captive or a breaker.
func busy(p: Person) -> bool:
	return marked.has(p) or p == captive or _breakers().has(p)


## `p` is on the chain's errand -- the captive, or a freed victim running for the Temple -- and so is not on his round: a subclass's round skips him.
func claimed(p: Person) -> bool:
	return p == captive or _runners.has(p)


# --- The chain's keys --------------------------------------------------------------------------

## C was pressed: "aim" when the chain is ready (the caller begins an aim), "yank" after a Yank in a drag (done here), else the words of the refusal.
func chain_key() -> String:
	match chain_state:
		Chain.READY:
			return "aim"
		Chain.BITE:
			return ONE_CHAIN
		Chain.DRAG:
			if yank():
				return "yank"
			return YANK_USED if YANKS > 0 else ONE_CHAIN
		_:
			return NOT_READY


## The aim was clicked on `ground`: the marked victim nearest within PICK_R is chained ("" on success, else the refusal); none there is NOT_VICTIM.
func chain_at(ground: Vector2) -> String:
	var best: Person = null
	for w: Variant in marked:
		if not _alive(w) or (w as Person).inside or w == captive:
			continue
		var v := w as Person
		var d := v.ground_pos.distance_to(ground)
		if d <= PICK_R and (best == null or d < best.ground_pos.distance_to(ground)):
			best = v
	if best == null:
		return NOT_VICTIM % victim_word()
	return chain(best)


## Chain `p` (a marked victim, anywhere on the map, panicking or not): "" on success, else the refusal. Quiet: no alarm, no danger.
func chain(p: Person) -> String:
	if chain_state == Chain.COOLDOWN:
		return NOT_READY
	if chain_state != Chain.READY:
		return ONE_CHAIN
	if not marked.has(p):
		return NOT_VICTIM % victim_word()
	if not _alive(p) or p.inside:
		return CANT_REACH
	var way := _path_length(p.ground_pos)
	if way < 0.0:
		return CANT_REACH
	captive = p
	_runners.erase(p)
	_stranded.erase(p)
	p.chained = true
	_way = way
	_speed = drag_pace(way)
	_pace_before = p.pace
	p.pace = _speed / Person.PANIC_SPEED
	grip = 0.0
	grip_by = null
	_stopped = false
	_still = 0.0
	_still_at = Vector2.INF
	yanks_left = YANKS
	chain_state = Chain.BITE
	_bite_left = BITE
	_hold_captive(p)
	p.compel(p.ground_pos, BITE + TICK, 0.5, MARK_VICTIM, false, &"kneel")
	_clear_walk(p)
	return ""


## How fast a captive is dragged (units a second) along a path `path_len` long: the pace that takes DRAG_MAX seconds, never under PACE_MIN, so
## every drag is DRAG_MAX seconds or less (MS §2) -- at full speed: a power that slows him (Death Mark's slow, Pestilence) lengthens it, and the god chose that.
static func drag_pace(path_len: float) -> float:
	return maxf(PACE_MIN, path_len / DRAG_MAX)


## The Yank (MS §2, R9): in a drag with one left, the captive lurches YANK_STEP on along his path, a grip resets and its breaker stands stunned
## YANK_STUN seconds. False when there is no drag or no Yank left.
func yank() -> bool:
	if chain_state != Chain.DRAG or yanks_left <= 0 or not _alive(captive):
		return false
	yanks_left -= 1
	var way := crowd._grid.path(captive.ground_pos, _shrine)
	var at := captive.ground_pos
	var rest := YANK_STEP
	for i in way.size():
		var seg := at.distance_to(way[i])
		if seg >= rest:
			at = at.move_toward(way[i], rest)
			rest = 0.0
			break
		rest -= seg
		at = way[i]
	if grip_by != null and _alive(grip_by):
		_stunned[grip_by] = YANK_STUN
		grip_by.stun(YANK_STUN)
	grip = 0.0
	grip_by = null
	captive.fold(at)
	if _stopped:
		_resume()
	return true


## Seconds of the drag left at his pace (the bite counts in full before it starts); 0 with no captive.
func drag_eta() -> float:
	if not _alive(captive):
		return 0.0
	return (_way if chain_state == Chain.BITE else _remaining()) / maxf(_speed, 0.05)


## The chain plate's words: READY, DRAG with the seconds left, or the cooldown's clock.
func chain_plate() -> String:
	match chain_state:
		Chain.READY:
			return "READY"
		Chain.BITE, Chain.DRAG:
			return "DRAG %s" % UiTheme.clock(drag_eta())
		_:
			return UiTheme.clock(cooldown_left)


## The captive is sacrificed on the shrine's stone (a captive within SHRINE_REACH, or a test or FLOW hook on any marked victim): he dies, a shard
## is won, the flame grows a step, the subclass answers, and the chain (if he was its captive) goes to its cooldown. False when `p` is not a living
## marked victim. Quiet (MS §2 "Noise: Quiet: no alarm"; review Ruling): he is killed with Person.die(), not EnemyField.kill(), so no enemy_killed
## is emitted -- the crowd counts no kill, raises no incident and hears no alarm, and the town's soldiers are never drawn to the shrine (MS §0, no luck).
func offer(p: Person) -> bool:
	if not _alive(p) or not marked.has(p):
		return false
	var was_captive := p == captive
	if was_captive:
		_release(p)
		_end_chain()
	marked.erase(p)
	_runners.erase(p)
	p.die(&"rite", _shrine)
	shards += 1
	rules.banner.emit(SHARD_BANNER % [String(RiteBook.row(rite_id()).get("name", "THE RITE")).to_upper(), shards, need()])
	_answer(shards)
	return true


# --- Breakers ----------------------------------------------------------------------------------

## Breaker `b` cannot grip now (MS §2, P3-11): dead or freed, indoors, held by the god (Whisper, Discord, The Bell Lies' call, a lure), wounded with
## Death Mark (frail), bound by a Leaving Is Prohibited law (B5: its bars are over his head), frightened, fighting, down or frozen, or stunned by a Yank.
func held(b: Variant) -> bool:
	if not _alive(b):
		return true
	var p := b as Person
	if p.inside or p.held_by_god() or p.statuses.has(&"frail") or p.is_down() or p.is_frozen():
		return true
	if p.badge_glyph == DecreeParts.BARS and p.badge_left > 0.0:
		return true
	if p.mind == Person.Mind.PANIC or p.mind == Person.Mind.FLEE or p.mind == Person.Mind.SHELTER or p.mind == Person.Mind.FIGHT:
		return true
	return float(_stunned.get(p, 0.0)) > 0.0


## Breaker `b` is on the director's errand and looking: not held, and at a post or on duty -- never taken by the rally, a marshal's post or a fight
## (MS §0 "no luck").
func _active(b: Variant) -> bool:
	return not held(b) and ((b as Person).mind == Person.Mind.DUTY or (b as Person).mind in EscortDirector.POST_MINDS)


## The breaker gripping the captive now, or null: the one already gripping while he still can, else the nearest active one within GRIP_REACH.
func _gripper() -> Person:
	if grip_by != null and _alive(grip_by) and _active(grip_by) and grip_by.ground_pos.distance_to(captive.ground_pos) <= GRIP_REACH:
		return grip_by
	var best: Person = null
	for w: Variant in _breakers():
		if not _alive(w) or not _active(w):
			continue
		var b := w as Person
		var d := b.ground_pos.distance_to(captive.ground_pos)
		if d <= GRIP_REACH and (best == null or d < best.ground_pos.distance_to(captive.ground_pos)):
			best = b
	return best


# --- Each frame ----------------------------------------------------------------------------------

## One frame: the Yank stuns tick down, the chain's state advances (the bite, the drag and its grip, the cooldown), and every TICK a look.
func step(delta: float) -> void:
	for k in _stunned.keys():
		if not is_instance_valid(k):
			_stunned.erase(k)
			continue
		_stunned[k] = float(_stunned[k]) - delta
		if float(_stunned[k]) <= 0.0:
			_stunned.erase(k)
	match chain_state:
		Chain.BITE:
			_step_bite(delta)
		Chain.DRAG:
			_step_drag(delta)
		Chain.COOLDOWN:
			cooldown_left -= delta
			if cooldown_left <= 0.0:
				cooldown_left = 0.0
				chain_state = Chain.READY
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	_look()


## The captive kneels; when the bite is over the drag begins.
func _step_bite(delta: float) -> void:
	if not _alive(captive):
		_wasted()
		return
	_hold_captive(captive)
	_bite_left -= delta
	if _bite_left > 0.0:
		return
	chain_state = Chain.DRAG
	captive.go_duty(_shrine)


## One frame of the drag: the sacrifice at the shrine, the grip, and the walk kept on (a whisper and fear shaken off, Discord not letting him wander).
func _step_drag(delta: float) -> void:
	if not _alive(captive):
		_wasted()
		return
	_hold_captive(captive)
	if captive.ground_pos.distance_to(_shrine) <= SHRINE_REACH:
		offer(captive)
		return
	var by := _gripper()
	if by == null:
		grip = 0.0
		grip_by = null
		if _stopped:
			_resume()
		elif captive.mind != Person.Mind.DUTY or captive.anchor.distance_to(_shrine) > MOVE:
			captive.go_duty(_shrine)
		elif not captive.has_goal():
			# A walk that found no way (a Thornwall grown across his lane, a jam) leaves him with no goal for good; try again every TICK, so a wall that
			# withers lets the drag go on instead of leaving the chain stuck in its drag until dawn (found by Task 7's scripted Passage).
			_repath_in -= delta
			if _repath_in <= 0.0:
				_repath_in = TICK
				captive.go_duty(_shrine)
		_check_stuck(delta)
		return
	_still = 0.0
	_still_at = captive.ground_pos
	if by != grip_by:
		grip_by = by
		grip = 0.0
	if not _stopped or captive.mind != Person.Mind.DUTY:
		_stopped = true
		_stand(captive)
	grip += delta
	if grip >= BREAK_SECONDS:
		_break()


## A captive who has not moved STUCK_STEP in STUCK_SECONDS while no one grips him has no way to the shrine (a Mirrorfold set him down in a closed
## pocket, a wall that does not wither): the chain lets go of him like a broken one, so the night is never left with a chain stuck in its drag until
## dawn (MS §3.6 "never a dead end"; found by Task 7's scripted Passage).
func _check_stuck(delta: float) -> void:
	if captive.ground_pos.distance_to(_still_at) > STUCK_STEP:
		_still_at = captive.ground_pos
		_still = 0.0
		return
	_still += delta
	if _still >= STUCK_SECONDS:
		_still = 0.0
		_stranded.append(captive)
		_break()


## The captive holds still where he stands (a grip).
func _resume() -> void:
	_stopped = false
	captive.go_duty(_shrine)


## `p` stands where he is: on duty at his own feet, with no walk to the nearest cell's centre.
func _stand(p: Person) -> void:
	p.go_duty(p.ground_pos)
	_clear_walk(p)


## `p` has no walk to make: no goal, no path, his target his own feet.
func _clear_walk(p: Person) -> void:
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._leg = 0
	p._target = p.ground_pos


## Keeps the captive shaking off a whisper and past fear this frame (P3-13: as EscortDirector's bound charge).
func _hold_captive(p: Person) -> void:
	p._shaken_left = maxf(p._shaken_left, HOLD)
	p.fearless_left = maxf(p.fearless_left, HOLD)


## The ring is full: the chain breaks, the captive runs for the Temple's door, still marked, and the chain cools down.
func _break() -> void:
	var p := captive
	_release(p)
	_end_chain()
	rules.banner.emit(FREED_BANNER)
	_runners.append(p)
	p.go_duty(lantern_door())


## The chain lets go of `p`: the flag, the holds and the pace he had.
func _release(p: Person) -> void:
	if not is_instance_valid(p):
		return
	p.chained = false
	p.pace = _pace_before
	p._shaken_left = 0.0
	if p.fearless_left <= HOLD:
		p.fearless_left = 0.0  # (only what _hold_captive() laid: a longer fearless from a Reassure stays)


## The chain ends (sacrificed, freed or died): the captive is let go of and the cooldown begins.
func _end_chain() -> void:
	captive = null
	grip_by = null
	grip = 0.0
	_stopped = false
	chain_state = Chain.COOLDOWN
	cooldown_left = COOLDOWN


## The captive died away from the shrine (any cause): wasted, never a loss; the chain cools down.
func _wasted() -> void:
	captive = null
	_end_chain()
	rules.banner.emit(LOST_BANNER)


## The path length from `at` to the shrine in units, -1 when there is no way (a victim walled in).
func _path_length(at: Vector2) -> float:
	if at.distance_to(_shrine) <= SHRINE_REACH:
		return at.distance_to(_shrine)
	var way := crowd._grid.path(at, _shrine)
	if way.is_empty():
		return -1.0
	var total := 0.0
	var from := at
	for pt in way:
		total += from.distance_to(pt)
		from = pt
	return total + from.distance_to(_shrine)


## The units the captive still has to walk: along the path he is on, else straight.
func _remaining() -> float:
	var p := captive
	if p.has_goal() and p._leg < p._path.size():
		var rest := 0.0
		var from := p.ground_pos
		for i in range(p._leg, p._path.size()):
			rest += from.distance_to(p._path[i])
			from = p._path[i]
		return rest + from.distance_to(_shrine)
	return p.ground_pos.distance_to(_shrine)


# --- Each look (every TICK) ----------------------------------------------------------------------

## Every TICK: the director's people kept at their errands through an evacuation, the freed and the dead dropped (a body may be freed: Variants
## throughout), the runners and the breakers looked at, the replacement rule.
func _look() -> void:
	_hold_all(_held_people(), _evacuation_began())
	marked.assign(marked.filter(func(v: Variant) -> bool: return _alive(v)))
	_runners.assign(_runners.filter(func(v: Variant) -> bool: return _alive(v)))
	_step_runners()
	_step_breakers()
	_replace_if_short()


## Freed victims run on for the Temple's door; one who gets there is safe and unmarked (MS §2).
func _step_runners() -> void:
	var door := lantern_door()
	for w: Variant in _runners.duplicate():
		var p := w as Person
		if p.ground_pos.distance_to(door) <= SAFE_REACH:
			_runners.erase(p)
			marked.erase(p)
			safe.append(p)
			crowd.off_duty(p)
		else:
			_recall_to(p, door)


## A breaker within SIGHT of the captive walks to him; with none in sight he goes back to his post. A held one is left to his hold (R5).
func _step_breakers() -> void:
	var seen := _alive(captive) and chain_state != Chain.COOLDOWN
	for w: Variant in _breakers():
		if not _alive(w) or not _active(w):
			continue
		var b := w as Person
		if seen and b.ground_pos.distance_to(captive.ground_pos) <= SIGHT:
			if b.anchor.distance_to(captive.ground_pos) > MOVE * 2.0:
				_go_grip(b, captive.ground_pos)
		elif b.anchor.distance_to(_post_of(b)) > MOVE:
			_go_back(b)


## MS §3.6: fewer marked victims left (alive, not safe) than the shards still needed + 1, and a new one sets out.
func _replace_if_short() -> void:
	var tries := 3
	while tries > 0 and left() < need() - shards + 1:
		var before := left()
		_replace()
		tries -= 1
		if left() <= before:
			break


## The marked victims still in play: alive, not safe, and not stranded (the captive counts). A man _check_stuck() freed from a pocket is no victim the
## night can use, so the replacement rule (MS §3.6 "never a dead end") sends another.
func left() -> int:
	var n := 0
	for v: Variant in marked:
		if _alive(v) and not safe.has(v) and not _stranded.has(v):
			n += 1
	return n


# --- Tags ----------------------------------------------------------------------------------------

## Each marked victim (gold, edge-arrowed, with a gold pip for his lantern), the captive (his countdown, the grip's ring) and the shrine (orange,
## its flame one step higher per shard). The captive and the shrine first.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if _alive(captive):
		var c := MapTag.person(captive.ground_pos, MARK_VICTIM, CAPTIVE_TAG % UiTheme.clock(drag_eta()), true)
		if grip_by != null:
			c.ring = clampf(grip / BREAK_SECONDS, 0.0, 1.0)
		out.append(c)
	var rise := 0.0 if flame_out else FLAME_RISE + FLAME_STEP * float(shards)
	out.append(MapTag.place(_shrine, MARK_SHRINE, SHRINE_TAG % [shards, need()], rise, true))
	for w: Variant in marked:
		if not _alive(w) or w == captive or (w as Person).inside:
			continue
		var v := w as Person
		out.append(MapTag.person(v.ground_pos, MARK_VICTIM, victim_word(), true))
		var pip := MapTag.pip(v.ground_pos, MARK_VICTIM)
		pip.lift = 8.0
		out.append(pip)
	return out


## Lets the captive and the runners go (their flags and pace); a freed body is passed over.
func teardown() -> void:
	if is_instance_valid(captive):
		_release(captive)
	for p: Variant in _runners:
		if is_instance_valid(p):
			(p as Person).chained = false
	captive = null
	grip_by = null
