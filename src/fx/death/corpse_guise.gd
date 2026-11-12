class_name CorpseGuiseFx
extends FxTimeline
## Corpse Guise (Death, Tier III, quiet; spec 5.3): the MOST people nearest the click within MARK_R (by distance, a tie by
## instance id: no luck) pass as the walking dead for SPAN seconds. Each carries Person.statuses[&"guise"] = the seconds
## left, which this effect counts down and takes off at zero (or when it is cut short), so the guised are seen again the
## moment it ends. What reads it is Person.guised(): the watch looks straight past them (EscortDirector._seen_by(), the
## search's trail, MissionDirector.faithful_seeing()/watchers() asked about them, Crowd.nearest_witness() and
## TempleReport's copy of it, a soldier's choice of whom to fight), Death's own undead spare them (Visitors' spare_guise),
## and Person draws them greyed and shambling head down. A second cast on someone already guised gives them the full SPAN
## again and takes over their count. Quiet: no alarm, no fright, no panic -- only a cold breath (q_guise) nobody turns at.

const MARK_R := 2.0
const MOST := 4
const SPAN := 25.0
## The status this lays (Visitors' spare_guise and Person.guised() read the same key).
const KEY := &"guise"
## A breath of cold air rises from each of the guised every BREATH_EVERY seconds (drawn only).
const BREATH_EVERY := 3.0
## Ash and bone, cold to nothing (Death's palette; no green but in the dead's eyes).
const BREATH := [Color(0.92, 0.94, 0.96, 0.45), Color(0.75, 0.78, 0.8, 0.3), Color(0.55, 0.56, 0.58, 0.12), Color(0.4, 0.4, 0.42, 0.0)]
const ASH := [Color(DeathParts.BONE, 0.8), Color(DeathParts.ASH, 0.6), Color(0.35, 0.35, 0.37, 0.3), Color(0.2, 0.2, 0.22, 0.0)]

## Whose count each guised person's guise is (person instance id -> effect instance id): only that effect counts it down
## and takes it off, so an earlier cast ending never ends a later one's guise.
static var _owner := {}

## The people this cast guised.
var marked: Array[Person] = []
## Their instance ids, to let go of the count even for one freed meanwhile.
var _ids: Array[int] = []

var _breath_in := BREATH_EVERY * 0.5


## Whom a click at `at` would guise: the MOST nearest living people out of doors within MARK_R, nearest first, a tie by
## instance id.
static func marked_at(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	if field == null:
		return out
	for e in field.in_radius(at, MARK_R):
		var p := e as Person
		if p != null and p.is_alive() and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	return out.slice(0, MOST)


func _build() -> void:
	duration = SPAN
	busy = 0.8
	marked = marked_at(ctx.field, origin)
	if marked.is_empty():
		duration = 1.0
		return
	for p in marked:
		p.statuses[KEY] = SPAN
		_owner[p.get_instance_id()] = get_instance_id()
		_ids.append(p.get_instance_id())
	ctx.play(&"q_guise", origin)
	if DominionParts.staged(self):
		# The grave's cold settles on each of them: ash motes drawn down, and a first breath of cold.
		for p in marked:
			DominionParts.motes(self, p.ground_pos, ASH, 6)
		_breathe()


## Whether this cast still keeps `p`'s guise: it laid it, no later cast took it over, and it is still on. A Variant: `p` may be freed.
func _keeps(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).statuses.has(KEY) \
		and int(_owner.get((p as Person).get_instance_id(), 0)) == get_instance_id()


func _fx_process(delta: float) -> void:
	for p in marked:
		if not _keeps(p):
			continue
		var left := float(p.statuses[KEY]) - delta
		if left <= 0.0 or not p.is_alive():
			_lift(p)
		else:
			p.statuses[KEY] = left
	if not DominionParts.staged(self):
		return
	_breath_in -= delta
	if _breath_in <= 0.0:
		_breath_in = BREATH_EVERY
		_breathe()


## A thin breath of cold air from each of the guised still out of doors.
func _breathe() -> void:
	for p in marked:
		if _keeps(p) and p.is_alive() and not p.inside:
			FxParts.smoke(self, Iso.ground_to_screen(p.ground_pos) + Vector2(0, -15), 1.5, 6.0, 0.25, Vector2(6, 14),
				Vector2(1, 2), Vector2(0.6, 1.0), Color(0, 0, 0, 0), BREATH, ctx.overhead)


## `p`'s guise is off: he is seen again.
func _lift(p: Person) -> void:
	p.statuses.erase(KEY)
	_owner.erase(p.get_instance_id())


func _finish() -> void:
	_release()
	super()


## Freed without finishing (its parent torn down mid-night): the guise still comes off and the count is let go.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_release()


## Every guise this cast still keeps comes off, and its share of _owner is let go (for one freed meanwhile too). Safe to call twice.
func _release() -> void:
	for p in marked:
		if _keeps(p):
			_lift(p)
	for id in _ids:
		if int(_owner.get(id, 0)) == get_instance_id():
			_owner.erase(id)
	_ids.clear()
