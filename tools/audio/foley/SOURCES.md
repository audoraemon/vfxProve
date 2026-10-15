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
| `soundfonts/GeneralUser-GS.sf2` | the instruments `music_render.py` plays | GeneralUser GS licence 2.0: free for music, commercial too | [GeneralUser GS](https://github.com/mrbumpy409/GeneralUser-GS) |
| `tools/fluidsynth/`, `tools/ffmpeg/` | FluidSynth 2.6.1 (renders the MIDI), ffmpeg (converted the Opus files soundfile cannot read) | LGPL, GPL (tools only, nothing shipped) | FluidSynth and BtbN GitHub releases |
| `sao/`, `elevenlabs/` | generated takes, once `sao_generate.py` or `elevenlabs_generate.py` has run | see those scripts | |
| `sonniss/` | the Sonniss GDC 2026 bundle (7.5 GB), once downloaded in a browser: its site blocks scripts | royalty-free, no AI training, no redistribution as sound effects | [sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc) |

**Sonniss and this repo.** The repo is public. Sonniss forbids redistributing its sounds as sound effects, so a game
WAV built from a Sonniss recording must not be pushed to a public repo. Nothing here uses Sonniss yet.

Python needs `numpy`, `scipy`, `soundfile` and `mido` (`python -m pip install scipy soundfile mido`).
