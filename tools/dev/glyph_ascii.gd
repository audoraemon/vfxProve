extends SceneTree
## Prints the pixels and advance of letters at 11 u: godot --path . --script tools/dev/glyph_ascii.gd -- BGHZ
class Sheet extends Node2D:
	var chars := ""
	var SZ := 11
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 400, 20), Color.BLACK)
		var x := 2.0
		for c in chars:
			draw_string(UiTheme.base_font(), Vector2(x, 14), c, HORIZONTAL_ALIGNMENT_LEFT, -1, SZ, Color.WHITE)
			x += 14
var SZ := 11
func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 1: SZ = int(OS.get_cmdline_user_args()[1])
	var chars := String(OS.get_cmdline_user_args()[0])
	var vp := SubViewport.new()
	vp.size = Vector2i(400, 20)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var s := Sheet.new()
	s.chars = chars
	s.SZ = SZ
	vp.add_child(s)
	for i in 3: await process_frame
	var img := vp.get_texture().get_image()
	for i in chars.length():
		var c := chars[i]
		print("== ", c, " advance ", UiTheme.base_font().get_char_size(c.unicode_at(0), SZ).x)
		for y in 20:
			var row := ""
			for x in 14:
				row += "#" if img.get_pixel(2 + i * 14 + x, y).r > 0.5 else "."
			if row.contains("#"): print(row)
	quit()
