#!/bin/sh
# Probe the host for runtimes the reference-harvester can use.
# Pure POSIX sh — needs nothing installed. Prints a human + AI readable report.
set -u

have() { command -v "$1" >/dev/null 2>&1; }
mark() { if [ "$1" = "1" ]; then printf '  [ yes ] %s\n' "$2"; else printf '  [  no ] %s\n' "$2"; fi; }

py=0; pyplay=0; node=0; nodeplay=0; ps=0; edge=0; chrome=0; curlw=0

if have python3; then PY=python3; py=1; elif have python; then PY=python; py=1; fi
if [ "$py" = "1" ]; then
  "$PY" -c "import playwright" >/dev/null 2>&1 && pyplay=1
fi
if have node; then
  node=1
  node -e "require.resolve('playwright')" >/dev/null 2>&1 && nodeplay=1
  [ "$nodeplay" = "0" ] && { node -e "require.resolve('puppeteer')" >/dev/null 2>&1 && nodeplay=1; }
fi
if have pwsh || have powershell; then ps=1; fi
if have msedge || [ -x "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" ]; then edge=1; fi

# Chrome / Chromium detection — check CLI commands AND macOS app bundle paths
if have google-chrome || have chromium || have chrome; then
  chrome=1
elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  chrome=1
elif [ -x "$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  chrome=1
elif [ -x "/Applications/Chromium.app/Contents/MacOS/Chromium" ]; then
  chrome=1
fi
if have curl || have wget; then curlw=1; fi

echo "reference-harvester — runtime probe"
echo "-----------------------------------"
mark "$py"       "Python 3"
mark "$pyplay"   "  + Playwright (python -m pip install playwright)"
mark "$node"     "Node.js"
mark "$nodeplay" "  + Playwright or Puppeteer"
mark "$ps"       "PowerShell"
mark "$edge"     "Microsoft Edge (headless-capable)"
mark "$chrome"   "Chrome / Chromium"
mark "$curlw"    "curl or wget"
echo "-----------------------------------"

if   [ "$pyplay"   = "1" ]; then echo "RECOMMENDED PATH: scripts/harvest.py   (Python + Playwright)"
elif [ "$nodeplay" = "1" ]; then echo "RECOMMENDED PATH: scripts/harvest.mjs  (Node.js headless browser)"
elif [ "$ps" = "1" ] && [ "$edge" = "1" ]; then
     echo "RECOMMENDED PATH: scripts/harvest.ps1  (PowerShell + headless Edge)"
elif [ "$chrome" = "1" ]; then
     echo "RECOMMENDED PATH: scripts/harvest-chrome.sh  (headless Chrome --dump-dom)"
elif [ "$curlw" = "1" ]; then
     echo "RECOMMENDED PATH: scripts/fetch-basic.sh  (no JavaScript rendering)"
     echo "NOTE: JS-rendered pages may be incomplete. See README.md to add a headless browser."
else
     echo "NO USABLE PATH FOUND. Install one of the options in README.md."
fi
