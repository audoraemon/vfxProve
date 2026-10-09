extends SceneTree

const SUITES := [
	"res://tests/test_iso.gd",
	"res://tests/test_enemy_field.gd",
	"res://tests/test_fx_timeline.gd",
	"res://tests/test_sfx_catalog.gd",
	"res://tests/test_environment.gd",
	"res://tests/test_freeze.gd",
	"res://tests/test_structure_roles.gd",
	"res://tests/test_building_kinds.gd",
	"res://tests/test_art_kit.gd",
	"res://tests/test_town_decor.gd",
	"res://tests/test_art_tuning.gd",
	"res://tests/test_sprite_art.gd",
	"res://tests/test_decor_sprites.gd",
	"res://tests/test_people_art.gd",
	"res://tests/test_town_layout.gd",
	"res://tests/test_citadel.gd",
	"res://tests/test_town.gd",
	"res://tests/test_power_book.gd",
	"res://tests/test_walk_grid.gd",
	"res://tests/test_person.gd",
	"res://tests/test_crowd.gd",
	"res://tests/test_threats.gd",
	"res://tests/test_alarm.gd",
	"res://tests/test_evac.gd",
	"res://tests/test_fire.gd",
	"res://tests/test_shelter.gd",
	"res://tests/test_profile.gd",
	"res://tests/test_bell.gd",
	"res://tests/test_rite.gd",
	"res://tests/test_engineers.gd",
	"res://tests/test_ferry.gd",
	"res://tests/test_quiet.gd",
	"res://tests/test_town_signals.gd",
	"res://tests/test_wisp.gd",
	"res://tests/test_thornwall.gd",
	"res://tests/test_discord.gd",
	"res://tests/test_plague.gd",
	"res://tests/test_solaris.gd",
	"res://tests/test_mirrorfold.gd",
	"res://tests/test_congregation.gd",
	"res://tests/test_madness.gd",
	"res://tests/test_voice.gd",
	"res://tests/test_schism.gd",
	"res://tests/test_dominion_tiers.gd",
	"res://tests/test_tier1.gd",
	"res://tests/test_decree.gd",
	"res://tests/test_corps.gd",
	"res://tests/test_marshals.gd",
	"res://tests/test_escorts.gd",
	"res://tests/test_rescue.gd",
	"res://tests/test_plague_look.gd",
	"res://tests/test_sort.gd",
	"res://tests/test_voices.gd",
	"res://tests/test_stability.gd",
	"res://tests/test_rules.gd",
	"res://tests/test_cast_lock.gd",
	"res://tests/test_score.gd",
	"res://tests/test_targeting.gd",
	"res://tests/test_tornado_lock.gd",
	"res://tests/test_hud.gd",
	"res://tests/test_fps_meter.gd",
	"res://tests/test_save_file.gd",
	"res://tests/test_flow.gd",
	"res://tests/test_draft.gd",
	"res://tests/test_menu.gd",
	"res://tests/test_results.gd",
	"res://tests/test_rebuild.gd",
	"res://tests/test_objectives.gd",
	"res://tests/test_mission_book.gd",
	"res://tests/test_whisper.gd",
	"res://tests/test_warning.gd",
	"res://tests/test_night.gd",
	"res://tests/test_raise.gd",
	"res://tests/test_events.gd",
	"res://tests/test_judgement.gd",
	"res://tests/test_festival.gd",
	"res://tests/test_procession.gd",
	"res://tests/test_campaign.gd",
	"res://tests/test_campaign_screens.gd",
	"res://tests/test_gaze.gd",
	"res://tests/test_temple_report.gd",
	"res://tests/test_vigil_route.gd",
	"res://tests/test_miras_house.gd",
	"res://tests/test_shrine.gd",
	"res://tests/test_lantern_knight.gd",
	"res://tests/test_broken_lanterns.gd",
	"res://tests/test_searchlight.gd",
	"res://tests/test_vigil_flame.gd",
	"res://tests/test_cael_lines.gd",
	"res://tests/test_map_tags.gd",
	"res://tests/test_board_tags.gd",
	"res://tests/test_mission_hints.gd",
	"res://tests/test_intro_tour.gd",
	"res://tests/test_tiers.gd",
	"res://tests/test_board_missions.gd",
	"res://tests/test_starfall.gd",
	"res://tests/test_descent.gd",
	"res://tests/test_wishes.gd",
	"res://tests/test_wish_kinds.gd",
	"res://tests/test_tier_board.gd",
	"res://tests/test_board_nights.gd",
	"res://tests/test_descend_hud.gd",
	"res://tests/test_descend_screens.gd",
	"res://tests/test_tier1_groundwork.gd",
	"res://tests/test_tax_collector.gd",
	"res://tests/test_spoiled_harvest.gd",
	"res://tests/test_lost_lamb.gd",
	"res://tests/test_first_prayers.gd",
	"res://tests/test_tier1_wishes.gd",
	"res://tests/test_tier1_board.gd",
	"res://tests/test_tier2_groundwork.gd",
]

var failures := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: ", msg)


func near(a: float, b: float, eps: float, msg: String) -> void:
	check(absf(a - b) <= eps, "%s (got %f expected %f)" % [msg, a, b])


func _initialize() -> void:
	for path in SUITES:
		var suite: GDScript = load(path)
		if suite == null or not suite.can_instantiate():
			check(false, "suite failed to load: %s" % path)
			continue
		var before := checks
		suite.run(self)
		if checks == before:
			check(false, "suite ran no checks (runtime error?): %s" % path)
	print("checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
