# Task 7 report: emblem and power effects on the screen

**Status:** done, commit `6a75fe7a` on `claude/magical-lichterman-23d920` (not pushed).

## What
- `GodSelectArt.frame_set(prefix)`: probes `prefix_1`, `prefix_2`, ... , cached, empty when missing; `art_off` makes it empty.
- `GodSelectScreen`:
  - `EMBLEM_AT` is now (320, 200). Constants: `EMBLEM_FADE` 0.2, `FX_FPS` 12, `BURST_FRAMES` 8, `BURST_TIME = BURST_FRAMES / FX_FPS`
    (0.667 s, from the frame count and fps), `EMBLEM_FPS` 8, `FLASH_FPS` 12, `SPARK_FPS` 10, orbit and entrance constants.
  - State: `fx_age` (resets on a different pick only), `emblem_type()`, `fx_phase()`, `emblem_frame()`, `entrance_scale()`,
    `spark_count()`, `spark_angle(k)`, `spark_in_front(k)`, `spark_pos(k, bob)`. Spark orbit params are made once in `setup()`
    (seeded, like the leaves).
  - Drawing, before the statues: pulsing glow (three discs), two dashed ellipse rings on the pool (rx 46 / 39, drawn pixel by
    pixel), flipped half-height reflection at alpha 0.2, sparks behind (alpha 0.75) then the emblem (bob of 2 px, turn frames,
    scale-in under the flash) then sparks in front, then the flash. The old emblem fades out over `EMBLEM_FADE`.
  - The statue effect is drawn right after the picked statue's sprite (so after the statue, before its carved name), top left =
    `feet(i) - (56, 119)`, burst once then loop.
  - Missing frames: that piece is skipped (no emblem, no effect); the lit statue, picks and the rest work. No texture allocation per frame.
- Tests (`tests/test_god_select_art.gd`): emblem follows the pick; `fx_age` resets per new pick and not on a repeat; phase burst/loop
  using `BURST_TIME`; `BURST_TIME` equals the burst frame count / `FX_FPS`; quick picks 3,4,5 end in a running burst for 5;
  `emblem_frame()` advances with time; a new pick restarts the entrance (scale < 1, then 1.0); sparks split in front/behind by
  `sin(angle)`; frame-set counts (8/16/24/6/4), missing set empty, `art_off` empty; with `art_off` state still follows the pick.

## Tests
- Focused (`test_god_select_art` + `test_slot_screens`, 97 checks): 0 failures (includes the clockwise test around the new `EMBLEM_AT`).
- RED evidence: the new tests were written first, but I did not capture a clean RED log (the first run was swallowed by tool
  timeouts, and my first implementation attempt then failed to compile on a swapped `draw_texture` argument, which I fixed). So the
  tests were not cleanly watched failing. The first full part-8 run over the broken compile showed 2 failures, which is
  the compile breaking the suite, not a meaningful RED.
- Full suite (`run_suite_parallel.sh 8`): parts 1-5 and 7 green (11165 checks, 0 failures); parts 6 and 8 died with NO RESULT under load from other sessions (30 min timeout), so I re-ran them alone: part 6 = 1735 checks, part 8 (holds the god select tests) = 3231 checks, both 0 failures.

## Screenshots (not committed), scratchpad `.../scratchpad/t7_<type>_burst.png` and `t7_<type>_loop.png` for all six gods
Looked at ruin (burst), veil (burst), decree (loop): the emblem sits in the pool behind Decree's head, glow, rings, sparks
and flash read like `r2b_screen.png`; effects sit on the statue's feet behind the carved names; others dimmed.

## Concerns
- The reflection is faint (alpha 0.2 as in the mock), hardly visible on the dark pool.
- The old `_draw_statue` aura circles still draw under the picked statue (left as is).
- Scene tests that exercise the screen under heavy load take a long time in part 8.
