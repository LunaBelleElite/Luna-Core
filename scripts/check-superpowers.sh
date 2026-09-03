#!/usr/bin/env bash
# Checks whether both superpowers-based Claude Code dependencies are
# INSTALLED and FUNCTIONING:
#   1. superpowers-extended-cc (pcvelz/superpowers marketplace plugin)
#   2. Claude Code on Steroids (GadaaLabs skill pack + /tokenburn command)
# Run this once after cloning Luna-Core into a new project, before relying
# on any agent/skill that assumes either is available.
#
# Usage: bash scripts/check-superpowers.sh

QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/lib-claude-home.sh" ]; then
  # Fail loudly. Falling back to a naive $HOME here would reintroduce exactly
  # the wrong-reason failure this library exists to prevent: reporting both
  # dependencies as missing when they are installed, just not where we looked.
  echo "ERROR: $SCRIPT_DIR/lib-claude-home.sh is missing -- cannot reliably locate"
  echo "       this machine's Claude config, and guessing would produce a false"
  echo "       'MISSING' verdict. Restore it from Luna-Core's scripts/ folder."
  exit 1
fi
# shellcheck source=lib-claude-home.sh
. "$SCRIPT_DIR/lib-claude-home.sh"

SETTINGS="$CLAUDE_DIR/settings.json"
MARKETPLACE_KEY="superpowers-extended-cc-marketplace"
PLUGIN_KEY="superpowers-extended-cc@superpowers-extended-cc-marketplace"
PLUGIN_ROOT="$CLAUDE_DIR/plugins/cache/superpowers-extended-cc-marketplace/superpowers-extended-cc"
ON_STEROIDS_MARKER="$CLAUDE_DIR/skills/chronicle/SKILL.md"
TOKENBURN_SCRIPT="$CLAUDE_DIR/scripts/tokenburn.py"

overall_status=0

print_superpowers_install_instructions() {
  echo
  echo "To install it, run these commands inside an interactive 'claude' session:"
  echo
  echo "  /plugin marketplace add pcvelz/superpowers"
  echo "  /plugin install ${PLUGIN_KEY}"
  echo
  echo "Then enable auto-update so it stays current across every project/session:"
  echo '  Open /plugin -> Marketplaces tab -> enable automatic updates'
  echo "  (or add \"autoUpdate\": true to the marketplace entry in"
  echo "   ~/.claude/settings.json under extraKnownMarketplaces.${MARKETPLACE_KEY})"
  echo
  echo "Then run onboarding:"
  echo "  /superpowers-extended-cc:onboard"
  echo
  echo "Also required for Claude Code 2.1.233+: add this to ~/.claude/settings.json:"
  echo '  { "env": { "CLAUDE_CODE_ENABLE_TODO_TOOLS": "1" } }'
}

print_on_steroids_install_instructions() {
  echo
  echo "This is a shell installer that downloads and runs code from GitHub —"
  echo "an AI assistant should not run this for you. Run it yourself, in your"
  echo "own terminal:"
  echo
  echo "  curl -fsSL https://raw.githubusercontent.com/GadaaLabs/claude-code-on-steroids/main/install.sh | bash"
  echo
  echo "Requirements: Claude Code CLI, and Node.js 20+ (used to try to build the"
  echo "/tokenburn CLI — if that build fails, the installer falls back to a"
  echo "standalone Python script at ~/.claude/scripts/tokenburn.py, which needs"
  echo "Python's 'py' launcher on Windows to run correctly)."
  echo
  echo "This installs into ~/.claude/skills/ (24 renamed skills: arbiter,"
  echo "architect, ascend, blueprint, chronicle, commander, exodus, forge,"
  echo "gradient, horizon, hunter, ironcore, legion, nexus, oracle, pathfinder,"
  echo "phantom, prism, sculptor, seal, sentinel, tribunal, vault, vector) and"
  echo "adds the /tokenburn command. It does not touch the superpowers-extended-cc"
  echo "plugin directory — the two coexist without file conflicts, though several"
  echo "skills overlap in purpose under different names (e.g. architect vs."
  echo "brainstorming, forge vs. test-driven-development)."
}

echo "=== Checking superpowers-extended-cc (pcvelz/superpowers) ==="
registered=0
if [ -f "$SETTINGS" ] && grep -q "$MARKETPLACE_KEY" "$SETTINGS" 2>/dev/null; then
  registered=1
fi

sample_skill="$(find "$PLUGIN_ROOT" -maxdepth 6 -iname "SKILL.md" -ipath "*brainstorming*" 2>/dev/null | head -1)"
functioning=0
if [ -n "$sample_skill" ] && [ -s "$sample_skill" ]; then
  functioning=1
fi

if [ "$registered" -eq 1 ] && [ "$functioning" -eq 1 ]; then
  echo "OK: registered in $SETTINGS, and skill content is present on disk"
  echo "  ($sample_skill)."
  echo "If skills prefixed 'superpowers-extended-cc:' aren't showing up in your"
  echo "current session, restart Claude Code to pick up the plugin."
else
  overall_status=1
  if [ "$registered" -eq 0 ]; then
    echo "MISSING: superpowers-extended-cc is NOT registered in Claude Code settings."
  else
    echo "BROKEN: registered in settings, but no skill content was found under"
    echo "  $PLUGIN_ROOT"
    echo "  (the plugin may not have finished downloading/caching — try"
    echo "  '/plugin update ${PLUGIN_KEY}' first, or reinstall)."
  fi
  print_superpowers_install_instructions
fi

echo
echo "=== Checking Claude Code on Steroids (GadaaLabs) ==="
if [ ! -f "$ON_STEROIDS_MARKER" ] || [ ! -s "$ON_STEROIDS_MARKER" ]; then
  overall_status=1
  echo "MISSING: Claude Code on Steroids is NOT installed (no skill content found"
  echo "  at $ON_STEROIDS_MARKER)."
  print_on_steroids_install_instructions
else
  echo "OK: skill content found at $CLAUDE_DIR/skills/."
  echo
  if [ "$QUICK" -eq 1 ]; then
    # --quick: presence only. The Wake Up protocol's quick-check path runs on
    # every wake on a familiar machine, and it is supposed to stay cheap, so it
    # must not spawn Python. Presence is enough to catch the thing that
    # actually happens -- a plugin uninstalled, or wiped by a Claude Code
    # update -- without paying for a functional test each time. The full sweep
    # still runs the real one.
    if [ -f "$TOKENBURN_SCRIPT" ]; then
      echo "OK: tokenburn.py is present (--quick: not executed)."
    else
      overall_status=1
      echo "BROKEN: skills are installed but the tokenburn fallback script is"
      echo "  missing at $TOKENBURN_SCRIPT — /tokenburn will not work."
      echo "  Re-run the installer to repair it:"
      print_on_steroids_install_instructions
    fi
  elif [ -f "$TOKENBURN_SCRIPT" ]; then
    echo "Functional check: running the /tokenburn fallback script..."
    # Redirect to a real temp file, not /dev/null — on this Windows/MSYS setup,
    # /dev/null confuses this script's terminal-detection (it crashes inside
    # curses.wrapper), even though it runs fine with output going anywhere else.
    tb_out="$(mktemp)"
    if PYTHONIOENCODING=utf-8 py "$TOKENBURN_SCRIPT" today >"$tb_out" 2>&1; then
      echo "OK: tokenburn.py ran successfully (exit 0)."
    else
      overall_status=1
      echo "BROKEN: tokenburn.py exists but failed to run. Output:"
      sed 's/^/    /' "$tb_out"
      echo "  Common cause on Windows: the 'py' launcher isn't installed/on PATH,"
      echo "  or Python isn't 3.x. Verify with: py --version"
    fi
    rm -f "$tb_out"
  else
    overall_status=1
    echo "BROKEN: skills are installed but the tokenburn fallback script is"
    echo "  missing at $TOKENBURN_SCRIPT — /tokenburn will not work."
    echo "  Re-run the installer to repair it:"
    print_on_steroids_install_instructions
  fi
  echo
  echo "If skills like 'chronicle' or 'architect' aren't showing up in your"
  echo "current session, restart Claude Code to pick them up."
fi

echo
if [ "$overall_status" -eq 0 ]; then
  echo "All superpowers dependencies are installed and functioning."
else
  echo "One or more superpowers dependencies need attention — see above."
fi

exit $overall_status
