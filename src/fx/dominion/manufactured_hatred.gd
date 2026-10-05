class_name ManufacturedHatredFx
extends FxTimeline
## Manufactured Hatred (Dominion, Tier III): a group is made sure that one kind of people is to blame. The GROUP_MAX
## nearest the click (GROUP_R), but for those of the hated kind themselves, first stop and turn on them in accusation
## (T_ACCUSE); then go for them (Person.fight(), OF_KIND) for HATE_TIME, each as what it is -- a soldier with a soldier's
## blow, a citizen with CIVIL_BLOW. They are not mad: they go for no one else. The hated kind is the cast's mode: the
## guard (soldiers), the clergy, the engineers. Quiet when cast, but for the book entry's "alarm"; the fighting is seen.
## The cast locks the other slots for 1 s.

const GROUP_R := 3.0
const GROUP_MAX := 20
const T_ACCUSE := 3.0
const HATE_TIME := 20.0
const CIVIL_BLOW := 0.25
## How far they look for the hated once the first is down, and how far the first may be.
const SIGHT := 10.0
const FIRST_REACH := 30.0
const MARK := Color("ff7048")

## The hated kind (Person.kind()).
var hated := &"soldier"
var group: Array[Person] = []
## The first of the hated they go for (the nearest to the click), or null when there is none.
var first: Person


func _build() -> void:
	hated = StringName(String(extra.get("mode", "soldier")))
	duration = T_ACCUSE + HATE_TIME + 0.5
	busy = 1.0
	for p in DominionParts.near(ctx.field, origin, GROUP_R):
		if p.kind() != hated and group.size() < GROUP_MAX:
			group.append(p)
	for p in DominionParts.near(ctx.field, origin, FIRST_REACH):
		if p.kind() == hated:
			first = p
			break
	for p in group:
		# Accusation: they stop what they were doing and turn, an eye of red-gold over each.
		p.set_badge(DominionParts.EYE, MARK, T_ACCUSE + HATE_TIME)
		p.stun(T_ACCUSE)
	at(T_ACCUSE, _turn)
	ctx.play(&"grav_field", origin, -8.0)
	if DominionParts.staged(self):
		DominionParts.ground_sigil(self, origin, GROUP_R, MARK, 0.6, T_ACCUSE - 0.6)
		DominionParts.pulse(self, origin, GROUP_R * 1.3, MARK, 0.6, T_ACCUSE)
		if first != null:
			DominionParts.icon(self, first, DominionParts.BLADE, DominionParts.CRIMSON, T_ACCUSE + 4.0, 40.0)
			var links := DominionParts.links(self)
			for p in group:
				links.add(p, first, MARK)


## Accusation turns to violence.
func _turn() -> void:
	var left := HATE_TIME
	for p in group:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		p.wait = 0.0
		var target: Person = first if is_instance_valid(first) and first.is_alive() else null
		p.fight(target, left, Person.SOLDIER_BLOW if p.soldier else CIVIL_BLOW, Person.FightRule.OF_KIND, SIGHT, hated)
	if is_instance_valid(first) and first.is_alive():
		first.set_badge(DominionParts.BLADE, DominionParts.CRIMSON, left)
	ctx.play(&"cit_shout", origin)
