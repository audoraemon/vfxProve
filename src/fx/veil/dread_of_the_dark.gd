class_name DreadOfTheDarkFx
extends FxTimeline
## Dread of the Dark (Veil): a stub until its own task builds it. It lands at once and leaves its dusk (VeilParts.land()).


## Why a Dread cast at `ground` must be refused ("no_dark": no dark ground in its reach), else "" (Rules.cast() asks; a refused cast
## spends no cooldown). `crowd` may be null; `dark` is the cast's own stamp. A stub that allows every cast until Task 8 fills it.
static func refusal(_crowd: Crowd, _ground: Vector2, _dark: bool) -> String:
	return ""


func _build() -> void:
	duration = 1.0
	VeilParts.land(self, origin)
