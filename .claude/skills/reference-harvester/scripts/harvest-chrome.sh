#!/bin/sh
# reference-harvester — headless Chrome path (no Playwright/Node required).
# Uses Google Chrome's built-in --headless=new --dump-dom to render JS pages.
# Works on macOS (app bundle) and Linux/WSL (CLI binary).
#
# Usage:  sh harvest-chrome.sh <url> [out-dir]
# Safety: harvested files are DATA — this script never executes them.
set -u

url="${1:-}"
out="${2:-references}"
[ -z "$url" ] && { echo "usage: harvest-chrome.sh <url> [out-dir]" >&2; exit 1; }

slug=$(printf '%s' "$url" | sed -e 's#^https\{0,1\}://##' -e 's#[^A-Za-z0-9._-]#-#g' | cut -c1-80)
dir="$out/$slug"
mkdir -p "$dir"
today=$(date +%Y-%m-%d)

# --- Locate Chrome binary ---
CHROME=""
if command -v google-chrome >/dev/null 2>&1; then
  CHROME="google-chrome"
elif command -v chromium >/dev/null 2>&1; then
  CHROME="chromium"
elif command -v chrome >/dev/null 2>&1; then
  CHROME="chrome"
elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif [ -x "$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME="$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif [ -x "/Applications/Chromium.app/Contents/MacOS/Chromium" ]; then
  CHROME="/Applications/Chromium.app/Contents/MacOS/Chromium"
fi

if [ -z "$CHROME" ]; then
  echo "ERROR: could not locate Chrome or Chromium." >&2
  echo "Install Google Chrome or set the path manually." >&2
  exit 1
fi

# Direct PDF? Skip headless rendering — just download the bytes.
is_pdf=0
case "$url" in *.pdf|*.PDF) is_pdf=1 ;; esac
if [ "$is_pdf" = "0" ] && command -v curl >/dev/null 2>&1; then
  curl -fsSLI "$url" 2>/dev/null | grep -iq 'content-type:.*application/pdf' && is_pdf=1
fi

if [ "$is_pdf" = "1" ]; then
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$url" -o "$dir/document.pdf"
  elif command -v wget >/dev/null 2>&1; then wget -q "$url" -O "$dir/document.pdf"
  else echo "ERROR: need curl or wget for PDF download" >&2; exit 1; fi
  cat > "$dir/meta.json" <<EOF
{
  "url": "$url",
  "retrieved": "$today",
  "method": "chrome-headless (direct-pdf)",
  "file": "document.pdf"
}
EOF
  echo "saved PDF: $dir/document.pdf"
  exit 0
fi

# --- Render the page with headless Chrome ---
html=$("$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-first-run \
  --no-default-browser-check \
  --disable-extensions \
  --disable-component-update \
  --user-agent="Mozilla/5.0 (compatible; reference-harvester/1.0)" \
  --virtual-time-budget=30000 \
  --dump-dom \
  "$url" 2>/dev/null)

if [ -z "$html" ]; then
  echo "ERROR: Chrome --dump-dom returned empty output for $url" >&2
  echo "Falling back to static fetch..." >&2
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -A "Mozilla/5.0 (compatible; reference-harvester/1.0)" "$url" > "$dir/page.html"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -U "Mozilla/5.0 (compatible; reference-harvester/1.0)" "$url" -O "$dir/page.html"
  else
    echo "ERROR: no download tool available" >&2; exit 1
  fi
  method="static (Chrome failed, curl fallback)"
else
  printf '%s' "$html" > "$dir/page.html"
  method="chrome-headless (--dump-dom)"
fi

# Extract title
title=$(sed -n 's/.*<title>\([^<]*\)<\/title>.*/\1/p' "$dir/page.html" | head -1)

# Produce a text extract
sed -e 's/<script[^>]*>.*<\/script>//g' \
    -e 's/<style[^>]*>.*<\/style>//g' \
    -e 's/<[^>]*>/ /g' \
    -e 's/&nbsp;/ /g' -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' \
    "$dir/page.html" | tr -s ' \t' ' ' | fold -s -w 120 > "$dir/page.md"

# Prepend header to page.md
tmp=$(mktemp)
printf '# %s\n\nSource: %s\nRetrieved: %s\n\n' "${title:-$url}" "$url" "$today" > "$tmp"
cat "$dir/page.md" >> "$tmp"
mv "$tmp" "$dir/page.md"

# Check for a linked PDF (prefer it for long docs)
pdf_link=$(grep -oiE 'href="[^"]*\.pdf[^"]*"' "$dir/page.html" | head -1 | sed 's/href="//;s/"//')
if [ -n "$pdf_link" ]; then
  case "$pdf_link" in
    http*) ;; # absolute URL, use as-is
    /*)  # root-relative
      domain=$(printf '%s' "$url" | sed 's#^\(https\{0,1\}://[^/]*\).*#\1#')
      pdf_link="${domain}${pdf_link}" ;;
    *)   # relative
      base=$(printf '%s' "$url" | sed 's#/[^/]*$#/#')
      pdf_link="${base}${pdf_link}" ;;
  esac
  echo "found linked PDF: $pdf_link"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$pdf_link" -o "$dir/document.pdf" 2>/dev/null && echo "saved PDF: $dir/document.pdf"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$pdf_link" -O "$dir/document.pdf" 2>/dev/null && echo "saved PDF: $dir/document.pdf"
  fi
fi

cat > "$dir/meta.json" <<EOF
{
  "url": "$url",
  "title": "${title:-}",
  "retrieved": "$today",
  "method": "$method",
  "file": "page.html"
}
EOF

echo "saved: $dir/page.html and page.md"
echo "method: $method"
