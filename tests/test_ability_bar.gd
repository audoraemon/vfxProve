extends RefCounted
## The ability bar: its pages by god type, the number keys' meaning per page, the layout inside the HUD's 640x360 units, the hit
## tests, the page that survives an armed ability, the tile states and the redraw signature. Drawing itself is judged from captures.


## Dominion, ten Ruin, three Passage keys, in that loadout order.
const KEYS := ["whisper", "smite", "ember", "tornado", "scatter", "solaris", "dragon", "tsunami", "cinder", "tempest", "shatter",
	"skylift", "windfall", "houndgate"]
const VIEW := Vector2(640, 360)
const TILE_SIDE := AbilityBar.TILE


static func run(t) -> void:
	_pages(t)
	_setup_and_turn(t)
	_digits(t)
	_layout(t)
	_hits(t)
	_armed_across_pages(t)
	_states(t)
	_signature(t)


## A Rules over a bare town with `keys` as its loadout and a pool of `size`.
static func _rules(keys: PackedStringArray, size := 16) -> Rules:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, WalkGrid.new().setup(env, town), world, 5)
	var rules := Rules.new().setup(keys, null, env, field, crowd, town)
	rules.caster = func(_script: GDScript, _ground: Vector2, _extra: Dictionary) -> FxTimeline:
		return null
	rules.might = MightPool.make(size)
	return rules


## A bar over a fresh Rules holding `keys`.
static func _bar(keys := KEYS, own := "ruin", size := 16) -> AbilityBar:
	return AbilityBar.new().setup(_rules(PackedStringArray(keys), size), own)


## The type of each page.
static func _types(pages: Array) -> Array:
	var out := []
	for p: Dictionary in pages:
		out.append(p.type)
	return out


static func _pages(t) -> void:
	var pages := AbilityBar.pages_for("ruin", PackedStringArray(KEYS))
	t.check(_types(pages) == ["dominion", "ruin", "passage"], "pages_for ruin: the neighbours around the own type (%s)" % [_types(pages)])
	t.check(pages[1].slots == PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]), "a page's slots run in tree order (%s)" % [pages[1].slots])
	t.check(pages[0].slots == PackedInt32Array([0]) and pages[2].slots == PackedInt32Array([11, 12, 13]), "and index the loadout")
	var shuffled := PackedStringArray(["shatter", "smite", "tornado"])
	var order: PackedInt32Array = AbilityBar.pages_for("ruin", shuffled)[0].slots
	t.check(order == PackedInt32Array([1, 2, 0]), "tree order wins over loadout order (%s)" % [order])
	t.check(AbilityBar.pages_for("ruin", PackedStringArray(["smite", "ember"])).size() == 1, "ruin keys only: one page")
	t.check(AbilityBar.pages_for("", PackedStringArray()).is_empty(), "no keys: no page")
	var ring := _types(AbilityBar.pages_for("", PackedStringArray(["whisper", "smite", "skylift"])))
	t.check(ring == ["ruin", "passage", "dominion"], "no own type: ring order (%s)" % [ring])
	ring = _types(AbilityBar.pages_for("death", PackedStringArray(["smite", "whisper"])))
	t.check(ring == ["ruin", "dominion"], "an own type with no key: ring order too (%s)" % [ring])
	t.check(AbilityBar.pages_for("ruin", PackedStringArray(["no_such_key", ""])).is_empty(), "a key in no tree spot gets no page")


static func _setup_and_turn(t) -> void:
	var bar := _bar()
	t.check(bar.pages().size() == 3 and bar.page == 1 and not bar.open, "setup: three pages, on the own type's, hidden (page %d)" % bar.page)
	bar.turn(1)
	t.check(bar.page == 2, "turn(1) goes to the next page")
	bar.turn(1)
	t.check(bar.page == 0, "turn(1) from the last page wraps to 0")
	bar.turn(-1)
	t.check(bar.page == 2, "turn(-1) from 0 wraps to the last")
	bar.toggle()
	t.check(bar.open, "toggle opens")
	bar.toggle()
	t.check(not bar.open, "and closes")
	var one := _bar(["smite", "ember"])
	one.turn(1)
	one.turn(-1)
	t.check(one.page == 0 and one.pages().size() == 1 and one.page_flash() == 0.0, "one page: turn changes nothing")
	var far := _bar(["whisper", "skylift"], "death")
	t.check(far.page == 0, "an own type with no page opens on page 0")


static func _digits(t) -> void:
	var bar := _bar()
	t.check(bar.slot_for_digit(0) == 1 and bar.slot_for_digit(9) == 10, "digits 0..9 address the ruin page's ten slots")
	t.check(bar.slot_for_digit(10) == -1 and bar.slot_for_digit(-1) == -1, "a digit out of range is -1")
	bar.turn(1)
	t.check(bar.slot_for_digit(0) == 11 and bar.slot_for_digit(2) == 13 and bar.slot_for_digit(3) == -1,
		"a page of three answers digits 0..2 only (%d %d %d)" % [bar.slot_for_digit(0), bar.slot_for_digit(2), bar.slot_for_digit(3)])
	t.check(bar.digit_of(12) == 1 and bar.digit_of(1) == 0 and bar.digit_of(99) == -1, "digit_of is the place on the slot's own page")
	t.check(bar.page_of(12) == 2 and bar.page_of(0) == 0 and bar.page_of(99) == -1, "page_of names the slot's page")
	var none := _bar([], "ruin")
	var all_minus := true
	for d in 10:
		all_minus = all_minus and none.slot_for_digit(d) == -1
	t.check(none.pages().is_empty() and all_minus, "zero pages: every digit is -1")
	none.toggle()
	t.check(not none.open and none.rect(VIEW).size.y < Hud.SLOT_SIZE, "zero pages: it never opens, rect() is the strip")
	none.turn(1)
	t.check(none.page == 0, "and turning does nothing")


## True when `r` lies inside a view of that size.
static func _inside(r: Rect2, view: Vector2) -> bool:
	return Rect2(Vector2.ZERO, view).encloses(r)


static func _layout(t) -> void:
	var bar := _bar()
	bar.toggle()
	for view: Vector2 in [VIEW, Vector2(1280, 720), Vector2(480, 270)]:
		var ok := _inside(bar.rect(view), view)
		for i in 10:
			ok = ok and _inside(bar.tile_rect(i, view), view)
			for j in range(i + 1, 10):
				ok = ok and not bar.tile_rect(i, view).intersects(bar.tile_rect(j, view))
		for i in 3:
			ok = ok and _inside(bar.tab_rect(i, view), view)
			for j in range(i + 1, 3):
				ok = ok and not bar.tab_rect(i, view).intersects(bar.tab_rect(j, view))
		t.check(ok, "open at %s: tiles, tabs and rect() inside the view and apart" % [view])
	var big := Vector2(1280, 720)
	var first := bar.tile_rect(0, big)
	var last := bar.tile_rect(9, big)
	t.near((first.position.x + last.end.x) * 0.5, big.x * 0.5, 0.01, "the row is centred on the view")
	t.check(is_equal_approx(first.size.x, AbilityBar.TILE) and is_equal_approx(first.size.y, AbilityBar.TILE), "a tile is TILE square")
	var tile := bar.tile_rect(0, VIEW)
	t.check(AbilityBar._icon_rect(tile) == UiIcon.native_rect(tile.get_center(), TILE_SIDE), "a tile's icon sits at the native size")
	t.check(AbilityBar._icon_rect(bar.strip_tile_rect(VIEW)) == bar.strip_tile_rect(VIEW) or AbilityBar._icon_rect(bar.strip_tile_rect(VIEW)).size.x <= AbilityBar.STRIP_TILE,
		"the strip's icon never overflows its tile")
	t.check(bar.rect(VIEW).size.y <= AbilityBar.TILE + 3.0 * AbilityBar.LINE + 8.0, "open: no taller than a row and three lines (%.1f)" % bar.rect(VIEW).size.y)
	t.check(bar.rect(VIEW).end.y <= VIEW.y - AbilityBar.BOTTOM + 0.01, "and the bottom gap is kept")
	bar.toggle()
	t.check(bar.rect(VIEW).size.y < Hud.SLOT_SIZE and _inside(bar.rect(VIEW), VIEW), "hidden: the strip is shorter than a slot card and inside")
	var one := _bar(["smite", "ember"])
	one.toggle()
	t.check(one.tab_rect(0, VIEW) == Rect2() and one.rect(VIEW).size.y <= AbilityBar.TILE + 2.0 * AbilityBar.LINE + 8.0,
		"one page: no tabs, a shorter bar")
	var wide := _bar(KEYS, "ruin", 22)
	t.check(_inside(wide.rect(VIEW), VIEW), "a 22-segment gauge's strip fits 640 wide (%s)" % [wide.rect(VIEW)])
	wide.toggle()
	t.check(_inside(wide.rect(VIEW), VIEW), "and so does the open bar")


static func _hits(t) -> void:
	var bar := _bar()
	t.check(bar.hit(bar.rect(VIEW).get_center(), VIEW) == "strip", "hidden: the strip's centre is the strip")
	t.check(bar.hit(Vector2(5, 5), VIEW) == "", "elsewhere is empty")
	bar.toggle()
	var at: String = bar.hit(bar.tile_rect(2, VIEW).get_center(), VIEW)
	t.check(at == "tile:3", "a tile's centre names its loadout slot (%s)" % at)
	t.check(bar.hit(bar.tab_rect(2, VIEW).get_center(), VIEW) == "tab:2", "a tab's centre names the tab")
	t.check(bar.hit(Vector2(5, 5), VIEW) == "", "open: elsewhere is empty")
	t.check(bar.hit(bar.tile_rect(0, VIEW).position - Vector2(2, 2), VIEW) == "", "open: the gap beside a tile is empty")


static func _armed_across_pages(t) -> void:
	var bar := _bar()
	var armed := 3
	t.check(bar.page_of(armed) == 1, "the armed tornado is on the ruin page")
	bar.turn(1)
	t.check(bar.page_of(armed) == 1 and bar.page == 2, "turning does not move it")
	t.check(bar.armed_rect(armed, VIEW) == bar.strip_tile_rect(VIEW), "off its page, the strip's tile is where it is")
	t.check(bar.slot_for_digit(0) == 11, "a number key now arms from the new page")
	bar.toggle()
	t.check(bar.armed_rect(armed, VIEW) == bar.strip_tile_rect(VIEW), "open on another page: still the strip's tile")
	bar.turn(-1)
	t.check(bar.armed_rect(armed, VIEW) == bar.tile_rect(2, VIEW), "open on its own page: the bar's tile")
	t.check(bar.armed_rect(-1, VIEW) == Rect2(), "nothing armed: no rect")
	var flash := _bar()
	t.check(flash.page_flash() == 0.0, "no page flash at the start")
	flash.turn(1)
	t.near(flash.page_flash(), AbilityBar.PAGE_FLASH, 0.0001, "a turn starts the page flash")
	flash.advance(2.0)
	t.check(flash.page_flash() == 0.0, "which runs out")


static func _states(t) -> void:
	var rules := _rules(PackedStringArray(KEYS), 6)
	var bar := AbilityBar.new().setup(rules, "ruin")
	t.check(bar.tile_state(1) == "ready", "a fresh tile is ready (%s)" % bar.tile_state(1))
	t.check(bar.tile_state(99) == "empty", "a slot past the loadout is empty")
	rules.sealed = "smite"
	t.check(bar.tile_state(1) == "sealed", "the sealed key is sealed")
	rules.sealed = ""
	rules.might.pay(6.0)
	t.check(bar.tile_state(10) == "might", "an empty pool: a costly ability is 'might' (%s)" % bar.tile_state(10))
	rules.might.refill()
	rules._cooldowns[2] = 4.0
	t.check(bar.tile_state(2) == "cooldown", "a cooling tile is cooldown")
	rules.finished = true
	t.check(bar.tile_state(1) == "over", "a finished night is over")


static func _signature(t) -> void:
	var rules := _rules(PackedStringArray(KEYS), 16)
	var bar := AbilityBar.new().setup(rules, "ruin")
	var base := bar.signature(-1)
	t.check(bar.signature(-1) == base, "two calls with nothing changed agree")
	bar.toggle()
	var opened := bar.signature(-1)
	t.check(opened != base, "open changes it")
	bar.turn(1)
	t.check(bar.signature(-1) != opened, "page changes it")
	bar.turn(-1)
	bar.advance(2.0)
	t.check(bar.signature(-1) == opened, "back on the page, the flash run out, the signature returns")
	t.check(bar.signature(3) != opened, "the armed slot changes it")
	rules.might.pay(2.0)
	t.check(bar.signature(-1) != opened, "the pool's whole() changes it")
	var before := bar.signature(-1)
	rules._cooldowns[1] = 6.0
	t.check(bar.signature(-1) != before, "a tile's state changes it")
	t.check(bar.signature(-1) == bar.signature(-1), "and again two calls agree")
