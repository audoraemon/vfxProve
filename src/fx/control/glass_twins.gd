extends RefCounted
## Mirror Twins (Mirrorfold Passage, level 5): everyone who goes through the way in leaves a glass twin standing where
## they stepped on, and the twin walks on toward where they meant to go, for TWIN_TIME. The town takes it for the one
## it mirrors: it is a Person in the EnemyField (never in the crowd's lists), so whatever hunts people there finds it
## the same way -- Visitors' hounds, spirits and demons (Visitors._nearest()), a maddened frenzy (Person.fight() looks
## through field.in_radius()). Struck, bitten or killed by a power, it shatters: it is out of the field at once and its
## shards cut whoever stands within SHARD_R (hurt_from(SHARD_CUT): a citizen hurt and knocked down, a soldier wounded).
## A twin is nobody: it is never ticked by the crowd, never escapes, and a blow or bite never kills it through the
## field (Twin overrides hurt() and hurt_from()), so no hunter counts it and the crowd's numbers never move for it.
## (A power's own field.kill() on one shatters it too, but the field still reports that kill to its listeners; see
## Twin.die().) At most MAX_TWINS stand at once; a crossing past that leaves none. Owned and stepped by the passage
## (step()); clear() takes them all away.

## How long a twin walks, how many stand at once, how far its shards fly and how deep they cut.
const TWIN_TIME := 12.0
const MAX_TWINS := 12
const SHARD_R := 0.6
const SHARD_CUT := 0.5
## Seconds a twin takes to come clear of the glass, and to fade at the end of its walk.
const FADE_IN := 0.3
const FADE_OUT := 1.0
const GLASS := [Color("f0faff"), Color("b8e4ff"), Color("78b8e0"), Color(0.35, 0.6, 0.8, 0.0)]
const GLASS_LIGHT := Color(0.6, 0.85, 1.0)

## The passage that owns them (its clock, its context, its layers).
var fx: FxTimeline
## Twins made, shattered, and people their shards cut.
var made := 0
var shattered := 0
var cut := 0

var _twins: Array = []
## Twins taken away, dead to everyone since the step that took them: freed on the next (a hunter that still held one
## has let go of it by then: it asks whether its prey is alive every step).
var _dying: Array = []


func _init(owner: FxTimeline) -> void:
	fx = owner


## The twins standing now (not shattered, not faded).
func living() -> Array:
	var out := []
	for tw in _twins:
		if is_instance_valid(tw) and not tw.broken and tw.left > 0.0:
			out.append(tw)
	return out


## Whether `e` is a glass twin (of any passage).
static func is_twin(e: Object) -> bool:
	return e != null and e.has_meta(&"glass_twin")


## `p` went through, stepping on at `from` on its way to `aim` at `speed`: a twin of it stands there and walks on (none
## past MAX_TWINS). `along` is the way the lane runs, walked when it had nowhere to go. Returns the twin, or null.
func leave(p: Person, from: Vector2, aim: Vector2, speed: float, along: Vector2) -> Person:
	if living().size() >= MAX_TWINS or is_twin(p):
		return null
	var ctx := fx.ctx
	var tw := Twin.new()
	tw.set_meta(&"glass_twin", true)
	tw.set_meta(&"decoy", true)
	tw.pack = self
	tw.name = "GlassTwin%d" % made
	tw.like_soldier = p.soldier
	tw.look = p.look
	tw.profile = p.profile
	tw.grid = p.grid
	tw.env = p.env
	tw.field = ctx.field
	tw.mind = Person.Mind.CALM
	tw.pace = p.pace
	tw.health = Person.HEALTH_CITIZEN
	tw.ground_pos = from
	tw.anchor = from
	tw._target = from
	tw.walk_speed = maxf(speed, DummyEnemy.WALK_SPEED * 0.5)
	tw.left = TWIN_TIME
	if aim == Vector2.INF or aim.distance_to(from) < 0.1:
		aim = from + along * 3.0
	if p.grid != null and p.grid.walkable(aim):
		tw.way = p.grid.path(from, aim)
	if tw.way.is_empty():
		tw.way = PackedVector2Array([aim])
	ctx.field.add(tw)
	var parent: Node = ctx.world if ctx.world != null and is_instance_valid(ctx.world) else ctx.overhead
	parent.add_child(tw)
	tw._sync_position()
	_twins.append(tw)
	made += 1
	return tw


## One step: each twin walks on; one whose time is up fades out of the field; shattered ones are taken away.
func step(delta: float) -> void:
	for tw in _dying:
		_free(tw, false)
	_dying.clear()
	var frozen := fx.ctx.crowd != null and fx.ctx.crowd.is_frozen()
	for tw in _twins.duplicate():
		if not is_instance_valid(tw):
			_twins.erase(tw)
			continue
		if tw.broken:
			_take(tw)
			continue
		tw.left -= delta
		tw.age += delta
		if tw.left <= 0.0:
			_take(tw)
			continue
		if not frozen and not tw.is_frozen():
			tw.walk(delta)


## Every twin gone (the passage is over, or cut short).
func clear() -> void:
	for tw in _twins + _dying:
		if is_instance_valid(tw):
			_out(tw)
			tw.state = DummyEnemy.State.DEAD
			_free(tw, true)
	_twins.clear()
	_dying.clear()


## `tw` struck: it breaks, leaves the field, and its shards cut whoever stands within SHARD_R.
func shatter(tw: Person) -> void:
	if tw.broken:
		return
	tw.broken = true
	shattered += 1
	var at: Vector2 = tw.ground_pos
	_out(tw)
	var ctx := fx.ctx
	for e in ctx.field.in_radius(at, SHARD_R):
		var q := e as Person
		if q == null or is_twin(q) or q.inside or not q.is_alive():
			continue
		q.hurt_from(SHARD_CUT, at)
		cut += 1
	ctx.play(&"glac_shatter", at, -6.0)
	if not DominionParts.staged(fx):
		return
	var sp := Iso.ground_to_screen(at) + Vector2(0, -6)
	var shards := FxParts.particles(fx, ctx.overhead, sp, PixelParticles.Shape.STREAK, GLASS)
	shards.gravity = 260.0
	shards.drag = 0.6
	shards.burst(26, {"radius": 3.0, "speed": Vector2(30, 90), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 8),
		"alt_speed": Vector2(30, 110), "life": Vector2(0.35, 0.7), "size": Vector2(1, 2)})
	var glow := FxParts.bloom(fx, sp, 16.0, GLASS_LIGHT, 0.7, 0.8)
	glow.tween_param("intensity", 0.7, 0.0, 0.35, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.4


## Out of the field and out of everyone's sight: no hunter goes for it, no power finds it. It stays "alive" until
## it is taken away (_take()), so the blow or bite that broke it is never counted as a kill.
func _out(tw: Person) -> void:
	tw.inside = true
	tw.visible = false
	if fx.ctx != null and is_instance_valid(fx.ctx.field):
		fx.ctx.field.remove(tw)


## A twin done with (shattered, or its walk over): out, and its node freed once nobody is looking at it this frame.
func _take(tw: Person) -> void:
	_twins.erase(tw)
	_out(tw)
	tw.state = DummyEnemy.State.DEAD
	_dying.append(tw)


## Free a twin's node. `later`: one only just dead (the passage's end) is freed a second on, in the game, so no hunter
## stepped before it this frame still holds it when it goes.
static func _free(tw: Variant, later: bool) -> void:
	if not is_instance_valid(tw):
		return
	if not tw.is_inside_tree():
		tw.free()
	elif later:
		tw.get_tree().create_timer(1.0).timeout.connect(tw.queue_free)
	else:
		tw.queue_free()


## A glass twin: a Person to whoever looks in the field, walked by its pack along `way`, drawn as clear glass.
class Twin extends Person:
	var pack: RefCounted
	var way := PackedVector2Array()
	var leg := 0
	## Seconds of its walk left, and since it was made.
	var left := 0.0
	var age := 0.0
	var broken := false
	## Drawn in a soldier's shape (it is never one: no guard duty, no refill, no blows).
	var like_soldier := false

	func _ready() -> void:
		_sync_position()

	## Never thinks: its pack walks it. Only drawn.
	func _process(_delta: float) -> void:
		queue_redraw()

	## On along its way at its pace; it stands at the end.
	func walk(delta: float) -> void:
		var step := walk_speed * delta
		while step > 0.0 and leg < way.size():
			var to := way[leg]
			var d := ground_pos.distance_to(to)
			if d <= step:
				ground_pos = to
				step -= d
				leg += 1
			else:
				var next := ground_pos + (to - ground_pos) / d * step
				if block_env != null and block_env.blocked(next):
					break  # a wall where the way was: it stands
				ground_pos = next
				step = 0.0
		_sync_position()

	## Struck (a frenzy's blow, a soldier's): it shatters; it never dies through the field.
	func hurt(_amount: float, _by: Person) -> void:
		if pack != null and not broken:
			pack.shatter(self)

	## Bitten (a visitor, a maddened animal): it shatters.
	func hurt_from(_amount: float, _from: Vector2) -> void:
		if pack != null and not broken:
			pack.shatter(self)

	## Killed by a power (EnemyField.kill()): it shatters, leaving no body. The field reports the kill to its listeners
	## all the same; EnemyField.kill() passing over a "decoy" would keep it from every count.
	func die(_kind: StringName, _source := Vector2.INF) -> void:
		if pack != null and not broken:
			pack.shatter(self)

	func is_down() -> bool:
		return false

	func _draw() -> void:
		var a := clampf(minf(age / FADE_IN, left / FADE_OUT), 0.0, 1.0)
		if a <= 0.0:
			return
		var shimmer := 0.5 + 0.5 * sin(age * 5.0 + float(get_instance_id() % 7))
		var edge := Color(0.86, 0.96, 1.0, 0.75 * a)
		var body := Color(0.55, 0.8, 1.0, 0.42 * a)
		var deep := Color(0.35, 0.6, 0.85, 0.45 * a)
		draw_rect(Rect2(-4, -1, 9, 2), Color(0.3, 0.55, 0.8, 0.25 * a))
		var stride := 1.0 if fmod(age * 4.0, 2.0) < 1.0 and leg < way.size() else 0.0
		# Legs, body, head: clear glass with a pale rim.
		draw_rect(Rect2(-2, -4, 1, 4 - stride), deep)
		draw_rect(Rect2(1, -4, 1, 4 - (1.0 - stride) * (1.0 if leg < way.size() else 0.0)), deep)
		draw_rect(Rect2(-3, -9, 6, 5), body)
		draw_rect(Rect2(-2, -12, 4, 3), body)
		if like_soldier:
			draw_rect(Rect2(-3, -13, 6, 1), edge)
		draw_rect(Rect2(-3, -9, 1, 5), edge)
		draw_rect(Rect2(-2, -12, 1, 3), edge)
		# A glint running up it.
		var gy := -2.0 - fmod(age * 6.0, 11.0)
		draw_rect(Rect2(-1, gy, 2, 1), Color(1, 1, 1, 0.55 * a * shimmer))
