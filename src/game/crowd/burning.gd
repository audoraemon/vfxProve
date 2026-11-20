class_name Burning
extends RefCounted
## The burning (Ember on a person, 2026-11-19): a reusable status any power may lay, modelled on the Withering (R36). Laid on
## a person (lay(); Crowd.burn()) for BURN_FOR seconds, he screams, panics and runs, with no shelter roll (Person.panic()'s
## `may_shelter`), drawn alight (Person.burning(), draw only). Every SPREAD_EVERY a burnable building within SPREAD_R of him
## catches (FireManager.ignite, at the level he was laid with), and the citizens within SEE_R who can see him are
## frightened -- the fright and the alarm come from the sight of him, never from the power that lit him. When the time is
## up, alive and out in the open, he dies where he stands as KIND, the town's own fire kill: no body to raise
## (Remains.BODY_KINDS). Indoors, dead of something else first, freed (carried off) or cleared with the town: it lapses at
## once, with no fire death. He runs until he dies: whenever his flight ends (he reached where he ran to, his fright ran
## out) or another mind takes him, he panics again from just behind him and runs on, still with no shelter roll
## (_keep_running()); a god's hold wins, as at the lay. Laid on one already burning, nothing new runs. p.statuses[STATUS]
## holds the seconds left. A trail (trail()) calls back with each spot he leaves behind (Ember's level 5 Fire Trail). The
## Crowd owns one and steps it every frame, after the town's orders (Crowd._advance()). It draws no number from a shared town
## stream: only the people it touches move (his flight and the witnesses' draw from their own rngs, a cry from the town's
## voice budget), and with nobody burning it does nothing at all.

const BURN_FOR := 4.0
const SPREAD_EVERY := 0.5
const SPREAD_R := 0.8
const SEE_R := 4.0
## The town's fire kill (FireManager.FIRE_KINDS, GroundFire's): it leaves no body.
const KIND := &"fire"
## Where his seconds are kept (Person.burning()).
const STATUS := &"burning"
## The level a building he brushes catches at, unless the one laying it says (Ember's START_LEVEL at level 1).
const LIGHT_AT := 0.45
## He panics from himself, a danger this wide; those who see him run from a danger this wide where he is.
const FRIGHT_R := 1.0
## Whether his panic may send him for a shelter: never -- he burns out in the open, not behind a door.
const SHELTERS := false
## His cry when he catches (Crowd._voice(): the town's own voice budget).
const SCREAM := &"cit_scream"
## Float drift: the spread clock is counted down in frame steps.
const DUE := 1e-6
## When his flight ends he panics again from this far behind him (the way he was running), so he runs on that way.
const BEHIND := 0.3

var _crowd: Crowd
## One entry a burning person: {p, id, level, spread_in, trail, every, most, laid, anchor, from}. `p` untyped: he may be freed
## (carried off) before his time is up, and a freed node errors in a typed slot. `from`: where his last panic ran from.
var _on: Array = []
## The instance ids of everyone with an entry, live or still being stepped: one person never has two (a re-lay after his
## status was taken off from outside is refused until his old entry has lapsed).
var _ids := {}
## The list a step is walking (step()), so a clear in the middle of it (a death's callback ends the town) reaches those too.
var _stepping: Array = []
## Counts the clears: a step that sees it change stops there and puts nobody back.
var _clears := 0


func _init(crowd: Crowd = null) -> void:
	_crowd = crowd


## Sets `p` alight for `seconds`, from `from` (where the fire came from): false (and nothing laid) when he is gone, dead,
## inside, burning already, or still has an entry here. A building he brushes catches at `level`.
func lay(p: Person, seconds: float, from: Vector2, level := LIGHT_AT) -> bool:
	if p == null or not is_instance_valid(p) or not p.is_alive() or p.inside or p.burning() or seconds <= 0.0:
		return false
	if _ids.has(p.get_instance_id()):
		return false
	p.statuses[STATUS] = seconds
	_free_to_run(p)
	p.panic(from, FRIGHT_R, KIND, false, SHELTERS)
	_ids[p.get_instance_id()] = true
	_on.append({"p": p, "id": p.get_instance_id(), "level": level, "spread_in": SPREAD_EVERY, "trail": Callable(),
		"every": 0.0, "most": 0, "laid": 0, "anchor": p.ground_pos, "from": from})
	if _crowd != null:
		_crowd._voice(p, SCREAM)
	return true


## While `p` burns, `on_step` is called with each spot he leaves behind: first the spot he stands on now (where he caught
## fire, when called as he is laid), once he is `every` from it; then the spot he had reached when the last was given, once
## he is `every` from that -- `most` in all (below 1: no end). A spot inside a building is passed over. False when he is
## not burning.
func trail(p: Person, on_step: Callable, every := 1.0, most := 0) -> bool:
	for b: Dictionary in _on:
		if is_instance_valid(b.p) and b.p == p:
			b.trail = on_step
			b.every = every
			b.most = most
			b.laid = 0
			b.anchor = p.ground_pos
			return true
	return false


## Counts every burning down: one whose flight has ended runs on (_keep_running()); a building he brushes catches and those
## who see him run, each SPREAD_EVERY; his trail is laid as he goes; one whose time is up dies (out in the open). One
## indoors, dead of something else, or freed lapses at once. It walks the list as the step began: one laid meanwhile (a
## kill's callback lays another) goes on the live list whole, counted from the next step. Cleared meanwhile (a kill's
## callback ends the town), it stops there: the clear has put out every one on the list, and nobody is put back.
func step(delta: float) -> void:
	if _on.is_empty():
		return
	var now := _on
	_on = []
	_stepping = now
	var clears := _clears
	for b: Dictionary in now:
		if _clears != clears:
			return
		if not is_instance_valid(b.p):
			_ids.erase(b.id)
			continue  # carried off and freed: nothing of his is left
		var p: Person = b.p
		if not p.is_alive() or not p.statuses.has(STATUS) or p.inside:
			p.statuses.erase(STATUS)
			_ids.erase(b.id)
			continue
		_keep_running(b, p)
		_lay_trail(b, p)
		b.spread_in = float(b.spread_in) - delta
		if float(b.spread_in) <= DUE:
			b.spread_in = float(b.spread_in) + SPREAD_EVERY
			_spread(p, float(b.level))
			_frighten(p)
		if _clears != clears:
			return
		var left := float(p.statuses[STATUS]) - delta
		if left > 0.0:
			p.statuses[STATUS] = left
			_on.append(b)
			continue
		p.statuses.erase(STATUS)
		_ids.erase(b.id)
		if _crowd != null and _crowd._field != null:
			_crowd._field.kill(p, KIND, p.ground_pos)
	_stepping = []


## Every burning lapses at once (the town's end): nobody dies of it, no trail goes on. A step under way (_stepping) is put out
## too, and stops (_clears).
func clear() -> void:
	_clears += 1
	for list: Array in [_on, _stepping]:
		for b: Dictionary in list:
			if is_instance_valid(b.p):
				(b.p as Person).statuses.erase(STATUS)
	_on.clear()
	_stepping = []  # a new list, not cleared in place: the step is still walking the old one
	_ids.clear()


## He runs until he dies (the spec's flight: he panics and runs, with no shelter roll). Once his flight has ended -- he reached
## the spot he ran to and settled, or his fright ran out -- or another mind took him (a shelter, the gate, a fight), he is
## freed as at the lay and panics again, from BEHIND him the way he ran, so he runs on that way; no shelter roll. A god's hold
## wins, as at the lay (_free_to_run(), Person.panic()), and a soldier in a fight fights on.
func _keep_running(b: Dictionary, p: Person) -> void:
	if p.mind == Person.Mind.PANIC:
		return
	var away := p.ground_pos - (b.from as Vector2)
	var from := p.ground_pos - away.normalized() * BEHIND if away.length() > 0.01 else p.ground_pos
	_free_to_run(p)
	p.panic(from, FRIGHT_R, KIND, false, SHELTERS)
	if p.mind == Person.Mind.PANIC:
		b.from = from


## How many are burning now.
func count() -> int:
	var n := 0
	for b: Dictionary in _on:
		if is_instance_valid(b.p) and (b.p as Person).is_alive():
			n += 1
	return n


## Whatever he was set on that would keep him from running is dropped first, through the town's own ways out of it, so the
## burning's panic takes: on his way into a shelter (ShelterManager drops him from its list as his mind changes), leaving the
## town, or a citizen in a fight. A god's hold wins -- held absolutely (Person.held_by_will), told there is nothing to fear
## or beyond the mind's reach (Person.resists_mind): he is left as he is, and panic() refuses him too. Told there is nothing
## to fear (Person.fearless_left) does not hold: fire beats fearless (fair life, 2026-11-20). A soldier in a fight fights on.
func _free_to_run(p: Person) -> void:
	if p.resists_mind() or p.held_by_will(Person.WILL_ABSOLUTE):
		return
	match p.mind:
		Person.Mind.SHELTER:
			p.leave_shelter(false)
		Person.Mind.FLEE:
			# Out of the gate queue and off the gate (Person.reassure()'s way), then come round where he stands.
			p.release_from_queue()
			p.passing_gate = null
			p.leave_shelter(false)
		Person.Mind.FIGHT:
			if not p.soldier:
				p.stop_fighting()


func _lay_trail(b: Dictionary, p: Person) -> void:
	if not (b.trail as Callable).is_valid() or (int(b.most) > 0 and int(b.laid) >= int(b.most)):
		return
	var anchor: Vector2 = b.anchor
	if p.ground_pos.distance_to(anchor) < float(b.every):
		return
	b.anchor = p.ground_pos
	if _crowd != null and _crowd._env != null and _crowd._env.blocked(anchor, 0.0):
		return  # never inside a building
	b.laid = int(b.laid) + 1
	(b.trail as Callable).call(anchor)


## The nearest standing burnable building within SPREAD_R of him that is not burning yet catches at `level`.
func _spread(p: Person, level: float) -> void:
	if _crowd == null or _crowd.fires == null or _crowd._env == null:
		return
	var g := p.ground_pos
	var best: Structure = null
	var best_d := SPREAD_R
	for s in _crowd._env.near(g, SPREAD_R):
		if not is_instance_valid(s) or s.destroyed or not FireManager.burns(s) or _crowd.fires.is_burning(s):
			continue
		var d := s.distance_to(g)
		if d <= best_d:
			best_d = d
			best = s
	if best != null:
		_crowd.fires.ignite(best, level)


## The citizens within SEE_R who can see him run from him (a few cry out): out in the open, awake, with the ground between
## clear (WalkGrid.clear_line) and his place not veiled or past their sight (Crowd.sight()). Those running already are left
## to their flight. Soldiers stand fast, as they do at the town's other dangers (Crowd._react()).
func _frighten(p: Person) -> void:
	if _crowd == null:
		return
	var at := p.ground_pos
	if _crowd.is_veiled(at):
		return  # nothing there is seen (Unseen Hour)
	var frightened: Array[Person] = []
	for q in _crowd.citizens:
		if not is_instance_valid(q) or q.ground_pos.distance_squared_to(at) > SEE_R * SEE_R or q == p:
			continue
		if not q.is_alive() or q.inside or q.night_indoors:
			continue
		if q.mind == Person.Mind.PANIC or q.mind == Person.Mind.FLEE or q.mind == Person.Mind.ASLEEP:
			continue
		if q.ground_pos.distance_to(at) > _crowd.sight(q, at, SEE_R):
			continue
		if _crowd._grid != null and not _crowd._grid.clear_line(q.ground_pos, at):
			continue
		q.panic(at, FRIGHT_R, KIND)
		if q.mind == Person.Mind.PANIC:
			frightened.append(q)
	if not frightened.is_empty():
		_crowd._yelp(frightened, at)
