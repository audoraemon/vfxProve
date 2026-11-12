class_name LawMark
extends RefCounted
## Decree's law on a person (spec §4.1): what the law says he is, set by a power for a time under its own owner id (its instance id), like
## Person.hold_pace(). Several owners may each hold one; the latest set of those still holding is the one that counts (kind_of()). Every
## place that decides whether a guard sees, seizes or strikes him, or whether he is a witness, asks here, never the power:
##   CRIMINAL  every guard (a soldier, a watchman, an inquisitor) who sees him goes for him, a FightRule.TARGET_ONLY fight as Saint or
##             Sinner's mob (step()); called off when the law ends.
##   OFFICER   one of the garrison: no guard sees him as a suspect (unseen_by_guards()); anyone else still sees him.
##   NOBODY    no one sees him, strikes him or heeds what he saw (unseen_by_all()).
##   BOUND     Bound in Law's, for its badge and cleanup: it changes no sight.
## Perception only: no count ever changes -- a NOBODY believer is still a believer, a charge still the charge.
## The person holds one (Person.law) only while a law holds him. Every helper takes a Variant and answers the default (no law) for none or
## a freed body: a freed person passed on as a Person aborts the call.

const CRIMINAL := &"criminal"
const OFFICER := &"officer"
const NOBODY := &"nobody"
const BOUND := &"bound"
const KINDS: Array[StringName] = [CRIMINAL, OFFICER, NOBODY, BOUND]
## How near a guard sees a criminal and goes for him.
const SIGHT := 3.0
## How often a criminal is looked for by the guards about him.
const LOOK := 0.5
## The fight's tag (Person.fight_kind), so only the law's own hunters are called off.
const FIGHT_KIND := &"law"

## Owner id -> [kind, seconds left], the latest set last.
var laws := {}
## The guards set on him while he was a criminal.
var hunters: Array = []
var _look_in := 0.0


## `p` is, by law, `kind` for `seconds`, under `owner` (one law per owner: setting again replaces it and makes it the latest).
static func set_law(p: Variant, kind: StringName, seconds: float, owner: int) -> void:
	if not _person(p) or seconds <= 0.0 or not kind in KINDS:
		return
	var who := p as Person
	if who.law == null:
		who.law = LawMark.new()
	who.law.laws.erase(owner)
	who.law.laws[owner] = [kind, seconds]
	who.law._look_in = 0.0  # a criminal is looked for at his next step
	_settle(who)


## `owner`'s law on `p` is lifted; any other owner's still holds.
static func lift(p: Variant, owner: int) -> void:
	if not _held(p):
		return
	(p as Person).law.laws.erase(owner)
	_settle(p as Person)


## What the law says `p` is: the latest law still holding, &"" for none.
static func kind_of(p: Variant) -> StringName:
	if not _held(p):
		return &""
	var laws_now: Dictionary = (p as Person).law.laws
	return laws_now[laws_now.keys().back()][0] if not laws_now.is_empty() else &""


## No guard sees `p` as a suspect: NOBODY or OFFICER.
static func unseen_by_guards(p: Variant) -> bool:
	var k := kind_of(p)
	return k == NOBODY or k == OFFICER


## No one sees `p`, nor heeds what he saw: NOBODY.
static func unseen_by_all(p: Variant) -> bool:
	return kind_of(p) == NOBODY


## Every guard who sees `p` goes for him: CRIMINAL.
static func wanted(p: Variant) -> bool:
	return kind_of(p) == CRIMINAL


## A guard: a soldier, or a citizen of the watch (a watchman, an inquisitor in the watch's cloak).
static func is_guard(p: Person) -> bool:
	return p.soldier or (p.profile != null and p.profile.role == CitizenProfile.Role.WATCHMAN)


## Fighter `by`, under `rule`, may not strike `p` (Person._fightable()): no one strikes a NOBODY; a guard breaking up a fight
## (FightRule.HOSTILES) does not take an OFFICER for a hostile.
static func spares(by: Person, p: Variant, rule: Person.FightRule) -> bool:
	return unseen_by_all(p) or (rule == Person.FightRule.HOSTILES and is_guard(by) and unseen_by_guards(p))


## One frame of `p`'s laws (Person.tick()): each runs down and those run out are dropped; a criminal out of doors is looked for every
## LOOK by the guards within SIGHT.
static func step(p: Variant, delta: float) -> void:
	if not _held(p):
		return
	var who := p as Person
	var m := who.law
	for owner: int in m.laws.keys():
		var e: Array = m.laws[owner]
		e[1] = float(e[1]) - delta
		if float(e[1]) <= 0.0:
			m.laws.erase(owner)
	_settle(who)
	if who.law == null or not wanted(who):
		return
	m._look_in -= delta
	if m._look_in <= 0.0:
		m._look_in = LOOK
		m._hunt(who)


## Every guard within SIGHT of criminal `p` who can see -- alive, out of doors, awake, not held by the god -- and is not already fighting
## goes for him for as long as his law has left.
func _hunt(p: Person) -> void:
	if p.field == null or p.inside or not p.is_alive():
		return
	var left := 0.0
	for e: Array in laws.values():
		if e[0] == CRIMINAL:
			left = maxf(left, float(e[1]))
	for e in p.field.in_radius(p.ground_pos, SIGHT):
		var q := e as Person
		if q == null or q == p or not q.is_alive() or q.inside or not is_guard(q) or q.held_by_god() \
				or q.mind == Person.Mind.FIGHT or q.mind == Person.Mind.ASLEEP:
			continue
		q.fight(p, left, Person.SOLDIER_BLOW, Person.FightRule.TARGET_ONLY, SIGHT, FIGHT_KIND)
		if q.mind == Person.Mind.FIGHT and not hunters.has(q):
			hunters.append(q)


## After a change to `p`'s laws: no longer wanted, his hunters are called off; no law left, he holds none.
static func _settle(p: Person) -> void:
	var m := p.law
	if not wanted(p):
		for h: Variant in m.hunters:
			if is_instance_valid(h) and (h as Person).mind == Person.Mind.FIGHT and (h as Person).fight_target == p \
					and (h as Person).fight_kind == FIGHT_KIND:
				(h as Person).stop_fighting()
		m.hunters.clear()
	if m.laws.is_empty():
		p.law = null


static func _person(p: Variant) -> bool:
	return is_instance_valid(p) and p is Person


static func _held(p: Variant) -> bool:
	return _person(p) and (p as Person).law != null
