# Test index

Names every test in this project, so an agent can find the right one by
grepping this file instead of reading the test tree. `luna-core-qa-tester`
and `luna-core-implementer` are both told to grep here first.

Keep it current: a test that isn't listed is a test nobody will find, and an
entry pointing at a test that no longer exists is worse than no entry.

| Test | File | Covers |
| --- | --- | --- |
| Keeper-file check | `tests/notes/live-checks.md` → "Referenced folders need a keeper file" | `validate-luna-core-setup.sh`'s `check_keeper()` fires on an emptied `ref/docs/` or `.claude-memory/` and stays silent when the keeper is present. Must be run on a bootstrapped fixture — Luna-Core's own `.claude-memory/` holds real files and passes either way |

Luna-Core has no automated suite yet — it is documentation, shell scripts and
agent definitions. Until it has one, verification comes from running the
toolkit for real: bootstrapping a throwaway project and validating it. Record
anything that run teaches you in `tests/notes/live-checks.md`.
