# Open items

An **index**, not the detail: one row per open question. Give each a stable id,
the question in one line, where the detail lives, the exit condition, and the
test that owns it. Delete a row when it closes rather than annotating it.

Read whole on every qa-tester pass — it is meant to stay one screen.

| id | Question | Detail in | Exit condition | Owning test |
| --- | --- | --- | --- | --- |
| readme-step5-blind-dispatch-detection | How should a dispatched (not directly chat-facing) subagent decide whether it's the "interactive" or "fully non-interactive" branch of README step 5's Astrid ask, given cycle 3 and cycle 4's identically-worded blind dispatches diverged (ask-and-wait vs. skip-to-fallback)? | `live-checks.md` "Sim loop cycle 4" entry | Either the wording gains a concrete detection rule for a dispatched-agent caller, or a future sim cycle shows dispatches converging on one behavior without a wording change, or it's ruled a harness-only artifact not worth chasing further | two-PC blind sim loop (manual, `feedback_simulation_loop_protocol.md`) |
