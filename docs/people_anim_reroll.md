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

## Round 2 (2026-11-05): done

Re-rolled with v3 under temporary names (`scream_rr`, `scream_rr2`, `swing_rr`), staged one folder per clip and imported.
22 generations spent.

- **Back-view screams in, 8 of 9:** merchant_a, merchant_b, craft_a, craft_b, clergy, caregiver_a, bellkeeper and
  engineer. The prompt that turned them away: `walking away from the viewer, back turned, clutching the back of the head
  with both hands and screaming, staggering, only the back of the head visible` (or `..., seen from behind, face turned
  away`).
- **Still rejected: caregiver_b.** It faced the viewer twice, so it stays in `_REJECTED_SOURCE`.
- **Spear thrusts in:** marshal and rescue, both directions. Marshal south-east is the first take with its flash frame
  dropped (7 frames).
- **Still missing: escort.** The south-east take swung the spear both ways, twice, so it keeps the idle fallback.
- **Farmer swing kept as it was.** The re-roll was whiter than the idle and dropped the pitchfork in the last frame. The
  old south-east cross-punch was deleted on PixelLab by `--replace`; the local frames are the only copy.

## Phase 2 (2026-11-05): pray, point, look up, cower

All 13 citizen designs have the four new rows (ANIMS 9-12), generated SE + NE with v3 (8 frames) and mirrored. Soldiers and
stand-ins have none and keep their old look (the procedural kneel for Voice of God).

When they play (drawing only; no timing changes):
- pray: Voice of God's Kneel (compel_pose &"kneel"), and Divine Congregation (compel_pose &"pray") once standing still.
- point / cower: the startle freeze before a run (Person.startled()); cower within COWER_REACH (3 tiles) of the threat,
  point beyond it. The clip plays across the freeze.
- look up: Mind.OBSERVE with look_up set; only the Falling Star watchman sets it (WarningDirector). Death Mark gawkers
  stare at a body on the ground, so they do not look up.

Prompts: pray "kneeling upright on both knees with a straight back, hands pressed together in prayer, head slightly
bowed, not lying down" (the first prompt, "kneeling down on both knees and praying ... head bowed", often lay flat);
point "pointing ahead with one outstretched arm clearly visible and shouting a warning"; lookup "standing still and
looking up at the sky in awe, head tilted back"; cower "crouching low and covering the head with both arms, trembling
in fear". Back views add ", seen from behind facing away from the viewer, back of the head visible".

Generations: 8 pilot + 96 + 18 re-rolls. Kept with flaws, to re-roll later:
- merchant_b pray back and bellkeeper pray front lie face-down (reads as prostration).
- caregiver_b pray back kneels facing the viewer.
- merchant_b, caregiver_b and clergy point back face the viewer.
- clergy point front: the arm barely shows against the white robe.

## Interaction (2026-11-07): talk, work, dig, douse

New rows (ANIMS 13-16), SE + NE with v3 (8 frames), mirrored: talk and douse for all 17 designs, work for the 13
citizens, dig for the 4 soldiers (guard, marshal, escort, rescue). The pose code grew to `frame << 7 | anim << 2 | facing`
(anim mask `& 31`) to fit more than 16 rows.

When they play:
- talk: a calm citizen at a LEISURE stop. A soldier at its post talks in the pauses that fall in a TALK_WINDOW (4 s) of
  every 8-15 s (seeded per soldier).
- work: a calm citizen at a WORK or ERRAND stop; a fire responder filling its bucket at the water.
- douse: a fire responder with a full bucket at the fire; the clip runs once across FireManager.ACT.
- dig: a rescue crew member at the rubble (RescueManager sets Person.dig_shown).

Gameplay change (approved): a calm citizen within STOP_REACH (1.2 tiles) of a work, errand or leisure stop, and a rescue
digger, now stand still instead of milling (Person._at_stop(), _drift()). At home they mill as before. This moves the
crowd, so the exact references were re-recorded.

Prompts: talk "standing and chatting with a friend, gesturing with both hands while talking"; work "standing in place,
both hands busy on a workbench at waist height, sorting goods, small movements" (the pilot's "standing at a table working
with both hands in front, handling goods" was rejected in review); douse "throwing water forward from a wooden bucket held in both
hands, blue water splashing from the bucket" (without the water the back view read as lifting a box); dig "bending down
and digging through rubble, lifting heavy stones and throwing them aside". Back views add the usual suffix.

Generations: 12 pilot + 90 + 7 re-rolls. Re-rolled and kept: resident_a work (both), resident_a and rescue douse back,
marshal dig (both; the first take threw the shield apart, the re-roll adds "kneeling ... with bare hands ... weapon and
shield set down on the ground"), merchant_b talk back. Kept with flaws, to re-roll later:
- work: invented props (a table, a box) on merchant_b, laborer, caregiver_a, craft_a and engineer. The people stand
  where no table is drawn.
