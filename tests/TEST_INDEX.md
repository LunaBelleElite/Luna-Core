# Test index

Names every test in this project, so an agent can find the right one by
grepping this file instead of reading the test tree. `luna-core-qa-tester`
and `luna-core-implementer` are both told to grep here first.

Keep it current: a test that isn't listed is a test nobody will find, and an
entry pointing at a test that no longer exists is worse than no entry.

| Test | File | Covers |
| --- | --- | --- |
| Keeper-file check | `tests/notes/live-checks.md` → "Referenced folders need a keeper file" | `validate-luna-core-setup.sh`'s `check_keeper()` fires on an emptied `ref/docs/` or `.claude-memory/` and stays silent when the keeper is present. Must be run on a bootstrapped fixture — Luna-Core's own `.claude-memory/` holds real files and passes either way |
| Memory index keying | `tests/notes/live-checks.md` → "The memory index keyed on the wrong thing" | `merge-memory.sh`'s `merge_index()` keys on the markdown link target, not the last parenthetical; duplicates and silent cross-side erasure. Needs a 3-ingredient fixture, incl. one genuinely new entry, or the erasure never surfaces |
| Entry-point installer | `tests/notes/live-checks.md` → "The entry-point installer, and why CRLF hid a silent no-op" | `install-global-entrypoint.sh` writes two files, substitutes `origin`, is idempotent, and writes nothing when refusing; plus CR-tolerance of the marker match. Requires a `BINMODE=3` awk wrapper — this machine's awk hides the bug |
| Template-vs-functional drift | `tests/notes/live-checks.md` → "The template-vs-functional drift check: what it sees, and the 18% it cannot" | `validate-luna-core-setup.sh`'s `strip_fillins()` + filter chain across all six drift shapes: one-sided method edit, exempt-region drift, blockquote notes, missing/orphan functional copy, whitespace and re-wrap, and the `luna-core-` filter blind spot. Content drift is `NOTE:` only and exits 0; 18.5% of the three fill-in agents is unreachable. Fixture must be a `cp -r` named `Luna-Core` with repo paths rebased — a bootstrapped one cannot run this check at all |
| Prerequisites checker | `tests/notes/live-checks.md` → "check-prerequisites.sh, run for the first time against real declarations" | `check-prerequisites.sh`'s two-pass parse against Luna-Core's now-populated `ref/prerequisites.conf` (Git, GNU sed, GNU find): happy-path `OK`, `MISMATCH`, `NOT FOUND`, the regex-validity guard, a malformed line, and an orphan hint line. Found: the regex-validity guard's `status=1` is silently discarded and overwritten to exit 0 when the bad-regex line is the only one declared — `checked` never increments past the `continue`, so the trailing `checked -eq 0` branch wins |
| Bootstrap literal-filename shield | `tests/notes/live-checks.md` → "The literal `validate-luna-core-setup.sh` filename, shielded from the rename gsubs" | `bootstrap-new-project.sh`'s awk rename chain leaves the deliberately-never-renamed `validate-luna-core-setup.sh` literal unchanged in copied agent body text, while still renaming everything else (frontmatter, prose, cross-references) and leaving blockquote lines untouched. Reverting the shield/restore gsub pair reproduces the exact mangled-filename bug on both affected lines |
| Memory index one-way write-back | `tests/notes/live-checks.md` → "`merge_index()`'s write-back only fires in one direction" | `merge-memory.sh`'s `merge_index()` gated its write-back on `added -gt 0`, which only counted entries the OLDER side contributed, so a strict-superset NEWER side never propagated to older. **Fixed and independently re-verified (2026-09-03):** a second `gap`-counting scan over `newer`'s own lines widens the gate to `added -gt 0 \|\| gap -gt 0`. Re-ran both original superset directions (now converge, byte-identical, truthful summary) plus four new fixtures: two-way gap + conflict in the same run, pure-conflict-must-not-overwrite, non-pointer-line content ignored by both scans, and the pre-fix `added`-only path standalone — all converge correctly |

Luna-Core has no automated suite yet — it is documentation, shell scripts and
agent definitions. Until it has one, verification comes from running the
toolkit for real: bootstrapping a throwaway project and validating it. Record
anything that run teaches you in `tests/notes/live-checks.md`.
