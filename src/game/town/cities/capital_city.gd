extends CityDef
## The Capital (placeholder until its layout lands): every CityDef method answers with empty data, so selecting or
## building it crashes nothing. City.by_id(&"capital") makes it.


func id() -> StringName:
	return &"capital"


func floor_areas() -> Dictionary:
	var none: Array[Rect2] = []
	return {
		&"plazas": none.duplicate(), &"yards": none.duplicate(), &"gate_plazas": none.duplicate(),
		&"building_yards": none.duplicate(), &"farm": none.duplicate(),
	}
