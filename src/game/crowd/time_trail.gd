class_name TimeTrail
extends RefCounted
## The town's short memory (Yesterday's Door, and any power after it that turns people back): it writes down, about
## every EVERY seconds of the crowd's clock, for each living person, what Person.rewind() needs to put them back as they
## were -- where they stood, their mind and what it was counting down, their goal and anchor, the danger they ran from,
## whether they were inside -- and answers for the last KEEP seconds of it. back() reads it.
##
## It only reads people: no random draw, no write to anyone, so it changes nothing the crowd does (tools/dev/crowd_check.gd
## keeps its checksum). The writing is spread over the frames -- a share of the roster each frame, so that everyone is
## written once every EVERY (a whole pass over the Capital's 600 people at once would be a spike of its own) -- into
## packed columns that are reused: no object or dictionary is made per person or per record (a dictionary is made only by back(), at a cast).
## The crowd steps it at the end of its own frame (Crowd._advance()), so it stands still with the crowd (Crowd.freeze()).

## How many seconds back the trail answers for, and how often each person is written down.
const KEEP := 10.0
const EVERY := 0.5
## Records kept for each person: KEEP's worth even when the roster shifts under the writing and someone is written down
## as soon as SOONEST after the last time.
const SOONEST := EVERY * 0.9
const SLOTS := 24
## A record's flags, beside the mind (the low 5 bits) and the awareness (the next 3).
const AWARE_SHIFT := 5
const INSIDE := 1 << 8
const LURED := 1 << 9
## The minds whose record carries more (folded here: an enum read through its class in the loop costs more than the rest).
const _CALM := Person.Mind.CALM
const _RECOVER := Person.Mind.RECOVER
const _PANIC := Person.Mind.PANIC
const _OBSERVE := Person.Mind.OBSERVE
const _DEAD := DummyEnemy.State.DEAD

## The trail's own clock (the crowd's, while it runs).
var clock := 0.0
## Records written so far (every person's, all told).
var records := 0
## The roster's share owed this frame, and where in it the writing is.
var _due := 0.0
var _at := 0
## When the forgotten were last swept out (_sweep()).
var _swept := 0.0
## Each person's row in the columns, by instance id; rows of people gone (dead, escaped, freed) are given out again.
var _rows := {}
var _free := PackedInt32Array()
var _cap := 0
## Per row: how many records it has had (the next goes in slot _head % SLOTS).
var _head := PackedInt32Array()
## The columns, SLOTS entries a row, packed four to an entry (each write to a column costs as much as the four):
## when; where it stood and its goal (x, y, x, y); its mind with its flags, what the mind was counting down (a fright's
## seconds, a look's, a stay's) and the danger's radius; and the point the mind was about (its anchor in its day, the
## danger in a fright or a look).
var _time := PackedFloat64Array()
var _where := PackedVector4Array()
var _mind := PackedVector4Array()
var _about := PackedVector2Array()


## The crowd's frame: count the clock, and write down this frame's share of `citizens` then `soldiers` (everyone once
## every EVERY).
func step(delta: float, citizens: Array[Person], soldiers: Array[Person]) -> void:
	clock += delta
	var nc := citizens.size()
	var n := nc + soldiers.size()
	if n == 0:
		return
	_due = minf(_due + float(n) * delta / EVERY, float(n))
	var k := int(_due)
	_due -= k
	for j in k:
		if _at >= n:
			_at = 0
			if clock - _swept >= EVERY:
				_sweep()
		var p: Variant = citizens[_at] if _at < nc else soldiers[_at - nc]  # untyped: it may be freed
		_at += 1
		if is_instance_valid(p):
			_note(p, true)


## Write everyone living down now (a test's whole pass; step() spreads the same over EVERY).
func record(citizens: Array[Person], soldiers: Array[Person]) -> void:
	for list: Array in [citizens, soldiers]:
		for p: Variant in list:
			if is_instance_valid(p):
				_note(p, false)


## Write `p` down (one record), unless it is dead (then it is forgotten) or -- `spaced` -- was written less than
## SOONEST ago (the roster shifted and brought it round again early).
func _note(p: Person, spaced: bool) -> void:
	var id := p.get_instance_id()
	var row: int = _rows.get(id, -1)
	if p.state == _DEAD:
		if row >= 0:
			_rows.erase(id)
			_free.append(row)
		return
	if row < 0:
		row = _new_row()
		_rows[id] = row
	var h := _head[row]
	if spaced and h > 0 and clock - _time[row * SLOTS + (h - 1) % SLOTS] < SOONEST:
		return
	var i := row * SLOTS + h % SLOTS
	_head[row] = h + 1
	records += 1
	var m: int = p.mind
	var at := p.ground_pos
	var to := p._goal
	_time[i] = clock
	_where[i] = Vector4(at.x, at.y, to.x, to.y)
	var info := m | (int(p.awareness) << AWARE_SHIFT)
	if p.inside:
		info |= INSIDE
	# Only what the mind needs to be taken up again (Person._take_up()): the rest of the slot is not read for it.
	if m == _CALM or m == _RECOVER:
		_about[i] = p.anchor
		_mind[i] = Vector4(info, p.stay_left, 0.0, 0.0)
	elif m == _PANIC or m == _OBSERVE:
		if m == _OBSERVE and p._lured:
			info |= LURED
		_about[i] = p._threat
		_mind[i] = Vector4(info, p._panic_left if m == _PANIC else p._observe_left, p._threat_r, 0.0)
	else:
		_mind[i] = Vector4(info, 0.0, 0.0, 0.0)


## Forget whoever has not been written down for two rounds (freed: escaped, or the dead gone from the roster).
func _sweep() -> void:
	_swept = clock
	for id in _rows.keys():
		var row: int = _rows[id]
		var h := _head[row]
		if h == 0 or clock - _time[row * SLOTS + (h - 1) % SLOTS] > EVERY * 2.0 + SOONEST:
			_rows.erase(id)
			_free.append(row)


func _new_row() -> int:
	var row := -1
	if not _free.is_empty():
		row = _free[_free.size() - 1]
		_free.resize(_free.size() - 1)
	else:
		row = _head.size()
		_head.append(0)
		if row >= _cap:
			_cap = maxi(64, _cap * 2)
			# Each column by name: a packed array put in a list is a copy.
			_time.resize(_cap * SLOTS)
			_where.resize(_cap * SLOTS)
			_mind.resize(_cap * SLOTS)
			_about.resize(_cap * SLOTS)
	_head[row] = 0
	return row


## How `p` was `seconds` ago, as Person.rewind() takes it: the record nearest that time among those of the last KEEP
## seconds (and the half-round either side of it), or -- for one remembered for less long (come into the town since) --
## the oldest of them. Keys: pos, goal, mind, awareness, inside, age (how many seconds ago the record was written), and
## what that mind is taken up again with: anchor and timer (the stay left) for CALM and RECOVER, threat, threat_r and
## timer (the seconds left) for PANIC and OBSERVE, lured for OBSERVE -- for any other mind these keys hold nothing
## meaningful. Empty when there is none.
func back(p: Person, seconds: float) -> Dictionary:
	var row := _row(p)
	if row < 0:
		return {}
	var want := clock - minf(seconds, KEEP)
	var best := -1
	var best_d := INF
	var h := _head[row]
	for k in range(maxi(h - SLOTS, 0), h):
		var when := _time[row * SLOTS + k % SLOTS]
		if clock - when > KEEP + EVERY * 0.5:
			continue
		var d := absf(when - want)
		if d < best_d - 0.0001:
			best_d = d
			best = k
	if best < 0:
		return {}
	var i := row * SLOTS + best % SLOTS
	var where := _where[i]
	var held := _mind[i]
	var info := int(held.x)
	return {
		"pos": Vector2(where.x, where.y), "goal": Vector2(where.z, where.w), "anchor": _about[i], "threat": _about[i],
		"threat_r": held.z, "timer": held.y, "mind": info & 31, "awareness": (info >> AWARE_SHIFT) & 7,
		"inside": (info & INSIDE) != 0, "lured": (info & LURED) != 0,
		"age": clock - _time[i],
	}


## How many seconds back the trail answers for `p` (its oldest record back() would give; 0 for one it has none of).
func span(p: Person) -> float:
	var oldest := back(p, KEEP)
	return float(oldest.get("age", 0.0))


## How many people it remembers now.
func size() -> int:
	return _rows.size()


func _row(p: Person) -> int:
	if p == null or not is_instance_valid(p):
		return -1
	return _rows.get(p.get_instance_id(), -1)


## Forget everything (Crowd.clear()).
func clear() -> void:
	clock = 0.0
	records = 0
	_due = 0.0
	_at = 0
	_swept = 0.0
	_rows.clear()
	_free = PackedInt32Array()
	_cap = 0
	_head = PackedInt32Array()
	_time.clear()
	_where.clear()
	_mind.clear()
	_about.clear()
