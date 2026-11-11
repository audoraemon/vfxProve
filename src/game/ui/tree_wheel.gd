class_name TreeWheel
extends RefCounted
## The Skill Tree wheel's geometry and Authority palette (statics only): five nested ovals (one per tier I-V), two spots on each,
## and the screen areas the wheel, the side columns, the top bar and the detail strip keep to. The screen is 640x360.

const CENTER := Vector2(320, 132)
const NODE_R := 12.0
const RY0 := 22.0
const RY_STEP := 20.0
const RX_SCALE := 1.45
## Degrees, tier I-V; spot 1 of a tier sits opposite spot 0 (+180).
const ANGLES := [60.0, 120.0, 30.0, 150.0, 90.0]

const COLORS := {
	"dominion": Color("9b7fd0"),
	"ruin": Color("e08a5a"),
	"death": Color("9fcf9a"),
	"passage": Color("6fc4b8"),
	"veil": Color("b4a8c8"),
	"decree": Color("d8c27a"),
}

const WHEEL_AREA := Rect2(128, 28, 384, 216)
const SIDE_L := Rect2(8, 34, 112, 198)
const SIDE_R := Rect2(520, 34, 112, 198)
const TOP_BAR := Rect2(0, 0, 640, 26)
const DETAIL := Rect2(8, 250, 624, 102)


static func color(type: String) -> Color:
	return COLORS.get(type, UiTheme.COL_TEXT)


## (rx, ry) of the oval of tier 1-5.
static func ring(tier: int) -> Vector2:
	var ry := RY0 + float(tier - 1) * RY_STEP
	return Vector2(ry * RX_SCALE, ry)


## Screen centre of spot i (0-1) of tier 1-5.
static func node_at(tier: int, i: int) -> Vector2:
	var a := deg_to_rad(float(ANGLES[tier - 1]) + float(i) * 180.0)
	var r := ring(tier)
	return Vector2(CENTER.x + sin(a) * r.x, CENTER.y - cos(a) * r.y)


## (tier, i) of the node whose circle holds the point, else (-1, -1).
static func node_hit(point: Vector2) -> Vector2i:
	for tier in range(1, 6):
		for i in 2:
			if node_at(tier, i).distance_to(point) <= NODE_R:
				return Vector2i(tier, i)
	return Vector2i(-1, -1)
