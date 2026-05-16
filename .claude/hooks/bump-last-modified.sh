#!/bin/sh
# =============================================================================
#  bump-last-modified.sh — Claude Code PostToolUse hook
# =============================================================================
#  When index.html is edited, bumps its "last modified" date to today in all
#  the places that carry it: the <meta> tag, the JSON-LD dateModified, the
#  ai-content-map lastModified, and the visible hero metadata row.
#
#  Pure POSIX sh + sed — no runtime dependency. Exits 0 silently on any
#  non-match so it never blocks the tool flow.
# =============================================================================
payload=$(cat 2>/dev/null)

# Only act when an Edit/Write/MultiEdit targeted a file named index.html.
echo "$payload" | grep -Eq '"file_path"[[:space:]]*:[[:space:]]*"[^"]*index\.html"' || exit 0

f="${CLAUDE_PROJECT_DIR:-.}/index.html"
[ -f "$f" ] || exit 0

today=$(date +%Y-%m-%d)
tmp="$f.bump.$$"

sed -E \
  -e "s@(<meta name=\"last-modified\" content=\")[0-9]{4}-[0-9]{2}-[0-9]{2}(\")@\1${today}\2@" \
  -e "s@(\"dateModified\": \")[0-9]{4}-[0-9]{2}-[0-9]{2}(\")@\1${today}\2@" \
  -e "s@(\"lastModified\": \")[0-9]{4}-[0-9]{2}-[0-9]{2}(\")@\1${today}\2@" \
  -e "s@(Last modified: <b>)[0-9]{4}-[0-9]{2}-[0-9]{2}(</b>)@\1${today}\2@" \
  "$f" > "$tmp" 2>/dev/null && cp "$tmp" "$f"
rm -f "$tmp" 2>/dev/null
exit 0
