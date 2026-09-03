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

## The memory index keyed on the wrong thing (2026-09-02)

`merge_index()` in `merge-memory.sh` extracted the link target with
`s/.*(\([^)]*\)).*/\1/p`. `.*(` is greedy, so it matched the **last** `(` on the
line: a pointer line ending "… (personal)" keyed on `personal`, not on
`user_license_tier.md`. Measured on the real index at the time: **2 of 6 lines
miskeyed**. Fixed by anchoring — `s/^- \[[^]]*\](\([^)]*\)).*/\1/p`.

**Both consequences were driven, not reasoned.** The same file keyed differently
on each side is appended as a duplicate. Worse, two different files whose
descriptions end with the same parenthetical collapse into one entry — and the
loser is then **erased from the side that still had it**, because a nonzero
`added` writes the union back to both sides. In the fixture, `beta_rule.md`
existed on the repo side before the run and on neither side after. Exit code 0,
message "1 file(s) updated". Silent data loss on the script whose only job is
not losing memory across machines.

**Fixture recipe.** Copy `merge-memory.sh` + `lib-claude-home.sh` into a
throwaway repo root under the system temp dir; point `CLAUDE_CONFIG_DIR` at a
throwaway config dir; run `--dry-run` first so the script *prints* the bucket
path it derives — do not compute that path by hand, it is the sanitized
long-form Windows path. With no `modified:` frontmatter and no git repo, both
sides fall through to mtime, so `touch -d` fully controls which side is "newer".

The fixture needs three ingredients to show both modes at once: one entry keyed
differently on each side with a trailing parenthetical on the older side; two
different files whose descriptions end with the same parenthetical, one per
side; and **at least one genuinely new entry** — without it `added` stays 0, no
write-back happens, and the erasure never surfaces.

**Mutation numbers.** Reverting to the greedy form reds 8 of 13 assertions.
Keying on the bracketed label instead reds 4. Forcing `if true` in place of the
`grep -qF -- "($target)"` test reds 3. Both arms move, so neither the `->
added` nor the `!!` message is a free pass.

**Trap that cost a round:** do not build the reverting mutation with `awk` — it
eats the `\(` `\)` escapes and applies an always-empty target instead, a
different failure (4 reds, total no-op) that reads like an undershooting pin.
Revert by copying the pre-fix file.

## The entry-point installer, and why CRLF hid a silent no-op (2026-09-02)

First execution ever of `install-global-entrypoint.sh` after its rewrite.
Sandbox it by exporting `CLAUDE_CONFIG_DIR` to a throwaway — `lib-claude-home.sh`
honours that first, so the real `C:\Claude` is never touched. Post-run
invariants worth asserting: `C:\Claude\CLAUDE.md` absent, `commands/` unchanged.

Measured clean: writes exactly two files; substitutes `origin` with no `@@`
left; stamps the CHANGELOG version; idempotent from the first install onward;
preserves unrelated text on both sides of the marker block; keeps one `.bak`;
and **writes literally nothing** when refusing (no repo, no origin, no config
dir) — verified by `find`, not by the error text.

**The block is selected by `grep -qF` (CR-tolerant substring) but replaced by
`awk '$0 == b'` (exact).** On a CRLF file those disagree: grep takes the replace
branch, awk never matches, and the run prints "Updated the Luna-Core block"
while changing nothing. Fixed with `{ sub(/\r$/, "") }` before the comparisons.

**This machine cannot see that bug by default.** Git Bash gawk 5.3.2 strips CR
in text mode: `printf 'X\r\n' | awk '{print length($0)}'` → **1**. `awk -b` does
**not** change it. `awk -v BINMODE=3` → **2**. To test CR-sensitivity here, put a
PATH-shadowing wrapper named `awk` containing `exec /usr/bin/gawk -v BINMODE=3
"$@"`, and add the PATH entry in **POSIX form via `cygpath -u`** — a `C:/...`
entry silently resolves to the real awk and the test passes for the wrong reason.

**Two hazards in that file, both of which produced false confidence:**

- The awk program is single-quoted, so **an apostrophe anywhere inside it —
  including in a comment — breaks the script.** Only `bash -n` catches it.
- **`grep` BRE treats `\r` as a literal `r`.** Verifying a mutation with
  `grep -c 'sub(/\r\$/'` returns 0 whether or not the line was removed — a
  vacuous check that reads as proof. Two separate readers hit this within ten
  minutes. Use `grep -F`, and confirm by line-count delta plus a diff.

**The validator's entry-point check cannot fail a run.** All four reader states —
current, missing, stale stamp, no block — are `NOTE:` lines and all exit 0. So a
machine with an absent or years-stale entry point passes green. Assert on the
specific line, never the exit code. This is the second confirmed instance of that
rule, after the `EMPTY:` case above.

Latent, not live: `install-global-entrypoint.sh:83` uses `awk '{print $2}'` on
the CHANGELOG version line. If that file were ever CRLF, a trailing CR would ride
into the stamp and the validator would mismatch for an invisible reason.

## The template-vs-functional drift check, rebuilt (2026-09-03)

The original compared `agents/` to `.claude/agents/` by diffing and then
**filtering the diff** — dropping any differing line that merely *contained* an
expected token. Measured then: blind to 18.5% of lines across the three fill-in
agents (research 10%, qa-tester 16%, implementer 23%), and it could not fail a
run. A semantic inversion was driven through it: rewriting qa-tester's
"you don't update `CLAUDE.md` … that's `luna-core-docs-writer`'s job" into
"… freely, overriding `luna-core-docs-writer`'s" reported `OK:`, exit 0.

**Now it normalises instead of filtering.** Both copies get the same
substitutions — `<projectname>`, `<directory>`, `<absolute path…>`, the project
name and the repo path all collapse to `@@PROJ@@` / `@@REPO@@` — and then the
normalised texts are compared. Every remaining difference is real drift by
construction; there is no allowlist left to leak through. Block-shaped fill-ins
(`## Stack`, `# PART TWO`) are still cut by `strip_fillins()`, because a blank
block and a filled block are genuinely different prose, not one substitution
apart.

Three further changes landed with it: a fill-in **region must exist on both
sides** (cutting it from both meant deleting a whole `## Stack` section,
heading included, left the stripped sides identical and reported `OK:`);
**content drift now fails the run** rather than printing an unfailing `NOTE:`;
and the adjacent roster reverse-check now iterates every `.claude/agents/*.md`
rather than only role-suffixed names.

**Measured after the rebuild**, on a clean fixture, one variable at a time:
clean baseline exit 0 / 0 drift; semantic inversion exit 1 / 1 drift; whole
`## Stack` section deleted exit 1 with the region message; orphan agent file
reported by name. Mutation: filtering the sentinel (`grep -Fv "@@PROJ@@-"`) —
the post-normalisation equivalent of the old filter — puts it straight back to
exit 0 / 0 drift. Restoring returns exit 1. So the detection rests on the
normalisation, not on luck.

**It found a real divergence on its first run against the real repo**: the
research agent's functional copy had lost its `(branch `dev`)` parenthetical,
dropped by hand earlier that day and masked by the old filter ever since.

**Fixture recipe — the opposite of the keeper-file one; read this before
copying that.** This check needs `agents/` AND `scripts/bootstrap-new-project.sh`
to set `IS_LUNA_CORE=1`, and bootstrap copies neither — so a bootstrapped
fixture cannot exercise it at all. `cp -r` the repo, then two corrections or the
baseline lies:

1. Name the throwaway **exactly `Luna-Core`** — `LC_PROJ` is `basename $(pwd)`
   lowercased and drives the normalisation.
2. Rebase the recorded repo path inside the fixture's `.claude/agents/*.md` to
   the fixture's own path, in **both** spellings.

**And rebuild the fixture between experiments.** Copying a file back from the
real repo mid-run without re-applying correction 2 leaves the fixture holding
the *real* repo path — two differences instead of one, so the "baseline" is
contaminated and every mutation result after it is unreadable. That cost two
wrong conclusions before it was spotted.

**Traps that produced false confidence while doing this work:**

- An escaper built as `sed -e 's/[][\/.*^$|]/\&/g'` turned every backslash
  into `&`, so the interpolated path pattern matched nothing and a weaker rule
  fired instead — plausible output, silent no-match. Avoid interpolating Windows
  paths into `sed` patterns at all: convert separators to `/` first, then
  substitute.
- Generated escaping collapsed `\` to `\`, leaving `sed -e 's|\|/|g'`, which
  is an unterminated `s` command. The function errored on every call while the
  check appeared to run and reported OK.
- A `replace(old, new, 1)` hit the **first** of two identical conditions in
  `check-prerequisites.sh` — the orphan-hint guard, not the trailing branch — so
  a mutation "failed to move the needle" for a reason that had nothing to do
  with the pin. Anchor on surrounding unique context and assert the occurrence
  count before replacing.

## `check-prerequisites.sh`, run for the first time against real declarations (2026-09-03)

First execution ever of `scripts/check-prerequisites.sh`'s pass-2 check-and-report
path against a non-empty `ref/prerequisites.conf`. Previously the conf declared
nothing, so `OK`, `MISMATCH`, `NOT FOUND`, the regex-validity guard, and both
malformed-input `NOTE:` branches were reasoned-through from source only (per
`ref/docs/check-prerequisites.md`'s own honest caveat), never observed. Invoked
the script **directly**, not through `validate-luna-core-setup.sh`, which was
mid-edit during this pass and would have made any result un-attributable.

**Real declarations now in `ref/prerequisites.conf`: Git, GNU sed, GNU find.**
Checked the source first, not just guessed: `git`, `sed`, `awk`, `grep`, `find`,
`mktemp`, `diff`, `cmp` are all invoked somewhere in `scripts/*.sh`, unguarded
(no `command -v` gate) — only `cygpath` is gated (`merge-memory.sh:52`,
`lib-claude-home.sh:45`), so it is correctly *not* declared as a hard
requirement. Of the unguarded set, only `sed` and `find` are used with
implementation-specific syntax that would actually break on a non-GNU
sed/find: `sed -i` with no backup-suffix argument
(`bootstrap-new-project.sh:213-214`, `install-global-entrypoint.sh:130,272` —
BSD sed requires a suffix arg there) and `find ... -printf`
(`merge-memory.sh:203-204` — a GNU findutils extension, no BSD equivalent).
`awk`, `grep`, `mktemp`, `diff`, `cmp` are all used in portable, POSIX-safe
ways elsewhere in the same files, so declaring them would have been a false
prerequisite (worse than a missing one, since it would fail on a machine that
was actually fine) — left undeclared on purpose, not by oversight.

**Sandbox recipe.** The script resolves `CONF` relative to its own location
(`cd "$SCRIPT_DIR/.."`), so the minimum fixture is just two files:
`<tmp>/scripts/check-prerequisites.sh` (copied) and `<tmp>/ref/prerequisites.conf`
(the case under test). No other repo scaffolding is needed — this script does
not source `lib-claude-home.sh` and does not check `IS_LUNA_CORE`.

**All six predictions matched exactly, one revealed a real defect:**

1. **Happy path**, real conf, run from the repo root: three `OK:` lines (Git,
   sed, find), trailing "All 3 declared prerequisite(s) satisfied.", exit 0.
2. **`MISMATCH`** — `Git | git --version | ^git version 99\.`: prints
   `MISMATCH: Git -- expected /^git version 99\./, got: git version 2.52.0...`,
   then the hint block (`show_hint` fires and prints the `>` line), exit 1.
3. **`NOT FOUND`** — a nonexistent command: prints
   `` NOT FOUND: Fake Tool -- `some-totally-fake-cmd-xyz --version` failed (exit 127). ``
   plus the captured stderr line, then the hint block, exit 1.
4. **Regex-validity guard**, bad pattern `[invalid(`: the `NOTE: ... isn't a
   valid regex` branch does fire (confirms `grep` exits 2 there, not 1) — but
   see the defect below, this is where it gets interesting.
5. **Malformed line** (no pipe) and **orphan hint line** (no check above):
   both print their documented `NOTE:` exactly as written in the source, and
   neither sets `status`, so exit stays 0 whether alone or alongside a valid
   entry. No surprises here.

**Real defect found in case 4 — `scripts/check-prerequisites.sh:170-173`.**
The regex-validity guard correctly sets `status=1` and prints the `NOTE:`, but
it `continue`s *before* `checked=$((checked + 1))` on line 143 — a bad-regex
line is never counted as "checked". If it is the **only** declared entry, the
trailing block

```
if [ "$checked" -eq 0 ]; then
  echo "OK: no runtime prerequisites declared for this project."
  exit 0
fi
```

fires anyway, because `checked` really is 0. Measured: conf with just
`Bad Regex | git --version | [invalid(` prints the correct `NOTE:` line
followed immediately by `OK: no runtime prerequisites declared for this
project.` and **exits 0** — silently discarding the `status=1` that was just
set one branch earlier, and asserting something false (a check *was*
declared; it just couldn't run). This is exit-code-only masking of a
genuinely-reported problem, one line down. The mask is conditional, not
universal: when a bad-regex line sits alongside at least one valid entry that
runs (`checked` > 0), the `if` is skipped, `status` survives, and the run
correctly exits 1 — confirmed by adding a second, valid `Git` line to the
same conf. So the defect only bites a conf whose bad-regex line is otherwise
alone, or where every other line also fails to reach `checked=$((checked+1))`.
**Fixed.** The trailing check now keys on what was *declared* (`${#LABELS[@]}`)
rather than what was successfully *checked* (`$checked`), so a bad-regex-only
conf no longer takes the "nothing declared" branch. Re-measured after the fix:
same single-bad-regex conf now prints the `NOTE:` followed by "Some declared
prerequisites need attention" and exits 1; the two-line conf (bad regex +
valid `Git` entry) is unaffected, still exit 1 as before. `${#LABELS[@]}` is
never wrong for this purpose since it counts parsed declarations before
either continue branch, unlike `checked`, which several branches skip.

**Recipe, if this needs re-proving:** sandbox as above, single-line conf
`Bad Regex | git --version | [invalid(`, run, read the last two lines and the
exit code.
