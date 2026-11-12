extends RefCounted
## A helper for tests (not a suite, never registered in run_all.gd): a real Battlefield in the scene tree, so the set2 effects that
## draw on the whole stage (tornado, dragon, tsunami, cinder use ctx.impact, ctx.lights and ctx.shake unguarded) can be cast
## headless. (The suites run from the tree's initialize(), when the root is not yet in the tree: make() runs the stage's _ready() itself, and
## the engine prints one "make_current" error per stage for its camera, which is harmless.) make() hands it back with its FxContext built; drop() frees it. Cast with
## FxTimeline.cast(script, bf.ctx, at, {"level": n}) and step the effect with fx._process(dt).


## The Impact every staged cast gets (installed by make(), freed by drop()): the real one asks its viewport where a world point is on
## screen, and the stage's root is not ready when the suites run, and it has no post pass to drive. This one answers the screen centre
## and does nothing for hitstop, impact frame, aberration and dim, so a cast can run to its crash and past it.
class StageImpact extends Impact:
	func focus_of(_p: Vector2) -> Vector2:
		return Vector2(0.5, 0.5)

	func hitstop(_s: float, _scale := 0.04) -> void:
		pass

	func impact_frame(_s := 0.05, _f := Vector2(0.5, 0.5), _a := Color.WHITE, _b := Color.BLACK) -> void:
		pass

	func aberration(_px: float, _s: float) -> void:
		pass

	func dim(_amount: float, _speed := 1.5) -> void:
		pass


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
	var stub := StageImpact.new()
	bf.ctx.impact = stub
	bf.set_meta(&"stage_impact", stub)
	bf.ctx.field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	return bf


## Free a stage made by make(), and everything an effect left on it.
static func drop(bf: Battlefield) -> void:
	Engine.time_scale = 1.0  # a hitstop an effect started is undone by Impact._process, which a staged cast may not reach
	if is_instance_valid(bf):
		var stub = bf.get_meta(&"stage_impact", null)
		if stub != null and is_instance_valid(stub):
			bf.ctx.impact = null
			stub.free()
		bf.get_parent().remove_child(bf)
		bf.free()
