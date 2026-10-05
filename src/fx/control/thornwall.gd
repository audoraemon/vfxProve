class_name ThornwallFx
extends FxTimeline
## Thornwall (v0.06): a line of brambles THORN_LENGTH long grows along the drag, centred on the press -- THORN_SEGMENTS
## square segments, each a structure (tree kind, tagged thorns) that blocks walking. The walk grid closes under it
## (EnvironmentField.structure_added), so evacuees reroute or jam behind it and a gate's mouth can be sealed. Anyone
## standing where a segment grows is shoved clear, unhurt. After THORN_TIME it withers away. Engineers can cut it down
## sooner (EngineerManager's Clear job), and it burns. The town notices it (Crowd.THORN_ALARM). The cast locks the
## other slots for 1 s.

const THORN_LENGTH := 3.0
const THORN_SEGMENTS := 5
const SEG := 0.6
const THORN_TIME := 25.0
const HEIGHT := 14.0
## Seconds to grow, and to wither at the end.
const GROW := 0.6
const WITHER := 0.8
const LEAF := [Color("6a7a3a"), Color("4a5a2a"), Color("2a3218")]

var segments: Array[Structure] = []


## The segments' footprints for a wall centred on `at` along `dir`.
static func rects(at: Vector2, dir: Vector2) -> Array[Rect2]:
	var unit := dir.normalized() if dir.length() > 0.01 else Vector2(1, 0)
	var out: Array[Rect2] = []
	for k in THORN_SEGMENTS:
		var c := at + unit * (-THORN_LENGTH * 0.5 + THORN_LENGTH * (float(k) + 0.5) / float(THORN_SEGMENTS))
		out.append(Rect2(c - Vector2(SEG, SEG) * 0.5, Vector2(SEG, SEG)))
	return out


func _build() -> void:
	duration = THORN_TIME
	busy = 1.0
	for r in rects(origin, extra.get("dir", Vector2(1, 0))):
		if ctx.env.blocked(r.get_center(), 0.0):
			continue  # no thorns inside a building
		_shove(r)
		var s := ctx.env.add_structure(r, HEIGHT, Structure.Kind.TREE, &"thorns", &"thorns")
		s.scale = Vector2(1.0, 0.05)
		segments.append(s)
		var leaves := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(r.get_center()), PixelParticles.Shape.SQUARE,
			LEAF)
		leaves.gravity = 120.0
		leaves.drag = 1.0
		leaves.burst(8, {"radius": 6.0, "speed": Vector2(10, 30), "alt": Vector2(0, 6), "alt_speed": Vector2(30, 70),
			"life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})
	ctx.play(&"grav_compress", origin, -10.0)
	at(THORN_TIME, _wither_away)


## Anyone standing where a segment grows is pushed just clear of it.
func _shove(r: Rect2) -> void:
	var c := r.get_center()
	for e in ctx.field.in_radius(c, SEG):
		if not r.grow(0.2).has_point(e.ground_pos):
			continue
		var away := e.ground_pos - c
		var dir := away.normalized() if away.length() > 0.01 else Vector2(0, 1)
		for d: float in [0.65, 0.9, 1.2]:
			var to := c + dir * d
			if not ctx.env.blocked(to):
				e.ground_pos = to
				break


func _wither_away() -> void:
	for s in segments:
		if is_instance_valid(s) and ctx.env.structures().has(s):
			ctx.env.remove(s)
	segments.clear()


## Cut short (FxTimeline.end_now()): the brambles go with it, or they would block the way for good.
func end_now() -> void:
	_wither_away()
	super()


## The brambles grow up out of the ground, and sink back as they wither.
func _fx_process(_delta: float) -> void:
	var k := minf(clampf(t / GROW, 0.05, 1.0), clampf((duration - t) / WITHER, 0.05, 1.0))
	for s in segments:
		if is_instance_valid(s) and not s.destroyed:
			s.scale.y = k
