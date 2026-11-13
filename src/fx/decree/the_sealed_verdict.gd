class_name SealedFx
extends FxTimeline
## The Sealed Verdict (Decree, Tier V; spec 5.10; the Judge's death verdict, a law that holds once written): a district
## of RADIUS round the click is written into the brass ledger. Only the player sees it: everything before the stroke is
## drawn on the god's overlay (ctx.overhead) -- its circle, the runes counting down round it, the gilt script chains
## turning round its rim, the ledger page inside it inking a tally of the souls inside, and over the last DUSK seconds
## the district darkening while a brass bell comes down over its middle. The town sees nothing -- the cast is quiet (no
## alarm, no danger, no fright), no law is laid for its choices to ask, nobody is marked -- and goes on, walking in and
## out.
## At COUNTDOWN the bell strikes once (q_sealed_hit), a great seal stamps down on the middle, and everyone inside at that
## moment dies in that one frame, where he stands, without a cry (kill kind verdict, a quiet death:
## DeathVoices.QUIET_KINDS):
##   out of doors  every living person standing within RADIUS (soldiers, inquisitors and a rite's chained captive too:
##                 a verdict outruns any chain);
##   sheltering    everyone sheltering in a house whose place (its middle, where they stand) lies inside: a house inside
##                 the circle is inside. They are brought out at its door and die there, for the town to find;
##   at home       one kept indoors for the night (NightRules) whose place lies inside dies at home.
## Whoever another system holds indoors -- a director's charge "untouchable until brought out", the trapped under rubble
## (RescueManager), those aboard the ferry -- is that system's to keep, and is passed by; so are hounds and other Visitors
## (the verdict is on people). After the stroke the bodies are found like any other dead (Crowd._on_killed: the alarm, an
## incident, the investigation); the verdict is carried out once, and whoever walks in afterwards lives. Cut short before
## the stroke (end_now: an act of the night ends), it is never carried out. Who dies is where each stands at the stroke,
## never a roll, and nothing in its look is rolled either. Once a descent (PowerBook cooldown 999).

const RADIUS := 10.0
const COUNTDOWN := 30.0
const KIND := &"verdict"
## The quill writes the district into the ledger; the other slots wait this long.
const WRITE := 0.6
## The ledger's circle fades out after the stroke (look only).
const FADE := 1.5
## Over the last seconds the circle beats with each one (look only).
const TOLL_FROM := 10.0
## At most this many of the dead get a gilt line from the seal and a soul rising from them (look only; the rest fall
## just the same).
const FLECKS := 24
## Over the last DUSK seconds the district darkens and the bell comes down over its middle (look only).
const DUSK := 5.0
## The seal's fall onto the middle, ending at the stroke (look only).
const DROP := 0.12
## The seal burnt into the ground fades over BURN after the stroke; the effect lasts until it has (look only).
const BURN := 4.0
## The ledger page counts the souls inside this often (look only).
const TALLY_EVERY := 0.5

## Whether the bell has struck (the verdict is carried out), and how many it took.
var struck := false
var dead := 0
var _ledger: Ledger
var _next_tally := 0.0


## Seconds until the stroke (0 once it has struck).
func left() -> float:
	return maxf(COUNTDOWN - t, 0.0)


func _build() -> void:
	duration = COUNTDOWN + BURN
	busy = WRITE
	at(COUNTDOWN, _stroke)
	ctx.play(&"q_sealed", origin)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, RADIUS, DecreeParts.GILT, 1, 40.0)
	mark.set_param("scan", 0.0)
	mark.set_param("crosshair", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, WRITE, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.tween_param("alpha", 1.0, 0.0, 0.6, WRITE + 0.2)
	mark.life = WRITE + 0.9
	var plate := DecreeParts.seal(self, origin, DecreeParts.HOURGLASS, 2.2, 46.0, 3)
	plate.shrink_at = 1.2
	_ledger = Ledger.new()
	_ledger.fx = self
	_ledger.position = Iso.ground_to_screen(origin).round()
	_ledger.z_index = 3
	track(_ledger, ctx.overhead)


## The ledger page's tally, counted every TALLY_EVERY until the stroke (only when it is drawn).
func _fx_process(_delta: float) -> void:
	if _ledger == null or struck or t < _next_tally:
		return
	_next_tally = t + TALLY_EVERY
	_ledger.souls = souls_at(ctx.crowd, ctx.field, origin)


## Everyone the verdict takes at `at`, but those sheltering (their houses are found by shelters_at()): every living person
## out of doors within RADIUS, then those kept at home for the night whose place lies inside; nearest first, a tie to the
## earlier instance.
static func doomed_at(crowd: Crowd, field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, RADIUS):
		var p := e as Person
		if p != null and p.is_alive() and not p.inside:
			out.append(p)
	if crowd != null:
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if is_instance_valid(p) and p.is_alive() and p.inside and p.night_indoors \
						and p.ground_pos.distance_squared_to(at) <= RADIUS * RADIUS:
					out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	return out


## The shelters with people in them whose place lies within RADIUS of `at`, in the town's order.
static func shelters_at(crowd: Crowd, at: Vector2) -> Array[Structure]:
	var out: Array[Structure] = []
	if crowd == null or crowd.shelters == null:
		return out
	for s: Structure in crowd.shelters.shelters:
		if is_instance_valid(s) and crowd.shelters.occupants(s) > 0 and s.center().distance_squared_to(at) <= RADIUS * RADIUS:
			out.append(s)
	return out


## How many the verdict would take if the bell struck now: those doomed_at() and everyone sheltering in shelters_at().
static func souls_at(crowd: Crowd, field: EnemyField, at: Vector2) -> int:
	var n := doomed_at(crowd, field, at).size()
	for s in shelters_at(crowd, at):
		n += crowd.shelters.occupants(s)
	return n


## The bell strikes once: everyone inside dies in this frame. Who is taken is settled before the first falls, so the town's
## reaction to one death never changes who else dies.
func _stroke() -> void:
	if struck:
		return
	struck = true
	ctx.play(&"q_sealed_hit", origin)
	var doomed := doomed_at(ctx.crowd, ctx.field, origin)
	for s in shelters_at(ctx.crowd, origin):
		doomed.append_array(ctx.crowd.shelters.throw_out_of(s, 0.0))  # brought out at the door, where the body is found
	var staged := _ledger != null and DominionParts.staged(self)
	for p in doomed:
		var at_g := p.ground_pos
		if not ctx.field.kill(p, KIND, at_g):
			continue
		dead += 1
		if staged and dead <= FLECKS:
			_ledger.taken(Iso.ground_to_screen(at_g))
			if not p.inside:
				DecreeParts.scatter(self, at_g, 4, 10.0)
	if not staged:
		return
	_ledger.souls = dead
	DecreeParts.wave(self, origin, RADIUS, 0.9, 0.03)
	DecreeParts.wave(self, origin, 3.2, 0.35, 0.12)
	var glow := FxParts.bloom(self, _ledger.position, 110.0, DecreeParts.GILT, 1.6, 0.6)
	glow.tween_param("intensity", 1.6, 0.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	glow.life = 0.65
	if ctx.flash.is_valid():
		ctx.flash.call(Color(1.0, 0.9, 0.6, 0.3), 0.25)
	if ctx.shake != null:
		ctx.shake.add_trauma(0.3)
	var brand := Brand.new()
	brand.position = origin
	brand.z_index = 1
	track(brand, ctx.ground)


## How much of the ledger's circle shows: written in over WRITE, whole until the stroke, gone over FADE after it.
func shown() -> float:
	if t < COUNTDOWN:
		return clampf(t / WRITE, 0.0, 1.0)
	return clampf(1.0 - (t - COUNTDOWN) / FADE, 0.0, 1.0)


## How dark the district is drawn: none until the last DUSK seconds, deepening to the stroke, lifted just after it.
func dusk() -> float:
	if t < COUNTDOWN:
		var k := clampf((t - (COUNTDOWN - DUSK)) / DUSK, 0.0, 1.0)
		return k * k * (3.0 - 2.0 * k)
	return clampf(1.0 - (t - COUNTDOWN) / 0.8, 0.0, 1.0)


## The ledger's entry, drawn for the player alone on the god's overlay round the district's middle, see-through so
## the town shows through it: a thin brass circle (ink under it so it reads on any ground); round its outside a rune
## for each of the COUNTDOWN seconds, from the top round clockwise, each going dark as its second is spent, the next one
## lit gilt; round its inside a brass and gilt chain turning one way and a band of gilt script turning the other; over
## the middle the seconds left, in gilt on a small ink page edged in brass; and inside the circle, east of the middle, the
## ledger's page, where a gilt tally of the souls inside is inked in as it changes. Over the last TOLL_FROM seconds the circle beats with
## each one; over the last DUSK the district darkens and a brass bell is let down on its chain over the middle.
## At the stroke the bell is gone, a great seal falls (DROP) and stamps the middle, a gilt line runs from it to each of
## the dead it took (FLECKS at most) and a soul rises from each. Its shapes are laid out once and its lines filled in
## place each frame; the texts are made only when they change.
class Ledger extends Node2D:
	const BRASS := Color("c8963c")
	const BRASS_DARK := Color("6e4a1c")
	const PALE := Color("fff6d0")
	## Bright brass: the runes still to come and the chain's heavy links, to read over a busy town.
	const BRIGHT := Color("e8b44c")
	const MARKS := 30  # one rune a second: COUNTDOWN
	const ALPHA := 0.8
	const SIZE := 20
	const LINKS := 48
	const SCRIPT := 64
	## The darkness over the district at its deepest.
	const DARK := 0.42
	## The tally page: where it hangs inside the circle, east of its middle (PAGE_IN of the way to the rim, so it stays
	## on screen at play zoom), its size, and the most marks it holds.
	const PAGE_IN := 0.5
	const PAGE_SIZE := Vector2(124, 96)
	## The page's words, as big as the seconds' (the town is played zoomed out: Mission.PLAY_ZOOM).
	const PAGE_TEXT := 20
	const TALLY_MAX := 40
	## Marks inked per second as the tally changes.
	const INK_RATE := 10.0
	## The bell: its scale, where its lip ends (above the seconds' page) and where it starts, in screen pixels.
	const BELL_SCALE := 2.4
	const BELL_FROM := -340.0
	const BELL_TO := -30.0
	## The great seal's radius on the ground; how high it falls from.
	const SEAL_R := 1.5
	const SEAL_FALL := 140.0
	## A soul rises this high over this long; a gilt line is drawn out over LINE_IN and gone by LINE_OUT.
	const WISP_UP := 72.0
	const WISP_LIFE := 2.6
	const LINE_IN := 0.15
	const LINE_OUT := 1.2

	var fx: SealedFx
	## The souls inside, as last counted (the dead taken, once struck).
	var souls := 0
	var _rim := PackedVector2Array()
	var _disc := PackedVector2Array()
	var _disc_out := PackedVector2Array()
	## Each rune's three strokes (pairs of points) and their colours, one per stroke.
	var _runes := PackedVector2Array()
	var _rune_cols := PackedColorArray()
	var _links_a := PackedVector2Array()
	var _links_b := PackedVector2Array()
	var _script := PackedVector2Array()
	var _tally := PackedVector2Array()
	var _tally_cols := PackedColorArray()
	var _bell := PackedVector2Array()
	var _bell_shine := PackedVector2Array()
	var _glyph := PackedVector2Array()
	## The dead the seal reaches (FLECKS at most), in this node's pixels; the gilt lines to them, filled in place.
	var _dead := PackedVector2Array()
	var _lines := PackedVector2Array()
	var _page_at := Vector2.ZERO
	var _inked := 0.0
	var _secs := -1
	var _text := ""
	var _w := 0.0
	var _count := -1
	var _count_text := ""
	var _count_w := 0.0
	var _head := ""

	## The ground circle of RADIUS's half width and half height on screen.
	static func half_axes() -> Vector2:
		return Vector2(RADIUS * 32.0 * sqrt(2.0), RADIUS * 16.0 * sqrt(2.0))

	## The point at `angle` on the circle grown `k` times, in screen pixels from the middle.
	static func on_rim(angle: float, k: float) -> Vector2:
		return Vector2(cos(angle), sin(angle)) * half_axes() * k

	func _ready() -> void:
		var h := half_axes()
		for i in 65:
			_rim.append(Vector2.from_angle(TAU * float(i) / 64.0) * h)
		for i in 64:
			_disc.append(_rim[i])
			_disc_out.append(_rim[i] * 1.05)
		for i in MARKS:
			# From the top of the circle, round clockwise, as a clock's hand goes.
			var ang := -PI * 0.5 + TAU * float(i) / float(MARKS)
			var b := on_rim(ang, 1.03)
			var u := (on_rim(ang, 1.11) - b).normalized() * 22.0
			var v := Vector2(-u.y, u.x).normalized()
			_runes.append_array(PackedVector2Array([b, b + u]))
			match i % 3:
				0:  # a stem crossed twice
					_runes.append_array(PackedVector2Array([b + u * 0.55 - v * 6.0, b + u * 0.55 + v * 6.0, b + u - v * 5.0, b + u + v * 5.0]))
				1:  # a stem with two branches
					_runes.append_array(PackedVector2Array([b + u * 0.8, b + u * 0.55 + v * 8.0, b + u * 0.5, b + u * 0.25 + v * 8.0]))
				_:  # an arrow
					_runes.append_array(PackedVector2Array([b + u, b + u * 0.6 - v * 6.0, b + u, b + u * 0.6 + v * 6.0]))
			for k in 3:
				_rune_cols.append(BRASS)
		_links_a.resize(LINKS)
		_links_b.resize(LINKS)
		_script.resize(SCRIPT * 2)
		_page_at = Vector2(h.x * PAGE_IN, -PAGE_SIZE.y * 0.5).round()
		# Groups of five, four groups a row: four strokes and one across them.
		for m in TALLY_MAX:
			@warning_ignore("integer_division")
			var g := m / 5
			var j := m % 5
			@warning_ignore("integer_division")
			var o := _page_at + Vector2(12.0 + float(g % 4) * 27.0, 38.0 + float(g / 4) * 28.0)
			if j < 4:
				_tally.append_array(PackedVector2Array([o + Vector2(j * 5.0, 0.0), o + Vector2(j * 5.0, 18.0)]))
			else:
				_tally.append_array(PackedVector2Array([o + Vector2(-3.0, 15.0), o + Vector2(18.0, 3.0)]))
			_tally_cols.append(Color(0, 0, 0, 0))
		# The bell's outline, the lip's middle at (0, 0): the right side down from the crown, then the left side back up.
		var side := [Vector2(0, -44), Vector2(5, -43), Vector2(9, -40), Vector2(11, -34), Vector2(12, -24), Vector2(13, -14),
			Vector2(16, -7), Vector2(20, -3), Vector2(22, 0)]
		for pt: Vector2 in side:
			_bell.append(pt)
		for i in range(side.size() - 1, 0, -1):
			_bell.append(Vector2(-side[i].x, side[i].y))
		for i in range(2, 7):
			_bell_shine.append(Vector2(-side[i].x * 0.55, side[i].y))
		# The seal's sign, on the ground: HOURGLASS, a cell a square of ground 0.34 across.
		for r in 5:
			for c in 5:
				if DecreeParts.HOURGLASS[r] & (1 << (4 - c)):
					_glyph.append(Vector2(c - 2.5, r - 2.5) * 0.34)

	## One of the dead, at `screen` (a screen point), for a gilt line and a rising soul.
	func taken(screen: Vector2) -> void:
		_dead.append(screen - position)
		_lines.append(Vector2.ZERO)
		_lines.append(Vector2.ZERO)

	func _process(delta: float) -> void:
		if fx.t > fx.duration:
			queue_free()
			return
		# The tally is inked in a mark at a time, and struck off as quickly.
		var want := float(mini(souls, TALLY_MAX))
		_inked = move_toward(_inked, want, INK_RATE * delta)
		queue_redraw()

	func _draw() -> void:
		var d := fx.dusk()
		if d > 0.0:
			draw_colored_polygon(_disc_out, Color(DecreeParts.INK, d * DARK * 0.5))
			draw_colored_polygon(_disc, Color(DecreeParts.INK, d * DARK * 0.5))
		var a := fx.shown() * ALPHA
		var left := fx.left()
		var beat := 0.0
		if left < TOLL_FROM and left > 0.0:
			beat = 1.0 - fposmod(left, 1.0)
			beat = beat * beat
		var lit := 0.0 if fx.struck else beat * 0.5
		if a > 0.0:
			_draw_circle(a, lit)
			_draw_page(a)
		if not fx.struck:
			_draw_bell(lit)
			_draw_seconds(a, lit, left)
		_draw_seal()
		if fx.struck:
			_draw_dead()

	## The circle, its runes, its chain and its script.
	func _draw_circle(a: float, lit: float) -> void:
		draw_polyline(_rim, Color(DecreeParts.INK, a * 0.8), 9.0)
		draw_polyline(_rim, Color(BRASS.lerp(DecreeParts.GILT, lit), minf(a + lit * 0.4, 1.0)), 5.0)
		# The seconds: those spent go dark (the last one fading), the next one still to come lit gilt.
		var spent := clampi(int(floor(fx.t)), 0, MARKS)
		var frac := fposmod(fx.t, 1.0)
		for i in MARKS:
			var c := Color(BRIGHT, a)
			if i < spent - 1 or (fx.struck and i < spent):
				c = Color(DecreeParts.INK, a * 0.7)
			elif i == spent - 1:
				c = Color(DecreeParts.GILT.lerp(DecreeParts.INK, clampf(frac / 0.6, 0.0, 1.0)), a)
			elif i == spent and not fx.struck:
				c = Color(DecreeParts.GILT.lerp(PALE, lit), minf(a * 1.8, 1.0))
			for k in 3:
				_rune_cols[i * 3 + k] = c
		draw_multiline(_runes, Color(DecreeParts.INK, a * 0.8), 6.5)
		draw_multiline_colors(_runes, _rune_cols, 3.5)
		# The chain turns clockwise, the script against it.
		var step := TAU / float(LINKS)
		var turn := fx.t * 0.12
		for i in LINKS:
			var a0 := turn + float(i) * step
			@warning_ignore("integer_division")
			var slot := (i / 2) * 2
			# Every other link is the thick brass one; written in place (a packed array is copied when shared).
			if i % 2 == 0:
				_links_a[slot] = on_rim(a0, 0.95)
				_links_a[slot + 1] = on_rim(a0 + step * 0.8, 0.95)
			else:
				_links_b[slot] = on_rim(a0, 0.95)
				_links_b[slot + 1] = on_rim(a0 + step * 0.8, 0.95)
		draw_multiline(_links_a, Color(DecreeParts.INK, a * 0.7), 8.0)
		draw_multiline(_links_a, Color(BRIGHT, a), 5.0)
		draw_multiline(_links_b, Color(PALE, a), 2.5)
		var sstep := TAU / float(SCRIPT)
		var back := -fx.t * 0.08
		for i in SCRIPT:
			var a0 := back + float(i) * sstep
			var long := 0.25 + 0.5 * float((i * 7) % 5) / 4.0
			_script[i * 2] = on_rim(a0, 0.89)
			_script[i * 2 + 1] = on_rim(a0 + sstep * long, 0.89)
		draw_multiline(_script, Color(DecreeParts.INK, a * 0.6), 4.5)
		draw_multiline(_script, Color(DecreeParts.GILT, a), 2.5)

	## The ledger's page inside the circle, east of the middle: who is inside, as a gilt tally inked in.
	func _draw_page(a: float) -> void:
		var page := Rect2(_page_at, PAGE_SIZE)
		draw_rect(page.grow(2.0), Color(BRASS, a))
		draw_rect(page, Color(DecreeParts.INK, minf(a * 1.4, 1.0)))
		for y in [31.0, 59.0, 87.0]:
			draw_line(_page_at + Vector2(4.0, y), _page_at + Vector2(PAGE_SIZE.x - 4.0, y), Color(BRASS_DARK, a), 2.0)
		var head := "TAKEN" if fx.struck else "INSIDE"
		if souls != _count or head != _head:
			_count = souls
			_head = head
			_count_text = str(souls)
			_count_w = UiTheme.width(_count_text, PAGE_TEXT)
		var font := UiTheme.font()
		var ink := Color(DecreeParts.GILT, minf(a * 1.8, 1.0))
		draw_string(font, _page_at + Vector2(7.0, 23.0), _head, HORIZONTAL_ALIGNMENT_LEFT, -1, PAGE_TEXT, Color(BRASS, minf(a * 1.8, 1.0)))
		draw_string(font, (_page_at + Vector2(PAGE_SIZE.x - 7.0 - _count_w, 23.0)).round(), _count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, PAGE_TEXT, ink)
		var whole := int(floor(_inked))
		for m in TALLY_MAX:
			_tally_cols[m] = ink if m < whole else Color(0, 0, 0, 0)
		draw_multiline_colors(_tally, _tally_cols, 2.5)
		if whole < TALLY_MAX and _inked > float(whole):
			# The mark being inked, drawn in from its start.
			var from := _tally[whole * 2]
			draw_line(from, from.lerp(_tally[whole * 2 + 1], _inked - float(whole)), ink, 2.5)

	## The seconds left, over the middle.
	func _draw_seconds(a: float, lit: float, left: float) -> void:
		if a <= 0.0:
			return
		var secs := ceili(left)
		if secs != _secs:
			_secs = secs
			_text = str(secs)
			_w = UiTheme.width(_text, SIZE)
		var at := Vector2(-_w * 0.5, -8.0).round()
		var page := Rect2(at + Vector2(-5.0, -17.0), Vector2(_w + 10.0, 22.0))
		draw_rect(page.grow(2.0), Color(BRASS, a))
		draw_rect(page, Color(DecreeParts.INK, minf(a * 1.4, 1.0)))
		var font := UiTheme.font()
		draw_string(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(DecreeParts.GILT.lerp(Color.WHITE, lit), minf(a * 1.8 + lit, 1.0)))

	## Over the last DUSK seconds the bell comes down on its chain over the middle, swaying, glinting with each second.
	func _draw_bell(lit: float) -> void:
		var k := clampf((fx.t - (COUNTDOWN - DUSK)) / DUSK, 0.0, 1.0)
		if k <= 0.0:
			return
		var ba := clampf(k * DUSK / 0.5, 0.0, 1.0) * 0.9
		var down := 1.0 - pow(1.0 - k, 3.0)
		var lip := Vector2(0.0, lerpf(BELL_FROM, BELL_TO, down)).round()
		draw_line(lip + Vector2(0.0, -48.0 * BELL_SCALE), lip + Vector2(0.0, -48.0 * BELL_SCALE - 260.0), Color(BRASS_DARK, ba), 3.0)
		draw_set_transform(lip, sin(fx.t * 2.1) * 0.04 * (1.0 - down * 0.6), Vector2.ONE * BELL_SCALE)
		draw_colored_polygon(_bell, Color(BRASS.lerp(DecreeParts.GILT, lit), ba))
		draw_polyline(_bell, Color(BRASS_DARK, ba), 1.5)
		draw_line(_bell[_bell.size() - 1], _bell[0], Color(BRASS_DARK, ba), 1.5)
		draw_polyline(_bell_shine, Color(PALE, ba * (0.5 + lit)), 1.0)
		draw_line(Vector2(-13, -14), Vector2(13, -14), Color(BRASS_DARK, ba), 1.0)
		draw_line(Vector2(-22, 0), Vector2(22, 0), Color(DecreeParts.GILT, ba), 2.0)
		draw_arc(Vector2(0, -47), 3.0, 0.0, TAU, 10, Color(BRASS_DARK, ba), 1.5)
		draw_circle(Vector2(0, 2), 2.5, Color(BRASS_DARK, ba))
		draw_set_transform(Vector2.ZERO)

	## The great seal: it falls over DROP onto the middle, landing at the stroke, its handle lifts away, and its face
	## lies a moment on the ground in gilt and fades as the burn (Brand) takes its place; a gilt ring runs out from it.
	func _draw_seal() -> void:
		var s := fx.t - COUNTDOWN
		if s < -DROP or s > 0.9:
			return
		var fall := clampf(-s / DROP, 0.0, 1.0)
		var up := SEAL_FALL * fall * fall
		var a := 1.0 if s <= 0.1 else clampf(1.0 - (s - 0.1) / 0.8, 0.0, 1.0)
		var shaft := up + (maxf(s, 0.0) * 500.0 if s > 0.05 else 0.0)
		var sa := clampf(1.0 - maxf(s - 0.05, 0.0) / 0.25, 0.0, 1.0)
		if sa > 0.0:
			draw_rect(Rect2(Vector2(-7.0, -shaft - 52.0), Vector2(14.0, 46.0)), Color(BRASS_DARK, sa))
			draw_rect(Rect2(Vector2(-5.0, -shaft - 52.0), Vector2(4.0, 46.0)), Color(BRASS, sa))
			draw_circle(Vector2(0.0, -shaft - 56.0), 7.0, Color(BRASS, sa))
		draw_set_transform_matrix(Transform2D(Iso.BASIS.x, Iso.BASIS.y, Vector2(0.0, -up)))
		var hot := Color.WHITE.lerp(DecreeParts.GILT, clampf(s / 0.15, 0.0, 1.0))
		draw_circle(Vector2.ZERO, SEAL_R, Color(DecreeParts.INK, a * 0.95))
		draw_arc(Vector2.ZERO, SEAL_R, 0.0, TAU, 40, Color(hot, a), 0.14)
		draw_arc(Vector2.ZERO, SEAL_R * 0.82, 0.0, TAU, 40, Color(hot, a * 0.8), 0.06)
		for cell in _glyph:
			draw_rect(Rect2(cell, Vector2(0.34, 0.34)), Color(hot, a))
		if s > 0.0 and s < 0.4:
			var k := s / 0.4
			draw_arc(Vector2.ZERO, lerpf(SEAL_R, SEAL_R * 2.8, 1.0 - (1.0 - k) * (1.0 - k)), 0.0, TAU, 48,
				Color(PALE, 1.0 - k), lerpf(0.16, 0.03, k))
		draw_set_transform(Vector2.ZERO)

	## A gilt line from the seal to each of the dead, drawn out and gone; a soul rising from each.
	func _draw_dead() -> void:
		var s := fx.t - COUNTDOWN
		var n := _dead.size()
		if n == 0:
			return
		if s < LINE_OUT:
			var drawn := clampf(s / LINE_IN, 0.0, 1.0)
			var la := clampf(1.0 - (s - LINE_IN) / (LINE_OUT - LINE_IN), 0.0, 1.0)
			for i in n:
				_lines[i * 2 + 1] = _dead[i] * drawn + Vector2(0.0, -8.0 * drawn)
			draw_multiline(_lines, Color(DecreeParts.INK, la * 0.7), 5.0)
			draw_multiline(_lines, Color(DecreeParts.GILT, la), 2.0)
		for i in n:
			# Each rises a little after the one before it, nearest first, swaying as it goes.
			var w := (s - LINE_IN - float(i) * 0.04) / WISP_LIFE
			if w <= 0.0 or w >= 1.0:
				continue
			var wa := minf(w / 0.15, 1.0) * (1.0 - maxf(w - 0.6, 0.0) / 0.4)
			var rise := 1.0 - (1.0 - w) * (1.0 - w)
			var base := _dead[i] + Vector2(0.0, -10.0)
			for j in 4:
				var lag := maxf(rise - float(j) * 0.06, 0.0)
				var at := base + Vector2(sin(lag * 7.0 + float(i) * 1.7) * 6.0, -WISP_UP * lag)
				draw_circle(at.round(), 4.0 - float(j) * 0.8, Color(PALE.lerp(DecreeParts.GILT, float(j) / 3.0), wa * (1.0 - float(j) * 0.22)))


## The great seal burnt into the ground at the middle, on the ground plane (in ground units): its rings and its sign,
## glowing like an ember at first, then charred, gone over BURN.
class Brand extends Node2D:
	const R := 2.4
	const EMBER := Color("ff8a2a")
	const CHAR := Color(0.06, 0.04, 0.03)
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		if _age >= BURN:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - _age / BURN
		var hot := clampf(1.0 - _age / 1.2, 0.0, 1.0)
		var line := Color(CHAR.lerp(EMBER, hot), a * 0.9)
		draw_circle(Vector2.ZERO, R * 1.12, Color(CHAR, a * 0.7))
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 48, line, 0.22)
		draw_arc(Vector2.ZERO, R * 0.82, 0.0, TAU, 48, line, 0.1)
		for r in 5:
			for c in 5:
				if DecreeParts.HOURGLASS[r] & (1 << (4 - c)):
					draw_rect(Rect2(Vector2(c - 2.5, r - 2.5) * 0.55, Vector2(0.55, 0.55)), line)
