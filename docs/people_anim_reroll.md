# People animations: clips to re-roll later

Every clip below is rejected or missing. The game shows a fallback until it is re-rolled (a still stand from the idle
frames, or the old fight pose). Each direction costs 1 PixelLab generation. Character ids are in
`assets/pixellab/people/characters.json`.

Re-roll recipe (from the project root; each call is one direction):

    python tools/dev/pixellab_api.py char-anim --id <id> --mode v3 --action "<action>" --frames 8 \
        --name <name> --dirs <direction> --out <scratch dir>
    python tools/dev/make_people_atlas.py --import <design>=<scratch dir>

v3 clips come on a 28 x 28 canvas with the reference as frame 0; `--import` fits them to the 24 cell by the feet.
After a successful re-roll, delete the design's entry from `REJECTED` in `tools/dev/make_people_atlas.py`, rebuild the
atlas and re-record the references that move.

## 1. Back-view screams (9): rejected, silent fallback

The north-east scream shows the face, so it reads as facing south. Frames stay on disk in
`assets/pixellab/people/frames/<design>/scream/north-east_*.png`. North-west mirrors north-east, so both back views
use the idle frames (a still stand; the scream sound still plays). Re-roll the north-east direction only.

- mode: v3, name `scream`, frames 8, direction `north-east`
- action: `clutching head with both hands and screaming, staggering in place` (same as the south-east clip; to push the
  back view, try appending `, seen from behind, face turned away`)

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

- mode: template, template id `cross-punch`, name `swing`, direction `south-east` (south-west mirrors it)

## 3. Soldier spear thrusts (6): not yet generated

The marshal, escort and rescue designs show their old fight pose. Both directions for each (`south-east`,
`north-east`), the same as the guard.

- mode: v3, name `swing`, frames 8
- action: `thrusting a spear forward then pulling it back`

| design | character id |
|---|---|
| marshal | a3122700-f4fd-4652-84ff-098c2db4a99a |
| escort | 549ef66a-6647-4035-9cdb-0839379a2caf |
| rescue | 414fb657-9e17-4a36-a50d-ed44664b8c3e |
