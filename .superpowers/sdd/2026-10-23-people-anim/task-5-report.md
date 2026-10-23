# Task 5 report (Steps 0-3; Step 5 wrap-up left to the controller)
Status: DONE.
Commits: 9880ce5b (Step 0), 90da0942 (scream sound), 144bc5a4 (madness capture scenario), plus this report.

## Step 0
- make_people_atlas.py: REJECTED table (design, state, direction): scream NE for merchant_a, merchant_b, craft_a, craft_b, clergy, caregiver_a, caregiver_b, bellkeeper, engineer, plus NW (mirror) expanded in code. Those cells pack the idle frames (4 frames); frames stay on disk. `own` bit unchanged.
- docs/people_anim_reroll.md: 9 back-view screams, farmer swing SE, marshal/escort/rescue thrusts, with ids and parameters.
- tests: test_madness precondition (screaming before freeze); test_people_art checks a rejected back scream equals the idle and the front scream keeps its art.
- Atlas and manifest regenerated (scream NE/NW counts 8 -> 4 on those 9 designs).

## Step 1 Sound
cit_scream_1..3 (tools/audio/foley/citizen recipes): Female Scream 1 (CC0) at pitch 0 and -3, and 80 CC0 creature SFX scream_02 (CC0) at -2. No Sonniss. Catalog `cit_scream` (3 variants, -8 dB), played in MadnessManager when the scream starts, like q_madness_hit (not through the voice budget). CREDITS.md and loudness.tsv updated (167 files, 0 bad). Tests: voices catalog+disk check, test_sfx_catalog counts 164->167, foley 146->149.

## Step 2 Captures
New `behaviour_check --scenario=madness [--shots --ring= --pick= --prefix= --front]` (captures/ is git-ignored). Shots read:
- behaviour_madness_scream.png: maddened one seen from behind (idle fallback, red ring, no scream pose) among nine bystanders at the market.
- behaviour_madness_front_scream.png: front-facing scream mid-clip, hands to the head, bystanders around.
- behaviour_madness_swing.png / front_swing.png: punch mid-swing; a victim beside him is a white flash silhouette (hit flash).
- behaviour_madness_down.png: the victim knocked back and tinted white/horizontal, the attacker still swinging.
- behaviour_madness_getup.png: victim lying/rising on the ground beside the attacker, overlapping figures.
- far1_scream/far2_scream.png: single maddened person (red coat / green dress) from behind, idle fallback, nobody near.
- far1_lurch/far2_lurch.png: the zombie walk, arms forward, walking toward a distant target (red coat, green dress).
- far1_swing/far2_swing.png: swing at the end of the chase; far2 shows the club/arm streak.
All read fine; no clipping or holes. Back-view screams stand still, as ruled.

## Step 3 Landing checks (land.sh parts run separately; the machine was busy with other sessions' Godot)
- Fetch: origin/feat/Develop-Main has 1 incoming commit (1c28dc00, F1 hides the interface); trial merge clean.
- Suite: checks=8250 failures=0, no SCRIPT ERROR.
- References: all 233 OK, none moved in this task (digest 61267b7e..., crowd_check, calm, gates, fire, rite, soldiers, warnings, miras/lanterns/flame/feast and 189 board rows). Earlier re-records are Task 3's (judgement_b_play_1/_3, night_b_play_1..3 etc.).
- FLOW alone: checks=127 failures=0.
- Bench vs kak-v0.11.2 (tag worktree), board versions, 3 alternating runs; machine noisy (first pair quiet ~90-110 fps, later pairs ~30 fps with other sessions' load): A=tag, B=HEAD
  - warning: 111.6/111.0 | 33.5/34.0 | 34.3/34.7 (median A 34.3, B 34.7)
  - miras_house: 94.2/94.9 | 29.6/28.7 | 28.9/28.2 (A 29.6, B 28.7)
  - vigil_flame: 99.2/98.5 | 29.7/29.1 | 29.9/30.3 (A 29.9, B 29.1)
  - procession: 90.0/86.9 | 26.7/26.1 | 24.9/26.6 (A 26.7, B 26.1); rerun 87.7/91.6 | 26.3/26.9 | 27.3/26.2
  - last_judgement: 96.0/94.9 | 27.1/27.8 | 27.1/27.3 (A 27.1, B 27.8)
  All within about 3 fps (noise-limited); quiet first pairs within 1 fps except procession 3.1 down then 3.9 up on the rerun.

## Concerns
- Bench is noisy because other sessions run Godot throughout; no clear regression.
- Back-view screams still show the idle until the re-roll.
