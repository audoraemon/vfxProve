# Town lighting proof: day and night looks — design

**Date:** 2026-10-24
**Branch:** `feat/town-lighting`, worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-lighting`, cut from `feat/Develop-Main` 617ec822.

## Why

The user wants the town to look more real while staying pixel art. Their reference is a ChatGPT picture of a medieval town at dawn in light mist: sunbeams slant from the top-left through mist over the forest, rooftops catch warm low light, windows glow amber, and soft shadows stretch across the streets.

Asked what makes the reference feel real where ours feels flat, they said: **"the shadows and the warm sunlight with mist."** For night they want **"warm lamp light from windows and torches, cool moonlight."**

This is a **proof of the look**. It is not a time-of-day system.

## Decisions (user, 2026-10-24)

- **Two fixed looks:** day and night. There is no light changing during play. Later a mission picks one when it starts (at the descent); that hook is out of scope here.
- **Day:** cast shadows, warm sunlight, mist with faint sunbeams.
- **Night:** cool moonlight, with warm light pools from windows, wall torches, lamp posts and bonfires.
- **Stays crisp pixel art:** hard edges, nothing blurred or smeared, no art repainted.
- **Where it shows:** a new branch, shown in the town debug view and one mission, with before/after captures.

## What the player sees

### Day

1. **Cast shadows.**
   - Every standing structure casts a shadow onto the ground: buildings, walls, towers, gatehouses, trees, stalls, the Citadel. Shadow length follows the structure's height.
   - Light comes from the upper left, matching how all the art is lit, so shadows fall **down and to the right** on screen.
   - Shadows are flat pixel shapes in one darkness level, crisp-edged. Where shadows overlap they don't stack darker.
   - People get a small shadow under their feet.
   - A destroyed or ruined structure casts a low ruin-height shadow, or none.
   - Today a structure draws only a small contact shadow (its footprint nudged by (6,-3); `Structure._shadow()` / `_sprite_shadow()`). The new cast shadow replaces it in the day and night looks. The current look keeps it.
2. **Warm sunlight.**
   - The scene shifts to a golden, early-morning light.
   - Sunlit ground and the left faces and roofs of buildings read warm. Ground in shadow reads cooler and slightly blue.
   - This warm/cool split is the main effect.
3. **Mist and sunbeams.**
   - Thin, slowly drifting mist sits in the forest ring, by the river and harbour, and in the new border band. It is thicker toward the map's edge, and the town centre stays clear.
   - Faint diagonal sunbeams slant from the top-left through the mist.
   - Both are pixel-stepped (dithered or banded alpha, not smooth gradients) and subtle enough never to hide people, tags or targets.

### Night

1. **Cool moonlight.**
   - The scene goes dark blue-grey.
   - Moonlight comes from the same upper-left direction: the same cast shadows, drawn fainter and cooler.
2. **Warm lamp pools.**
   - Every light the game already registers (`LightField.add_static`: wall torches, lamp posts, bonfires, braziers) throws a warm pool onto the ground, nearby walls and people.
   - Lit windows (the `glow_mask` sets) glow, and give a small pool in front of the building.
   - Inside a pool, colours come back warm; between pools the town stays cool and dark.
   - Pools are pixel-stepped rings (a few bands), not smooth gradients.
3. **Mist at night.** Thinner and grey-blue. Near a lamp pool it catches the warm light.

### Current look

The game as it is today (`Town.EVENING` / `GROUND_EVENING` tint, contact shadows) stays available, unchanged and the default. The proof adds the two new looks beside it.

## How it is built (my calls)

- **Shadows from geometry, not Godot's Light2D shadows.** Godot's 2D occluder shadows are top-down and point the wrong way in our 2:1 iso view.
  - Each structure's shadow is its footprint swept along the sun direction by `height × k`, as a polygon in screen space: the footprint's top outline extruded down-right.
  - Draw them into one shadow layer **under** every structure and person and **over** the floor and plants.
  - The layer is drawn once into a mask, at one alpha, so overlaps don't stack.
  - Shadows are rebuilt only when a structure changes state (destroyed, ruin), never per frame.
  - Trees in the forest band get a shadow blob each, drawn in the same layer.
- **One full-screen grade pass** at game resolution (640×360), a CanvasItem shader over the world and under the HUD.
  - Day: warm the lit areas and cool the shadow mask.
  - Night: darken toward moonlight blue, then add the lamp pools.
  - The lamp pools come from a small light texture built from `LightField`'s static lights and the window masks, drawn additively at low resolution with stepped falloff.
  - It must run in GL Compatibility.
- **Mist and beams** are a few large textured quads with drifting, pixel-stepped noise, placed by city data: the forest ring, the river and harbour, the border band.
  - They read the city through `City.current()` if that has landed (v0.12 M1). Otherwise they use `TownLayout`, as everything else on this branch does.
- **A look switch:** `Town.look`, one of CURRENT, DAY or NIGHT. It is set by a `--look=day|night` argument and toggled by a dev key (L) in the town debug view and in missions. The current look is the default, so nothing changes for players.
- **The sprites' own light** (`LightField.tint`/`ambient`, the window glow shader, `SpriteView` light) stays. Each look sets its own tint and ambient so sprites and the grade agree.
- **No gameplay change.** No RNG draws, no walk-grid or structure-state change. The deterministic references must stay exact, because the default look is CURRENT and headless runs draw nothing.

## Rules settled after review (my calls)

1. **The mission is Last Judgement**, the free-play skirmish.
   - **Choosing the look:** a mission takes its look from `--look` only. The L key is a dev key in the town debug view, and it rebuilds the town in the next look (as R rebuilds it today).
   - **Grade layer:** the grade sits over the world and under `Battlefield`'s glow, post and flash layers and the HUD. Spell glows and flashes therefore stay bright at night.
2. **Shadows, lamp pools, window pools and mist are world-space geometry** under the camera.
   - They scale and pan with the art, and their pixel steps are world pixels, the same as the sprites'.
   - Only the colour grade is a screen-space pass. It is a colour transform with no positions, apart from reading the shadow and light masks.
   - Static pools are built once at town build; torch flicker only modulates their alpha.
3. **Window pools come from the art, not `LightField`.**
   - For each standing building whose set has a `glow_mask`, draw one small warm pool on the ground at the front edge of its footprint, sized by the mask's lit pixel count.
   - Nothing is registered in `LightField`, so `sample()` and every behaviour reference are unchanged. Torch, lamp and bonfire pools read `LightField`'s existing static lights, read-only.
4. **`Structure.height` is in game pixels, like the art.**
   - The cast shadow is a screen-space shear: the footprint diamond plus its copy shifted by `height × k` along the sun direction (down-right). The union of the two, plus the hull between them, is the shadow.
   - Each Citadel part casts its own.
   - Flat or walkable kinds (fields, bridges, paving) cast none.
5. **Layer order:** floor, plants and the forest floor; then the **shadow layer**; then the depth-sorted structures, people and forest trees.
   - Trees cast their blobs into the shadow layer.
   - Shadows fall on the ground and the plants, never on top of buildings or people.
6. **People's shadows are not in the mask.** Each person draws its own small foot shadow in its own `_draw`, in DAY and NIGHT only. That costs nothing per frame beyond one small quad each, and the mask stays static.
7. **A look is chosen at build time.**
   - DAY and NIGHT bake the floor, plants and forest with **no evening tint** (neutral). The look's grade supplies the colour.
   - `LightField.tint` and `ambient` are set per look, so sprites match.
   - CURRENT bakes exactly as today.
8. **Nothing exists in CURRENT.** The grade, shadow layer, pools and mist are created only when the look is not CURRENT, so headless runs and every reference are untouched.

## Proof

- **Captures:** town debug captures in all three looks at the same camera spots: overview, market, Citadel, river and bridge, the forest edge, a night street with torches. Also the same in one mission.
- **The judge is the user's eye against the reference.**
- **Bench:** Aldermere in DAY and NIGHT against CURRENT. It must stay within about 3 fps, on a quiet machine.

## Pass when

1. The user sees the before/after captures and says the day look has the reference's shadows, warm light and mist, and the night look has warm lamp pools in cool moonlight.
2. The look stays crisp pixel art: no blur, no smooth gradients.
3. CURRENT is unchanged.
4. All tests pass, all references are exact (`tools/dev/refs_check.sh`), and FLOW passes.
5. The bench is within about 3 fps.

## Out of scope

- A day/night cycle or any light changing during play.
- Mission choice of look and the descent hook.
- Repainting or regenerating any art. No PixelLab.
- Light2D-based dynamic lights.

## Notes for the builder

- **Branch timing:** another session will land v0.12 M1 ("Many Towns") on Develop-Main soon, tag `kak-v012-m1`. It touches the town and crowd code (`City.current()`).
  - Before Task 1, check whether it has landed. If so, cut from it, or merge it in.
  - Before landing this branch, merge it in, then re-gate.
- Left to the builder: exact colours, the shadow length factor, mist density, pool radii and the number of stepped bands, all tuned by eye on the captures.
