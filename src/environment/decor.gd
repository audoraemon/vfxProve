class_name Decor
extends Node2D
## One small thing in town (a barrel, a garden, a tree...) standing in the y-sorted world. It has no per-frame
## work: it draws once through DecorArt and again only when a blast chars it or knocks it down. Its layer is dimmed
## with the ambient light (see Town), so it needs no lighting of its own. EnvironmentField hands it hits.

enum Kind {
	BARREL, CRATES, BENCH, FENCE, GARDEN, BUSH, ROCK, OAK, PINE, LAMP, BUNTING, SCARECROW, SIGNPOST, REEDS, FLOWERS,
}

## A hit this strong (or any falling stone) knocks decor down; weaker hits char it by amount / CHAR_PER.
const KNOCK_AT := 30.0
const CHAR_PER := 60.0

var kind := Kind.BARREL
## Ground point it stands on (its sort corner), and its extent (a run's direction and length, a plot's size).
var at := Vector2.ZERO
var size := Vector2.ZERO
var seed_value := 0
## 0..1 how burnt it is.
var char_amount := 0.0
var down := false
var _glow: QuadFx


func setup(k: Kind, at_point: Vector2, extent: Vector2, s: int) -> Decor:
	kind = k
	at = at_point
	size = extent
	seed_value = s
	position = Iso.ground_to_screen(at)
	if kind == Kind.BUNTING:
		# Strung high over the street: above the people walking under it.
		z_index = 1
	return self


func _ready() -> void:
	if kind == Kind.LAMP:
		_glow = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(46, 23))
		_glow.set_param("color", Structure.TORCH_LIGHT)
		_glow.set_param("falloff", 1.6)
		_glow.set_param("intensity", 0.4)
		_glow.set_param("flicker", 0.6)
		_glow.z_as_relative = false
		_glow.z_index = -4
		add_child(_glow)


## A blast reached it: char it, or knock it down when the hit is strong enough.
func hit(amount: float, damage_kind: StringName) -> void:
	if down:
		return
	if amount >= KNOCK_AT or damage_kind == &"stone":
		down = true
		if is_instance_valid(_glow):
			_glow.queue_free()
	else:
		char_amount = minf(char_amount + amount / CHAR_PER, 1.0)
	self_modulate = Color.WHITE.lerp(Structure.COL_CHAR, char_amount * 0.7)
	queue_redraw()


func _draw() -> void:
	ArtKit.begin()
	DecorArt.paint(kind, at, size, seed_value, position, down)
	ArtKit.flush(self)
