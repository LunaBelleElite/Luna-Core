# `ref/docs/`

This folder holds the primary reference documentation for Luna-Core's own
scripts — one page per script (or shared library), explaining what it does,
how it's invoked, when it refuses, and the non-obvious traps in its
behavior. It exists to serve the instruction in the project's root
`CLAUDE.md`, under "Always do these":

> Before reading source files, check `ref/docs/` for an explanation of the
> module or file first. These MD files are the primary reference for
> understanding what source files do and how they fit together. Only read
> source files directly when the docs don't cover what you need.

Read a page here before opening the corresponding source file. If a page
doesn't answer your question, then read the source — and consider whether
the page should be updated once you've learned something it was missing.

## Pages

| Script | Page |
| --- | --- |
| `scripts/lib-claude-home.sh` | [lib-claude-home.md](lib-claude-home.md) |
| `scripts/install-global-entrypoint.sh` | [install-global-entrypoint.md](install-global-entrypoint.md) |
| `scripts/check-superpowers.sh` | [check-superpowers.md](check-superpowers.md) |
| `scripts/check-prerequisites.sh` | [check-prerequisites.md](check-prerequisites.md) |
| `scripts/validate-luna-core-setup.sh` | [validate-luna-core-setup.md](validate-luna-core-setup.md) |
| `scripts/bootstrap-new-project.sh` | [bootstrap-new-project.md](bootstrap-new-project.md) |
| `scripts/merge-memory.sh` | [merge-memory.md](merge-memory.md) |

## Dev-only

These pages are development documentation for working *on* Luna-Core
itself — useless and confusing to a fresh consumer who clones `main` having
never run this project. They live only on `dev` and are stripped when `dev`
merges into `main`. The folder and this file's neighbor, `.gitkeep`, are the
one exception: they survive on `main`, empty, so the "check `ref/docs/`
first" instruction above still points at a real, present folder instead of
one that vanished on clone. See `CLAUDE.md`'s "A referenced folder must be
created, with a keeper file" and the branch-discipline table in
`luna-core-docs-writer`'s own agent definition for the exact mechanics.
