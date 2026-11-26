class_name FencedFx
extends FxTimeline
## Fenced Rule (Decree, Tier IV; spec 5.8): a fence of iron posts is driven in round a district of RADIUS about the click,
## and for HOLD_TIME two of five rules hold inside it -- the cast's mode names the pair (Q/E, the ten pairs in order):
##   NO RUNNING  everyone walks: the law holds each one inside to a walk (LawZone; Person.hold_pace() at walk_share()).
##   NO ARMS     no guard strikes or seizes there (Person's blow, EscortDirector._seen_by, the Harvest's guard).
##   NO DOORS    nobody goes into a building there, and nobody inside one comes out (ShelterManager).
##   NO SIGHT    nobody sees farther than LawZone.SIGHT_CAP into it or out of it (Crowd.sight(): MissionDirector._sees,
##               EscortDirector._seen_by, LawMark's hunt, Person's fight pick).
##   NO LEAVING  as Leaving Is Prohibited, at the fence (the LawZone itself holds it).
## Both rules hold for everyone inside, the god's own faithful too. The effect only lays the law (one LawZone of the two
## kinds, T_LAND after the cast, stepped on the effect's own clock) and shows where it holds; the town's own choice points
## ask it. Nothing is rolled. Loud: the posts are driven in with a ring of iron, and that is when its danger lands
## (PowerBook.IMPACT), so whoever it frightens is already bound. The law shows for its 30 s: the ring of iron posts and
## the two rules' words in gilt on the ground.

const RADIUS := 7.0
const HOLD_TIME := 30.0
## The posts are driven in, one after another round the ring, from T_DRIVE; the last is in at T_LAND, and the law holds.
const T_DRIVE := 0.2
const T_LAND := 0.8
## The posts sink and the words fade this long once the law lifts (look only).
const FADE := 0.8
## The five rules, in the modes' order, the kind of law each lays, and its words.
const RULES := ["run", "arms", "doors", "sight", "leave"]
const KINDS := {"run": LawZone.NO_RUNNING, "arms": LawZone.NO_ARMS, "doors": LawZone.NO_DOORS, "sight": LawZone.NO_SIGHT,
	"leave": LawZone.NO_LEAVING}
const WORDS := {"run": "NO RUNNING", "arms": "NO ARMS", "doors": "NO DOORS", "sight": "NO SIGHT", "leave": "NO LEAVING"}

## The wheel's words for the rules (the wheel upper-cases them; short, so three fit its slices): each reads as the rule, never as a command.
const ORDER_WORDS := {"run": "no run", "arms": "no arms", "doors": "no doors", "sight": "no sight", "leave": "no exit"}

## The cast's mode: its two rules joined by "_" (run_arms .. sight_leave).
var mode := "run_arms"
## Its two rules (RULES' keys), in order.
var rules := PackedStringArray(["run", "arms"])
## The law on the place (LawZone, the two kinds): laid at T_LAND, lifted at the end. null before.
var law: LawZone
## Third Clause (level 5): the rule (a RULES key) the player added through the order wheel, "" until then; and when (the cast's
## clock). One only; it lifts with the fence (it is a kind of the same LawZone, which is lifted whole).
var third := ""
var third_at := 0.0
## The fence's centre sigil (level 5): the subject the order wheel opens on. Tracked, so it goes with the cast.
var sigil: Node2D
var _twist := false
## The law's hum while it holds (a looping cue, faded at the lift), and when the next turn at the fence may sound (NO LEAVING):
## one ting at most every TURN_SOUND_GAP.
const TURN_SOUND_GAP := 0.5
var _hum: Node
var _next_turn := 0.0


## The two rules a mode names, in order; a mode that names no two of them is NO RUNNING + NO ARMS.
static func rules_of(m: String) -> PackedStringArray:
	var parts := m.split("_")
	if parts.size() != 2 or not KINDS.has(parts[0]) or not KINDS.has(parts[1]) or parts[0] == parts[1]:
		return PackedStringArray(["run", "arms"])
	return parts


## The two kinds of law a mode lays.
static func kinds_of(m: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for r in rules_of(m):
		out.append(KINDS[r])
	return out


## This cast's numbers at its ability level (the consts at level 1).
var lv_radius := RADIUS
var lv_hold_time := HOLD_TIME


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "fenced", "RADIUS", RADIUS))
	lv_hold_time = float(PowerBook.stat(extra, "fenced", "HOLD_TIME", HOLD_TIME))
	_twist = PowerBook.twist_at(extra, "fenced")
	rules = rules_of(String(extra.get("mode", "run_arms")))
	mode = "_".join(rules)
	duration = T_LAND + lv_hold_time + FADE
	busy = T_LAND
	at(T_LAND, _land)
	at(T_LAND + lv_hold_time, _lift)
	ctx.play(&"fe_posts", origin)
	if _twist and ctx.overhead != null:
		var s := Sigil.new()
		s.fx = self
		s.ground_pos = origin
		s.position = Iso.ground_to_screen(origin).round()
		s.z_index = 5
		sigil = track(s, ctx.overhead) as Node2D
	if not DominionParts.staged(self):
		return
	DecreeParts.proclaim(self, origin, 70.0, 76.0, T_DRIVE + 0.2, 0.6)
	var mark := FxParts.rings(self, origin, lv_radius, DecreeParts.GILT, 2, 24.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_LAND, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = T_LAND + 0.1
	# The fence: its posts, rail and words, drawn from the first post's fall to the last one sinking.
	var fence := Fence.new()
	fence.fx = self
	fence.position = Iso.ground_to_screen(origin).round()
	fence.z_index = 4
	track(fence, ctx.overhead_back)


## The last post is in: the two rules hold from now.
func _land() -> void:
	law = LawZone.circle(origin, lv_radius, kinds_of(mode), lv_hold_time)
	law.stepped_by_holder = true
	if ctx.crowd != null:
		ctx.crowd.add_law(law, self)
		ctx.crowd.step_law(law, 0.0)  # whoever stands inside is bound from this frame
	else:
		law.hold_by(self)
	_hum = ctx.play(&"law_hum", origin)
	if not DominionParts.staged(self):
		return
	DecreeParts.wave(self, origin, lv_radius * 1.05, 0.7, 0.05)
	var plate := DecreeParts.seal(self, origin, DecreeParts.BARS, 2.2, 84.0, 4)
	plate.shrink_at = 1.4
	plate.shrink_px = 2


## The law lifts: both rules end, and whoever they held is let go.
func _lift() -> void:
	if law != null:
		if ctx.crowd != null:
			ctx.crowd.remove_law(law)
		else:
			law.lift()
	_hush(0.6)
	if t >= T_LAND + lv_hold_time:
		ctx.play(&"fe_sink", origin)
	if DominionParts.staged(self):
		DecreeParts.wave(self, origin, lv_radius * 1.1, 0.5, 0.04)


## The hum fades over `seconds`, if the voice is still this fence's.
func _hush(seconds: float) -> void:
	if _hum != null and is_instance_valid(_hum) and _hum.get_meta(&"cue", &"") == &"law_hum":
		ctx.fade_out(_hum, seconds)
	_hum = null


func _finish() -> void:
	_hush(0.3)
	super()


func _exit_tree() -> void:
	_hush(0.3)
	super()


## Third Clause (level 5): the law holds now and no third rule has been added.
func can_follow_up() -> bool:
	return _twist and not finished and third == "" and law != null and law.alive()


## The wheel opens on the fence's centre sigil.
func follow_up_wheel() -> bool:
	return true


func follow_up_subject() -> Node2D:
	return sigil if is_instance_valid(sigil) else null


## The wheel's words (ORDER_WORDS) of the rules not in force, in RULES' order: three while the cast's two hold, none once a third is added.
func follow_up_orders() -> Array:
	var out: Array = []
	for r in RULES:
		if not rules.has(r) and r != third:
			out.append(ORDER_WORDS[r])
	return out


## An order from the wheel: {"order": the wheel's word of a rule not in force}. It joins the live law for the time it has left, once; anything else
## (a rule already in force, an unknown word, a second clause, no law) is refused and changes nothing.
func follow_up(_at: Vector2, extra_data: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var shown := String(extra_data.get("order", ""))
	if not follow_up_orders().has(shown):
		return false
	var word: String = ORDER_WORDS.find_key(shown)
	third = word
	third_at = t
	var kind: StringName = KINDS[word]
	if not law.kinds.has(kind):
		law.kinds.append(kind)
	if DominionParts.staged(self):
		DecreeParts.wave(self, origin, lv_radius * 0.6, 0.5, 0.04)
		ctx.play(&"fe_posts", origin)
	return true


## Cut short (an act of the night ends): the law is lifted with it.
func end_now() -> void:
	if not finished and law != null and law.alive():
		_lift()
	super()


func _fx_process(delta: float) -> void:
	if law == null or not law.alive():
		return
	# The law's clock starts when the last post is in, so it holds to the last frame before the lift.
	var dt := minf(delta, t - T_LAND)
	if ctx.crowd != null:
		ctx.crowd.step_law(law, dt)
	else:
		law.step(dt, [], [])
	if not law.turned.is_empty() and t >= _next_turn:
		_next_turn = t + TURN_SOUND_GAP
		ctx.play(&"law_turn", law.turned[0][1])


## When post `i` of `n` is driven home: one after another round the ring, the last at T_LAND.
static func driven_at(i: int, n: int) -> float:
	return T_DRIVE + (T_LAND - T_DRIVE) * float(i + 1) / float(n)


## How far the posts stand out of the ground (0..1): each driven home in its turn, all of them while the law holds,
## sinking as it lifts.
func standing(i: int, n: int) -> float:
	if t >= T_LAND + lv_hold_time:
		return clampf(1.0 - (t - T_LAND - lv_hold_time) / FADE, 0.0, 1.0)
	return 1.0 if t >= driven_at(i, n) else 0.0


## How much of the words shows: written in after the posts are in, whole while the law holds, gone as it lifts.
func shown() -> float:
	if t < T_LAND:
		return 0.0
	if t < T_LAND + lv_hold_time:
		return clampf((t - T_LAND) / 0.4, 0.0, 1.0)
	return clampf(1.0 - (t - T_LAND - lv_hold_time) / FADE, 0.0, 1.0)


## The fence, drawn in screen space round its middle (over the town, as every Decree mark is): a ring of iron posts on
## the circle's rim, each driven down from above in its turn and struck home with a gilt spark, joined by an iron rail
## low on the ground and drawn far ones first; inside it an ink wash and the two rules' words in gilt on ink plates laid
## flat on the ground. Its shapes are laid out once; each frame only draws them.
class Fence extends Node2D:
	const POSTS := 36
	## A post's height and half width, in screen pixels; how high it falls from as it is driven; how long its spark shows.
	const HIGH := 34.0
	const HALF := 3.5
	const DROP := 60.0
	const FALL := 0.12
	const SPARK := 0.2
	const WASH := Color(0.07, 0.04, 0.11, 0.24)
	const IRON := Color(0.15, 0.15, 0.2)
	const IRON_LIGHT := Color(0.5, 0.5, 0.58)
	## The words' size, and how flat they lie on the ground.
	const SIZE := 22
	const FLAT := Vector2(2.0, 1.1)
	var fx: FencedFx
	var _disc := PackedVector2Array()
	## Each post's foot, in screen pixels round (0, 0), in its turn round the ring; and the order to draw them, far first.
	var _feet := PackedVector2Array()
	var _order := PackedInt32Array()
	## The rail: the posts' feet, the ring closed.
	var _rail := PackedVector2Array()
	var _words := PackedStringArray()
	var _widths := PackedFloat32Array()
	var _third_word := ""
	var _third_w := 0.0

	## The ground circle's half width and half height on screen.
	static func half_axes(r := RADIUS) -> Vector2:
		return Vector2(r * 32.0 * sqrt(2.0), r * 16.0 * sqrt(2.0))

	func _ready() -> void:
		var h := half_axes(fx.lv_radius)
		for i in 40:
			_disc.append(Vector2.from_angle(TAU * float(i) / 40.0))
		var order: Array[int] = []
		for i in POSTS:
			# Driven in one after another in one sweep round the ring, from its left-hand end.
			var ang := PI + TAU * float(i) / float(POSTS)
			_feet.append(Vector2(cos(ang), sin(ang)) * h)
			order.append(i)
		order.sort_custom(func(a: int, b: int) -> bool: return _feet[a].y < _feet[b].y if _feet[a].y != _feet[b].y else a < b)
		for i in order:
			_order.append(i)
		_rail = _feet.duplicate()
		_rail.append(_feet[0])
		for r in fx.rules:
			_words.append(String(WORDS[r]))
			_widths.append(UiTheme.width(String(WORDS[r]), SIZE))

	func _process(_delta: float) -> void:
		if fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		_draw_ground(now)
		for i in _order:
			_draw_post(i, now)

	## The wash, the rail and the words: on the ground, under the posts.
	func _draw_ground(now: float) -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var h := half_axes(fx.lv_radius)
		draw_set_transform(Vector2.ZERO, 0.0, h)
		draw_colored_polygon(_disc, Color(WASH, WASH.a * a))
		draw_set_transform(Vector2.ZERO)
		draw_polyline(_rail, Color(DecreeParts.INK, 0.75 * a), 7.0)
		draw_polyline(_rail, Color(IRON_LIGHT, 0.9 * a), 3.0)
		draw_polyline(_rail, Color(DecreeParts.GILT, 0.6 * a), 1.0)
		# The two rules' words, laid flat on the ground on ink plates: the first above the middle, the second below,
		# each written in as its stroke runs under it.
		var font := UiTheme.font()
		for k in _words.size():
			var stroke := clampf((now - T_LAND - 0.15 * float(k)) / 0.35, 0.0, 1.0)
			_draw_word(font, _words[k], _widths[k], (-0.3 if k == 0 else 0.3) * h.y, stroke, a)
		# Third Clause: the added rule's words, written in below the two once it is added.
		if fx.third != "":
			if _third_word == "":
				_third_word = String(WORDS[fx.third])
				_third_w = UiTheme.width(_third_word, SIZE)
			_draw_word(font, _third_word, _third_w, 0.7 * h.y, clampf((now - fx.third_at) / 0.35, 0.0, 1.0), a)
		draw_set_transform(Vector2.ZERO)

	## One rule's words on their ink plate, laid flat at `y`, its gilt stroke run `stroke` of the way.
	func _draw_word(font: Font, word: String, w: float, y: float, stroke: float, a: float) -> void:
		draw_set_transform(Vector2(0.0, y), 0.0, FLAT)
		var at := Vector2(-w * 0.5, 7.0).round()
		var plate := Rect2(at + Vector2(-5.0, -SIZE + 2.0), Vector2(w + 10.0, SIZE + 6.0))
		draw_rect(plate.grow(1.0), Color(DecreeParts.GILT, 0.55 * a))
		draw_rect(plate, Color(DecreeParts.INK, 0.72 * a))
		draw_string(font, at + Vector2(1.0, 1.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(DecreeParts.INK, a))
		draw_string(font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(DecreeParts.GILT, a))
		var line := at.y + 4.0
		draw_line(Vector2(at.x - 3.0, line), Vector2(at.x - 3.0 + (w + 6.0) * stroke, line), Color(DecreeParts.GILT, 0.9 * a), 1.0)

	## Post `i`: falling from above until it is driven home, a gilt spark at its foot as it strikes, then standing; it
	## sinks as the law lifts.
	func _draw_post(i: int, now: float) -> void:
		var home := FencedFx.driven_at(i, POSTS)
		var foot := _feet[i]
		var drop := 0.0
		var stand := fx.standing(i, POSTS)
		if now < home:
			var fall := (now - (home - FALL)) / FALL
			if fall < 0.0:
				return
			drop = DROP * (1.0 - fall * fall)
			stand = 1.0
		if stand <= 0.0:
			return
		var high := HIGH * stand
		var top := foot + Vector2(0.0, -high - drop)
		var base := foot + Vector2(0.0, -drop)
		# Its shadow on the ground once it is in.
		if drop <= 0.0:
			draw_line(foot + Vector2(-HALF, 1.5), foot + Vector2(HALF + 6.0, 1.5), Color(DecreeParts.INK, 0.6 * stand), 3.0)
		draw_rect(Rect2(top + Vector2(-HALF - 1.5, -1.5), Vector2(HALF * 2.0 + 3.0, high + 3.0)), Color(DecreeParts.INK, 0.95))
		draw_rect(Rect2(top + Vector2(-HALF, 0.0), Vector2(HALF * 2.0, high)), IRON)
		draw_rect(Rect2(top + Vector2(-HALF, 0.0), Vector2(2.0, high)), IRON_LIGHT)
		# A gilt finial: a flat cap and a spear point over it, the law's mark on every post.
		draw_rect(Rect2(top + Vector2(-HALF - 1.5, -4.0), Vector2(HALF * 2.0 + 3.0, 3.0)), DecreeParts.GILT)
		draw_rect(Rect2(top + Vector2(-1.5, -8.0), Vector2(3.0, 4.0)), DecreeParts.GILT)
		draw_rect(Rect2(top + Vector2(-0.5, -10.0), Vector2(1.0, 2.0)), Color(1.0, 0.96, 0.82))
		# Struck home: a gilt spark round its foot, thrown out and gone.
		var since := now - home
		if since >= 0.0 and since < SPARK:
			var k := since / SPARK
			var r := 4.0 + 14.0 * k
			var c := Color(DecreeParts.GILT, 1.0 - k)
			draw_line(base + Vector2(-r, 0.0), base + Vector2(-r * 0.4, -r * 0.35), c, 2.0)
			draw_line(base + Vector2(r, 0.0), base + Vector2(r * 0.4, -r * 0.35), c, 2.0)
			draw_line(base + Vector2(-r * 0.7, 1.0), base + Vector2(r * 0.7, 1.0), Color(DecreeParts.INK, 0.6 * (1.0 - k)), 3.0)


## Third Clause's centre sigil (level 5): a small gilt clause mark on the ground at the fence's middle, where the order wheel
## opens. A subject for Targeting (ground_pos, is_alive()); drawn only, no simulation state. It stands while the cast can take the
## clause (the law holds, none added yet), and is freed with the cast.
class Sigil extends Node2D:
	var fx: FencedFx
	var ground_pos := Vector2.ZERO

	func is_alive() -> bool:
		return is_instance_valid(fx) and fx.can_follow_up()

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(fx) or fx.law == null or fx.third != "":
			return
		var a := clampf(fx.shown(), 0.0, 1.0)
		if a <= 0.0:
			return
		var pulse := 0.65 + 0.35 * sin(fx.t * 4.0)
		var g := Color(DecreeParts.GILT, a * pulse)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.0, 1.0))
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, Color(DecreeParts.INK, a * 0.8), 4.0)
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, g, 2.0)
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(-1.0, -8.0, 2.0, 16.0), g)
		draw_rect(Rect2(-8.0, -1.0, 16.0, 2.0), g)
