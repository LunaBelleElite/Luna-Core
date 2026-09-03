# Open items

An **index**, not the detail: one row per open question. Give each a stable id,
the question in one line, where the detail lives, the exit condition, and the
test that owns it. Delete a row when it closes rather than annotating it.

Read whole on every qa-tester pass — it is meant to stay one screen.

| id | Question | Detail in | Exit condition | Owning test |
| --- | --- | --- | --- | --- |
| OI-1 | Should content drift between a template and its functional copy fail the run, when a missing functional copy already does? | `notes/live-checks.md` → drift-check section | A ruling: either content drift sets `overall_status`, or the split is stated in the script's comment as deliberate | Template-vs-functional drift |
| OI-2 | The roster reverse-check misses an on-disk agent whose filename carries no role suffix (`luna-core-orphan.md` appears nowhere in the output) | `notes/live-checks.md` → drift-check section, final paragraph | Either the check covers all `.claude/agents/*.md`, or its comment stops claiming it catches undeclared agents | Template-vs-functional drift |
