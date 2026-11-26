# KAK God's Chamber, step 7: life and state objects (design)

Date: 2026-11-26. Branch `feat/god-chamber`. Follows the Chamber design (`2026-11-19-kak-god-chamber-design.md`, step 7: "idle life
and state objects in the room: flames, portal, candles per milestone") and the painted room of step 6 (`assets/chamber/wall.png`,
`desk.png`, built by `concepts/chamber/build_chamber_art.py` from one PixelLab painting).

## 1. Goal

The painted room is a still picture. Make it breathe (idle life), and make it show how far the god has come (state objects), so a
player reads their progress from the room before reading the top bar. No new painted art and no PixelLab: everything is derived
from the existing painting or drawn by code.

Success: the room visibly lives at rest; each state object changes when its state changes; the user approves captures of every
state; the suite and FLOW pass; no replay reference moves (the room changes no night).

## 2. Approach

Light masks and patches cut from the painting itself, plus a few code-drawn particles.

- The build script gains a `life` pass. For each light source it writes a **glow mask**: the painting's own lit pixels around that
  source (warm or bright pixels within a radius), as a white-alpha PNG in `assets/chamber/life/`. Drawn additively with a varying
  alpha, a mask makes the painted light itself flicker, so the motion always matches the art.
- It also writes **patches** for states the painting does not show: an unlit candle (flame and glow removed, wick dark), a dull
  trophy (darkened and desaturated). Same method as `awaken_closed.png` in step 6.
- Small moving things (sparks, dust motes, star twinkles, falling sand) are drawn by code as 1-unit pixels in palette colours.

Considered and not chosen: hand-made animated frames (needs new art); one big shader on the wall (harder to test and to tune per
source). The mask method can move to a shader later without changing the data.

## 3. Idle life (always on at rest)

Positions are room units (the 840 x 360 room; see `ChamberLayout`). All life rides the wall's layer, so it moves with parallax.

| Source | Where (room) | Motion |
|---|---|---|
| Altar brazier | (590, 215) | Strong flicker (glow mask alpha 0.7-1.0, smooth noise); 2-4 sparks rise and fade (0.8-1.5 s each). |
| Altar candles (5) | around the brazier | Gentle flicker, each with its own phase; only lit candles flicker (see 4). |
| Shelf candles (3) | (515-535, 165-190) | Gentle flicker. |
| Desk candle | (75, 285-330) | Gentle flicker; its light on the desk breathes with it. |
| Hanging lantern | (315, 45-90) | Slow breathe (4 s). |
| Rite Door light | (120-235, 95-260) | Lit door only: the crack pulses (2.5 s) and dust motes drift slowly in its beam. Closed door: still. |
| Ability Tree runes | (-10-55, 120-300) | Slow purple pulse (3 s). |
| World table map | (208-420, 232-260) | A soft band of light sweeps across the water (8 s); the town pins twinkle. |
| Window | (265-355, 105-230) | A few stars twinkle; thin shimmer lines move on the sea. |
| Hourglass | (605-635, 295-350) | A 1-unit stream of sand falls. |

Comfort limits: no light changes faster than 3 times a second; a pulse is never shorter than 2 s; brightness moves by at most 25%.

## 4. State objects (show progress)

| Object | Shows | Rule |
|---|---|---|
| The five altar candles | The god's tier | Tier k: k candles lit, left to right; the rest unlit (patch, no glow). Tier 5: all five. |
| The two trophies on the top shelf | Conquered towns (Conquer Progress) | One cup per town in `Conquest.towns()` order (Aldermere, the Capital). Conquered: bright gold, a glint sweeps it every 6 s. Not yet: dull. |
| The hourglass | The Lantern's Notice | Sand in the lower bulb fills with `notice_fill()` (0-1). When the Hunt is due the glass glows red and pulses. |
| The window | The Hunt | When the Hunt is due the sky takes a red tint and the moon dims. Otherwise the night sky as painted. |
| The brazier | Faith to spend | Burns higher (taller flame, more sparks) while Faith can buy at least one row (the Faith badge's rule). |
| The Ability Tree runes | Points to spend | Pulse brighter and faster (2 s) while the god has unspent points (the Tree badge's rule). |
| The Rite Door | A rite is ready | Already lit or closed (step 2); adds the pulse in section 3 when the door is lit and not dim. |

The badges and the top bar stay as they are; the objects repeat their news in the room. The empty arched niche right of the window
(room 380-440, 120-220) stays empty: it is kept for step 9 (each god's idol).

## 5. Structure

| Unit | File | Job |
|---|---|---|
| Build pass | `concepts/chamber/build_chamber_art.py` (`life` section) | Writes `assets/chamber/life/<source>_glow.png` and the patches (`candle_out_<i>.png`, `trophy_dull_<i>.png`); prints a contact sheet for review. |
| `ChamberLife` | `src/game/ui/chamber_life.gd` (new, RefCounted, pure) | The table of sources (name, rect, kind, period); `state(slot, status) -> Dictionary` (lit candles, gleaming cups, sand level, hunt, brazier high, tree fast); `frame(t) -> Array` (what to draw at time t: mask alphas, particles). No nodes, no clock of its own: time is passed in. |
| `GodChamber` | `src/game/ui/god_chamber.gd` | Keeps a running time, asks `ChamberLife` for the frame and draws it on the wall's layer after the wall, before outlines, badges and the bar. Additive pieces go on one child canvas item with an add blend. |

## 6. Switches and edge cases

- `ChamberLife.moving` (static, default true): off in FLOW, `--capture` and headless runs, like `GodChamber.transitions`. Off, the
  room is drawn at t = 0: state objects are still shown (so captures show state), only motion stops.
- Particles use their own seeded random, never the game's, so nothing in a night can change.
- During zoom transitions life keeps running and is scaled with the room.
- A missing mask or patch file: that source is skipped silently (like a missing texture today).
- Cost: at most about 40 draw calls a frame for life; target under 0.3 ms of a frame on this machine.

## 7. Tests

`tests/test_chamber_life.gd`:
- every source rect lies inside the room; every mask and patch file exists and matches its rect's size;
- tier 1-5 gives 1-5 lit candles (and clamps outside that range); conquered towns give gleaming cups in order; `notice_fill` sets
  the sand level; Hunt due turns the window and hourglass red; the Faith and points rules match the badges' rules exactly;
- the same t gives the same frame; with `moving` off the frame does not change with t; flicker alphas stay within their bounds and
  no pulse period is under 2 s;
- life pieces move with the wall's parallax shift.

Plus captures for the user (art rule): the room at rest at tier 1 and tier 5, a conquered and an unconquered Capital, the Hunt due;
and a short animated strip of the idle life.

## 8. Order of work

1. Build pass: masks and patches; contact sheet to the user.
2. `ChamberLife` and its tests.
3. Drawing in `GodChamber`.
4. Room sound (section 9).
5. Captures, the animated strip and the sound takes to the user; tune on their word.
6. Suite and FLOW; refs untouched (spot-check the digest).

## 9. Room sound

The user asked for a fire crackle and any sound that makes the working room more alive.

- **Bed:** one quiet room loop on the Ambience bus while the Chamber is shown: the brazier's crackle and a soft room tone, from
  the existing fire recordings (`amb_fire`, `fire_burn_*`) and the library's CC0 sources, built by `tools/audio/foley.py` like
  every other bed. It fades in with the room and out when a page opens; it ducks under the music.
- **Occasional room sounds**, one every 8-20 s, never the same take twice in a row, quiet, panned to where they happen:
  a candle sputter (near a lit candle), a log settling in the brazier (louder while it burns high), wind against the window
  (a red Hunt sky makes it a low moan instead), the hourglass's sand hiss, a page turning on the desk, a quill scratch, the lantern's
  chain creaking.
- **State sounds**, once when the state is first seen on entering the room: a soft chime when a trophy gleams for the first time;
  a low swell when the Hunt is due.
- Sources: only CC0 / public-domain library sounds or synth renders (the repo is public; no Sonniss, no Stable Audio output).
  Credits in `assets/audio/CREDITS.md`.
- Switches: silent in FLOW, `--capture` and headless runs (like the music); a calm-minute probe counts what plays (at most about
  6 occasional sounds a minute).
- Tests: every room cue is in the Sfx catalog with its takes; the bed starts and stops with the room; no back-to-back repeat;
  the probe's count stays in bounds.

## 10. Decisions (the user, 2026-11-26)

1. Candles count the tier: yes.
2. Trophies mark conquered towns; a third town later needs a third cup painted: yes.
3. Hourglass = the Lantern's Notice; window and hourglass turn red when the Hunt is due: yes.
4. Room sound: yes, the fire crackle and other sounds that make the room alive (section 9).
