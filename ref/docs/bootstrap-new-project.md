# `scripts/bootstrap-new-project.sh`

395 lines. Sets up a brand-new project from a Luna-Core checkout: copies and
renames the four agents, copies commands/scripts, places a filled-in
`CLAUDE.md` at the new project's root, and creates fresh (not copied)
`ref/docs/`, `handoff/`, `tests/`, `.claude-memory/`, and `CHANGELOG.md`. This
is Luna-Core's own distribution tool — it is never copied into a project it
bootstraps (see "What it deliberately does not copy" below).

## Invocation

```
bash bootstrap-new-project.sh <luna-core-source-dir> <new-project-dir> <ProjectName>
```

All three positional arguments are required; missing any prints usage and
exits 1. Real example:

```
bash bootstrap-new-project.sh C:/Users/Owner/Documents/Claude/Luna-Core C:/Users/Owner/Documents/Claude/TestProj TestProj
```

`<ProjectName>` must match `^[A-Za-z0-9_-]+$` — no spaces, no other
characters — because it's used verbatim in agent filenames and each agent's
`name:` frontmatter field, which Claude Code requires to be a safe
identifier. It is used in two forms throughout the run: the **prose form**
(exactly as typed, e.g. `TestProj`) in generated documentation text, and a
**lowercased identifier form** (`LC_NAME`, e.g. `testproj`) in agent
filenames and the `name:` field (`luna-core-qa-tester` → `testproj-qa-tester`).

## What it writes — inside `<new-project-dir>`

- `scripts/` — every `scripts/*.sh` from the source **except**
  `bootstrap-new-project.sh` itself and `install-global-entrypoint.sh` (see
  below).
- `.gitattributes` and `.gitignore`, copied if present in the source.
- `.claude/commands/` — all of `commands/*.md` copied in (`/wake-up`,
  `/debrief`).
- `.claude/agents/` — the four `agents/luna-core-*.md` templates, copied and
  renamed (see "The rename" below).
- `CLAUDE.md` at the project root — the source file with its `## This
  project's toolkit` section (bounded by that heading and the next `## 1.
  Think Before Coding` heading) replaced with a freshly generated one naming
  this project's actual agents/commands/version, plus any
  `<projectname>-`/`<ProjectName>` placeholders elsewhere in the file filled
  in via `sed`. If the section markers aren't found, it falls back to copying
  CLAUDE.md as-is and warns that the toolkit section needs filling by hand.
- `ref/docs/.gitkeep` — an empty `ref/docs/` folder, never populated from the
  source (Luna-Core's own `ref/docs/` documents Luna-Core, not the new
  project).
- `ref/prerequisites.conf`, copied verbatim if the source has one — copied
  rather than generated so its format-documentation comments travel with it;
  it declares nothing on its own until the new project edits it.
- `.claude-memory/.gitkeep` — an empty folder, created here rather than left
  to `merge-memory.sh`'s own `mkdir` fallback, so it exists from bootstrap
  day one rather than only after someone happens to run a merge.
- `tests/TESTING_NOTES.md`, `tests/TEST_INDEX.md`, `tests/notes/live-checks.md`,
  `tests/notes/open-items.md` — all freshly generated boilerplate (not
  copied), each stamped with `${LC_NAME}-qa-tester`/`${LC_NAME}-implementer`
  where the text names an agent. Deliberately only these two notes files, not
  a full copy of Luna-Core's own `tests/notes/` — the qa-tester agent's hub
  table is documented as the authority on what notes files exist, so a new
  project is meant to earn additional notes files rather than inherit ones
  that don't apply to it yet.
- `handoff/STATUS.md` and `handoff/HANDOFF.md` — freshly generated, stamped
  with today's date and this machine's hostname, not copied (Luna-Core's own
  handoff notes are about Luna-Core).
- `CHANGELOG.md` — freshly generated: the versioning-scheme boilerplate plus
  one opening entry, `## ver-0.1.0.0-dev - <today>`, "Project bootstrapped
  from Luna-Core." Not Luna-Core's own history.

## What it writes — outside the repo

Nothing. Every write target above is under `<new-project-dir>`. It reads
`hostname` and `date` for stamping text but doesn't touch any machine-level
location (contrast `scripts/install-global-entrypoint.sh`, which does, and is
explicitly excluded from what this script copies — see below).

## What it deliberately does not copy

- **Itself** (`bootstrap-new-project.sh`) — bootstrapping other projects is
  Luna-Core's own role; a child project has no use for the distributor.
- **`install-global-entrypoint.sh`** — machine-level: it writes the entry
  point that points *at* Luna-Core and reads its clone URL from its own
  repo's origin, so a copy sitting inside a child project would simply be
  broken. This is why `validate-luna-core-setup.sh`'s entry-point section, on
  a non-Luna-Core project, tells you to run that script from the *Luna-Core*
  checkout, not from the local one.
- **`ref/docs/*.md` content** — fresh empty folder only.
- **`handoff/*.md` content** — fresh generated stubs only, not Luna-Core's
  own notes.
- **Luna-Core's own git history** — the destination must already be its own
  initialized git repo (see refusal conditions); this script copies specific
  files *into* an existing checkout, it does not clone or fork Luna-Core's
  repository.

## Refusal conditions (exit non-zero, write nothing)

Checked in order, each printing `ERROR:` and exiting 1 before any write
happens:

1. Any of the three arguments empty.
2. `<ProjectName>` fails the `^[A-Za-z0-9_-]+$` pattern.
3. `$SOURCE` doesn't look like a Luna-Core checkout — missing `agents/` or
   `CLAUDE.md`.
4. `$DEST` is not an initialized git repo (`$DEST/.git` missing). The script
   never runs `git init` itself — that's left to the caller.
5. `$DEST/handoff/HANDOFF.md` already exists — read as "this project was
   already bootstrapped once." Re-running would silently overwrite real
   handoff notes, a real CHANGELOG, and a customized CLAUDE.md back to
   fresh-bootstrap boilerplate. If you need one updated file from a newer
   Luna-Core (an agent, a script), the script tells you to copy that single
   file by hand instead of re-running it.
6. The source's `agents/` folder is missing any of the four required
   role templates (`docs-writer`, `research`, `qa-tester`, `implementer`,
   matched as `agents/luna-core-<role>.md`). This is checked as a complete
   set up front and refuses on any gap, rather than silently producing a
   project that's short one whole agent — later-generated text (the toolkit
   list, HANDOFF.md's next steps) references all four by name, so continuing
   with a partial set would leave the new project's own docs pointing at
   files that don't exist.

**Not a refusal, only a warning that lets the run continue:** if `$DEST` is
on a branch other than `dev` (or in a detached/no-branch state), it prints a
`WARNING:` explaining that everything this script installs is dev-only
content and that it will not create or switch branches for you — then
proceeds anyway. You're expected to create `dev` yourself, before or after.

## Non-obvious behavior and traps

**The rename is line-scoped by blockquote, not whole-file.** The `awk`
program that renames each agent file skips (`/^>/ { print; next }`) any line
starting with `>` — every agent keeps a permanent "Template note" blockquote
documenting the Luna-Core-to-this-project rename convention itself, for the
*next* clone downstream. Those lines correctly say `Luna-Core` /
`<ProjectName>` forever and must never be rewritten. Everywhere else, the
substitution is:

```
luna-core-        -> <lowercase-name>-
<projectname>-    -> <lowercase-name>-
Luna-Core         -> <ProjectName>  (prose form)
<ProjectName>     -> <ProjectName>
<projectname>     -> <ProjectName>
```

Order matters here: `luna-core-` and `<projectname>-` (with trailing hyphen)
are substituted before the bare `Luna-Core` / `<ProjectName>` / `<projectname>`
forms, so an identifier fragment like `luna-core-docs-writer` becomes
`testproj-docs-writer` rather than partially colliding with the prose
substitution.

**Only the identifier half of the placeholder is auto-filled.** The lowercase
`<projectname>` token is filled in everywhere it appears in operative body
text (descriptions, cross-references between agents), because the answer is
simply this project's name. `<directory>` is deliberately **never** filled —
only a human knows where the project will actually live — which is why the
script's own closing output explicitly tells you to re-read each agent file
afterward; the research agent in particular still needs its repo path filled
in by hand before it's usable (`validate-luna-core-setup.sh` treats this one
as a required, not draft, gap).

**CLAUDE.md's toolkit-section replacement is heading-anchored, not
line-count-based**, using `grep -n` for `^## This project's toolkit$` and
`^## 1\. Think Before Coding$`. If either heading has been renamed or
reordered upstream in Luna-Core's own CLAUDE.md, the script falls back to a
raw copy with a `WARNING:` rather than mangling the file — this is a
correctness safeguard, not a silent failure.

**Bare `Luna-Core` outside the toolkit section is intentionally left
alone** in the copied CLAUDE.md — elsewhere in the file it's a legitimate
lineage reference (e.g. "cloned in from Luna-Core"), and blanket-renaming it
would corrupt that meaning. Only the bounded toolkit section and the explicit
`<projectname>`/`<ProjectName>` placeholder tokens are substituted.

**`git -C "$DEST" branch --show-current` failing is treated as "no branch,"
not as an error** — the `|| echo ""` fallback means a detached-HEAD or
otherwise unusual git state prints the same dev-branch warning rather than
crashing the script.

**`set -e` is active**, unlike `merge-memory.sh` (see that page) — a failed
`cp`, a failed `mkdir`, or any other unexpected non-zero command aborts the
whole run immediately, potentially leaving `$DEST` partially written. There
is no rollback; a failed mid-run bootstrap needs manual cleanup or a fresh
`$DEST` before retrying (the "already bootstrapped" refusal above will only
catch this if `handoff/HANDOFF.md` happened to get written before the
failure).

**The dev-branch warning is advisory only** — the script proceeds and writes
files regardless of what branch `$DEST` is on. Nothing later re-checks this;
it's on the operator to have actually created and switched to `dev` at some
point, since everything this script installs is documented project-wide as
dev-only content (see the branch-discipline table in
`.claude/agents/*-docs-writer.md`).

## Cross-references

- Reads `agents/luna-core-*.md`, `CLAUDE.md`, `commands/*.md`,
  `scripts/*.sh`, `.gitattributes`, `.gitignore`, and
  `ref/prerequisites.conf` from `$SOURCE` (the Luna-Core checkout).
- The generated `CLAUDE.md`'s toolkit section names
  `scripts/validate-luna-core-setup.sh` as the next step to run — see that
  page for what it then checks.
- The generated `handoff/HANDOFF.md`'s "Next steps" explicitly tells the new
  project to write its own README (with a "Dependency: superpowers plugins"
  section) and to run `scripts/check-superpowers.sh`.
- Its output is exactly what `validate-luna-core-setup.sh`'s "File layout,"
  "Agents," "CHANGELOG," and "This machine's Luna-Core entry point" sections
  verify afterward — the two scripts are a matched producer/checker pair.
- Does not source or invoke `merge-memory.sh` or `lib-claude-home.sh` itself;
  it only creates the empty `.claude-memory/` folder that `merge-memory.sh`
  later operates on.

## What I'm not confident about

- I did not execute this script in this pass (no network/execution was in
  scope for this task) — the behavior above is read from source, not
  re-measured. `tests/notes/live-checks.md` records that other checks were
  built and verified against bootstrap-produced fixtures, but I did not find
  a live-checks entry specifically probing `bootstrap-new-project.sh`'s own
  refusal paths or partial-failure behavior under `set -e`; treat the
  "no rollback" claim above as read from the `set -e` mechanism, not as a
  measured trace of an actual mid-run failure.
