class_name ArtToggle
extends Node
## F7 flips the buildings between their PixelLab sprites and the procedural art (SpriteArt), live, for old-vs-new
## comparisons in the PixelLab structures proof. `-- --art=procedural` starts with the procedural art.

const TOGGLE_KEY := KEY_F7

var env: EnvironmentField


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == TOGGLE_KEY:
		toggle()


func toggle() -> void:
	SpriteArt.set_enabled(not SpriteArt.on())
	if env != null:
		for s in env.structures():
			if is_instance_valid(s):
				s.refresh_sprite()
	# Decor, the forest bands and the floor bake follow too (group "decor_art", art_changed()).
	if is_inside_tree():
		get_tree().call_group(&"decor_art", &"art_changed")
	print("Building art: ", "sprites" if SpriteArt.on() else "procedural")
