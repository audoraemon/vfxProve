# KAK god select restyle ("God's Paths") — design

Date: 2026-11-11. Branch: off `feat/god-progression` (not Develop-Main).

## Intent

The god select screen (`src/game/ui/god_select_screen.gd`) is six plain gold-framed boxes on a black screen. The user wants it to
feel like their reference image (`docs/superpowers/specs/assets/2026-11-11-god-select-reference.webp`): a ruined temple at
night where each god is a **stone statue on its own pedestal**, standing in a ring around a **glowing swirl**. Choosing a god
should feel like choosing an authority to serve, not picking a menu item.

The look must match the rest of KAK: **pixel art at 640×360**, not the reference's smooth painting. The user allowed PixelLab for
the art.

## What the user decided

- **Layout B** (from the mockups): the ring uses the whole screen, as now. The selected god's details sit inside the glowing centre,
  as now. There is no right-hand info panel and no statue close-up.
- **Background**: no plain dark fill. A pixel-art ruined temple at night, as in the reference: a moon, broken stone arches and an
  aqueduct behind, red autumn leaves at the screen edges, fire bowls (braziers) by the pedestals, mist over a wet stone floor, and
  light rays from above.
- **Statues**: one per god, grey stone, each with that god's coloured aura (cloth or smoke ribbons) and a hanging banner with its
  sign. From the reference:
  - **Ruin**: a crowned, muscular man reaching up, with falling rocks. Red-orange aura, burst sign.
  - **Passage**: a woman with orbs circling her hands. Blue aura, hourglass sign.
  - **Veil**: a hooded woman with a finger to her lips. Teal aura, eye sign.
  - **Decree**: a bearded man holding a stone tablet. Warm white-gold aura, scales sign.
  - **Death**: a hooded skeleton holding an hourglass. Pale green aura, skull sign.
  - **Dominion**: a crowned woman with arms spread. Purple aura, crown sign.
- **Nameplates**: each statue has a plate with the god's name and three verbs under it, as in the reference (see "Builder's calls"
  for the verb text).
- **Ring order stays the game's** (`GodTree.RING`): Ruin at the top, then clockwise Passage, Veil, Decree, Death, Dominion. The
  reference swaps Veil and Death; **do not** copy that. Neighbours do not change.
- **Title**: "GOD'S PATHS" with "CHOOSE YOUR AUTHORITY" under it, top left.
- **Buttons**: "‹ Back" bottom left, "Enter Path ›" bottom centre (this is today's Choose button).
- **Motion** (all of these):
  - the centre swirl turns slowly;
  - the fire bowls flicker;
  - a few leaves drift down;
  - the selected god's statue lights up (stronger aura, nameplate glows), the light rays move onto it, and the other statues dim.

## Goals

- The screen reads as the reference's place and mood at a glance, in KAK's pixel style.
- Each god is recognisable from its statue and colour, before reading its name.
- The selected god is obvious from across the room.

## Non-goals

- No rule changes: the type is still chosen once per slot; neighbours, tiers and the ring order stay as they are.
- No Divine Power counter, no "?" button, no right-hand panel (all in the reference, none wanted here).
- No restyle of other screens (skill tree, god hub). That can come later.
- No new controls: Left/Right, Enter, Esc and mouse clicks work as now.

## Anti-goals (failure even if it works)

- A smooth painted or blurry image dropped in: it must be pixel art that sits with the town art.
- Text that is hard to read over the busy background: the centre text and nameplates need their own dark backing.
- A slower screen: the motion must not drop the frame rate.

## Constraints

- **Resolution**: 640×360. Text uses `UiTheme`'s font, sizes and colours.
- **Code contract**: keep `GodSelectScreen`'s public parts that other code and tests use: `ring_rect(i)`, `CHOOSE_RECT`,
  `BACK_RECT`, `INFO_RECT`, `hit()`, `click()`, `select()`, `confirm()`, `type_lines()`, the `action` signal and `chosen_type`.
  The rectangles may move and grow (a ring "box" becomes the statue plus nameplate hit area). `tests/test_slot_screens.gd`
  checks that the ring boxes sit inside the frame, don't overlap the buttons or the centre panel, and that RING[0] is at the top
  with the ring running clockwise. `game.gd`'s dev paths click `ring_rect(0)` and `CHOOSE_RECT`. Those tests must still pass;
  update them only where a rectangle's new size needs it.
- **Text stays**: the centre shows today's four lines (name, flavour, Tier 1 powers, neighbours).
- **PixelLab budget**: 2000 generations a month, shared with other art work. Keep this job to a small share (aim under 150
  generations, re-rolls included).
- **Art files** go under `assets/pixellab/` (for example `assets/pixellab/god_select/`), like the other PixelLab art.
- **Landing**: commits on this branch, then fast-forwarded onto `feat/god-progression` only with the user's yes for the push.
  After the push, one dated bullet in Discord #god-changelog.

## Builder's calls (decided by Claude, not the user; flagged so the user can check)

- **Nameplate verbs**: from the reference, except Passage. The reference gives Passage "Conceal · Move · Manipulate", which repeats
  Veil's "Conceal". Use "Open · Move · Close" for Passage, from its flavour line ("Every way is yours to open or to close.").
  - Ruin: Destroy · Collapse · Erase
  - Passage: Open · Move · Close
  - Veil: Conceal · Obscure · Displace
  - Decree: Law · Bind · Enforce
  - Death: Wither · Harvest · Release
  - Dominion: Control · Command · Bend
- **Hover**: a hovered statue brightens a little (less than the selected one) and plays today's hover sound.
- **Light rays**: they slide to the newly selected statue over a short time (about a quarter second), not in one frame.
- **Hit areas vs art**: `ring_rect(i)` is the click area (statue body plus nameplate). The statue art, its aura and the light may
  draw past it and overlap the swirl, as in the reference. The ring boxes must still not overlap `INFO_RECT`, `CHOOSE_RECT` or
  `BACK_RECT`. Update `tests/test_slot_screens.gd`'s numbers only where the new layout needs it; its checks stay.
- **Centre**: the swirl shows fully around the text. The four lines sit on a soft, translucent dark backing just big enough
  for them, not on a box that hides the swirl (as in mockup B).
- **Ring shape**: all six statues are the same size, on an ellipse at 60° steps as now. The ellipse may be retuned to fit.
- **Existing lines kept**: "A god's type is chosen once, for this slot." stays (small, under the title), because it states a
  rule. The keys hint ("Left and Right look round the ring…") stays, small, at the top right (beside Back it would run into
  "Enter Path ›").
- **Enter Path**: stays bottom centre, clear of Decree's nameplate. `CHOOSE_RECT` may move; `game.gd`'s dev clicks use the
  constant, so they follow.
- **Art fallback**: each statue is its own generation (no recolouring one base). If generations run short, finish or fix by
  hand with PixelLab's free `pixelart_workbench`.
- **Missing art**: if a texture fails to load, the screen still works and draws today's boxes for that piece, so headless tests
  never depend on the art.

## Left to the builder

- The PixelLab tools, prompts, and sizes. Statues likely about 56–72 px tall; the background is one 640×360 scene or built from
  parts (sky, ruins, floor, side foliage).
- Whether the background is one image or layers, and whether motion is done with sprites, a shader, or `_draw`.
- How many leaves, how fast the swirl turns, how strong the dimming is.
- The exact new rectangles, as long as the constraints above hold.
- How to show the work for the user's judgement (in-game screenshots and a play through `play_dev.bat`).
