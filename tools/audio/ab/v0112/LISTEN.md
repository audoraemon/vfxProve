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
| `q_doom` | -18.07 / -4.61 | +0.6 | -17.5 | `mix_q_doom.wav` | Silent Doom, the cast: a dark breath gathering over the spot, 0.45 s before the fall. Quiet but present; eerie, not a wail. | | |
| `q_doom_hit` | -18.19 / -1.87 | +0.2 | -18.0 | `mix_q_doom_hit.wav` | Silent Doom, the fall: a soft drained thud as they go (with cit_fall under it). Not a cry. | | |
| `q_blight` | -17.53 / -0.40 | +0.5 | -17.0 | `mix_q_blight.wav` | Blight, the cast: a wet gurgle and a thin hiss, rot beginning. | | |
| `q_blight_hit` | -19.99 / -1.81 | +1.5 | -18.5 | `mix_q_blight_hit.wav` | Blight, the rot takes: a brittle crack and a sizzle. Heard when the well, the gate or the standard goes grey. | | |
| `q_deathmark` | -17.32 / -4.89 | -0.2 | -17.5 | `mix_q_deathmark.wav` | Death Mark, the cast: a cold touch with a low ring under it, then ten quiet seconds. | | |
| `q_deathmark_hit` | -15.85 / -1.98 | -0.7 | -16.6 | `mix_q_deathmark_hit.wav` | Death Mark, ten seconds later: one knell as the marked falls. Heard once, final. | | |
| `q_pestilence` | -18.22 / -0.18 | +1.2 | -17.0 | `mix_q_pestilence.wav` | Pestilence: a swarm of flies and a cough. Sickness, not magic. | | |
| `q_ember` | -16.16 / -0.28 | -0.8 | -17.0 | `mix_q_ember.wav` | Ember, the cast: a thin hiss and crackle of a spark falling for 0.7 s. | | |
| `q_ember_hit` | -18.75 / 0.09 | +2.8 | -15.9 | `mix_q_ember_hit.wav` | Ember lands and the building catches: a soft whump of flame (replaces the dragon's ignition cue). | | |
| `q_noleave` | -16.54 / -0.20 | +0.5 | -16.0 | `mix_q_noleave.wav` | Leaving Is Prohibited: shackles rattling, then at 0.6 s a lock and an anvil clang as the wall seals. | | |
| `q_belllies` | -17.70 / -0.28 | +1.2 | -16.5 | `mix_q_belllies.wav` | The Bell Lies: a bell played backwards, swelling into an out-of-tune toll at 0.8 s. Should sound false. | | |
| `q_magnify` | -14.69 / -0.17 | -1.3 | -16.0 | `mix_q_magnify.wav` | Magnify: a lens swell, then at 0.9 s a chime struck twice, the second an octave up. | | |
| `q_abolition` | -16.52 / -0.43 | +1.0 | -15.5 | `mix_q_abolition.wav` | Abolition: a low swell for 1.8 s, then a gong, an anvil and breaking glass as the law is struck down. | | |
| `q_thorns` | -16.79 / -3.07 | -0.2 | -17.0 | `mix_q_thorns.wav` | Thornwall, the cast: a dry rustle and a wooden creak. | | |
| `q_thorns_hit` | -16.41 / -1.79 | -1.6 | -18.0 | `mix_q_thorns_hit.wav` | Thornwall, the brambles snap up: a whip crack. | | |
| `q_mirror` | -16.28 / -3.37 | -0.7 | -17.0 | `mix_q_mirror.wav` | Mirrorfold Passage, laid down: glass chimes and a high ring. | | |
| `q_mirror_hit` | -15.93 / -1.99 | -3.1 | -19.0 | `mix_q_mirror_hit.wav` | Someone steps through a mirror: a quick bright whoosh and ping. Plays at every crossing (3 voices): not tiring? | | |
| `q_madness` | -15.82 / -3.13 | -1.2 | -17.0 | `mix_q_madness.wav` | Madness Bloom, the cast: a murmuring wail that will not settle. | | |
| `q_madness_hit` | -15.22 / -1.98 | -0.8 | -16.0 | `mix_q_madness_hit.wav` | A frenzy breaks: a short horror scream and a snarl, once per new frenzy (3 voices at most). | | |
| `lantern_flare` | -14.59 / -0.30 | +0.6 | -14.0 | `mix_lantern_flare.wav` | The toll's flare at the Temple: a deep struck bell under a rising swell. Should read as an event, over the music. | | |
| `lantern_burn` | -15.76 / -0.23 | +1.3 | -14.5 | `mix_lantern_burn.wav` | The Lantern burns: a low whump, then a roar of flame. | | |
| `lantern_blind` | -16.05 / -0.29 | +0.5 | -15.6 | `mix_lantern_blind.wav` | The Bearer falls: a snuffed hiss, then a low bell. | | |
| `q_whisper` | -13.75 / -1.10 | -5.3 | -19.1 (floor -21.0) | `mix_q_whisper.wav` | Mind Whisper. A breath of voice in the dark, all air and hiss; the quietest of the twelve on purpose. Can you still hear it over the music? | | |
| `q_wisp` | -15.52 / -0.29 | -2.0 | -17.5 (floor -21.0) | `mix_q_wisp.wav` | Will-o'-Wisp. Four glass chimes climbing, like a light bobbing off down the street. Lures, so it should sound like an invitation. | | |
| `q_discord` | -16.83 / -0.29 | -0.7 | -17.5 (floor -21.0) | `mix_q_discord.wav` | Discord. Bells struck out of tune on top of each other, a glass shard in it: a clash, thoughts that will not agree. | | |
| `q_congregation` | -17.08 / -2.75 | +0.0 | -17.1 (floor -21.0) | `mix_q_congregation.wav` | Divine Congregation. A crowd murmuring as it gathers under a low church bell. Reads as a meeting called, not an attack. | | |
| `q_oath` | -16.27 / -0.32 | -0.7 | -17.0 (floor -21.0) | `mix_q_oath.wav` | Oathbound. A lock turning, a heavy clang and a chain: a vow sealed. Solid metal, not a magic sparkle. | | |
| `q_echo` | -17.61 / -0.26 | -0.4 | -18.0 (floor -21.0) | `mix_q_echo.wav` | Command Echo. One short shout handed on five times, each further off and duller. The repetition is the point. | | |
| `q_turncoat` | -15.20 / -0.12 | -1.8 | -17.0 (floor -21.0) | `mix_q_turncoat.wav` | Turncoat. A reversed rush of air then a drawn blade and a ring: someone changing sides. Sharp and quick. | | |
| `q_hatred` | -15.71 / -2.71 | -0.8 | -16.5 (floor -21.0) | `mix_q_hatred.wav` | Manufactured Hatred. A growl over an angry crowd murmur. Ugly, mid-low, close to a threat but with no flash. | | |
| `q_priority` | -18.72 / -4.34 | +0.2 | -18.5 (floor -21.0) | `mix_q_priority.wav` | Rewrite Priority. A page turned, two small marks written, a clear bell as it is set: an order rewritten. | | |
| `q_verdict` | -19.04 / -0.29 | +0.0 | -19.0 (floor -21.0) | `mix_q_verdict.wav` | Mob Verdict (the cast). Two knocks of a gavel and a bell. The ruling being made. | | |
| `q_verdict_hit` | -17.87 / -0.29 | +0.0 | -17.9 (floor -21.0) | `mix_q_verdict_hit.wav` | Mob Verdict (the fall). A heavy fall with a short crowd roar and a low bell, where the judged one drops. Quiet-power fall, not a death cry. | | |
| `q_delusion` | -14.51 / -1.16 | -2.5 | -17.0 (floor -21.0) | `mix_q_delusion.wav` | Collective Delusion. A bell played backwards swelling into a wavering theremin: reality bending. Peaks as the lie lands. | | |
| `q_voice` | -16.08 / -0.91 | +0.6 | -15.5 (floor -21.0) | `mix_q_voice.wav` | Voice of God. A deep, huge voice with a bass hit and a choir halo. The loudest of the twelve; still under a Heaven Splitter. | | |

Every quiet cast plays between the floor (-21.0) and the loud median + 2 (-12.6); the Lantern's three sit at the median or just under it. A hit sits within 3 LU of its cast. To re-measure: `python tools/audio/loudness.py`, then `python tools/audio/loudness.py --mix <cue>...`, and copy the numbers from `tools/audio/loudness.tsv`.

## In the game

1. **Title -> Options.** Each bar (Music, Sounds, Interface) moves; Sounds plays one Smite crack, Interface a click; closing keeps the setting.
2. **Last Judgement, a Nova into the market.** One wave of falling, a roar and three cries, not sixty cries.
3. **The Tax Collector, Silent Doom on a collector.** Hear the cast, then the fall; no cry from an unseen death.
4. **The Vigil Sandbox, each quiet power in turn.** Every cast has its own sound and none is lost under the music.
5. **The Warning, a toll.** The Lantern's flare at the Temple; kill the Bearer for the blind cue, or let the clock burn for the roar.
6. **The pause duck.** Pause a mission: the music ducks; open Options from the pause menu: the duck lifts so the Music bar is audible.
