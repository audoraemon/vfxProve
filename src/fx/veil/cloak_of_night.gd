class_name CloakOfNightFx
extends FxTimeline
## Cloak of Night (Veil): a stub until its own task builds it. It lands at once and leaves its dusk (VeilParts.land()).


func _build() -> void:
	duration = 1.0
	VeilParts.land(self, origin)
