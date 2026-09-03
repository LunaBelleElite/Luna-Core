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

## ver-0.1.1.0-dev - 2026-09-02

Fixes and rulings found by testing after `ver-0.1.0.0-dev` was committed and
pushed (`be3fb7f`) — everything below landed on `dev` afterward, so unlike
earlier passes this genuinely earns its own version rather than folding into
the starting commit.

- **Fixed silent memory loss in `merge-memory.sh`.** The script's whole job
  is reconciling this project's memory index across machines without ever
  losing an entry, but `merge_index()` located each entry's target file by
  matching the *last* parenthesis on its line instead of the one right after
  the link text. An entry whose description happened to end in something
  like "(personal)" got keyed on `personal` instead of its actual filename.
  That produced duplicate entries, and — worse — let two unrelated files
  whose descriptions happened to end in the same parenthetical collapse into
  a single index entry; once collapsed, the file that lost the collision had
  it silently erased from the side that still held it, because a nonzero
  `added` count writes the merged union back to both sides. Exit code 0,
  message "1 file(s) updated" — no error anywhere. This is the most serious
  fix in this batch: the one tool whose entire purpose is not losing memory
  was capable of losing it without a trace. Fixed by anchoring the match at
  the start of the line so it reads the bracketed link's actual target
  rather than whatever parenthetical happens to come last.
- **Fixed a false "Updated" from `install-global-entrypoint.sh` on a CRLF
  entry-point file.** The script decided *whether* to replace its managed
  block using a CR-tolerant substring match, but then performed the
  replacement with an exact line match — the two disagree on a file with
  Windows line endings, so the script reports success while changing
  nothing. The bug was invisible on this machine, where the local awk
  strips carriage returns automatically, which is exactly why it needed
  catching by other means: this installer's whole purpose is running
  correctly on machines that haven't been tested on directly.
- **Fixed a misread version stamp in `validate-luna-core-setup.sh`.** The
  same greedy-match mistake as the memory-index bug above, in a different
  script: reading the entry point's version stamp took whatever followed
  the *last* occurrence of the marker text instead of the real one, which
  could report a stale entry point as current (`OK:`) rather than flagging
  it (`NOTE:`) in a bootstrapped project.
- **Fixed leftover advice in `validate-luna-core-setup.sh` for a removed
  argument.** Every freshly bootstrapped project was being told to pass a
  `<hub-folder>` argument to the entry-point installer that the installer no
  longer accepts — the second instance of this exact "advice that cannot be
  followed" shape found in this file.
- **Ruled: Fable is manual-only.** The assistant routes dispatches across
  Sonnet and Opus only, on any license tier — Fable is never dispatched by
  the assistant; the user invokes it themselves when a project calls for
  it. Recorded directly in `CLAUDE.md` so every project bootstrapped from
  Luna-Core inherits the boundary, not just this machine's local memory.
- **Added `CLAUDE.md` section 5, "Verify Interfaces Before Testing."** A
  test written against an interface nobody confirmed exists is worse than
  no test at all — it creates false confidence and pushes discovery of the
  real interface from planning time into implementation time. The new
  section requires confirming an interface actually exists, by reading
  source or type definitions, before writing a test against it.
- **Corrected the recorded Claude license tier** in `.claude-memory/` from
  Business Standard (teams) to Max 5x (personal) — the wrong tier had been
  silently under-routing dispatches to Sonnet — and added
  `feedback_fable_manual_only.md` to record the Fable boundary above outside
  any one project's `CLAUDE.md`.
- **Extended test coverage** for all three script fixes above, plus a newly
  documented blind spot in the template-vs-functional drift check: its
  filter for lines mentioning `luna-core-` is broad enough to silently wave
  through a semantic edit to any line containing that token, including an
  inversion of a "what you don't do" constraint. Two open questions from
  that work are tracked in `tests/notes/open-items.md` as OI-1 and OI-2.

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
