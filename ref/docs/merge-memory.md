# `scripts/merge-memory.sh`

284 lines. Two-way, no-clobber merge between this project's local Claude
Code auto-memory (machine-specific, outside the repo) and the `.claude-memory/`
folder inside this repo, so memory can roam across machines via git instead
of staying pinned to whichever machine created it. Replaces an older
`sync-memory-to-repo.sh` / `restore-memory-from-repo.sh` pair that did flat
`cp -rf` in each direction and would silently destroy whichever side happened
to be newer — this script is the fix for that, not a new feature.

It's deliberately the **same operation** regardless of which direction memory
needs to flow (Wake Up, on a machine that may not have this project's memory
yet; Debrief, to get a session's memory into the repo before committing) —
two directions implemented separately would eventually disagree about what's
current.

## Invocation

```
bash scripts/merge-memory.sh [--dry-run]
```

No other arguments. `--dry-run` runs every comparison and prints every
decision it would make, but skips all actual file writes (`copy()` and the
write-back half of `merge_index()` both check `$DRY_RUN` before touching
disk). Run from anywhere — it resolves its own location the same way
`validate-luna-core-setup.sh` does, then derives `REPO_ROOT` from that, so
caller cwd doesn't matter.

## What it writes — inside the repo

`.claude-memory/*.md` at the top level only (not recursive — see "Non-flat
layout" below): new files copied in from local memory, existing files
overwritten *only* when local memory's copy is genuinely newer, and
`.claude-memory/MEMORY.md` specifically merged by union rather than
overwritten (see "MEMORY.md is special" below).

## What it writes — outside the repo

The local auto-memory bucket: `$CLAUDE_DIR/projects/$SANITIZED/memory/*.md`,
where `$CLAUDE_DIR` comes from `lib-claude-home.sh`'s `resolve_claude_home()`
and `$SANITIZED` is the repo's own absolute path with `:`, `\`, `/`, and space
each replaced by `-`. Same write rules as above, mirrored: new files copied
in from the repo side, existing files overwritten only when the repo side is
genuinely newer.

**Nothing is ever deleted, by design, on either side.** This is a hard
invariant of the script, not an incidental property — see "What it refuses
to decide for you" below.

## Refusal conditions (what makes it exit non-zero, or write nothing)

- `scripts/lib-claude-home.sh` missing next to it → prints `ERROR:`, exits 1,
  writes nothing. The script won't guess where memory lives if it can't
  source the shared resolver — guessing wrong would silently merge into the
  wrong bucket.
- Neither `$LOCAL_DIR` nor `$REPO_DIR` exists → "Neither side exists yet.
  Nothing to merge." Exits 0 (this is a legitimate empty state, not an
  error).
- No `.md` files on either side (both dirs exist but are empty) → "No memory
  files on either side. Nothing to merge." Exits 0.

Otherwise it always exits 0, even when it declines to resolve something —
see the next section. **This script's exit code tells you almost nothing
about whether it actually finished the merge cleanly; read its printed
`!!` lines.**

## The three cases it refuses to decide for you

These are the actual point of the script — the older flat-copy tools didn't
have a concept of "ambiguous," they just picked a direction and overwrote.
Each of these prints `!!` and increments `needs_attention`, and is otherwise
left completely untouched:

1. **A file on one side only.** Absence carries no timestamp, so "deliberately
   deleted on the other machine" and "never synced here yet" are
   indistinguishable. The script never deletes to resolve this — it copies
   the lone file to the side missing it and says so, specifically so the copy
   can be undone by a human if it was actually a deletion.
2. **Same timestamp, different content.** Printed as `!!  same timestamp
   (...) but different content -- left as-is, reconcile by hand`. Neither
   side is touched.
3. **`MEMORY.md` index entries that conflict for the same link target** — see
   below. Printed as `!!  index entry for (target) differs between sides --
   left as-is, reconcile by hand`.

## Timestamp resolution — frontmatter first, mtime is the fragile fallback

`ts_local()` and `ts_repo()` both try a file's own `modified:` YAML
frontmatter line first (`ts_frontmatter()`), and only fall back to filesystem
mtime if that's absent or unparseable. This is not an equivalent fallback,
it's a known-worse one, and the asymmetry between the two sides matters:

- **Local side** falls back straight to `ts_mtime` (the file's actual mtime
  on this machine).
- **Repo side** falls back to `git log -1 --format=%ct -- <file>` (the file's
  last *commit* date) **before** falling back to mtime. This is the critical
  design point: git records no mtimes at all, so every file in a fresh clone
  carries the moment of checkout as its mtime — which would make the entire
  repo side look uniformly newer than any local file that hadn't just been
  freshly cloned itself, and a naive mtime comparison would silently prefer
  the checkout-noise timestamp over real content. Using commit date instead
  ties the repo side's timestamp to when the content actually changed.

If `modified:` is present but fails to parse as a date, the script does not
silently fall back — it prints a `??` warning to stderr naming the bad value,
specifically so an unreadable frontmatter date doesn't quietly downgrade to
guesswork over what's likely just a typo.

**Trap for anyone testing this script in isolation:** with no `modified:`
frontmatter and no git repository at all (e.g. a bare fixture), both sides
fall through all the way to mtime, so in that specific setup `touch -d` fully
controls which side wins — useful for building deterministic test fixtures,
but not representative of how a real project (which has both frontmatter and
git history) actually resolves timestamps.

## `MEMORY.md` is special — union, not newest-wins

`MEMORY.md` is treated as an *index*, not a document: both machines
independently append pointer lines to it over time (`- [label](target) —
description`), so "pick whichever copy is newer" would silently discard
every entry the other side has that the newer copy doesn't. `merge_index()`
instead unions the two sides' pointer lines, keyed on the **link target**
(the part inside `(...)`), and writes the union back to **both** sides when
anything new was added — not just to whichever side happened to be picked as
the merge destination.

**This was the site of a real, measured bug**, described in detail in
`tests/notes/live-checks.md`'s "The memory index keyed on the wrong thing"
section — summarizing only enough to explain the current code, not
re-deriving the fix:

The original extraction pattern, `s/.*(\([^)]*\)).*/\1/p`, used a greedy
`.*(` that matched the *last* `(` on the line rather than the first — so a
pointer line ending in a parenthetical description like "... (personal)" got
keyed on `personal` instead of on the actual link target. Measured on the
real index at the time: 2 of 6 lines miskeyed. Two compounding failures
followed from that: the same file keyed differently on each side got
appended as a duplicate entry, and two genuinely different files whose
descriptions happened to end in the same parenthetical collapsed into one
entry — silently erasing the loser from whichever side still had it, because
a nonzero `added` count triggers writing the union back to *both* sides. The
current code (`s/^- \[[^]]*\](\([^)]*\)).*/\1/p`) is anchored at line start
and takes the *first* parenthesized group after the bracketed label, closing
that hole. If you ever touch this regex again, read that live-checks section
first — it also documents the exact fixture recipe and mutation-testing
numbers (reverting to the greedy form reds 8 of 13 assertions) needed to
re-prove a fix.

**A second, independent bug sat in the write-back gate itself**, described in
detail in `tests/notes/live-checks.md`'s "`merge_index()`'s write-back only
fires in one direction" section. The paragraph above (and the write-back
gate's own intent) says the union writes back to both sides "when anything
new was added" — but the original gate, `[ "$added" -gt 0 ]`, only counted
entries the *older* side contributed to the union. When *newer* was a strict
superset of *older* (had everything older had, plus an entry older lacked
entirely), older contributed nothing, `added` stayed 0, and the write-back
never fired — older silently never received newer's exclusive entry, with no
`!!` warning and exit 0. In some runs this printed the self-contradictory
`MEMORY.md: differs` immediately followed by `Both sides already agree.
Nothing copied.` The fix adds a second scan over *newer*'s own lines,
checking each target's presence in *older* at all (a `gap` counter,
alongside the existing `added` counter), and widens the gate to `[ "$added"
-gt 0 ] || [ "$gap" -gt 0 ]`. This does not touch the conflict path above —
a same-target entry with differing wording is still correctly excluded from
both counters and left for a human. If you ever touch this gate again, read
that live-checks section first for the fixture recipe and the four
mutation/coverage cases (two-way gap-plus-conflict in one run, pure-conflict
must-not-overwrite, non-pointer-line content, and the pre-fix `added`-only
path standalone) needed to re-prove a fix.

## Non-flat layout is flagged, not merged

After the main file-by-file walk, the script separately checks both
`$LOCAL_DIR` and `$REPO_DIR` for subdirectories (`find ... -maxdepth 1 -type
d`). If either has any, it prints a `NOTE:` listing them and increments
`needs_attention` — **this script only merges `*.md` files at the top level
of each memory folder.** Anything nested inside a subdirectory on either side
is completely invisible to every other part of this script; it neither
copies, compares, nor reports on individual files within a subdirectory,
only on the subdirectory's existence.

## Non-obvious behavior and traps

**`set -uo pipefail`, not `set -e`.** Deliberate: this script is mostly
comparisons, and a non-zero `grep` (no match found) or a file with no
frontmatter are *expected*, routine outcomes here, not failures that should
abort the run. Errors are handled explicitly at the specific points they can
actually occur, rather than by blanket abort-on-any-nonzero.

**The bucket path must use the long-form Windows path, not whatever form the
caller's shell happens to produce.** `cygpath -wl` (note the `-l`) is used
specifically to force the long form. Claude Code's own bucket-naming always
uses the long form; if this script computed the short 8.3 form instead
(`C:\Users\USERNA~1\...` vs `C:\Users\username\...`), it would derive a
*different* sanitized bucket name than Claude Code's own and silently report
"nothing to merge" against a bucket that simply doesn't exist — a silent
no-op is called out in the source comments as the worst possible failure
mode here, since memory just quietly stops roaming with no error at all.

**When the expected local bucket is missing, it actively cross-checks against
other projects' buckets** rather than just proceeding — it lists sibling
directories under `$CLAUDE_DIR/projects/` (up to 8) so a wrong bucket name is
visible for comparison rather than indistinguishable from "this project
genuinely has no memory yet."

**`copy()` always prints before checking `$DRY_RUN`** — the `-> <reason>`
line and the `changed` counter increment happen unconditionally; only the
actual `mkdir -p`/`cp -p` are gated on `$DRY_RUN`. This means dry-run output
and real-run output look identical except for the `(dry run -- nothing will
be written)` banner at the top — don't rely on absence of `->` lines to tell
whether something was a dry run.

**A repo-side change (`.claude-memory/` written) is not committed by this
script.** It only ever writes files to disk; the closing message explicitly
reminds you to commit `.claude-memory/` to `dev` yourself, with the project's
standing explicit-permission git rule still in force — this script has no
git-write behavior of its own beyond reading `git log` for repo-side
timestamps.

## Cross-references

- Sources `scripts/lib-claude-home.sh` for `resolve_claude_home()` /
  `$CLAUDE_DIR` — refuses to run at all if that file is missing (see
  refusal conditions above). Read `ref/docs/` for that file if a page for it
  exists; otherwise its own header comments explain the
  `CLAUDE_CONFIG_DIR` → `$USERPROFILE`/`$HOME`-with-`.claude/projects` →
  bare `$HOME` fallback order and why `$HOME` alone is unsafe on Windows
  (frequently a mapped network drive).
- Copied (not generated) into every bootstrapped project by
  `bootstrap-new-project.sh` — see that page's "What it writes" list.
  `validate-luna-core-setup.sh` checks for its presence via `check
  "scripts/merge-memory.sh"`.
- Invoked by both the Wake Up and Debrief protocols
  (`.claude/commands/wake-up.md` / `.claude/commands/debrief.md`), and by
  the `*-docs-writer` agent, which is told to run it before committing any
  memory changes and to report anything it flags as `needs_attention` rather
  than silently resolving it.
- CLAUDE.md's "Memory roaming across machines" section is the authoritative
  policy statement this script implements — read that section for *why*
  flat-copy is prohibited project-wide, not just in this script.
- Full bug history, fixture recipe, and mutation-testing numbers for the
  `MEMORY.md` keying bug live in `tests/notes/live-checks.md` — referenced
  above, not duplicated.

## What I'm not confident about

- I have not traced exactly how Claude Code itself derives its own bucket
  sanitization (the `$SANITIZED` computation here is this script's
  independent reproduction of that scheme, per its own comments) — I'm
  relying on the source comment's claim that long-form-path-plus-character-
  substitution matches Claude Code's own bucket naming, not on inspecting
  Claude Code's own source.
- I did not re-execute the fixture recipe from `tests/notes/live-checks.md`
  in this pass; the specific measured numbers cited (2 of 6 lines miskeyed,
  8 of 13 assertions red on revert) are carried from that file, not
  independently re-verified here.
