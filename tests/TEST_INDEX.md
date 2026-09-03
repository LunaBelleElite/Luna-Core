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

Luna-Core has no automated suite yet — it is documentation, shell scripts and
agent definitions. Until it has one, verification comes from running the
toolkit for real: bootstrapping a throwaway project and validating it. Record
anything that run teaches you in `tests/notes/live-checks.md`.
