extends RefCounted
## A helper for tests (not a suite, never registered in run_all.gd): a real Battlefield in the scene tree, so the set2 effects that
## draw on the whole stage (tornado, dragon, tsunami, cinder use ctx.impact, ctx.lights and ctx.shake unguarded) can be cast
## headless. (The suites run from the tree's initialize(), when the root is not yet in the tree: make() runs the stage's _ready() itself, and
## the engine prints one "make_current" error per stage for its camera, which is harmless.) make() hands it back with its FxContext built; drop() frees it. Cast with
## FxTimeline.cast(script, bf.ctx, at, {"level": n}) and step the effect with fx._process(dt).


## A Battlefield on the tree root with the god's rng seeded and a 60x60 field around the origin.
static func make(seed_value: int) -> Battlefield:
	var tree := Engine.get_main_loop() as SceneTree
	var bf := Battlefield.new()
	tree.root.add_child(bf)
	if bf.ctx.field == null:
		# The suite runs from the tree's initialize(), before the root is ready: the child's _ready() has not come yet. Run it now (the stage
		# is dropped before any frame, so it is never run twice).
		bf._ready()
	# Nothing can sound off the tree (and FxContext.play() is a no-op without a Sfx, as in every other headless test).
	bf.ctx.sfx = null
	bf.rng.seed = seed_value
	bf.ctx.field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	return bf


## Free a stage made by make(), and everything an effect left on it.
static func drop(bf: Battlefield) -> void:
	Engine.time_scale = 1.0  # a hitstop an effect started is undone by Impact._process, which a staged cast may not reach
	if is_instance_valid(bf):
		bf.get_parent().remove_child(bf)
		bf.free()
