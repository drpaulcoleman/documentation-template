#!/bin/sh
# =============================================================================
#  commit-guard.sh — Claude Code PreToolUse(Bash) guard
# =============================================================================
#  Stops an AI assistant from bypassing the pre-commit security gate.
#  Registered in .claude/settings.json on the PreToolUse event for Bash.
#
#  Reads the hook payload (JSON) on stdin. Exits 2 to BLOCK the tool call
#  (Claude Code shows the stderr message); exits 0 to allow.
#
#  A human can still override deliberately with `git commit --no-verify` from
#  their own terminal — this guard only constrains the AI assistant.
# =============================================================================
payload=$(cat 2>/dev/null)

block() {
  printf '%s\n' "$1" >&2
  exit 2
}

# --no-verify / -n on a git commit or push  ->  skips the pre-commit gate.
if printf '%s' "$payload" | grep -Eq 'git[^|;&]*\b(commit|push)\b[^|;&]*(--no-verify|[[:space:]]-n([[:space:]]|"|$))'; then
  block "BLOCKED: do not bypass the security commit gate with --no-verify / -n.
Fix what the pre-commit hook reported instead. If a human has reviewed the
finding and is certain it is safe, the human can override from their own
terminal — the AI assistant may not."
fi

# Re-pointing core.hooksPath would disable the gate entirely.
if printf '%s' "$payload" | grep -Eq 'core\.hooksPath|hooksPath[[:space:]]*='; then
  block "BLOCKED: changing git's hooksPath would disable the security commit gate.
The gate must stay enabled at '.githooks'."
fi

# Disabling the gate by deleting or emptying the hook is also off-limits.
if printf '%s' "$payload" | grep -Eq '(rm|del|Remove-Item)[^|;&]*\.githooks'; then
  block "BLOCKED: do not delete or modify the .githooks security gate."
fi

exit 0
