class_name CommandEchoFx
extends FxTimeline
## Command Echo (Dominion, Tier III): a command planted in a few that passes from one to the next. The SEED_MAX people
## nearest the click (SEED_R) are given it; every ECHO_EVERY each carrier passes it to each person within ECHO_R who
## does not carry it, with ECHO_CHANCE -- by contact, not at once -- up to ECHO_MAX carriers, for SPREAD_TIME. Whoever
## catches it obeys for HOLD (Person.compel(), WILL: an evacuation does not call them away; a danger on them does).
## The command is the cast's mode:
##   GO HOME   each walks home (a soldier to its post) and stays.
##   GO THERE  two clicks: each walks to the second click's place, to a spot of its own.
## Quiet, but for the book entry's "alarm". The cast locks the other slots for 1 s.

const SEED_R := 1.2
const SEED_MAX := 5
const ECHO_EVERY := 1.0
const ECHO_R := 1.5
const ECHO_CHANCE := 0.4
const ECHO_MAX := 60
const SPREAD_TIME := 20.0
const HOLD := 25.0
const WILL := 0.8

var mode := "home"
## Everyone who has caught it, in the order they did.
var carriers: Array[Person] = []
var place := {}

var _spots: Array[Vector2] = []
var _echo_in := ECHO_EVERY
var _links: DominionParts.Links


func _build() -> void:
	mode = String(extra.get("mode", "home"))
	duration = SPREAD_TIME + HOLD
	busy = 1.0
	var seeds := DominionParts.near(ctx.field, origin, SEED_R, SEED_MAX)
	if mode == "go":
		place = CongregationFx.place_for(ctx.env, extra.get("to", origin))
		var grid: WalkGrid = seeds[0].grid if not seeds.is_empty() else null
		_spots = CongregationFx.spots_for(grid, place, ECHO_MAX)
	if DominionParts.staged(self):
		_links = DominionParts.links(self)
		if mode == "go":
			DominionParts.icon(self, place.at, DominionParts.WAVES, DominionParts.GOLD, SPREAD_TIME, 30.0)
	for p in seeds:
		_carry(p, null)
	ctx.play(&"grav_shimmer", origin, -10.0)


## `p` catches the command (from `from`, or from the god).
func _carry(p: Person, from: Person) -> bool:
	if carriers.size() >= ECHO_MAX or p in carriers or p.mind == Person.Mind.COMPELLED:
		return false
	var to := DominionParts.home_of(p)
	if mode == "go":
		to = _spots[carriers.size()] if carriers.size() < _spots.size() else place.at
	if not p.compel(to, HOLD, WILL, DominionParts.GOLD, false, &"", DominionParts.WAVES):
		return false
	carriers.append(p)
	if is_instance_valid(_links):
		if from != null:
			_links.add(from, p, DominionParts.GOLD)
		DominionParts.motes(self, p.ground_pos, DominionParts.GOLD_LIFE, 4)
	return true


func _fx_process(delta: float) -> void:
	if t > SPREAD_TIME:
		return
	_echo_in -= delta
	if _echo_in > 0.0:
		return
	_echo_in = ECHO_EVERY
	var fresh: Array = []
	for p in carriers:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.mind != Person.Mind.COMPELLED:
			continue
		for q in DominionParts.near(ctx.field, p.ground_pos, ECHO_R):
			if q != p and q.mind != Person.Mind.COMPELLED and not q in carriers and ctx.rng.randf() < ECHO_CHANCE:
				fresh.append([q, p])
	for f: Array in fresh:
		_carry(f[0], f[1])
