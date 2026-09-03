#!/usr/bin/env bash
# Confirms a project bootstrapped from Luna-Core (via bootstrap-new-project.sh
# or done by hand) actually landed correctly, and prints an explicit summary
# of what's installed and recognized.
#
# Usage: bash scripts/validate-luna-core-setup.sh
# Can be run from anywhere -- it resolves paths relative to its own location
# (this file must stay at <project-root>/scripts/), not the caller's cwd.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

overall_status=0
# Machine-level dependency problems: reported, but deliberately kept out of
# overall_status, which is about this project's FILES.
deps_status=0

# Is this checkout Luna-Core itself, rather than a project bootstrapped from
# it? Bootstrap copies neither the agents/ template source nor its own
# distribution script, so their presence together is a reliable tell. It
# matters because Luna-Core's agents are legitimately named luna-core-*,
# and flagging that as a failed rename made Luna-Core permanently unable to
# pass its own validator -- useless for the Wake Up protocol, which now relies
# on this script as its environment gate.
IS_LUNA_CORE=0
if [ -d "agents" ] && [ -f "scripts/bootstrap-new-project.sh" ]; then
  IS_LUNA_CORE=1
fi

check() {
  # check <description> <path>
  if [ -e "$2" ]; then
    echo "OK: $1"
  else
    overall_status=1
    echo "MISSING: $1 (expected at $2)"
  fi
}

# check() proves a folder EXISTS, which is not the same as proving it survives.
# Git tracks files, not directories, so a referenced folder whose keeper file
# has been deleted is simply absent after the next clone -- the failure shows up
# on the second machine, not this one, which is exactly the case CLAUDE.md's
# "A referenced folder must be created, with a keeper file" section requires this
# script to catch. Recursive (-type f) on purpose: a folder holding only an empty
# subdirectory still vanishes wholesale on clone, so "has a subfolder" is not
# "has content".
check_keeper() {
  # check_keeper <description> <dir>
  [ -d "$2" ] || return 0   # absence is check()'s job, not this one
  if [ -z "$(find "$2" -type f 2>/dev/null | head -1)" ]; then
    overall_status=1
    echo "EMPTY: $1"
    echo "       $2/ exists but contains no files. Git cannot track an empty"
    echo "       directory, so it will be missing after the next clone."
    echo "       Restore its keeper file:  touch $2/.gitkeep"
  fi
}

echo "=== File layout ==="
check "CLAUDE.md at project root" "CLAUDE.md"
check "CHANGELOG.md at project root" "CHANGELOG.md"
check "ref/docs/ folder" "ref/docs"
check_keeper "ref/docs/ has a keeper file" "ref/docs"
check "handoff/STATUS.md" "handoff/STATUS.md"
check "handoff/HANDOFF.md" "handoff/HANDOFF.md"
# Every path a template tells this project to use has to actually exist, or the
# first instruction an agent follows points at nothing. These are checked
# rather than merely created because that gap survived once already: the folder
# creation was right for ref/docs/ and simply never extended to the rest.
check ".claude-memory/ folder (repo side of the memory merge)" ".claude-memory"
check_keeper ".claude-memory/ has a keeper file" ".claude-memory"
check "tests/TESTING_NOTES.md (qa-tester reads this first, every time)" "tests/TESTING_NOTES.md"
check "tests/TEST_INDEX.md (qa-tester and implementer grep this before opening a test)" "tests/TEST_INDEX.md"
check "tests/notes/live-checks.md (qa-tester reads this every pass)" "tests/notes/live-checks.md"
check "tests/notes/open-items.md (qa-tester reads this every pass)" "tests/notes/open-items.md"
check ".claude/commands/wake-up.md" ".claude/commands/wake-up.md"
check ".claude/commands/debrief.md" ".claude/commands/debrief.md"
check "scripts/check-superpowers.sh" "scripts/check-superpowers.sh"
check "scripts/lib-claude-home.sh (shared ~/.claude resolver)" "scripts/lib-claude-home.sh"
check "scripts/merge-memory.sh" "scripts/merge-memory.sh"
check "scripts/check-prerequisites.sh" "scripts/check-prerequisites.sh"

echo
echo "=== README.md ==="
# Bootstrap deliberately does NOT create a README.md (a new project should
# write its own, not reuse Luna-Core's) -- so its absence right after
# bootstrap is expected, not a setup failure. But CLAUDE.md already
# references a "Dependency: superpowers plugins" section in README.md by
# exact name in two places, so flag this as an informational note (same
# treatment as an agent's unfilled placeholder) rather than staying silent.
if [ -f "README.md" ]; then
  if grep -q "Dependency: superpowers plugins" README.md; then
    echo "OK: README.md exists and has the 'Dependency: superpowers plugins' section CLAUDE.md references"
  else
    echo "NOTE: README.md exists but is missing the 'Dependency: superpowers plugins' section -- CLAUDE.md references it by that exact name in two places"
  fi
else
  echo "NOTE: no README.md yet -- expected right after bootstrap, but CLAUDE.md already references a 'Dependency: superpowers plugins' section in one. Write your own README with that section before relying on CLAUDE.md's cross-references."
fi

echo
echo "=== Agents ==="
AGENT_FILES=(.claude/agents/*-docs-writer.md .claude/agents/*-research.md .claude/agents/*-qa-tester.md .claude/agents/*-implementer.md)
FOUND_AGENTS=()
for f in "${AGENT_FILES[@]}"; do
  if [ -f "$f" ]; then
    base="$(basename "$f" .md)"
    FOUND_AGENTS+=("$base")
    # Note: every agent file legitimately keeps a literal "<ProjectName>" in
    # its permanent "Template note" (documents the rename convention for the
    # NEXT clone) -- that's not a bug. Only the lowercase <projectname>/
    # <directory>/<absolute path...> placeholders (qa-tester's operative body
    # text, Research's repo-path line) or an explicit "fill in" instruction
    # (implementer's Part Two, or any future draft agent using the same
    # convention) indicate a genuinely unfilled template.
    # Placeholder checks read the file WITHOUT its blockquote lines. Every
    # agent keeps a permanent "> Template note" documenting the rename
    # convention for the next clone, and those lines legitimately contain
    # placeholder text forever -- counting them means a correctly filled-in
    # agent is reported as unfilled, and the real signal gets ignored as noise.
    body="$(grep -v '^>' "$f")"
    if [[ "$base" == *-research ]] && printf '%s' "$body" | grep -q "<absolute path"; then
      # Research's repo-path placeholder is never auto-filled (bootstrap
      # can't know the project's final home) -- this one is always a
      # required fix, not an optional draft state. (Implementer's Part Two
      # also uses an <absolute path> placeholder, but that one IS meant to
      # stay a draft until real code exists -- keyed off the role name, not
      # the shared placeholder text, so the two aren't conflated.)
      echo "NOTE: $base still has its <absolute path...> placeholder unfilled -- this is REQUIRED, not a draft state; fill in the real repo path before relying on this agent"
    # Markdown headings are excluded from the "fill in" test: the implementer's
    # permanent heading "PART TWO -- THIS PROJECT'S SPECIFICS (fill in when
    # first used on real code)" contains the phrase forever, so the note fired
    # no matter how completely the section was filled in. Same failure as the
    # blockquote template notes above -- a note that can never come clean is
    # one you learn to ignore, which costs you the times it is real.
    elif printf '%s' "$body" | grep -q "<projectname>\|<directory>\|<absolute path" || printf '%s' "$body" | grep -v '^#' | grep -qi "fill in"; then
      # Informational only -- some agents (e.g. qa-tester, implementer) are
      # meant to stay a draft template until first real use. Not a setup
      # failure.
      echo "NOTE: $base still has unfilled <placeholder> text -- expected for a draft template, fill in before relying on it"
    fi
    if grep -q "^name: luna-core-" "$f"; then
      if [ "$IS_LUNA_CORE" -eq 1 ]; then
        echo "OK: $base is present (this is Luna-Core itself, so the luna-core-* name is correct)"
      else
        overall_status=1
        echo "NOT RENAMED: $base's 'name:' field still says luna-core-* -- rename didn't complete"
      fi
    else
      echo "OK: $base is present and renamed"
    fi
  fi
done
if [ ${#FOUND_AGENTS[@]} -eq 0 ]; then
  overall_status=1
  echo "MISSING: no agent files found matching *-docs-writer.md / *-research.md / *-qa-tester.md in .claude/agents/"
fi

# Cross-check the agents on disk against the roster CLAUDE.md declares.
#
# The loop above only iterates what its glob matched, and the guard directly
# above it fires only when EVERY agent is absent -- so a project missing one
# role passed with no signal at all, reporting "everything Luna-Core
# provides" while a whole capability didn't exist. Checking against CLAUDE.md's
# own "**Agents:**" line rather than a hardcoded list of four means this stays
# true for a project that legitimately changes its roster: that file already
# instructs you to update the section when an agent is added, removed or
# renamed, so the declaration is the authority. It also catches the reverse --
# an agent present on disk that nothing declares.
if [ -f "CLAUDE.md" ]; then
  # Flatten to a single space-separated list: `grep -o` emits one match per
  # line, and the membership test below is a space-delimited `case` glob, which
  # silently matches nothing across newlines -- so without this every declared
  # agent reads as undeclared.
  DECLARED="$(grep -m1 '^\- \*\*Agents:\*\*' CLAUDE.md 2>/dev/null \
              | grep -oE '`[A-Za-z0-9][A-Za-z0-9_-]*`' | tr -d '`' | tr '\n' ' ')"
  DECLARED="$(printf '%s' "$DECLARED" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  if [ -z "$DECLARED" ]; then
    echo "NOTE: CLAUDE.md has no '- **Agents:**' line listing this project's agents,"
    echo "      so there's nothing to check the .claude/agents/ folder against."
  else
    for name in $DECLARED; do
      if [ ! -f ".claude/agents/$name.md" ]; then
        overall_status=1
        echo "MISSING: CLAUDE.md declares agent '$name' but .claude/agents/$name.md does not exist"
        echo "         (either the file was lost, or CLAUDE.md's toolkit list is stale — fix whichever is wrong)"
      fi
    done
    # Iterate every agent file on disk, NOT just the role-suffixed ones the
    # glob above matched. FOUND_AGENTS only ever holds files ending in a known
    # role, so an agent whose filename carries none of them was invisible to
    # this check -- and to the whole validator -- while the comment above
    # claimed it catches an agent that nothing declares.
    for af in .claude/agents/*.md; do
      [ -f "$af" ] || continue
      abase="$(basename "$af" .md)"
      case " $DECLARED " in
        *" $abase "*) : ;;
        *) echo "NOTE: .claude/agents/$abase.md exists but CLAUDE.md's toolkit list doesn't mention it — add it to that list" ;;
      esac
    done
  fi
fi

echo
echo "=== CHANGELOG has at least one version entry ==="
if grep -q "^## ver-" CHANGELOG.md 2>/dev/null; then
  CURRENT_VERSION_LINE="$(grep "^## ver-" CHANGELOG.md | head -1 | sed 's/^## //')"
  CURRENT_VERSION="$(echo "$CURRENT_VERSION_LINE" | awk '{print $1}')"
  echo "OK: current version is $CURRENT_VERSION_LINE"
else
  overall_status=1
  echo "MISSING: no '## ver-...' entry found in CHANGELOG.md"
fi

echo
echo "=== Template source vs functional agent copies ==="
# Only meaningful where both locations exist -- i.e. Luna-Core itself, which
# keeps agents/ as template source AND .claude/agents/ as its working copies.
# These two can silently disagree when one is edited and the other isn't, which
# no other check would catch.
if [ "$IS_LUNA_CORE" -eq 1 ] && [ -d "agents" ]; then
  drift=0
  # Three agents deliberately carry this project's own specifics in their
  # functional copy where the template keeps a blank: the research agent's
  # repo path, qa-tester's `## Stack` block, and implementer's Part Two.
  # Those regions are cut out of BOTH sides before comparing, so filling them
  # in is not drift -- while every line outside them is still compared, so a
  # method paragraph edited on one side only is still caught.
  strip_fillins() {
    awk '
      /^# PART TWO/ { exit }
      /^## Stack$/  { skip = 1; next }
      /^## /        { skip = 0 }
      !skip
    ' "$1"
  }
  for t in agents/*.md; do
    [ -f "$t" ] || continue
    base="$(basename "$t")"
    fc=".claude/agents/$base"
    if [ ! -f "$fc" ]; then
      overall_status=1
      echo "MISSING: $base exists as template source but has no functional copy at $fc"
      drift=1
      continue
    fi
    case "$base" in
      *-research.md|*-qa-tester.md|*-implementer.md)
      # Compare by NORMALISING both sides, not by diffing and then filtering the
      # diff. The old filter chain dropped any differing line merely
      # *containing* an expected token, which silently accepted a semantic
      # inversion of a behavioural constraint on a line that happened to name an
      # agent -- measured blind rate, 18.5% of lines. Mapping each fill-in and
      # its filled-in counterpart onto one sentinel instead makes every
      # remaining difference real drift by construction, with no allowlist left
      # to leak through.
      REPO_POSIX="$(pwd)"
      REPO_WIN="$(cygpath -w "$REPO_POSIX" 2>/dev/null || echo "$REPO_POSIX")"
      REPO_FWD="$(printf '%s' "$REPO_WIN" | tr '\\' '/')"
      PROJ="$(basename "$REPO_POSIX")"
      LC_PROJ="$(printf '%s' "$PROJ" | tr '[:upper:]' '[:lower:]')"
      # Both sides get every rule, so text that is genuinely identical stays
      # identical and only substitution differences collapse.
      #
      # Backslashes are converted to forward slashes FIRST, on both sides. An
      # earlier attempt interpolated the Windows path straight into a sed
      # pattern behind an escaper -- and the escaper turned every backslash
      # into "&", so the rule matched nothing and a *different*, weaker rule
      # fired instead. The output looked plausible. Normalising the separator
      # up front means no interpolated pattern ever contains a backslash.
      normalise() {
        sed -e 's|\\|/|g' "$1"          | sed -e "s|<directory>/<projectname>|@@REPO@@|g"                 -e "s|<absolute path to this project's repo>|@@REPO@@|g"                 -e "s|<directory>|@@REPO@@|g"                 -e "s|$REPO_FWD|@@REPO@@|g"                 -e "s|$REPO_POSIX|@@REPO@@|g"                 -e "s|<projectname>|@@PROJ@@|g"                 -e "s|<ProjectName>|@@PROJ@@|g"                 -e "s|$LC_PROJ|@@PROJ@@|g"                 -e "s|$PROJ|@@PROJ@@|g"
      }
      # A fill-in region must exist on BOTH sides. strip_fillins() cuts it from
      # both, so deleting a whole `## Stack` section -- heading included --
      # would otherwise leave the stripped sides identical and report OK: the
      # exemption cannot see the loss of the very thing it exists to permit.
      region_drift=""
      for marker in '^## Stack$' '^# PART TWO'; do
        ca="$(grep -c "$marker" "$t")"; cb="$(grep -c "$marker" "$fc")"
        if [ "$ca" != "$cb" ]; then
          m_disp="${marker#^}"; m_disp="${m_disp%\$}"
          region_drift="${region_drift}        fill-in region '$m_disp' appears $ca time(s) in the template and $cb in the functional copy
"
        fi
      done
      extra="$(diff <(strip_fillins <(normalise "$t")) <(strip_fillins <(normalise "$fc")) | grep -E '^[<>]')"
      if [ -n "$extra" ] || [ -n "$region_drift" ]; then
        # Content drift FAILS the run. A missing functional copy already does,
        # and divergent content is the same class of broken toolkit -- a NOTE
        # that can never fail the run trains people to ignore it.
        overall_status=1
        echo "DRIFT: $base differs from its functional copy beyond its fill-ins -- re-sync it:"
        [ -n "$region_drift" ] && printf '%s' "$region_drift"
        [ -n "$extra" ] && printf '%s
' "$extra" | sed 's/^/        /' | head -6
        drift=1
      fi
      ;;
      *)
      if ! cmp -s "$t" "$fc"; then
        overall_status=1
        echo "DRIFT: $base differs from its functional copy at $fc -- one was edited without the other; re-sync"
        drift=1
      fi
      ;;
    esac
  done
  [ "$drift" -eq 0 ] && echo "OK: every agent template matches its functional copy (the research/qa-tester/implementer fill-ins are expected)"
else
  echo "OK: not applicable -- this project has no agents/ template source, only the functional .claude/agents/ copies it needs"
fi

echo
# How to actually run the entry-point installer FROM HERE. It is deliberately
# not copied into a bootstrapped project (it is machine-level, and resolves the
# clone URL from its own repo's origin), so a child project naming
# "scripts/install-global-entrypoint.sh" was pointing at a file that does not
# exist there -- advice that cannot be followed, in every project bootstrapped
# so far. [2026-09-02] Second instance, same shape: this branch also passed
# a <hub-folder> argument, but the installer was rewritten to take NO arguments
# (it reads the clone URL from its own checkout's origin). Extra arguments are
# ignored, so nothing broke -- it just told the user to supply something that
# does not exist, in every freshly bootstrapped project.
if [ "$IS_LUNA_CORE" -eq 1 ]; then
  ENTRYPOINT_HOWTO="bash scripts/install-global-entrypoint.sh"
else
  ENTRYPOINT_HOWTO="bash <your-Luna-Core-checkout>/scripts/install-global-entrypoint.sh  (not in this project -- it is machine-level)"
fi

echo "=== Agent repo paths (do they point at THIS machine?) ==="
# Agent definitions record an absolute repo path. That is inherently
# machine-specific, so after a machine switch it silently names a directory
# that does not exist here -- which undermines the whole point of the memory
# and handoff roaming. Nothing detected this: a stale path is still a
# perfectly well-formed line. Compare what each agent claims against where
# this checkout actually is.
REPO_POSIX_NOW="$(pwd)"
REPO_WIN_NOW="$(cygpath -w "$REPO_POSIX_NOW" 2>/dev/null || echo "$REPO_POSIX_NOW")"
# Resolve a path to a canonical directory rather than comparing strings. One
# directory has many correct spellings on Windows -- `cygpath -w` returns the
# 8.3 short form (C:\Users\USERNA~1\...) while `pwd -W` returns the long one,
# and both are right. String-matching those reported a correctly filled-in
# path as "from another machine": a wrong-reason failure, from the very check
# added to catch wrong-reason failures. So ask the filesystem instead: if the
# recorded path names a real directory that IS this checkout, it is correct
# however it happens to be spelled.
canon() {
  local p u
  p="$1"
  u="$(cygpath -u "$p" 2>/dev/null)" || u=""
  [ -z "$u" ] && u="$p"
  if [ -d "$u" ]; then ( cd "$u" 2>/dev/null && pwd -P ); else printf ''; fi
}
NOW_CANON="$(canon "$REPO_POSIX_NOW")"
# Fallback for the case where the claimed path does not exist here at all --
# then it genuinely is another machine's, and only the strings can be shown.
norm() {
  printf '%s' "$1" | tr 'A-Z' 'a-z' | tr '\\' '/' | sed 's#/*$##'
}
path_problems=0
for f in .claude/agents/*.md; do
  [ -f "$f" ] || continue
  # Find EVERY absolute-looking backticked path in the file, rather than
  # trusting one sentence. This check first grepped only "The repo lives at",
  # and the implementer agent said "- Repo: ..." instead -- so it silently
  # skipped that file and then reported "every agent points at this checkout"
  # while one still pointed at another machine. A check that is blind to a
  # phrasing is worse than no check, because its OK is believed. Templates are
  # now standardised on one wording too, but this no longer depends on it.
  #
  # Absolute-looking means a drive letter or a leading slash; relative
  # mentions like `.claude/agents/` are not paths to this repo. awk field-split
  # on the backtick, deliberately: a sed backreference here was mangled twice
  # by an intervening escaping layer, so there are no backslashes left to
  # mis-escape.
  for claimed in $(awk -F'`' '{for(i=2;i<=NF;i+=2) if ($i ~ /^[A-Za-z]:/ || $i ~ /^\//) print $i}' "$f" | tr ' ' '\001' | sort -u); do
    claimed="$(printf '%s' "$claimed" | tr '\001' ' ')"
    case "$claimed" in *"<"*) continue ;; esac  # unfilled placeholder: reported above
    c_canon="$(canon "$claimed")"
    if [ -n "$c_canon" ] && [ "$c_canon" = "$NOW_CANON" ]; then
      continue                     # same directory, however it is spelled
    fi
    if [ -n "$NOW_CANON" ] && [ "$(norm "$claimed")" = "$(norm "$REPO_WIN_NOW")" ]; then
      continue                     # string-identical to this checkout
    fi
    overall_status=1
    path_problems=1
    echo "MISSING: $(basename "$f" .md) records this path:"
    echo "           $claimed"
    if [ -z "$c_canon" ]; then
      echo "         which is not a directory on this machine. This checkout is at:"
    else
      echo "         which is a real directory, but NOT this checkout. This checkout is at:"
    fi
    echo "           $REPO_WIN_NOW"
    echo "         Update it in $f -- the agent will otherwise look for files"
    echo "         that aren't there. (Any spelling of the right directory is accepted:"
    echo "         short 8.3 form, long form, forward or back slashes.)"
  done
done
if [ "$path_problems" -eq 0 ]; then
  echo "OK: every agent that records a repo path points at this checkout"
fi

echo
echo "=== This machine's Luna-Core entry point ==="
# Written by scripts/install-global-entrypoint.sh, outside any repo, so nothing
# in git can tell you it's stale. It stamps the version that produced it;
# compare that against this checkout.
ENTRY_MD=""
if [ -f "$SCRIPT_DIR/lib-claude-home.sh" ]; then
  # Use the shared resolver rather than a fourth hand-rolled variant. This one
  # happened to be safe only because it ordered USERPROFILE first, not because
  # it verified the config was live.
  . "$SCRIPT_DIR/lib-claude-home.sh"
  [ -f "$CLAUDE_DIR/CLAUDE.md" ] && ENTRY_MD="$CLAUDE_DIR/CLAUDE.md"
fi
if [ -z "$ENTRY_MD" ]; then
  echo "NOTE: no machine-level entry point found. Run the installer once on this"
  echo "      machine so a session started outside a project knows this toolkit exists:"
  echo "      $ENTRYPOINT_HOWTO"
elif ! grep -q 'luna-core:begin' "$ENTRY_MD"; then
  echo "NOTE: $ENTRY_MD exists but has no Luna-Core pointer block."
  echo "      Add it with: $ENTRYPOINT_HOWTO"
  echo "      (your other content in that file is preserved)"
else
  # Anchored deliberately. The obvious `sed 's/.*luna-core:version //'` is wrong:
  # BRE `.*` is greedy, so a line naming the marker twice yields the text after
  # the LAST occurrence -- reporting a current entry point as stale. grep -o
  # takes the leftmost match, and the prefix strip below is anchored at ^ so it
  # cannot slide past it. Same class as the greedy `.*(` in merge_index().
  STAMPED="$(grep -m1 'luna-core:version' "$ENTRY_MD" | grep -o 'luna-core:version .*' | sed 's/^luna-core:version //; s/ *-->.*//')"
  if [ -z "$STAMPED" ]; then
    echo "NOTE: this machine's entry point predates version stamping -- re-run the installer:"
    echo "      $ENTRYPOINT_HOWTO"
  elif [ "$IS_LUNA_CORE" -eq 0 ]; then
    # Only a Luna-Core checkout can judge whether the stamp is current.
    # CURRENT_VERSION here is THIS project's own version, which is a completely
    # separate track from Luna-Core's toolkit version -- comparing them would
    # mismatch permanently (a fresh project is ver-0.1.0.0-dev while the stamp
    # might say ver-0.6.0.0-dev), and re-running the installer wouldn't change
    # that, so the advice would be useless as well as wrong. Just report it.
    echo "OK: this machine's entry point was written by Luna-Core $STAMPED"
    echo "    (whether that's the latest is only knowable from a Luna-Core checkout,"
    echo "    not from this project -- the two version numbers are unrelated tracks)"
  elif [ -n "${CURRENT_VERSION:-}" ] && [ "$STAMPED" != "$CURRENT_VERSION" ]; then
    echo "NOTE: this machine's entry point was written by $STAMPED, but this Luna-Core"
    echo "      checkout is $CURRENT_VERSION. Re-run it: $ENTRYPOINT_HOWTO"
  else
    echo "OK: this machine's entry point is current ($STAMPED)"
  fi
fi

echo
echo "=== Declared runtime prerequisites (informational -- doesn't affect setup pass/fail) ==="
if [ -f "scripts/check-prerequisites.sh" ]; then
  if ! bash scripts/check-prerequisites.sh; then
    deps_status=1
    echo "(one or more declared prerequisites need attention -- see above; this doesn't mean the file setup itself is broken)"
  fi
else
  echo "SKIPPED: scripts/check-prerequisites.sh not found"
fi

echo
echo "=== Superpowers plugin dependencies (informational -- doesn't affect setup pass/fail) ==="
if [ -f "scripts/check-superpowers.sh" ]; then
  if ! bash scripts/check-superpowers.sh; then
    deps_status=1
    echo "(one or both superpowers dependencies need attention -- see above; this doesn't mean the file setup itself is broken)"
  fi
else
  echo "SKIPPED: scripts/check-superpowers.sh not found"
fi

echo
if [ "$overall_status" -eq 0 ]; then
  # Scope the headline to what this status actually covers. It used to read
  # "this project has everything Luna-Core provides", which could sit
  # directly beneath two MISSING lines from the dependency checks above and
  # still say it -- a reported problem coexisting with a "fine" conclusion.
  # The Wake Up protocol is told not to trust the exit code, but this script is
  # also documented as runnable on its own, and read that way the old banner
  # flatly contradicted its own output.
  echo "=== File setup verified: everything Luna-Core installs into a project is in place ==="
  echo "Agents:   ${FOUND_AGENTS[*]}"
  echo "Commands: /wake-up, /debrief"
  echo "Version:  ${CURRENT_VERSION:-unknown}"
  if [ "$deps_status" -ne 0 ]; then
    echo
    echo "NOT READY TO WORK ON YET: the file setup is correct, but one or more"
    echo "dependencies above are missing or wrong (see the MISSING/MISMATCH/"
    echo "NOT FOUND lines). Those are machine-level, not part of this project's"
    echo "files, which is why they don't change this script's exit code -- but"
    echo "they do have to be resolved before the project is workable. Follow the"
    echo "instructions printed with each one."
  fi
else
  echo "=== Setup INCOMPLETE -- see MISSING/INCOMPLETE/NOT RENAMED items above ==="
fi

exit $overall_status
