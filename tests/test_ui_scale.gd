extends RefCounted
## UI resolution milestone: integer scaling of the 640x360 frame.


static func _integer_setting(t) -> void:
	t.check(str(ProjectSettings.get_setting("display/window/stretch/scale_mode")) == "integer", "the frame scales by whole numbers only (crisp at every window size)")


static func run(t) -> void:
	_integer_setting(t)
