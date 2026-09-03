# Live checks

Things verified by actually running the toolkit rather than by reading it, and
what they showed. Read on every qa-tester pass.

Record a result here when running something taught you a fact that reading it
would not have — a measured value, a behaviour that contradicted the docs, a
trap that cost a round. Keep each entry to what a future pass needs so it does
not re-derive the same thing: what was run, what it showed, and what follows
from it.

## Referenced folders need a keeper file (2026-09-02)

`check()` uses `[ -e "$2" ]`, which is true for a directory whatever is inside
it — so before `check_keeper()` existed, a `ref/docs/` whose `.gitkeep` had been
deleted reported `OK: ref/docs/ folder` and the run exited 0. Measured, not
assumed. That left `CLAUDE.md`'s "a referenced folder must be created, with a
keeper file" rule only half enforced: the folder's existence was checked, its
survival was not.

**The recipe, if you need to re-prove it.** Build the fixture with
`bootstrap-new-project.sh` into a throwaway under the system temp dir —
**not** with `cp -r`. A raw copy sits at a different path than the one the
agents record, which trips the "Agent repo paths" check and makes the run exit
1 for an unrelated reason; an exit-code-only assertion then passes for the
wrong cause. Bootstrap leaves each agent's `<directory>` placeholder unfilled,
and the path check skips any claimed path containing `<`, so a bootstrapped
fixture is quiet. Assert on the specific `EMPTY:` line, not just the exit code.

Delete the fixture's `ref/docs/.gitkeep`, run its validator: expect the `EMPTY:`
line and exit 1. Comment out the `check_keeper` call and re-run: expect the line
gone and exit 0, with the final banner flipping from "File setup verified" back
to "Setup INCOMPLETE" — that banner change is the check propagating
`overall_status`, not a second failure.

`find -type f` is recursive on purpose: a folder holding only an empty
subdirectory still vanishes wholesale on clone, so "has a subfolder" is not
"has content". Measured: `ref/docs/empty-subdir/` and a five-level empty tree
both report `EMPTY:` correctly.

**Which folders need a keeper check, and which don't — settled, don't re-derive.**
Only two folders are protected by nothing but a `.gitkeep`, so only those two
need `check_keeper`: `ref/docs/` and `.claude-memory/`. Every other referenced
folder already has at least one mandatory file that `check()` verifies by name,
so it cannot go silently empty — `tests/` via `TESTING_NOTES.md` (measured:
removing it gives `MISSING` and exit 1), `handoff/` via `STATUS.md`,
`.claude/commands/` via `wake-up.md`, `scripts/` via `merge-memory.sh`, and
`.claude/agents/` via the CLAUDE.md roster cross-check.

`.claude-memory/` was missed when `check_keeper` was first added, and the gap
mattered most in a *bootstrapped* project, where that folder contains only its
`.gitkeep` — in Luna-Core itself it holds real memory files, so the check passes
there whether or not the bug exists. That asymmetry is why this has to be tested
on a bootstrapped fixture and not on Luna-Core.
