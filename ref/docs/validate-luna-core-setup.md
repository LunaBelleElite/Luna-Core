# `scripts/validate-luna-core-setup.sh`

471 lines. Confirms a project bootstrapped from Luna-Core (by
`bootstrap-new-project.sh` or by hand) actually landed correctly, and prints
an explicit summary of what's installed and recognized. It is also Luna-Core's
own environment gate: the Wake Up protocol runs it to decide whether a
session's toolkit is intact before doing anything else.

## Invocation

```
bash scripts/validate-luna-core-setup.sh
```

No arguments. It resolves its own location (`SCRIPT_DIR`) from
`BASH_SOURCE[0]` and `cd`s to `SCRIPT_DIR/..`, so it can be run from anywhere
as long as the file itself stays at `<project-root>/scripts/`. It does not
depend on the caller's cwd.

**Writes nothing** — this script only reads and prints. It has no repo-side
or outside-the-repo output of its own. (It does shell out to
`scripts/check-prerequisites.sh` and `scripts/check-superpowers.sh`, which are
themselves read-only checks, not writers.)

## The one rule that matters most: exit code is not trustworthy alone

The script has three severities, and only two of them affect `overall_status`
(the exit code):

- **`MISSING:`** — a required path or condition absent. Sets `overall_status=1`.
- **`EMPTY:`** — a folder exists but holds no files (see `check_keeper()`
  below). Sets `overall_status=1`.
- **`NOTE:`** — informational. **Never touches `overall_status`.** A run can
  print several `NOTE:` lines describing real problems and still exit 0.

This is deliberate in some places (see `deps_status` below) and a measured gap
in others. Concretely, three separate checks in this script can only ever
print `NOTE:`/print nothing useful and can never fail the run on their own:

- The entry-point section (all four of its states — current, missing, stale
  stamp, no block — are `NOTE:` lines).
- The template-vs-functional drift check's *content*-drift branches (only its
  *structural* branch — a template with no functional copy at all — sets
  `overall_status`).
- (By the same logic, anything that degrades to a `NOTE:` anywhere else in the
  file.)

**Consequence: never assert on this script's exit code alone.** A machine
with an absent or years-stale entry point passes green. A functional agent
copy with an inverted constraint, a deleted section, or ten drifted lines
passes green. Assert on the specific `MISSING:`/`EMPTY:`/`NOTE:` line you
care about. This is documented and measured three times over in
`tests/notes/live-checks.md` (the `EMPTY:` case, the entry-point case, and the
drift-check case) — see that file for the exact fixture recipes and measured
outputs, not reproduced here.

There is also a **separate, deliberately-excluded status track**:
`deps_status`, covering `scripts/check-prerequisites.sh` and
`scripts/check-superpowers.sh`. Those are machine-level dependency checks, not
this project's *files*, so a missing dependency prints under "informational"
headers and never flips `overall_status` — but if `deps_status` is nonzero
while `overall_status` is 0, the final banner still says "File setup
verified" and then appends a "NOT READY TO WORK ON YET" paragraph explaining
the dependency gap. Read the whole tail of the output, not just the top-line
banner.

## Refusal conditions (what makes it exit non-zero)

Everything under `check()` and `check_keeper()` below, plus:

- **`MISSING:`** on any of: `CLAUDE.md`, `CHANGELOG.md`, `ref/docs/`,
  `handoff/STATUS.md`, `handoff/HANDOFF.md`, `.claude-memory/`,
  `tests/TESTING_NOTES.md`, `tests/TEST_INDEX.md`, `tests/notes/live-checks.md`,
  `tests/notes/open-items.md`, `.claude/commands/wake-up.md`,
  `.claude/commands/debrief.md`, `scripts/check-superpowers.sh`,
  `scripts/lib-claude-home.sh`, `scripts/merge-memory.sh`,
  `scripts/check-prerequisites.sh`.
- **`EMPTY:`** on `ref/docs/` or `.claude-memory/` (see below).
- No agent files at all matching `*-docs-writer.md` / `*-research.md` /
  `*-qa-tester.md` / `*-implementer.md` in `.claude/agents/`.
- An agent's `name:` frontmatter still reads `luna-core-*` on a project that
  is **not** Luna-Core itself (i.e. rename didn't complete) — `NOT RENAMED:`.
- `CLAUDE.md` declares an agent in its `**Agents:**` line that has no
  corresponding file in `.claude/agents/`.
- No `## ver-...` header anywhere in `CHANGELOG.md`.
- (Luna-Core-only) a template agent in `agents/` with no functional copy at
  all in `.claude/agents/` — the structural branch of the drift check.
- (Any project) an agent file records an absolute repo path that resolves to
  a real directory on this machine but is **not** this checkout — a stale
  path left over from a machine switch.

A project failing any of these gets the final banner `=== Setup INCOMPLETE
-- see MISSING/INCOMPLETE/NOT RENAMED items above ===` and a non-zero exit.

## `check()` vs `check_keeper()` — existence vs survival

`check()` is `[ -e "$2" ]` — true for a directory *whatever is inside it*.
It proves a path exists, nothing more.

`check_keeper()` is the second, stricter check for the two folders that are
held up by **nothing but a `.gitkeep`**: `ref/docs/` and `.claude-memory/`.
Git tracks files, not directories, so a referenced folder whose keeper file
has been deleted is simply *absent* after the next clone — the failure shows
up on a different machine, not this one. `check_keeper()` runs `find "$2"
-type f` recursively (deliberately recursive: a folder holding only an empty
subdirectory still vanishes wholesale on clone, so "has a subfolder" is not
"has content") and reports `EMPTY:` plus a restore hint if nothing turns up.

Every other referenced folder already has at least one mandatory file that
`check()` verifies by name, so it can't go silently empty the same way:
`tests/` via `TESTING_NOTES.md`, `handoff/` via `STATUS.md`,
`.claude/commands/` via `wake-up.md`, `scripts/` via `merge-memory.sh`,
`.claude/agents/` via the CLAUDE.md roster cross-check below. That's why only
two folders get `check_keeper()` calls — this is a settled design decision,
not an oversight; see `tests/notes/live-checks.md`'s "Which folders need a
keeper check" section if you need to re-derive it.

**Trap:** `.claude-memory/`'s keeper-check gap (before `check_keeper` was
extended to it) mattered *only* on a freshly bootstrapped project, where that
folder holds nothing but its `.gitkeep`. On Luna-Core's own checkout the
folder holds real memory files, so the same bug is invisible there. Any
future check on this folder needs a bootstrapped fixture, not a Luna-Core
self-test, to actually exercise the empty case.

## `IS_LUNA_CORE` — the fork in the road

```sh
if [ -d "agents" ] && [ -f "scripts/bootstrap-new-project.sh" ]; then
  IS_LUNA_CORE=1
fi
```

Bootstrap copies neither the `agents/` template-source folder nor its own
distribution script into a child project, so their joint presence reliably
identifies "this checkout is Luna-Core itself" rather than "a project
bootstrapped from it." This matters because Luna-Core's own agents are
legitimately named `luna-core-*` — without this fork, the validator would
permanently and correctly-yet-uselessly flag its own agents as "not renamed,"
which would make Luna-Core unable to ever pass its own validator (and the
Wake Up protocol depends on this script passing).

`IS_LUNA_CORE` changes three sections:
1. The `NOT RENAMED:` check on each agent's `name:` field (skipped/inverted
   when `IS_LUNA_CORE=1`).
2. The template-vs-functional drift section — only runs at all when
   `IS_LUNA_CORE=1` and `agents/` exists; every other project reports "not
   applicable" instead.
3. The entry-point how-to text and version comparison (a bootstrapped
   project's own `CURRENT_VERSION` is a separate numbering track from
   Luna-Core's installer-stamp version, so they're never compared against
   each other — only Luna-Core itself can judge whether its stamp is
   current).

## Agent placeholder / rename checks

For each matched agent file, the script strips blockquote (`^>`) lines before
testing for unfilled placeholders — every agent keeps a permanent `>
Template note` documenting the rename convention for the *next* clone, and
that note legitimately contains `<ProjectName>`/`<projectname>` forever. Not
stripping it would report a correctly-filled agent as still templated.

Two placeholder patterns are treated differently:

- The research agent's `<absolute path...>` placeholder is flagged as a
  **required** fix (bootstrap can never know a project's eventual home
  directory, so this one never auto-fills).
- Any other `<projectname>`/`<directory>`/`<absolute path` token, or a
  non-heading line containing "fill in," is flagged as an **informational**
  draft-state note — qa-tester's `## Stack` and implementer's Part Two are
  meant to stay unfilled until first real use. Markdown headings are
  excluded from the "fill in" text search specifically because implementer's
  permanent section heading contains the phrase "(fill in when first used on
  real code)" forever; without the exclusion that heading alone would fire
  the note regardless of how complete the section actually was.

## The CLAUDE.md agent-roster cross-check

Beyond "at least one agent file exists," the script parses CLAUDE.md's own
`- **Agents:**` line (the backtick-quoted names on it) and diffs that roster
against what's actually in `.claude/agents/`. This catches two independent
failure shapes the simple existence checks miss entirely: a project missing
one role out of four (the "any agent present" guard only fires when *every*
agent is absent), and an agent present on disk that CLAUDE.md's toolkit list
never mentions. A missing declared agent is `MISSING:` (fails the run); an
undeclared-but-present agent is `NOTE:` only.

**Known gap, not yet fixed** (found while probing the drift check, recorded
in `tests/notes/live-checks.md`): this cross-check only catches an
undeclared agent whose filename matches one of the four role suffixes
(`*-docs-writer.md` etc., via `FOUND_AGENTS`, populated by the earlier loop).
An agent file with no recognized role suffix at all — e.g.
`.claude/agents/luna-core-orphan.md` — appears in **no** validator output
whatsoever, not here and not in the drift check (whose loop is template-side,
`agents/*.md`). The comment in the script claims this check "also catches the
reverse," which is only true for role-suffixed files.

## Template-vs-functional drift check (Luna-Core only)

Compares `agents/*.md` (template source) against `.claude/agents/*.md`
(functional copies), which can silently disagree when one is edited and the
other isn't — nothing else catches that. Runs only when `IS_LUNA_CORE=1`.

Three agents legitimately carry project-specific content in their functional
copy where the template stays blank: research's repo path, qa-tester's `##
Stack` block, implementer's Part Two. `strip_fillins()` cuts those regions
out of **both** sides before diffing (qa-tester: skip from `^## Stack$` to the
next `^## ` heading; implementer: everything from `^# PART TWO` to EOF, via
`exit`). `docs-writer` takes a plain `cmp -s` byte-exact comparison instead —
no exempt regions, no filters.

For the three fill-in agents, what survives `strip_fillins()` is then further
filtered (`grep -v` chain) to drop expected fill-in tokens: the placeholder
text itself, the project name/path substituted into it, and a few known
opening-sentence patterns. **This filter chain is measured to be leaky — read
`tests/notes/live-checks.md`'s "template-vs-functional drift check" section
before trusting an `OK:` from this check on any of the three fill-in agents.**
Highlights (all measured, not inferred):

- **~18.5% of lines across the three fill-in agents are structurally blind**
  (114 of 617 lines) — `docs-writer` is 0% blind since it takes no
  exemptions.
- The exempt regions have **no opinion about their contents at all** once cut
  — replacing qa-tester's entire `## Stack` body, or deleting it heading and
  all, both report `OK:` and exit 0.
- The `grep -Fv "${LC_PROJ}-"` filter (dropping any differing line containing
  `luna-core-`) silently swallows **semantic inversions**, not just
  boilerplate — a "what you don't do" constraint rewritten into its opposite
  on a line containing that token reports clean.
- Content drift, when it *is* caught, only ever prints `NOTE:` — it can never
  fail the run (see "exit code is not trustworthy alone" above).
- `head -6` on the diff output silently truncates; ten drifted lines produce
  twenty diff lines and only six print, with no "…more" indicator.

If you're extending this check, read the fixture recipe in
`tests/notes/live-checks.md` first — it requires a `cp -r` fixture named
exactly `Luna-Core` (not a bootstrapped one; bootstrap doesn't create
`agents/` at all) with agent-recorded repo paths rewritten to the fixture's
own location, or the baseline itself reports false drift.

## Agent repo paths (machine-switch staleness)

Independent of the drift check: for every `.claude/agents/*.md` file, the
script extracts every backticked absolute-looking path (drive letter or
leading slash — `awk -F'`' ... $i ~ /^[A-Za-z]:/ || $i ~ /^\//`) and compares
it against where this checkout actually lives right now. Deliberately scans
*every* such path in the file rather than trusting one known sentence — a
prior version only grepped for `"The repo lives at"` and silently missed the
implementer agent's `"- Repo: ..."` phrasing, reporting a stale checkout as
clean.

Comparison is by canonicalized directory (`cd "$path" && pwd -P`), not string
match — Windows has multiple correct spellings of one directory (8.3 short
form from `cygpath -w`, long form from `pwd -W`, forward vs. back slashes),
and string-comparing those produces exactly the wrong-reason failure this
check exists to prevent. A path containing `<` (an unfilled placeholder) is
skipped — that's the placeholder check's job, not this one's.

## The entry-point section (machine-level, outside the repo)

Reads (never writes) `$CLAUDE_DIR/CLAUDE.md`, resolved via
`scripts/lib-claude-home.sh`'s `resolve_claude_home()` (see that file for how
`CLAUDE_CONFIG_DIR` / `$USERPROFILE` / `$HOME` are prioritized). This file is
written by `scripts/install-global-entrypoint.sh`, lives outside any repo, and
so nothing in git tells you it's stale — this section exists specifically to
surface that. It reports one of four states (current / missing / no
Luna-Core block / stale version stamp), **all four as `NOTE:` lines, all
exiting 0** — see "exit code is not trustworthy alone" above.

The version-stamp comparison only happens meaningfully when `IS_LUNA_CORE=1`
— a bootstrapped project's own version number is on an unrelated track from
the installer's stamp, so on such a project the script just reports the
stamp's value without judging currency.

`ENTRYPOINT_HOWTO` (the suggested fix command) also branches on
`IS_LUNA_CORE`: Luna-Core itself gets `bash scripts/install-global-entrypoint.sh`;
everywhere else gets a pointer to run it *from the Luna-Core checkout*, since
that script is deliberately not copied into bootstrapped projects (see
`ref/docs/bootstrap-new-project.md`).

## Declared-prerequisites and superpowers sections

Both are pure passthroughs — `bash scripts/check-prerequisites.sh` and `bash
scripts/check-superpowers.sh`, run only if the file exists (`SKIPPED:`
otherwise), with their own exit codes rolled into `deps_status`, never into
`overall_status`. This script does not itself know what a "prerequisite" or
a "superpowers plugin" is; it only reports whether those two scripts, if
present, were satisfied. See those scripts' own headers / `ref/docs/`
entries (if any) for what they individually check.

## Cross-references

- Sources `scripts/lib-claude-home.sh` for the entry-point section only.
- Shells out to `scripts/check-prerequisites.sh` and
  `scripts/check-superpowers.sh` (both optional, `SKIPPED:` if absent).
- Copied verbatim into every bootstrapped project by
  `bootstrap-new-project.sh` (see `ref/docs/bootstrap-new-project.md`) — it
  is one of the few scripts that *does* travel outward.
- Depended on by the Wake Up protocol (`.claude/commands/wake-up.md`) as its
  environment gate — per this page's central warning, Wake Up (and anyone
  else) must read specific lines out of this script's output, not trust its
  exit code alone.
- Its own template-vs-functional check, the keeper-file check, and the
  entry-point CRLF/exit-code behavior are all covered with fixture recipes
  and measured numbers in `tests/notes/live-checks.md` — read that file
  before re-deriving any of this by hand.

## What I'm not confident about

- I have not traced `scripts/check-prerequisites.sh` or
  `scripts/check-superpowers.sh` themselves — this page describes only how
  `validate-luna-core-setup.sh` invokes and reports on them, not their
  internal logic or their own failure modes.
- I have not independently re-run the fixture recipes from
  `tests/notes/live-checks.md` in this pass; the measured numbers above
  (18.5% blind-line figure, specific line numbers, etc.) are carried from
  that file's own recorded measurements, not re-verified by me here.
