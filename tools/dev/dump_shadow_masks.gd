extends SceneTree
## Dev: writes the baked shadow mask (TownShadows.mask_for) of a few sprite sets under their intact still, to check the
## shadow's shape by eye. usage: godot --headless --path . --script res://tools/dev/dump_shadow_masks.gd --
## --out=<dir> [--sets=town_wall,cathedral]   (each set plain and mirrored: <set>.png, <set>_m.png, 3x)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := "user://shadow_masks"
	var sets := ["town_wall", "town_tower", "cathedral", "citadel_keep", "stall_1", "tavern"]
	for a in args:
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--sets="):
			sets = Array(a.trim_prefix("--sets=").split(","))
	DirAccess.make_dir_recursive_absolute(out)
	for n: String in sets:
		for mirror in [false, true]:
			var art: Dictionary = SpriteArt.sprite(n).duplicate()
			if art.is_empty():
				print("no set ", n)
				continue
			art.mirror = mirror
			var still: Texture2D = art.stills[&"intact"]
			var m := TownShadows.mask_for(still, art)
			var mask: Image = (m.tex as Texture2D).get_image()
			var img := still.get_image()
			if img.is_compressed():
				img.decompress()
			img = img.duplicate()
			img.convert(Image.FORMAT_RGBA8)
			if mirror:
				img.flip_x()
			var sheet := Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_RGBA8)
			sheet.fill(Color(0.85, 0.8, 0.7))
			for y in mask.get_height():
				for x in mask.get_width():
					if mask.get_pixel(x, y).a > 0.5:
						sheet.set_pixel(x, y, Color(0.25, 0.3, 0.5))
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(TownShadows.MASK_PAD, TownShadows.MASK_PAD))
			var anchor: Vector2 = art.anchor
			if mirror:
				anchor.x = img.get_width() - anchor.x
			var ap := Vector2i(anchor) + Vector2i(TownShadows.MASK_PAD, TownShadows.MASK_PAD)
			if Rect2i(Vector2i.ZERO, sheet.get_size()).has_point(ap):
				sheet.set_pixelv(ap, Color.RED)
			sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
			sheet.save_png(out.path_join("%s%s.png" % [n, "_m" if mirror else ""]))
	quit()
