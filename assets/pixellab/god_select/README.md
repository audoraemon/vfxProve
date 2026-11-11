# God's Paths art (god select screen)

Art for the god select restyle (spec `docs/superpowers/specs/2026-11-11-kak-god-select-restyle-design.md`). Task 3's
`GodSelectArt` loads these files. Made 2026-11-11.

## Budget

- Balance before: **1598** generations left of 2000 (cycle resets 2026-12-02).
- Spent: **125** generations (plan cap: under 150). Balance after: **1473**.
- No re-rolls. Every PixelLab call went through `/generate-image-v2` (Create Image Pro), the same endpoint as
  `tools/dev/pixellab_api.py generate`, from a scratch wrapper that also allows an opaque background.

| Call | Size | Seed | Job id | Candidates | Generations |
|---|---|---|---|---|---|
| background | 640x360 | 1111 | 6b198dc1-18d2-4135-92cc-558ef757ef12 | 1 | 25 |
| statue_ruin | 64x80 | 2001 | 25f209dd-8ef3-4c7c-8de8-54a3a2647613 | 9 (picked #8) | 15 |
| statue_passage | 64x80 | 2101 | 5866f242-4fda-411b-9426-238ae937c08f | 9 (picked #0) | 15 |
| statue_veil | 64x80 | 2102 | 9af17f63-7dcd-4a37-922b-e1325ea53ca3 | 9 (picked #0) | 15 |
| statue_decree | 64x80 | 2103 | b0146d17-f7db-4b58-899d-ca9faf5cfb99 | 9 (picked #4) | 15 |
| statue_death | 64x80 | 2104 | 868759d4-9674-4161-b261-26678e9f98aa | 9 (picked #1) | 15 |
| statue_dominion | 64x80 | 2105 | f8901190-8932-4de4-9799-f067f92cc783 | 9 (picked #3) | 15 |
| swirl | 120x120 | 3001 | 5a9be58e-269d-4165-81ac-4c2ca72dc062 | 4 (picked #0) | 10 |
| brazier_1..4, leaf | | | hand-drawn (Pillow, pixel by pixel) | | 0 |
| **Total** | | | | | **125** |

## Files

### `background.png`: 640x360, opaque, 40 colours

The ruined temple at night, front view: moon top right, broken arches, a gateway and an aqueduct behind, red maple trees at the
left and right edges, a wet stone floor with mist, six empty stone pedestals on an oval and a dark pool in the middle.

- Prompt: "Detailed pixel art game menu background, front view, a ruined ancient stone temple courtyard at night. A pale full moon
  in the top right of a dark blue starry sky. Behind: broken grey stone arches, crumbling columns and a long ruined aqueduct with
  arches. Dark red autumn maple leaves on trees at the far left and far right edges. Wet dark stone tile floor reflecting
  moonlight, low mist over the floor. Six empty low square stone pedestals with steps standing in a wide oval ring around an
  empty dark centre. The middle of the image is dark and empty. Dim, moody, cold blue moonlight with no statues, no people, no
  text, no fire. Hard pixel edges, limited palette."
- Reference: a flat-shape layout guide (moon, arches, floor, red edges, dark centre, six pedestal blocks under Task 1's nameplate
  spots), usage "layout and composition only ... redraw all of it as detailed pixel art".
- No edits. The pedestals sit just under (and partly behind) the nameplates: the top one is behind the centre panel and swirl.

### `statue_<type>.png` x6: 64x80, transparent

Grey stone statues, front view, the same plinth and scale, light from the top left. **The plinth's bottom row is y = 79,
centred on x = 32**: draw each with its bottom centre on the nameplate's top edge (x = `statue_anchor(i).x`,
y = `ring_rect(i).end.y - 22`).

- Shared prompt: "Pixel art game sprite, front view, a grey stone statue of a god standing on a short square stone plinth at the
  bottom: <god>. Weathered grey stone, ... moonlight from the top left, dark outline, hard pixel edges, limited palette,
  transparent background." The five after Ruin add "the same statue style, size, plinth and proportions as the reference
  statue" and pass Ruin's pick as a reference ("art style, grey stone colours, figure size and proportions, the plinth and
  lighting: match exactly, but draw a different god").
- `<god>` per type:
  - ruin: "a crowned muscular bearded man with one arm reaching up to the sky, broken rocks falling around him. Glowing
    red-orange cloth ribbons of aura ... A small red hanging banner on his chest with a white starburst sign."
  - passage: "a serene goddess in long flowing robes with long hair, both hands raised open at her sides, small glowing blue orbs
    circling her hands. Glowing blue cloth ribbons ... banner ... white hourglass sign."
  - veil: "a hooded goddess in a long hooded cloak, one finger raised to her lips in a hush gesture, face half in shadow under the
    hood. Glowing teal smoke ribbons ... banner ... white eye sign."
  - decree: "an old bearded man in long robes holding a large stone tablet carved with writing against his chest with both hands.
    Glowing warm white-gold ribbons ... banner ... dark scales of justice sign."
  - death: "a hooded skeleton in a tattered hooded robe with a skull face, holding an hourglass in one bony hand. Glowing pale
    green smoke ribbons ... banner ... white skull sign."
  - dominion: "a crowned queen in flowing robes with both arms spread wide outward, commanding. Glowing purple cloth ribbons ...
    banner ... gold crown sign."
- Hand edits (free, deterministic):
  1. Re-centred so every plinth's bottom is y = 79 and its centre x = 32 (moves of 0-1 px across, 5-6 px down).
  2. Banners redrawn bigger: the generated ones were 4-5 px wide with unreadable signs. Each is now a 7 px wide pennant
     (9 px for Decree) under a gold rod, in the god's colour, with a 5x5 sign (Decree: 7x6 scales): burst, hourglass, eye,
     scales, skull, crown.
  3. Stone cooled to the background's moonlit blue-grey (hue 216, saturation x0.4 + 0.06, value kept) on the low-saturation,
     not-bright pixels only, so the coloured auras keep their colour.

### `swirl.png`, `rays.png`: removed in round 2

The centre swirl and the light rays were dropped (statues stand on the background's platforms; emblem and power effects replace them). The files were deleted; they stay in git history. Their spend (10 generations for the swirl) stays in the budget above.

### `brazier_1.png` .. `brazier_4.png`: 18x26, transparent

A stone fire bowl on a short stand with its flame: four flicker frames, the bowl and stand identical in each. Bottom centre
(x = 9, y = 25) is where it stands. Hand-drawn, 12 colours.

### `leaf.png`: 8x8, transparent

A red maple leaf for the drifting leaves (rotate or flip it in engine). Hand-drawn, 3 colours.

## Round 2: emblems and power effects (Task 6, 2026-11-11)

The effects are all drawn in code, pixel by pixel: `tools/dev/god_select_r2_art.py` (deterministic; run it to rebuild every file below,
`--preview <dir>` also writes contact sheets and GIFs). **0 PixelLab generations.** Balance before and after: **1473**.
Each god uses five tones of its own colour (dark to light, the middle one near `GOD_COL`), plus white for the hottest
pixels and four stone greys for Ruin's rocks. Edges are hard; the only see-through pixels are glow (a 2 px halo round the
bright parts) and Veil's mist and veil, all snapped to eight alpha levels.

### Emblems: replaced in round 2b (below)

The flat 48x48 `emblem_<type>.png` files were removed (the user found them too plain). They are still in git history.

### `fx_<type>_burst_1..8.png` and `fx_<type>_loop_1..16.png` x6: 112x128, transparent

| Set | Frames | fps | Length |
|---|---|---|---|
| `fx_<type>_burst_` | 8 | 12 | 0.67 s, once, on pick |
| `fx_<type>_loop_` | 16 | 12 | 1.33 s, seamless loop; burst 8 flows into loop 1 |

- **Anchor: (56, 119) = the statue's feet** (plinth bottom centre): frame top left = `feet(i) - (56, 119)`. The 8 rows
  under the anchor hold what spreads onto the platform top. The statue sprite sits at (24, 40) inside the frame.
- **Draw the frame in front of the statue, at full brightness, exactly on the anchor.** Parts that pass behind the
  statue (the far half of rings and orbits, back mist, Dominion's aura waves) are already cut out of the statue's
  silhouette, so they read as behind it. Normal alpha blend.
- Veil's frames carry the statue fade themselves: a dithered teal veil over the statue's silhouette, fading in and out
  once per loop (up to 45% mid-loop, gone at loop frame 1). No modulate needed.
- What each one does (spec Round 2):
  - ruin: a ground flash and shock ring, then glowing fire cracks run out over the platform and up the plinth, flames
    flicker on their ends, rocks are thrown up; the loop: magma pulses along the cracks, flames, rising embers, three
    small rocks lifted by the heat and crumbling.
  - passage: a flash at both hands; three orbs spin out of the hands onto an orbit round her waist while four more spiral
    out and fade, two rings widen out; the loop: three orbs orbiting with trails, two small orbs on a tilted inner orbit
    the other way, a widening dashed ring every 0.67 s.
  - veil: mist pours from the hood down the cloak and floods out over the platform, the statue veiled; the loop: mist
    tendrils curling out round the feet and winding up round the statue, the statue fading in and out.
  - decree: a big rune circle (rings, a hexagram, glyphs) comes down and stamps onto the platform with shards and a shock
    ring, a ring rises off it; the loop: the circle glows and turns one glyph per loop, a ring rises up the statue, gold
    motes.
  - death: a green ground flash and shock ring, eight souls torn up out of the platform winding round the statue; the
    loop: a faint soul pool with turning rim dashes, nine soul wisps (the big ones with eyes) rising with tails.
  - dominion: a flash at the chest, two aura waves pulse out from behind her, threads shoot out from the hands, sparks;
    the loop: two aura waves per loop, six thin threads from the hands swaying with sparks running out along them, a
    ground wave.

## Round 2b: living emblems (Task 6b, 2026-11-11)

Pre-rendered in code by `tools/dev/god_select_emblems.py` (deterministic; `--preview <dir>` also writes the sheet, a
screen grid and GIF mock-ups). **0 PixelLab generations.** Balance before and after: **1473**.

Each sign is modelled as a cast medal: its layers (body, inlays, jewels) are raised reliefs with bevels on a 4 px thick
solid. A small renderer spins it about its upright axis like a coin, lingering face-on and back-on and passing quickly
through edge-on. It is lit from the top left, with a rim light from behind right, so the light on the edges moves with
the turn. It renders at 4x and snaps each pixel to the god's six-tone ramp. The result is hard-edged and fully opaque,
with a dark 1 px outline. The back face shows the sign the right way round. The god's own touch is animated inside the
frames.

| Files | Frames | Size | Centre | fps |
|---|---|---|---|---|
| `emblem_<type>_1..24.png` | 24 = one full turn | 72x72 | (36, 36) | 8 (3 s), loops |
| `emblem_flash_<type>_1..6.png` | 6 | 96x96 | (48, 48) | 12 (0.5 s), once on pick |
| `emblem_spark_<type>_1..4.png` | 4 (twinkle) | 9x9 | (4, 4) | about 10, cycled per spark |

- The sign fills about 64x64 when face-on (the flames reach the top rows). It sits centred at **(320, 200)**, drawn
  before the statues, so Decree's head covers its lower edge.
- Frame 1 is face-on, frame 7 edge-on, frame 13 back-on and frame 19 edge-on.
- Touches:
  - Ruin: flames lick up off every top edge, and the core throbs.
  - Passage: grains of sand run down through the neck.
  - Veil: the lid blinks shut at frames 2-4, and the iris glows.
  - Decree: the beam tips about 7 degrees each way and the pans follow; the finial jewel glows.
  - Death: the eye sockets pulse green twice per turn, and a spark leaps at each peak.
  - Dominion: seven jewels and orbs take turns to flash a star glint.
- Flash: a white-hot core bursting into rays and a widening ring in the god's colours, with a soft glow. The emblem
  should scale in under it (frames 2-4).
- Sparks: a four-point twinkle with a white core and arms in the god's colour. They are opaque; fade them with
  modulate alpha.
- Left to the engine (mocked in the GIFs): the bob, the pulsing glow behind, sparks orbiting on an ellipse (the far half
  drawn behind the emblem), the ring of light and the flipped reflection on the pool, and the scale-in.
