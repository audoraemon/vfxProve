extends RefCounted
## Dragonfire ground fire, Task 3: the patch's look (GroundFireSprite) -- two flames, embers, smoke, a scorch decal and a light --
## that outlives the cast, and, with no town to keep the patch, steps it itself: it burns down in 40 s and burns who stays in it.

const FxStage := preload("res://tests/fx_stage.gd")


static func _stage(seed_value := 3) -> Battlefield:
	return FxStage.make(seed_value)


static func _drop(bf: Battlefield) -> void:
	bf.ctx.field.clear()
	FxStage.drop(bf)


static func _sprite(bf: Battlefield, at: Vector2, id := 1000) -> GroundFireSprite:
	return GroundFireSprite.new().setup(GroundFire.new(at, GroundFire.RADIUS, id), bf.ctx)


static func run(t) -> void:
	_no_town(t)
	_owned(t)
	_voice(t)
	_no_ctx_rng(t)
	_clears(t)


## No town keeps the patch: the sprite burns it down, burns who is in it, and frees itself after it is out.
static func _no_town(t) -> void:
	var bf := _stage()
	var s := _sprite(bf, Vector2(4.0, 3.0))
	t.check(s.is_in_group(GroundFireSprite.GROUP) and s.get_parent() == bf.ctx.world, "ground_fire_sprite: lasting group, drawn in the world layer")
	t.check(s.flames.size() == 2 and s.ground != null and s.ground.get_parent() == bf.ctx.ground, "two flames, and a ground node under the ground layer")
	t.check(not s.patch.owned, "a patch made by hand is nobody's: the sprite keeps it")
	var held := DummyEnemy.new()
	held.ground_pos = Vector2(4.0, 3.0)
	bf.ctx.field.add(held)
	var free := DummyEnemy.new()
	free.ground_pos = Vector2(14.0, 3.0)
	bf.ctx.field.add(free)
	var time := 0.0
	var step := 0.1
	for i in 14:
		s.advance(step)
		time += step
	t.check(held.is_alive() and free.is_alive(), "1.4 s in the fire does not kill, and one far off is untouched")
	s.advance(step)
	time += step
	t.check(not held.is_alive() and absf(time - 1.5) < 0.001 and free.is_alive(), "a dummy held in it dies at 1.5 s (at %.2f), the far one lives" % time)
	t.check(s.patch.strength > 0.9 and not s.patch.out, "it is burning (strength %.3f)" % s.patch.strength)
	# Up to 39.9 s after its start; it was stepped 1.5 s already.
	while time < 39.9 - 0.0001:
		s.advance(step)
		time += step
	t.check(not s.patch.out and s.patch.strength > 0.0, "39.9 s: still burning (strength %.4f)" % s.patch.strength)
	s.advance(0.2)
	time += 0.2
	t.check(s.patch.out and not s.patch.beaten, "40.1 s: out, burned out and not beaten")
	t.check(not s.is_queued_for_deletion(), "out: the scorch still shows")
	var gnode := s.ground
	s.advance(6.7)
	t.check(s.is_queued_for_deletion() and gnode.is_queued_for_deletion(), "6.7 s after it went out the sprite and its ground node are queued for freeing")
	_drop(bf)


## A town keeps an owned patch: the sprite never changes its strength, and the flames follow it.
static func _owned(t) -> void:
	var bf := _stage()
	var s := _sprite(bf, Vector2(-4.0, 2.0))
	s.patch.owned = true
	s.patch.strength = 0.5
	var held := DummyEnemy.new()
	held.ground_pos = Vector2(-4.0, 2.0)
	bf.ctx.field.add(held)
	for i in 100:
		s.advance(0.1)
	t.check(is_equal_approx(s.patch.strength, 0.5), "an owned patch's strength is the town's: unchanged after 10 s (%.4f)" % s.patch.strength)
	t.check(held.is_alive(), "and the sprite does not burn who is in an owned patch (the town does)")
	var follows := true
	for f in s.flames:
		follows = follows and is_equal_approx(f.strength, sqrt(0.5))
	t.check(follows, "the flames' strength follows sqrt(strength) (%.3f)" % s.flames[0].strength)
	s.patch.strength = 0.0
	s.patch.out = true
	s.patch.beaten = true
	s.advance(0.1)
	var shrinking: float = s.flames[0].strength
	t.check(shrinking < sqrt(0.5) and shrinking > 0.0, "out: the flames shrink, not vanish (%.3f)" % shrinking)
	s.advance(0.6)
	t.check(is_zero_approx(s.flames[0].strength) and not s.is_queued_for_deletion(), "gone in 0.6 s; the scorch stays")
	s.advance(6.1)
	t.check(s.is_queued_for_deletion(), "an owned patch's sprite frees itself after its scorch fades, too")
	_drop(bf)


## The strip's sound loop: kept, and faded by the sprite once every patch of the strip is out; no Sfx is no fault.
static func _voice(t) -> void:
	var bf := _stage()
	var a := _sprite(bf, Vector2(2.0, 2.0), 1001)
	var b := _sprite(bf, Vector2(3.0, 5.0), 1002)
	var strip: Array = [a.patch, b.patch]
	a.hold_voice(null, strip)
	for i in 5:
		a.advance(0.1)
	t.check(a._voice == null and not a.is_queued_for_deletion(), "hold_voice(null) with no Sfx keeps no loop and does not fail")
	var voice := Node.new()
	a.hold_voice(voice, strip)
	t.check(a._voice == voice, "it keeps the loop it is handed")
	a.patch.out = true
	a.advance(0.1)
	t.check(a._voice == voice, "one patch of the strip still burns: the loop stays")
	b.patch.out = true
	a.advance(0.1)
	t.check(a._voice == null, "every patch of the strip out: the loop is let go (faded)")
	voice.free()
	# A sprite that leaves while it still holds the loop lets it go too.
	var c := _sprite(bf, Vector2(6.0, 6.0), 1003)
	var v2 := Node.new()
	c.hold_voice(v2, [c.patch])
	c._exit_tree()
	t.check(c._voice == null, "a sprite leaving the tree holding a loop lets it go and does not fail")
	c.free()
	v2.free()
	a.free()
	b.free()
	_drop(bf)


## Nothing here draws the god's random numbers: its particles are seeded from the patch id.
static func _no_ctx_rng(t) -> void:
	var bf := _stage(9)
	var before := bf.ctx.rng.state
	var s := _sprite(bf, Vector2(5.0, -5.0), 1007)
	for i in 50:
		s.advance(0.1)
	t.check(bf.ctx.rng.state == before, "ctx.rng is untouched by setup() and 5 s of advance()")
	t.check(s.embers.rng.seed == 1007 * 7919 + 13, "the embers are seeded from the patch's id")
	_drop(bf)


## Battlefield.clear_effects() frees the sprite: the ground node goes with it, and the light is no more.
static func _clears(t) -> void:
	var bf := _stage()
	var s := _sprite(bf, Vector2(1.0, 1.0))
	var gnode := s.ground
	t.check(is_instance_valid(gnode) and gnode.get_child_count() == 2, "the ground node holds the decal and the light")
	# (The staged tree is not inside the running tree during the suites, so leaving it is called by hand.)
	s._exit_tree()
	t.check(gnode.is_queued_for_deletion(), "leaving the tree queues the sprite's ground node")
	s.free()
	_drop(bf)
