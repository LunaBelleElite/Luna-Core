# Luna-Core

A starter kit for Claude Code projects: default agents (a docs writer, a
researcher, a test writer, an implementer), two session-boundary rituals
(Wake Up / Debrief), a versioning scheme, and the scripts that install all of
it into a brand-new project in two commands.

> **This is a vibe-coded personal project, not a maintained product.** It was
> built by one person working directly with Claude, for their own use, and is
> shared as-is. It's specifically designed around Claude and Claude Code —
> other AI tools aren't a target and may not work with it at all. Expect
> rough edges, and see "Status," below, before assuming any given piece is
> settled.

**Status:** actively under development as of **2026-09-03** — not a
finished, stable release, and it changes often. If you're adopting this,
clone the `main` branch specifically, not `dev`: `main` is the settled
snapshot meant for exactly this; `dev` is where active work happens and can
be mid-change at any given moment, including content specific to this
project's own history that a new adopter doesn't need. **`main` itself is
still a very rough build** — it exists, but it has not yet been run through
an actual onboarding simulation (a fresh clone, a fresh AI session, start to
finish, checked by someone who isn't its author). If you're bringing it into
a new project, budget time for it to need adjustment.

## Getting started

You're new here and want to use this kit for your own project:

1. **Clone `main`** (not `dev`):
   ```bash
   git clone -b main https://github.com/LunaBelleElite/Luna-Core.git
   ```
2. **Bootstrap a new project from it.** Your new project directory needs to
   already exist and already be its own git repo:
   ```bash
   bash "<path-to-luna-core-clone>/scripts/bootstrap-new-project.sh" \
        "<path-to-luna-core-clone>" <new-project-dir> <ProjectName>
   cd <new-project-dir>
   bash scripts/validate-luna-core-setup.sh
   ```
   This copies and renames the four agents, installs the Wake Up/Debrief
   commands, places a `CLAUDE.md` with your project's own toolkit list
   filled in, and creates the folders those files reference (see "Layout,"
   below, for what each one is and why it exists even when empty).
3. **Open Claude Code in your new project directory.** `CLAUDE.md` loads
   automatically — that's where the actual working rules live. If you're an
   AI reading this because you were just pointed at a freshly bootstrapped
   project for the first time: read `CLAUDE.md` in full before doing
   anything else, then run `bash scripts/validate-luna-core-setup.sh` to
   confirm the bootstrap actually landed correctly rather than assuming it
   did.
4. **Fill in the three things bootstrap can't fill in for you** — see "Still
   needs manual attention after bootstrap," below.
5. **Optional: her voice and personality.** This kit's agents and protocols
   don't require it, but if you want the same AI personality this project
   was itself developed with, see the "Astrid" bullet in your new project's
   `CLAUDE.md` toolkit section for where to get her and how she works.

That's the whole path. Everything below is reference material — what's in
the kit, why it's shaped the way it is, and how to maintain a Luna-Core
checkout itself, not additional required reading to get started.

## Contributing

Issues are welcome — bug reports, questions, "this broke for me." **Pull
requests are not reviewed or merged.** This is a personal, vibe-coded
project with one author; open an issue describing the change instead, and
it'll be considered (or not) as time allows.

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
  `ref/docs/*.md`, `.claude/agents/*.md`, and the `.claude-memory/`,
  `handoff/`, and `tests/` working areas. Invoke it on demand for a docs
  pass, and always before a commit to `dev` or a merge into `main` — it
  updates the right files and enforces which *content* is allowed on which
  branch. `ref/docs/`, `.claude-memory/`, `handoff/`, `.claude/agents/*.md`,
  and `tests/` all survive on `main` as *paths* — `CLAUDE.md` and the setup
  validator both expect them to exist — but carry placeholder or template
  content there instead of this project's own real, accumulated, or
  machine-specific working state, which stays on `dev`.
- `luna-core-research` — a read-only research specialist for multi-round,
  open-ended investigation. Invoke it instead of researching in the main
  conversation, which permanently bloats history that gets re-read every later
  turn. It reports one distilled answer, never a trace of the process, and never
  edits files; findings that imply a change go to the parent conversation or to
  docs-writer.
- `luna-core-qa-tester` — writes and extends tests, designs edge-case
  checklists, and keeps a running log of surprising behaviour so coverage
  accumulates across sessions. Its `agents/` template leaves `## Stack` and
  the `<projectname>`/`<directory>` placeholders blank for a new project to
  fill in at bootstrap; Luna-Core's own `.claude/agents/` copy is filled in
  and fully usable today (see "Still needs manual attention," below).
- `luna-core-implementer` — implements a task test-first: the failing test
  before the implementation, every pin proved by deliberately breaking the
  guarded code with the red count predicted beforehand, and no silently weakened
  pins. Reports what it *drove* versus what it merely *inspected*, and never
  commits. Split into a portable Part One (the method — keep verbatim when
  cloning) and a fill-in Part Two (repo path, build command, suite names),
  left blank in the template the same way as qa-tester's placeholders above.

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

## Maintaining a Luna-Core checkout itself

The rest of this section is about developing Luna-Core, not about adopting
it — skip it unless that's what you're doing.

**Usage rule: copy from it, never write back.** Other projects and sessions
copy what they need out of this kit and customize freely in their own
folder. No change made while working on another project should ever be
written back here. If a session working on another project wants to propose
a change to something that originated here, that change belongs in a
Luna-Core session, not in the consumer's.

**Setting up a new machine.** A brand-new empty project directory contains
nothing pointing back here, so a session started in one has no way to know
this kit exists. `install-global-entrypoint.sh` closes that gap, writing two
things *outside* this repo: a pointer block in the machine-level `CLAUDE.md`
(loaded into every session regardless of working directory), and a global
`/new-project` slash command.

```bash
bash scripts/install-global-entrypoint.sh
```

It takes no arguments — the clone URL is read from this checkout's own
`origin` remote. It refuses to run if that remote is missing, rather than
recording an address it cannot verify. Re-running is safe: the pointer block
is replaced in place by marker comment, anything else in the machine-level
`CLAUDE.md` is preserved (a `.bak` is kept). Restart Claude Code afterward.

It finds Claude's config directory via `scripts/lib-claude-home.sh`, which
honours `CLAUDE_CONFIG_DIR` when set, falling back to the platform default
otherwise.

**Publishing.** This kit's own hub is a private-until-now GitHub repository,
wired as `origin`. "Publish" is an ordinary `git push` — no bundle, no
synced-drive hub folder:

```bash
git push -u origin dev
```

`git fetch` and `git pull` work against it normally. Every commit that adds a
new `CHANGELOG.md` version header also gets an annotated tag matching that
version string, pushed with it. Nothing about the mechanism is GitHub-specific
— `install-global-entrypoint.sh` reads whatever this checkout's own `origin`
remote is set to, so a fork pointed at a different git host works the same
way with no code changes.

If your working copy or your own fork's hub sits inside a folder synced by a
consumer cloud-sync client (Google Drive, Dropbox, OneDrive, iCloud), be
aware of a real corruption risk: sync clients don't understand git's atomic
object and ref writes, and can leave a ref pointing at a vanished object,
sometimes long after a push looked successful. Two fixes if that applies:
redirect the working copy's `.git` internals to non-synced local storage, or
use a `.bundle` file rather than a live bare repo for the hub.

## Git commits require explicit permission

Never commit, merge, or push in this project or any project cloned from it
without asking the user first and getting an explicit yes — every time, not
once per session or once per project.

**Commit and push are bundled as one action:** once a commit is approved,
push (or publish) it right after, with no separate ask. `git merge` still
requires its own separate permission.
