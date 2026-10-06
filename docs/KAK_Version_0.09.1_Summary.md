# KAK v0.09.1 — the decisions batch

**Tag:** `kak-v0.09.1`. **Built on:** v0.10 (`88ccb94`).

This batch builds nine decisions the user made on 2026-10-06 from the Dev Ledger's open cards. The plan, with each decision word for word, the measurements and the review notes, is `docs/superpowers/plans/2026-10-06-kak-v0091-decisions.md`.

## What changed

### The soldiers

- **Escorts by need.** Each tier keeps only the escorts it can assign: escorts per duty × duties. The duties are the bell, the rite and each engineer team.

  | Tier | Escorts |
  |---|---|
  | Unaware | 0 |
  | Unprepared | 0 |
  | Organized | 1 |
  | Prepared | 8 |
  | God-Resistant | 10 |

  The other patrollers patrol, investigate and rally, as before v0.07. Raising a night town between acts also raises its escorts.
- **The rally as a reserve.** Once the soldiers have rallied, a marshal, escort or rescuer who dies is replaced by the nearest soldier on the ring. That soldier takes the dead one's role and post, and the role's manager puts it to work.
- **The rally as a garrison.** Each soldier on the ring cuts damage to the Citadel by 2%, up to 30%. F4 shows "Garrison −NN%".

### Pestilence and the engineers

- **Pestilence** spreads within 1.5 units, up from 1.0.
- **Engineers** frightened during the evacuation go back to their team when they calm down; they no longer flee for good.
- **Fire before mending:** a burning building outranks mending a damaged house. The full order is the Citadel, then gates, the bridge and the dock, then Thornwall, then landmarks, then a fire, then a house.

### The Long Night

- **A calm feast:** a warned town's feast breaks only when the god frightens it:
  - a power;
  - a seen kill;
  - the Mayor's death;
  - or a cast whose danger reaches goers already fleeing.

  Goers sent away or out of town by the town's own evacuation do not count.
- **The rite at night:** a completed Banishing Rite costs 20 s in The Long Night. It still costs 40 s in Last Judgement and in the campaign's Feast.
- **Per-act DP:** Act I 6 DP / 3 slots, Act II 10 DP / 4 slots, Act III 14 DP / 4 slots. The board card reads "6 DP rising to 14".
- **A rank cap:** a night with any act lost ranks at most B.
- **The Mayor's death** frightens only goers within 8 units of the fountain.

## Gates

- Tests: 3726 checks, 0 failures.
- State digest, crowd_check and FLOW (86 checks) unchanged.
- The Warning's five cases and the calm, escort and rescue scenarios are unchanged.
- Four scenario checksums changed, each traced to one rule by reverting it:
  - `gates`, `fire` and `rite --interrupt` move with the escort cap;
  - `soldiers --case=marshals` moves with the escort cap, and again with the engineers no longer fleeing at the evacuation.
- Pestilence scenarios move with the 1.5 reach.
- The v0.10 campaign's Feast still wins all six played runs at the same times.
- Played Long Nights still win on both paths, rank A.

## Fixes found on the way

- `Crowd.on_ring()` errored on a freed soldier, which stopped the ring count.
- `EngineerManager.begin()` errored on a freed engineer, which stopped the turn-out.

Both now skip freed people. Each has a test.

## Open questions for the user

1. **The Mayor's 8-unit reach barely helps.** During his address 68 of 80 goers stand within 8 units and only 50 are needed, so one Silent Doom on the Mayor still wins the Festival. Options:
   - a radius of about 3;
   - only a seen death counts;
   - a higher need.
2. **The garrison is effectively a flat 30% from the first hit.** The rally happens on the first hit, and the Citadel's 20 guards already reach the cap of 15. If each garrison kill should matter, retune the step and the cap.
3. **Refills happen even on an unseen Silent Doom kill:** a ring soldier runs to replace a death the town "doesn't know" about.
4. **Ring soldiers who are compelled or made to fight** go back to their old post, not the ring, so Dominion and Discord can strip the garrison for good. This could be counterplay.
5. **The save keeps the rank of the best score,** so a capped B night with a higher score replaces an earlier S as the saved best rank.
