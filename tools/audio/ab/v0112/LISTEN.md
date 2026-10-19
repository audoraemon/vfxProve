# v0.11.2 listening sheet

The numbers below are measured (`python tools/audio/loudness.py`, ITU-R BS.1770-4); whether they sound right is yours to say.
Mark each row 1-5 (1 = wrong, 3 = fine, 5 = just right) and write what you heard in the note column. A level that is off is
one number in `Sfx.CATALOG` (`db`), so say "louder" or "quieter" and by how much if you can.

**How to listen.** Every row has a mix beside this file, `mix_<cue>.wav`: four seconds of `music_theme` at the game's music
level (`Music.DB` -16 dB; the bed measures -29.2 LUFS) and the cue at its played level at 1.0 s. If the cue reads over the
music in the mix, it reads over it in the game. A cue with several variants is mixed with its loudest variant (the one the
measure and the tests use); the others are up to 2.5 LU quieter.

**Terms.** LUFS = integrated loudness of the file. Peak = true peak in dBTP. Played = LUFS + the catalog's dB + the call's offset,
the level the player hears (jitter of +-1.5 dB aside). The loud powers' median main cue plays at **-14.55**; the floor for every
power's cast sound is that minus 6 LU, **-21.0** (`QUIET_FLOOR` in `tests/test_power_sounds.gd`).

## Rows

| Cue | Files (LUFS / peak) | Catalog dB | Played | Mix | Listen for | Mark 1-5 | Note |
|---|---|---|---|---|---|---|---|
| `Music.DB` | `music_theme` -13.15 / -0.43 | -16 (was -10) | bed -29.2 | the bed of every mix | The music is a bed, not a wall: lowered 6 dB. Too quiet? Too loud still? Tell me a number between -20 and -14. | | |
| `cit_death` | 1: -14.12 / -0.28, 2: -15.53 / -1.95, 3: -16.61 / -1.69, 4: -14.96 / -1.13, 5: -15.55 / -0.27 | -4.4 | -18.5 (loud median -4) | `mix_cit_death.wav` | A citizen's short cry and fall. Heard at once over the music, but a Smite or a Heaven Splitter is still the loud thing. Not funny, not shrill; five takes that do not repeat. | | |
| `sol_death` | 1: -14.39 / -2.17, 2: -15.63 / -1.84, 3: -14.65 / -2.10 | -4.2 | -18.6 (loud median -4) | `mix_sol_death.wav` | A soldier's grunt, mail and a fall: reads as armour, not as a villager. | | |
| `cit_fall` | 1: -26.56 / -5.99, 2: -25.34 / -5.99, 3: -25.79 / -5.99, 4: -25.30 / -5.99 | +1.8 | -23.5 (loud median -9) | `mix_cit_fall.wav` | A body slumping, no cry: Silent Doom, Death Mark and plague. Quiet on purpose; can you still hear it on a calm street, and does it stay unsettling rather than silent? | | |
| `crowd_death_wave` | 1: -13.97 / -0.28, 2: -15.67 / -0.29 | -2.0 | -16.0 (under the median) | `mix_crowd_death_wave.wav` | The roar of a crowd falling at once: one crunchy wave over three cries, never sixty. | | |

Rows for the quiet powers' own `q_<key>` cues (Tasks 13-14) and the Lantern's `lantern_flare`, `lantern_burn` and
`lantern_blind` (Task 14) are added by those tasks with the same columns: run `python tools/audio/loudness.py`, then
`python tools/audio/loudness.py --mix <cue>...`, and copy the numbers from `tools/audio/loudness.tsv`.

## In the game

1. **Title -> Options.** Each bar (Music, Sounds, Interface) moves; Sounds plays one Smite crack, Interface a click; closing keeps the setting.
2. **Last Judgement, a Nova into the market.** One wave of falling, a roar and three cries, not sixty cries.
3. **The Tax Collector, Silent Doom on a collector.** Hear the cast, then the fall; no cry from an unseen death.
4. **The Vigil Sandbox, each quiet power in turn.** Every cast has its own sound and none is lost under the music.
5. **The Warning, a toll.** The Lantern's flare (once Task 14 has landed).
6. **The pause duck.** Pause a mission: the music ducks; open Options from the pause menu: the duck lifts so the Music bar is audible.
