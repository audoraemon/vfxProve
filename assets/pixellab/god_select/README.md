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
