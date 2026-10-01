# Kingdoms Amid Kataclysm (KAK) — Version 0.05 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `feat/vfx-proof`, tag `kak-v0.05`. v0.05 is the civilization-response release: the town organizes against the god — a bell network, a banishing rite, engineers, river boats — and a chosen difficulty decides how much of that it has. Two quiet powers make a stealth opening real.*

## 1. Concept

You are an ancient god who **manifests over one walled medieval town, Aldermere**. You draft 4 of 13 cataclysm powers and, before the manifestation ends, must **destroy the Royal Citadel and collapse City Stability** while keeping too many citizens from escaping.

**Design goals:**
- players replay the same town because they believe a better sequence of powers would level it faster or with less Divine Power;
- v0.05: a harder game through **organization, not hit points**. Every response the town mounts is readable and can be countered.

## 2. Game flow

**Title → Prepare (draft and difficulty) → Mission → Results**, with **Pause** over the mission.

| Screen | What it does |
|---|---|
| Title | Game name over a slowly panning town; Play, VFX Sandbox, Quit |
| Prepare | Briefing, the draft (pick exactly 4 of 13 power cards into slots 1–4; the last loadout is preselected), and the **difficulty selector** with the town's **Defense Profile** along the bottom |
| Mission | 2 s intro (camera sweeps to the Citadel, "MANIFEST" banner), then the 6:00 clock runs |
| Pause (Esc) | Resume, Restart, Change powers, Title |
| Results | Victory/defeat, stat lines with points, score, rank S–D, "NEW BEST!" (saved) |

## 3. Controls

| Action | Input |
|---|---|
| Pan | WASD / arrows, or middle-mouse drag |
| Zoom | Mouse wheel (0.5–1.6) |
| Pick power | Keys 1–4 or click the slot |
| Cast | Click (point powers) or press-drag-release (line/lane powers) |
| Cancel / unfocus / pause | Esc |
| Restart | R |
| Difficulty (Prepare) | Left/Right, or the arrows |
| FPS meter | F3 |
| Behaviour overlay | F4 (intents, alarm stage and timeline, gate queues, the citizen under the mouse; v0.05 adds the tier, the bell, the rite, each engineer team's job with lines to its site, and the boats) |

## 4. Rules and resources

- **Divine Power (DP):** a 100-point bar regenerating 0.5 a second. Each power costs DP and has a cooldown. **One power at a time:** while a power is still playing no other can be cast (the slots show its seconds left in gold).
- **The Temple (cathedral):** destroying it restores 70% of the DP bar, once.
- **City Stability:** five parts (Population, Infrastructure, Leadership, Military, Resources).
- **Citadel:** fortified, losing at most 25% of its health a second; every 10% lost collapses one of its towers or walls.
- **Losing:** 50 citizens escaping, or the manifestation clock running out — and in v0.05 the clergy can shorten that clock (§7.3).
- **Score and ranks** as in v0.04 (win 5000; 25 a second left; 40 a building; 10 a citizen; 25 a soldier; 300 a chain; 10 a DP left; S ≥ 19,200 … D).

## 5. The 13 powers

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| **Silent Doom** (quiet) | 8 | 15 s | click | Up to 3 people within 0.8 die under a dark wisp. Unseen, the town never knows; a witness within 2 units panics and the deaths raise the alarm |
| Heaven Splitter | 10 | 20 s | drag | Line strike with 8 fissures |
| **Blight** (quiet) | 12 | 25 s | click | Rots the nearest useful structure within 1.0: a well or fountain gives no water, the bell cracks, a gate jams for 30 s, the dock sinks the boats, the cathedral holds no rite. +1 alarm |
| Tornado Tempest | 15 | 30 s | click | 10 s vortex that softly locks onto buildings |
| Dragonfire Parade | 18 | 35 s | click | Cone of dragonfire |
| Tsunami Breaker | 20 | 40 s | drag | Moving wall of water |
| Gravity Distortion | 20 | 45 s | click | Pull field |
| Walking Laser Grid | 22 | 45 s | drag | Moving laser lane |
| Orbital Strike | 22 | 45 s | click | Random bombardment |
| Cinderfall Barrage | 25 | 50 s | click | Volcano and stone rain |
| Judgement of the Ancients | 30 | 60 s | click | 8 punches and a slam |
| Glacial Cataclysm | 30 | 60 s | click | Burst, freeze, ice |
| Nuclear Nova | 40 | 120 s | click | Huge blast circle |

**Quiet powers** register no danger and raise no alarm when cast. Their aim preview shows what they would hit: Silent Doom rings its victims, Blight outlines its target (a red ring when nothing is in reach). Their cards carry a green "quiet" tag. The default loadout is Heaven Splitter, Tsunami Breaker, Cinderfall Barrage and Nuclear Nova.

## 6. Difficulty and the Defense Profile

Chosen on the Prepare screen and saved. Harder tiers add no hit points: the town organizes better.

| Tier | The town's responses |
|---|---|
| Unprepared | Fire brigade (2 per fire, from City Emergency). No bellkeeper: the Bell Tower is scenery. The postern is barred |
| **Organized** (default) | Bell Network (8 s climb), fire brigade (4 per fire, from Local Emergency) |
| Prepared | Organized + engineers (2 teams) + river boats and the postern + the Banishing Rite (45 s) |
| God-Resistant | Prepared, faster: bell 5 s, fire brigade 5, engineers 3 teams, rite 35 s |

## 7. The town's responses

### 7.1 Bell Tower (Bell Network)
- A stone tower with an open belfry east of the market. Its **bellkeeper** (in a navy coat with a brass badge) works at its foot.
- At the first Local Emergency the bellkeeper runs to the tower and climbs it for 8 s (a gold bar over the roof). The ring adds 20 alarm, tells every citizen, and brings City Emergency at alarm 25 (not 35) and the evacuation at 60 (not 90).
- **Until the bell has rung, alarm from events counts half** (collapses, deaths, Citadel hits): a town kept from its bell mobilizes slower.
- **Counters:** kill the bellkeeper (it is not replaced), Blight the tower (the bell cracks), or destroy it. A frightened bellkeeper drops the climb and retries 10 s later.

### 7.2 Fire brigade
- Up to 4 calm citizens per fire (5 at God-Resistant; 2 when Unprepared), from Local Emergency (City Emergency when Unprepared), fetch water from the nearest fountain or well and douse it. Blighted or destroyed water points give none.

### 7.3 Banishing Rite (Prepared and up)
- At City Emergency up to 4 clergy (in cream robes with gold stoles) gather on the cathedral's steps. Once 3 stand in the ring they chant for 45 s (35 s at God-Resistant): a gold ring fills on the ground, halos over the clergy, and a bar under the clock.
- **Completed, the rite takes 40 s off the manifestation**, once per mission.
- **Broken** — progress lost — when fewer than 2 remain in the ring (killed or frightened away) or the cathedral drops under half health; the clergy regather after 30 s. **Ended for good** by a fallen or blighted cathedral, or fewer than 3 clergy alive (the town starts with about 9).

### 7.4 Engineers (Prepared and up)
- Two teams of two (three at God-Resistant) from the workshop, in leather caps and aprons with hammers, turn out at City Emergency.
- Each team takes the job scoring highest on **priority less 2 for every unit of travel** — Citadel 100, routes (gates, bridge, dock) 80, Bell Tower and cathedral 60, houses 20 — never one another team holds, rethinking every 2 s.
- With both at the site they heal 5% of a building's health a second (sparks and a green bar), or rebuild a fallen gate, the bridge or the dock in 20 s (a steel bar), exactly as it stood.
- **The Citadel mends only back to its last collapse:** fallen towers and walls stay down.
- During the evacuation the gates are left alone (a fallen gate lets the crowd out faster).
- A team that loses a member is lost; the workshop sends another 60 s later while it stands.

### 7.5 River boats and the postern (Prepared and up)
- The dock is a pier on the north bank below the **postern**, a narrow door in the south wall at the end of the west street (one person every 3 s; barred in towns without boats).
- From the Evacuation stage the ship moored there ferries people away: they wait behind the pier, step aboard one by one, and escape when it sails full (6) — or 4 s after the first with nobody left waiting. It is back 12 s later.
- Evacuees score the dock as a third way out, counting the postern's queue and the crowd at the dock.
- **Counters:** destroy the dock (the boats stop until the engineers rebuild it) or Blight it (they stop for good). Destroying the bridge no longer seals the south.

## 8. The town of Aldermere

- **Layout:** walls with towers; the Main Gate (south, over the river bridge), the Side Gate (east road) and the postern (south, to the dock).
- **Landmarks:** the Royal Citadel (9 parts), the cathedral (the Temple), the Bell Tower, the barracks and its yard, a workshop, a smithy, 3 taverns, a carpenter's yard, the market square with a fountain, a second fountain plaza, 3 wells.
- **Density:** 81 houses, 30 market stalls, street props, trees, gardens, paved plazas.
- **Countryside:** the river and its west branch, the bridge, the dock and ship, farms and fields, a windmill and a watermill, pastures, a forest ring.
- **Look and sound:** warm evening light, procedural pixel art, moving water, mills, trees, awnings, banners, torches; synthesized effects, crowd voices and music that follows the city's fall.

## 9. People

- **220 citizens with roles** (Resident, Caregiver, Merchant, Craft Worker, Farmer, Laborer, Clergy; v0.05 adds the Bellkeeper and the Engineers), each with a home, a workplace and leisure spots, living a daily routine.
- **Local awareness** of every danger by its radius, sight and sound; fright that spreads; shelter in sturdy buildings; households that leave together.
- **Staged alarm** (rises only):

  | Stage | Reached when | What happens |
  |---|---|---|
  | Normal | — | Routines as usual |
  | Concern | Any danger | People nearby look or flee locally |
  | Local Emergency | 4 incidents in one district | Two patrol soldiers investigate; the bellkeeper is called |
  | City Emergency | Alarm 35 (25 after the bell), or 2 districts in emergency | Soldiers rally at the Citadel; the market closes; 30% of citizens regroup at home; the clergy gather; the engineers turn out |
  | Evacuation | 15 s after City Emergency, then alarm 60 with the bell or 90 without | Citizens make for the gates, the postern and the boats |
  | Collapse | The Citadel falls, or stability drops to 25% | Route choices grow erratic |

- **People on duty** — the bellkeeper, the clergy at the rite, the engineers — stand at their posts, keep to them through the evacuation, and go on (home, or to the gates) when their duty ends.
- **Gate routing:** evacuees score each way out by route length, the queue at its gate (only while they are inside the walls) and the danger they know of. **100 soldiers** drill, guard, patrol, investigate and rally.

## 10. Tools and dev features

- **Scripted runs:** `--mission-test` (now with `--difficulty=`), `--crowd-test`, `--flow-test`, `--bench`; `crowd_check.gd`; `state_digest.gd`.
- **Behaviour scenarios** (`tools/dev/behaviour_check.gd`, seeded, deterministic checksums): calm, strike, escalate, gates, fire, and in v0.05 bell (`--kill-keeper`), rite (`--interrupt`), engineers, boats (`--cut-bridge`), quiet, opening (`--quiet`) and siege (with `--difficulty=`).
- **Profilers:** `profile_view.gd`, `profile_wear.gd`.
- **Art:** `tools/dev/make_quiet_icons.py` paints the quiet powers' icons; the sandbox records every power's preview clip (`--capture-clip`).
- **Tests:** 921 automated checks (`tools/test.sh`).

## 11. Tuning (v0.05 M7)

Measured with the seeded behaviour scenarios. **No numbers were retuned:** as in v0.04, the tiers wait for a playtest. These runs show what each response does and where it is weak.

**Stealth against loud** (`opening`, Organized). The same four loud casts from 30 s; the quiet run first kills the bellkeeper with Silent Doom and blights the Bell Tower and the Main Gate:

| Opening | Bell | Evacuation called | Escaped by 100 s |
|---|---|---|---|
| Loud | Rang | 48.8 s | 65 |
| Quiet first | Silenced | 63.6 s | 47 |

The quiet opening bought 15 s before the evacuation and 18 fewer escapes.

**The tiers under one siege** (`siege`). Eight loud casts from 20 s (Heaven Splitter in the west, Cinderfall, two Novas on the Citadel, Tsunami, more Heaven Splitters), with no answer to the escapes. Every tier ends lost to escapes:

| Tier | Evacuation | Escaped at 60 s | 50 escaped | Rite | Boats carried |
|---|---|---|---|---|---|
| Unprepared | ~38 s (alarm 90) | 22 | ~92 s | — | — |
| Organized | ~28 s (the bell rang) | 35 | ~75 s | — | — |
| Prepared | ~28 s | 43 | ~71 s | broken once (clergy scattered), done too late | 27 |
| God-Resistant | ~28 s | 40 | ~72 s | **done at ~40 s: the clock lost 40 s** | 30 |

**What the runs show (for the playtest):**
- **Each tier is harder:** Organized's bell brings the evacuation 10 s sooner than Unprepared; the postern and boats lose the game to escapes about 4 s sooner again.
- **God-Resistant is mostly Prepared plus a faster rite.** If it should feel clearly harder, candidates are a bigger boat load, a quicker postern, or more clergy.
- **The bellkeeper works at the tower's foot by the market.** A first strike on the market kills them, and then Organized plays like Unprepared. That is counterplay working, but it is easy to do by accident.
- **Engineers matter most against chip damage.** In a fire-heavy siege they stood idle:
  - the damaged houses were burning (left to the fire brigade, which stops at the evacuation);
  - the Nova's 25%-a-second bursts left the Citadel on its collapse marks, with nothing to mend.
  - Options: let engineers douse fires, mend burning buildings, or (at God-Resistant) rebuild a fallen Citadel part.
- **The rite completes only when undisturbed.** At 35 s it finished before the siege reached the steps; at 45 s a cast scattered the clergy first.

## 12. Performance

- **Market view, mission bench, same hour, alternating** (`--bench`):

  | Build | fps | Draw calls |
  |---|---|---|
  | `kak-v0.04-final` | 115.6 | 1042 |
  | v0.05, Organized (default) | ~111 (−4.7) | 1052 |
  | v0.05, God-Resistant | ~109 (−6.2) | 1052 |

- **Where it went:**
  - **The Bell Tower:** about 0.6 fps and 12 draw calls (it stands in the market view).
  - **Walkers no longer stick on building corners** (M2's fix): people who used to stand pinned keep walking and redrawing, about 2.5 fps. A fix, kept.
  - **God-Resistant's responders** walk to their posts.
- **Recovered in M7:** the escape check asked the evacuation manager about the boats before its cheap tests, for every citizen every frame. Reordered, it gave back 1.7 fps.
- The default tier is inside the 5-fps budget against v0.04; God-Resistant is just over it.

## 13. Not yet in (later)

World map, progression and upgrades, more maps, civilization ages, building materials, elemental combos, enemy heroes and defenses that fight back; for the responses: commanders, ward protection, a targetable ferry, and per-tier tuning after playtests.
