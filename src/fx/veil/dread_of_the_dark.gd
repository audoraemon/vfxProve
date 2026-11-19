class_name DreadOfTheDarkFx
extends FxTimeline
## Dread of the Dark (Veil): a stub until its own task builds it. It lands at once and leaves its dusk (VeilParts.land()).


func _build() -> void:
	duration = 1.0
	VeilParts.land(self, origin)
