extends SceneTree
## Renders A-Z and a-z through UiTheme at 11/13/16/22 u to one PNG, magnified, for reading glyphs by eye.
## godot --path . --script tools/dev/glyph_sheet.gd -- out.png

class Sheet extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 700, 200), Color.BLACK)
		var y := 4.0
		for size in [11, 13, 16, 22]:
			for row in ["ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"]:
				var s := ""
				for c in row:
					s += c + " "
				UiTheme.text(self, Vector2(4, y + size), s, size)
				y += size + 4
		
func _initialize() -> void:
	var out := "res://glyph_sheet.png"
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var vp := SubViewport.new()
	vp.size = Vector2i(700, 200)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	vp.add_child(Sheet.new())
	await process_frame
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	img = img
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(out)
	quit()
