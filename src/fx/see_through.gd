class_name SeeThrough
extends RefCounted
## Buildings that stand in front of a tall effect go see-through while it stands, so the effect is never hidden behind
## a house: each step() every standing structure whose drawing (Structure.view_box()) overlaps the effect's screen rect
## and that sorts in front of it (its base lower on screen than the effect's foot) eases to ALPHA; one that no longer
## does eases back. The world layer's sort is untouched, so people still pass in front of the effect and behind it as
## they should. release() gives every building its own look back at once. Structure.modulate is the only thing touched.

const ALPHA := 0.3
## How fast a building fades (alpha a second).
const RATE := 3.0

## Structure -> the modulate alpha it had before it was faded.
var _faded := {}


## One step of `delta`: fade what stands in front of `rect` (world px) whose base sorts below `foot_y`; an empty `rect`
## fades nothing (all ease back).
func step(structures: Array, rect: Rect2, foot_y: float, delta: float) -> void:
	var now := {}
	for s in structures:
		var b := s as Structure
		if b == null or not is_instance_valid(b) or b.destroyed:
			continue
		if rect.has_area() and b.base_position().y > foot_y and b.view_box().intersects(rect):
			now[b] = true
			if not _faded.has(b):
				_faded[b] = b.modulate.a
	for b in _faded.keys():
		if not is_instance_valid(b):
			_faded.erase(b)
			continue
		var own: float = _faded[b]
		var target := ALPHA * own if now.has(b) else own
		b.modulate.a = move_toward(b.modulate.a, target, RATE * delta)
		if not now.has(b) and is_equal_approx(b.modulate.a, own):
			_faded.erase(b)


## Whether `s` is faded now (or easing back).
func fading(s: Structure) -> bool:
	return _faded.has(s)


## Every faded building back to its own look.
func release() -> void:
	for b in _faded.keys():
		if is_instance_valid(b):
			b.modulate.a = _faded[b]
	_faded.clear()
