class_name RaiseTheDeadFx
extends FxTimeline
## Raise the Dead (Death, Tier I; spec 5.1): a click near bodies -- every remain within RING_R of it rises, MOST at the most, the
## oldest first (R28; Rules refuses a click with none within RING_R, "NO DEAD THERE", before any cooldown). Q and E pick what rises (extra["mode"]):
##
## ZOMBIE: the grave breathes over T_RISE, then each body gets up where it lay (DeathParts.zombie(): its own people sprite,
##   greyed, walking at a walk, a quarter faster on the chase, eyes alight). It hunts the nearest living within SEEK; a citizen's first bite knocks
##   them down, a second within 3 s kills (frenzy). Whoever it kills gets up as another (DeathParts.on_kill_rise()), CHAIN - 1
##   more in all by the whole cast, shared by every zombie of it (R29). A soldier cuts one down in DeathParts.ZOMBIE_BLOWS (3) blows. A plague body's zombie infects
##   with its bites. The town panics at its first bite as at a hellhound's. At ZOMBIE_LIFE every one still up falls to ash.
## SPIRIT (needs a soul: a remain under Remains.SOUL old; else "THE SOUL HAS GONE"): each soul in the ring rises as a pale spirit
##   (DeathParts.spirit()) for SPIRIT_LIFE, through walls, never cut down. Everyone within FRIGHT_R flees it (Visitors
##   fright_r), and each drifts after its own nearest group: the people within GROUP_R of the nearest living person within SEEK,
##   looked for again every DRIFT_LOOK. It only haunts: it never possesses anyone, and the slot has no follow-up (R3).
## The remain is used up at the cast (Remains.take()); a raised body stays dead -- the zombie is a Visitor, never the Person.
## Level 5, Body and Soul (twist): one cast gives both halves for the ring's own bodies, once for each. ZOMBIE: a ring zombie's end
##   (cut down, or ZOMBIE_LIFE) raises its soul as a spirit of this cast (SPIRIT_LIFE) if its remain had a soul at the cast; chain
##   risers give none. SPIRIT: a ring spirit's fade raises its own body as a zombie of this cast (ZOMBIE_LIFE; its kills share the
##   cast's CHAIN), never a second spirit.
## Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead stand.

## The grave breathes, and the dead stand at T_RISE.
const T_RISE := 0.8
## The ring a click raises: every remain within RING_R of it, MOST at the most, the oldest first (R28).
const RING_R := 3.0
const MOST := 8
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

## The risen, how many rose, the spirits (empty in ZOMBIE), and whether they drift (a test pins them to stand).
var visitors: Visitors
var raised := 0
var spirits: Array[Animal] = []
var drift := true

var _ring: Array[Remains.Remain] = []
var _spirit_mode := false
## How many more of the zombies' kills may rise.
var _left := CHAIN - 1
## This cast's numbers at its ability level (the consts at level 1): the zombies' time, the chain, the spirits' time.
var lv_zombie_life := ZOMBIE_LIFE
var lv_chain := CHAIN
var lv_spirit_life := SPIRIT_LIFE
var _bitten := false
## The level-5 twist (Body and Soul), the ring's bodies' souls (remain -> had a soul at the cast), the ring zombies still owing a
## spirit (ZOMBIE), each spirit's body (SPIRIT) and its own end time (ZOMBIE twist: spirits rise at different times).
var _twist := false
var _soul_of := {}
var _owes := {}
var _spirit_body: Array[Remains.Remain] = []
var _spirit_until: Array[float] = []
## Each spirit's own drift target and look timer, in the order of `spirits`.
var _drift_to: Array[Vector2] = []
var _look_in: Array[float] = []


func _build() -> void:
	lv_zombie_life = float(PowerBook.stat(extra, "raise", "ZOMBIE_LIFE", ZOMBIE_LIFE))
	lv_chain = int(PowerBook.stat(extra, "raise", "CHAIN", CHAIN))
	lv_spirit_life = float(PowerBook.stat(extra, "raise", "SPIRIT_LIFE", SPIRIT_LIFE))
	_left = lv_chain - 1
	_twist = PowerBook.twist_at(extra, "raise")
	_spirit_mode = String(extra.get("mode", "zombie")) == "spirit"
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	if rem != null:
		_ring = rem.ring(origin, RING_R, _spirit_mode, MOST)
	if _ring.is_empty():
		duration = 0.1  # no body (or no soul) there: Rules refuses such a click before it comes here
		return
	for r in _ring:
		if _twist:
			_soul_of[r] = rem.has_soul(r)
		rem.take(r)
	duration = (lv_spirit_life if _spirit_mode else lv_zombie_life) + FADE
	if _twist:
		duration = lv_zombie_life + lv_spirit_life + FADE  # the second half has its own time after the first's end
	busy = T_RISE
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, ctx.crowd._grid, parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	at(T_RISE, _rise)
	at(duration - FADE, _end_life)
	if _twist:
		at(lv_spirit_life if _spirit_mode else lv_zombie_life, _first_half_ends)
	ctx.play(&"raise_wail" if _spirit_mode else &"raise_rise", _ring[0].pos, -1.0 if _spirit_mode else 0.0)
	if not DominionParts.staged(self):
		return
	# The grave breathes: a cold light gathers under each body and ash dust lifts off it.
	for r in _ring:
		var light := FxParts.ground_light(self, r.pos, 1.1, DeathParts.GRAVE_GREEN, 0.0)
		light.tween_param("intensity", 0.0, 0.7, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
		light.tween_param("intensity", 0.7, 0.0, 0.8, T_RISE)
		var sp := Iso.ground_to_screen(r.pos)
		FxParts.smoke(self, sp, 8.0, 18.0, T_RISE, Vector2(6, 16), Vector2(2, 4), Vector2(0.5, 1.0), Color(DeathParts.GRAVE_GREEN, 0.2), DUST)


## The dead stand: each body as a zombie, or each soul as a spirit.
func _rise() -> void:
	for r in _ring:
		_rise_one(r)


func _rise_one(r: Remains.Remain) -> void:
	var at_ground := r.pos
	if _spirit_mode:
		var sp := DeathParts.spirit(visitors, at_ground, true)
		visitors.give(sp, {"fright_r": FRIGHT_R})  # wider than a plain spirit's DeathParts.SPIRIT_FRIGHT_R (R16)
		spirits.append(sp)
		_drift_to.append(Vector2.INF)
		_look_in.append(0.0)
		if _twist:
			_spirit_body.append(r)
	else:
		var z := DeathParts.zombie(visitors, r, r.kind == &"plague")
		if _twist and bool(_soul_of.get(r, false)):
			_owes[z] = true
		raised += 1
		if ctx.crowd != null:
			ctx.crowd.threats.register(at_ground, 1.2, 0.6, 3.0, 6.0, 9.0, &"beast")
	if not DominionParts.staged(self):
		return
	var screen := Iso.ground_to_screen(at_ground)
	if _spirit_mode:
		var burst := FxParts.bloom(self, screen + Vector2(0, -10), 22.0, DeathParts.PALE_FIRE, 1.0, 1.0)
		burst.tween_param("intensity", 1.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		burst.life = 0.65
		FxParts.sparks(self, ctx.overhead, screen + Vector2(0, -8), 10, PALE, Vector2(20, 80), Vector2(40, 120))
	else:
		FxParts.debris(self, screen, 6, 5.0, Vector2(20, 70), BONE_CHIPS, Vector2(1.0, 2.0), true)
		FxParts.smoke(self, screen, 6.0, 30.0, 0.25, Vector2(8, 20), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	if _twist and not _spirit_mode:
		_age_spirits(delta)
		return
	if not _spirit_mode or t >= lv_spirit_life or not drift:
		return
	for i in spirits.size():
		if is_instance_valid(spirits[i]):
			_drift(i, delta)


## ZOMBIE twist: each spirit drifts and thins away at its own time.
func _age_spirits(delta: float) -> void:
	var i := spirits.size() - 1
	while i >= 0:
		var sp := spirits[i]
		if not is_instance_valid(sp):
			_forget_spirit(i)
		elif t >= _spirit_until[i]:
			_spirit_fade_fx(sp.ground_pos)
			visitors.take(sp)
			_forget_spirit(i)
		i -= 1
	if drift:
		for k in spirits.size():
			_drift(k, delta)


func _forget_spirit(i: int) -> void:
	spirits.remove_at(i)
	_drift_to.remove_at(i)
	_look_in.remove_at(i)
	_spirit_until.remove_at(i)


func _spirit_fade_fx(at_ground: Vector2) -> void:
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(at_ground), 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0),
			Color(0, 0, 0, 0), PALE)


## A soul rises out of a fallen zombie (twist): a spirit of this cast for SPIRIT_LIFE.
func _soul_rises(at_ground: Vector2) -> void:
	var sp := DeathParts.spirit(visitors, at_ground, true)
	visitors.give(sp, {"fright_r": FRIGHT_R})
	spirits.append(sp)
	_drift_to.append(Vector2.INF)
	_look_in.append(0.0)
	_spirit_until.append(t + lv_spirit_life)
	ctx.play(&"raise_wail", at_ground, -1.0)
	if DominionParts.staged(self):
		var screen := Iso.ground_to_screen(at_ground)
		var burst := FxParts.bloom(self, screen + Vector2(0, -10), 22.0, DeathParts.PALE_FIRE, 1.0, 1.0)
		burst.tween_param("intensity", 1.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		burst.life = 0.65
		FxParts.sparks(self, ctx.overhead, screen + Vector2(0, -8), 10, PALE, Vector2(20, 80), Vector2(40, 120))


## A spirit sinks into its body and the body gets up (twist, SPIRIT): a zombie of this cast, its kills sharing the cast's CHAIN.
func _body_rises(r: Remains.Remain) -> void:
	DeathParts.zombie(visitors, r, r.kind == &"plague")
	raised += 1
	ctx.play(&"raise_rise", r.pos, 0.0)
	if ctx.crowd != null:
		ctx.crowd.threats.register(r.pos, 1.2, 0.6, 3.0, 6.0, 9.0, &"beast")
	if DominionParts.staged(self):
		var screen := Iso.ground_to_screen(r.pos)
		FxParts.debris(self, screen, 6, 5.0, Vector2(20, 70), BONE_CHIPS, Vector2(1.0, 2.0), true)
		FxParts.smoke(self, screen, 6.0, 30.0, 0.25, Vector2(8, 20), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), DUST)


## The first half's time is up (twist). ZOMBIE: every zombie still up falls to ash and each ring one with a soul lets it rise as a
## spirit. SPIRIT: every spirit fades and its own body gets up.
func _first_half_ends() -> void:
	if visitors == null:
		return
	if _spirit_mode:
		for i in spirits.size():
			if is_instance_valid(spirits[i]):
				_spirit_fade_fx(spirits[i].ground_pos)
				visitors.take(spirits[i])
				_body_rises(_spirit_body[i])
		spirits.clear()
		_spirit_body.clear()
		return
	var souls: Array[Vector2] = []
	for a in visitors.living():
		if spirits.has(a):
			continue
		if _owes.has(a):
			souls.append(a.ground_pos)
		_spirit_fade_fx(a.ground_pos)
		visitors.take(a)
	_owes.clear()
	for at_ground in souls:
		_soul_rises(at_ground)


## A spirit drifts after the nearest group: the people within GROUP_R of the nearest living one within SEEK, their middle.
func _drift(i: int, delta: float) -> void:
	var spirit := spirits[i]
	_look_in[i] -= delta
	if _look_in[i] <= 0.0:
		_look_in[i] = DRIFT_LOOK
		_drift_to[i] = Vector2.INF
		var near := DominionParts.near(ctx.field, spirit.ground_pos, SEEK, 1)
		if not near.is_empty():
			var group := DominionParts.near(ctx.field, near[0].ground_pos, GROUP_R)
			var sum := Vector2.ZERO
			for p in group:
				sum += p.ground_pos
			_drift_to[i] = sum / float(group.size())
	if _drift_to[i] != Vector2.INF:
		spirit.walk_to(_drift_to[i], delta, null)


## The town panics at a zombie's first bite as at a hellhound's; a bite that kills raises the dead one while the chain lasts.
func _on_bite(_a: Animal, victim: Person, first: bool) -> void:
	if first and not _bitten and ctx.crowd != null:
		_bitten = true
		ctx.crowd.fright(victim.ground_pos, BITE_FRIGHT_R, 0.6, 3.0, 6.0, 8.0, &"bite", true)
		ctx.crowd.add_alarm(BITE_ALARM)
	if not is_instance_valid(victim) or victim.is_alive() or (_spirit_mode and not _twist) or ctx.crowd == null:
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
func _on_cut_down(a: Animal, at_ground: Vector2) -> void:
	if _twist and _owes.has(a):
		_owes.erase(a)
		_soul_rises(at_ground)  # its soul leaves it (a chain riser, never in _owes, gives none)
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
				PALE if spirits.has(a) else DUST)
	visitors.clear()
	spirits.clear()
	_owes.clear()


func _finish() -> void:
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): the risen are gone, the pack only queued for freeing (its
## parents may be mid-teardown). After _finish there is nothing left to do here.
func _exit_tree() -> void:
	if visitors != null:
		visitors.clear(true)
	spirits.clear()
	super()
