#!/bin/sh
# No-JavaScript fallback fetcher: downloads static HTML or a PDF with curl/wget.
# Usage:  sh fetch-basic.sh <url> [out-dir]
# Limitation: does NOT run JavaScript — JS-rendered pages may come back partial.
set -u

url="${1:-}"
out="${2:-references}"
[ -z "$url" ] && { echo "usage: fetch-basic.sh <url> [out-dir]" >&2; exit 1; }

slug=$(printf '%s' "$url" | sed -e 's#^https\{0,1\}://##' -e 's#[^A-Za-z0-9._-]#-#g' | cut -c1-80)
dir="$out/$slug"
mkdir -p "$dir"
today=$(date +%Y-%m-%d)

if command -v curl >/dev/null 2>&1; then GET="curl -fsSL"; HEAD="curl -fsSLI"
elif command -v wget >/dev/null 2>&1; then GET="wget -qO-"; HEAD="wget -qS --spider"
else echo "ERROR: neither curl nor wget is available." >&2; exit 1; fi

# Direct PDF? (url ends .pdf, or the server reports application/pdf)
is_pdf=0
case "$url" in *.pdf|*.PDF) is_pdf=1 ;; esac
if [ "$is_pdf" = "0" ] && command -v curl >/dev/null 2>&1; then
  $HEAD "$url" 2>/dev/null | grep -iq 'content-type:.*application/pdf' && is_pdf=1
fi

if [ "$is_pdf" = "1" ]; then
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$url" -o "$dir/document.pdf"
  else wget -q "$url" -O "$dir/document.pdf"; fi
  echo "saved PDF: $dir/document.pdf"
  body_file="document.pdf"
else
  $GET "$url" > "$dir/page.html" 2>/dev/null || { echo "ERROR: fetch failed for $url" >&2; exit 1; }
  echo "saved HTML: $dir/page.html"
  echo "NOTE: JavaScript was NOT executed — review page.html for completeness."
  body_file="page.html"
fi

cat > "$dir/meta.json" <<EOF
{
  "url": "$url",
  "retrieved": "$today",
  "method": "fetch-basic (no JavaScript)",
  "file": "$body_file"
}
EOF
echo "saved meta: $dir/meta.json   (retrieved $today)"
