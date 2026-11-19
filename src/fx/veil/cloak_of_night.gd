class_name CloakOfNightFx
extends FxTimeline
## Cloak of Night (Veil, Tier 2; spec 5.4): the MOST people nearest the click within MARK_R (3 within 2 in the light, 8 within 4
## in the dark: VeilRules.SIZES; nearest first, a tie by instance id: no luck) are hidden from the watch for SPAN seconds. Each
## carries Person.statuses[&"cloak"] = the seconds left, which this cast counts down and takes off at zero (or when it is cut
## short or freed). What reads it is Person.hidden_from_watch(): the witness check, the watch's and the search's sight, a
## soldier's choice of whom to fight. Not a guise: guised() stays false (the cloaked walk normally, Death's undead do not spare
## them). A second cast on someone cloaked gives them the full SPAN again and takes over their count: each person's owner is
## the cast's instance id, kept on the person (no statics), so one cast ending never lifts another's cloak. Silent: no alarm,
## no fright. Drawn: a dark shimmer over each cloaked person, in the god's overhead layer only. Lands its dusk.

const SPAN := 25.0
## The status this lays (Person.hidden_from_watch() reads the same key).
const KEY := &"cloak"
## The person's meta that names the cast keeping his cloak.
const OWNER := &"cloak_owner"

## The instance ids of the people this cast cloaked (they may be freed meanwhile).
var _ids: Array[int] = []
## The shimmers, one per cloaked person.
var shimmers: Array[Node2D] = []


## Whom a click at `at` would cloak: the `most` nearest living people out of doors within `r`, nearest first, a tie by id.
static func marked_at(field: EnemyField, at: Vector2, r := 2.0, most := 3) -> Array[Person]:
	var out: Array[Person] = []
	if field == null:
		return out
	for e in field.in_radius(at, r):
		var p := e as Person
		if p != null and p.is_alive() and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	return out.slice(0, most)


func _build() -> void:
	duration = SPAN
	var r := VeilParts.size(self, "cloak", "MARK_R")
	var most := int(VeilParts.size(self, "cloak", "MOST"))
	var marked := marked_at(ctx.field if ctx != null else null, origin, r, most)
	VeilParts.land(self, origin, r)
	if marked.is_empty():
		duration = 1.0
		return
	for p in marked:
		p.statuses[KEY] = SPAN
		p.set_meta(OWNER, get_instance_id())
		_ids.append(p.get_instance_id())
	var parent: Node2D = ctx.overhead if ctx.overhead != null else ctx.world
	if parent != null:
		for p in marked:
			var m := CloakShimmer.new()
			m.who_id = p.get_instance_id()
			m.fx_id = get_instance_id()
			m.sync()
			shimmers.append(track(m, parent) as Node2D)


## The person with this instance id, or null if freed.
static func _person(id: int) -> Person:
	return instance_from_id(id) as Person


## Whether this cast still keeps `p`'s cloak: it laid it, no later cast took it over, and it is still on.
func _keeps(p: Person) -> bool:
	return p != null and p.statuses.has(KEY) and int(p.get_meta(OWNER, 0)) == get_instance_id()


func _fx_process(delta: float) -> void:
	for id in _ids:
		var p := _person(id)
		if not _keeps(p):
			continue
		var left := float(p.statuses[KEY]) - delta
		if left <= 0.0 or not p.is_alive():
			_lift(p)
		else:
			p.statuses[KEY] = left


func _lift(p: Person) -> void:
	p.statuses.erase(KEY)
	p.remove_meta(OWNER)


## Every cloak this cast still keeps comes off. Safe to call twice, and for people freed meanwhile.
func _release() -> void:
	for id in _ids:
		var p := _person(id)
		if _keeps(p):
			_lift(p)
	_ids.clear()


func _finish() -> void:
	_release()
	super()


func _exit_tree() -> void:
	_release()
	super()


## Freed without finishing (an effect layer torn down outside the tree): the cloaks still come off.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_release()


## The dark shimmer over one cloaked person, for as long as `fx_id`'s cast keeps him. Drawn only (no simulation state); it frees
## itself when the cloak lifts or he is gone, and hides while he is indoors.
class CloakShimmer extends Node2D:
	var who_id := 0
	var fx_id := 0
	var _head := 20.0
	var _clock := 0.0

	func _fx() -> CloakOfNightFx:
		return instance_from_id(fx_id) as CloakOfNightFx

	func _who() -> Person:
		return instance_from_id(who_id) as Person

	func sync() -> void:
		var who := _who()
		if who == null:
			return
		position = Iso.ground_to_screen(who.ground_pos)
		var design: String = who._design()
		if PeopleArt.has(design):
			_head = (PeopleArt.info(design)[2] as Vector2).y

	func _process(delta: float) -> void:
		var fx := _fx()
		var who := _who()
		if fx == null or who == null or not fx._keeps(who):
			queue_free()
			return
		_clock += delta
		sync()
		visible = who.is_alive() and not who.inside
		queue_redraw()

	func _draw() -> void:
		var fx := _fx()
		var who := _who()
		if fx == null or who == null or not fx._keeps(who):
			return
		var w := 5.0
		var top := -_head - 1.0
		var veil := PackedVector2Array([Vector2(-w, top + 3), Vector2(0, top), Vector2(w, top + 3), Vector2(w + 1, 1), Vector2(-w - 1, 1)])
		draw_colored_polygon(veil, Color(VeilParts.BLACK, 0.42))
		# Violet motes drift up the body and fade: the shimmer.
		for i in 4:
			var ph := fposmod(_clock * 0.9 + float(i) * 0.25, 1.0)
			var x := sin(_clock * 2.0 + float(i) * 1.7) * (w - 1.0)
			draw_rect(Rect2(x, -ph * _head, 1, 2), Color(VeilParts.VEIL, 0.55 * (1.0 - ph)))
