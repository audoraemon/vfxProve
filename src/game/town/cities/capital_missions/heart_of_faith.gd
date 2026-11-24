extends RefCounted
## The Heart of Faith in the Capital (plan "The Capital at every tier", Task 23; spec 6.4.5): the Temple is the cathedral (steps_at_spot at its front, (-3.9, -14.0); the Citadel's
## gate is the place citadel_gate, (0.0, -22.6)); Odran's litter road goes by the foot of the lane at (2.0, -13.0) in the pilgrim plaza. Three points were moved off the spec's
## (task-23-report.md, gates judged against Aldermere's own on this branch: A 3/3 median 181 s, B 3/3 median 201 s):
## - the oil-house: the patrician row at (-11.0, -20.0) has no dwelling (its buildings are gpt props; the nearest dwelling is 14.6 off). The Capital's dwellings the street from the Citadel's
##   gate reaches lie along the row at y -3.5..-5.1 and in the east; each was measured for who stands near it (task-23-report.md). The first two tried (1.8, -3.5) and (6.3, -5.1) lost
##   2 of 6 runs on the Gaze (Knights Doomed in the crowded street, seen by 8-13); the west house at (-16.19, -6.375), the only dwelling in the west, wins all six, 17.4 from the steps
##   against Aldermere's 19.2 (0.91x);
## - the oil-house's Knights stand on its west face, (-18.0, -6.4) (the quiet one: one person within a Silent Doom's witness reach);
## - the Temple's Knights stand on its east face, (-0.8, -17.7) (the west face the spec asked for had Doomed Knights seen by 5-8 and lost route A seed 3 on the Gaze);
## - the camera rests at (-13.0, -17.0): with the oil-house in the far west the spec's (-6.0, -16.0) puts it in the HUD stack (only cameras west of x -11 clear every tag and arrow).
## Floats carry a decimal point (Overrides is strict).


static func overrides() -> Dictionary:
	var camera := Vector2(-13.0, -17.0)
	return {
		"def": {"camera_at": camera, "intro_from": camera + Vector2(0.0, 6.0)},
		"director": {
			"oil_at": Vector2(-16.19398, -6.375),
			"steps_at_spot": Vector2(-3.9, -14.0),
			"lane_foot": Vector2(2.0, -13.0),
			"quiet_at": [Vector2(-18.0, -6.4), Vector2(-0.8, -17.7)],
		},
	}
