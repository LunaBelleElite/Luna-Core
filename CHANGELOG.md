# Changelog

## Versioning scheme

This project uses a 4-number version format: `ver-A.B.C.D`. The `ver-` prefix is always present.

- **A (1st number):** a complete redesign/rewrite of the whole program or layout.
- **B (2nd number):** changes to core features, short of a full redesign.
- **C (3rd number):** large bug fixes.
- **D (4th number):** very small bug fixes. A doc/spec-only addition (no feature, no bugfix) counts as a 4th-number change too, same treatment as a minor bugfix.

Any number can climb arbitrarily high. When a higher-order number increments, every number to its right resets to 0.

**Pre-1.0 phase:** development starts at `ver-0.1.0.0-dev`. Until this project reaches `ver-1.0.0.0`, anything that would normally increment the 1st number instead increments the 2nd number — the 1st number stays locked at 0 for the entire pre-1.0 phase. The 3rd and 4th numbers behave normally throughout. Moving to `ver-1.0.0.0` only happens when the user explicitly says so.

`dev` and `main` carry the exact same version number in lockstep — the only difference is `dev`'s version string has `-dev` appended.

(Full detail, including the "why," lives in `CLAUDE.md`. This section is not edited when entries below are added — only when the scheme itself changes.)

## ver-0.1.0.0-dev - 2026-09-02

Luna-Core's starting state: the starter kit every project on this machine is
bootstrapped from.

- Four agent templates (`luna-core-docs-writer`, `luna-core-research`,
  `luna-core-qa-tester`, `luna-core-implementer`), in `agents/` as template
  source and `.claude/agents/` as the functional copies Claude Code invokes.
  **Agent identifiers are lowercase**, `<projectname>-<role>`; bootstrap
  lowercases the project name for them, so `TestProj` yields
  `testproj-qa-tester` while prose still reads `TestProj`. The templates keep
  their fill-in blanks (`<projectname>`, `<directory>`, qa-tester's `## Stack`,
  implementer's Part Two) for a new project to fill in; Luna-Core's own
  functional copies have them filled in, and the validator excludes those
  regions when comparing the two.
- The Wake Up and Debrief session protocols, as `/wake-up` and `/debrief`.
- A baseline `CLAUDE.md` carrying the operating rules every bootstrapped
  project inherits, including this versioning scheme.
- `scripts/` — `bootstrap-new-project.sh` to set up a new project,
  `validate-luna-core-setup.sh` to confirm it landed, `merge-memory.sh` for
  memory that roams between machines, `install-global-entrypoint.sh` for the
  machine-level entry point, and the dependency/prerequisite checks.
- `scripts/lib-claude-home.sh` resolves Claude's config directory from
  `CLAUDE_CONFIG_DIR` when it is set, falling back to `$USERPROFILE/.claude`
  and `$HOME/.claude`. Without that first branch, a machine that sets
  `CLAUDE_CONFIG_DIR` has every script read and write where Claude Code never
  looks.
- The setup validator enforces `CLAUDE.md`'s "a referenced folder must be
  created, with a keeper file" rule in full: `check()` proves a folder exists,
  `check_keeper()` proves it still holds a file. It guards the two folders that
  are backed by nothing but a `.gitkeep` — `ref/docs/` and `.claude-memory/`;
  every other referenced folder has a mandatory file checked by name. Git tracks files rather than
  directories, so a folder whose keeper was deleted is simply absent after the
  next clone — a failure that appears on the second machine, not the first.
  The recipe for re-proving it is in `tests/notes/live-checks.md`.
- The hub is a private GitHub repository at
  `https://github.com/LunaBelleElite/Luna-Core.git`, wired as `origin` on
  `dev`. Neither the hub nor the working copy at
  `C:\Users\Owner\Documents\Claude\Luna-Core` sits in a folder synced by a
  consumer cloud-sync client, so the corruption risk that a bundle-based hub
  guards against does not apply here — an ordinary `git push` is the publish
  step.

Not yet set up: the repository exists but is empty — nothing has been
committed, tagged, or pushed yet. See README's "Publishing" section.
