class_name RedefineFx
extends FxTimeline
## Redefine (Decree, Tier II; spec 5.3): say what a person is and, for SPAN, the law agrees. The MAX_NAMED living people
## nearest the click within PICK_R, out of doors, are named what the cast's mode says -- nearest first, a tie to the
## earlier instance, never a roll -- each by LawMark under this effect's own owner id, and a gilt word floats over each:
##   CRIMINAL  everyone within 4 cells runs from him, and every guard within 8 goes for him and keeps at it until the law ends or he
##             dies (LawMark: a TARGET_ONLY fight); a soldier named so is hunted by his own.
##   OFFICER   one of the garrison: no guard takes him for a suspect (a believer walks past an inquisitor unseized).
##   NOBODY    nobody sees him, strikes him or heeds what he saw.
## Perception only: no count changes (a believer named so still counts). What each law means is LawMark's, asked by every
## sight, seizure, fight and witness check; this effect only names and lifts. At SPAN every mark it set is lifted, and
## when it is cut short or leaves the tree too -- only its own: another power's law on the same man stays. Quiet: its
## own q_redefine cue (a gilt scratch of a quill), no alarm.

const PICK_R := 1.5
const MAX_NAMED := 3
const SPAN := 25.0
## The quill's stroke under each word as it is written (look only).
const WRITE := 0.35
## The words fade out over this long once the law lifts (look only).
const FADE := 0.6
const KINDS := {"criminal": LawMark.CRIMINAL, "officer": LawMark.OFFICER, "nobody": LawMark.NOBODY}
const WORDS := {"criminal": "CRIMINAL", "officer": "OFFICER", "nobody": "NOBODY"}

var mode := "criminal"
## What the law says they are now: KINDS[mode].
var kind := LawMark.CRIMINAL
## Whom it named, nearest first (Persons; any may since have been freed, so untyped).
var named: Array = []
## The marks are lifted (at SPAN, or cut short).
var lifted := false


## The MAX_NAMED living people out of doors within PICK_R of `at`, nearest first, a tie to the earlier instance.
static func named_at(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	if field == null:
		return out
	for e in field.in_radius(at, PICK_R):
		var p := e as Person
		if p != null and p.is_alive() and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	return out.slice(0, MAX_NAMED)


func _build() -> void:
	mode = String(extra.get("mode", "criminal"))
	if not KINDS.has(mode):
		mode = "criminal"
	kind = KINDS[mode]
	duration = SPAN + FADE
	busy = WRITE
	named.assign(named_at(ctx.field, origin))
	for p: Variant in named:
		LawMark.set_law(p, kind, SPAN, get_instance_id())
	at(SPAN, _lift)
	ctx.play(&"q_redefine", origin)
	if DominionParts.staged(self):
		_show()


## The law's word is withdrawn: every mark this cast set is lifted (another owner's stays).
func _lift() -> void:
	if lifted:
		return
	lifted = true
	for p: Variant in named:
		LawMark.lift(p, get_instance_id())


## Cut short (an act of the night ends): the marks are lifted with it.
func end_now() -> void:
	if not finished:
		_lift()
	super()


func _exit_tree() -> void:
	_lift()
	super()


## The writing: a faint gilt ring where the quill touched, flecks of gilt and ink off each one named, and the words.
func _show() -> void:
	var mark := FxParts.rings(self, origin, PICK_R, DecreeParts.GILT, 1, 14.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, WRITE, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.set_param("crosshair", 0.0)
	mark.tween_param("alpha", 1.0, 0.0, 0.5, WRITE + 0.2)
	mark.life = WRITE + 0.75
	for p: Variant in named:
		DecreeParts.scatter(self, (p as Person).ground_pos, 6, Words.HEAD)
	var words := Words.new()
	words.fx = self
	words.z_index = 8
	track(words, ctx.overhead)


## How much of the words shows: written in over WRITE, whole while the law holds, gone over FADE once it lifts.
func shown() -> float:
	if lifted:
		return clampf(1.0 - (t - SPAN) / FADE, 0.0, 1.0) if t >= SPAN else 0.0
	return clampf(t / WRITE, 0.0, 1.0)


## A gilt word over each one named, on an ink plate, bobbing a little: CRIMINAL underlined in the Decree's red, OFFICER in
## gilt, NOBODY pale and broken off, half there. The quill's stroke runs under it as it is written. A word goes when the
## man dies, goes indoors or another law is set over him. Its sizes are measured once; each frame only draws.
class Words extends Node2D:
	## How high over a person's feet his word hangs.
	const HEAD := 38.0
	const SIZE := 11
	var fx: RedefineFx
	var _text := ""
	var _w := 0.0
	var _ink := Color(DecreeParts.INK, 0.8)
	var _line := DecreeParts.GILT
	var _gilt := DecreeParts.GILT

	func _ready() -> void:
		_text = String(WORDS[fx.mode])
		_w = UiTheme.width(_text, SIZE)
		if fx.mode == "criminal":
			_line = DecreeParts.STRUCK
		elif fx.mode == "nobody":
			_gilt = Color(1.0, 0.94, 0.78, 0.6)
			_line = Color(DecreeParts.GILT, 0.45)

	func _process(_delta: float) -> void:
		if fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var font := UiTheme.font()
		var stroke := clampf(fx.t / WRITE, 0.0, 1.0)
		for i in fx.named.size():
			var body: Variant = fx.named[i]
			if not is_instance_valid(body):
				continue
			var p := body as Person
			if not p.is_alive() or p.inside or (not fx.lifted and LawMark.kind_of(p) != fx.kind):
				continue
			var bob := sin(fx.t * 2.2 + float(i) * 1.9) * 1.0
			var at := (Iso.ground_to_screen(p.ground_pos) + Vector2(-_w * 0.5, -HEAD + bob)).round()
			# The plate: ink, edged in gilt.
			var plate := Rect2(at + Vector2(-3.0, -9.0), Vector2(_w + 6.0, 13.0))
			draw_rect(plate.grow(1.0), Color(_line, 0.7 * a * _line.a))
			draw_rect(plate, Color(_ink, _ink.a * a))
			# The word, an ink edge under it so it reads on any ground.
			draw_string(font, at + Vector2(1.0, 1.0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(DecreeParts.INK, a))
			draw_string(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(_gilt, _gilt.a * a))
			# The quill's stroke under it, drawn as it is written.
			var y := at.y + 6.0
			draw_line(Vector2(at.x - 2.0, y), Vector2(at.x - 2.0 + (_w + 4.0) * stroke, y), Color(DecreeParts.INK, 0.8 * a), 3.0)
			draw_line(Vector2(at.x - 2.0, y), Vector2(at.x - 2.0 + (_w + 4.0) * stroke, y), Color(_line, _line.a * a), 1.0)
