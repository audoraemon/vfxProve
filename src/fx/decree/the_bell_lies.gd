class_name BellLiesFx
extends FxTimeline
## The Bell Lies (Decree, Tier II): the town's own warning is made false. T_CAST after the cast, and for LIE_TIME, the
## bell lies (Crowd.bell_lies()): when the keeper rings it, it tolls that all is well -- the town is not warned, its
## alarm falls, everyone who hears takes heart (Crowd.false_bell()) -- and the keeper, baffled, tries again and is
## made a liar again. Nothing happens if nobody rings: it is laid before the town is frightened, not after. It works
## at the Bell Tower wherever the click lands. Quiet: nobody sees a law change.

const LIE_TIME := 45.0
const T_CAST := 0.8
const UP := 74.0

## How many times the bell has lied under this cast.
var lies := 0

var _tower := Vector2.ZERO


func _build() -> void:
	duration = T_CAST + LIE_TIME + 1.0
	busy = T_CAST
	_tower = TownLayout.BELL_TOWER.get_center()
	at(T_CAST, _begin)
	ctx.play(&"hs_charge", _tower, -10.0)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, _tower, 54.0, UP, T_CAST, 1.4)
		var mark := FxParts.rings(self, _tower, 1.8, DecreeParts.GILT, 2, 14.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_CAST, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_CAST + 0.6


func _begin() -> void:
	if ctx.crowd != null:
		ctx.crowd.bell_lies(LIE_TIME)
		ctx.crowd.bell_lied.connect(_on_lie)
	if not DominionParts.staged(self):
		return
	# The bell's sign turns over and stays over the tower, small, for as long as the lie holds.
	var plate := DecreeParts.seal(self, _tower, DecreeParts.BELL_DOWN, LIE_TIME, UP, 3)
	plate.shrink_at = 2.5
	DecreeParts.scatter(self, _tower, 12, UP - 20.0)
	DominionParts.pulse(self, _tower, 2.4, DecreeParts.GILT, 0.5, 1.0)
	DecreeParts.wave(self, _tower, 3.0, 0.5)


## The bell tolled, and lied.
func _on_lie(at_tower: Vector2) -> void:
	lies += 1
	if not DominionParts.staged(self):
		return
	# Three slow rings go out over the town, soft where a true bell's would be hard, and the sign shows large again.
	for i in 3:
		var w := FxParts.shockwave(self, at_tower, 16.0, DecreeParts.GILT_RAMP)
		w.set_param("progress", 0.02)
		w.set_param("fade", 0.0)
		w.set_param("thickness", 0.035)
		w.tween_param("progress", 0.02, 1.0, 2.2, 0.35 * float(i), Tween.TRANS_SINE, Tween.EASE_OUT)
		w.tween_param("fade", 0.0, 0.8, 0.1, 0.35 * float(i))
		w.tween_param("fade", 0.8, 0.0, 1.2, 0.35 * float(i) + 1.0)
		w.life = 2.3 + 0.35 * float(i)
	var plate := DecreeParts.seal(self, at_tower, DecreeParts.BELL_DOWN, 2.4, UP + 26.0, 4)
	plate.strike()
	DecreeParts.scatter(self, at_tower, 10, UP - 20.0)
	DominionParts.pulse(self, at_tower, 5.0, Color(1.0, 0.9, 0.6), 0.5, 1.6)
