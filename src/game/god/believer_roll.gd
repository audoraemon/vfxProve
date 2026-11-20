class_name BelieverRoll
extends RefCounted
## The believers a god carries into a night of a town (World Map + Conquer Progress, Task 2): the saved count of the town, marked on
## that many ordinary citizens with a generator of their own (never the crowd's, a person's, NightRules' or the global stream), the
## deaths among them counted once each, those who got away kept as alive, and what is left at the end as the roll's report.
## A count of 0 makes no generator and touches nothing: the night is today's night, bit for bit.

## Mixed into the seed so this stream is not the look's, the wishes' or the indoors' (as NightRules.pick_indoors does).
const SEED_TAG := "believers"

var town := ""
## The count the god's save asked to carry (mark_carried's `count`).
var asked := 0
## The citizens marked (faith BELIEVER), in the order drawn. Not iterated after the night starts: an escaped one is freed.
var marked: Array[Person] = []
## How many of the asked could not be placed (the town had too few ordinary citizens left).
var unplaced := 0
## Believers lost in the night (each marked person counts once).
var lost := 0
## Where the believers named at casts landed (Task 3 fills it).
var landings := PackedVector2Array()

var crowd: Crowd
var _seed := 0
var _ids := {}        # instance id -> true, for every marked person
var _dead := {}       # instance id -> true, a marked person already counted in `lost`
var _escaped := 0     # marked people who got away alive
var _rules: Rules
var _field: EnemyField


func setup(p_crowd: Crowd, p_town: String, p_seed: int) -> BelieverRoll:
	crowd = p_crowd
	town = p_town
	_seed = p_seed
	if is_instance_valid(crowd):
		_field = crowd._field
		if _field != null and not _field.enemy_killed.is_connected(_on_killed):
			_field.enemy_killed.connect(_on_killed)
		if not crowd.escaped.is_connected(_on_escaped):
			crowd.escaped.connect(_on_escaped)
	return self


## `p` may carry a believer's faith: an ordinary living citizen with no faith, not a child, not in `reserved`.
static func eligible(p: Variant, reserved: Array) -> bool:
	if not is_instance_valid(p):
		return false
	var c := p as Person
	return c.is_alive() and not c.soldier and c.profile != null and c.profile.role != CitizenProfile.Role.CHILD \
		and c.profile.faith == CitizenProfile.Faith.NONE and not reserved.has(c)


## Marks up to `count` eligible citizens as believers; returns how many. A count of 0 (or less) returns at once: no generator, no draw.
func mark_carried(count: int, reserved: Array) -> int:
	asked = maxi(count, 0)
	if count <= 0:
		return 0
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if eligible(p, reserved):
			pool.append(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_seed, SEED_TAG])
	for i in range(pool.size() - 1, 0, -1):  # Fisher-Yates, as NightRules.pick_indoors
		var j := rng.randi_range(0, i)
		var t := pool[i]
		pool[i] = pool[j]
		pool[j] = t
	for p in pool.slice(0, mini(count, pool.size())):
		p.profile.faith = CitizenProfile.Faith.BELIEVER
		marked.append(p)
		_ids[p.get_instance_id()] = true
	unplaced = count - marked.size()
	return marked.size()


func is_carried(p: Variant) -> bool:
	return is_instance_valid(p) and _ids.has((p as Object).get_instance_id())


## One act's Rules (Task 3 connects the casts here); safe to call twice.
func attach(rules: Rules) -> void:
	_rules = rules


## The marked still alive in the town, those who got away alive, and those that never found a place.
func carried_alive() -> int:
	var n := _escaped + unplaced
	if is_instance_valid(crowd):
		for p in crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and _ids.has(p.get_instance_id()):
				n += 1
	return n


func report(_main: bool, _ascended: bool, _reserved: Array) -> Dictionary:
	return {"town": town, "carried": asked, "marked": marked.size(), "carried_alive": carried_alive(), "named": 0, "fill": 0, "lost": lost}


func release() -> void:
	if is_instance_valid(_field) and _field.enemy_killed.is_connected(_on_killed):
		_field.enemy_killed.disconnect(_on_killed)
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
	_rules = null


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	var p := e as Person
	if p == null or p.profile == null or p.profile.faith != CitizenProfile.Faith.BELIEVER:
		return
	var id := p.get_instance_id()
	if _dead.has(id):
		return
	_dead[id] = true
	lost += 1


func _on_escaped(p: Person) -> void:
	if is_carried(p):
		_escaped += 1
