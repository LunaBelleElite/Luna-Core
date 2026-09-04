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

## ver-0.1.6.0 - 2026-09-03

Large bug fix: `merge-memory.sh`'s `MEMORY.md` union only ever wrote back in
one direction. Found independently of the two-PC simulation-loop batch
below — during a routine memory-merge step in an earlier pass — so it gets
its own version bump rather than folding into that one.

- **Fixed `merge_index()` silently dropping one side's exclusive entries
  when the other side was a strict superset.** The write-back that copies
  the unioned `MEMORY.md` pointer lines back to both sides was gated on a
  counter that only incremented when the *older* side contributed a new
  entry to the union. If the *newer* side already had everything the older
  side had, plus an entry the older side lacked entirely, the older side
  never received that entry — the gate never opened. The run still exited
  0 with no warning, and in some cases printed `MEMORY.md: differs`
  immediately followed by the contradictory `Both sides already agree.
  Nothing copied.` This ran directly against the function's own documented
  purpose and against `ref/docs/merge-memory.md`'s description of the same
  union behavior. Fixed by adding a second scan over the newer side's own
  entries (a `gap` counter, alongside the existing `added` counter) and
  widening the write-back gate to fire when either counts anything. Does
  not touch the pre-existing conflict path — same-target entries with
  differing wording still correctly refuse to auto-resolve.

## ver-0.1.5.0 - 2026-09-03

Two real defects found by a two-PC blind onboarding/handoff simulation test
(cycle 1) and fixed, landing together as one large-bug-fix bump.

- **Fixed `bootstrap-new-project.sh` mangling the one filename it must never
  rename.** The `awk` rename chain that copies each `agents/luna-core-*.md`
  template into a new project's `.claude/agents/` (renaming `luna-core-` to
  `<projectname>-` throughout) was blindly matching the literal,
  deliberately-never-renamed filename `validate-luna-core-setup.sh`
  wherever it appeared inside agent body text — two places in
  `luna-core-docs-writer.md` — turning it into a broken reference like
  `validate-simtestproject-setup.sh` in every single project ever
  bootstrapped from this repo. Fixed by shielding that literal filename
  behind a placeholder token before the rename substitutions run, then
  restoring it afterward. This is real, shipped corruption of template
  content across every past bootstrap, not just a documentation gap — the
  more serious of the two fixes in this batch.
- **`commands/wake-up.md`'s full sweep now checks for a sibling-clone
  dependency (e.g. Astrid) and confirms it's actually present.** A new step,
  3a-ii, reads this project's own `CLAUDE.md` toolkit section for a
  "Personality & voice" line; if one exists, it clones the sibling fresh at
  the documented path/branch when the directory doesn't exist yet (the
  new-machine case) or runs `git -C <path> pull` when it does, then confirms
  the expected files (e.g. `PERSONALITY.md`/`VOICE.md`) are actually
  present afterward. Before this fix, wake-up.md never mentioned Astrid at
  all, so a blind Wake Up session on a genuinely new machine never checked
  for her — `CLAUDE.md`'s existing `git -C ../Astrid pull` instruction
  silently assumes the clone is already there, which it never is on a
  machine that's never worked on this project before. Caught by an actual
  blind-subagent simulation run that hit exactly this gap.

## ver-0.1.4.0 - 2026-09-03

Large bug fix: the one machine-level path a stranger's AI session is supposed
to trust for bootstrapping a new project could silently land on the wrong
branch.

- **`scripts/install-global-entrypoint.sh`'s two generated clone commands now
  pin `-b main`.** Neither the pointer block it writes into a machine's global
  `CLAUDE.md` nor the generated `/new-project` command specified a branch, so
  a fresh machine-level bootstrap would silently follow whatever GitHub
  reported as the default branch — which was still `dev`, even though the
  README already told humans to clone `-b main` explicitly. Both generated
  paths now agree with the README instead of one being a stale trap for
  anyone who ran the other.
- **Flipped Luna-Core's actual GitHub default branch from `dev` to `main`**
  (`gh repo edit --default-branch main`, confirmed via `gh repo view`), so a
  bare `git clone` with no flags at all — not generated by either path above —
  also now lands on `main`. A repo setting, not a code change, but a real
  behavioral change to this project's own hosting worth recording alongside
  the fix it complements.
- **Trimmed a now-stale line in the same script:** the failure message after a
  failed clone used to blame "no network, or this machine not being
  authenticated to a private repository." Luna-Core is public now, so the
  second cause no longer applies — it now just says "the likeliest cause is
  no network."

## ver-0.1.3.1 - 2026-09-03

Doc-only: `main` is live now, and `README.md`'s "Agents" section still
described docs-writer's job using the framing that `ver-0.1.3.0-dev` had
already superseded — "these paths never reach `main`" — rather than the
resolved policy (the path survives with placeholder content; only this
project's own real working state stays on `dev`). Caught and fixed on
`main` itself before that commit, and now applied here too so `dev`'s copy
doesn't drift back into stating a rule that no longer holds.

## ver-0.1.3.0 - 2026-09-03

Fixed the front door, ahead of this project being public. A stranger arriving
here — a person or an AI session — had nowhere to start, and one of the few
instructions actually aimed at them could not be run as written.

- **`README.md` rebuilt around someone who has never seen this project.** It
  used to open with a "Current state" status report and read as a development
  log, offering no onboarding path at all, and its example bootstrap command
  hardcoded the author's own machine path — so anyone who copied it ran a
  command pointing at a directory that does not exist on their computer. The
  command now uses `<path-to-luna-core-clone>` placeholders, and a numbered
  "Getting started" section leads with clone, bootstrap, validate, open.
  Maintainer-only material (the copy-from-it-never-write-back rule, per-machine
  setup, publishing) moved into a "Maintaining a Luna-Core checkout itself"
  section at the bottom, where it reads as reference rather than as a barrier
  standing between a newcomer and step one. Nothing was dropped, only
  reordered.
- **Added the disclaimers this needed before going public:** that it is a
  vibe-coded personal project rather than a maintained product, that it is
  built specifically around Claude and does not target other AI tools, a dated
  development-status line, and an instruction to clone `main` rather than
  `dev`.
- **Stated the contribution policy plainly** — issues welcome, pull requests
  not reviewed or merged. There is no repository setting that actually
  prevents a pull request from being opened, so this has to be a stated
  policy rather than a switch, and staying silent about it would waste a
  stranger's time on work that was never going to be merged.
- **`CLAUDE.md` now tells a cold session what its first action is.** The file
  loads automatically, so the rules were always in front of a stranger's
  session — but nothing told that session to orient itself first, and the Wake
  Up protocol only triggers on phrases like "wake up" that someone new here
  would never think to say, so nothing would ever prompt it. A new opening
  section has such a session work out whether it is sitting in a Luna-Core
  checkout or in a project bootstrapped from one (using the same tell the
  setup validator already uses, rather than a second test that could drift
  away from it), run the validator instead of assuming the setup is sound, and
  read the README's "Getting started" section when it turns out to be in
  Luna-Core itself.
- **Settled what the `main` branch actually carries, before creating it.** The
  rule had always been that this project's own working files never reach
  `main`. Read as "those paths are absent from `main`," it would have produced
  a branch that fails its own setup validator on a fresh clone — the validator
  requires the handoff files, the memory folder and the agent definitions to
  exist, and every project's `CLAUDE.md` sends sessions to those paths too.
  The rule is now stated the way it was already applied to the reference-docs
  folder: the *path* survives on `main`, carrying generic or template content,
  and only this project's own accumulated and machine-specific content is left
  behind. Recorded in the docs-writer agent, which owns the branch rules, so
  the next merge follows the resolved version rather than rediscovering the
  problem. The memory folder also gained the keeper file it had been missing
  all along — it happened to be safe only because it currently holds real
  files, and would have vanished from the next clone the moment it didn't.

## ver-0.1.2.2 - 2026-09-03

Doc-only: made the Astrid pointer explicit about which branch, since it
previously just said "clone this repo" without naming one.

- **Both the `CLAUDE.md` bullet and `bootstrap-new-project.sh`'s generated
  copy now say `dev` explicitly**, and note that Astrid's `main` has been
  retired — it was a pure mirror of `dev` (verified: zero commits unique to
  `dev`, no content difference beyond version-stamp wording), so maintaining
  a second branch was pure overhead for zero benefit. `dev` is also already
  that repo's default branch, so a plain clone already got it — this just
  makes the intent explicit rather than leaning on a default that could
  change without anyone here noticing.

## ver-0.1.2.1 - 2026-09-03

Doc-only addition: pointed Luna-Core at Astrid, its sibling personality-and-voice
spec, instead of bundling her in.

- Astrid (https://github.com/LunaBelleElite/Astrid) is developed as its own
  repo so she can be adopted, updated, and versioned independently of any
  one project's toolkit, rather than merged into each project that uses
  her. Luna-Core now references her by pointer instead of copy.
- Added a "Personality & voice" bullet to Luna-Core's own `CLAUDE.md`
  toolkit list, describing Astrid as a sibling clone (e.g. `../Astrid` next
  to this project) and pointing to her `PERSONALITY.md` and `VOICE.md`
  rather than duplicating their content here.
- The same bullet was already added to `scripts/bootstrap-new-project.sh`'s
  generated `CLAUDE.md` template, so every project bootstrapped from
  Luna-Core going forward automatically inherits this same pointer to
  Astrid without any manual step.

## ver-0.1.2.0 - 2026-09-03

Two real, previously-undetected defects found by testing and fixed, landing
together as one large-bug-fix bump.

- **Fixed silent exit-0 masking in `check-prerequisites.sh`.** The trailing
  "nothing declared" branch was keyed on `$checked` (only incremented for
  lines that passed the regex-validity guard) instead of on everything
  actually declared. A config whose *only* line had an invalid regex set
  `status=1`, printed the correct `NOTE:` about the bad pattern, then hit
  the "nothing declared" branch anyway — since that one line was never
  counted as checked — printed `OK: no runtime prerequisites declared for
  this project`, and exited 0, silently discarding the failure it had just
  reported one branch earlier. The mask was conditional, not universal: a
  second, valid entry alongside the bad one made the run fail correctly,
  which is exactly the kind of intermittence that hides a bug. Fixed by
  keying that branch on what was declared instead of what was successfully
  checked. This was the first time this code path had ever run against a
  real, non-empty config — see the next item for why.
- **`ref/prerequisites.conf` now declares real prerequisites**: Git, GNU
  sed, and GNU find, replacing the empty stub. Sed and find are declared
  specifically because three of this project's own scripts rely on
  GNU-specific flags (`sed -i` with no backup suffix, `find ... -printf`)
  that a non-GNU sed/find doesn't provide. This is what let the bug above
  actually be exercised for the first time, rather than reasoned through
  from source alone.
- **Rebuilt the template-vs-functional drift check** in
  `validate-luna-core-setup.sh`. The old design diffed the two sides and
  then filtered the diff, dropping any differing line that merely
  *contained* an expected token — measured to be blind to 18.5% of lines
  across the three fill-in agents, and capable of silently waving through
  a semantic inversion of a behavioral constraint. The new design
  normalises both sides onto shared sentinels before comparing, so every
  remaining difference is real drift by construction, with no allowlist
  left to leak through. Landed with it: a fill-in region (`## Stack`,
  `# PART TWO`) must now exist on both sides, or deleting one wholesale no
  longer reports clean; content drift now fails the run instead of only
  ever printing an informational note; and the CLAUDE.md agent-roster
  reverse-check now walks every agent file on disk instead of only
  role-suffixed ones, so an orphan agent filename is no longer invisible
  to the whole validator. The rebuilt check found one real drift on its
  first live run: the research agent's functional copy had lost a
  `(branch `dev`)` parenthetical, previously masked by the old filter.
  Resolves the two open items this had been tracked under
  (`tests/notes/open-items.md` OI-1 and OI-2).
- **Extended `CLAUDE.md`'s interface-verification rule to plan tasks, not
  just tests**, and added a new rule requiring a row-by-row conflict scan
  before dispatching parallel agents rather than a verbal "looks clean."
  Doc-only, no code involved, folded into this batch's bump rather than
  given its own.

## ver-0.1.1.1 - 2026-09-03

Documentation-only batch: `ref/docs/` goes from empty to populated, and a
branch-scoping question about it gets ruled on. No code changed and no
defect was fixed, so this stays a 4th-number bump rather than a core-feature
one — see the reasoning below.

- **Populated `ref/docs/` with one page per script**, plus `ref/docs/README.md`
  as an index: `bootstrap-new-project.md`, `check-prerequisites.md`,
  `check-superpowers.md`, `install-global-entrypoint.md`,
  `lib-claude-home.md`, `merge-memory.md`, and `validate-luna-core-setup.md`,
  covering the seven scripts in `scripts/`. `CLAUDE.md` has always told every
  session to consult `ref/docs/` before reading source, but the folder was
  empty, so that instruction pointed at nothing while 1,847 lines of shell
  sat unexplained. Each page covers what its script does, how it's invoked,
  what it writes inside versus outside the repo, its refusal conditions, and
  the non-obvious traps mined from source comments — several of which record
  real failures. The pages cite `tests/notes/live-checks.md` for measured
  behavior rather than duplicating it.
- **Ruled: `ref/docs/*.md` pages are dev-only, not shared with `main`.**
  `main` is what a fresh consumer clones — someone who has never run this
  project — and these pages document *this* project's own internals, useless
  and confusing to that reader. This reverses the previous assumption (that
  `ref/docs/*.md` shipped on both branches like `CLAUDE.md`/`README.md`/
  `CHANGELOG.md`) and is now encoded in both `luna-core-docs-writer` copies
  (`agents/` and `.claude/agents/`), `CLAUDE.md`, and `README.md`.
  `ref/docs/` itself keeps the partial exception it already had for its
  folder-plus-keeper-file: the pages are stripped at merge time like
  `.claude-memory/`, `handoff/`, and `.claude/agents/*.md`, but the empty
  folder and its `.gitkeep` survive on `main`, since the "check `ref/docs/`
  first" instruction must still point at something real there — the same
  keeper-file reasoning `CLAUDE.md` already applies to every other
  referenced-but-empty path.

## ver-0.1.1.0 - 2026-09-02

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

## ver-0.1.0.0 - 2026-09-02

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
