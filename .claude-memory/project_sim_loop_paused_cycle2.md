---
name: project-sim-loop-paused-cycle2
description: "CONVERGED 2026-09-04: cycles 3 and 4 both ran clean back to back, meeting the two-clean-cycles-in-a-row stopping condition. Campaign done; several low-priority open items remain for a future non-urgent pass."
metadata: 
  node_type: memory
  type: project
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
  modified: 2026-09-04T17:08:50.247Z
---

**CONVERGED 2026-09-04.** Cycle 3 (fresh bootstrap, Astrid accepted via the
new opt-out-by-default ask, PC B's Wake Up correctly cloned her fresh on a
genuine machine switch — the original cycle-1 fix validated end-to-end for
the first time) and cycle 4 (fresh bootstrap, blind session skipped the ask
and correctly applied the documented non-interactive fallback instead,
Astrid's sibling-clone check fired correctly again) both came back clean.
Two in a row meets the stopping condition in
[[feedback_simulation_loop_protocol]] — the campaign is done unless the user
starts a new one. Full account: `C:\Claude\sim-testing\cycle-log.md`.

**A real methodology lesson landed mid-campaign, recorded in
[[feedback_simulation_loop_protocol]]:** a blind PC correctly refuses to
commit/tag/push on the orchestrating session's relayed instruction (the same
cross-session-permission-laundering principle `luna-core-docs-writer`
already enforces) — this is desired behavior, not a bug. The orchestrator
now finishes the mechanical git steps directly once a blind PC's prep work
is done, rather than fighting this.

**Open items left for a future non-urgent pass** (none blocking, all
navigated correctly when they came up — logged in
`tests/notes/open-items.md`):
- `readme-step5-blind-dispatch-detection` — two identically-worded blind
  dispatches diverged on whether to pause and ask about Astrid vs. apply
  the non-interactive fallback directly; the outcome converges safely
  either way, but the doc doesn't tell an agent how to know which case it's
  in.
- `wake-up-first-clone-placement` — `wake-up.md` never actually addresses a
  genuinely bare machine with zero local checkout (step 1 assumes one
  already exists); where to place a first-ever clone relative to Astrid is
  currently inferred, not documented.
- `debrief-self-stale-handoff-note` — `HANDOFF.md`'s "commit hasn't
  happened yet" note can end up baked into the very commit that performs
  it, when the actual commit is finished by someone other than whoever
  wrote the note (see the methodology lesson above).

---

**Update 2026-09-04 — this memory's original content below is now history,
not current state.** The README/CHANGELOG wordiness pass happened first
thing this session, as planned. Cycle 2 then ran: PC A bootstrapped clean
from `main`, qa-tester verified everything including cycle 1's fix holding
on a genuine real-world bootstrap — but Astrid was never wired in. That
turned out to be *correct* behavior under the then-current policy (pure
opt-in), not a bug, but the user decided the policy itself should flip:
Astrid is now brought in **by default**, opt-out instead of opt-in
(`README.md`'s Getting Started step 5 rewritten to introduce her and ask
directly; declining removes her `CLAUDE.md` bullet and skips the clone).
Fixed, merged to `main` as `ver-0.2.0.0`. PC B/Wake Up was never reached
this cycle — PC A's Debrief got interrupted once the policy question came
up, so cycle 2 stopped early. Full account logged at
`C:\Claude\sim-testing\cycle-log.md`.

**Current state going into cycle 3:** clean streak is 0 (cycle 2 produced a
real fix, even though framed as a policy decision rather than a bug). Cycle
3 needs to confirm the new Astrid default-inclusion flow actually works in
practice — the real thing this cycle exists to test — plus reach PC B/Wake
Up for the first time since cycle 1.

---

## Original content (2026-09-03, now historical)

Session ended 2026-09-03 without running `/debrief` (user explicitly said not
to). See [[feedback_handoff_only_at_debrief]] and
[[feedback_simulation_loop_protocol]] for the surrounding protocols — this
memory exists to cover the gap that skipping Debrief leaves, since
`handoff/HANDOFF.md` was not updated to reflect this session's end state.

## Where the simulation loop stands

Cycle 1 of the two-PC blind onboarding/handoff simulation found three real
defects (two from the simulation itself, one found independently by
`luna-core-docs-writer` during a routine memory-merge step):

1. `commands/wake-up.md` never checked for a missing sibling-clone dependency
   (Astrid) on a new machine.
2. `bootstrap-new-project.sh`'s rename chain mangled the literal filename
   `validate-luna-core-setup.sh` inside agent body text.
3. `scripts/merge-memory.sh`'s `MEMORY.md` union only wrote back in one
   direction, silently dropping the newer side's exclusive entries.

All three fixed, test-first, independently QA-verified, and fully landed:
committed to `dev`, tagged, merged to `main` through the real docs-writer-
mediated procedure, tagged again on `main`, both branches pushed. A fourth,
smaller gap (the functional `.claude/commands/wake-up.md` copy being out of
sync with the template) surfaced during the merge itself and was fixed and
merged the same way. Final state: **`main` is at `ver-0.1.6.1`, `dev` at
`ver-0.1.6.1-dev`, in lockstep, validator-clean on both branches.**

**Why this matters for the next cycle:** PC A in this test onboards from
Luna-Core's `main` branch specifically (not `dev`) — confirmed explicitly by
the user this session ("doesn't PC A take from our main"). So all three
fixes had to actually reach `main`, not just `dev`, before a re-run would be
a meaningful test. That's done.

**Cycle count:** still 1 clean-streak-reset (cycle 1 found real findings, so
the "two clean cycles in a row" stopping condition per
[[feedback_simulation_loop_protocol]] has not started accumulating yet).
Logged at `C:\Claude\sim-testing\cycle-log.md`.

**The loop is paused, not stopped** — the user said "pause before we run
simulation 2," not that they were done with the campaign. Resume cycle 2
(reset the harness, PC A onboards from `main`, Debrief to the throwaway
remote, PC B Wake Up) on the user's go-ahead, not automatically.

## First task next session, before resuming the loop

The user wants a pass over Luna-Core's `README.md` and `CHANGELOG.md` to
check they aren't too wordy, before getting back into cycle 2. Offer this
first when the session picks back up, rather than jumping straight to
resetting the harness.
