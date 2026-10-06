# Handoff: PixelLab art for KAK (structures and people)

**For:** a new Claude session on **BURIN_NITRO** taking over from the session that ran on DESKTOP-0RLQN9A (2026-10-02 → 2026-10-03). Read this first, then the docs it links.

## Where things stand

- **Branch:** `feat/pixellab-structures`, pushed to `origin`. It was branched off `feat/vfx-proof` at `21c28c5`.
  - **Not merged anywhere yet.** The main line is now **`feat/Develop-Main`**; see the memory note "KAK branch roles".
  - How to bring it in, merge or cherry-pick, is the user's call (ledger card `p05`).
- **Where to work (BURIN_NITRO):** the worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-pixellab`. Godot is found through the `GODOT` environment variable (the console exe, `Godot_v4.7.2-stable_win64_console.exe`). Python 3.12 with Pillow is installed; `gh` is logged in.
- **What's done:**
  - **Batch 1:** cottages (red, blue), tavern, smithy, cathedral, the Citadel's keep, towers, walls and gateway; and every citizen and soldier (17 designs).
  - **Batch 2 (2026-10-03 to 10-04):** the town's walls, towers, corner towers, postern and gates; the 18 townhouses (two roofs); barracks; workshop; market stalls (three colours). See "Batch 2" in `docs/PixelLab_Structures_Proof.md`.
    - Each has intact, damaged and ruins stills. Barracks has a PixelLab collapse; the workshop has none yet; the defences use the engine's sink.
  - **F7** in the mission or town debug flips buildings and people between the new and the old art. `-- --art=procedural` starts old; `-- --collapse=engine` swaps the generated collapses for the engine's sink.
  - Gameplay is unchanged: the same hits and the same crowd behave identically with sprites on or off (tests prove it). Speed is level or better (mission bench 116.7 / 114.6 fps sprites against 113.6 / 113.9 procedural).
- **Checks at handoff:** `GODOT=... bash tools/test.sh` gives `checks=1473 failures=0` (the suite takes 150-270 s on the laptop; the runner's timeout is 400 s); `state_digest` = `61267b7e90524d800bf1c3473a71146b` (unchanged from before the work).
- **PixelLab budget:** 81 generations left. Batches 3 and 4 cost none (see below).
- **Later branches (2026-10-04 to 10-05), all free:** `feat/ref-re-texture` (the bell tower), then `feat/ref-batch3`, then `feat/decor-batch4`. Each is cut from the one before. They are pushed to `origin`.
  - **Merged:** all three are in `feat/Develop-Main` at `30b435c` ("reference-converted art (bell tower, batch 3) and decor batch 4 into Develop-Main").
  - **Worktrees:** `C:\BURIN_NITRO\Godot\GIT\vfxProve-ref3` (batch 3), `C:\BURIN_NITRO\Godot\GIT\vfxProve-decor` (batch 4).
  - **Checks at wrap-up:** tests `checks=2305` or more, `failures=0`; the digest is still `61267b7e90524d800bf1c3473a71146b`; no sprite over 5% glow.
- **Then `feat/art-animation`** (2026-10-05, cut from `feat/Develop-Main` 30b435c, which already contains those merges): animation, pushed. See "Art animation round" below.
  - **Tools:** `tools/dev/ref_convert/README.md`.

## Reference-converted batch 3 (`feat/ref-batch3`)

Spec: `docs/superpowers/specs/2026-10-04-ref-convert-batch3-design.md`. Sprites cut or drawn from the user's reference sheets (`concepts/TOWN REF/`), no AI. The user reviewed after each group. Collapse is the engine's sink; ruins are clean.

- **Group 1:** market stalls (12 designs, striped ones in red, blue, cream; the design follows the plot's place in `TownLayout.STALLS`, so neighbours differ), the fountain and the well.
  - This replaced the PixelLab stalls the user rejected. The old `stall_red` / `blue` / `cream` folders are unused.
- **Group 2:** street torches and lamps (`keep_flames`: the engine's flame and glow burn on the sprite), and trees (`tree_1..5` forest and meadow, `oak_1..3` town), with a crown sway.
- **Group 3:** the stone bridge (steps at both road ends) and the dock, drawn clean after the user's review. Both are flat and draw under people.
- **Group 4:** barn and carpenter (from the timber warehouse), windmill and watermill (bodies drawn clean, sails and wheel turn), and four farm fields (wheat sways).
- **Audit fixes (Task 15):** corner towers lose their painted torches and take the town tower's roof; the river waterfall was redrawn.
- **Engine:**
  - Idle strips run in the shader from a shared clock (`SpriteView`), so views need no processing; `EnvironmentField` owns the clock.
  - `Structure._sync_spin` lets sprite mills and fountains sleep.
  - Fields: damaged below `CRACK_AT`, ruins at once, no shadow.
- **Minors, not fixed:** `convert.py` has an unused `harmonize` param and a corner check that swaps sides on long plots. Striped stall designs 1-3 and 11 show damage weakly; design 11 is tall (84 px). The carpenter is mostly hidden by the south corner tower. Drawn mills are less painterly than cut sets. The well's ruins read as a flat disc. Ring sprite trees are smaller and brighter than the decor forest beyond. `test_sprite_art.gd:1023` has tabs mid-line.

## Decor batch 4 (`feat/decor-batch4`)

Spec: `docs/superpowers/specs/2026-10-05-decor-batch4-design.md`. Every `Decor.Kind` now has a sprite set, free and no AI. Sets live in `assets/pixellab/decor/` (57 folders) with `manifest.json`.

- **Now sprite (user OK'd groups 1 and 2; group 3 awaits review):**
  - **Goods and water:** barrels, crates (single and stacked), benches, market tables, log piles, carts, signpost, house-front lamps (lit lanterns), bunting, the ship, the rowing boats.
  - **Farm and animals:** fences (with a closing end post), house gardens (one still per plot size), scarecrow, sheep and cows (mixed by decor order, facing either way).
  - **Nature and forest:** bushes, rocks, flowers, reeds, the floor's small meadow shrubs and flower clumps, and the forest and town decor oaks and pines.
  - Almost all are drawn clean: cuts from the sheets were speckle at decor size.
- **Still procedural (effects only):** smoke, flames, glows, banners' sway and the lamp light pool. The decor `DOCK` kind stays procedural; the dock is a Structure since batch 3.
- **How it works:**
  - `DecorSprites` (`src/environment/art/decor_sprites.gd`) maps a decor piece to a set; `DecorArt.paint()` and `DecorArt.tree()` queue textured quads (`ArtKit.tex`) instead of polygons. Runs (fence, bench, bunting) tile a set's `segment`.
  - A down tree draws its `stump.png`; any other down piece draws nothing, as before.
  - Colour tint, charring and wind apply as they do to polygons (`wind.gdshader` sways by the texture's `UV.y`).
- **F7 covers decor:** live `Decor` nodes redraw, `TownFloor` re-bakes its detail layer (baked low decor and meadow shrubs), and `ForestLayer` redraws its bands. Cost: one hitch per toggle. After a toggle the floor is blank for one frame (minor).
- **The forest ruling:** the batch 3 tree sets halved the forest's crown size and cost ~6 fps through extra draw calls. So decor oaks and pines do not reuse them. They have their own forest-scale sets (`forest_oak_<n>`, `forest_pine_<n>`; `town_oak_<n>`, `town_pine_<n>` for the smaller house-back trees), and each family is packed into one runtime atlas (horizontal, bottom-aligned) so a forest band is one draw call. Draw calls went 1205 → 1040.
- **Speed:** within noise of procedural (decor 123.6 against batch 3 114.7 fps on the last pair; a noisy machine, 2-12 other Godot processes). Report medians.
- **Open minors worth knowing:**
  - The forest reads lighter and yellower than the procedural one, with slimmer pines. A felled stump splits a forest batch.
  - Goods are darker and heavier than the stalls; the `cart_1` sacks read as white balls; crates are 1.25x tall.
  - The `lamp_house` lantern dims with the decor layer at night while street lamp flames stay bright; its glow pool sits 8 px off the procedural one.
  - Sprite fences are slimmer than the procedural ones; garden fence 8 px against 9; boats are darker; bunting is denser.
  - Reeds are 1.15x taller; `bush_2` blossoms are bright; rocks are bright against the dark forest; `cow_2` has a dark ear patch.
  - Procedural boats may still lie across the river (a pre-existing issue; sprite boats follow the river).
  - Code: `ArtKit.tex` tests cover segment structure only; `reload()` can free an in-use texture or atlas (tests and tools only); `flipped()`'s doc names a `_herd_pick` that does not exist; `decor.gd:47-53` has a displaced doc comment.

## Art animation round (`feat/art-animation`)

Spec: `docs/superpowers/specs/2026-10-05-art-animation-design.md`. Worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-anim`, cut from `feat/Develop-Main` 30b435c. Free, no AI. The user approved groups A, B and D at their checkpoints; group C (animated decor) is finished and awaits review. Tool notes: the "Animation" section of `tools/dev/ref_convert/README.md`.

- **What animates now (sprites on):**
  - tower and keep bonfires flicker, and the barracks banner sways;
  - lit windows flicker softly: `cottage_red`, `cottage_blue`, `townhouse_a`, `townhouse_b`, `tavern`, `cathedral` and `citadel_keep` (the sets with a `glow_mask.png`). Barracks, workshop and smithy have no mask (no lit panes beyond 0-5 px of forge rim), so they do not flicker;
  - boats and the ship bob; reeds, bushes, flowers and small shrubs sway with the wind;
  - sheep and cows graze (1.5 fps), the scarecrow flutters and the ship's pennant moves; house lanterns flicker through their lit glass overlay (`lamp_house` itself is a still since art polish 2: its old strip only changed under that glass).
- **Still static, and why:**
  - **`citadel_gate` lanterns:** two small caged lanterns, glass with no open flame, so the flame finder skips them. They could flicker as lit glass through a window mask; not done.
  - **Bell tower:** no fire (its warm pixels are gold trim) and no lit panes, so no window mask.
  - **Gates** (`town_gate`, `citadel_gate`): idle-strip sets with no lit panes found, so no window mask.
  - **Strip sets** (`town_wall`, `town_postern`, the only sets with `"strip": true`): `window_glow.py` refuses them, since a piece draws more than one frame and the mask would stretch. The wall and postern torches stay the engine's `keep_flames`.
  - Damaged, ruins and collapse stills; "under" decor pieces (they stay baked).
- **Open minors worth knowing:**
  - A few tavern front panes are core-only, so their flicker is weak. The `townhouse_a` and `_b` masks are identical (recolours).
  - New tower strips run 6 fps, not the plan's 8, so adjacent towers flicker at one speed. The citadel_tower top brazier is clipped at y=0.
  - Procedural-mode tower-top glow differs 0.1-0.2% from before (light timing of extra objects); draw-only.
  - Plant layer: unstable sort on equal x+y; shrub-to-shrub order differs between bake and layer; short plants sway less.
  - Meadow shrubs in front of an animal draw under it. About 44 live pieces near pastures, 20 of them trees by cascade (outside the mission bench view); watch the live-node count.
  - The cow's half-way frame reuses the profile head; the scarecrow flutter is faint at 1x.
- **Frame rate (measured):** about **3-4 fps** below `feat/Develop-Main` 30b435c in the mission bench (vsync off; 4 pairs 134.3 against 130.0; bisect medians 133.0, 131.8 at the end of D, 130.3 in full). Roughly 1.2 fps comes from the plant layer (+26 draw calls) and 1.5 from animated decor. **Borderline against the ~3 fps budget**; reported to the user, who decides. Two other Godot processes ran, so the numbers are noisy. After the final review, the plant bands are four times coarser (59 segments to 26), so the branch draws +9-10 calls over Develop-Main in the mission bench instead of +25; procedural decor carries no material with sprites off. The fps re-bench was throttled; bench again on a quiet machine.
- **Checks:** tests 2861 or more with `failures=0` at the last checkpoint; digest `61267b7e90524d800bf1c3473a71146b` unchanged (the digest does not build the town).

## Read next

| Doc | What's in it |
|---|---|
| `docs/PixelLab_Structures_Proof.md` | The proof: what was replaced, how it works, criteria, findings, people, fixes, what's still open |
| `docs/pixellab_structures_log.md` | Every PixelLab call: prompt, seed, cost, pick, and the fix applied |
| `docs/superpowers/specs/2026-10-02-pixellab-structures-proof-design.md` and `…/2026-10-03-pixellab-people-design.md` | The designs, with the user's decisions |
| `docs/superpowers/plans/2026-10-02-pixellab-structures-proof.md` and `…/2026-10-03-pixellab-people.md` | The plans (the recipes for more components are there) |
| `assets/pixellab/buildings/manifest.json`, `assets/pixellab/people/manifest.json`, `assets/pixellab/people/characters.json` | Sprite sets (anchors, frames, chimneys, shadows) and the people's PixelLab character ids |

## Setting up BURIN_NITRO

1. **Repo:** in the clone, run `git fetch` and `git switch feat/pixellab-structures`.
   - The old PC worked in a separate worktree, `F:\Godot\Git\vfxProve-pixellab`, so it would not collide with another session in `F:\Godot\Git\vfxProve`.
   - If other sessions run in the same clone on the laptop, make a worktree again: `git worktree add ../vfxProve-pixellab feat/pixellab-structures`.
2. **Godot 4.7.2:** `tools/test.sh` and `tools/capture.sh` expect `/f/Godot/Godot_v4.7.2-stable_win64_console.exe`. Elsewhere, set `GODOT` to the console exe.
   - Run `bash tools/test.sh` once: it imports the project (atlases, sprites) and runs the tests.
3. **Python 3 + Pillow** for the tools (`pip install pillow`).
4. **PixelLab key** (the user adds it; never paste it into chat). Either:
   - `claude mcp add --transport http --scope user pixellab https://api.pixellab.ai/mcp --header "Authorization: Bearer <key>"`, or
   - set the `PIXELLAB_API_KEY` environment variable.

   `tools/dev/pixellab_api.py` reads `PIXELLAB_API_KEY` first, then the `pixellab` MCP entry in `~/.claude.json`. Check with `python tools/dev/pixellab_api.py balance`.

## Tools (all from the project root)

| Tool | Use |
|---|---|
| `tools/dev/pixellab_api.py` | PixelLab REST: `balance`, `generate` (Pro image, labelled refs), `edit`, `inpaint`, `animate`, `character`, `char-anim` (re-submits directions PixelLab dropped), `char-get`. Saves every image as PNG |
| `tools/dev/pixellab_batch.py` | Runs a JSON list of `pixellab_api.py` jobs, 4 at a time, re-queueing 429s |
| `tools/dev/render_sprite_refs.gd` | Today's procedural building per manifest entry, on its sprite canvas: the PixelLab composition reference (and placeholders) |
| `tools/dev/make_style_refs.py` | Style refs cut from `concepts/TOWN REF/TownMap_Component1.png` |
| `tools/dev/sprite_fix.py` | Image fixes: `shift` ruins onto the base, `corner` / `profile` to find a front corner, `unwhite` a white background, `largest` to drop a floating piece, `strip` to join frames, review sheets, and (batch 2) `tile`, `harmonize`, `stonemean`, `huemap` (next rows) |
| `sprite_fix.py tile <run> <still> <u0> <period> <span>` | Cuts a seamless wall strip from a long generated run; prints the size, anchor, footprint and period for the manifest |
| `sprite_fix.py harmonize <target> <box or all> <png> [...]` | Moves a sprite's stone colour toward a target (Lab), in place; `stonemean <png>` prints a sprite's mean stone colour |
| `sprite_fix.py huemap <src> <dst> <h0,h1> <palette png> <box> [...]` | Recolours a hue band from a palette (roofs, awnings): free colour variants |
| `tools/dev/banner_mask.py` | The keep's banner mask and its falling layer |
| `tools/dev/check_sprite_glow.py` | Guards the sprite shader's glow rule: no sprite over 5% "glowing" |
| `tools/dev/make_people_atlas.py` | Packs the people frames into the atlas; `--import <design>=<downloaded dir>` |
| `tools/dev/sprite_states.gd`, `tools/dev/people_states.gd` | Capture every building and every person through all their states |

## Recipes that worked

- **A building:**
  1. Add a manifest entry (canvas, footprint, height, seed, kind, role, tag) and render its reference.
  2. `generate` at the canvas size with two refs: the reference ("exact footprint, iso angle…, keep this composition") and the style crop ("art style only…").
  3. Pick a candidate that doesn't clip the canvas. Find its front corner (`sprite_fix.py profile`, `footprint`) and set `anchor`.
  4. `edit` it twice, damaged and ruins. Ruins come back 5–22 px high: `sprite_fix.py shift`.
  5. `animate` from damaged to ruins, 8 frames (1–4 generations), then `strip` it to `collapse.png` and set `collapse_frames`.
- **A wall strip (batch 2):**
  1. Generate one long run, wider than the plot.
  2. Find `u0` and the `period`: match columns at the same merlon of the next repeat (keep torches out of the repeated band); the period must be a multiple of 1/16.
  3. `sprite_fix.py tile <run> <still> <u0> <period> <span>` prints size, anchor, footprint and period; put them in the manifest with `strip` and `period`.
- **Fill the footprint:** PixelLab draws at 0.8-0.9x the plot. Measure the base corners against the diamond (`corner`, `profile`) and hand-fit by pixel copy before spending a regenerate.
- **One palette:** `harmonize` each set toward the town stone (`stonemean` reads it); `huemap` makes colour variants (townhouse_b, stall_blue, stall_cream) at 0 generations.
- **Door variants:** composite them locally on the tower stills (2 inpaints for the art, the rest free), named `..._door_<e|e_hi>_<s|s_hi>`; `TownLayout` tags the tower, `SpriteArt.name_for` maps the tag.
- **A set (the Citadel):** pass the first good part as a third reference ("the same castle: match this tower's stone…"). Otherwise parts drift in style.
- **A person:**
  1. `character --size 16` (1 generation).
  2. `char-anim` per template (`breathing-idle`, `walking-4-frames`, `running-4-frames`, `crouching`, `falling-back-death`), 4 diagonals at 1 generation each.
  3. `make_people_atlas.py --import`.
  - Small props can vanish at 16 px; say them loudly ("holding a big iron shovel in both hands, no spear, no shield").

## Open work (KAK Dev Ledger, https://claude.ai/artifact/6zL2bsrt3H1Vnehk1RkfiK)

- **Art animation, needs the user:** review group C (animals, scarecrow, lantern, pennant) and decide on the 3-4 fps cost (about 1.2 plant layer, 1.5 animated decor; borderline against ~3). Then merge `feat/art-animation` into `feat/Develop-Main`, with a trial merge on a throwaway commit first. Optional: flicker the `citadel_gate` lanterns.
- **Market stalls:** the PixelLab stalls were rejected (crowded, uniform produce) and are replaced on `feat/ref-batch3` by 12 converted designs. The old `stall_red` / `blue` / `cream` assets stay unused.
- **`p05`, needs the user:** bring the PixelLab art into `feat/Develop-Main`, by merge or cherry-pick.
- **Merge the reference work, needs the user's approval:** `feat/ref-re-texture` → `feat/ref-batch3` → `feat/decor-batch4`, in that order, into `feat/Develop-Main`. Run a trial merge on a throwaway commit first (memory note "Trial merge needs a commit").
- **Decor group 3 review:** the user has not yet signed off on nature and forest (bushes, rocks, flowers, reeds, forest trees). Send captures; the wrap-up docs are written, but the group is not approved.
- **`p07`, mostly done without AI:** carpenter, barn, bell tower, windmill, watermill, fountains, wells, torches, lamps, bridge, dock and decor are all sprite now (batches 3 and 4).
  - Still open: the workshop's collapse (and smoke).
  - 81 generations are left; a set costs 60-65.
  - The cathedral is capped near 256 px and undersized for its plot; generating it in two parts would fill the plot.
- **Known and accepted:**
  - the damaged keep's bare patches are a shade paler than the wall;
  - mirrored cottages have their sunlight on the opposite side;
  - sprites take effect light evenly, not per wall face.

## Conventions this work followed

- **Commits:** stage files by name, never `git commit -a`. A shared folder once swept another session's file into a commit. Messages end with the `Co-Authored-By` trailer.
- **Tests:**
  - `bash tools/test.sh` after each change.
  - The runner doesn't count a GDScript runtime error as a failure, so watch the check count, or grep for `SCRIPT ERROR`.
  - Prove gameplay is unchanged with `tools/dev/state_digest.gd`, not screenshots.
- **Ledger:** update the KAK Dev Ledger after each feature, fix or decision (memory note "KAK Dev Ledger").

## The old session

The conversation's own history is a Claude Code transcript. It doesn't move between machines by itself; a copy is in OneDrive (`ClaudeHandoff`) with a README on resuming it from the Claude Code CLI. A fresh session reading this file and the linked docs doesn't need it.
