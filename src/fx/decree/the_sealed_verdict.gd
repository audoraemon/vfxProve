class_name SealedFx
extends FxTimeline
## The Sealed Verdict (Decree, Tier V; spec 5.10; the Judge's death verdict, a law that holds once written): a district
## of RADIUS round the click is written into the brass ledger. Only the player sees it: its circle and its countdown are
## drawn faint in gilt and brass on the god's overlay (ctx.overhead). The town sees nothing -- the cast is quiet (no alarm,
## no danger, no fright), no law is laid for its choices to ask, nobody is marked -- and goes on, walking in and out.
## At COUNTDOWN the bell strikes once (q_sealed_hit), and everyone inside at that moment dies in that one frame, where he
## stands, without a cry (kill kind verdict, a quiet death: DeathVoices.QUIET_KINDS):
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
## never a roll. Once a descent (PowerBook cooldown 999).

const RADIUS := 10.0
const COUNTDOWN := 60.0
const KIND := &"verdict"
## The quill writes the district into the ledger; the other slots wait this long.
const WRITE := 0.6
## The ledger's circle fades out after the stroke (look only).
const FADE := 1.5
## Over the last seconds the circle beats with each one (look only).
const TOLL_FROM := 10.0
## At most this many bodies are flecked with gilt at the stroke (look only; the rest fall just the same).
const FLECKS := 24

## Whether the bell has struck (the verdict is carried out), and how many it took.
var struck := false
var dead := 0
var _ledger: Ledger


## Seconds until the stroke (0 once it has struck).
func left() -> float:
	return maxf(COUNTDOWN - t, 0.0)


func _build() -> void:
	duration = COUNTDOWN + FADE
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
	var staged := DominionParts.staged(self)
	for p in doomed:
		var at_g := p.ground_pos
		if not ctx.field.kill(p, KIND, at_g):
			continue
		dead += 1
		if staged and dead <= FLECKS and not p.inside:
			DecreeParts.scatter(self, at_g, 4, 10.0)
	if not staged:
		return
	DecreeParts.wave(self, origin, RADIUS, 0.9, 0.03)
	var bell := DecreeParts.seal(self, origin, DecreeParts.BELL, 1.8, 14.0, 3)  # where the count stood
	bell.strike()


## How much of the ledger's circle shows: written in over WRITE, whole until the stroke, gone over FADE after it.
func shown() -> float:
	if t < COUNTDOWN:
		return clampf(t / WRITE, 0.0, 1.0)
	return clampf(1.0 - (t - COUNTDOWN) / FADE, 0.0, 1.0)


## The ledger's entry, drawn for the player alone on the god's overlay round the district's middle, faint so the town
## shows through it: a thin brass circle (ink under it so it reads on any ground) ringed with sixty marks, one a second,
## that go dark as the seconds are spent, the hand -- a gilt mark -- moving round to the stroke; and over the middle the
## seconds left, in gilt on a small ink page edged in brass. Over the last TOLL_FROM seconds the circle beats with each
## one. Its shapes are laid out once; the number's text is made only when it changes.
class Ledger extends Node2D:
	const BRASS := Color("c8963c")
	const MARKS := 60
	const ALPHA := 0.55
	const SIZE := 20
	var fx: SealedFx
	var _rim := PackedVector2Array()
	## Each second's mark: its inner and outer points, in screen pixels from the middle.
	var _in := PackedVector2Array()
	var _out := PackedVector2Array()
	var _secs := -1
	var _text := ""
	var _w := 0.0

	## The ground circle of RADIUS's half width and half height on screen.
	static func half_axes() -> Vector2:
		return Vector2(RADIUS * 32.0 * sqrt(2.0), RADIUS * 16.0 * sqrt(2.0))

	func _ready() -> void:
		var h := half_axes()
		for i in 65:
			_rim.append(Vector2.from_angle(TAU * float(i) / 64.0) * h)
		for i in MARKS:
			# From the top of the circle, round clockwise, as a clock's hand goes.
			var u := Vector2.from_angle(-PI * 0.5 + TAU * float(i) / float(MARKS))
			var long := 0.08 if i % 5 == 0 else 0.04
			_in.append(u * h * (1.0 - long))
			_out.append(u * h)

	func _process(_delta: float) -> void:
		if fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown() * ALPHA
		if a <= 0.0:
			return
		var left := fx.left()
		var beat := 0.0
		if left < TOLL_FROM and left > 0.0:
			beat = 1.0 - fposmod(left, 1.0)
			beat = beat * beat
		var lit := 0.0 if fx.struck else beat * 0.5
		draw_polyline(_rim, Color(DecreeParts.INK, a * 0.8), 6.0)
		draw_polyline(_rim, Color(BRASS.lerp(DecreeParts.GILT, lit), minf(a + lit * 0.4, 1.0)), 3.0)
		# The seconds: those spent go dark; the hand is the next one still to come.
		var spent := clampi(int(floor(fx.t)), 0, MARKS)
		for i in MARKS:
			var c := Color(DecreeParts.INK, a * 0.7) if i < spent else Color(BRASS, a)
			if i == spent and not fx.struck:
				c = Color(DecreeParts.GILT, minf(a * 1.8, 1.0))
			draw_line(_in[i], _out[i], c, 3.0)
		if fx.struck:
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
