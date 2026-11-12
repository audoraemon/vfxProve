# The sound library

`tools/audio/foley.py` and `tools/audio/music_render.py` read recordings, a soundfont and tools from a library outside
the repo: `KAK_SOUND_LIBRARY`, default `C:/BURIN_NITRO/SoundLibrary`. The repo keeps only the recipes, the scores and
the built WAVs; `assets/audio/CREDITS.md` lists every recording a recipe uses.

| Folder | What | Licence | From |
|---|---|---|---|
| `oga/<page>/` | about 90 sound packs: breaking, debris, explosions, fire, ice, water, wind, thunder, lasers, magic, roars, voices, a crowd, birds, crickets, outdoor ambiences | CC0 (each page's licence block checked; `manifest.json` has title, author, URL) | [OpenGameArt](https://opengameart.org), CC0 search |
| `kenney/impact-sounds/` | stone, wood, metal, glass and bell impacts | CC0 | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) |
| `wikimedia/` | church bells (Leverkusen, Litovel, Zabuhailo), a struck bell, the Hiroshima peace bell; a crowd at a distance and market recordings (the ambience) | public domain or CC0 (`manifest.json`) | [Wikimedia Commons](https://commons.wikimedia.org) |
| `synth/<power>/` | `tools/audio/synth.py`'s renders, the base layer of every power's recipe | this repo | `KAK_SYNTH_OUT=<library>/synth python tools/audio/synth.py` |
| `orchestra/sso-4.0/` | Sonatina Symphonic Orchestra 4.0 (SFZ): choir, strings, brass, organ, percussion; the music's instruments | CC Sampling Plus 1.0 (credit requested) | [peastman/sso](https://github.com/peastman/sso) |
| `orchestra/VSCO-2-CE-1.1.0/` | VS Chamber Orchestra 2 Community Edition (SFZ; its raw percussion and organ samples also serve a few recipes: the quiet powers and the Lantern) | CC0 | [sgossner/VSCO-2-CE](https://github.com/sgossner/VSCO-2-CE) |
| `tools/sfizz/` | sfizz 1.2.3 `sfizz_render`, plays the SFZ instruments | BSD-2 (tool only) | [sfztools/sfizz](https://github.com/sfztools/sfizz) |
| `soundfonts/GeneralUser-GS.sf2` | General MIDI instruments `music_render.py` can fall back to | GeneralUser GS licence 2.0: free for music, commercial too | [GeneralUser GS](https://github.com/mrbumpy409/GeneralUser-GS) |
| `tools/fluidsynth/`, `tools/ffmpeg/` | FluidSynth 2.6.1 (renders the MIDI), ffmpeg (converted the Opus files soundfile cannot read) | LGPL, GPL (tools only, nothing shipped) | FluidSynth and BtbN GitHub releases |
| `sao/`, `elevenlabs/` | generated takes, once `sao_generate.py` or `elevenlabs_generate.py` has run | see those scripts | |
| `sonniss/` | the Sonniss GDC 2026 bundle (7.5 GB), once downloaded in a browser: its site blocks scripts | royalty-free, no AI training, no redistribution as sound effects | [sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc) |

**Sonniss and this repo.** The repo is public. Sonniss forbids redistributing its sounds as sound effects, so a game
WAV built from a Sonniss recording must not be pushed to a public repo. Nothing here uses Sonniss yet.

Python needs `numpy`, `scipy`, `soundfile` and `mido` (`python -m pip install scipy soundfile mido`).

**Loudness and the listening sheet.** `python tools/audio/loudness.py` measures every WAV the catalog plays (ITU-R BS.1770-4
integrated loudness and true peak) into `tools/audio/loudness.tsv`; `--check` fails if a WAV no longer matches its row, so run the
tool after any recipe rebuild or new cue and commit the TSV. `--table` prints the played level (LUFS + catalog dB + the call's
offset) of every power's cues and the quiet floor; `tests/test_power_sounds.gd` reads the same numbers. `--mix CUE...` renders
`tools/audio/ab/v0112/mix_<cue>.wav` (the cue over `music_theme` at the game's music level) for `tools/audio/ab/v0112/LISTEN.md`,
the sheet the user listens with.

## Crowd panic (natural sound pass 3)

- Wikimedia Commons: `20080618KamagasakiRiot.ogg` (CC0, Kamagasaki450; a real riot, under the chaos bed),
  `Street_parade_carnival_people_yelling_kamelle_kamelle`, `Douzen_kids_on_playground`,
  `Church_people_walking_steps_with_reverb`, `Festival_concert_people_crowd` (public domain, stephan; converted from
  Opus to WAV with ffmpeg), `UncleSigmund - ahhh` and `NOW screaming` (CC0). The alligator scream recording was left
  out: it holds the famous "Wilhelm scream", which players would know.
- OpenGameArt (CC0): female-high-pitched-scream-sfx, girly-scream, female-distressed-no-no-no, plus the male yelling
  pack already in use. Modern English lines ("please help somebody", "come on let's run") are no longer used.
- Pass 4 (clearer, heavier): the beds keep their full range (no more 2.4-6 kHz low-pass), take less reverb, drop the
  kids and church steps, and get a stampede: a `scatter` layer of single footsteps from OpenGameArt `footsteps-0` and
  `footsteps-leather-cloth-armor` (CC0), each runner with its own distance, pace and crossing pan. The cries are drier.

## Animals and soldiers (natural sound pass 5)

- Dogs: OpenGameArt `dog-sounds` (one clean recording of several dogs: barks big and small, yelps), `dog-growl`,
  `dog-grunt` (CC0); Wikimedia Commons `Puppy at a night` (CC0, a whimper). `Bark (avk)` on Commons is a spoken word,
  not a dog: not used.
- Cats: OpenGameArt `meow`, `cat-purr-meow`, `kitten-mew` (CC0); Wikimedia Commons meows (`Meow of a Siamese cat`,
  `MeowUSA`, a Greek recording saved as `Greek_meow_2015-11-24.flac`, `GettingOutImpatient`, `Meow of a pleading cat`),
  `NoTrip` (yowls) and `Cat hissing - Zabuhailo` (CC0 or public domain).
- Soldiers: boots (`footsteps-0`) with a leather step (`footsteps-leather-cloth-armor`; the metal steps clanked like gunfire and are not used), a faint chainmail and spear swings (the RPG
  sound pack), Kenney impacts, the 150 combat pack's punches, and six low, steady yells from the male yelling pack for
  orders. The war horn is Sonatina's horn section (CC Sampling Plus, credited), a low call and a fifth above.

## Fire where it burns (natural sound pass 6)

- A burning building: OpenGameArt `fireplace-sound-loop` (the body) and Wikimedia Commons `Bones breaking wood fire ice
  crackling` and `Dry grass burning in open fireplace` (public domain, stephan and ezwa; converted to WAV with ffmpeg).
- Catching: OpenGameArt `catching-fire` and `fire-crackling` with the dry-grass burst. Timbers cracking: the 75 breaking
  pack's snaps, the 80 RPG pack's wood cracks pitched down, Kenney wood impacts, `tree-creaking`. Dousing: OpenGameArt
  `steam-release-sounds` (CC0, bart) after a splash from the 100 CC0 pack.
- A hit's aftermath (`ability/aftermath/`): the 100 CC0 pack's stones, the 75 breaking pack's hits and falls, `breaking-rock`
  pitched down for the first chunk, `stonerockorwoodmovednotick` for the settling, the 80 RPG pack's wood for what a tornado
  drops; dozens of hits per take, dense at first and thinning out.

## Interface (natural sound pass 6)

- `ui/`: the 100 CC0 pack's paper and wood, the 80 RPG pack's books and locks, the RPG sound pack's heavy cloth, Kenney
  wood impacts, OpenGameArt `bell-dingschimes` (CC0), Wikimedia Commons `Striking a bell 15cm large` and `Church bells -
  Leverkusen 2007`. The GodotSfxr originals are kept in `tools/audio/sfxr/_replaced/ui/`.

## Dominion, the mind (skill-tree sound audit)

- OpenGameArt (CC0): `dialog-vocal-samples` (short syllables and whispers that are not words), `creepy-incoherent-chanting`,
  `droning-sound-effects`, `ghost-breath`, `heartbeat-sounds`; Wikimedia Commons `SingingBowl1` and `SingingBowl2` (public
  domain, BambooBeast). Choir and brass layers rendered on Sonatina by `music_render.py` from
  `tools/audio/music/dom_choir_*.score.json` into `tools/audio/music/render/`.
- The Dominion powers no longer borrow Heaven Splitter, Nova or Judgement cues: each casts and takes hold with its own
  (`q_<key>` and `dom_*` under `ability/dominion/`).


## Ruin and Passage (skill-tree sound audit)

- Ruin (`ability/ruin/`): OpenGameArt (CC0) `35-wooden-crackshitsdestructions` (the cracks, pitched up, are the split air
  of a bolt), `5-break-crunch-impacts`, `rain-long-thunder` and `storm-siren` (the thunder only, never the siren),
  `100-cc0-sfx-2` thunder and stones, `earthquake-and-open-sesame`, `stone-door`, `breaking-rock`, `cave-in`,
  `low-rumbling`, `explosions-4`, `dull-explosion`, `chunky-explosion`, `spell-sounds`, `fire-staff-sound-effects`,
  `steam-release-sounds`, `wind1`; Wikimedia Commons `Earthquake.ogg` (public domain, igel457; converted to WAV). Choir
  and brass for Light of Solaris from `tools/audio/music/solar_choir_*.score.json`.
- Passage (`ability/passage/`): OpenGameArt (CC0) `iron-door`, `stone-door`, `monster-snarls` and
  `dog-snarl-grunt-grumble` and `16-monster-growls` (the hellhounds), `demon-voice` (growls, snarls, grunts and laughter
  only, never its words), `ghost-monster-voice-moaning-growling` (the ghosts; not the voice-line pack, whose lines are words),
  `6-short-water-splashes`, `water-waves`, `sea-and-river-wave-sounds`, `skippy-fish-water-sound-collection`, the Monster
  RPG 2 pack's water, door and chest, `portal-sound`, `4-space-portal-sounds`, `sick-noises`, the RPG sound pack's coins
  and cloth; Wikimedia Commons `Door handle creaking.ogg` (public domain, stephan; converted to WAV, pitched down to a
  door). Choir and brass for Heaven's Door from `tools/audio/music/heaven_choir_*.score.json`.
- The Ruin and Passage powers in the skill tree no longer borrow Heaven Splitter, Judgement, Nova, the laser, the orbital,
  the Dragon's roar, the Tsunami's water or Cinderfall's fire: each has its own cues. The hellhounds, demons and ghosts
  that Hound Gate and Doors of the Dead let out have voices of their own (`hound_*`, `demon_*`, `ghost_*`): heard as they come
  through, while they roam (VisitorVoices), when they bite, claw or touch, and when they fall.

## The town's children

- `citizen/child_play_*`, `child_cry_*`, `child_death_*`: Wikimedia Commons `Short clip of girl laughing.wav` (CC0,
  lmbubec), `Douzen kids on playground.ogg` (public domain, stephan), `Baby long wanting cry.ogg` and `Babys disappointed
  crying.oga` (public domain, natalie; converted to WAV, pitched down a little to a small child); OpenGameArt (CC0)
  `children-voices`, `group-giggling` (pitched up), `girly-scream`; the falls from Kenney's impact sounds. Wordless takes
  only: laughs, shrieks, giggles and cries, never a word.
