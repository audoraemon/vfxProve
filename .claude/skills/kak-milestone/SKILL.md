---
name: kak-milestone
description: Use when the KAK user brings a new game design (missions, a tier, a system) to build and land on feat/Develop-Main, or asks to run a version or milestone straight through subagent-driven
---

# Running a KAK milestone fast

## Overview
v0.11 took a week: four days were a weekly usage limit (opus everywhere), the rest was slow checks, design redo rounds
and stacked reviews. This skill is the cheaper, faster way. **REQUIRED SUB-SKILL:** superpowers:subagent-driven-development
for the loop itself; this skill sets who does what and which checks run when.

## 1. Before any spec: check the design on paper
Run each mission idea through memory `kak-mission-design-lessons` (chain arithmetic, spread opposition, stages not
seals, no luck, no hidden losses, countdown tags). Show the user the gaps in chat and get a yes. Most v0.11 fix rounds
were these.

## 2. Who does what
| Work | Model | Review |
|---|---|---|
| Mission spec + plan (one pass, one agent) | opus | controller reads; opus pre-flight scan |
| Plan content | interfaces, tests, numbers to tune; **no full code** | — |
| Mission or shared-code task | sonnet (opus only for a redesign) | sonnet task review |
| Wishes, board, docs, photos | sonnet | none per task; the milestone review covers them |
| Fix rounds | resume the same implementer | haiku re-review |
| Milestone final review | opus | one fix wave, sonnet re-review |

Dispatch prompts are files: copy `implementer.md` (this folder) into the workspace once; each dispatch is two lines.

## 3. Checks: per task vs at landing
| When | Run |
|---|---|
| Per task | focused tests; `bash tools/dev/run_suite_parallel.sh 8` before commit (~5 min); `bash tools/dev/refs_check.sh --only='<touched scenarios>'`; the mission's gate; FLOW only if FLOW/board/shared directors changed |
| Landing | `bash tools/dev/land.sh --bench=<last tag>` (trial merge, suite, all references, FLOW alone, bench); it never pushes |

New mission references go in `tools/dev/refs/references.tsv` in the task's commit.

## 4. Scheduling
- Groundwork first; then one worktree per mission, run in parallel, merged at the milestone.
- Keep the laptop awake (`mcp__ccd_host__request_keep_awake`) for long runs.
- Before FLOW or a bench: no other session's Godot running (land.sh waits).

## 5. Landing
Memory `check-before-every-merge`, then ff feat/Develop-Main, tag `kak-vXYZ-mN`, push, update the Dev Ledger
(memory `kak-dev-ledger`). Collect every `Ruling:` line into the version's rulings doc.

## Common mistakes
- Two reviews per task on every task: burns the weekly limit. Mechanical tasks get none.
- Full-suite + all 119 references after every task: hours. Touched references per task; everything at landing.
- Tuning the opposition down to pass a gate: fix the scripted policy first.
- Writing full code into the plan: it drifts and the pre-flight finds blocking issues anyway.
