extends Node
## Autoload: steps the sprites' shared idle clock (SpriteView.advance()) once a frame with the game's delta, so time
## scale (slow-mo, hit-stop) and pause slow or stop every idle strip as they did when each view stepped its own.


func _process(delta: float) -> void:
	SpriteView.advance(delta)
