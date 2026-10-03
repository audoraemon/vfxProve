class_name OathboundFx
extends FxTimeline
## Oathbound (Dominion, Tier III): a lasting task. Up to MAX_BOUND people nearest the click (PICK_R) -- any role -- are
## bound for OATH_TIME, held by WILL: no evacuation, duty or regrouping calls them away, though a danger on top of
## them still breaks it. The task is the cast's mode:
##   REMAIN        they stay where they stand.
##   HOLD A PLACE  two clicks: they go to the second click's place (a building's walls, or the ground) and hold it.
## Bind the bellkeeper and the bell is not rung; bind the clergy and the rite cannot gather. Quiet: nobody sees it.
## The cast locks the other slots for 1 s.

const PICK_R := 1.2
const MAX_BOUND := 4
const OATH_TIME := 60.0
const WILL := 0.9
const CHAIN_SECONDS := 0.9

var mode := "remain"
var bound: Array[Person] = []
## Where they hold (the Hold mode), else Vector2.INF.
var place_at := Vector2.INF


## Whom a click at `at` would bind: the nearest `most` within PICK_R.
static func bound_at(field: EnemyField, at: Vector2, most := MAX_BOUND) -> Array[Person]:
	return DominionParts.near(field, at, PICK_R, most)


func _build() -> void:
	mode = String(extra.get("mode", "remain"))
	duration = OATH_TIME + 0.5
	busy = 1.0
	var targets := bound_at(ctx.field, origin)
	var spots: Array[Vector2] = []
	if mode == "hold" and extra.has("to"):
		var place := CongregationFx.place_for(ctx.env, extra.to)
		place_at = place.at
		var grid: WalkGrid = targets[0].grid if not targets.is_empty() else null
		spots = CongregationFx.spots_for(grid, place, targets.size())
	for i in targets.size():
		var p := targets[i]
		var spot: Vector2 = spots[i] if i < spots.size() else p.ground_pos
		if p.compel(spot, OATH_TIME, WILL, DominionParts.GOLD, false, &"", DominionParts.RINGS):
			bound.append(p)
	ctx.play(&"grav_compress", origin, -10.0)
	if DominionParts.staged(self):
		_show()


## How many still keep their oath.
func keeping() -> int:
	var n := 0
	for p in bound:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.COMPELLED:
			n += 1
	return n


func _show() -> void:
	var chains := Chains.new()
	chains.fx = self
	chains.z_index = 5
	track(chains, ctx.overhead)
	for p in bound:
		DominionParts.motes(self, p.ground_pos, DominionParts.GOLD_LIFE, 6)
	if place_at != Vector2.INF:
		# The anchor: the same linked rings over the place they hold, for as long as the oath lasts.
		DominionParts.icon(self, place_at, DominionParts.RINGS, DominionParts.GOLD, OATH_TIME, 30.0)
		DominionParts.pulse(self, place_at, 1.6, DominionParts.GOLD)
		var links := DominionParts.links(self)
		for p in bound:
			links.add(p, Iso.ground_to_screen(place_at) + Vector2(0, -30), DominionParts.GOLD)


## The chain: two rings of light closing round each of the bound, then gone.
class Chains extends Node2D:
	var fx: OathboundFx

	func _process(_delta: float) -> void:
		if fx.t > CHAIN_SECONDS:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(fx.t / CHAIN_SECONDS, 0.0, 1.0)
		var r := lerpf(16.0, 5.0, k)
		for p in fx.bound:
			if not is_instance_valid(p):
				continue
			var at := Iso.ground_to_screen(p.ground_pos) + Vector2(0, -8)
			for i in 2:
				var turn := fx.t * 7.0 * (1.0 if i == 0 else -1.0)
				draw_set_transform(at + Vector2(0, -3.0 + 6.0 * float(i)), 0.0, Vector2(1.0, 0.45))
				draw_arc(Vector2.ZERO, r, turn, turn + TAU * 0.8, 14, Color(DominionParts.GOLD, 1.0 - k * 0.5), 1.0)
		draw_set_transform(Vector2.ZERO)
