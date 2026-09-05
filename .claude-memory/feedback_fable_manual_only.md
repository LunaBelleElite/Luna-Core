---
name: feedback-fable-manual-only
description: "Fable is manual-only by default in every project — except Luna-Core and Astrid, where a standing grant (2026-09-05) lets the assistant dispatch agents on Fable when the task genuinely fits. The carve-out is deliberately kept out of Luna-Core's CLAUDE.md so bootstrapped projects don't inherit it."
metadata: 
  node_type: memory
  type: feedback
  modified: 2026-09-05T15:23:54.390Z
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
---

**Default rule (2026-09-03, reaffirmed 2026-09-04):** the user reserves
**Fable** for projects they personally decide need it, and invokes it
themselves. **The assistant works with Sonnet and Opus only, and never
dispatches an agent on Fable.** This holds even on Max/Premium tiers where
[[feedback_model_selection]] otherwise says "pick whichever model is
best-suited, task by task."

**Standing exception, granted 2026-09-05 — Luna-Core and Astrid only:** "For
Luna-Core and Astrid, when working on the projects, I am giving you the
ability to use the Fable model when it is appropriate. This is specific to
Luna-Core and Astrid development." So, in those two repos:

- The assistant **may** dispatch agents on Fable without asking each time,
  when the task genuinely fits Fable — hard design, precision-on-first-pass
  spec or personality prose, subtle debugging with a non-local cause.
- **"When appropriate" is the whole condition.** Fable is not a new default
  and does not displace the routing rule: mechanical edits, sweeps, test
  runs and routine doc passes still go to Sonnet; Opus is still the ordinary
  top of the routing range. Fable is for the cases where a wrong first pass
  is expensive.
- **Name the agent and the model out loud at every dispatch**, as always.
- Known behaviour from the 2026-09-04 trial: Fable was the *wrong* fit for
  voice-matched spec prose once the design was already settled (Opus was
  right), and it hit a session rate limit mid-task — a real risk for
  anything that must not be cut off half-done. Weigh that when choosing.
- Outside these two repos the default stands unchanged. A short-lived,
  budget-based exception elsewhere ("tokens to burn this week") is not a
  rule change; when in doubt treat it as expired and ask.

**Where this is recorded, and where it deliberately is not.** The carve-out
lives in the machine-global `C:\Claude\CLAUDE.md` and here. It is **not**
written into Luna-Core's repo-root `CLAUDE.md`, whose "Match model to license
tier and task" → point 1 still says Fable is excluded and manual-only. That
wording is correct as written and should not be "reconciled": that file is
copied verbatim into every project bootstrapped from Luna-Core, so loosening
it there would hand the exception to every unrelated downstream project. The
global file is machine-scoped and never copied by bootstrap, which is why it
is the right home for a two-repo carve-out. Astrid has no `CLAUDE.md` of its
own, so it is governed by whichever session adopts her plus the global file.

**Correction trail:** a 2026-09-04 version of this memory wrongly declared
the manual-only rule SUPERSEDED, citing a global line reading "The 'most
capable' subagent tier is Fable, not Opus." The user corrected that ("the old
rule is correct for Fable is manual only"), the global line was rewritten,
and Luna-Core's `CHANGELOG.md` `ver-1.0.0.3-dev` entry still repeats the wrong
claim as a dated historical note — superseded, not to be edited retroactively.
The 2026-09-05 grant above is a genuine, user-stated change on top of the
corrected rule, not a re-run of that mistake.

**Why the default exists:** on 2026-09-03 a session under-routed seven agent
dispatches onto Sonnet because the recorded license tier was stale (see
[[user_license_tier]]). The fix — dynamic per-task routing across
Sonnet/Opus — had a boundary the user drew explicitly: Fable stays out of the
pool the assistant routes into. That boundary now has two named openings in
it, and nowhere else.
