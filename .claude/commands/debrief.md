---
description: Debrief Protocol — wrap up work on this project so it can be picked up cleanly by anyone with no prior context
---

# Debrief Protocol

Wrap up work on this project so it can be picked up cleanly by anyone (a
different person, a different AI, a different computer) with no prior
context. Run through these steps in order.

## 1. Prep the docs

Perform (or invoke) this project's docs-writer duties: make sure
`CLAUDE.md`, `README.md`, `CHANGELOG.md` (with a current version entry —
see "Versioning & CHANGELOG entries" in the docs-writer agent),
`ref/docs/*.md`, and `.claude/agents/*.md` are all current and reflect the actual
state of the project.

## 2. Merge the memory mirror

Run `bash scripts/merge-memory.sh` (if this project has it) so this
machine's local auto-memory and the repo's `.claude-memory/` end up
agreeing, and the memory roams with the user instead of being stranded
here.

This is its own step because it's easy to skip and the failure is silent:
nothing breaks locally, and the loss only shows up later on a different
machine as memory that never arrived, or a `MEMORY.md` index pointing at
files that aren't there.

It's a comparison, not a copy — it moves only the genuinely newer side of
each file, so it's safe to run even if you're unsure which side is ahead.
Two things it deliberately won't decide for you, and will instead report:
a file that exists on one side only (it copies it across and never
deletes, since absence has no timestamp to judge), and a file with the
same timestamp but different content.

Afterwards, actually read what it reported and check `git status
.claude-memory/` rather than assuming it worked. If any memory file
mirrors a repo file, update that mirror *before* merging, or the merge
faithfully carries a stale version.

## 3. Write the handoff notes

Update `handoff/HANDOFF.md` with everything a total stranger (person or
AI) would need to continue this project from exactly where you're leaving
it. At minimum:

- What was being worked on, and its current state (done / in progress /
  blocked)
- Any decisions made this session and why, especially ones not yet
  reflected elsewhere
- Anything uncommitted, and why (if there's a reason it wasn't committed) —
  meaning genuinely separate work still open beyond this session, not this
  Debrief's own pending commit/publish decision. That part is inherent to
  every Debrief run and self-resolving: step 5 handles it right after this
  note is written, so asserting it here just goes stale the moment step 5
  runs, baked into the very commit that discharges it. Wake Up's own step
  3c already checks live git state independently rather than trusting this
  file for that.
- Concrete next steps
- Anything the previous handoff flagged that's now resolved, so it doesn't
  get re-flagged

Overwrite the previous content — this file always reflects the *current*
handoff, not a running log. (Historical handoffs are what git history and
`CHANGELOG.md` are for.)

## 4. Update the tracking record

Write this machine's computer name (`hostname` on macOS/Linux/Git Bash,
`$env:COMPUTERNAME` in PowerShell) and the current date/time into
`handoff/STATUS.md`.

## 5. Ask to commit and publish

**Before asking: make sure `handoff/HANDOFF.md`'s "Where this project
publishes" section is filled in** -- the exact bundle path or remote URL,
under that exact heading, since Wake Up's first step looks for it by name.
If it still says nothing is published yet and the project does have somewhere
to publish to, fill it in now.

A clone does not carry the address it came from. Wake Up's first step looks
in this project's own docs to learn where to fetch from, so if nothing records
it, a session starting on a new machine has no way to discover it and the next
person has to be told out of band -- which is exactly the dependency on human
memory this protocol exists to remove.


Everything above is prep — do not commit or publish anything yourself.
Once steps 1-4 are done, ask the user for explicit permission to commit
and publish (per the project's standing git-permission rule), the same as
any other commit. Don't assume it's wanted just because Debrief was run —
the user might have something else to do first. A little personality in
how you ask is welcome; this is the user-facing wrap-up moment.
