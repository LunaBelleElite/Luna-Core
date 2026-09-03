# Luna-Core

The source-of-truth starter kit for new Claude Code projects: the default
agents, the session protocols, the baseline `CLAUDE.md`, the versioning scheme,
and the scripts that install all of it into a new project.

Lives at `C:\Users\Owner\Documents\Claude\Luna-Core`.

## Current state

Luna-Core now has a real git repository, on branch `dev`, with `origin` wired
to a private GitHub remote at `https://github.com/LunaBelleElite/Luna-Core.git`.
`ver-0.1.0.0-dev` is committed and pushed, tagged with that version.

## Usage rule: copy from it, never write back

Other projects and sessions **copy** what they need out of this kit and
customize freely in their own folder. **No change made while working on another
project should ever be written back here.** Luna-Core is the only place these
files are authored and maintained. If a session working on another project
wants to propose a change to something that originated here, that change
belongs in a Luna-Core session, not in the consumer's.

## Setting up a new project

The new project should already be its own directory. Bootstrap copies files
*into* it; it does not bring Luna-Core's own dev-only content (`handoff/`,
`.claude-memory/`) along.

```bash
bash "C:/Users/Owner/Documents/Claude/Luna-Core/scripts/bootstrap-new-project.sh" \
     "C:/Users/Owner/Documents/Claude/Luna-Core" <new-project-dir> <ProjectName>
cd <new-project-dir>
bash scripts/validate-luna-core-setup.sh
```

`bootstrap-new-project.sh` copies and renames the agents (`luna-core-*` →
`<projectname>-*`, lowercased, replacing internal references), copies `commands/` into
`.claude/commands/`, places `CLAUDE.md` at the new project's root with its
"This project's toolkit" section filled in with that project's actual agent
names, and creates fresh (not copied) `ref/docs/`, `handoff/`,
`.claude-memory/`, `tests/` (the `TESTING_NOTES.md` hub, the `TEST_INDEX.md`
index that qa-tester and implementer grep before opening any test, and the two
notes files qa-tester reads on every pass), and `CHANGELOG.md` starting at
`ver-0.1.0.0-dev`.

Every one of those exists because a template file *references* it, and each
gets a keeper file — a `.gitkeep`, or a real stub where an agent is told to read
a specific file. Git cannot track an empty directory, so without a keeper the
folder would exist on the machine that ran bootstrap and be absent after the
first clone. The validator checks each path itself rather than trusting
bootstrap to have created it.

`validate-luna-core-setup.sh` is copied into the new project too, so it can be
re-run anytime. It checks the file layout, that every agent was actually
renamed, and functionally checks the superpowers dependencies — then prints a
summary of what is installed. That summary is the same list now sitting in the
new project's own `CLAUDE.md`, which Claude Code auto-loads into every future
session there.

**Still needs manual attention after bootstrap:**

- `<projectname>-research` — bootstrap cannot fill in its `<absolute path to
  this project's repo>` placeholder, since the destination passed in may not be
  the project's final home. This is a required fix, not an optional draft: the
  agent's stated repo path is wrong until you fill it in yourself, in both the
  frontmatter `description:` and the body.
- `<projectname>-qa-tester` is deliberately an unfilled draft — its `## Stack`
  block and the `<projectname>`/`<directory>` placeholders throughout — until
  there is something real to test against. Its own "Template note" is the
  authoritative list of what is open.
- `<projectname>-implementer`'s Part Two (repo path/branch, build command, test
  suite names) is similarly empty until there is real code and tests to point it
  at.

The validator flags all three as notes rather than failures, since it cannot
tell "required fix" from "intentionally still a draft" — check each by hand. The
new project also needs its own `README.md` written from scratch.

## Setting up a new machine

A brand-new empty project directory contains nothing pointing back here, so a
session started in one has no way to know this kit exists. `install-global-entrypoint.sh`
closes that gap, writing two things *outside* this repo:

1. A pointer block in the machine-level `CLAUDE.md`, which Claude Code loads
   into every session regardless of working directory. Deliberately just the
   pointer — every real convention lives in a project's own root `CLAUDE.md`.
2. A global `/new-project` slash command, so bootstrapping is one keystroke
   rather than three remembered commands and a clone URL.

```bash
bash scripts/install-global-entrypoint.sh
```

It takes no arguments — the clone URL is read from this checkout's own
`origin` remote, which is now `https://github.com/LunaBelleElite/Luna-Core.git`.
It refuses to run if that remote is missing, rather than recording an address
it cannot verify, since a wrong address would leave the generated
`/new-project` command failing at clone time with no obvious cause.

Re-running is safe: the pointer block is replaced in place by marker comment,
and anything else in the machine-level `CLAUDE.md` is preserved (a `.bak` is
kept). Restart Claude Code afterward so it picks up the new global command.

It finds Claude's config directory via `scripts/lib-claude-home.sh`, which
honours `CLAUDE_CONFIG_DIR` when set — this machine sets it to `C:\Claude`, and
also has a stale `C:\Users\Owner\.claude`, so the variable is what distinguishes
them.

## Publishing

Luna-Core's hub is a private GitHub repository at
`https://github.com/LunaBelleElite/Luna-Core.git`, wired as `origin`. "Publish"
means an ordinary `git push` — there is no bundle and no synced-drive hub
folder involved:

```bash
git push -u origin dev
```

`git fetch` and `git pull` work against it normally too. Every commit that adds
a new `CHANGELOG.md` version header also gets an annotated tag matching that
version string, pushed with it.

Neither this repo's working copy nor its hub sits inside a folder synced by a
consumer cloud-sync client (Google Drive, Dropbox, OneDrive, iCloud). That
sync-client corruption risk — sync clients don't understand git's atomic
object and ref writes, and can leave a ref pointing at a vanished object,
sometimes long after a push looked successful — doesn't apply to Luna-Core
itself for that reason. It's noted here as general guidance for other
projects that might publish to a hub on a synced drive.

For a project whose *working copy* or whose *hub* is in a synced folder, there
are two fixes: redirect the working copy's `.git` internals to non-synced
local storage and leave a `gitdir:` pointer file behind, or use a `.bundle`
file rather than a live bare repo for the hub (a single file has nothing to
catch mid-write, unlike a bare repo's incremental ref and object writes).
Neither is a default. Check, note the risk, and ask before applying either.

## Git commits require explicit permission

Never commit, merge, or push in this project or any project cloned from it
without asking the user first and getting an explicit yes — every time, not once
per session or once per project.

**Commit and push are bundled as one action:** once a commit is approved, push
(or publish) it right after, with no separate ask. `git merge` still requires its
own separate permission.

## Layout

- `agents/` — the template source for agent definitions. **Not a working
  location:** Claude Code only recognizes subagents in `.claude/agents/`, so a
  bare `agents/` folder is documentation only, invisible to the harness.
  Bootstrap copies from here into a new project's `.claude/agents/`.
- `.claude/agents/` — Luna-Core's own functional copies, for the same reason.
- `commands/` — same pattern: the template source for `/wake-up` and
  `/debrief`, copied into a new project's `.claude/commands/`.
- `CLAUDE.md` — the baseline instructions, at the repo root. It does two jobs:
  it is Luna-Core's own operating instructions (auto-loaded by any session
  working here, with nothing to install), and it is the template a new project
  starts from, copied by bootstrap with the toolkit section rewritten. Loading
  is automatic; *keeping it accurate* is not — that is
  `<projectname>-docs-writer`'s job.
- `scripts/bootstrap-new-project.sh` — sets up a new project. Not copied into
  new projects; it is this kit's own distribution tool.
- `scripts/validate-luna-core-setup.sh` — confirms a bootstrap landed
  correctly. Copied into new projects.
- `scripts/install-global-entrypoint.sh` — writes this machine's entry point.
  Run once per machine; not copied into new projects, since it is about the
  machine rather than any one project.
- `scripts/lib-claude-home.sh` — the shared resolver for "where does this
  machine's live Claude config actually live?", sourced by every script that
  touches it. It sets `CLAUDE_DIR`, honouring `CLAUDE_CONFIG_DIR` first. A
  missing library is a loud error rather than a silent fall back to guessing.
  Copied into new projects.
- `scripts/merge-memory.sh` — a two-way, no-clobber merge between local
  auto-memory and this repo's `.claude-memory/`. Copied into new projects.
- `scripts/check-superpowers.sh` — the dependency check described below.
- `scripts/check-prerequisites.sh` + `ref/prerequisites.conf` — the runtime and
  toolchain a project declares it needs (a .NET SDK, a Python version), checked
  by the validator so Wake Up can verify them on an unfamiliar machine. The
  script is generic; each project declares its own list, and this kit's own stub
  declares nothing. Both copied into new projects.

## Agents

**Naming convention, for every agent here:** a project's copy is prefixed with
that project's own name, lowercased — `<projectname>-<agent-role>`. When cloning an agent
into a new project, rename the file and its `name:` field, and replace the
`Luna-Core` references inside it. Every agent file carries a "Template note"
saying so — keep that note on any new agent added here.

- `luna-core-docs-writer` — owns `CLAUDE.md`, `README.md`, `CHANGELOG.md`,
  `ref/docs/*.md`, `.claude/agents/*.md`, and the `.claude-memory/` and
  `handoff/` working areas. Invoke it on demand for a docs pass, and always
  before a commit to `dev` or a merge into `main` — it updates the right files
  and enforces which files are allowed on which branch (in particular that
  `.claude-memory/`, `handoff/`, `.claude/agents/*.md`, and `ref/docs/*.md`
  pages never reach `main` — though `ref/docs/`'s folder and keeper file do,
  empty, since it's a path `CLAUDE.md` tells every session to consult).
- `luna-core-research` — a read-only research specialist for multi-round,
  open-ended investigation. Invoke it instead of researching in the main
  conversation, which permanently bloats history that gets re-read every later
  turn. It reports one distilled answer, never a trace of the process, and never
  edits files; findings that imply a change go to the parent conversation or to
  docs-writer.
- `luna-core-qa-tester` — writes and extends tests, designs edge-case
  checklists, and keeps a running log of surprising behaviour so coverage
  accumulates across sessions. The `agents/` copy is a template that
  deliberately leaves its `## Stack` block and `<projectname>`/`<directory>`
  placeholders blank, for a new project to fill in when it bootstraps from
  Luna-Core; the functional copy in `.claude/agents/` has all of them filled
  in for Luna-Core itself and is fully usable today.
- `luna-core-implementer` — implements a task test-first: the failing test
  before the implementation, every pin proved by deliberately breaking the
  guarded code with the red count predicted beforehand, and no silently weakened
  pins. Reports what it *drove* versus what it merely *inspected*, and never
  commits. Split into a portable Part One (the method — keep verbatim when
  cloning) and a fill-in Part Two (repo path, build command, suite names). As
  with qa-tester, the `agents/` template leaves Part Two blank for a new
  project to fill in at bootstrap; the `.claude/agents/` functional copy has
  it filled in for Luna-Core itself and is fully usable today.

## Wake Up / Debrief protocols

Two session-boundary rituals, available as slash commands
(`.claude/commands/wake-up.md`, `debrief.md`) and as natural-language phrases
recognized via `CLAUDE.md`.

- **Wake Up** — "wake up", "let's get our day started", "are you awake", or
  `/wake-up`. Fetches the latest published state, then checks whether the
  computer has changed since the last recorded check (via `handoff/STATUS.md`).
  Same computer → a quick freshness check. Different computer, or first run → a
  full sweep: memory, `handoff/HANDOFF.md`, recent commits, CHANGELOG, README,
  and a *functional* test of every agent in `.claude/agents/` — actually
  invoking each one, since a machine switch is exactly when an agent could be
  stale or missing.
- **Debrief** — "let's end here for the day", "I'm switching to another
  computer", or `/debrief`. Preps everything docs-writer owns, writes
  `handoff/HANDOFF.md` with enough detail for a total stranger to continue,
  records the computer and timestamp, then **asks** to commit and publish — it
  never does so on its own.

**When triggered by a phrase rather than the slash command, confirm before
running either** — with a little personality, like a butler checking in, not a
flat system prompt. Typing the slash command already counts as confirmation.

`handoff/STATUS.md` and `handoff/HANDOFF.md` are dev-only, never `main`, owned
by `<projectname>-docs-writer` — same treatment as `.claude-memory/` and
`.claude/agents/*.md`.

## Dependency: superpowers plugins

The agents and workflows here are written assuming two plugins, both descended
from Jesse Vincent's [`obra/superpowers`](https://github.com/obra/superpowers):

1. **superpowers-extended-cc** (`pcvelz/superpowers` marketplace) — skills like
   `brainstorming`, `writing-plans`, `executing-plans`,
   `test-driven-development`, `systematic-debugging`, `requesting-code-review`.
2. **Claude Code on Steroids** (`GadaaLabs/claude-code-on-steroids`) — 24
   renamed skills plus the `/tokenburn` command. It installs into the config
   directory's `skills/` and does not touch the other plugin, so the two
   coexist, though several overlap in purpose under different names.

Run the check before anything that depends on either. It verifies each is
*installed* and that it *functions*:

```bash
bash scripts/check-superpowers.sh
```

**State on ASUNA-PC (2026-09-02):** both are installed and
`check-superpowers.sh` exits 0. This machine additionally runs
`superpowers@superpowers-dev` from `obra/superpowers`, the upstream project both
forks descend from — so three overlapping skill sources are enabled at once, and
several skills exist under more than one name. Which is authoritative is an open
decision.

Claude Code on Steroids needed two local fixes here, both from the same cause:
it assumes `$HOME/.claude`, while this machine sets `CLAUDE_CONFIG_DIR=C:\Claude`.
Its skills and `/tokenburn` were installed to `C:\Claude` by hand rather than by
its installer, and `tokenburn.py` was patched to read session logs from
`CLAUDE_CONFIG_DIR` — unpatched it found 2 log files instead of 589 and reported
a confident $0.00.

If a session rather than a person does the cloning, it should run the check
itself immediately afterward, before proceeding.

### Installing them

For superpowers-extended-cc, inside an interactive `claude` session:

```bash
/plugin marketplace add pcvelz/superpowers
/plugin install superpowers-extended-cc@superpowers-extended-cc-marketplace
/superpowers-extended-cc:onboard
```

Then enable auto-update, and note that Claude Code 2.1.233+ also wants
`{ "env": { "CLAUDE_CODE_ENABLE_TODO_TOOLS": "1" } }` in `settings.json`.

Claude Code on Steroids is a shell installer that downloads and runs code from
GitHub — an AI assistant should not, and will not, run it on your behalf. **Run
it yourself**, in your own terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/GadaaLabs/claude-code-on-steroids/main/install.sh | bash
```

It needs the Claude Code CLI and Node.js 20+, and it creates a session-start
hook affecting every Claude Code session on the machine, not just this project.

## Memory roaming across machines

Claude's local auto-memory for a project only lives on the machine it was
created on. Every project from this kit keeps a synced copy in its own repo so
memory roams with the user:

```bash
bash scripts/merge-memory.sh
```

One command covers both directions — deliberately, because two directions
implemented separately would eventually disagree about what is current. Run it
before committing memory changes, and on a machine that may not have that
project's memory yet. Wake Up runs it for you on a machine switch.

**It never flat-copies.** It compares each file and moves only the genuinely
newer side. The timestamp it trusts is each memory file's own `modified:`
frontmatter, falling back on the repo side to that file's last *commit* date —
never its mtime. Git records no mtimes, so every file in a fresh clone carries
the moment of checkout and would look newer than anything local; a flat copy in
exactly that situation — a new machine, when you need this most — would destroy
real work.

Three things it refuses to decide, reporting them instead:

- **A file on one side only.** Absence has no timestamp, so "deliberately
  deleted" and "never received" cannot be told apart. It copies across, never
  deletes, and says so.
- **Same timestamp, different content.** Left untouched on both sides.
- **`MEMORY.md`.** An index both machines append to, so newest-wins would
  discard the other machine's entries. Its pointer lines are unioned by link
  target, and conflicting text for the same target is reported, not resolved.

## Keep each project's memory scoped locally

Claude's local auto-memory is scoped by the session's working directory
(`<config dir>/projects/<sanitized-cwd>/memory/`). A session that works on a
project while its working directory is a shared parent folder puts that
project's memories in a shared bucket, where they can leak into unrelated
projects opened from that same folder later.

**Always work on a project as its own session, with the working directory set to
that project's own folder.** If a session realizes partway through that it is
scoped to a shared directory, switch, then move that project's existing memory
files into the project's own scoped location and remove them from the shared
one.

## Branches

- `dev` — where work happens. The working branch.
- `main` — does not exist yet. It will hold the clean template: no project
  history, so someone can point their AI at the repo and its README and go.
  Published by explicitly merging `dev` into it, with the dev-only content
  (`.claude-memory/`, `handoff/`, `.claude/agents/`, and `ref/docs/*.md`
  pages) stripped first. `ref/docs/` itself is a partial exception: the
  pages are stripped like the rest, but the empty folder and its keeper
  file survive on `main`, since `CLAUDE.md` tells every session to consult
  `ref/docs/` before reading source. Both branches carry the same version
  number; `dev`'s string has `-dev` appended.
