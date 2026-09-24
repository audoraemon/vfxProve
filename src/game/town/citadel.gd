class_name Citadel
extends Node
## The Royal Citadel: a fortress of nine real buildings (4 corner towers, 4 curtain walls, the central keep) sharing
## one hidden health pool. It loses at most `budget_per_second` of its health in any rolling second, so no single
## strike flattens it. Every 10% lost collapses the standing outer part nearest the blow; the keep falls last, at 0%.
## Hits show before anything falls: parts shake, crack and scorch; courtyard fires start at 40% and the keep's
## banner falls at 20%.

signal health_changed(fraction: float)
## Every part as it collapses, the keep included (last).
signal part_collapsed(part: Structure)
signal fallen

## Part footprints relative to the keep's centre (ground units): NW, NE, SW, SE towers; N, S, W, E walls; keep.
const TOWERS := [Rect2(-2.7, -2.3, 1.3, 1.3), Rect2(1.4, -2.3, 1.3, 1.3), Rect2(-2.7, 1.0, 1.3, 1.3), Rect2(1.4, 1.0, 1.3, 1.3)]
const WALLS := [Rect2(-1.4, -2.2, 2.8, 0.6), Rect2(-1.4, 1.6, 2.8, 0.6), Rect2(-2.6, -1.0, 0.6, 2.0), Rect2(2.0, -1.0, 0.6, 2.0)]
const KEEP := Rect2(-1.0, -1.0, 2.0, 2.0)
const TOWER_H := 84.0
const WALL_H := 40.0
const KEEP_H := 118.0
const OUTER := 8
## Health share of each outer part; the keep holds the last 20%.
const STEP := 0.1
const FIRE_AT := 0.4
const BANNER_AT := 0.2
## Courtyard spots (relative to the keep's centre) that catch fire at FIRE_AT.
const FIRE_POINTS := [Vector2(-1.7, -1.3), Vector2(1.6, 1.3), Vector2(-1.5, 1.4)]
const FIRE_SECONDS := 120.0

var max_health := 1000.0
## Largest share of max_health lost in any rolling second.
var budget_per_second := 0.25
var health := 1000.0
## Centre of the keep, in ground units.
var origin := Vector2.ZERO
## NW, NE, SW, SE towers, then N, S, W, E walls, then the keep.
var parts: Array[Structure] = []
var keep: Structure

var _env: EnvironmentField
var _shake: CameraShake
var _clock := 0.0
## Recent losses as [time, amount] for the rolling budget.
var _window: Array = []
## 10% marks passed so far (0..OUTER).
var _marks := 0
var _fires_lit := false
var _banner_dropped := false
var _fallen := false


func setup(env: EnvironmentField, at: Vector2, shake: CameraShake = null) -> Citadel:
	_env = env
	_shake = shake
	origin = at
	health = max_health
	parts.clear()
	keep = null
	_window.clear()
	_clock = 0.0
	_marks = 0
	_fires_lit = false
	_banner_dropped = false
	_fallen = false
	for r: Rect2 in TOWERS:
		_add_part(r, TOWER_H, Structure.Kind.KEEP)
	for r: Rect2 in WALLS:
		_add_part(r, WALL_H, Structure.Kind.CASTLE_WALL)
	keep = _add_part(KEEP, KEEP_H, Structure.Kind.KEEP)
	return self


func fraction() -> float:
	return health / max_health


func standing_parts() -> int:
	var n := 0
	for p in parts:
		if is_instance_valid(p) and not p.destroyed:
			n += 1
	return n


func is_fallen() -> bool:
	return _fallen


## The Citadel's clock: forgets losses older than one second. Runs in _process; tests call it directly.
func advance(delta: float) -> void:
	_clock += delta
	while not _window.is_empty() and _window[0][0] <= _clock - 1.0:
		_window.pop_front()


func _process(delta: float) -> void:
	advance(delta)


func _add_part(rel: Rect2, h: float, kind: Structure.Kind) -> Structure:
	var s := _env.add_structure(Rect2(rel.position + origin, rel.size), h, kind, &"citadel")
	s.damage_filter = _on_part_hit
	parts.append(s)
	return s


func _budget_left() -> float:
	var used := 0.0
	for e in _window:
		used += e[1]
	return max_health * budget_per_second - used


## Every hit on any part lands here instead of on the part's own health.
func _on_part_hit(part: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	if _fallen:
		return
	part.mark_hit(minf(amount / part.max_hp, 1.0) * 0.25, kind)
	var loss := minf(amount, _budget_left())
	if loss <= 0.0:
		return
	_window.append([_clock, loss])
	health = maxf(health - loss, 0.0)
	if fraction() < 0.9:
		part.crack()
	health_changed.emit(fraction())
	_advance_stages(source, kind)


func _advance_stages(source: Vector2, kind: StringName) -> void:
	var f := fraction()
	while _marks < OUTER and f <= 1.0 - STEP * (_marks + 1) + 0.0001:
		_marks += 1
		var p := _nearest_standing_outer(source)
		if p != null:
			_collapse(p, source, kind)
	if f <= FIRE_AT and not _fires_lit:
		_fires_lit = true
		for spot: Vector2 in FIRE_POINTS:
			keep.ignite(Iso.ground_to_screen(origin + spot) - keep.position, FIRE_SECONDS)
	if f <= BANNER_AT and not _banner_dropped:
		_banner_dropped = true
		keep.drop_banner()
	if f <= 0.0:
		_fall(source, kind)


func _nearest_standing_outer(source: Vector2) -> Structure:
	var best: Structure = null
	var best_d := INF
	for i in OUTER:
		var p := parts[i]
		if p.destroyed:
			continue
		var d := p.distance_to(source)
		if d < best_d:
			best = p
			best_d = d
	return best


func _collapse(p: Structure, source: Vector2, kind: StringName) -> void:
	p.destroy(source, kind)
	p.dust_burst(1.0)
	if _shake != null:
		_shake.add_trauma(0.3)
	part_collapsed.emit(p)


func _fall(source: Vector2, kind: StringName) -> void:
	_fallen = true
	for i in OUTER:
		if not parts[i].destroyed:
			_collapse(parts[i], source, kind)
	keep.destroy(source, kind)
	keep.dust_burst(2.5)
	if _shake != null:
		_shake.add_trauma(0.8)
	part_collapsed.emit(keep)
	fallen.emit()
