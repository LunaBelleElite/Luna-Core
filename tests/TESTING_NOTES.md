# Testing notes hub

Read end to end by the qa-tester agent before it does any work. This file is
a **hub, not the notes** — the notes live in `tests/notes/`, and the table
below is the authority on which of them exist and when they apply.

This is `main`'s placeholder copy. Luna-Core's own accumulated testing
history stays on `dev`; a project bootstrapped from this kit gets its own
fresh copy of this same structure. Add a row for each notes file you create,
and keep this table complete — the agent trusts it over any list written in
the agent file itself.

| Notes file | Applies to | Read when |
| --- | --- | --- |
| `notes/live-checks.md` | Checks run against the real running project | Every pass |
| `notes/open-items.md` | Index of open questions, one row each | Every pass |
