extends RefCounted
## v0.10 M3 the wayside shrine (Structure.Kind.SHRINE): a stone post with a lantern niche, Broken Lanterns' own. Its
## health, its fall, and its relighting (restore()). Drawn by the procedural art on either art path. Never part of the
## shared town.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var s := env.add_structure(Rect2(0.0, 0.0, 0.4, 0.4), 22.0, Structure.Kind.SHRINE, &"shrine")
	var fell := [0]
	s.broken.connect(func(_b: Structure) -> void: fell[0] += 1)
	t.check(Structure.Kind.SHRINE == Structure.Kind.FOUNTAIN + 1, "the shrine kind comes last, after the fountain")
	t.check(s.max_hp == Structure.SHRINE_HP and s.hp == s.max_hp and not s.walkable,
		"a shrine stands at full health and blocks the way")
	t.check(SpriteArt.name_for(s) == "" and s.sprite.is_empty() and s.art.is_empty(),
		"no sprite and no art plan: the procedural post draws it on either art path")
	t.check(s.tuning_key() == "shrine" and Town.collapse_cue(s) == &"collapse_stone", "it falls with a stone crash")
	s.damage(Structure.SHRINE_HP - 1.0, s.center(), &"stone")
	t.check(not s.destroyed and fell[0] == 0, "a blow short of its health leaves it standing")
	s.damage(2.0, s.center(), &"stone")
	t.check(s.destroyed and fell[0] == 1, "the next breaks it")
	s.restore()
	t.check(not s.destroyed and s.hp == s.max_hp and s.scorch == 0.0, "relit, it stands again, whole")
	var shrines := 0
	for d in TownLayout.structures():
		shrines += 1 if d.kind == Structure.Kind.SHRINE else 0
	t.check(shrines == 0, "the shared town has no shrines: only Broken Lanterns places them")
	env.clear()
	env.free()
