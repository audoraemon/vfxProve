# The sound library

`tools/audio/foley.py` and `tools/audio/music_render.py` read recordings, a soundfont and tools from a library outside
the repo: `KAK_SOUND_LIBRARY`, default `C:/BURIN_NITRO/SoundLibrary`. The repo keeps only the recipes, the scores and
the built WAVs; `assets/audio/CREDITS.md` lists every recording a recipe uses.

| Folder | What | Licence | From |
|---|---|---|---|
| `oga/<page>/` | about 80 sound packs: breaking, debris, explosions, fire, ice, water, wind, thunder, lasers, magic, roars, voices, a crowd | CC0 (each page's licence block checked; `manifest.json` has title, author, URL) | [OpenGameArt](https://opengameart.org), CC0 search |
| `kenney/impact-sounds/` | stone, wood, metal, glass and bell impacts | CC0 | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) |
| `wikimedia/` | church bells (Leverkusen, Litovel, Zabuhailo), a struck bell, the Hiroshima peace bell | public domain or CC0 (`manifest.json`) | [Wikimedia Commons](https://commons.wikimedia.org) |
| `synth/<power>/` | `tools/audio/synth.py`'s renders, the base layer of every power's recipe | this repo | `KAK_SYNTH_OUT=<library>/synth python tools/audio/synth.py` |
| `orchestra/sso-4.0/` | Sonatina Symphonic Orchestra 4.0 (SFZ): choir, strings, brass, organ, percussion; the music's instruments | CC Sampling Plus 1.0 (credit requested) | [peastman/sso](https://github.com/peastman/sso) |
| `orchestra/VSCO-2-CE-1.1.0/` | VS Chamber Orchestra 2 Community Edition (SFZ) | CC0 | [sgossner/VSCO-2-CE](https://github.com/sgossner/VSCO-2-CE) |
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
