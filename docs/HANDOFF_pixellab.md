# Handoff: PixelLab art for KAK (structures and people)

**For:** a new Claude session on **BURIN_NITRO** taking over from the session that ran on DESKTOP-0RLQN9A (2026-10-02 → 2026-10-03). Read this first, then the docs it links.

## Where things stand

- **Branch:** `feat/pixellab-structures`, pushed to `origin` with all the work below. It was branched off `feat/vfx-proof` at `21c28c5`.
  - **Not merged anywhere yet.** The main line is now **`feat/Develop-Main`**; see the memory note "KAK branch roles".
  - How to bring it in, merge or cherry-pick, is the user's call (ledger card `p05`).
- **What's done:**
  - **Buildings** from PixelLab sprites: cottages (red, blue), tavern, smithy, cathedral, and the Citadel's keep, towers, walls and gateway.
    - Each has intact, damaged and ruins stills.
    - All but the cathedral play a PixelLab-generated collapse.
    - Gravity sinks and squeezes, and the laser slices, in-engine.
    - The keep's banners fall at the Citadel's 20%.
  - **People:** every citizen and soldier, 17 designs (all 9 citizen roles, 2 looks for the big ones; guard, marshal, escort, rescue).
    - Idle, walk, run, stumble and death, in 4 diagonals.
    - Every effect is drawn on top.
  - **F7** in the mission or town debug flips buildings and people between the new and the old art. `-- --art=procedural` starts old; `-- --collapse=engine` swaps the generated collapses for the engine's sink.
  - Gameplay is unchanged: the same hits and the same crowd behave identically with sprites on or off (tests prove it). Speed is level.
- **Checks at handoff:** `bash tools/test.sh` → `checks=1333 failures=0`; `state_digest` = `61267b7e90524d800bf1c3473a71146b` (unchanged from before the work).
- **PixelLab budget:** 873 of 2000 generations left on the user's plan (1127 used, itemised in the log).

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
| `tools/dev/sprite_fix.py` | Image fixes: `shift` ruins onto the base, `corner` / `profile` to find a front corner, `unwhite` a white background, `largest` to drop a floating piece, `strip` to join frames, and review sheets |
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
- **A set (the Citadel):** pass the first good part as a third reference ("the same castle: match this tower's stone…"). Otherwise parts drift in style.
- **A person:**
  1. `character --size 16` (1 generation).
  2. `char-anim` per template (`breathing-idle`, `walking-4-frames`, `running-4-frames`, `crouching`, `falling-back-death`), 4 diagonals at 1 generation each.
  3. `make_people_atlas.py --import`.
  - Small props can vanish at 16 px; say them loudly ("holding a big iron shovel in both hands, no spear, no shield").

## Open work (KAK Dev Ledger, https://claude.ai/artifact/6zL2bsrt3H1Vnehk1RkfiK)

- **`p05`, needs the user:** bring the PixelLab art into `feat/Develop-Main`, by merge or cherry-pick.
- **`p07`, needs the user:** convert the rest. Still procedural:
  - town walls, towers and gates (~400 generations);
  - bell tower and 18 townhouses (~200);
  - barracks, workshop, carpenter, barns, mills, stalls.
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
