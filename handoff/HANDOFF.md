# Handoff notes

Current state of this project, written so a person or AI with zero prior context could continue from here. Overwritten each time the Debrief Protocol runs — this always reflects the *current* handoff, not a running log (see `CHANGELOG.md` for that).

## Where this project publishes

`origin` is `https://github.com/LunaBelleElite/Luna-Core.git`, a private GitHub repository. "Publish" means an ordinary `git push` — no bundle, no synced-drive hub folder.

Recorded under this exact heading because the Wake Up protocol's first step looks for it by name — a clone carries no record of the address it came from.

`ver-0.1.0.0-dev` is committed and pushed (`be3fb7f`) — `dev` has git history now, not the empty-repo state this section used to describe.

## What this project is

Luna-Core is a starter kit. Every new project is bootstrapped from it so they all inherit the same conventions instead of each drifting into its own: four custom agents (docs-writer, research, qa-tester, implementer), the Wake Up / Debrief session protocols, a baseline `CLAUDE.md`, the `ver-A.B.C.D` versioning scheme, and memory that roams between machines.

The target workflow it exists to serve: get a new computer, point at the repo, run Wake Up, and have everything you need to work.

## Current state

`ver-0.1.1.0-dev`, staged and pending the user's commit approval (not yet committed — see `CHANGELOG.md` for the full entry). `ver-0.1.0.0-dev` is already committed and pushed to `dev` (`be3fb7f`). This pass is a defect batch: three script bugs found by testing (one, in `merge-memory.sh`, was silent memory loss — the most serious fix in it), two `CLAUDE.md` rulings (Fable manual-only; a new section 5, "Verify Interfaces Before Testing"), a corrected license-tier memory entry, and expanded test coverage. Full detail in `CHANGELOG.md`'s `ver-0.1.1.0-dev` entry.

## In progress / not yet resolved

- **`ref/docs/` is empty**, while `CLAUDE.md` instructs every session to consult it before reading source files. The scripts that carry the real logic — `validate-luna-core-setup.sh`, `merge-memory.sh`, `bootstrap-new-project.sh` — have no doc pages yet.
- **The `agents/` templates keep their fill-in blanks on purpose** — `<projectname>`, `<directory>`, qa-tester's `## Stack` block, implementer's Part Two — since that is what a new project inherits and fills in for itself. Luna-Core's own functional copies in `.claude/agents/` have all of them filled in and are fully usable. The setup validator excludes those regions when comparing the two, so filling them is not reported as drift.
- **Both superpowers dependencies are now installed** on this machine (ASUNA-PC) — `superpowers-extended-cc` via the real plugin/marketplace system, and Claude Code on Steroids installed by hand after auditing its published installer (which has its own bugs — see `.claude-memory/claude_code_skill_stack_setup.md`). `scripts/check-superpowers.sh` exits 0 here. They still cannot be installed by a script, by design — one needs interactive `/plugin` slash commands, the other pipes a remote installer into bash — so a fresh machine still has to run through `scripts/check-superpowers.sh`'s reported steps by hand.
- **A known defect remains in the template-vs-functional drift check**, found but not yet fixed this pass: `validate-luna-core-setup.sh`'s comparison filters out any differing line containing `luna-core-` (via `grep -Fv "${LC_PROJ}-"`) to tolerate expected fill-in differences, but the filter is too permissive — it silently accepts a semantic edit to *any* line that happens to contain that token, including an inversion of a "what you don't do" constraint (measured, see `tests/notes/live-checks.md`). Content drift of this kind is reported as `NOTE:` at best and never fails the run.
- **Two open questions tracked in `tests/notes/open-items.md`:** OI-1 — should content drift between a template and its functional copy fail the run, given a missing functional copy already does? OI-2 — the roster reverse-check misses an on-disk agent whose filename carries no role suffix. Neither is ruled on yet.

## Next steps

Decided with the user, not assumed here.
