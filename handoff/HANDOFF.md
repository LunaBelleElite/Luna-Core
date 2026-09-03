# Handoff notes

Current state of this project, written so a person or AI with zero prior context could continue from here. Overwritten each time the Debrief Protocol runs — this always reflects the *current* handoff, not a running log (see `CHANGELOG.md` for that).

## Where this project publishes

`origin` is `https://github.com/LunaBelleElite/Luna-Core.git`, a private GitHub repository. "Publish" means an ordinary `git push` — no bundle, no synced-drive hub folder. Nothing has been pushed yet; `dev` has no commits.

Recorded under this exact heading because the Wake Up protocol's first step looks for it by name — a clone carries no record of the address it came from.

## What this project is

Luna-Core is a starter kit. Every new project is bootstrapped from it so they all inherit the same conventions instead of each drifting into its own: four custom agents (docs-writer, research, qa-tester, implementer), the Wake Up / Debrief session protocols, a baseline `CLAUDE.md`, the `ver-A.B.C.D` versioning scheme, and memory that roams between machines.

The target workflow it exists to serve: get a new computer, point at the repo, run Wake Up, and have everything you need to work.

## Current state

`ver-0.1.0.0-dev`. Git repository initialized on `dev`, `origin` wired to the GitHub remote, no commits yet.

## In progress / not yet resolved

- **The repo has a git history of zero.** `dev` is initialized and `origin` points at the private GitHub remote, but nothing has ever been committed, tagged, or pushed. `scripts/install-global-entrypoint.sh` no longer needs a published bundle — it now only needs an `origin` remote, which exists — but running it, committing, and pushing are all still outstanding.
- **`ref/docs/` is empty**, while `CLAUDE.md` instructs every session to consult it before reading source files. The scripts that carry the real logic — `validate-luna-core-setup.sh`, `merge-memory.sh`, `bootstrap-new-project.sh` — have no doc pages yet.
- **The `agents/` templates keep their fill-in blanks on purpose** — `<projectname>`, `<directory>`, qa-tester's `## Stack` block, implementer's Part Two — since that is what a new project inherits and fills in for itself. Luna-Core's own functional copies in `.claude/agents/` have all of them filled in and are fully usable. The setup validator excludes those regions when comparing the two, so filling them is not reported as drift.
- **The two superpowers dependencies cannot be installed by a script**, by design — one needs interactive `/plugin` slash commands, the other pipes a remote installer into bash. `scripts/check-superpowers.sh` reports what is missing and prints the exact commands for the user to run.

## Next steps

Decided with the user, not assumed here.
