class_name DeathParts
extends RefCounted
## Death's undead kit (Death authority, spec 5.1 and 6): every Death power that raises or calls the dead summons through
## here. A zombie wears the dead person's own people sprite, greyed, with pale fire in its eyes and a shambling pace;
## a spirit is a thin pale shape that passes through walls and cannot be cut down; a wraith is a spirit that withers whoever
## it reaches (the crowd's Withering) and slows whoever it passes through; a pale ghost is Pale Reign's gaunt runner; the
## skeleton warrior and the ghoul are Grave Tide's. All are Visitors (src/game/crowd/visitors.gd), so the town's guard cuts a
## zombie down as it does a hound. The caller owns the dead's lifetime (ZOMBIE_LIFE) and takes the remain it raised.

## The palette: bone white, ash grey, pale-white fire; grave green is for eyes and glows only. No blood.
const BONE := Color("d8d2bf")
const ASH := Color("8a8a8c")
const PALE_FIRE := Color("eaf4ff")
const GRAVE_GREEN := Color("7fe8b0")
## What greys a zombie's own colours.
const ZOMBIE_TINT := Color(0.58, 0.62, 0.6)

## A zombie lives this long, walks at ZOMBIE_PACE of a walk (ZOMBIE_CHASE times that once it has prey), falls to ZOMBIE_BLOWS blows, and smells prey within ZOMBIE_SEEK.
const ZOMBIE_LIFE := 30.0
const ZOMBIE_PACE := 1.0
## With prey in sight a zombie runs at this multiple of its pace.
const ZOMBIE_CHASE := 1.25
const ZOMBIE_BLOWS := 3
const ZOMBIE_SEEK := 10.0
const ZOMBIE_BITE_R := 0.5
const ZOMBIE_BITE_EVERY := 1.2
## A spirit's fright reaches this far.
const SPIRIT_FRIGHT_R := 3.0
## A spirit cannot be cut down: its blows are beyond counting.
const SPIRIT_BLOWS := 999
## A spirit drifts at this share of a dog's run; a wraith (which withers anyone in its sector, R37) looks this far.
const SPIRIT_SPEED := 0.7
const WRAITH_SEEK := 12.0
const WRAITH_SPEED := 1.0
## A wraith's touch reaches this far.
const WRAITH_TOUCH := 0.5
## A wraith withers this many (R37), then it is spent and sinks; it flies out to its sector for this long at most (R35).
const WRAITH_TOUCHES := 3
const WRAITH_OUT := 3.0
## Pale Reign's ghosts: pace in walks, tint, touch reach and how often they touch.
const PALE_GHOST_PACE := 2.2
const PALE_GHOST_TINT := Color(0.92, 0.94, 0.97, 0.7)
const PALE_GHOST_TOUCH := 0.4
const PALE_GHOST_EVERY := 0.8
## Past Pale Reign's last kill its ghosts only frighten, this far (R39).
const PALE_GHOST_FRIGHT_R := 2.0
## Grave Tide's skeleton warrior (R42): blows, pace in walks, chase, seek, reach, how often it strikes, its bite.
const SKELETON_BLOWS := 4
const SKELETON_PACE := 1.3
const SKELETON_CHASE := 1.25
const SKELETON_SEEK := 12.0
const SKELETON_REACH := 0.6
const SKELETON_EVERY := 1.0
const SKELETON_BITE := 1.0
## Grave Tide's ghoul (R42): blows, pace in walks, chase, seek, reach (the leap), how often it bites.
const GHOUL_BLOWS := 2
const GHOUL_PACE := 2.0
const GHOUL_CHASE := 1.2
const GHOUL_SEEK := 12.0
const GHOUL_REACH := 0.8
const GHOUL_EVERY := 0.9
## Whoever a wraith passes through keeps this share of their pace for this long.
const WRAITH_SLOW := 0.5
const WRAITH_SLOW_FOR := 4.0
## on_kill_rise(): the body must lie this near where the victim fell, and have just fallen.
const RISE_NEAR := 0.5
const RISE_FRESH := 2.0


## The dead person of remain `r` gets up as a zombie where they lay, wearing their own design. It knocks a citizen down
## with its first bite and kills with a second within 3 s, leaves a guised person alone, and carries the plague when
## `plague` or the dead person was sick. `eyes` is the colour of its eyes (alpha 0: none, it passes for living). The
## caller `take`s the remain.
static func zombie(v: Visitors, r: Remains.Remain, plague: bool, eyes := GRAVE_GREEN) -> Animal:
	var mul := ZOMBIE_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var a := v.summon(r.pos, Animal.Breed.ZOMBIE, ZOMBIE_BLOWS, mul, ZOMBIE_SEEK, ZOMBIE_BITE_R, ZOMBIE_BITE_EVERY, true)
	a.chase_mul = ZOMBIE_CHASE
	a.wear(r.design, r.facing, ZOMBIE_TINT, eyes)
	v.give(a, {"knock_first": true, "spare_guise": true, "infect": plague or r.sick})
	return a


## A pale spirit comes up at `at`: through walls, never cut down, drawn procedurally. It frightens whoever is within
## SPIRIT_FRIGHT_R when `fright` (a quiet power's spirit does not), and leaves a guised person alone. It does not bite; it
## drifts where its owner sends it (it hunts no one of its own accord).
static func spirit(v: Visitors, at: Vector2, fright := true) -> Animal:
	return _spirit(v, at, fright, 0.0)


static func _spirit(v: Visitors, at: Vector2, fright: bool, seek: float) -> Animal:
	var a := v.summon(at, Animal.Breed.SPIRIT, SPIRIT_BLOWS, SPIRIT_SPEED, seek, 0.5, 1.0, false)
	var traits := {"phase": true, "spare_guise": true, "no_bite": true}
	if fright:
		traits["fright_r"] = SPIRIT_FRIGHT_R
	v.give(a, traits)
	return a


## A wraith (R35, R37): the painted spirit, through walls, never cut down. It flies out to `out_to` first (WRAITH_OUT at
## most; its own spot: no flight), then hunts the nearest anyone, citizen or soldier, whose bearing lies in its `sector`
## (Visitors' trait; Vector4.ZERO: the whole circle). Its touch withers (Withering.WITHER) and, after WRAITH_TOUCHES, it is
## spent; whoever it passes through is slowed to half their pace for 4 s.
static func wraith(v: Visitors, at: Vector2, sector: Vector4, out_to: Vector2) -> Animal:
	var a := v.summon(at, Animal.Breed.WRAITH, SPIRIT_BLOWS, WRAITH_SPEED, WRAITH_SEEK, WRAITH_TOUCH, 1.0, false)
	v.give(a, {"phase": true, "spare_guise": true, "prey": "anyone", "wither": Withering.WITHER,
		"touches_most": WRAITH_TOUCHES, "slow": WRAITH_SLOW, "slow_for": WRAITH_SLOW_FOR, "slow_r": 0.5,
		"fright_r": SPIRIT_FRIGHT_R, "sector": sector, "march": out_to, "march_for": WRAITH_OUT})
	return a


## A haunt: a wraith that hunts and bites no one and frightens no one; it drifts where its owner sends it.
static func haunt(v: Visitors, at: Vector2) -> Animal:
	var a := v.summon(at, Animal.Breed.WRAITH, SPIRIT_BLOWS, SPIRIT_SPEED, 0.0, 0.5, 1.0, false)
	v.give(a, {"phase": true, "spare_guise": true, "no_bite": true})
	return a


## One of Pale Reign's ghosts (its own breed, R38): a pale runner that touches dead (as pale, a body left) only people
## within `r` of `centre`.
static func pale_ghost(v: Visitors, at: Vector2, centre: Vector2, r: float) -> Animal:
	var mul := PALE_GHOST_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var a := v.summon(at, Animal.Breed.PALE_GHOST, SPIRIT_BLOWS, mul, 2.0 * r, PALE_GHOST_TOUCH, PALE_GHOST_EVERY, false)
	a.worn_tint = PALE_GHOST_TINT
	v.give(a, {"phase": true, "spare_guise": true, "touch_kill": &"pale", "bounds": Vector3(centre.x, centre.y, r)})
	return a


## A skeleton warrior comes up at `at` (R42): four blows, a walk of 1.3 (1.25 times that chasing), it strikes within 0.6
## every second (a citizen falls to one blow, a soldier to two), does not flinch, takes the nearest soldier within its seek
## first, and leaves a guised person alone. The wreck traits are the caller's.
static func skeleton(v: Visitors, at: Vector2) -> Animal:
	var mul := SKELETON_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var a := v.summon(at, Animal.Breed.SKELETON, SKELETON_BLOWS, mul, SKELETON_SEEK, SKELETON_REACH, SKELETON_EVERY, false)
	a.chase_mul = SKELETON_CHASE
	v.give(a, {"spare_guise": true, "prefer": "soldiers", "bite": SKELETON_BITE})
	return a


## A ghoul comes up at `at` (R42): two blows, a walk of 2.0 (1.2 times that chasing), it leaps within 0.8 every 0.9 s,
## knocks a citizen down first (a second bite kills), flinches when struck, and leaves a guised person alone. The wreck
## traits are the caller's.
static func ghoul(v: Visitors, at: Vector2) -> Animal:
	var mul := GHOUL_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var a := v.summon(at, Animal.Breed.GHOUL, GHOUL_BLOWS, mul, GHOUL_SEEK, GHOUL_REACH, GHOUL_EVERY, true)
	a.chase_mul = GHOUL_CHASE
	v.give(a, {"knock_first": true, "spare_guise": true})
	return a


## `victim` was just killed (a zombie's bite kills as frenzy): if they left a whole body, it rises as a zombie -- the
## chain -- and `left` (how many more may rise) comes back one fewer. A body that is not there (a stone death leaves none,
## the ledger is off, none are left to raise) leaves `left` as it was and raises nothing.
static func on_kill_rise(v: Visitors, remains: Remains, victim: Person, left: int) -> int:
	if left <= 0:
		return left
	var fresh := fresh_remain(remains, victim)
	if fresh == null:
		return left
	zombie(v, fresh, false)
	remains.take(fresh)
	return left - 1


## The body `victim` has just left: the youngest whole-body remain within RISE_NEAR of where they fell, under RISE_FRESH
## old (a Remain keeps no person, by design), or null -- none left (a stone death), or the ledger off.
static func fresh_remain(remains: Remains, victim: Person) -> Remains.Remain:
	if remains == null or not remains.enabled or victim == null or not is_instance_valid(victim):
		return null
	var fresh: Remains.Remain = null
	for r in remains.near(victim.ground_pos, RISE_NEAR):
		if remains.age(r) > RISE_FRESH or not Remains.BODY_KINDS.has(r.kind):
			continue
		if fresh == null or r.born > fresh.born:
			fresh = r
	return fresh
