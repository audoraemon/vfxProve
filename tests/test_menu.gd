extends RefCounted
## Buttons: laid out in a column or a row without touching, centred where asked, and the point under the
## mouse maps to the right one -- or to none, between them.


static func run(t) -> void:
	var col := Menu.column(["play", "sandbox", "quit"], ["Play", "VFX Sandbox", "Quit"], 320.0, 200.0, 120.0)
	t.check(col.items.size() == 3, "a column of three buttons (%d)" % col.items.size())
	var a := col.rect_of("play")
	var b := col.rect_of("sandbox")
	var c := col.rect_of("quit")
	t.check(a.end.y < b.position.y and b.end.y < c.position.y, "stacked top to bottom, with a gap between")
	t.near(a.get_center().x, 320.0, 0.51, "centred on the x it was given (%.1f)" % a.get_center().x)
	t.near(a.size.y, Menu.HEIGHT, 0.001, "every button is one height")

	t.check(col.at(b.get_center()) == "sandbox", "the point over a button is that button (%s)" % col.at(b.get_center()))
	t.check(col.at(Vector2(320.0, a.end.y + 2.0)) == "", "the gap between two buttons is nobody's")
	t.check(col.at(Vector2(10.0, 10.0)) == "", "and so is the rest of the screen")
	t.check(col.rect_of("nothing") == Rect2(), "an action the menu does not have has no rect")

	var row := Menu.row(["replay", "change", "title"], ["Replay", "Change powers", "Title"], 320.0, 300.0, 100.0)
	var left := row.rect_of("replay")
	var right := row.rect_of("title")
	t.check(left.end.x < row.rect_of("change").position.x and row.rect_of("change").end.x < right.position.x,
		"a row runs left to right without touching")
	t.near((left.position.x + right.end.x) * 0.5, 320.0, 0.51, "and is centred as a whole")
	t.check(row.at(right.get_center()) == "title", "the last one answers to its own point")
