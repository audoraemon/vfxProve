class_name PowerBook
extends RefCounted
## The draftable powers: Might price, cooldown (seconds), how they are aimed, their effect script and icons, and
## their Authority (v0.08: the draft's tabs).
## Prices are the loadout budget (v0.08): a mission's draft may spend its Might capacity on them, and nothing
## is spent once the mission runs. Cooldowns follow spec §2's rule of thumb, the larger of the old cooldown and 3x
## the old DP cost. Aim "drag" = press at the start point, drag the direction, release; aim "whisper" (v0.08) = press
## on a person, drag to where they should go, release; aim "two clicks" = one click for each of the power's two places
## (Mirrorfold Passage, Divine Congregation). The quiet powers (v0.05, "quiet") register no danger for the
## town and raise no alarm when cast (Crowd.on_cast()): Silent Doom's deaths count only if someone saw them, Blight
## adds one alarm; a quiet power with an "alarm" unsettles the town by that much when cast. A power with "modes" is cast
## in one of them (Targeting: Q and E step through them; the effect is told which in extra["mode"]); a mode may aim
## its own way ("aim"), cover its own ground ("area") and wait its own cooldown ("cooldown", mode_cooldown()).

const POWERS := [
	{"key": "doom", "name": "Silent Doom", "path": "res://src/fx/quiet/silent_doom.gd",
		"blurb": "Everyone within reach is struck down, unseen.",
		"dp": 1, "cooldown": 10.0, "aim": "click", "shape": "everyone within reach struck down, unseen", "quiet": true,
		"authority": "veil"},
	{"key": "whisper", "name": "Mind Whisper", "path": "res://src/fx/dominion/mind_whisper.gd",
		"blurb": "Press a person: send them walking, at someone, or to burn a building.",
		"dp": 1, "cooldown": 8.0, "aim": "whisper",
		"shape": "press a person: walk, attack or burn -- send them somewhere (8 s), set them on someone, or at a building; not the same one again for 20 s", "quiet": true,
		"authority": "dominion",
		"levels": [
			{"REACH": 10.0, "ATTACK_SECS": 10.0, "cooldown": 8.0},
			{"REACH": 11.0, "ATTACK_SECS": 11.0, "cooldown": 7.5},
			{"REACH": 12.0, "ATTACK_SECS": 12.0, "cooldown": 7.0},
			{"REACH": 13.0, "ATTACK_SECS": 13.0, "cooldown": 6.5},
			{"REACH": 14.0, "ATTACK_SECS": 14.0, "cooldown": 6.0, "twist": true, "twist_text": "Held String: whisper the same one again"}]},
	{"key": "smite", "name": "Smite", "path": "res://src/fx/ruin/smite.gd",
		"blurb": "A bolt falls where you click. It kills all there and hurts a building.",
		"dp": 1, "cooldown": 10.0, "aim": "click", "shape": "one bolt: whoever stands there, and a blow to one building",
		"authority": "ruin",
		"levels": [
			{"KILL_R": 0.6, "DAMAGE": 45.0, "cooldown": 10.0},
			{"KILL_R": 0.65, "DAMAGE": 50.0, "cooldown": 9.5},
			{"KILL_R": 0.7, "DAMAGE": 55.0, "cooldown": 9.0},
			{"KILL_R": 0.75, "DAMAGE": 60.0, "cooldown": 8.5},
			{"KILL_R": 0.8, "DAMAGE": 65.0, "cooldown": 8.0, "twist": true, "twist_text": "Forked Bolt: leaps to one more nearby"}]},
	{"key": "ember", "name": "Ember", "path": "res://src/fx/ruin/ember.gd",
		"blurb": "One spark flies to a building and sets it alight.",
		"dp": 1, "cooldown": 15.0, "aim": "click", "shape": "one spark that sets one building alight", "quiet": true,
		"authority": "ruin",
		"levels": [
			{"START_LEVEL": 0.45, "REACH": 1.0, "cooldown": 15.0},
			{"START_LEVEL": 0.5, "REACH": 1.0, "cooldown": 14.0},
			{"START_LEVEL": 0.55, "REACH": 1.2, "cooldown": 13.0},
			{"START_LEVEL": 0.6, "REACH": 1.2, "cooldown": 12.0},
			{"START_LEVEL": 0.65, "REACH": 1.4, "cooldown": 11.0, "twist": true, "twist_text": "Leaping Spark: jumps to the next house"}]},
	{"key": "deathmark", "name": "Death Mark", "path": "res://src/fx/death/death_mark.gd",
		"blurb": "One person grows frail and slow, then dies. The body draws a crowd.",
		"dp": 1, "cooldown": 20.0, "aim": "click", "shape": "one grows frail and slow, dies in 10 s; the body draws a crowd",
		"quiet": true, "authority": "death"},
	{"key": "raise", "name": "Raise the Dead", "path": "res://src/fx/death/raise_the_dead.gd",
		"blurb": "A body rises to attack, or its soul to terrify and possess.",
		"dp": 1, "cooldown": 25.0, "aim": "click", "needs": "body",
		"shape": "click a body: ZOMBIE -- it gets up for 30 s and hunts the nearest, and whoever it kills gets up too, 3 in all; SPIRIT -- its soul rises for 20 s, everyone within 3 flees, and a press on someone within 4 of it possesses them for 5 s with Mind Whisper's orders, 3 in all",
		"authority": "death", "modes": [
			{"key": "zombie", "name": "ZOMBIE"},
			{"key": "spirit", "name": "SPIRIT", "needs": "soul"}]},
	{"key": "noleave", "name": "Leaving Is Prohibited", "path": "res://src/fx/decree/leaving_is_prohibited.gd",
		"blurb": "Nobody in the circle can leave it for a time.",
		"dp": 1, "cooldown": 20.0, "aim": "click", "shape": "nobody in the circle can leave it, 15 s",
		"quiet": true, "alarm": 0.5, "authority": "decree"},
	{"key": "skylift", "name": "Skylift", "path": "res://src/fx/control/skylift.gd",
		"blurb": "A beam lifts what stands at one spot and drops it at another.",
		"dp": 1, "cooldown": 20.0, "aim": "two clicks", "shape": "a beam takes whatever stands at the first click -- people, goods, a stall -- and drops it at the second: the goods land as a heap that crushes and bars the way",
		"quiet": true, "alarm": 0.5, "authority": "passage",
		"levels": [
			{"RADIUS": 2.5, "T_TAKE": 1.4, "cooldown": 20.0},
			{"RADIUS": 2.7, "T_TAKE": 1.3, "cooldown": 19.0},
			{"RADIUS": 2.9, "T_TAKE": 1.2, "cooldown": 18.0},
			{"RADIUS": 3.1, "T_TAKE": 1.1, "cooldown": 17.0},
			{"RADIUS": 3.3, "T_TAKE": 1.0, "cooldown": 16.0, "twist": true, "twist_text": "Stay Put: the landed stand rooted 10 s"}]},
	{"key": "windfall", "name": "Windfall", "path": "res://src/fx/control/windfall.gd",
		"blurb": "A load falls from the sky: stone bars, oil burns, goods, plague.",
		"dp": 1, "cooldown": 25.0, "aim": "drag", "shape": "a load dropped from the sky along the drag: crushes what is under it; STONE bars the way, OIL burns, GOODS draw looters, PLAGUE sickens who clears it; Q/E",
		"authority": "passage", "modes": [
			{"key": "stone", "name": "STONE"}, {"key": "oil", "name": "OIL"}, {"key": "goods", "name": "GOODS"}, {"key": "plague", "name": "PLAGUE"}],
		"levels": [
			{"LENGTH": 3.6, "SEGMENTS": 6, "CLEAR_WORK": 150.0, "cooldown": 25.0},
			{"LENGTH": 3.9, "SEGMENTS": 6, "CLEAR_WORK": 165.0, "cooldown": 24.0},
			{"LENGTH": 4.2, "SEGMENTS": 7, "CLEAR_WORK": 180.0, "cooldown": 23.0},
			{"LENGTH": 4.5, "SEGMENTS": 8, "CLEAR_WORK": 195.0, "cooldown": 22.0},
			{"LENGTH": 4.8, "SEGMENTS": 8, "CLEAR_WORK": 210.0, "cooldown": 21.0, "twist": true, "twist_text": "Heart of the Fall: a meteor and a boulder at the middle"}]},
	{"key": "hellspark", "name": "Hellmouth Spark", "path": "res://src/fx/control/hellmouth_spark.gd",
		"blurb": "A furnace door opens: those near it burn, houses catch fire.",
		"dp": 1, "cooldown": 20.0, "aim": "click", "shape": "a small door to the furnace opens on the ground for 6 s: whoever stands within 1.5 burns, every building in reach catches",
		"authority": "passage",
		"levels": [
			{"RADIUS": 1.5, "OPEN": 6.0, "cooldown": 20.0},
			{"RADIUS": 1.65, "OPEN": 6.5, "cooldown": 19.0},
			{"RADIUS": 1.8, "OPEN": 7.0, "cooldown": 18.0},
			{"RADIUS": 1.95, "OPEN": 7.5, "cooldown": 17.0},
			{"RADIUS": 2.1, "OPEN": 8.0, "cooldown": 16.0, "twist": true, "twist_text": "Wandering Mouth: click once to move the open mouth"}]},
	{"key": "wisp", "name": "Will-o'-Wisp", "path": "res://src/fx/control/will_o_wisp.gd",
		"blurb": "A pale light lures calm people to stand round it. ENTHRALL holds them.",
		"dp": 2, "cooldown": 30.0, "aim": "click", "shape": "lures up to 25 calm people, 12 s; or ENTHRALL holds all near the light, 30 s (cooldown 75 s); Q/E",
		"quiet": true, "authority": "dominion", "modes": [
			{"key": "lure", "name": "LURE"}, {"key": "enthrall", "name": "ENTHRALL", "area": {"r": 4.0, "roam": 0.0}, "cooldown": 75.0}],
		"levels": [
			{"LURE_MAX": 25, "WISP_TIME": 12.0, "ENTHRALL_TIME": 30.0, "cooldown": 30.0},
			{"LURE_MAX": 27, "WISP_TIME": 13.0, "ENTHRALL_TIME": 32.0, "cooldown": 28.0},
			{"LURE_MAX": 30, "WISP_TIME": 14.0, "ENTHRALL_TIME": 34.0, "cooldown": 26.0},
			{"LURE_MAX": 32, "WISP_TIME": 15.0, "ENTHRALL_TIME": 37.0, "cooldown": 25.0},
			{"LURE_MAX": 35, "WISP_TIME": 16.0, "ENTHRALL_TIME": 40.0, "cooldown": 24.0, "twist": true, "twist_text": "Procession: click again to lead the light"}]},
	{"key": "discord", "name": "Discord", "path": "res://src/fx/quiet/discord.gd",
		"blurb": "People in the circle forget their task and wander off.",
		"dp": 2, "cooldown": 30.0, "aim": "click", "shape": "people forget their task, 15 s", "quiet": true,
		"authority": "dominion",
		"levels": [
			{"DISCORD_R": 1.2, "DISCORD_TIME": 15.0, "cooldown": 30.0},
			{"DISCORD_R": 1.3, "DISCORD_TIME": 16.0, "cooldown": 28.0},
			{"DISCORD_R": 1.4, "DISCORD_TIME": 17.0, "cooldown": 26.0},
			{"DISCORD_R": 1.5, "DISCORD_TIME": 18.0, "cooldown": 24.0},
			{"DISCORD_R": 1.6, "DISCORD_TIME": 20.0, "cooldown": 22.0, "twist": true, "twist_text": "Tangled Threads: forgetting spreads one hop"}]},
	{"key": "belllies", "name": "The Bell Lies", "path": "res://src/fx/decree/the_bell_lies.gd",
		"blurb": "The bell tolls that all is well, or calls the guard to a place. Q and E pick.",
		"dp": 2, "cooldown": 60.0, "aim": "click", "shape": "the bell tolls all is well, now and for 45 s; or calls the guard to a place; Q/E",
		"quiet": true, "authority": "decree", "modes": [
			{"key": "well", "name": "ALL IS WELL"}, {"key": "guard", "name": "CALL THE GUARD", "area": {"r": 1.5}}]},
	{"key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd",
		"dp": 2, "cooldown": 30.0, "aim": "drag", "shape": "line + 8 fissures", "authority": "ruin"},
	{"key": "scatter", "name": "Scatter Strike", "path": "res://src/fx/ruin/scatter_strike.gd",
		"blurb": "Bursts of fire erupt at random from the ground over a wide circle.",
		"dp": 2, "cooldown": 30.0, "aim": "click", "shape": "twelve bursts from the ground, thrown at random over a wide circle, 4 s", "authority": "ruin",
		"levels": [
			{"BLASTS": 12, "KILL_R": 0.9, "cooldown": 30.0},
			{"BLASTS": 13, "KILL_R": 0.9, "cooldown": 29.0},
			{"BLASTS": 14, "KILL_R": 1.0, "cooldown": 28.0},
			{"BLASTS": 15, "KILL_R": 1.0, "cooldown": 27.0},
			{"BLASTS": 16, "KILL_R": 1.1, "cooldown": 25.0, "twist": true, "twist_text": "Seeking Bursts: each burst finds someone near"}]},
	{"key": "madness", "name": "Madness Bloom", "path": "res://src/fx/curse/madness_bloom.gd",
		"blurb": "A madness grows, spreads from mind to mind and breaks into frenzy.",
		"dp": 2, "cooldown": 40.0, "aim": "click", "shape": "a madness that grows, spreads and breaks into frenzy",
		"quiet": true, "alarm": 0.2, "authority": "dominion",
		"levels": [
			{"RADIUS": 1.5, "SEED": 0.02, "cooldown": 40.0},
			{"RADIUS": 1.65, "SEED": 0.04, "cooldown": 38.0},
			{"RADIUS": 1.8, "SEED": 0.06, "cooldown": 36.0},
			{"RADIUS": 1.95, "SEED": 0.08, "cooldown": 34.0},
			{"RADIUS": 2.1, "SEED": 0.1, "cooldown": 32.0, "twist": true, "twist_text": "Directed Frenzy: the broken hunt soldiers"}]},
	{"key": "blight", "name": "Blight", "path": "res://src/fx/quiet/blight.gd",
		"blurb": "Ruins a well, bell, gate, dock or rite.",
		"dp": 2, "cooldown": 36.0, "aim": "click", "shape": "ruins a well, bell, gate, dock or rite", "quiet": true,
		"authority": "veil"},
	{"key": "thorns", "name": "Thornwall", "path": "res://src/fx/control/thornwall.gd",
		"blurb": "A bramble wall rises and blocks the way for a while.",
		"dp": 2, "cooldown": 42.0, "aim": "drag", "shape": "3-unit bramble wall, 25 s", "quiet": true,
		"authority": "passage"},
	{"key": "pilgrim", "name": "Pilgrim Road", "path": "res://src/fx/control/pilgrim_road.gd",
		"dp": 2, "cooldown": 35.0, "aim": "drag", "shape": "the road itself travels: for 15 s whoever stands on the 6-long lane is carried along it at a run and thrown off its end, into whatever stands there",
		"authority": "passage"},
	{"key": "deep", "name": "Door to the Deep", "path": "res://src/fx/control/door_to_the_deep.gd",
		"blurb": "A black whirlpool slows all near it and drags them under.",
		"dp": 2, "cooldown": 40.0, "aim": "click", "shape": "a door opens in the ground and a whirlpool of black water turns over a circle of 4 for 25 s: everyone in it slows to a third and is drawn to the middle, where the door takes them; fires go out, buildings soak",
		"authority": "passage",
		"levels": [
			{"RADIUS": 4.0, "SPAN": 25.0, "PULL_CORE": 0.75, "cooldown": 40.0},
			{"RADIUS": 4.25, "SPAN": 26.0, "PULL_CORE": 0.8, "cooldown": 38.5},
			{"RADIUS": 4.5, "SPAN": 28.0, "PULL_CORE": 0.85, "cooldown": 37.0},
			{"RADIUS": 4.75, "SPAN": 30.0, "PULL_CORE": 0.9, "cooldown": 35.5},
			{"RADIUS": 5.0, "SPAN": 31.0, "PULL_CORE": 0.95, "cooldown": 34.0, "twist": true, "twist_text": "Standing Water: the flood stays 20 s and slows"}]},
	{"key": "houndgate", "name": "Hound Gate", "path": "res://src/fx/control/hound_gate.gd",
		"blurb": "A Hellgate opens and hellhounds run out to hunt the nearest.",
		"dp": 2, "cooldown": 40.0, "aim": "click", "shape": "a Hellgate rises and opens: four hellhounds run out and hunt whoever is nearest for 30 s; a lone soldier falls to one, two can bring one down",
		"authority": "passage",
		"levels": [
			{"HOUNDS": 4, "HUNT": 30.0, "BLOWS": 4, "cooldown": 40.0},
			{"HOUNDS": 4, "HUNT": 32.0, "BLOWS": 4, "cooldown": 38.5},
			{"HOUNDS": 5, "HUNT": 34.0, "BLOWS": 4, "cooldown": 37.0},
			{"HOUNDS": 6, "HUNT": 36.0, "BLOWS": 5, "cooldown": 35.5},
			{"HOUNDS": 6, "HUNT": 38.0, "BLOWS": 5, "cooldown": 34.0, "twist": true, "twist_text": "Quarry: click a person and every hound hunts them"}]},
	{"key": "gravecall", "name": "Gravecall", "path": "res://src/fx/death/gravecall.gd",
		"blurb": "Three spirits rise, and haunt where you send them.",
		"dp": 2, "cooldown": 30.0, "aim": "two clicks",
		"shape": "no body needed: the first click calls three pale spirits up out of the ground, the second sends them; they drift through walls and haunt a circle of 3 there for 20 s, and a soldier a spirit passes through is frozen for 3 s",
		"authority": "death"},
	{"key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd",
		"blurb": "A roaming vortex tears through the town and flings people about.",
		"dp": 3, "cooldown": 45.0, "aim": "click", "shape": "roaming vortex, 10 s", "authority": "ruin",
		"levels": [
			{"PULL_RADIUS": 3.2, "LIFETIME": 10.0, "cooldown": 45.0},
			{"PULL_RADIUS": 3.4, "LIFETIME": 11.0, "cooldown": 45.0},
			{"PULL_RADIUS": 3.6, "LIFETIME": 12.0, "cooldown": 42.0},
			{"PULL_RADIUS": 3.8, "LIFETIME": 13.0, "cooldown": 40.0},
			{"PULL_RADIUS": 4.0, "LIFETIME": 14.0, "cooldown": 38.0, "twist": true, "twist_text": "Twin Funnels: splits in two as it dies"}]},
	{"key": "pestilence", "name": "Pestilence", "path": "res://src/fx/curse/pestilence.gd",
		"blurb": "A fast plague spreads through the crowds.",
		"dp": 3, "cooldown": 48.0, "aim": "click", "shape": "a fast plague spreading through crowds", "quiet": true,
		"authority": "death"},
	{"key": "guise", "name": "Corpse Guise", "path": "res://src/fx/death/corpse_guise.gd",
		"blurb": "The faithful pass as the walking dead; the watch looks past them.",
		"dp": 3, "cooldown": 50.0, "aim": "click",
		"shape": "the 4 nearest within 2 pass as the walking dead for 25 s: soldiers, watchmen and inquisitors look straight past them, and Death's own undead leave them alone",
		"quiet": true, "authority": "death"},
	{"key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd",
		"blurb": "A dragon breathes a cone of fire and burns all before it.",
		"dp": 3, "cooldown": 54.0, "aim": "click", "shape": "cone, faces down-right on screen", "authority": "ruin",
		"levels": [
			{"BREATH_TIME": 2.4, "SWEEP_ARC": 1.0, "cooldown": 54.0},
			{"BREATH_TIME": 2.6, "SWEEP_ARC": 1.0, "cooldown": 52.0},
			{"BREATH_TIME": 2.8, "SWEEP_ARC": 1.1, "cooldown": 50.0},
			{"BREATH_TIME": 3.0, "SWEEP_ARC": 1.2, "cooldown": 48.0},
			{"BREATH_TIME": 3.2, "SWEEP_ARC": 1.3, "cooldown": 46.0, "twist": true, "twist_text": "Second Breath: breathes again, back the other way"}]},
	{"key": "mirror", "name": "Mirrorfold Passage", "path": "res://src/fx/control/mirrorfold_passage.gd",
		"blurb": "A way in along the drag; whoever crosses it comes out at the click.",
		"dp": 3, "cooldown": 54.0, "aim": "drag then click", "shape": "a way in laid along the drag, a street wide, 2 to 6 long; a way out at the click: whoever and whatever crosses comes out there, 30 s",
		"quiet": true, "authority": "passage",
		"levels": [
			{"MAX_LEN": 6.0, "MIRROR_TIME": 30.0, "cooldown": 54.0},
			{"MAX_LEN": 6.5, "MIRROR_TIME": 32.0, "cooldown": 52.0},
			{"MAX_LEN": 7.0, "MIRROR_TIME": 35.0, "cooldown": 50.0},
			{"MAX_LEN": 7.5, "MIRROR_TIME": 38.0, "cooldown": 48.0},
			{"MAX_LEN": 8.0, "MIRROR_TIME": 40.0, "cooldown": 46.0, "twist": true, "twist_text": "Mirror Twins: glass twins the town attacks; shards cut"}]},
	{"key": "magnify", "name": "Magnify", "path": "res://src/fx/decree/magnify.gd",
		"dp": 3, "cooldown": 75.0, "aim": "click", "shape": "doubles what is already there: fires, cracks, madness, spells",
		"quiet": true, "alarm": 1.0, "authority": "decree"},
	{"key": "unseen", "name": "Unseen Hour", "path": "res://src/fx/quiet/unseen_hour.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "for 20 s nothing in the circle is seen: no alarm, no fright, nobody comes",
		"quiet": true, "authority": "veil"},
	{"key": "congregation", "name": "Divine Congregation", "path": "res://src/fx/dominion/divine_congregation.gd",
		"dp": 4, "cooldown": 60.0, "aim": "two clicks", "shape": "a district walks to the place of the first click, 25 s",
		"quiet": true, "alarm": 0.3, "authority": "dominion"},
	{"key": "oath", "name": "Oathbound", "path": "res://src/fx/dominion/oathbound.gd",
		"dp": 2, "cooldown": 45.0, "aim": "click", "shape": "binds up to four to stay, or to hold a place, 60 s; Q/E",
		"quiet": true, "authority": "dominion", "modes": [
			{"key": "remain", "name": "REMAIN"},
			{"key": "hold", "name": "HOLD A PLACE", "aim": "two clicks", "area": {"shape": "pick"}}]},
	{"key": "echo", "name": "Command Echo", "path": "res://src/fx/dominion/command_echo.gd",
		"dp": 2, "cooldown": 45.0, "aim": "click", "shape": "a command planted in a few that passes from one to the next; Q/E",
		"quiet": true, "alarm": 0.2, "authority": "dominion", "modes": [
			{"key": "home", "name": "GO HOME"},
			{"key": "go", "name": "GO THERE", "aim": "two clicks", "area": {"shape": "pick"}}]},
	{"key": "turncoat", "name": "Turncoat", "path": "res://src/fx/dominion/turncoat.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "one turns on its own side: a soldier fights, another sabotages, 30 s",
		"quiet": true, "authority": "dominion"},
	{"key": "hatred", "name": "Manufactured Hatred", "path": "res://src/fx/dominion/manufactured_hatred.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "a group comes to hate one kind, and goes for them; Q/E picks whom",
		"quiet": true, "alarm": 0.5, "authority": "dominion", "modes": [
			{"key": "soldier", "name": "THE GUARD"}, {"key": "clergy", "name": "THE CLERGY"},
			{"key": "engineer", "name": "THE ENGINEERS"}]},
	{"key": "clearmind", "name": "Clear Mind", "path": "res://src/fx/dominion/clear_mind.gd",
		"blurb": "Everyone in the circle senses nothing unusual. Whoever walks in joins them.",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "everyone in the circle senses nothing special, 30 s; whoever walks in joins",
		"quiet": true, "alarm": 0.3, "authority": "dominion",
		"levels": [
			{"RADIUS": 5.0, "TRANCE_TIME": 30.0, "cooldown": 60.0},
			{"RADIUS": 5.4, "TRANCE_TIME": 32.0, "cooldown": 57.0},
			{"RADIUS": 5.8, "TRANCE_TIME": 34.0, "cooldown": 54.0},
			{"RADIUS": 6.2, "TRANCE_TIME": 37.0, "cooldown": 51.0},
			{"RADIUS": 6.5, "TRANCE_TIME": 40.0, "cooldown": 48.0, "twist": true, "twist_text": "Sleepwalk: click again to walk the entranced"}]},
	{"key": "saint", "name": "Saint or Sinner", "path": "res://src/fx/dominion/saint_or_sinner.gd",
		"blurb": "One is chosen. Everyone round them guards them at all cost, or kills them.",
		"dp": 3, "cooldown": 60.0, "aim": "wheel", "shape": "one is chosen; everyone round them guards them at all cost, or kills them: the wheel picks",
		"quiet": true, "alarm": 0.5, "authority": "dominion", "modes": [
			{"key": "saint", "name": "SAINT", "glyph": [0b01110, 0b10001, 0b01110, 0b00100, 0b01110], "color": Color(1.0, 0.9, 0.6, 0.9)},
			{"key": "sinner", "name": "SINNER", "glyph": [0b01110, 0b10001, 0b01110, 0b00100, 0b00100], "color": Color(1.0, 0.3, 0.25, 0.9)}],
		"levels": [
			{"RADIUS": 6.0, "SPAN": 30.0, "cooldown": 60.0},
			{"RADIUS": 6.4, "SPAN": 32.0, "cooldown": 57.0},
			{"RADIUS": 6.8, "SPAN": 34.0, "cooldown": 54.0},
			{"RADIUS": 7.2, "SPAN": 37.0, "cooldown": 51.0},
			{"RADIUS": 7.5, "SPAN": 40.0, "cooldown": 48.0, "twist": true, "twist_text": "Passed Mark: the mark outlives its bearer"}]},
	{"key": "priority", "name": "Rewrite Priority", "path": "res://src/fx/dominion/rewrite_priority.gd",
		"dp": 4, "cooldown": 75.0, "aim": "click", "shape": "a district puts one thing above all else, 25 s; Q/E picks it",
		"quiet": true, "alarm": 1.0, "authority": "dominion", "modes": [
			{"key": "work", "name": "WORK"}, {"key": "worship", "name": "WORSHIP"}, {"key": "hide", "name": "HIDE"},
			{"key": "escape", "name": "ESCAPE"}, {"key": "ignore", "name": "IGNORE"}]},
	{"key": "verdict", "name": "Mob Verdict", "path": "res://src/fx/dominion/mob_verdict.gd",
		"dp": 4, "cooldown": 90.0, "aim": "two clicks", "shape": "a district judges the one, or the building, of the first click",
		"quiet": true, "alarm": 2.0, "authority": "dominion"},
	{"key": "delusion", "name": "Collective Delusion", "path": "res://src/fx/dominion/collective_delusion.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "a district believes a danger that is not there, or that all is well",
		"quiet": true, "authority": "dominion", "modes": [
			{"key": "danger", "name": "FALSE DANGER"}, {"key": "calm", "name": "ALL IS WELL", "area": {"r": 7.0}}]},
	{"key": "anathema", "name": "Anathema", "path": "res://src/fx/dominion/anathema.gd",
		"blurb": "A district is cursed so nobody stays, or hallowed so everyone does.",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "a district's buildings are cursed (nobody inside, fires left) or hallowed (everyone inside, and stays), 40 s; Q/E",
		"quiet": true, "alarm": 1.0, "authority": "dominion", "modes": [
			{"key": "cursed", "name": "CURSED"}, {"key": "hallowed", "name": "HALLOWED"}],
		"levels": [
			{"RADIUS": 6.0, "SPAN": 40.0, "cooldown": 90.0},
			{"RADIUS": 6.4, "SPAN": 44.0, "cooldown": 86.0},
			{"RADIUS": 6.8, "SPAN": 48.0, "cooldown": 82.0},
			{"RADIUS": 7.2, "SPAN": 52.0, "cooldown": 78.0},
			{"RADIUS": 7.5, "SPAN": 55.0, "cooldown": 74.0, "twist": true, "twist_text": "Spreading Mark: spreads to buildings near"}]},
	{"key": "sanctuary", "name": "Sacred Sanctuary", "path": "res://src/fx/dominion/sacred_sanctuary.gd",
		"blurb": "People at the first click wall off the second and set on who enters.",
		"dp": 4, "cooldown": 90.0, "aim": "two clicks", "shape": "the people at the first click wall the place at the second and set on whoever enters, 40 s; right-click: shape",
		"quiet": true, "alarm": 1.0, "authority": "dominion", "alt_steps_mode": true, "modes": [
			{"key": "circle", "name": "CIRCLE"}, {"key": "rect", "name": "RECTANGLE"}],
		"levels": [
			{"MAX_GUARDS": 40, "SPAN": 40.0, "PICK_R": 5.0, "cooldown": 90.0},
			{"MAX_GUARDS": 44, "SPAN": 44.0, "PICK_R": 5.25, "cooldown": 86.0},
			{"MAX_GUARDS": 48, "SPAN": 48.0, "PICK_R": 5.5, "cooldown": 82.0},
			{"MAX_GUARDS": 52, "SPAN": 52.0, "PICK_R": 5.75, "cooldown": 78.0},
			{"MAX_GUARDS": 55, "SPAN": 55.0, "PICK_R": 6.0, "cooldown": 74.0, "twist": true, "twist_text": "Pressed into Service: intruders guard"}]},
	{"key": "curfew", "name": "Curfew", "path": "res://src/fx/decree/curfew.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "everyone in the circle sleeps where they stand, 30 s; a loud blow or a hurt wakes them",
		"quiet": true, "alarm": 1.0, "authority": "decree"},
	{"key": "allroads", "name": "All Roads Lead Here", "path": "res://src/fx/control/all_roads_lead_here.gd",
		"blurb": "Every road in a district leads the people to one spot.",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "for 25 s every road in a district of 10 ends at the click: up to 80 people keep their own minds, but every way they take brings them here",
		"quiet": true, "alarm": 1.0, "authority": "passage",
		"levels": [
			{"RADIUS": 10.0, "MAX_PEOPLE": 80, "SPAN": 25.0, "cooldown": 90.0},
			{"RADIUS": 10.5, "MAX_PEOPLE": 88, "SPAN": 27.0, "cooldown": 87.0},
			{"RADIUS": 11.0, "MAX_PEOPLE": 95, "SPAN": 29.0, "cooldown": 84.0},
			{"RADIUS": 11.5, "MAX_PEOPLE": 102, "SPAN": 31.0, "cooldown": 81.0},
			{"RADIUS": 12.0, "MAX_PEOPLE": 110, "SPAN": 33.0, "cooldown": 78.0, "twist": true, "twist_text": "The Last Mile: a door of stars takes the gathered"}]},
	{"key": "yesterday", "name": "Yesterday's Door", "path": "res://src/fx/control/yesterdays_door.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "a district of 6 steps back 10 s: everyone in it is where they stood, doing what they did, 10 seconds ago; the dead stay dead",
		"quiet": true, "alarm": 1.0, "authority": "passage"},
	{"key": "foldward", "name": "The Folded Ward", "path": "res://src/fx/control/the_folded_ward.gd",
		"blurb": "A square folds shut: nobody gets out, or nobody gets in.",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "a square of 6 folded so its edges meet, 25 s: NO WAY OUT, whoever walks out walks back in at the far side; NO WAY IN, whoever walks in walks out at the far side; Q/E",
		"quiet": true, "alarm": 1.0, "authority": "passage", "modes": [
			{"key": "out", "name": "NO WAY OUT"}, {"key": "in", "name": "NO WAY IN"}],
		"levels": [
			{"HALF": 3.0, "SPAN": 25.0, "cooldown": 90.0},
			{"HALF": 3.25, "SPAN": 27.0, "cooldown": 87.0},
			{"HALF": 3.5, "SPAN": 29.0, "cooldown": 84.0},
			{"HALF": 3.75, "SPAN": 31.0, "cooldown": 81.0},
			{"HALF": 4.0, "SPAN": 33.0, "cooldown": 78.0, "twist": true, "twist_text": "Pocket Square: click to carry the square away"}]},
	{"key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd",
		"blurb": "A wall of water rolls across the town and sweeps away all in its path.",
		"dp": 4, "cooldown": 60.0, "aim": "drag", "shape": "moving wall", "authority": "ruin",
		"levels": [
			{"LENGTH": 6.5, "WIDTH": 8.0, "cooldown": 60.0},
			{"LENGTH": 7.0, "WIDTH": 8.5, "cooldown": 58.0},
			{"LENGTH": 7.5, "WIDTH": 9.0, "cooldown": 55.0},
			{"LENGTH": 8.0, "WIDTH": 10.0, "cooldown": 53.0},
			{"LENGTH": 8.5, "WIDTH": 11.0, "cooldown": 50.0, "twist": true, "twist_text": "Backwash: drags the living back"}]},
	{"key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd",
		"dp": 3, "cooldown": 60.0, "aim": "click", "shape": "pull field", "authority": "ruin"},
	{"key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd",
		"dp": 3, "cooldown": 66.0, "aim": "drag", "shape": "moving lane", "authority": "ruin"},
	{"key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd",
		"dp": 3, "cooldown": 66.0, "aim": "click", "shape": "random bombardment", "authority": "ruin"},
	{"key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd",
		"blurb": "A volcano rises and rains burning stone on the town.",
		"dp": 4, "cooldown": 75.0, "aim": "click", "shape": "volcano + stone rain", "authority": "ruin",
		"levels": [
			{"STONES": 20, "RADIUS": 5.8, "cooldown": 75.0},
			{"STONES": 22, "RADIUS": 5.8, "cooldown": 72.0},
			{"STONES": 24, "RADIUS": 6.2, "cooldown": 70.0},
			{"STONES": 26, "RADIUS": 6.6, "cooldown": 66.0},
			{"STONES": 28, "RADIUS": 7.0, "cooldown": 62.0, "twist": true, "twist_text": "Lava Pool: a burning pool stays 15 s"}]},
	{"key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "8 punches + slam", "authority": "ruin"},
	{"key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd",
		"dp": 4, "cooldown": 90.0, "aim": "click", "shape": "burst + freeze + ice", "authority": "ruin"},
	{"key": "solaris", "name": "Light of Solaris", "path": "res://src/fx/solaris/light_of_solaris.gd",
		"blurb": "A pillar of sunfire burns the spot, then leaves a pit that takes all.",
		"dp": 4, "cooldown": 105.0, "aim": "click", "shape": "5 s pillar of sunfire; leaves a pit that takes all who enter",
		"authority": "ruin",
		"levels": [
			{"RADIUS": 2.2, "BEAM_TIME": 5.0, "cooldown": 105.0},
			{"RADIUS": 2.4, "BEAM_TIME": 5.0, "cooldown": 100.0},
			{"RADIUS": 2.6, "BEAM_TIME": 5.5, "cooldown": 100.0},
			{"RADIUS": 2.8, "BEAM_TIME": 6.0, "cooldown": 95.0},
			{"RADIUS": 3.0, "BEAM_TIME": 6.5, "cooldown": 90.0, "twist": true, "twist_text": "Wandering Sun: drifts toward the crowd"}]},
	{"key": "voice", "name": "Voice of God", "path": "res://src/fx/dominion/voice_of_god.gd",
		"blurb": "One command the whole town obeys. Q and E pick the command.",
		"dp": 5, "cooldown": 180.0, "aim": "click", "shape": "one command the whole town obeys; Q/E picks it",
		"quiet": true, "alarm": 6.0, "authority": "dominion", "modes": [
			{"key": "kneel", "name": "KNEEL"}, {"key": "halt", "name": "HALT"}, {"key": "flee", "name": "FLEE"},
			{"key": "gather", "name": "GATHER"}, {"key": "return", "name": "RETURN"}, {"key": "silence", "name": "SILENCE"},
			{"key": "judge", "name": "JUDGE"}],
		"levels": [
			{"COMMAND_X": 1.0, "GATHER_CAPACITY": 150, "cooldown": 180.0},
			{"COMMAND_X": 1.1, "GATHER_CAPACITY": 160, "cooldown": 170.0},
			{"COMMAND_X": 1.2, "GATHER_CAPACITY": 175, "cooldown": 160.0},
			{"COMMAND_X": 1.3, "GATHER_CAPACITY": 185, "cooldown": 150.0},
			{"COMMAND_X": 1.4, "GATHER_CAPACITY": 200, "cooldown": 140.0, "twist": true, "twist_text": "Second Word: click again for a second command"}]},
	{"key": "abolition", "name": "Abolition", "path": "res://src/fx/decree/abolition.gd",
		"blurb": "One law is void for 15 s: the clock, the escape limit or the ward. Once only.",
		"dp": 5, "cooldown": 999.0, "aim": "click", "shape": "one law is void for 15 s: the clock (time stops), the escape limit, the ward; Q/E; once",
		"quiet": true, "alarm": 4.0, "authority": "decree", "modes": [
			{"key": "clock", "name": "THE CLOCK"}, {"key": "escape", "name": "THE ESCAPE LIMIT"},
			{"key": "ward", "name": "THE CITADEL'S WARD"}]},
	{"key": "tempest", "name": "Wrath of the Sky", "path": "res://src/fx/ruin/tempest.gd",
		"blurb": "A storm covers the town; bolts fall, rain drives people in. Once only.",
		"dp": 5, "cooldown": 999.0, "aim": "click", "shape": "a storm over the whole town: 25 s of bolts, the rain drives people in; once",
		"authority": "ruin",
		"levels": [
			{"STORM_TIME": 25.0, "VOLLEY": Vector2i(5, 7), "VOLLEY_EVERY": 1.3},
			{"STORM_TIME": 27.0, "VOLLEY": Vector2i(5, 7), "VOLLEY_EVERY": 1.3},
			{"STORM_TIME": 29.0, "VOLLEY": Vector2i(6, 8), "VOLLEY_EVERY": 1.3},
			{"STORM_TIME": 31.0, "VOLLEY": Vector2i(6, 8), "VOLLEY_EVERY": 1.2},
			{"STORM_TIME": 33.0, "VOLLEY": Vector2i(7, 9), "VOLLEY_EVERY": 1.2, "twist": true, "twist_text": "Called Bolts: click to call a bolt every 3 s"}]},
	{"key": "shatter", "name": "Earthshatter", "path": "res://src/fx/ruin/earthshatter.gd",
		"blurb": "The ground tears open from click to click, and stays so. Once only.",
		"dp": 5, "cooldown": 999.0, "aim": "two clicks", "shape": "the ground torn open from one click to the next, slowly; the crack stays; once",
		"authority": "ruin",
		"levels": [
			{"MAX_LENGTH": 18.0, "HALF": 1.1, "SPEED": 2.0},
			{"MAX_LENGTH": 20.0, "HALF": 1.2, "SPEED": 2.0},
			{"MAX_LENGTH": 22.0, "HALF": 1.2, "SPEED": 2.2},
			{"MAX_LENGTH": 24.0, "HALF": 1.3, "SPEED": 2.2},
			{"MAX_LENGTH": 26.0, "HALF": 1.4, "SPEED": 2.5, "twist": true, "twist_text": "Fault Lines: forks twice as it runs"}]},
	{"key": "everydoor", "name": "Every Door", "path": "res://src/fx/control/every_door.gd",
		"dp": 5, "cooldown": 999.0, "aim": "click", "shape": "every door in town for 20 s: SHUT, nobody goes in or out of a building or the town; OPEN, everyone inside is thrown into the street and no building takes anyone; Q/E; once",
		"quiet": true, "alarm": 1.0, "authority": "passage", "modes": [
			{"key": "shut", "name": "SHUT"}, {"key": "open", "name": "OPEN"}]},
	{"key": "schism", "name": "Divine Schism", "path": "res://src/fx/dominion/divine_schism.gd",
		"blurb": "Two sides form, each sure the other is the enemy. Once a descent.",
		"dp": 6, "cooldown": 999.0, "aim": "click", "shape": "two sides, each sure the other is the enemy; once a descent",
		"authority": "dominion", "modes": [
			{"key": "faction", "name": "FACTION SPLIT"}, {"key": "purge", "name": "PURGE", "area": {"r": 1.5}},
			{"key": "custom", "name": "CUSTOM", "aim": "two clicks", "area": {"shape": "regions", "r": 5.0}},
			{"key": "spreading", "name": "SPREADING", "area": {"r": 3.0}},
			{"key": "tumult", "name": "TUMULT"}],
		"levels": [
			{"REGION": 14.0, "MAX_FIGHTERS": 140, "DURATION": 25.0},
			{"REGION": 15.0, "MAX_FIGHTERS": 150, "DURATION": 27.0},
			{"REGION": 16.0, "MAX_FIGHTERS": 160, "DURATION": 29.0},
			{"REGION": 17.0, "MAX_FIGHTERS": 170, "DURATION": 32.0},
			{"REGION": 18.0, "MAX_FIGHTERS": 180, "DURATION": 35.0, "twist": true, "twist_text": "Turn the Tide: click a fighter to turn them"}]},
	{"key": "fargate", "name": "The Far Gate", "path": "res://src/fx/control/the_far_gate.gd",
		"dp": 6, "cooldown": 999.0, "aim": "click", "shape": "a door of stars opens for 15 s: up to 40 people within 10 walk through it with their dogs and goods, gone for the night; soldiers resist; once a descent",
		"quiet": true, "alarm": 1.0, "authority": "passage"},
	{"key": "heavendoor", "name": "Heaven's Door", "path": "res://src/fx/control/heavens_door.gd",
		"blurb": "A great door falls from heaven and draws all before it in.",
		"dp": 6, "cooldown": 999.0, "aim": "drag", "shape": "a great door falls from heaven: it crushes where it lands, then opens and for 12 s draws in everyone and everything in the half circle of 16 before it; buildings there are torn apart; drag to face it; once a descent",
		"authority": "passage",
		"levels": [
			{"PULL_R": 16.0, "SPAN": 12.0, "PULL_FAR": 0.6, "LAND_DAMAGE": 40.0},
			{"PULL_R": 17.0, "SPAN": 13.0, "PULL_FAR": 0.68, "LAND_DAMAGE": 45.0},
			{"PULL_R": 18.0, "SPAN": 14.0, "PULL_FAR": 0.75, "LAND_DAMAGE": 50.0},
			{"PULL_R": 19.0, "SPAN": 15.0, "PULL_FAR": 0.82, "LAND_DAMAGE": 55.0},
			{"PULL_R": 20.0, "SPAN": 16.0, "PULL_FAR": 0.9, "LAND_DAMAGE": 60.0, "twist": true, "twist_text": "Twin Doors: two doors back to back, the whole circle"}]},
	{"key": "deaddoors", "name": "Doors of the Dead", "path": "res://src/fx/control/doors_of_the_dead.gd",
		"blurb": "Every door opens onto hell; the dead pour out. Once a descent.",
		"dp": 6, "cooldown": 999.0, "aim": "click", "shape": "every door in a district of 12 opens onto the other side: the air turns cold and everyone in it slows, the houses throw out whoever sheltered there, and for 45 s hellhounds, ghosts and demons pour out without end to hunt the town and claw it down; once a descent",
		"authority": "passage",
		"levels": [
			{"RADIUS": 12.0, "MAX_DOORS": 18, "SPAN": 45.0, "MAX_SPIRITS": 160},
			{"RADIUS": 12.5, "MAX_DOORS": 20, "SPAN": 49.0, "MAX_SPIRITS": 175},
			{"RADIUS": 13.0, "MAX_DOORS": 21, "SPAN": 52.0, "MAX_SPIRITS": 190},
			{"RADIUS": 13.5, "MAX_DOORS": 22, "SPAN": 56.0, "MAX_SPIRITS": 205},
			{"RADIUS": 14.0, "MAX_DOORS": 24, "SPAN": 60.0, "MAX_SPIRITS": 220, "twist": true, "twist_text": "Rise Again: the horde's dead rise as ghosts"}]},
	{"key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd",
		"dp": 4, "cooldown": 120.0, "aim": "click", "shape": "huge circle", "authority": "ruin"},
]
const ICON_DIR := "res://assets/pixellab/icons/"
## Preview clips for the draft: each power recorded once from the sandbox (bash tools/capture.sh --capture-clip)
## into one sprite sheet -- CLIP_FRAMES frames spread over the whole effect, CLIP_COLUMNS to a row.
const CLIP_DIR := "res://assets/clips/"
const CLIP_FRAMES := 16
const CLIP_COLUMNS := 4
const CLIP_SIZE := Vector2i(152, 86)
## How fast the draft plays a clip: 16 frames at 8 a second is a two-second time-lapse of the whole power.
const CLIP_FPS := 8.0


## How far each power is seen and heard, how severe it is and how long it stays dangerous (v0.04 local awareness):
## [sight, sound, severity, seconds]. People inside its area plus Person.THREAT_MARGIN run clear of it; within sight
## or earshot they stop and look; beyond that they go on with their day.
const REACH := {
	"heaven": [6.0, 9.0, 0.5, 3.0], "tornado": [8.0, 11.0, 0.6, 10.0], "dragon": [8.0, 11.0, 0.6, 5.0],
	"tsunami": [8.0, 12.0, 0.7, 5.0], "gravity": [6.0, 9.0, 0.6, 6.0], "laser": [7.0, 10.0, 0.6, 6.0],
	"orbital": [9.0, 14.0, 0.7, 6.0], "cinder": [10.0, 16.0, 0.8, 8.0], "judgement": [9.0, 14.0, 0.8, 6.0],
	"glacial": [8.0, 12.0, 0.7, 6.0], "solaris": [12.0, 16.0, 0.9, 6.5], "smite": [5.0, 9.0, 0.4, 2.0], "schism": [14.0, 18.0, 0.8, 8.0],
	"nova": [40.0, 40.0, 1.0, 4.0],
	"scatter": [7.0, 10.0, 0.6, 5.0],
	"windfall": [5.0, 8.0, 0.5, 3.0],
	"hellspark": [5.0, 8.0, 0.6, 6.0],
	"pilgrim": [6.0, 9.0, 0.4, 15.0],
	"deep": [5.0, 8.0, 0.4, 4.0],
	"houndgate": [6.0, 9.0, 0.6, 30.0],
	# Raise the Dead: the dead getting up in the street is seen and heard as a hound gate's hounds are; the danger lasts the
	# zombies' 30 s (a spirit's is its own fright)
	"raise": [6.0, 9.0, 0.6, 30.0],
	# Gravecall: three pale spirits rising and drifting through the street are seen and heard like a spirit's wail; the danger lasts the haunt
	"gravecall": [5.0, 8.0, 0.5, 20.0],
	# Heaven's Door: a door taller than a house falling out of a shaft of light is seen and heard across the town, as the
	# Light of Solaris is; the danger lasts its opening and its pull
	"heavendoor": [16.0, 22.0, 0.9, 16.0],
	# Doors of the Dead: a district's doors burning cold and the other side pouring out of them is seen and heard far
	# off; the danger lasts the span
	"deaddoors": [16.0, 20.0, 1.0, 50.0],
	"shatter": [8.0, 12.0, 0.8, 6.0],
	# Tempest: seen by the whole town as it gathers; the cast's own danger is small (the bolts frighten, one by one)
	"tempest": [40.0, 40.0, 0.3, 2.0],
}
## When each loud power first kills (v0.11.2, spec §3.2): seconds after the cast, read from its effect script's own constants
## (tests/test_awareness.gd checks each). A loud power's danger counts from here (Crowd.on_cast()); the town looks at the
## build-up until then. Quiet powers (Ember too) register no danger and have none.
const IMPACT := {
	"smite": 0.35, "heaven": 1.4, "tornado": 1.0, "dragon": 1.2, "tsunami": 1.9, "gravity": 0.8, "laser": 2.0,
	"orbital": 1.45, "cinder": 1.2, "judgement": 2.0, "glacial": 1.2, "solaris": 1.2, "schism": 1.8, "nova": 2.3, "tempest": 5.0, "scatter": 0.9, "shatter": 1.2, "windfall": 0.8,
	"hellspark": 0.6, "pilgrim": 0.8, "deep": 0.8, "houndgate": 3.0, "heavendoor": 1.2, "deaddoors": 2.6,
	"raise": 0.8, "gravecall": 0.8,
}
## For a cast with no known power (the sandbox, scripted tests): v0.03's single 7-unit fright, heard to 10.
const REACH_DEFAULT := [7.0, 10.0, 0.6, 4.0]


## Seconds from a loud power's cast to its first impact (IMPACT), 0.0 for any other key.
static func impact(key: String) -> float:
	return float(IMPACT.get(key, 0.0))


static func get_power(key: String) -> Dictionary:
	for p: Dictionary in POWERS:
		if p.key == key:
			return p
	return {}


## The highest ability level (god P1, spec §5.4): levels run 1 to MAX_LEVEL.
const MAX_LEVEL := 5
## The levels at which a power costs one more Might (spec §6): reaching 3 adds 1, reaching 5 adds 1.
const MIGHT_STEPS := [3, 5]
## What level_change() says for a power whose row has no `levels` table yet (Ruin's and Dominion's powers have one; the other rows do not yet).
const NO_LEVELS := "Levels to come"
## The keys a level table holds besides stats: level 5's twist flag and its one-line text.
const TWIST_KEYS := ["twist", "twist_text"]


## What a power costs in Might at a level (spec §6): its `dp` plus one for each MIGHT_STEPS entry the level has reached.
## The level is clamped to 1-MAX_LEVEL; 0 for an unknown key. (The "dp" field keeps its name, ruling C1.)
static func might(key: String, level := 1) -> int:
	var p := get_power(key)
	if p.is_empty():
		return 0
	var lv := clampi(level, 1, MAX_LEVEL)
	var total := int(p.get("dp", 0))
	for step: int in MIGHT_STEPS:
		if step <= lv:
			total += 1
	return total


## True when the power's row has a `levels` table (an Array of MAX_LEVEL Dictionaries, index 0 = level 1, each mapping a stat name
## to the number its effect reads; index 4 also holds "twist": true and "twist_text").
static func has_levels(key: String) -> bool:
	return not _table(get_power(key)).is_empty()


## A row's levels table, or an empty Array when it has none.
static func _table(entry: Dictionary) -> Array:
	var t: Variant = entry.get("levels")
	return t as Array if t is Array else []


## The entry's value for `stat` at `level` (clamped 1-MAX_LEVEL) when it has a table naming that stat, else `base`.
static func stat_in(entry: Dictionary, level: int, stat: String, base: Variant) -> Variant:
	var table := _table(entry)
	if table.is_empty():
		return base
	var row: Variant = table[clampi(level, 1, table.size()) - 1]
	if row is Dictionary and (row as Dictionary).has(stat):
		return (row as Dictionary)[stat]
	return base


## A power's number for `stat` at `level`: its table's value, or `base` (the effect's own constant) without one.
static func level_stat(key: String, level: int, stat: String, base: Variant) -> Variant:
	return stat_in(get_power(key), level, stat, base)


## What an effect calls for each number its level may change: `PowerBook.stat(extra, "<key>", "<stat>", CONST)`. The level is
## extra["level"] (Rules.cast() puts it on every cast), 1 when absent. A power with no table plays exactly as it always did.
static func stat(extra: Dictionary, key: String, stat_name: String, base: Variant) -> Variant:
	return level_stat(key, int(extra.get("level", 1)), stat_name, base)


## The cooldown a power's mode carries (Will-o'-Wisp's ENTHRALL), or -1.0 when the mode has none (or the power no such mode): the cast
## then takes the power's own, at its level.
static func mode_cooldown(key: String, mode_key: String) -> float:
	for m: Dictionary in get_power(key).get("modes", []):
		if String(m.get("key", "")) == mode_key and m.has("cooldown"):
			return float(m.cooldown)
	return -1.0


## A power's cooldown in seconds at `level`: the "cooldown" its table gives that level, else the row's own; 0.0 for an unknown key.
## (Tempest and Earthshatter have no cooldown stat: they stay at the row's 999, once.)
static func cooldown(key: String, level := 1) -> float:
	var p := get_power(key)
	if p.is_empty():
		return 0.0
	return float(stat_in(p, level, "cooldown", p.get("cooldown", 0.0)))


## True when this cast carries a power's level-5 twist: its level is 5 and that row's level 5 has one. Level 1-4, no level and a
## power without a table are all false -- an effect gates its twist on this before it draws a random number or schedules anything.
static func twist_at(extra: Dictionary, key: String) -> bool:
	return int(extra.get("level", 1)) == MAX_LEVEL and bool(stat(extra, key, "twist", false))


## The one-line twist a power gains at level 5, or "" for a power without one.
static func twist(key: String) -> String:
	return twist_in(get_power(key))


## The entry's level-5 twist text ("" when it has no table or no twist).
static func twist_in(entry: Dictionary) -> String:
	var table := _table(entry)
	if table.size() < MAX_LEVEL:
		return ""
	var top: Variant = table[MAX_LEVEL - 1]
	if top is Dictionary and bool((top as Dictionary).get("twist", false)):
		return String((top as Dictionary).get("twist_text", ""))
	return ""


## What level_change() calls a stat when it prints it: the name an effect reads -> a few plain words (R4). A stat not named here
## prints under its own name. "<key>.<stat>" beats "<stat>" for the one name two powers use differently.
const STAT_LABELS := {
	"KILL_R": "kill radius", "DAMAGE": "damage", "cooldown": "cooldown", "START_LEVEL": "start fire", "REACH": "reach",
	"PULL_RADIUS": "pull radius", "LIFETIME": "life", "BLASTS": "bursts", "RADIUS": "radius", "cinder.RADIUS": "rain radius",
	"BEAM_TIME": "burn time", "BREATH_TIME": "breath", "SWEEP_ARC": "sweep", "LENGTH": "travel", "WIDTH": "wall width",
	"STONES": "stones", "STORM_TIME": "storm", "VOLLEY": "bolts", "VOLLEY_EVERY": "volley every",
	"MAX_LENGTH": "longest crack", "HALF": "fall width", "SPEED": "crawl",
	"whisper.REACH": "walk reach", "ATTACK_SECS": "attack", "DISCORD_R": "circle", "DISCORD_TIME": "forgetting",
	"SEED": "starting madness", "LURE_MAX": "lure cap", "WISP_TIME": "lure time", "ENTHRALL_TIME": "enthrall",
	"TRANCE_TIME": "trance", "SPAN": "span", "MAX_GUARDS": "guards", "PICK_R": "guard reach", "anathema.RADIUS": "district",
	"COMMAND_X": "command length", "GATHER_CAPACITY": "gather cap", "REGION": "region", "MAX_FIGHTERS": "fighters",
	"DURATION": "length",
}


## What reaching `level` changes for a power, as the tables give it: "radius 1.5 -> 1.7, damage 40 -> 46" (level 5 ends with the
## twist text); "" at level 1; NO_LEVELS for a power without a table.
static func level_change(key: String, level: int) -> String:
	return level_change_in(get_power(key), level)


## level_change() for a row given directly (built from level_rows_in(), so the two never disagree).
static func level_change_in(entry: Dictionary, level: int) -> String:
	if _table(entry).is_empty():
		return NO_LEVELS
	if level < 2:
		return ""
	var parts := PackedStringArray()
	for r: Dictionary in level_rows_in(entry, level):
		parts.append("%s %s -> %s" % [r.label, r.old, r.new])
	if mini(level, MAX_LEVEL) == MAX_LEVEL and twist_in(entry) != "":
		parts.append(twist_in(entry))
	return ", ".join(parts)


## A power's short player-facing description: its row's "blurb", else its "shape" with the first letter capitalised ("" for an unknown key).
static func blurb(key: String) -> String:
	var p := get_power(key)
	var b := String(p.get("blurb", ""))
	if b != "":
		return b
	var shape := String(p.get("shape", ""))
	return shape.substr(0, 1).to_upper() + shape.substr(1)


## The stats that change on reaching `level`, as [{"label", "old", "new"}] in table order (the twist keys left out); [] at level 1 or
## below and for a power without a table.
static func level_rows(key: String, level: int) -> Array:
	return level_rows_in(get_power(key), level)


## level_rows() for a row given directly.
static func level_rows_in(entry: Dictionary, level: int) -> Array:
	var table := _table(entry)
	var out := []
	if table.is_empty() or level < 2:
		return out
	var lv := mini(level, table.size())
	var before: Dictionary = table[lv - 2]
	var after: Dictionary = table[lv - 1]
	for name: String in after:
		if TWIST_KEYS.has(name):
			continue
		if not before.has(name) or before[name] != after[name]:
			out.append({"label": _stat_label(entry, name), "old": _stat_text(before.get(name, "?")), "new": _stat_text(after[name])})
	return out


## The words level_change() prints for a stat of this row (STAT_LABELS, else the stat's own name).
static func _stat_label(entry: Dictionary, name: String) -> String:
	var own := "%s.%s" % [String(entry.get("key", "")), name]
	return String(STAT_LABELS.get(own, STAT_LABELS.get(name, name)))


## A stat's value as level_change() prints it: a Vector2i "5-7", anything else as str().
static func _stat_text(v: Variant) -> String:
	if v is Vector2i:
		return "%d-%d" % [(v as Vector2i).x, (v as Vector2i).y]
	return str(v)


## What is wrong with a row's levels table; empty when valid: MAX_LEVEL tables, every stat named in all of them with one kind of
## value (numbers count as one kind), and the twist ("twist": true plus a non-empty "twist_text") at level 5 only.
static func levels_problems(entry: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var table := _table(entry)
	var label := String(entry.get("key", "?"))
	if table.size() != MAX_LEVEL:
		out.append("%s: needs %d level tables, has %d" % [label, MAX_LEVEL, table.size()])
		return out
	var names := {}
	for i in table.size():
		if not table[i] is Dictionary:
			out.append("%s: level %d is not a Dictionary" % [label, i + 1])
			return out
		for name: String in (table[i] as Dictionary):
			if not TWIST_KEYS.has(name):
				names[name] = true
	for name: String in names:
		var kind := -1
		for i in table.size():
			var row: Dictionary = table[i]
			if not row.has(name):
				out.append("%s: stat %s is missing at level %d" % [label, name, i + 1])
				continue
			var k := typeof(row[name])
			k = TYPE_FLOAT if k == TYPE_INT else k
			if kind >= 0 and k != kind:
				out.append("%s: stat %s changes type at level %d" % [label, name, i + 1])
			kind = k
	for i in table.size():
		var row: Dictionary = table[i]
		if i < MAX_LEVEL - 1:
			if row.has("twist") or row.has("twist_text"):
				out.append("%s: only level %d may carry a twist (level %d does)" % [label, MAX_LEVEL, i + 1])
		else:
			if not (row.has("twist") and row["twist"] == true):
				out.append("%s: level %d needs \"twist\": true" % [label, MAX_LEVEL])
			if String(row.get("twist_text", "")).strip_edges() == "":
				out.append("%s: level %d needs a twist_text" % [label, MAX_LEVEL])
	return out


## Decree rules the rules themselves: what is allowed, what is true, what is law (prohibit, distort, abolish).
## Dominion holds what was Disorder too: to command a mind and to break one are the same Authority.
## The Authorities (v0.08; before, the kinds): what a power commands, and the draft's tabs, in tab order.
const AUTHORITIES := ["ruin", "veil", "dominion", "passage", "decree", "death"]
## Their titles, index for index.
const AUTHORITY_TITLES := ["RUIN", "VEIL", "DOMINION", "PASSAGE", "DECREE", "DEATH"]


## The keys of an Authority's powers, in book order.
static func of_authority(authority: String) -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		if String(p.get("authority", "")) == authority:
			out.append(p.key)
	return out


## A power's Authority, or "" for an unknown key.
static func authority_of(key: String) -> String:
	return String(get_power(key).get("authority", ""))


## An Authority's title ("DEATH"), or "" for an unknown one.
static func authority_title(authority: String) -> String:
	var i := AUTHORITIES.find(authority)
	return String(AUTHORITY_TITLES[i]) if i >= 0 else ""


## A power's family (v0.11.1, spec §7.1): what it does, not its Authority (Decision 25). A mission's main step has a route in
## two families, loadout A's and loadout B's (RouteBook); the gate proves both.
const FAMILY := {
	"doom": "veil", "blight": "veil", "unseen": "veil",
	"deathmark": "death", "pestilence": "death", "raise": "death", "gravecall": "death", "guise": "death",
	"smite": "strike", "heaven": "strike", "tornado": "strike", "tsunami": "strike", "gravity": "strike", "laser": "strike",
	"orbital": "strike", "judgement": "strike", "glacial": "strike", "solaris": "strike", "nova": "strike", "tempest": "strike", "scatter": "strike", "shatter": "strike",
	"ember": "fire", "dragon": "fire", "cinder": "fire",
	"whisper": "lead", "oath": "lead", "saint": "lead", "echo": "lead", "congregation": "lead", "priority": "lead", "voice": "lead",
	"wisp": "draw", "delusion": "draw", "clearmind": "draw",
	"discord": "hold", "sanctuary": "hold", "anathema": "hold",
	"madness": "turn", "turncoat": "turn", "hatred": "turn", "verdict": "turn", "schism": "turn",
	"noleave": "decree", "belllies": "decree", "magnify": "decree", "curfew": "decree", "abolition": "decree",
	"thorns": "passage", "mirror": "passage", "skylift": "passage", "windfall": "passage",
	"hellspark": "passage", "pilgrim": "passage", "deep": "passage", "houndgate": "passage",
	"allroads": "passage", "yesterday": "passage", "everydoor": "passage", "fargate": "passage",
	"foldward": "passage", "heavendoor": "passage", "deaddoors": "passage",
}


## A power's family (FAMILY), or "" for an unknown key.
static func family(key: String) -> String:
	return String(FAMILY.get(key, ""))


## A quiet power (v0.05): its cast is no danger the town can see.
static func is_quiet(key: String) -> bool:
	return bool(get_power(key).get("quiet", false))


static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		out.append(p.key)
	return out


## 84x84 painted icon (Prepare cards), or null when it has not been painted yet.
static func icon(key: String) -> Texture2D:
	return _texture(ICON_DIR + key + ".png")


## 42x42 copy for the HUD slots, or null when it has not been painted yet.
static func hud_icon(key: String) -> Texture2D:
	return _texture(ICON_DIR + "hud/" + key + ".png")


## A texture that may not exist yet (a new power before its icon is painted): null rather than a load error.
static func _texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func clip_path(key: String) -> String:
	return CLIP_DIR + key + ".png"


## The power's preview sheet, or null when it has not been recorded.
static func clip(key: String) -> Texture2D:
	var path := clip_path(key)
	return load(path) if ResourceLoader.exists(path) else null


## Where frame `i` sits in a sheet.
static func clip_frame(i: int) -> Rect2:
	return Rect2(Vector2(float(i % CLIP_COLUMNS) * CLIP_SIZE.x, float(i / CLIP_COLUMNS) * CLIP_SIZE.y), Vector2(CLIP_SIZE))
