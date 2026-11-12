class_name RaiseTheDeadFx
extends FxTimeline
## Raise the Dead (Death, Tier I; spec 5.1): a click on a body -- the nearest remain within Remains.PICK_R (Rules refuses a click
## with none, "NO DEAD THERE", before any cooldown). Q and E pick what rises (extra["mode"]):
##
## ZOMBIE: the grave breathes over T_RISE, then the body gets up where it lay (DeathParts.zombie(): its own people sprite,
##   greyed, shambling at 0.6 of a walk, eyes alight). It hunts the nearest living within SEEK; a citizen's first bite knocks
##   them down, a second within 3 s kills (frenzy). Whoever it kills gets up as another (DeathParts.on_kill_rise()), CHAIN
##   raised in all by the cast. A soldier cuts one down in DeathParts.ZOMBIE_BLOWS (3) blows. A plague body's zombie infects
##   with its bites. The town panics at its first bite as at a hellhound's. At ZOMBIE_LIFE every one still up falls to ash.
## SPIRIT (needs a soul: a remain under Remains.SOUL old; else "THE SOUL HAS GONE"): the soul rises as a pale spirit
##   (DeathParts.spirit()) for SPIRIT_LIFE, through walls, never cut down. Everyone within FRIGHT_R flees it (Visitors
##   fright_r), and it drifts after the nearest group: the people within GROUP_R of the nearest living person within SEEK,
##   looked for again every DRIFT_LOOK. While it lives and has hosts left, the slot's click is a follow-up through Mind Whisper's
##   wheel (follow_up_wheel()): a press on a person within POSSESS_R of the spirit (measured from the spirit, follow_up_from())
##   possesses them -- the spirit goes into them and they obey one Mind Whisper order (MindWhisperFx.order()) for POSSESS: a
##   walk (at most POSSESS_R), an attack, or a burn (at the building's edge, the match struck MindWhisperFx.BURN_SECS after
##   getting there, as Mind Whisper's own burn). Their eyes glow grave green; no shake-off after (hold_string()). Then the
##   spirit comes out of them where they stand -- a burn when the match is struck -- and may possess again, HOSTS in all.
##   Someone who cannot hear (dead, indoors, a mind that resists, still shaking a whisper off) or who stands more than
##   POSSESS_R from the spirit when the follow-up comes is refused: follow_up() is false, the HUD says "missed", nothing spent.
## The remain is used up at the cast (Remains.take()); a raised body stays dead -- the zombie is a Visitor, never the Person.
## Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead stand.

## The grave breathes, and the dead stand at T_RISE.
const T_RISE := 0.8
## ZOMBIE: how long the risen stand, how many rise in all (the first and its kills'), how far they look for the living.
## (SEEK is DeathParts.ZOMBIE_SEEK: the zombie the kit makes hunts that far.)
const ZOMBIE_LIFE := 30.0
const CHAIN := 3
const SEEK := 10.0
## SPIRIT: how long it stays, how far its fright reaches, how far from it a host may stand, how long a possession holds, how
## many it may take.
const SPIRIT_LIFE := 20.0
const FRIGHT_R := 3.0
const POSSESS_R := 4.0
const POSSESS := 5.0
const HOSTS := 3
## The spirit drifts after the people within GROUP_R of the nearest living one, looked for again every DRIFT_LOOK.
const GROUP_R := 2.5
const DRIFT_LOOK := 0.5
## At the end the risen fall to ash over FADE.
const FADE := 0.6
## The first bite's outcry: how far the town's fright reaches and the alarm it adds (Hound Gate's).
const BITE_FRIGHT_R := 2.0
const BITE_ALARM := 0.6
## Ash and bone dust, a cold grave light (Death's palette: bone white, ash grey, pale-white fire; grave green for glows only).
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
const PALE := [Color("eaf4ff"), Color("c8f0dc"), Color(0.5, 0.9, 0.7, 0.5), Color(0.2, 0.4, 0.35, 0.0)]

## The risen, how many rose, the spirit (null in ZOMBIE), its host now (null when none), the hosts it may still take, and
## whether it drifts (a test pins it to stand).
var visitors: Visitors
var raised := 0
var spirit: Animal
var host: Person
var hosts_left := HOSTS
var drift := true

var _remain: Remains.Remain
var _spirit_mode := false
## How many more of the zombies' kills may rise.
var _left := CHAIN - 1
var _bitten := false
## The possession: when it began, the order and what it is set on, the spot it was whispered to, when a burn got there.
var _since := 0.0
var _order := ""
var _foe: Person
var _building: Structure
var _to := Vector2.INF
var _arrived := -1.0
var _drift_to := Vector2.INF
var _look_in := 0.0
var _eyes: HostEyes
var _light: QuadFx
## Whether the spirit is in a host now: set with `host`, but kept apart from it -- a host freed meanwhile (they left the town)
## cannot be read, and `host != null` cannot be trusted to tell; _leave() lets go of what is left.
var _riding := false


func _build() -> void:
	_spirit_mode = String(extra.get("mode", "zombie")) == "spirit"
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	_remain = rem.pick(origin, _spirit_mode) if rem != null else null
	if _remain == null:
		duration = 0.1  # no body (or no soul) there: Rules refuses such a click before it comes here
		return
	rem.take(_remain)
	duration = (SPIRIT_LIFE if _spirit_mode else ZOMBIE_LIFE) + FADE
	busy = T_RISE
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, ctx.crowd._grid, parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	at(T_RISE, _rise)
	at(duration - FADE, _end_life)
	if _spirit_mode:
		ctx.play(&"raise_wail", _remain.pos, -1.0)
	else:
		ctx.play(&"raise_rise", _remain.pos, 0.0)
	if not DominionParts.staged(self):
		return
	# The grave breathes: a cold light gathers under the body and ash dust lifts off it.
	_light = FxParts.ground_light(self, _remain.pos, 1.1, DeathParts.GRAVE_GREEN, 0.0)
	_light.tween_param("intensity", 0.0, 0.7, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	_light.tween_param("intensity", 0.7, 0.0, 0.8, T_RISE)
	var sp := Iso.ground_to_screen(_remain.pos)
	FxParts.smoke(self, sp, 8.0, 18.0, T_RISE, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0), Color(DeathParts.GRAVE_GREEN, 0.2), DUST)


## The dead stand: the body as a zombie, or its soul as a spirit.
func _rise() -> void:
	var at_ground := _remain.pos
	if _spirit_mode:
		spirit = DeathParts.spirit(visitors, at_ground, true)
		_look_in = 0.0
	else:
		DeathParts.zombie(visitors, _remain, _remain.kind == &"plague")
		raised = 1
		if ctx.crowd != null:
			ctx.crowd.threats.register(at_ground, 1.2, 0.6, 3.0, 6.0, 9.0, &"beast")
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at_ground)
	if _spirit_mode:
		var burst := FxParts.bloom(self, sp + Vector2(0, -10), 22.0, DeathParts.PALE_FIRE, 1.0, 1.0)
		burst.tween_param("intensity", 1.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		burst.life = 0.65
		FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 10, PALE, Vector2(20, 80), Vector2(40, 120))
	else:
		FxParts.debris(self, sp, 6, 5.0, Vector2(20, 70), BONE_CHIPS, Vector2(1.0, 2.0), true)
		FxParts.smoke(self, sp, 6.0, 30.0, 0.25, Vector2(8, 20), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	if not _spirit_mode or not is_instance_valid(spirit) or t >= SPIRIT_LIFE:
		return
	if _riding:
		_possess_step()
	elif drift:
		_drift(delta)


## The spirit drifts after the nearest group: the people within GROUP_R of the nearest living one within SEEK, their middle.
func _drift(delta: float) -> void:
	_look_in -= delta
	if _look_in <= 0.0:
		_look_in = DRIFT_LOOK
		_drift_to = Vector2.INF
		var near := DominionParts.near(ctx.field, spirit.ground_pos, SEEK, 1)
		if not near.is_empty():
			var group := DominionParts.near(ctx.field, near[0].ground_pos, GROUP_R)
			var sum := Vector2.ZERO
			for p in group:
				sum += p.ground_pos
			_drift_to = sum / float(group.size())
	if _drift_to != Vector2.INF:
		spirit.walk_to(_drift_to, delta, null)


## The town panics at a zombie's first bite as at a hellhound's; a bite that kills raises the dead one while the chain lasts.
func _on_bite(_a: Animal, victim: Person, first: bool) -> void:
	if first and not _bitten and ctx.crowd != null:
		_bitten = true
		ctx.crowd.fright(victim.ground_pos, BITE_FRIGHT_R, 0.6, 3.0, 6.0, 8.0, &"bite", true)
		ctx.crowd.add_alarm(BITE_ALARM)
	if not is_instance_valid(victim) or victim.is_alive() or _spirit_mode or ctx.crowd == null:
		return
	var before := _left
	_left = DeathParts.on_kill_rise(visitors, ctx.crowd.remains, victim, _left)
	if _left == before:
		return
	raised += 1
	ctx.play(&"raise_rise", victim.ground_pos, -6.0)
	if DominionParts.staged(self):
		var sp := Iso.ground_to_screen(victim.ground_pos)
		FxParts.smoke(self, sp, 6.0, 26.0, 0.3, Vector2(8, 20), Vector2(2, 4), Vector2(0.5, 1.0), Color(DeathParts.GRAVE_GREEN, 0.25), DUST)


## Cut down: it falls to ash and bone (its node is freed by the Visitors).
func _on_cut_down(_a: Animal, at_ground: Vector2) -> void:
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at_ground)
	FxParts.debris(self, sp, 6, 5.0, Vector2(30, 90), BONE_CHIPS, Vector2(1.0, 2.0), true)
	FxParts.smoke(self, sp, 7.0, 36.0, 0.2, Vector2(14, 36), Vector2(2, 5), Vector2(0.6, 1.1), Color(0, 0, 0, 0), DUST)


## The time is up: a host is let go, and every one of the risen still up falls to ash (a spirit thins away).
func _end_life() -> void:
	if _riding:
		_leave()
	if visitors == null:
		return
	for a in visitors.living():
		if DominionParts.staged(self):
			var sp := Iso.ground_to_screen(a.ground_pos)
			FxParts.smoke(self, sp, 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0),
				PALE if a == spirit else DUST)
	visitors.clear()
	spirit = null


## --- Possession: a follow-up through Mind Whisper's wheel (Targeting, Rules.recast()).

## While the spirit lives, is in nobody, and has hosts left.
func can_follow_up() -> bool:
	return _spirit_mode and not finished and is_instance_valid(spirit) and spirit.is_alive() and not _riding \
		and hosts_left > 0 and t < SPIRIT_LIFE


func follow_up_wheel() -> bool:
	return true


func follow_up_reach() -> float:
	return POSSESS_R


## The reach is measured from the spirit.
func follow_up_from() -> Vector2:
	return spirit.ground_pos if is_instance_valid(spirit) else origin


## A press at `at` with the wheel's `extra`: the spirit goes into the person it names (extra["target"], else whoever stands under the
## press) and lays the order on them for POSSESS. False -- nothing spent, the HUD says "missed" -- when the spirit cannot take one now,
## or that person cannot hear it (dead, indoors, a mind that resists, shaking a whisper off: Rules.whisper_refusal() may have passed a
## bystander under the press in their stead), stands more than POSSESS_R from the spirit now (it drifts), or the order does not take.
func follow_up(at_pos: Vector2, extra_data: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var who: Person = null
	if extra_data.has("target"):
		var given: Variant = extra_data.get("target")
		if not is_instance_valid(given) or not given is Person:
			return false
		who = given as Person
	else:
		who = MindWhisperFx.pick(ctx.field, at_pos)
	if who == null or not who.is_alive() or who.inside or who.resists_mind() or who.shaken():
		return false
	if who.ground_pos.distance_to(spirit.ground_pos) > POSSESS_R:
		return false
	var order := String(extra_data.get("order", ""))
	var said := extra_data.duplicate()
	if order != "attack" and order != "burn":
		said["to"] = MindWhisperFx.clamp_to(who.grid, who.ground_pos, extra_data.get("to", who.ground_pos), POSSESS_R)
	if not MindWhisperFx.order(ctx, who, said, POSSESS):
		return false
	who.hold_string()  # the spirit leaves no shake-off behind it
	host = who
	_riding = true
	hosts_left -= 1
	_since = t
	_order = order
	# Untyped until checked: assigning a freed one to a typed member errors.
	var foe = extra_data.get("foe") if order == "attack" else null
	var site = extra_data.get("building") if order == "burn" else null
	_foe = foe if is_instance_valid(foe) else null
	_building = site if is_instance_valid(site) else null
	_to = who.anchor
	_arrived = -1.0
	spirit.visible = false
	visitors.give(spirit, {"fright_r": 0.0})  # inside them it frightens nobody, the host least of all
	spirit.ground_pos = who.ground_pos
	spirit.sync_position()
	ctx.play(&"raise_wail", who.ground_pos, -8.0)
	if DominionParts.staged(self):
		_eyes = HostEyes.new()
		_eyes.who = who
		_eyes.position = Iso.ground_to_screen(who.ground_pos)
		track(_eyes, ctx.overhead)
		var burst := FxParts.bloom(self, _eyes.position + Vector2(0, -10), 14.0, DeathParts.GRAVE_GREEN, 0.9, 1.0)
		burst.tween_param("intensity", 0.9, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		burst.life = 0.45
	return true


## The host still under the spirit's order: alive, set on the foe (attack), or whispered to the spot it was sent.
func _holds() -> bool:
	if not is_instance_valid(host) or not host.is_alive():
		return false
	if _order == "attack":
		return host.mind == Person.Mind.FIGHT and host.fight_target == _foe
	return host.mind == Person.Mind.WHISPERED and host.anchor == _to


## The spirit rides in its host. A walk or an attack holds POSSESS; a burn holds until its match is struck at the building's edge
## (MindWhisperFx.BURN_SECS after getting there) or the walk ran out short of it. An order ended some other way ends it too.
func _possess_step() -> void:
	if is_instance_valid(host):
		spirit.ground_pos = host.ground_pos
		spirit.sync_position()
	if not _holds():
		_leave()
		return
	if _order == "burn":
		_burn_step()
	elif t - _since >= POSSESS:
		_leave()


## Mind Whisper's burn, on the spirit's clock: note when the host gets there, and BURN_SECS later light the building.
func _burn_step() -> void:
	if _arrived < 0.0:
		if host.goal() == Vector2.INF:
			if not is_instance_valid(_building) or _building.distance_to(host.ground_pos) > MindWhisperFx.BURN_NEAR:
				_leave()  # the walk ran out short of the building: no match is struck from here
				return
			_arrived = t
		return
	if t - _arrived < MindWhisperFx.BURN_SECS:
		return
	if ctx.crowd != null and ctx.crowd.fires != null and is_instance_valid(_building):
		ctx.crowd.fires.ignite(_building, EmberFx.START_LEVEL)
	_leave()


## The spirit comes out of its host where they stand and frightens again; the host is let go of what it laid on them.
func _leave() -> void:
	# Untyped until checked: a host who left the town (Crowd.escape) is freed, and assigning a freed one to a Person errors.
	var gone_from = host
	host = null
	_riding = false
	var was: Person = gone_from if is_instance_valid(gone_from) else null
	if was != null:
		if _order == "attack":
			if was.mind == Person.Mind.FIGHT and was.fight_target == _foe:
				was.end_whisper()
		elif was.mind == Person.Mind.WHISPERED and was.anchor == _to:
			was.end_whisper()
	if is_instance_valid(_eyes):
		_eyes.queue_free()
	_eyes = null
	_foe = null
	_building = null
	if not is_instance_valid(spirit):
		return
	if was != null:
		spirit.ground_pos = was.ground_pos
		spirit.sync_position()
	spirit.visible = true
	visitors.give(spirit, {"fright_r": FRIGHT_R})
	_look_in = 0.0


func _finish() -> void:
	if _riding:
		_leave()
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): a live possession is ended (the host let go of the order,
## the eyes gone) and the risen are gone, the pack only queued for freeing (its parents may be mid-teardown). After _finish
## there is nothing left to do here.
func _exit_tree() -> void:
	if _riding:
		_leave()
	if visitors != null:
		visitors.clear(true)
	spirit = null
	super()


## The possessed one's eyes glow grave green, drawn over them where the people sprite's eyes are (none with their back to us).
class HostEyes extends Node2D:
	var who: Person
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if is_instance_valid(who):
			position = Iso.ground_to_screen(who.ground_pos)
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(who) or not who.is_alive():
			return
		var face := who.remain_facing()
		if face == PeopleArt.Facing.NE or face == PeopleArt.Facing.NW:
			return
		var foot := 14.0
		var design := who._design()
		if PeopleArt.ready() and PeopleArt.has(design):
			foot = (PeopleArt.info(design)[2] as Vector2).y
		var ey := -(foot - 6.0)
		var pulse := 0.75 + 0.25 * sin(_t * 5.0)
		var c := Color(DeathParts.GRAVE_GREEN, pulse)
		draw_rect(Rect2(-2, ey - 1, 5, 3), Color(DeathParts.GRAVE_GREEN, 0.18 * pulse))
		draw_rect(Rect2(-1, ey, 1, 1), c)
		draw_rect(Rect2(1, ey, 1, 1), c)
