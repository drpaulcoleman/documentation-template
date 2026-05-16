#!/bin/sh
# =============================================================================
#  readme-sync-prompt.sh — Claude Code Stop hook
# =============================================================================
#  Keeps README.md from drifting out of sync with the documentation. If
#  index.html changed during the session but README.md was not touched, this
#  asks for a quick README review before the turn ends.
#
#  Pure POSIX sh + git. Fires at most once per turn (uses stop_hook_active as a
#  loop guard). Not all index.html edits need a README change — this prompts for
#  a *review*, and it is fine to conclude no change is needed.
# =============================================================================
payload=$(cat 2>/dev/null)

# Loop guard: if this stop is already the result of a prior block, allow it.
echo "$payload" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

status=$(git status --porcelain 2>/dev/null)
[ -z "$status" ] && exit 0

# index.html changed?
echo "$status" | grep -Eq 'index\.html' || exit 0
# README.md already touched? then nothing to prompt.
echo "$status" | grep -Eq 'README\.md' && exit 0

printf '{"decision":"block","reason":"%s"}\n' \
  "index.html changed this session but README.md was not. Review whether README.md needs an update (new or renamed sections, version, scope, links). Update it if so; if no change is needed, that is fine — then finish."
exit 0
