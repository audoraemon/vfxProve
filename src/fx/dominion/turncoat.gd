class_name TurncoatFx
extends FxTimeline
## Turncoat (Dominion, Tier III): one person's loyalty is turned for TURN_TIME, and it works against its own side with
## the skills it has. The one nearest the click (PICK_R):
##   a soldier   fights the other soldiers (Person.fight(), OWN_KIND); set on a side of its own, so they may strike back.
##   anyone else sabotages: it walks to the nearest thing the town depends on within SABOTAGE_REACH -- a well, a gate, the
##               bell, the dock, the cathedral (BlightFx.blightable()) -- and ruins it (EnvironmentField.blight()),
##               then goes for the next.
## When the time is up only that layer is lifted. Quiet when cast: what it does is seen. Locks the other slots for 1 s.

const PICK_R := 1.0
const TURN_TIME := 30.0
const SABOTAGE_REACH := 14.0
## How near the thing it must stand to ruin it, and how long the ruining takes.
const SABOTAGE_AT := 1.0
const SABOTAGE_SECONDS := 2.0
const SIGHT := 8.0
const WILL := 0.9
const MARK := Color("ffb060")

var turned: Person
## What it has ruined, and what it is going for now.
var ruined := 0
var aim: Structure

var _working := 0.0
var _check_in := 0.0


## Whom a click at `at` would turn: the nearest within PICK_R, or null.
static func target_at(field: EnemyField, at: Vector2) -> Person:
	var near := DominionParts.near(field, at, PICK_R, 1)
	return near[0] if not near.is_empty() else null


func _build() -> void:
	duration = TURN_TIME + 0.5
	busy = 1.0
	turned = target_at(ctx.field, origin)
	at(TURN_TIME, _end)
	if turned == null:
		duration = 1.0
		return
	turned.side = 2
	turned.set_badge(DominionParts.SPLIT, MARK, TURN_TIME)
	if turned.soldier:
		turned.fight(null, TURN_TIME, Person.SOLDIER_BLOW, Person.FightRule.OWN_KIND, SIGHT)
	else:
		_next_aim()
	ctx.play(&"grav_arc", origin, -4.0)
	if DominionParts.staged(self):
		# The emblem cracks and flips: a flash split in two colours over the turned.
		DominionParts.pulse(self, turned.ground_pos, 1.4, DominionParts.GOLD, 0.8, 0.5)
		DominionParts.pulse(self, turned.ground_pos, 1.4, DominionParts.CRIMSON, 0.8, 1.0)
		DominionParts.motes(self, turned.ground_pos, [Color("fff0d0"), Color("ffb060"), Color("ff4040"), Color(0.5, 0.1, 0.1, 0.5)], 12)
		DominionParts.icon(self, turned, DominionParts.SPLIT, MARK, 2.0, 40.0)


## The nearest thing of use it has not ruined yet, and the walk to it.
func _next_aim() -> void:
	aim = null
	var best := SABOTAGE_REACH
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.destroyed or s.blighted or not BlightFx.blightable(s):
			continue
		var d := s.distance_to(turned.ground_pos)
		if d < best:
			best = d
			aim = s
	if aim == null:
		return
	var to := aim.center()
	if turned.grid != null:
		var free := turned.grid.nearest_walkable(to, 6)
		to = free if free != Vector2.INF else turned.ground_pos
	turned.compel(to, maxf(TURN_TIME - t, 1.0), WILL, MARK, false, &"", DominionParts.SPLIT)


func _fx_process(delta: float) -> void:
	if turned == null or not is_instance_valid(turned) or not turned.is_alive() or turned.soldier or t >= TURN_TIME:
		return
	_check_in -= delta
	if _check_in > 0.0:
		return
	_check_in = 0.25
	if aim == null or not is_instance_valid(aim) or aim.destroyed or aim.blighted or turned.mind != Person.Mind.COMPELLED:
		_working = 0.0
		if turned.mind == Person.Mind.COMPELLED or turned.mind == Person.Mind.CALM or turned.mind == Person.Mind.RECOVER:
			_next_aim()
		return
	if aim.distance_to(turned.ground_pos) <= SABOTAGE_AT:
		_working += 0.25
		if _working >= SABOTAGE_SECONDS:
			ctx.env.blight(aim)
			ruined += 1
			_working = 0.0
			if DominionParts.staged(self):
				DominionParts.motes(self, aim.center(), BlightFx.ROT, 14)
			_next_aim()


func _end() -> void:
	if turned == null or not is_instance_valid(turned):
		return
	turned.side = 0
	turned.clear_badge()
	if turned.is_alive():
		turned.stop_fighting()
		turned.release_compulsion()


func _exit_tree() -> void:
	if is_instance_valid(turned):
		turned.side = 0
	super()
