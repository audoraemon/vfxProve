# Implementer instructions (KAK milestone; the dispatch names TASK N, its WORKSPACE and its worktree)

Copy this file into the plan's SDD workspace and fill the <...> fields once per milestone; every dispatch then says only
"Read and follow <WORKSPACE>/implementer.md with N = <n>" plus the task's rulings and the references it must keep.

Working directory: <WORKTREE> (never cd to the repo root; never touch other worktrees). Godot 4.7.2 GDScript game KAK.

## Read first
1. Your brief: <WORKSPACE>/task-N-brief.md.
2. <WORKSPACE>/global-constraints.md (commands, style, freed-body rules, references, test style).
3. <WORKSPACE>/rulings.md (controller rulings, binding over the plan text; find the ones naming your task).
4. The spec <SPEC> and plan <PLAN> for context; earlier tasks' reports in the workspace show what exists.

## The user's binding mission rules (every mission task's gate)
- Finished by acting, never by waiting; every timed wait ≤60 s; doing nothing loses 3/3; the scripted player wins ≥2/3;
  median clear 180-240 s; no idle stretch over 45 s for an acting player.
- Objective clarity first: every moving target tagged with an edge arrow; tags count down like the strip; plain hints;
  camera spots clear of the HUD stack (Kit.STACK grown by Hud.STACK_PAD).
- If the gate misses, first make the scripted policy work the opposition as a player would; then tune in the spec's
  order, at most three rounds; if it still misses, report DONE_WITH_CONCERNS with the numbers.
- No existing checksum moves (tools/dev/refs/references.tsv). A reference that moves on purpose is re-recorded there in
  the same commit with the reason.

## Commands (foreground only; never run_in_background, never a Monitor; each command under 10 minutes)
- NEVER stop, kill or close a process you did not launch (no Stop-Process/taskkill/pkill by name): other sessions and the user run Godot,
  refs_check.sh and land.sh on this machine too. Record the PID of each process you launch and stop only those; a run that looks
  like your job is not yours unless you launched it.
- Import after a new class_name or test file: `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
- Focused tests while iterating; before committing the whole suite: `bash tools/dev/run_suite_parallel.sh 8` (~5 min).
- References: only the ones your change can reach, e.g. `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|<your scenarios>)'`.
  The full list runs at the milestone's landing, not per task.
- Your mission's gate: `--scenario=<id> --case=none|play --seed=1..3` (record the six checksums in references.tsv).
- FLOW only if your task touches FLOW, game.gd, the board or a shared director: check `tasklist | grep -i godot` first;
  FLOW aborts under parallel load, so rerun alone before concluding anything.
- Shared files (mission_book.gd, mission_hints.gd, results_screen.gd, behaviour_check.gd, run_all.gd, the spec): if
  another task works in the same worktree, stage only your own hunks (`git add -p`, check `git diff --cached`).
- Python here defaults to cp874: pass encoding='utf-8' or use the Edit tool.

## Your job
Implement the task with the rulings applied; tests first where the brief says so (RED then GREEN); verify as above; one
commit ending `Co-Authored-By: <the attribution line the session gives>`; self-review your diff; report. If the brief
contradicts the code and the rulings don't settle it, report NEEDS_CONTEXT. You do not dispatch subagents.

## Report
Full report to <WORKSPACE>/task-N-report.md (what changed; tests with RED/GREEN; suite count; references run; the gate
table per seed with none/play outcome, time, checksum, idle; tuning rounds; files; concerns). Reply in under 15 lines:
Status; commit; test one-liner; gate one-liner; concerns; report path.
