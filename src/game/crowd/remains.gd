class_name Remains
extends Node2D
## The town's whole dead (Death authority, spec §4). A death that leaves the body whole is written down here as a value
## copy -- where, when, who, what killed them -- so the body stays usable for LIFE seconds (its soul for SOUL) after the
## Person node has freed. Death's powers pick a remain, raise it or move it. Off by default: with the ledger off nothing is
## recorded, stepped or drawn, and the town is exactly what it was.

## How long a body can be used, and how long its soul is still near.
const LIFE := 45.0
const SOUL := 15.0
## At most this many remains are kept; past it the oldest lapses first.
const MAX := 60
## A click takes the nearest remain within this.
const PICK_R := 1.0
## Only a death that leaves the body whole is recorded: Death's own quiet kills, the mob's and a fight's, and Decree's
## (choked, struck by the Sealed Verdict, killed by the bond, crushed by the Closing Cage or Erasing Distance's fold).
## A blast, a fire, the pit or a door of stars leaves nothing to raise.
const BODY_KINDS: Array[StringName] = [&"deathmark", &"plague", &"mob", &"frenzy", &"pale", &"shadow", &"choke",
	&"verdict", &"bound", &"crushed"]
## The powers that need the ledger on (Pale Reign: its dead rise as servants).
const WANTED_BY: Array[String] = ["raise", "walker", "gravetide", "pale"]


## One body: values only. `body` is a WeakRef to the dead Person, used for one thing -- hiding that node when the remain is
## taken (a risen body leaves no corpse behind) -- and it never keeps the node alive: once the node frees it resolves null.
class Remain:
	var pos := Vector2.ZERO
	var born := 0.0
	var role := 0
	var soldier := false
	var kind: StringName = &""
	var design := ""
	var facing := 0
	var sick := false
	var hidden := false
	var body: WeakRef


var enabled := false

var _field: EnemyField
var _list: Array[Remain] = []
var _clock := 0.0
var _shown := 0


func setup(field: EnemyField) -> Remains:
	_field = field
	field.enemy_killed.connect(_on_killed)
	return self


## True if any of the loadout's keys is a power that raises or moves bodies.
static func wants(keys: Array) -> bool:
	for k in keys:
		if WANTED_BY.has(String(k)):
			return true
	return false


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if not enabled or not BODY_KINDS.has(kind):
		return
	var p := e as Person
	if p == null:
		return
	var r := Remain.new()
	r.pos = p.ground_pos
	r.born = _clock
	r.role = p.profile.role if p.profile != null else 0
	r.soldier = p.soldier
	r.kind = kind
	r.design = p._design()
	r.facing = p.remain_facing()
	r.sick = p.sick_left > 0.0
	r.body = weakref(p)
	_list.append(r)
	if _list.size() > MAX:
		_list.erase(_oldest())
	_dirty()


func _oldest() -> Remain:
	var best: Remain = _list[0]
	for r in _list:
		if r.born < best.born:
			best = r
	return best


## Ages the remains; one lapses after LIFE.
func step(delta: float) -> void:
	if not enabled:
		return
	_clock += delta
	var i := _list.size() - 1
	while i >= 0:
		if age(_list[i]) >= LIFE:
			_list.remove_at(i)
			_dirty()
		i -= 1
	if is_inside_tree() and _shown_count() != _shown:
		queue_redraw()


func age(r: Remain) -> float:
	return _clock - r.born


func has_soul(r: Remain) -> bool:
	return age(r) < SOUL


## The nearest unhidden remain within PICK_R of `at` (one with its soul still near, if `need_soul`; a hidden one too, if
## `hidden_too`: Walking Corpse alone walks a hidden body back out), or null. Ties go to the older one.
func pick(at: Vector2, need_soul := false, hidden_too := false) -> Remain:
	var best: Remain = null
	var best_d := PICK_R * PICK_R
	for r in _list:
		if (r.hidden and not hidden_too) or (need_soul and not has_soul(r)):
			continue
		var d := r.pos.distance_squared_to(at)
		if d < best_d or (best != null and d == best_d and r.born < best.born):
			best = r
			best_d = d
	return best


## The unhidden remains within `r` of `at`, nearest first.
func near(at: Vector2, r: float) -> Array[Remain]:
	var out: Array[Remain] = []
	for b in _list:
		if not b.hidden and b.pos.distance_to(at) <= r:
			out.append(b)
	out.sort_custom(func(a: Remain, b: Remain) -> bool:
		return a.pos.distance_squared_to(at) < b.pos.distance_squared_to(at))
	return out


## Every unhidden remain, the oldest first.
func all() -> Array[Remain]:
	var out: Array[Remain] = []
	for r in _list:
		if not r.hidden:
			out.append(r)
	out.sort_custom(func(a: Remain, b: Remain) -> bool: return a.born < b.born)
	return out


## Uses a remain up. Its person's own corpse, still lying there (DummyEnemy's DEATH_FADE, or BODY_HOLD for its
## HELD_KINDS), is hidden at once: the body has got up, or gone, so it does not lie in two places. The node's own timer
## still frees it.
func take(r: Remain) -> void:
	var node := _body_node(r)
	if node != null and node.state == DummyEnemy.State.DEAD:
		node.visible = false
	if _list.has(r):
		_list.erase(r)
		_dirty()


## Moves a remain (hidden, if it is carried or buried) and restarts its clock. A remain taken up meanwhile (a body walking:
## Walking Corpse take()s it at the cast so no other power can pick it while it walks) is put back on the ledger here.
func move(r: Remain, to: Vector2, hidden: bool) -> void:
	r.pos = to
	r.hidden = hidden
	r.born = _clock
	if not _list.has(r):
		_list.append(r)
		if _list.size() > MAX:
			_list.erase(_oldest())
	_dirty()


func _dirty() -> void:
	if is_inside_tree():
		queue_redraw()


## How many remains are drawn: lying there once the person's own corpse no longer shows (_drawn()).
func _shown_count() -> int:
	var n := 0
	for r in _list:
		if _drawn(r):
			n += 1
	return n


## A remain lies drawn when it is not hidden and its person's own corpse no longer shows: the node has freed (after
## DEATH_FADE, or BODY_HOLD for DummyEnemy.HELD_KINDS) or was hidden (take()), or there never was one.
func _drawn(r: Remain) -> bool:
	if r.hidden:
		return false
	var node := _body_node(r)
	return node == null or not node.visible


## The remain's person node while it has not freed, else null.
static func _body_node(r: Remain) -> DummyEnemy:
	if r.body == null:
		return null
	var o: Variant = r.body.get_ref()
	return o as DummyEnemy if is_instance_valid(o) else null


## Each remain lies as its person's own death pose, last frame. Drawn only on a stage (a headless test has none).
func _draw() -> void:
	if not enabled or not is_inside_tree() or not SpriteArt.on() or not PeopleArt.ready():
		return
	_shown = 0
	var atlas := PeopleArt.atlas()
	for r in _list:
		if not _drawn(r) or not PeopleArt.has(r.design):
			continue
		var info := PeopleArt.info(r.design)
		var row := 4 * 4 + r.facing  # the "death" animation's row
		var n: int = info[4][row]
		var cell: Vector2 = info[3]
		var src := Rect2(info[0] + Vector2((n - 1) * cell.x, row * cell.y), cell)
		var foot: Vector2 = info[2]
		draw_texture_rect_region(atlas, Rect2(Iso.ground_to_screen(r.pos) - foot, cell), src)
		_shown += 1
