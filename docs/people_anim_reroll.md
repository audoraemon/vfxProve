# People animations: clips to re-roll later

Every clip below is rejected, missing or kept with a known flaw. The rejected and missing ones show a fallback until
re-rolled: a still stand from the idle frames (the back-view screams, and the marshal, escort and rescue during a
swing). The farmer swing (section 2) is in the game as it is; re-rolling it only improves its colours. Each direction costs 1 PixelLab
generation. Character ids are in `assets/pixellab/people/characters.json`.

## How to re-roll (the recipe that works)

`char-anim` skips any direction that already has frames under that animation (matched by template or name), and a
second group of the same name would overwrite the first one's files, so the old clip has to go first.

1. **Remove the old clip from PixelLab.** Either add `--replace` to `char-anim` (it deletes that name's frames for each of the
   given `--dirs` first; untested against the live API, so if it refuses, use the next), or call the MCP
   `delete_animation(character_id, animation_group_id, direction)` (group ids: `get_character`). A clip that is not
   generated yet (the soldier thrusts) needs no removal. Alternative for a v3 clip: generate under a temporary
   `--name <name>_rr` (a new group, no clash) and copy its folder over in step 3.
2. **Generate one direction:**

       python tools/dev/pixellab_api.py char-anim --id <id> --mode v3 --action "<action>" --frames 8 \
           --name <name> --dirs <direction> --replace --out <scratch dir>

   For a template clip: `--template cross-punch --dirs <direction> --replace --out <scratch dir>`.
3. **Fix the download so `--import` finds it.**
   - A template swing downloads into `<scratch dir>/cross-punch/`: copy its files into `<scratch dir>/swing/`
     (`--import` reads `swing/`, not `cross-punch/`).
   - A temporary `--name` folder: copy its files into the real folder name (`scream/` or `swing/`).
   - Delete the old `assets/pixellab/people/frames/<design>/<scream|swing>/<direction>_*.png` first, so the new frames
     are not mixed with stale ones (the import refits every direction of that folder from the download).
4. **Import and repack:**

       python tools/dev/make_people_atlas.py --import <design>=<scratch dir>

   (v3 clips come on a 28 x 28 canvas with the reference as frame 0; `--import` fits them to the 24 cell by the feet.)
5. **Un-reject:** for a back-view scream, delete the design from `_REJECTED_SOURCE` in `tools/dev/make_people_atlas.py`
   (`REJECTED` is built from it, with the mirrored direction), rerun `make_people_atlas.py`, import in Godot, and re-record
   whatever references move.

## 1. Back-view screams (9): rejected, silent fallback

The north-east scream shows the face, so it reads as facing south. The old frames stay on disk in
`assets/pixellab/people/frames/<design>/scream/north-east_*.png`. North-west mirrors north-east, so both back views use
the idle frames (the scream sound still plays). Re-roll the north-east direction only.

- mode: v3, name `scream`, frames 8, direction `north-east`
- action: `clutching head with both hands and screaming, staggering in place` (to push the back view, try appending
  `, seen from behind, face turned away`)

| design | character id |
|---|---|
| merchant_a | bc27b5a4-5ebc-4858-92a2-f4eaaaf13e75 |
| merchant_b | 49250f4e-6a60-4c8a-8eed-df43dab3fce5 |
| craft_a (also the wrong coat colour) | cdcc8e70-a828-47e5-94a3-9f5fc2801401 |
| craft_b | 5d1f1039-97b5-4970-9667-27ddbeb7af23 |
| clergy | fccf9349-607e-4448-aea1-31725c8fb57c |
| caregiver_a | 84a65599-8c26-4df8-8e6f-603b4b44ebb9 |
| caregiver_b (arms also wide) | 7f5c0cce-0514-4f01-9768-25cd3cd01f6f |
| bellkeeper | cb7bc68e-8058-4f8e-a92f-2445c251d2d7 |
| engineer (borderline) | c41ec230-6494-441a-94fe-d46f478d3d24 |

## 2. Farmer swing, south-east (kept, paler shirt)

The clip is in the game; re-roll it when budget allows. Farmer id `0b2d388b-9e50-46e5-9213-bea9957a9ac8`.

- mode: template, `--template cross-punch`, direction `south-east` (south-west mirrors it). Needs step 1 (remove) and the
  `cross-punch/` to `swing/` copy in step 3. Not in `_REJECTED_SOURCE`, so step 5 does not apply.

## 3. Soldier spear thrusts (6): not yet generated

The marshal, escort and rescue show their idle frames during a swing. Both directions for each (`south-east`,
`north-east`), the same as the guard. Nothing to remove first.

- mode: v3, name `swing`, frames 8
- action: `thrusting a spear forward then pulling it back`

| design | character id |
|---|---|
| marshal | a3122700-f4fd-4652-84ff-098c2db4a99a |
| escort | 549ef66a-6647-4035-9cdb-0839379a2caf |
| rescue | 414fb657-9e17-4a36-a50d-ed44664b8c3e |
