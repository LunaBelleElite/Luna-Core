#!/usr/bin/env bash
# Shared resolver for "where does this machine's live Claude Code config
# actually live?" -- sourced, not executed.
#
# Sets CLAUDE_DIR (the config directory itself) and HOME_DIR (the directory
# holding it, kept for messages). Every script here that touches Claude's
# config must use CLAUDE_DIR rather than rolling its own, because getting it
# wrong produces a WRONG-REASON failure: the script reports the thing it was
# looking for as missing, when really it looked in the wrong place. That reads
# as "reinstall the plugin" instead of "your HOME detection picked the wrong
# directory."
#
# CLAUDE_CONFIG_DIR wins when set, and is checked first. Claude Code itself
# honours that variable, so a machine that sets it has its live config there
# and nowhere else -- and, critically, that directory IS the config dir, not a
# home directory containing a .claude folder. Probing $USERPROFILE/$HOME on
# such a machine finds either nothing or a stale lookalike: exactly the
# wrong-reason failure this file exists to prevent.
#
# The gotcha: on Windows, $HOME is frequently a mapped network drive (on this
# author's machine it is Y:\) while the real config sits under $USERPROFILE.
# Anything that drops even an empty .claude folder on that mapped drive will
# capture a naive $HOME-first check.
#
# So: prefer whichever candidate holds .claude/projects -- that subdirectory is
# what proves it's the live config rather than a stray lookalike. Fall back to
# bare .claude existence only if neither has projects/, and to $HOME only if
# neither has anything.
#
# This lives in one file because the identical nine lines had already been
# written twice and the third script that needed them most -- the one whose
# entire job is detecting installed plugins -- never got them. See CLAUDE.md,
# "A referenced folder must be created, with a keeper file", for the general
# form of that mistake.

resolve_claude_home() {
  local cand conf
  HOME_DIR=""
  CLAUDE_DIR=""
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    conf="$CLAUDE_CONFIG_DIR"
    # A Windows-style path (C:\Claude) needs converting for shells that can't
    # stat it directly; cygpath is absent on non-Windows, where no conversion
    # is needed anyway.
    if command -v cygpath >/dev/null 2>&1; then
      conf="$(cygpath -u "$CLAUDE_CONFIG_DIR" 2>/dev/null || printf '%s' "$CLAUDE_CONFIG_DIR")"
    fi
    CLAUDE_DIR="$conf"
    HOME_DIR="$(dirname "$conf")"
    return 0
  fi
  for cand in "${USERPROFILE:-}" "$HOME"; do
    [ -z "$cand" ] && continue
    if [ -d "$cand/.claude/projects" ]; then HOME_DIR="$cand"; CLAUDE_DIR="$cand/.claude"; return 0; fi
  done
  for cand in "${USERPROFILE:-}" "$HOME"; do
    [ -z "$cand" ] && continue
    if [ -d "$cand/.claude" ]; then HOME_DIR="$cand"; CLAUDE_DIR="$cand/.claude"; return 0; fi
  done
  HOME_DIR="$HOME"
  CLAUDE_DIR="$HOME/.claude"
}

resolve_claude_home
