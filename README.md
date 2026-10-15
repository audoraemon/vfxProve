# VFX Prove

Real-time Godot proof of four sci-fi skill effects from the concept sheets in `concepts/`, built for a 2D isometric pixel-art game:

| Key | Effect | Stages |
|---|---|---|
| 1 | **Nuclear Nova** | target rings → warhead descent → white-hot core swells slowly → plasma dome (boiling veins, meridian energy lines, rising pulses) + shockwave accelerate outward with god-rays, rubble and a rolling dust ring → shader mushroom cloud rising and cooling from fire to smoke with a condensation ring, heat haze, crater, radiation fog |
| 2 | **Orbital Strike** | zone + pips → ~30 Poisson-disc strike points covering the whole radius, lock-on in bursts of 1–3 → beam impacts with light pools, rays, fireballs, heat haze → crater field, smoke, ion sparks |
| 3 | **Gravity Distortion** | sky beam seeds the field → screen-lensing singularity with wispy accretion disk, photon ring, lightning arcs and orbiting rubble pulls enemies in → compression → implosion with refraction shock ring and starburst → warped scar with hovering fragments |
| 4 | **Walking Laser Grid** | lane telegraph → emitter drones descend → wide glowing beams (core + additive halo, contact rings) link into a wall → wall sweeps the lane with red floor light, heat haze, flames and burn flashes → molten lava corridor (crack network shader) that cools to crust |

**Impact toolkit** (`src/core/impact.gd`): anticipation dimming of the world under the effect layers, inverted two-tone impact frames, hit-stop (real-time, audio keeps its pitch), RGB split, directional camera kicks. Enemies react per damage type: blasts throw and char them, gravity stretches them into the core, lasers cut them apart into embers. Smoke lives in `OverheadBackLayer` so fireballs always read in front of it.

**Destructible city + effect lighting**: `src/environment/` builds a small city block of towers, blocks, barricades and crates drawn as lit iso pixel boxes. Structures take damage per effect — blasts collapse them outward into rubble with dust, debris and fires, the laser cuts them and the top slides off, gravity shakes then crumbles them inward — and walkers path around standing ones. `src/core/light_field.gd` collects every effect light pool, so building faces facing a light and nearby troopers are lit by fireballs, beams and void glow; the anticipation dim darkens the ground while lit faces still glow.

**Set2 fantasy skills** (KWAI castle defense, concepts in `concepts/Set2/`): press `Tab` to switch to a fantasy castle map (stone courtyard, crenellated walls and keeps, timber houses, torches that light the scene, orc horde). Built so far:

| Key | Effect | Stages |
|---|---|---|
| 1 | **Glacial Cataclysm** | glowing frost rune + cold mist → faceted ice spikes erupt (impact frame, hit-stop) → freeze wave spreads, frozen ground, enemies encased in ice → crystal mountain (spread over the whole radius, tallest at the center) surges to full height, enemies inside it burst → when each freeze ends the enemy explodes in an icy blast (frost ring, shards, crystal pops, mist) → outer spikes break into residue, icy fog, snow |
| 2 | **Heaven Splitter** | glowing lane with star runes + storm sigil charge → colossal lightning column (crackling strands round a white core) crashes down with a starburst and flying stone, lightning crawls along the marked line → 8 jagged, forking fissures crack outward, white-hot at the front → forked bolts erupt along the fissures → glowing cracks, static arcs, grey smoke *(drag = line direction)* |
| 3 | **Cinderfall Barrage** | glowing magma sigil, quake and spreading lava cracks → a colossal volcano (PixelLab sprite: dark rock slabs, glowing lava veins and crater) thrusts out of the ground → the crater erupts, hurling giant fire stones → flaming boulders rain across the area (fire bursts, scorched craters, lava pools, glowing cracks) → the volcano sinks into a smoking crater, burning pools and embers |
| 4 | **Tsunami Breaker** | water lane telegraph → a breaking wave rises: a projected surface mesh of curling barrels that peel sideways, cut ends showing the curl hollow → sweeps the lane carrying enemies and smashing houses, flood water with drifting foam streaks behind it → terminal splash with radial spray and shockwave → calm flood with floating planks, ripples and mist *(drag = direction)* |
| 5 | **Tornado Tempest** | spiral wind rune + suction ring → a dense silver funnel of tapered wind ribbons forms, with swooshes orbiting outside it, a spiral cloud cap and a golden dust glow at its base → for about ten seconds it wanders slowly in random directions (the camera follows), pulling enemies in and spiralling them up the funnel before flinging them out, rocks and planks orbiting it and scarred swirls left along its path → unravels, dropping debris into dust *(click to cast)* |
| 6 | **Judgement of the Ancients** | golden earth rune → stone hands and sandstone spikes break out, a PixelLab pixel-art stone titan with glowing golden cracks rises from its crater, facing the camera → eight alternating left/right knuckle punches, each with a golden impact at the fist and a second shock further out → two-hand final slam with golden shockwave and spike ring → titan shudders and sinks into rubble |
| 7 | **Dragonfire Parade** | dragon sigil and sweep-arc preview → ground ruptures in lava and obsidian → a PixelLab pixel-art fire dragon climbs out of its lava hole, always facing south-east → lowers its head and roars while a procedural flame jet sweeps across the ground from in front of it to its right → sinks away, leaving scorched earth and flickering flame patches *(click to cast)* |

Design: `docs/superpowers/specs/2026-09-16-set2-fantasy-vfx-design.md`.

**Look pass**: daylight castle map, screen glow (`shaders/glow_post.gdshader`, thresholded mip bloom dithered to pixel steps), camera push-in framed per effect (`zoom`, `focus_up`, `focus_along` in `EFFECTS`) that eases back when the last effect ends, a lighter per-set anticipation dim (`Impact.dim_scale`) and dark outlines on debris chunks.

Everything is procedural: canvas shaders, a small pixel particle system, code-drawn sprites, and synthesized audio. No external art or sound assets.

Settings match the sibling KWAI project: Godot 4.7.2, GL Compatibility, 640×360 viewport scaled ×2 with nearest filtering, 64×32 iso cells.

## Run

```powershell
$godot = 'F:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path .
```

Or open the folder in the Godot 4.7.2 editor and press F5. Running the project (`& $godot --path .`, F5 in the editor, or `play.bat`) opens the **KAK title screen**; the VFX sandbox below is its "VFX Sandbox" button, or `& $godot --path . --scene res://scenes/sandbox.tscn`.

### Controls

| Input | Action |
|---|---|
| `1`–`7` | select effect |
| `Tab` | switch effect set (Set1 sci-fi city / Set2 fantasy castle) |
| Left click | cast at cursor |
| Left drag (Laser Grid) | press = lane start, drag direction = walk direction (short click walks down-right) |
| `R` | respawn 40 enemies |
| `Space` | toggle 0.25× slow motion (audio pitch follows) |
| `WASD` / arrows | pan camera |
| `Esc` | quit |

## Kingdoms Amid Kataclysm (KAK) — game slice in progress

The approved effects are becoming a one-mission game (spec: `docs/superpowers/specs/2026-09-19-kak-one-mission-game-design.md`). Milestone 4 put the game itself around the mission: Title, Prepare with the four-card draft, Pause, and Results with the score and rank, with the save file at `user://kak_save.cfg`. Milestone 3: the pieces became a mission you can play — Divine Power and its four-minute clock, City Stability, win/lose and scoring (`rules.gd`), aim previews for all eleven powers (`targeting.gd`) and the in-mission HUD (`ui/hud.gd`), composed into `mission.gd` / `scenes/mission.tscn`. Milestone 2 inhabited the town: 110 citizens who wander, panic, flee to the exits and queue at the gates, and 50 soldiers who hold their posts, rally to the Citadel when the alarm rises, and hold their ground in its rubble. Milestone 1 built the shared `Battlefield`, the walled town of Aldermere and its fortified Royal Citadel. Play it with `play.bat`, or:

```powershell
& $godot --path . --scene res://scenes/mission.tscn
```

| Input | Action |
|---|---|
| `Enter` | The Missions board on the title, choose the selected mission on the board, MANIFEST on Prepare once at least one power is picked, Replay on Results |
| `Left` / `Right` | select a mission on the board (or hover a card); the difficulty on Prepare (Last Judgement only) |
| `1`–`6` | pick a power from the drafted loadout (up to six slots, by mission) |
| Left click | cast a point power at the cursor |
| Left drag | line powers (Heaven Splitter, Tsunami Breaker, Thornwall): press = start, drag = direction; Mind Whisper: press on a person, release on the spot |
| `WASD` / arrows, middle drag | pan |
| Mouse wheel | zoom |
| `R` | restart with a fresh mission (a board night replays the loadout it was drafted with) |
| `F` | ASCEND on a board night, once its main objective is done (v0.11) |
| `U` | Upgrades, on the mission board (v0.11) |
| `Esc` | cancel an aim in progress, else quit; Title from the board, the board from Prepare, pause in a mission, resume from pause, the board from Results |

**Versions:** v0.10 (tag `kak-v0.10`) adds **the Lantern campaign**: four nights in Aldermere from the title's Campaign button — The Warning, a Night 2 chosen by path (Mira's House, The Vigil Flame or Broken Lanterns, under Halcyon's Gaze), a Night 3 Feast act and, on the Ruin path, Last Judgement — with Divine Power that grows and bites, Cael's memory fragments and lines, and four endings. v0.09 (tag `kak-v0.09`) adds **The Long Night** (Tier 3), a mission in three acts on one town: The Omen, then the Festival or the Procession, then Judgement, with an interlude and a re-draft between acts, timed events, and a rank and save for the night. v0.08 (tag `kak-v0.08`) added the mission board (The Warning, Tier 1; Last Judgement, Tier 5), Divine Power as a loadout budget with up to six slots, and Mind Whisper. Each version is described in `docs/KAK_Version_<version>_Summary.md` (latest: `docs/KAK_Version_0.11_Summary.md`). Night 2's missions now show their objectives on the map, say how to win under the objectives, and open on a short skippable tour. v0.11 (in progress, `docs/KAK_Version_0.11_Summary.md`): Missions now opens a five-tier board whose nights hear the town's wishes, end with an ascent, and bank believers for upgrades. Whisper, the first tier, is complete: The Warning, The Tax Collector, Spoiled Harvest, The Lost Lamb and First Prayers. Omen, the second tier, is complete: Mira's House, Broken Lanterns, The Bell-Ringers, Market Panic and The Informer.

**The Lantern campaign:** run `play.bat` and press **Campaign** on the title (**Missions** is the board of single missions). The night screen shows where the campaign stands (Divine Power, slots, bites, the god's title), Cael's memory for the night and, on Nights 2 and 3, one card per mission: pick one with Left/Right and Enter (or a click), then **Choose powers**. Night 1 is The Warning; Night 2 is Mira's House (Faith), The Vigil Flame (Theft) or Broken Lanterns (Ruin); Night 3 is a Feast act, The Festival or The Procession; Night 4, Last Judgement, is played on the Ruin path only. A won night adds 2 DP (1 more for a bonus); a lost one is a bite (−1 DP, never below 4), and three bites mean Halcyon eats the god. The campaign lives in its own `[campaign]` section of `user://kak_save.cfg`; campaign nights never change the board's bests or loadouts.

The mission, loadout, seed and population can be set on the command line: `-- --mission=warning --loadout=whisper,doom,discord --seed=7 --people=80` (`--mission=long_night` plays the night; the campaign's nights are `miras_house`, `vigil_flame`, `broken_lanterns`, `feast_festival` and `feast_procession`). Last Judgement's default loadout is Heaven Splitter, Tsunami Breaker, Cinderfall Barrage and Nuclear Nova; The Warning's is Mind Whisper, Silent Doom and Discord. A mission ends with a banner and the Results screen.

```bash
SCENE=res://scenes/mission.tscn bash tools/capture.sh --mission-test   # scripted mission; logs MISSION test ... (add --mission=warning for The Warning)
SCENE=res://scenes/game.tscn bash tools/capture.sh --show=prepare --capture   # one screen → captures/screen_<name>.png (title|board|prepare|results|results-warning|pause|campaign|campaign-choice|ending|results-feast|miras|cael|lanterns|flame|flame-beams|tiers|upgrades|results-descend|ascend|tax_collector|spoiled_harvest|lost_lamb|first_prayers|bell_ringers|market_panic|informer; add --mission=warning for The Warning); a --show run reads your save but writes user://test_show.cfg, never the real one
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/game.tscn -- --flow-test   # drives title -> board -> draft -> mission -> pause -> results -> replay -> board; prints FLOW lines
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=miras --case=play   # the campaign's nights scripted: miras, lanterns, flame (--case=none|play, --seed=) and feast (--path=festival|procession, --bell=rang); each prints its result and a checksum
/f/Godot/Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --scene res://scenes/mission.tscn -- --mission=vigil_flame --bench --bench-beams   # times Halcyon's Searchlight with both beams lit
```

### Debug scene

Every one of the eleven powers, freely castable, no rules yet. Open it with `town.bat`, or:

```powershell
& $godot --path . --scene res://scenes/town_debug.tscn
```

| Input | Action |
|---|---|
| `1`–`9`, `0`, `-` | pick a power (Heaven Splitter … Nuclear Nova, cheapest first) |
| Left click | cast a point power at the cursor |
| Left drag | line powers (Heaven Splitter, Tsunami Breaker, Walking Laser Grid): press = start, drag = direction |
| `WASD` / arrows, middle drag | pan |
| Mouse wheel | zoom |
| `R` | rebuild the town |
| `Esc` | quit |

The Citadel is nine buildings on one hidden health pool: at most 25% can go per second, every 10% lost drops the part nearest the blow, and the keep falls last.

```bash
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town   # town screenshots → captures/town_*.png
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --citadel-test   # scripted strikes; logs CITADEL t= frac= standing=
SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test    # scripted panic; logs CROWD t= fleeing= queued= escaped= alarm=
```

## Layout

```
src/core/        iso projection, camera shake
src/enemies/     dummy troopers + EnemyField (radius/lane queries, pull, knockback, kill)
src/environment/ destructible structures + EnvironmentField (city layout, damage queries, blocking)
src/fx/          FxTimeline base, QuadFx, PixelParticles, FxParts builders, the 4 effects
src/audio/       Sfx cue catalog + pooled positional playback
src/sandbox/     VFX sandbox: effect picker, floor tiles, input, HUD, camera push-in, capture/bench modes
src/game/        KAK game: Battlefield (shared world), PowerBook, town debug scene
src/game/town/   Aldermere layout, Town builder, town floor, fortified Citadel
src/game/crowd/  the people: Person (citizen/soldier brains and bodies), Crowd (spawning, panic, gates, alarm, rally)
shaders/         iso_rings, shockwave, fireball_dome, beam_glow, beam_add, scorch_decal, fog, singularity,
                 light_glow, god_rays, heat_haze, refract_ring, impact_post, molten_trail, mushroom_cloud
assets/audio/    generated WAV cues (committed)
tools/           test runner, capture runner, contact sheets, audio synth
docs/superpowers design spec + implementation plan
scenes/          game.tscn (main scene), mission.tscn, sandbox.tscn, town_debug.tscn
```

Each effect is a `FxTimeline` subclass: `_build()` schedules stage callbacks with `at(time, fn)`, `_fx_process()` runs per-frame logic. Effects reach gameplay only through `EnemyField` and audio only through `Sfx` (via `FxContext`). Ground-plane effects are children of a node whose transform is the iso basis, so they are authored in ground units and project to iso automatically.

## Verify

```bash
bash tools/test.sh                                   # headless tests → checks=562 failures=0
python tools/audio/synth.py --verify                 # audio cue checks → 78 cues, 0 problems
bash tools/capture.sh --capture-all [--only=nova]    # PNG frames at key stage times → captures/
python tools/contact_sheet.py nova 4                 # tile captures into captures/sheet_nova.png
```

Benchmark (all four effects at once, or one with `--only=`):

```powershell
& $godot --path . --audio-driver Dummy --disable-vsync --max-fps 0 --scene res://scenes/sandbox.tscn -- --bench
```

Dev machine results after the impact pass (RTX 3060 Ti; another game was running and using ~2 CPU cores, so numbers swing a lot between identical runs — the empty scene alone varied 380–448 FPS; rerun on an idle machine for real numbers):

| Bench | Avg FPS | Worst frame |
|---|---|---|
| nova | 250 | 20.0 ms |
| orbital | 140–157 | 31–35 ms |
| gravity | 253 | 15.7 ms |
| laser | 263 | 16.5 ms |
| all four at once | 96 | 46.9 ms |

All shaders are drawn once at startup (`FxParts.prewarm`) — without it the Compatibility renderer compiled them on each effect's first impact frame (~30 ms hitch).

## Audio

Every sound is sorted by kind under `assets/audio/`, and every one is built from a source in `tools/audio/`:

| Kind | Folder | Built from | By |
|---|---|---|---|
| Powers (78, shared by all 38 powers) | `ability/<element>/`: `fire`, `ice`, `water`, `wind`, `holy`, `energy`, `arcane` | recordings over `synth.py`'s render of the same cue (`tools/audio/foley/ability/<element>/<cue>.json`) | `tools/audio/foley.py` |
| Citizens and soldiers (9) | `citizen/` | recordings: real yells, screams, a crowd, a cheer and a bugle (`tools/audio/foley/citizen/`) | `tools/audio/foley.py` |
| Buildings and the town (10) | `building/` | recordings: rock, wood and debris, a church bell (`tools/audio/foley/building/`) | `tools/audio/foley.py` |
| Music (4 loops, stereo) | `music/` | scores (`tools/audio/music/<cue>.score.json`) played by orchestral sample libraries | `tools/audio/music_render.py` |
| Interface (14) | `ui/` | GodotSfxr (`tools/audio/sfxr/ui/`) | `tools/audio/sfxr_bake.gd` |

The recordings, the soundfont and the tools live in a sound library outside the repo (`KAK_SOUND_LIBRARY`, default `C:/BURIN_NITRO/SoundLibrary`); `tools/audio/foley/SOURCES.md` says what is in it and where it came from, and `assets/audio/CREDITS.md` lists every recording in use (all CC0 or public domain). Python needs `numpy`, `scipy`, `soundfile` and `mido`.

```bash
python tools/audio/foley.py                    # every recipe; or a cue name, or a folder (ability, fire, citizen...)
python tools/audio/foley.py --credits          # rewrite assets/audio/CREDITS.md
python tools/audio/music_render.py             # the music, plus tools/audio/music/midi/<cue>.mid for any music editor
KAK_SYNTH_OUT=C:/BURIN_NITRO/SoundLibrary/synth python tools/audio/synth.py   # the powers' synth base layers
"$GODOT" --headless --editor --path . --import # after building, so new WAVs get their .import files
```

**A recipe** (`tools/audio/foley/<category>/.../<cue>.json`) layers sound files: each layer has its source (`lib:` the library, `repo:` this repo), where it starts, where to read from (or its first sound), how much, its pitch, gain, filters and fades; the recipe has a length, a reverb and a level, and a loop wraps its tail into its start. The format is at the top of `foley.py`. To change a power's sound, swap or add a recording in its recipe and rebuild; its first layer is the synth render, which keeps the power's timing, kept 6 dB further back than at first so the recordings lead. A recipe may also set `eq` (the collapses cut their boom below 150 Hz and lift 3.2 kHz, so the materials breaking are heard, not only a thud). `python tools/audio/foley.py --recordings-only tools/audio/ab/recordings_only ability` renders every power without its synth base into `tools/audio/ab/` (Godot ignores that folder), to compare by ear. All sound WAVs import uncompressed (`compress/mode=0`): Godot's default compression is lossy. Catalog levels are matched to the previous versions by K-weighted (ITU BS.1770) loudness, so a change of tone does not change how loud a cue plays.

**The music** is dark and choral: a 58 s theme for the title and the board (a tolling bell, low strings, a choir, harp, a solo cello's tune, then organ and the choir singing it) and a 32 s battle loop in three layers that thicken as the city falls (base: strings ostinato, organ, low choir; drums: bass drum, timpani, snare, tam-tam, cymbals; lead: trombones, choir chant, horns, violin tremolo), in D minor with a phrygian E flat. Each score part names an instrument in `tools/audio/music/instruments.json` (Sonatina Symphonic Orchestra and VSCO 2 CE sample libraries, played by sfizz), its loudness (`level_db`), pan, reverb send and dynamics curve (`dyn`); the renderer high-passes each part below its range, mixes them in stereo through a hall reverb that hears only 280 Hz to 9 kHz (so the low end stays tight), cuts the 300 Hz mud, lifts presence and air with a master EQ and a gentle exciter (the samples hold little above 7 kHz), and folds each loop's tail into its start. The music WAVs import uncompressed (`compress/mode=0` in their `.import`), since Godot's default compression is lossy. `tools/audio/music/midi/<cue>.mid` has one track per part, for any music editor. `tools/audio/music/bugle.score.json` renders the soldiers' bugle that `citizen/sol_rally` uses.

**Generated sounds** for what no library has: `tools/audio/sao_generate.py` runs Stable Audio Open in the local ComfyUI (models staged in `C:/BURIN_NITRO/ComfyUI/ComfyUI/models`), and `tools/audio/elevenlabs_generate.py` calls ElevenLabs with your API key; both read `tools/audio/sao_prompts.json` and put their takes in the library, to audition and use in a recipe. Running Stable Audio Open means accepting the Stability AI Community License (a copy is beside the checkpoint): free under US$1M a year in revenue, commercial use needs a free registration at https://stability.ai/community-license.

A cue that varies its pitch per play (`jitter` in `Sfx.CATALOG`) varies its level too, by up to `Sfx.LEVEL_JITTER_DB`.

### GodotSfxr

[GodotSfxr](https://github.com/tomeyro/godot-sfxr) (MIT, `addons/godot_sfxr`, enabled in the project) is an sfxr synth inside the editor. It makes the interface sounds; its earlier citizen and building sounds are kept in `tools/audio/sfxr/_replaced/` (move a folder back out and bake to use them again). Sources live in `tools/audio/sfxr/<category>/`, and `tools/audio/sfxr_bake.gd` bakes each to `assets/audio/<category>/<cue>.wav`. The game plays plain WAVs and never loads the addon. Sources come in two kinds:

- **`<cue>.tres`:** one `SfxrAudioStream`, one sfxr sound. Open it in the editor: its settings show in the inspector, with a generator for each preset, and any change rebuilds the sound and plays it. Used for the short interface blips.
- **`<cue>.score.json`:** a score of sfxr notes that the bake mixes into one 16-bit WAV. One sfxr sound is one note, so the chords (`ui_manifest`, `ui_win`, `ui_lose`) are scores; so were the set-aside citizen and building sounds, and the music's scores in `tools/audio/music/` are in the same format. Each part plays an instrument from `tools/audio/sfxr/voices/`, itself an `SfxrAudioStream` you can audition and tweak in the inspector. The score format is at the top of `sfxr_bake.gd`: note times in beats or seconds, pitch as a note name or Hz, hold, attack, decay, gain, an echo per part (sfxr has no reverb), and seamless loops.

To change a sound, edit its source or a voice it uses, save, then bake and import:

```bash
"$GODOT" --headless --path . -s tools/audio/sfxr_bake.gd -- --only town_bell
"$GODOT" --headless --editor --path . --import
```

Without `--only` it bakes all 14. `--rebuild` builds each `.tres` from its settings first and saves that back into the resource. The bake refuses a `.tres` that clips and warns about a voice that clips: lower its `sample_params/sound_vol`. A score is normalized to `peak_db` (or `rms_db`, which the music stems use to keep their balance). Levels in play are each cue's `db` in `Sfx.CATALOG`.

A new sound needs its source, an entry in `Sfx.CATALOG` and a call that plays it (`UiSound.play()` for the interface, `Sfx`/`ctx.play()` in the world).

The interface cues:

| Cue | When it plays | Sound |
|---|---|---|
| `ui_hover` | the pointer moves onto a menu item | a tiny rounded chip blip, D6 |
| `ui_click` | a menu item is clicked | a punchy G5 "boop" that sags a little |
| `ui_focus` | a power is picked | a sine rising 700 to 1400 Hz |
| `ui_back` | Esc, a right-click or the slot's key again lets go of a power or a held press | `ui_focus` backwards |
| `ui_buzz` | a cast is refused, or a choice cannot be taken | a low warbling buzz falling a fifth, E3 to A2 |
| `ui_pause` / `ui_resume` | the pause menu opens / closes back into the mission | 660 then 440 Hz / 440 then 660 Hz |
| `ui_mode` | Q or E steps a power's modes | a tiny chip blip up a fifth |
| `ui_ready` | a slot comes off its cooldown | a coin pickup, B5 up to E6 |
| `ui_notice` | a banner comes on screen (not a refused cast's, nor the Divine Surge's) | a sine bell, C5 up the octave |
| `ui_surge` | the Divine Surge resets every cooldown | the classic sfxr power-up |
| `ui_manifest` | a loadout is manifested | an A chord swelling open, then a boom (score) |
| `ui_win` / `ui_lose` | the results | C E G C and its chord / G F E♭ C falling (scores) |

The earlier sfxr versions of the citizen and building sounds are in `tools/audio/sfxr/_replaced/`; the sfxr bake skips any folder starting with `_`.

Things to know about GodotSfxr:
- **Loudness:** its flanger stage doubles the signal even when the flanger is off. A `sound_vol` near 0.25 to 0.35 already reaches full scale, and a resonant low-pass rings higher still.
- **Length:** each envelope stage is at most 2.27 s, so one note is at most about 6.8 s.
- **Arpeggio and retrigger:** the arpeggio is timed from the sound's start, not from each retrigger. A retriggered arpeggio does not trill: it jumps once.
- **One local patch:** its `_get_property_list()` is typed `Array[Dictionary]`. Godot 4.7 logs an error for the untyped original.

## Gotchas

- Smoke puffs draw cached pixel-disc textures (`PixelParticles._disc_texture`) rather than `draw_circle`; polygons per puff were the biggest CPU cost.
- `project.godot` enables `snap_2d_vertices_to_pixel`: `draw_line` with width ≥ 1 builds quads that can collapse to nothing. Use hairlines (`width = -1`) and stack them for thick pixel lines.
- Shader timing uses `uniform float u_time` driven by `QuadFx`, not `TIME`, so effects honor `Engine.time_scale`.
- The first headless import of new files occasionally crashes; `tools/test.sh` retries once.
