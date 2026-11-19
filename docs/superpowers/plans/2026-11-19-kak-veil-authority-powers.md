# Veil Authority Powers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fill the Veil god's tree: the law of the Veil (small in the light, full in the dark), seven new quiet powers, the Blight rework, and two sizes for Silent Doom and Unseen Hour, all at level 1.

**Architecture:** A dusk ledger in the crowd answers one question, `Crowd.in_dark(at)`. `Rules.cast()` stamps `extra["dark"]` on every Veil-authority cast; each effect reads its light or dark numbers from one table in `VeilRules` and lays dusk when it lands. People expose small hooks (deep sleep, hidden from the watch, ill, dread, shadow); effects under `src/fx/veil/` use them.

**Tech Stack:** Godot 4.7.2 GDScript; the effect kit (`FxTimeline`, `FxParts`, `PixelParticles`); headless suites (`tests/run_part.gd`); reference rows (`tools/dev/refs_check.sh`).

**Spec:** `docs/superpowers/specs/2026-11-19-kak-veil-authority-powers-design.md` (approved 2026-11-19; §11 holds the amendments found while reading the code).

## Global Constraints

- Work only in `C:/BURIN_NITRO/Godot/GIT/vfxProve-veil`, branch `god/veil-powers`. Never push; never touch another worktree.
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
- Import first in a fresh worktree and after any new `class_name` or test file:
  `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`
- One suite (`X` = the file's name without `test_` and `.gd`):
  `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); timeout 600 $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N 2>&1 | grep -aE "SCRIPT ERROR|FAIL|failures="`
  Always grep `SCRIPT ERROR`: a parse error hangs `run_part` with no `failures=`, and a suite that dies on a runtime error still prints `failures=0`.
- Whole suite: 16 parts, 4 at a time, each `timeout 2400 $G --headless --path . --script res://tests/run_part.gd -- --part=$i --of=16`.
- References: `bash tools/dev/refs_check.sh --jobs=4 --only='<regex>'`, in chunks of at most 40 rows (it prints only at the end; a timeout loses every row). Never re-record a row outside Task 13.
- Every command runs under `timeout`, in the foreground. Never stop a process you did not start (other sessions run Godot here).
- Scripted windowed runs use `user://test_*` files, never the user's `kak_save.cfg`.
- Python on this machine defaults to cp874: pass `encoding='utf-8'`.
- **Level 1 in the light is today:** Silent Doom, Blight on a building with a use, and Unseen Hour cast on lit ground behave exactly as before, apart from the dusk they leave and Blight's alarm (§11).
- **A row that casts no Veil-authority power stays byte-identical.** An empty dusk ledger must change nothing.
- **Silent:** no Veil power registers a danger, raises alarm, calls `Crowd.on_cast` fright, or makes a death voice.
- **No luck:** no `rng` call decides who or what a power affects. Order by distance, then `get_instance_id()`.
- **Teardown:** whatever an effect switches on (a status, a pace hold, a light, a sight scale, a dread, a cooldown rate, a town-wide veil) is undone in `_finish()` and in `_exit_tree()`. Two overlapping casts never undo each other (own instance ids, no statics).
- Powers are effects; nothing power-specific is hard-coded into `Person` beyond the small hooks Task 2 names.
- Tests first: write the failing test, see it fail, then implement. Commit messages end with
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.
- A decision the plan and spec do not settle: take the smallest reading that keeps the constraints above, and write it as a line in `docs/KAK_God_Veil_Rulings.md` (`V<n>: what — why`).

## Review Focus

1. **An effect freed early** (mission ends, `end_now()`, the node freed mid-cast): no person stays asleep-deep, ill, cloaked, dreaded or a shadow; lights, sight scale, cooldown rate and the town-wide veil return. Each power's test file has a teardown check with `end_now()` and with a freed node, plus a positive control on the same path.
2. **Two casts overlap** (two Slumbers on one person, two dusk patches, Dread during Evernight): the second neither shortens nor undoes the first. Tests in Tasks 1, 5, 8, 11.
3. **The target changes between cast and landing** (dies, walks indoors, is taken): the effect skips them without an error. Tests in Tasks 4, 7, 9.
4. **No crowd or no rules** (the VFX Sandbox passes `ctx.crowd == null`, `ctx.rules == null`): every Veil effect builds and finishes without an error at the light size. One test per power.
5. **A NIGHT mission:** everywhere outdoors is dark, sight is 0.6 and never 0.36, Dread's whole circle is dreaded. Tests in Tasks 1 and 8.

---

## File map

| File | Responsibility |
|---|---|
| `src/game/veil_rules.gd` (new) | Every Veil constant: dusk, the two-size table, `wants()`, `size()` |
| `src/game/crowd/dusk.gd` (new) | The dusk ledger: patches, lasting patches, the everywhere flag, drawing |
| `src/fx/veil/veil_parts.gd` (new) | Shared effect helpers: `dark()`, `land()`, the Veil palette |
| `src/fx/veil/{slumber,cloak_of_night,dreamless,dread_of_the_dark,shadow_play,the_swallowing_dark,evernight}.gd` (new) | One power each |
| `src/fx/quiet/{silent_doom,blight,unseen_hour}.gd` | Two sizes, dusk; Blight's rework |
| `src/game/crowd/crowd.gd`, `person.gd` | The hooks of Tasks 1-2 only |
| `src/game/rules.gd`, `targeting.gd`, `power_book.gd`, `src/game/god/god_tree.gd` | Stamp, ring, rows, tree |
| `src/game/mission/mission_director.gd` + subclasses | `quarry()`, `keeps_alive()` |
| `src/core/light_field.gd` | `mute()` |
| `tests/test_veil_*.gd` (new) | One suite per task |
| `docs/KAK_God_Veil_Rulings.md`, `docs/KAK_God_Veil_Summary.md` (new) | Rulings and the summary |

Tasks 1 and 2 are the only ones that edit the shared files. Tasks 3-11 each own their effect file and test file and may run in parallel worktrees in three tracks: **A** = 3, 4, 10; **B** = 5, 7, 9; **C** = 6, 8, 11. Tasks 12-13 run last, on the merged branch.

---

### Task 1: The law of the Veil (rules, dusk, stamp, ring, rows, tree)

**Files:**
- Create: `src/game/veil_rules.gd`, `src/game/crowd/dusk.gd`, `src/fx/veil/veil_parts.gd`, seven stub effects under `src/fx/veil/`, `tests/test_veil_law.gd`, `docs/KAK_God_Veil_Rulings.md`
- Modify: `src/game/crowd/crowd.gd`, `src/game/rules.gd`, `src/game/targeting.gd`, `src/game/power_book.gd`, `src/game/god/god_tree.gd`, `src/game/ui/upgrades_screen.gd`, `tests/run_all.gd`, `tests/test_power_book.gd`, `tests/test_tree_detail.gd`, `tests/test_routes.gd` (and any other count test that fails)

**Interfaces — Produces:**
```gdscript
class_name VeilRules  # src/game/veil_rules.gd
const DUSK_R := 3.0
const DUSK_TIME := 20.0
const BLIGHT_MAX := 3
## key -> stat -> [light, dark]
const SIZES := {
	"doom": {"RADIUS": [0.8, 1.6]},
	"blight": {"DUSK_R": [3.0, 5.0], "ILL_MOST": [1, 3]},
	"slumber": {"RADIUS": [1.5, 3.5]},
	"cloak": {"MARK_R": [2.0, 4.0], "MOST": [3, 8]},
	"unseen": {"RADIUS": [5.0, 7.0], "VEIL_TIME": [20.0, 30.0]},
	"dreamless": {"REACH": [1.0, 2.0], "MOST": [1, 4]},
	"dread": {"REACH": [6.0, 12.0]},
	"shadowplay": {"RADIUS": [3.0, 6.0]},
	"swallow": {"FULL_R": [10.0, 14.0]},
	"evernight": {"NIGHT_TIME": [60.0, 90.0], "TAKE_EVERY": [2.0, 1.5]},
}
## The stat the aim ring shows, per key ("" = no ring change).
const RING := {"doom": "RADIUS", "slumber": "RADIUS", "cloak": "MARK_R", "unseen": "RADIUS", "dreamless": "REACH",
	"dread": "REACH", "shadowplay": "RADIUS", "swallow": "FULL_R"}
static func wants(loadout: PackedStringArray) -> bool   # any key whose PowerBook.authority_of() is "veil"
static func size(key: String, stat: String, dark: bool) -> float

class_name Dusk  # src/game/crowd/dusk.gd, extends Node2D (drawn on the ground layer)
signal laid(at: Vector2, r: float)
var enabled := false
var everywhere := false              # Evernight
func lay(at: Vector2, r: float, seconds: float) -> int      # seconds < 0 = until end(id); returns an id, 0 when not enabled
func end(id: int) -> void
func covers(at: Vector2) -> bool     # a live patch covers `at` (not the everywhere flag)
func r_at(at: Vector2) -> float      # the largest live patch covering `at`, else 0.0
func step(delta: float) -> void
func clear() -> void

# Crowd
var dusk: Dusk
var night_mission := false           # set where NightRules.apply() runs for a NIGHT look
func in_dark(at: Vector2) -> bool    # dusk.covers or is_veiled or night_mission or dusk.everywhere
func lay_dusk(at: Vector2, r: float, seconds: float) -> int
func sight_scale_at(viewer: Vector2, seen: Vector2) -> float  # min(sight_scale, NIGHT_SIGHT if either point is in dusk); INF = no such point

class_name VeilParts  # src/fx/veil/veil_parts.gd
const VEIL := Color("b98cff"); const DUSK := Color("3b1470"); const SILVER := Color("cfd3e6"); const BLACK := Color("07050c")
static func dark(fx: FxTimeline) -> bool                 # fx.extra.get("dark", false)
static func size(fx: FxTimeline, key: String, stat: String) -> float
static func land(fx: FxTimeline, at: Vector2, r := VeilRules.DUSK_R) -> int   # crowd.lay_dusk(at, max(r, DUSK_R), DUSK_TIME); 0 with no crowd
```
`Rules.cast()` sets `told["dark"] = crowd.in_dark(ground)` beside `told.level` when `PowerBook.authority_of(key) == "veil"` and a crowd exists (a key already in `extra` wins, for tests). Where Remains is enabled (`rules.gd:246`), `crowd.dusk.enabled = VeilRules.wants(loadout)`.

- [ ] **Step 0: Baseline.** Import; run the whole suite and `refs_check.sh --only='^(digest|crowd_check)$'`; write the numbers at the top of `docs/KAK_God_Veil_Rulings.md`. Stop and report if the base is not clean.
- [ ] **Step 1: Write `tests/test_veil_law.gd`** (copy `_setup` / `_done` from `tests/test_unseen_curfew.gd`), register it in `tests/run_all.gd`:
```gdscript
# sizes
t.check(VeilRules.size("doom", "RADIUS", false) == 0.8 and VeilRules.size("doom", "RADIUS", true) == 1.6, "doom two sizes")
t.check(VeilRules.wants(PackedStringArray(["smite", "doom"])) and not VeilRules.wants(PackedStringArray(["smite"])), "wants")
# ledger
crowd.dusk.enabled = false
t.check(crowd.lay_dusk(P, 3.0, 20.0) == 0 and not crowd.in_dark(P), "off: nothing laid")
crowd.dusk.enabled = true
var id := crowd.lay_dusk(P, 3.0, 20.0)
t.check(crowd.in_dark(P) and crowd.in_dark(P + Vector2(2.9, 0)) and not crowd.in_dark(P + Vector2(3.1, 0)), "patch edge")
crowd.dusk.step(20.1); t.check(not crowd.in_dark(P), "fades at 20 s")
var id2 := crowd.lay_dusk(P, 3.0, -1.0); crowd.dusk.step(500.0); t.check(crowd.in_dark(P), "lasting"); crowd.dusk.end(id2); t.check(not crowd.in_dark(P), "ended")
# two patches: ending one leaves the other
# veil and night count as dark
crowd.veil(Q, 5.0, 20.0); t.check(crowd.in_dark(Q), "veil is dark")
crowd.night_mission = true; t.check(crowd.in_dark(FAR), "night mission is dark"); crowd.night_mission = false
# sight: one scale, never two
t.check(is_equal_approx(crowd.sight_scale_at(IN_DUSK, IN_DUSK2), 0.6), "0.6 once")
crowd.sight_scale = 0.6; t.check(is_equal_approx(crowd.sight_scale_at(IN_DUSK, LIT), 0.6), "night: not 0.36"); crowd.sight_scale = 1.0
t.check(is_equal_approx(crowd.sight_scale_at(LIT, LIT2), 1.0), "lit: 1.0")
# the stamp
#   Rules.cast of "doom" on dusk ground -> the made effect's extra["dark"] == true; on lit ground false; of "smite" -> no key
# the laid signal fires once per lay with (at, r)
# the tree and the book
t.check(GodTree.TABLE["veil"] == [["doom","blight"],["slumber","cloak"],["unseen","dreamless"],["dread","shadowplay"],["swallow","evernight"]], "tree")
for k in ["slumber","cloak","dreamless","dread","shadowplay","swallow","evernight"]:
	t.check(PowerBook.authority_of(k) == "veil" and PowerBook.is_quiet(k) and PowerBook.blurb(k) != "", k)
t.check(PowerBook.might("slumber") == 3 and PowerBook.might("dread") == 4 and PowerBook.might("shadowplay") == 5 and PowerBook.might("swallow") == 6, "might")
```
- [ ] **Step 2: Run it** — expect `SCRIPT ERROR` (no `VeilRules`).
- [ ] **Step 3: Implement** `VeilRules`, `Dusk` (made in `Crowd.setup()` beside `remains`, stepped in `_advance`, cleared in `clear()`, drawn as soft-edged `DUSK`-coloured discs on the ground layer, alpha about 0.45), `Crowd.in_dark` / `lay_dusk` / `sight_scale_at`, `night_mission`, the `Rules` stamp and gate, `VeilParts`.
- [ ] **Step 4: Sight sites.** Replace the uses of `sight_scale` that know a point (`crowd.gd:1386 _look`, `:2232` collapse sight, `doom_witness()` / `nearest_witness()`) with `sight_scale_at()`. With an empty ledger each must return exactly what it did.
- [ ] **Step 5: The book.** Add seven `PowerBook.POWERS` rows after `unseen`, each `"quiet": true, "authority": "veil", "aim": "click"`, with `path` to its stub, `dp` and `cooldown` from the spec (slumber 3 / 40, cloak 3 / 45, dreamless 3 / 35, dread 4 / 70, shadowplay 5 / 90, swallow 6 / 999, evernight 6 / 999), a `blurb` of at most 70 characters and a `shape` line giving both sizes. Give `unseen` a blurb. Add them to `FAMILY` (`"veil"`), to `Targeting.AREAS` (circle, the light radius; evernight none), to `Rules.POWER_KINDS` (`slumber []`, `cloak []`, `dreamless [&"dreamless", &"dreamt"]`, `dread []`, `shadowplay [&"shadow"]`, `swallow [&"void"]`, `evernight [&"night"]`, `blight []`). Each stub: `class_name <Name>Fx extends FxTimeline`, `_build()` sets `duration = 1.0` and calls `VeilParts.land(self, origin)`.
- [ ] **Step 6: The tree and the counts.** Set `GodTree.TABLE.veil`. Update the counts that now differ: `test_power_book` 77 -> 84, `test_tree_detail` 52 -> 60, `test_routes` FAMILY size, and any other suite the whole run shows. Make the Upgrades grid hold 59 locked powers inside `GRID_BOTTOM` (four columns, or the smallest change that keeps its own tests green).
- [ ] **Step 7: The ring.** In `Targeting.area()`, for a key in `VeilRules.RING`, return the circle with `r = VeilRules.size(key, stat, _crowd.in_dark(_press))`, and draw a small `LIGHT` / `DARK` tag by the ring. Test: with the cursor on dusk `area().r == 1.6` for doom, on lit ground `0.8`.
- [ ] **Step 8: Placeholder icons.** Add the seven keys to `tools/dev/make_power_icons.py` (a dark field, one violet glyph each) and run it for them.
- [ ] **Step 9: Verify.** `test_veil_law` `failures=0`; the whole suite `failures=0`; `refs_check.sh --only='^(digest|crowd_check)$'` unchanged; 40 rows that cast no Veil power, picked from `tools/dev/refs/*.tsv` (rows whose loadout holds no `veil` key, for example the `god_ruin_*` rows), all `OK`.
- [ ] **Step 10: Commit** `feat: the law of the Veil -- dusk, two sizes, the Veil tree's rows`.

### Task 2: Shared hooks for the Veil powers

**Files:**
- Create: `tests/test_veil_hooks.gd`
- Modify: `src/game/crowd/person.gd`, `src/game/crowd/crowd.gd`, `src/game/rules.gd`, `src/core/light_field.gd`, `src/audio/death_voices.gd`, `src/game/crowd/remains.gd`, `src/game/mission/mission_director.gd` and its subclasses, and the readers of `guised()` listed below

**Interfaces — Produces:**
```gdscript
# Person
func sleep(seconds: float, deep := false) -> bool   # deep: noise does not wake; a hurt still does
func is_deep_asleep() -> bool
func hidden_from_watch() -> bool                    # guised() or statuses.has(&"cloak")
func is_shadow() -> bool                            # statuses.has(&"shadow"): sees nothing, reports nothing, fights nobody
func is_dreaded() -> bool                           # statuses.has(&"dread"): cannot walk, flee, shout, ring, fight or seize
func send_home_sick() -> void                       # walks to profile.home (a soldier: the barracks yard), then is taken indoors for the mission
func make_ill(seconds: float) -> void               # half pace for `seconds`, nothing dropped (quarry)
var home_sick := false

# Crowd
func dread(at: Vector2, reach: float, seconds: float) -> int
func end_dread(id: int) -> void
func dreaded(at: Vector2) -> bool                   # a live dread within reach of `at` AND in_dark(at)
func veil_all(seconds: float) -> int                # is_veiled() is true everywhere until it ends
func end_veil_all(id: int) -> void
func spared(p: Person) -> bool                      # faith == BELIEVER, or the director's keeps_alive(p)
func take(p: Person, kind: StringName) -> bool      # field.kill with a silent no-body kind; false if gone already

# MissionDirector (default false)
func quarry(p: Person) -> bool
func keeps_alive(p: Person) -> bool

# Rules
var haste: Dictionary = {}                          # authority -> cooldown clock rate; advance() uses it, never for a cooldown >= 999
# LightField
func mute(share: float) -> void                     # every static light's intensity * share (1.0 = as made); lights added later are not muted
```
Silent kinds `&"void"`, `&"night"`, `&"dreamt"`, `&"shadow"`: `Crowd._on_killed` returns early as for `&"gone"` (no voice, no incident, no alarm), and they are in `DeathVoices.QUIET_KINDS`; none leaves a remain. `&"dreamless"` takes the `&"doom"` path (witness settling) and is added to `Remains.BODY_KINDS`.

- [ ] **Step 1: Write `tests/test_veil_hooks.gd`:**
```gdscript
# deep sleep
p.sleep(20.0, true); crowd._react([p.ground_pos], 3.0, 5.0, p.ground_pos, &"lightning", true, false)
t.check(p.is_asleep(), "noise does not wake a deep sleeper")
q.sleep(20.0); crowd._react([q.ground_pos], 3.0, 5.0, q.ground_pos, &"lightning", true, false)
t.check(not q.is_asleep(), "noise wakes a light sleeper (control)")
# hidden from the watch
p.statuses[&"cloak"] = 25.0; t.check(p.hidden_from_watch() and not p.guised(), "cloak hides, is not a guise")
t.check(crowd.nearest_witness(p.ground_pos, []) != p, "a cloaked person is still a witness to others")  # cloak hides him, does not blind him
# a shadow and a dreaded person are never the nearest witness; a control person at the same distance is
# sick: after walking, p.inside and p.home_sick and p.is_alive(); crowd.alive_citizens() still holds him
# quarry: director stub with quarry(p) == true -> Blight's helper calls make_ill, pace is half for 20 s, then back
# dread: crowd.dread(P, 6.0, 25.0) with dusk at D inside reach -> crowd.dreaded(D); lit ground inside reach is not; end_dread clears; two dreads: ending one keeps the other
# veil_all: crowd.is_veiled(ANY) for its time; end restores; a normal veil laid meanwhile survives
# take: crowd.take(p, &"void") -> not p.is_alive(), crowd alarm unchanged, remains count unchanged, a second take returns false
# spared: a BELIEVER is spared; a FAITHFUL is not
# haste: rules.haste = {"veil": 2.0}; advance(1.0) drops doom's cooldown by 2.0, smite's by 1.0, and a 999 cooldown by 1.0
# mute: lights.mute(0.0) then mute(1.0) restores sample() at a lamp to its first value
```
- [ ] **Step 2: Run it** — expect failures (missing methods).
- [ ] **Step 3: Implement the hooks.** `send_home_sick()` reuses what `NightRules.apply` does at arrival (`inside`, `night_indoors`, hidden, `field.remove`) and drops what the person carries first (a carter's load by the path Harvest H7 uses; a duty by `can_take_duty()`). The dread and shadow statuses are read at the sites that already ask `is_asleep()` or `hidden`-like questions: witness (`nearest_witness`), a soldier's fight pick (`person.gd:2213`), seizing, ringing, shouting, and the step that moves a person.
- [ ] **Step 4: The watch's question.** Replace `guised()` with `hidden_from_watch()` at: `crowd.gd:2478`, `person.gd:2213`, `mission_director.gd:582`, `temple_report.gd:166`, `escort_director.gd:506,526,701,710`, `exodus_director.gd:719`, `hide_faithful_director.gd:812,832,835`. Leave Death's own readers (`visitors.gd`, `walking_corpse.gd`, `pale_reign.gd`, `pale_serpent.gd`, `the_gate_below.gd`, the grey draw and the shamble) on `guised()`.
- [ ] **Step 5: The directors.** Override `quarry()` where a director holds people the god must stop: `assassinate` (`quarries`), `warning` (`watchman`, `messenger`), `ringer` (`own_keeper`), `hide_faithful` / `face_halcyon` (`inquisitors`), `hunt` (`head`), `bell_ringers` (`ringers`), `procession` (`prince`), `festival` (`mayor`), `miras_house` family (`preacher`, `shouter`), `relic_run` (`carter`). Override `keeps_alive()` where a director holds people the god must not lose: `escort` (`charge`), `exodus` / `hide_faithful` (`households`), `face_halcyon` / `miras_house` (`believers`), `rite` (`captive`), `vigil_flame` (`wren`). Read each director before deciding; write one ruling line per director that differs from this list.
- [ ] **Step 6: Verify.** `test_veil_hooks` and `test_guise` `failures=0`; the whole suite `failures=0`; `refs_check.sh --only='death|guise'` in chunks, all `OK` (the refactor changes nothing); `digest|crowd_check` unchanged.
- [ ] **Step 7: Commit** `feat: shared hooks for the Veil powers`.

### Task 3: Silent Doom and Unseen Hour take two sizes

**Files:** Modify `src/fx/quiet/silent_doom.gd`, `src/fx/quiet/unseen_hour.gd`, `src/game/targeting.gd` (doom's victim rings only); Create `tests/test_veil_sizes.gd`.

**Interfaces — Consumes:** `VeilParts.size/land/dark`. **Produces:** `SilentDoom.victims_at(field, at, r := RADIUS)` (the default keeps every director and bot caller as today).

- [ ] **Step 1: Test.**
```gdscript
# doom, light: people at 0.7 and 1.2 from the click -> only the 0.7 one dies. dark (extra {"dark": true}): both die.
# doom lays dusk of DUSK_R at the click when it strikes (T_STRIKE), not before
# unseen, light: crowd.is_veiled(P + Vector2(4.9, 0)) and not at 5.1; veil gone after 20.8 s. dark: 6.9 yes, 7.1 no; still up at 29 s
# unseen lays dusk of its own radius
# no crowd / no rules: both build and finish without an error
```
- [ ] **Step 2: Run** — fails (dark size not applied).
- [ ] **Step 3: Implement.** Read `RADIUS` (and `VEIL_TIME`) through `VeilParts.size()` in `_build()`; call `VeilParts.land()` when the power lands; Targeting's doom rings use the ring's radius.
- [ ] **Step 4: Verify.** `test_veil_sizes`, `test_quiet`, `test_unseen_curfew` `failures=0`.
- [ ] **Step 5: Commit** `feat: Silent Doom and Unseen Hour are small in the light, full in the dark`.

### Task 4: Blight reworked

**Files:** Modify `src/fx/quiet/blight.gd`, `src/game/targeting.gd` (blight's marks only), `src/game/crowd/crowd.gd` (`_on_blighted`: no alarm); Create `tests/test_veil_blight.gd`.

**Interfaces — Consumes:** `Person.send_home_sick()`, `make_ill()`, `MissionDirector.quarry()`, `Crowd.lay_dusk(.., -1.0)`, `Dusk.end()`, `LightField`. **Produces:**
```gdscript
const PICK := 0.5; const ILL_REACH := 2.0; const ILL_TIME := 20.0
static func pick(ctx: FxContext, at: Vector2) -> Dictionary   # {"kind": &"director"|&"building"|&"person"|&"none", "s": Structure, "p": Person, "at": Vector2}
static func footholds(crowd: Crowd) -> Array                  # the blighted buildings that hold lasting dusk, oldest first
```
- [ ] **Step 1: Test.**
```gdscript
# pick order: a director target wins; a click inside a footprint takes that building even with a person 0.3 away;
#   off any building a person within 0.5 wins over a building 0.9 away; else the nearest building within 1.0; else &"none"
# any building: a plain house (not blightable() today) is blighted, its light is gone, dusk covers its centre + 2.9 and not + 3.1 (dark: 4.9 / 5.1), and still does after 300 s
# a building with a use: env.structure_blighted fired and Structure.blighted is true (as today)
# no alarm: crowd alarm before == after, for a house and for the bell tower
# cap: the fourth blight unblights the first (its light back, its dusk gone); the other three stand
# a person: walks home, goes inside, home_sick; no death, no kill credit, alarm unchanged
# dark, a person: that one and the 2 nearest within 2.0 go home; a fourth at 1.5 does not
# quarry: stays on the street, half pace for 20 s
# a BELIEVER under the click is passed over
# nothing in reach: Rules refuses the cast with a reason and no cooldown is spent
# the picked person dies before T_ROT: no error, nobody sent home
# teardown: the effect freed at 0.4 s -> nothing blighted, no dusk laid; (control) left to run -> blighted
```
- [ ] **Step 2: Run** — fails.
- [ ] **Step 3: Implement.** Keep the director path and `T_ROT` as they are. The lasting dusk and the removed light belong to the foothold, not to the effect: they outlive it and end only by the cap or by `Crowd.clear()`. The refusal goes through `Rules.refuse()` with a new reason and HUD words "NOTHING HERE TO BLIGHT".
- [ ] **Step 4: Verify.** `test_veil_blight`, `test_quiet` `failures=0` (update `test_quiet`'s alarm and fizzle checks to the rework, naming §11).
- [ ] **Step 5: Commit** `feat: Blight plants the dark on any building and sends a person home sick`.

### Task 5: Slumber

**Files:** Replace the stub `src/fx/veil/slumber.gd`; Create `tests/test_veil_slumber.gd`.

**Interfaces — Consumes:** `Person.sleep(seconds, deep)`, `DominionParts.near()`, `VeilParts`. **Produces:** `const SLEEP_TIME := 20.0`, `const T_FALL := 0.6`, `static func sleepers_at(field, at, r) -> Array[Person]`.

- [ ] **Step 1: Test.**
```gdscript
# light: people at 1.4 sleep, at 1.6 do not; a soldier sleeps too; all wake at 20 s
# light: a loud blow nearby wakes them. dark (r 3.5): the same blow does not; a hurt does
# quiet: alarm unchanged, no threat registered; dusk laid with r 3.0 (light) / 3.5 (dark)
# someone inside a building is not put to sleep
# two casts on the same person: the sleep runs to the later end, and the first effect's finish does not wake him
# teardown (end_now, freed node): nobody is left deep-asleep past the time; control: left to run, they sleep
# no crowd: builds and finishes
```
- [ ] **Steps 2-4:** run (fails), implement (the look: a slow violet hush settling, eyelid-dark motes; no flash), run (`failures=0`).
- [ ] **Step 5: Commit** `feat: Slumber`.

### Task 6: Cloak of Night

**Files:** Replace the stub `src/fx/veil/cloak_of_night.gd`; Create `tests/test_veil_cloak.gd`.

**Interfaces — Consumes:** `Person.hidden_from_watch()`, `statuses[&"cloak"]`. **Produces:** `const SPAN := 25.0`, `const KEY := &"cloak"`, `static func marked_at(field, at, r, most) -> Array[Person]`.

- [ ] **Step 1: Test.**
```gdscript
# light: the 3 nearest within 2.0 carry the status; a fourth inside 2.0 does not. dark: 8 within 4.0
# while cloaked: hidden_from_watch(); a soldier's fight pick skips them; EscortDirector._seen_by() does not see them
# not a guise: guised() is false, and a Visitors skeleton with spare_guise does not spare them
# the status counts down and is gone at 25 s; a second cast gives the full 25 s again and takes over the count
# teardown: end_now() and a freed node both lift every status this cast laid, and not one a second cast laid
# quiet, dusk laid, no crowd builds
```
- [ ] **Steps 2-4:** run, implement (drawn: a dark shimmer over each cloaked person that only the god's view shows; they walk normally), run.
- [ ] **Step 5: Commit** `feat: Cloak of Night`.

### Task 7: Dreamless

**Files:** Replace the stub `src/fx/veil/dreamless.gd`; Create `tests/test_veil_dreamless.gd`.

**Interfaces — Consumes:** `Person.sleep(.., true)`, `Crowd.take()`, `EnemyField.kill()`, `EnvironmentField.near()`. **Produces:** `const REST := 20.0`, `const T_SIT := 0.8`, `static func victims_at(field, at, r, most) -> Array[Person]`.

- [ ] **Step 1: Test.**
```gdscript
# light: the nearest 1 within 1.0; dark: the nearest 4 within 2.0, by distance then instance id
# an awake victim: sits (deep asleep, statuses[&"dreamless"]) by T_SIT; for the next 20 s no witness reacts and alarm is unchanged;
#   at T_SIT + 20 dies with kind &"dreamless" and leaves a remain; credit goes to the caster
# a victim already asleep at T_SIT (after a Slumber): taken at once with &"dreamt", no remain, alarm unchanged
# a shadow's owner counts as asleep: taken at once
# a victim who dies or goes indoors before T_SIT is skipped without an error
# teardown before the 20 s: nobody dies, the status is lifted and the sleep ends; control: left to run, they die
# quiet, dusk laid, no crowd builds
```
- [ ] **Steps 2-4:** run, implement (the victim walks at most 2.0 to the nearest wall when one is that near, else sits where they stand; the look is a single dark breath leaving the sitter, nothing more), run.
- [ ] **Step 5: Commit** `feat: Dreamless`.

### Task 8: Dread of the Dark

**Files:** Replace the stub `src/fx/veil/dread_of_the_dark.gd`; Create `tests/test_veil_dread.gd`.

**Interfaces — Consumes:** `Crowd.dread/end_dread/dreaded`, `Person.is_dreaded()`, `statuses[&"dread"]`. **Produces:** `const HOLD := 25.0`, `const T_FALL := 0.8`.

- [ ] **Step 1: Test.**
```gdscript
# with dusk at D (4 from the click): a person standing in D is dreaded for 25 s: does not move, is no witness, a soldier there neither fights nor seizes
# a person walking toward D from outside stops at its edge and never enters while it lasts; when it ends they walk on
# lit ground inside the reach is not dreaded: a person there walks freely
# light reach 6: dusk at 7 is untouched; dark reach 12: it is dreaded
# no dark ground within reach: the cast is refused, no cooldown spent
# a NIGHT mission (crowd.night_mission): everyone within 12 of the click is dreaded
# a shadow walks through dreaded ground and is not frozen
# a person frozen by dread who is then put to sleep by Slumber sleeps, and wakes free if the dread has ended
# Evernight starting during a Dread does not end it; two Dreads: ending the first leaves the second's people held
# teardown: end_now() and a freed node both free every person and end the dread; control
# quiet (nobody screams, alarm unchanged), dusk laid at the click, no crowd builds
```
- [ ] **Steps 2-4:** run, implement (the look: the dark ground inside the reach thickens and its edge shows pale eyes that only the god sees; the frozen stand rigid), run.
- [ ] **Step 5: Commit** `feat: Dread of the Dark`.

### Task 9: Shadow Play

**Files:** Replace the stub `src/fx/veil/shadow_play.gd`; Create `tests/test_veil_shadowplay.gd`.

**Interfaces — Consumes:** `statuses[&"shadow"]`, `Person.is_shadow()`, `Crowd.take()`. **Produces:** `const SPAN := 30.0`, `const T_RISE := 1.0`, `const KEY := &"shadow"`.

- [ ] **Step 1: Test.**
```gdscript
# light: everyone within 3.0 at T_RISE is a shadow for 30 s; dark: within 6.0
# a shadow keeps its goal and its post: a guard at a post is still at it after 10 s; a director's busy()/post count is unchanged
# a shadow witnesses nothing: a Silent Doom death 1.0 from a shadow guard settles as unseen (control: an ordinary guard there sees it)
# a shadow soldier does not fight, chase or seize
# Dreamless on a shadow takes them at once
# at the end, light: every shadow is a person again, alive, lying for a moment where the shadow stopped; mind as before
# at the end, dark: the soldiers among them are taken (&"shadow", no remain); the citizens wake
# someone who dies while a shadow is skipped at the end without an error
# teardown mid-span: every status lifted, nobody taken; control
# quiet, dusk laid (r 3 / 6), no crowd builds
```
- [ ] **Steps 2-4:** run, implement (drawn: the person's own sprite as a flat `BLACK` silhouette with a thin `SILVER` edge; where they stood, a faint lying outline only the god sees), run.
- [ ] **Step 5: Commit** `feat: Shadow Play`.

### Task 10: The Swallowing Dark

**Files:** Replace the stub `src/fx/veil/the_swallowing_dark.gd`; Create `tests/test_veil_swallow.gd`.

**Interfaces — Consumes:** `Dusk.r_at()`, `Crowd.take()`, `AnimalPack.in_radius/take`, `EnvironmentField.decor/remove_decor/remove(s, true, true)`, `MissionKeeps.spared()`, `ShelterManager`. **Produces:** `const GROW := 0.5`, `const PER_FRAME := 12`, `static func wholly_inside(s: Structure, at: Vector2, r: float) -> bool` (all four footprint corners within `r`).

- [ ] **Step 1: Test.**
```gdscript
# light: radius 0 at the cast, 5.0 after 10 s, full (10.0) at 20 s. dark, cast in a dusk patch of 3: starts at 3.0, full at 14.0 after 22 s
# while it grows: no threat registered, alarm unchanged, a person inside does not flee; one who walks out before the end lives
# at full size: every person within r is taken (&"void"), every animal, every decor whose `at` is inside
# a house wholly inside is gone: not in env.structures(), `taken`, the walk grid open at its centre, no rubble laid
# a house with one corner outside stands
# a building MissionKeeps.spared() names stands though wholly inside
# people sheltering in a taken building are taken with it
# nothing remembered: alarm unchanged after, no incident, no remains
# the removals never exceed PER_FRAME in one frame; all are done within 1 s of full size
# teardown before full size: nothing is taken; control
# the emptied ground is dusk for 20 s; no crowd builds
```
- [ ] **Steps 2-4:** run, implement (the look: a flat black disc with a thin silver rim that swallows the ground art; at full size a soundless inward fold, then bare dark earth that stays as a ground decal for the mission), run.
- [ ] **Step 5: Bench.** Three alternating pairs of `timeout 300 $G --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench --loadout=swallow` against the same with `--bench-cast=swallow --bench-after=4`. Median cast/base `avg_ms` ratio must be <= 1.55; write it and the worst frame in the rulings file. If over, lower `PER_FRAME` or cheapen the disc.
- [ ] **Step 6: Commit** `feat: The Swallowing Dark`.

### Task 11: Evernight

**Files:** Replace the stub `src/fx/veil/evernight.gd`; Create `tests/test_veil_evernight.gd`.

**Interfaces — Consumes:** `Dusk.everywhere`, `Dusk.laid`, `Dusk.covers()`, `Crowd.veil_all/end_veil_all/spared/take`, `Rules.haste`, `LightField.mute/add_static/remove`, `TownLook.ambient(Town.Look.NIGHT)`, `BlightFx.footholds()`. **Produces:**
```gdscript
const WAVE := 3.0; const DAWN := 3.0; const TORCHES := 6; const TORCH_R := 2.5; const TORCH_COUNT_R := 6.0; const TORCH_CALL := 10.0
static func bearers(crowd: Crowd) -> Array[Person]        # up to 6 living outdoor soldiers, most citizens within 6 first, ties by instance id
static func loneliest(crowd: Crowd, lit: Array) -> Person # the outdoor, unlit, unspared person whose nearest neighbour is farthest; ties by lower instance id; null if none
```
- [ ] **Step 1: Test.**
```gdscript
# after WAVE: crowd.in_dark(ANY), crowd.is_veiled(ANY), rules.haste["veil"] == 2.0, sight scale 0.6 (and 0.6, not 0.36, in a NIGHT mission)
# it lasts 60 s (90 s with crowd.night_mission); after DAWN all four are as they were before the cast, lights included
# the lone: with three clusters and one person alone, the first take (at WAVE + 2.0) is the lone one, kind &"night"; then one every 2.0 s (1.5 s in a NIGHT mission)
# never taken: a BELIEVER standing alone; a person the director keeps_alive; a person indoors; a person in a torch's light
# torches: bearers() picks by the rule (a fixed layout gives a fixed list); each torch lights TORCH_R; citizens within 10 walk to the nearest torch
# a torch put out: laying dusk that overlaps a torch takes everyone within TORCH_R of it (not the spared) and the light is gone
# a bearer killed: his torch goes out the same way
# no dawn: at dawn a person sheltering in a blighted building is taken; a person asleep inside a dusk patch is taken; a sleeper on plain ground wakes
# nothing counted: alarm at dawn equals alarm at the cast though people were taken
# a cast during a running Dread leaves the Dread's people held
# teardown at 10 s: dark, veil, haste, sight, lights all restored, torches removed, nobody else taken; control
# no crowd builds and finishes
```
- [ ] **Steps 2-4:** run, implement. The town's art look is not switched (the game rebuilds a mission to do that): the night is drawn by easing `LightField.ambient` and `tint` to the night values, muting the static lamps, and a star-flecked sky wash, all eased back at dawn. The wave is a dark front running out from the click at map-width / 3 s.
- [ ] **Step 5: Bench** as Task 10 Step 5 with `evernight`; the same bar; record it.
- [ ] **Step 6: Commit** `feat: Evernight`.

### Task 12: Sounds, clips and icons

**Files:** Create `tools/audio/foley/ability/veil/*.json`, `assets/audio/ability/veil/*.wav`, the clip sheets under `PowerBook.CLIP_DIR`; Modify `src/audio/sfx.gd`, `assets/audio/CREDITS.md`, `tests/test_sfx_catalog.gd`, `tests/test_power_sounds.gd`, each Veil effect (its `ctx.play` cues).

- [ ] **Step 1:** Write one recipe per cue and build with `python tools/audio/foley.py <cue>`: a cast cue for each of the seven new powers (`v_slumber`, `v_cloak`, `v_dreamless`, `v_dread`, `v_shadowplay`, `v_swallow`, `v_evernight`), a landing cue for the Swallowing Dark (`v_swallow_take`), a loop for Evernight (`v_evernight_loop`), and `q_blight_ill` for Blight on a person. Quiet sources only (breath, cloth, a held low tone, a lamp guttering); every source must be listed in `tools/audio/foley/SOURCES.md` as allowed in the public repository — nothing Sonniss-derived. Run `python tools/audio/foley.py --credits`.
- [ ] **Step 2:** Add the cues to `Sfx.CATALOG`, play them from the effects, and update the count in `tests/test_sfx_catalog.gd` (592 + the new files) and the loudness expectations in `tests/test_power_sounds.gd`.
- [ ] **Step 3:** Record a preview clip for each of the seven new powers with `tools/capture.sh --capture-clip` (a windowed run: it must use `user://test_*`, never the user's save), so `tests/test_draft.gd` finds `PowerBook.clip(key)` for every key.
- [ ] **Step 4: Verify.** `test_sfx_catalog`, `test_power_sounds`, `test_draft`, `test_skill_tree`, `test_tree_detail` `failures=0`.
- [ ] **Step 5: Commit** `feat: the Veil powers' sounds, preview clips and placeholder icons`.

### Task 13: The Tier 1 gate, references, documents

**Files:** Modify the Veil bots only where a route fails (`src/game/god/` and `tools/dev/` route files), `tools/dev/refs/*.tsv`; Create `docs/KAK_God_Veil_Summary.md`; finish `docs/KAK_God_Veil_Rulings.md`.

- [ ] **Step 1:** `bash tools/dev/god_gate.sh --only=<mission> --jobs=2` for each of the five Tier 1 missions and `bash tools/dev/hunt_gate.sh --only=hide_faithful --type=veil --jobs=2`. Bar: Veil wins >= 2/3 with idle <= 45 s on each (Hunt 1's known misses stay as recorded in `docs/KAK_God_P5_Summary.md`). A route that now fails is fixed in its bot (use the dark: Blight a foothold first, then Doom inside it); the rework is not weakened. Write each change as a ruling.
- [ ] **Step 2:** Run every reference row in chunks of 40. Sort the mismatches: a row that casts a Veil-authority power may move; a row that casts none must not. For each row that must not and did, find the cause and fix it; do not re-record it.
- [ ] **Step 3:** Re-record only the moved Veil-casting rows, and say in the commit message how many and which name patterns.
- [ ] **Step 4:** The whole suite in 16 parts, `failures=0`; FLOW alone on a quiet machine: `timeout 1500 $G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep -aE "FLOW result|FLOW FAIL"` -> `failures=0`.
- [ ] **Step 5:** Write `docs/KAK_God_Veil_Summary.md` (what each power does at level 1 in plain words, both sizes, how to try each in the VFX Sandbox and Remembrance, what is left: levels, Tier 2-5 bots, painted icons) and close the rulings file.
- [ ] **Step 6: Commit** `feat: the Veil tree passes its Tier 1 nights; references re-recorded; summary and rulings`. Stop here: the landing on `feat/god-progression` and any push wait for the user's word.
