class_name Set2Parts
extends RefCounted
## Palettes and builders shared by the Set2 fantasy skills.

# Shader ramps: darkest -> brightest (c0..c4).
const STORM := [Color(0.05, 0.1, 0.3, 0.5), Color("2f5fd8"), Color("5aa8ff"), Color("c8e8ff"), Color("ffffff")]
const GOLD := [Color(0.3, 0.18, 0.05, 0.5), Color("9a6a1e"), Color("d8a23a"), Color("ffd98a"), Color("fff6dc")]
const WATER := [Color(0.05, 0.15, 0.3, 0.5), Color("1f5fa8"), Color("3a9ad8"), Color("9ad8f5"), Color("f0fcff")]
const WIND := [Color(0.3, 0.3, 0.32, 0.4), Color("8a8c92"), Color("b8bcc4"), Color("dfe4ea"), Color("ffffff")]
const MAGMA := [Color(0.3, 0.05, 0.02, 0.55), Color("a82810"), Color("f06018"), Color("ffb040"), Color("fff0b8")]

# Particle lifetime ramps: first color at birth.
const STORM_LIFE := [Color("ffffff"), Color("c8e8ff"), Color("5aa8ff"), Color("2f5fd8"), Color(0.1, 0.2, 0.6, 0.5)]
const GOLD_LIFE := [Color("fff6dc"), Color("ffd98a"), Color("d8a23a"), Color(0.55, 0.36, 0.12, 0.6)]
const SAND_LIFE := [Color("c8ae86"), Color("a8906c"), Color(0.52, 0.44, 0.34, 0.75), Color(0.4, 0.34, 0.27, 0.45)]
const FOAM_LIFE := [Color("ffffff"), Color("e6f8ff"), Color("a8e0f8"), Color(0.5, 0.78, 0.95, 0.5)]
const WATER_LIFE := [Color("f0fcff"), Color("9ad8f5"), Color("3a9ad8"), Color(0.12, 0.38, 0.7, 0.55)]
const WIND_LIFE := [Color(1, 1, 1, 0.9), Color(0.88, 0.92, 0.96, 0.7), Color(0.75, 0.8, 0.86, 0.45), Color(0.7, 0.74, 0.8, 0.2)]
const DUST_CLOUD := [Color("b8a28a"), Color("9a8672"), Color(0.5, 0.44, 0.38, 0.8), Color(0.4, 0.36, 0.32, 0.5)]
const WOOD := [Color("8a6a44"), Color("6e5234"), Color("523c26"), Color("3e2c1c")]
const STONE_CHUNK := [Color("b4a48a"), Color("8e806a"), Color("6a5e4e"), Color("4a4238")]
const OBSIDIAN := [Color("ffb040"), Color("5a3a30"), Color("3a2a26"), Color("262022")]


static func sigil(fx: FxTimeline, center: Vector2, radius: float, color: Color, glyph: String) -> SigilRune:
	var s := SigilRune.new()
	s.radius = radius
	s.color = color
	s.glyph = glyph
	s.position = center
	# Above the dim layer so the rune glows while the world darkens.
	s.z_index = 9
	fx.track(s, fx.ctx.ground)
	s.create_tween().tween_property(s, "reveal", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return s


static func lane(fx: FxTimeline, origin: Vector2, dir: Vector2, length: float, width: float, color: Color,
		style: String) -> LanePath:
	var l := LanePath.new()
	l.length = length
	l.width = width
	l.color = color
	l.style = style
	l.position = origin
	l.rotation = dir.angle()
	l.z_index = 9
	fx.track(l, fx.ctx.ground)
	l.create_tween().tween_property(l, "reveal", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return l


## Jagged lightning bolt between screen points; `life` seconds, re-jitters while alive.
static func bolt(fx: FxTimeline, parent: Node, a: Vector2, b: Vector2, life: float, thickness := 1.0,
		branches := 2, color := Color("5aa8ff")) -> LightningBolt:
	var bolt_node := LightningBolt.new()
	bolt_node.from = a
	bolt_node.to = b
	bolt_node.life = life
	bolt_node.thickness = thickness
	bolt_node.branches = branches
	bolt_node.glow = color
	bolt_node.rng.seed = fx.ctx.rng.randi()
	fx.track(bolt_node, parent)
	return bolt_node


## Short-lived additive column of light standing on a screen point.
static func glow_column(fx: FxTimeline, screen_pos: Vector2, width: float, height: float, color: Color,
		intensity: float, seconds: float) -> QuadFx:
	var q := FxParts.quad(fx, FxParts.SH_BEAM_ADD, Vector2(width, height), fx.ctx.overhead, Vector2(0.5, 1.0))
	q.position = screen_pos
	q.set_param("color", color)
	q.tween_param("intensity", intensity, 0.0, seconds, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	q.life = seconds + 0.02
	return q


## Distance from point p to segment ab.
static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var k := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * k)
