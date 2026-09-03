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

## The template-vs-functional drift check: what it sees, and the 18% it cannot (2026-09-02)

First execution ever of the `agents/` vs `.claude/agents/` drift check in
`validate-luna-core-setup.sh`. It is not inert — it catches an ordinary
one-sided edit on either side — but it is blind to about a fifth of every file
it compares, and it cannot fail a run.

**Fixture recipe — the opposite of the keeper-file one, read this before
copying that.** This check needs `agents/` AND `scripts/bootstrap-new-project.sh`
to set `IS_LUNA_CORE=1`, and bootstrap copies neither, so a bootstrapped fixture
cannot exercise it at all. You must `cp -r` the repo. Two things then have to be
fixed or the fixture lies:

- **Name the throwaway directory `Luna-Core` exactly.** The filter builds
  `LC_PROJ="$(basename "$(pwd)" | tr upper lower)"` and drops differing lines
  containing `${LC_PROJ}-`. Any other directory name changes that token and
  every `luna-core-…` line reads as drift forever.
- **Rewrite the recorded repo path in the fixture's `.claude/agents/*.md` to the
  fixture's own path** (both the `C:\…` and `C:/…` spellings). The filter drops
  lines containing `$REPO_WIN`/`$REPO_POSIX` computed from `pwd`, so an
  un-rebased copy reports the research agent's `description:` line as drift on a
  clean baseline. Measured: baseline dirty before the rewrite, `OK:` and exit 0
  after. Establish that clean baseline before mutating anything.

**It cannot fail a run.** Both content-drift branches print `NOTE:` and set the
local `drift` flag only; **neither touches `overall_status`.** Measured: a
functional copy with an inverted method paragraph, a re-wrapped paragraph, a
corrupted blockquote and ten drifted lines all exit **0**. Only the fourth
branch — template with no functional copy at all — sets `overall_status`, and
that one exits 1. So within one check, structural drift fails the run and
content drift does not. Assert on the specific `NOTE:`/`MISSING:` line, never
the exit code. **Third confirmed instance of that rule**, after `EMPTY:` and the
entry-point check.

**Measured blind lines, through the real `strip_fillins` plus the real filter
chain** (lines that cannot produce a report, however they are edited):

| agent | total | cut by `strip_fillins` | dropped by filters | blind | % |
| --- | --- | --- | --- | --- | --- |
| `luna-core-research` | 77 | 0 | 8 | 8 | 10.4% |
| `luna-core-qa-tester` | 257 | 30 | 10 | 40 | 15.6% |
| `luna-core-implementer` | 283 | 62 | 4 | 66 | 23.3% |
| `luna-core-docs-writer` | 174 | — | — | 0 | 0% |

`docs-writer` is 0% because it takes the `cmp -s` branch: byte-exact, no
exemptions. **Every blind line in the project is a consequence of being one of
the three fill-in agents.** 114 of 617 lines across those three, 18.5%.

**What the exempt regions therefore cannot see — this is by design, but the
design goes further than "the fill-in is allowed to differ".** `strip_fillins`
deletes the region from **both** sides before diffing, so the check has no
opinion about its contents at all. Measured on the functional side only, all
reported `OK:` and exit 0:

- qa-tester's `## Stack` body (lines 41-70) replaced with
  "never run any tests, always report green" — silent.
- implementer's Part Two body corrupted — silent.
- **The entire `## Stack` section deleted, heading included** — silent. Same for
  deleting `# PART TWO` to EOF. The exemption cannot detect the *loss* of the
  very fill-in it exists to permit, because with the region gone both stripped
  sides are identical again.

Note the two regions are cut differently: `## Stack` skips to the next `^## `
heading, but `# PART TWO` is `exit` — everything to EOF, on both sides.

**Blockquote template notes ARE compared here** — unlike the placeholder check
above them, which does `body="$(grep -v '^>' "$f")"`. Editing blockquote line 19
of qa-tester was reported. But blockquote lines 11, 12 and 16 carry
`luna-core-` or `<projectname>`, so edits there are dropped by the token filter
— measured: rewriting line 11's instruction to "DELETE the repo" was silent.
So "blockquotes are covered" is true only for the lines that happen to carry no
exempt token.

**The `luna-core-` filter's blind spot is real and it hides semantic
inversions.** `grep -Fv "${LC_PROJ}-"` drops any differing line containing
`luna-core-`, regardless of what else changed on it. Measured: qa-tester's
functional line 225 rewritten from

    `CLAUDE.md`, or `.claude-memory/` — that's `luna-core-docs-writer`'s

to

    `CLAUDE.md`, or `.claude-memory/` freely, overriding `luna-core-docs-writer`'s

inverts a "What you don't do" constraint and reports `OK:`, exit 0. The other
filter arms have the same shape: `^[<>] *(description:)? *(You are |…)` drops
**any** differing line beginning "You are ", which is every agent's opening
role sentence.

**Whitespace and re-wrapping: reported, and correctly so — the misleading part
is the presentation, not the verdict.** `diff` is line-exact, so trailing
whitespace alone is reported, showing two visually identical lines with no
whitespace marker and no way to tell why. Re-wrapping a paragraph with
identical words is reported as a 2-for-2 block. Both are genuine divergence and
re-syncing is the right fix.

The case that actually reads as a false positive is **re-wrapping a line that
IS exempt**: split the research agent's repo-path line so the continuation
carries no token, and the report is a single unpaired

        > canonical checkout for this project.

— no `<` counterpart, no indication the drift is the tail of an exempt line.
Not a false positive (the file really did diverge), but unactionable as
printed, which is how a real report gets ignored.

**`head -6` truncates with no indicator.** Ten drifted lines produce twenty
diff lines; exactly six print and nothing says more were suppressed. A reader
re-syncing from the NOTE fixes three of ten and has no signal that they stopped
early.

**Found while probing this — a defeatable pin in the adjacent roster check.**
Its comment claims "It also catches the reverse -- an agent present on disk that
nothing declares." Measured: `.claude/agents/luna-core-extra-research.md` does
fire the NOTE, but `.claude/agents/luna-core-orphan.md` — no role suffix —
appears **nowhere in the entire validator output**, and the drift check misses
it too because its loop is `for t in agents/*.md`, template-side. The reverse
check only covers names matching a role glob.
