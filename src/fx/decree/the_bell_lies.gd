class_name BellLiesFx
extends FxTimeline
## The Bell Lies (Decree, Tier II): the town's own warning is made false. It works at the Bell Tower wherever the
## click lands, T_CAST after the cast; what the bell says is the cast's mode:
##   ALL IS WELL     the bell tolls that all is well, at once (Crowd.false_bell()): the alarm falls, everyone who
##                   hears takes heart and drops their fright, and a warning already given is taken back
##                   (Crowd.unring_bell()). And for LIE_TIME it goes on lying (Crowd.bell_lies()): each time the keeper
##                   rings it, it tolls all is well again, and the keeper, baffled, must try once more.
##   CALL THE GUARD  the bell calls the soldiers to the clicked place: up to GUARDS of them, the nearest first, run
##                   there and stand for GUARD_TIME (a compulsion of WILL_FIRM) -- away from wherever they were needed.
## Quiet: nobody sees a law change, and a bell is only a bell.

const LIE_TIME := 45.0
const T_CAST := 0.8
const UP := 74.0
const GUARDS := 12
const GUARD_TIME := 20.0
const GUARD_RING := 1.4

var mode := "well"
## How many times the bell has lied under this cast, and how many soldiers its call sent.
var lies := 0
var called := 0

var _tower := Vector2.ZERO


func _build() -> void:
	mode = String(extra.get("mode", "well"))
	if not mode in ["well", "guard"]:
		mode = "well"
	duration = T_CAST + (LIE_TIME if mode == "well" else GUARD_TIME) + 1.0
	busy = T_CAST
	_tower = TownLayout.BELL_TOWER.get_center()
	at(T_CAST, _toll_well if mode == "well" else _call_guard)
	ctx.play(&"hs_charge", _tower, -10.0)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, _tower, 54.0, UP, T_CAST, 1.4)
		var mark := FxParts.rings(self, _tower, 1.8, DecreeParts.GILT, 2, 14.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_CAST, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_CAST + 0.6


func _toll_well() -> void:
	if ctx.crowd != null:
		ctx.crowd.bell_lied.connect(_on_lie)
		ctx.crowd.bell_lies(LIE_TIME)
		ctx.crowd.unring_bell()
		ctx.crowd.false_bell(_tower)
	if not DominionParts.staged(self):
		return
	# The bell's sign turns over and stays over the tower, small, for as long as the lie holds.
	var plate := DecreeParts.seal(self, _tower, DecreeParts.BELL_DOWN, LIE_TIME, UP, 3)
	plate.shrink_at = 2.5


func _call_guard() -> void:
	if ctx.crowd != null:
		var pool: Array[Person] = []
		for s in ctx.crowd.soldiers:
			if is_instance_valid(s) and s.is_alive() and not s.inside:
				pool.append(s)
		pool.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(origin) < b.ground_pos.distance_squared_to(origin))
		pool = pool.slice(0, GUARDS)
		for i in pool.size():
			var p := pool[i]
			var spot := origin + Vector2.from_angle(TAU * float(i) / float(pool.size())) * GUARD_RING
			if p.grid != null:
				var near := p.grid.nearest_walkable(spot)
				spot = near if near != Vector2.INF else origin
			if p.compel(spot, GUARD_TIME, Person.WILL_FIRM, DecreeParts.GILT, true, &"", DecreeParts.BELL):
				called += 1
		if ctx.crowd.sfx != null:
			ctx.crowd.sfx.play(&"town_bell", _tower)
	if not DominionParts.staged(self):
		return
	_rings(_tower, 2)
	DecreeParts.seal(self, _tower, DecreeParts.BELL, 2.4, UP + 26.0, 4)
	# Where it sends them: the bell's sign over the place, and the ground marked.
	DecreeParts.seal(self, origin, DecreeParts.BELL, GUARD_TIME, 46.0, 2)
	DominionParts.ground_sigil(self, origin, GUARD_RING + 0.6, DecreeParts.GILT, 0.5, 2.5)
	DecreeParts.wave(self, origin, 3.0, 0.6)
	DominionParts.pulse(self, origin, 3.0, DecreeParts.GILT, 0.6, 1.4)


## The bell tolled, and lied.
func _on_lie(at_tower: Vector2) -> void:
	lies += 1
	if not DominionParts.staged(self):
		return
	# Slow rings go out over the town, soft where a true bell's would be hard, and the sign shows large, struck through.
	_rings(at_tower, 3)
	var plate := DecreeParts.seal(self, at_tower, DecreeParts.BELL_DOWN, 2.4, UP + 26.0, 4)
	plate.strike()
	DecreeParts.scatter(self, at_tower, 10, UP - 20.0)
	DominionParts.pulse(self, at_tower, 5.0, Color(1.0, 0.9, 0.6), 0.5, 1.6)


## The toll, seen: `count` slow rings out from the tower over the town.
func _rings(from: Vector2, count: int) -> void:
	for i in count:
		var w := FxParts.shockwave(self, from, 16.0, DecreeParts.GILT_RAMP)
		w.set_param("progress", 0.02)
		w.set_param("fade", 0.0)
		w.set_param("thickness", 0.035)
		w.tween_param("progress", 0.02, 1.0, 2.2, 0.35 * float(i), Tween.TRANS_SINE, Tween.EASE_OUT)
		w.tween_param("fade", 0.0, 0.8, 0.1, 0.35 * float(i))
		w.tween_param("fade", 0.8, 0.0, 1.2, 0.35 * float(i) + 1.0)
		w.life = 2.3 + 0.35 * float(i)
