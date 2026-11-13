class_name RaiseTheDeadFx
extends FxTimeline
## Raise the Dead (Death, Tier I; spec 5.1): a click on a body -- the nearest remain within Remains.PICK_R (Rules refuses a click
## with none, "NO DEAD THERE", before any cooldown). Q and E pick what rises (extra["mode"]):
##
## ZOMBIE: the grave breathes over T_RISE, then the body gets up where it lay (DeathParts.zombie(): its own people sprite,
##   greyed, walking at a walk, a quarter faster on the chase, eyes alight). It hunts the nearest living within SEEK; a citizen's first bite knocks
##   them down, a second within 3 s kills (frenzy). Whoever it kills gets up as another (DeathParts.on_kill_rise()), CHAIN
##   raised in all by the cast. A soldier cuts one down in DeathParts.ZOMBIE_BLOWS (3) blows. A plague body's zombie infects
##   with its bites. The town panics at its first bite as at a hellhound's. At ZOMBIE_LIFE every one still up falls to ash.
## SPIRIT (needs a soul: a remain under Remains.SOUL old; else "THE SOUL HAS GONE"): the soul rises as a pale spirit
##   (DeathParts.spirit()) for SPIRIT_LIFE, through walls, never cut down. Everyone within FRIGHT_R flees it (Visitors
##   fright_r), and it drifts after the nearest group: the people within GROUP_R of the nearest living person within SEEK,
##   looked for again every DRIFT_LOOK. It only haunts: it never possesses anyone, and the slot has no follow-up (R3).
## The remain is used up at the cast (Remains.take()); a raised body stays dead -- the zombie is a Visitor, never the Person.
## Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead stand.

## The grave breathes, and the dead stand at T_RISE.
const T_RISE := 0.8
## ZOMBIE: how long the risen stand, how many rise in all (the first and its kills'), how far they look for the living.
## (SEEK is DeathParts.ZOMBIE_SEEK: the zombie the kit makes hunts that far.)
const ZOMBIE_LIFE := 30.0
const CHAIN := 3
const SEEK := 10.0
## SPIRIT: how long it stays, how far its fright reaches.
const SPIRIT_LIFE := 20.0
const FRIGHT_R := 4.0
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

## The risen, how many rose, the spirit (null in ZOMBIE), and whether it drifts (a test pins it to stand).
var visitors: Visitors
var raised := 0
var spirit: Animal
var drift := true

var _remain: Remains.Remain
var _spirit_mode := false
## How many more of the zombies' kills may rise.
var _left := CHAIN - 1
var _bitten := false
var _drift_to := Vector2.INF
var _look_in := 0.0
var _light: QuadFx


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
		visitors.give(spirit, {"fright_r": FRIGHT_R})  # a haunt reaches further than the Gravecall one
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
	if drift:
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


## The time is up: every one of the risen still up falls to ash (a spirit thins away).
func _end_life() -> void:
	if visitors == null:
		return
	for a in visitors.living():
		if DominionParts.staged(self):
			var sp := Iso.ground_to_screen(a.ground_pos)
			FxParts.smoke(self, sp, 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0),
				PALE if a == spirit else DUST)
	visitors.clear()
	spirit = null


func _finish() -> void:
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): the risen are gone, the pack only queued for freeing (its
## parents may be mid-teardown). After _finish there is nothing left to do here.
func _exit_tree() -> void:
	if visitors != null:
		visitors.clear(true)
	spirit = null
	super()
