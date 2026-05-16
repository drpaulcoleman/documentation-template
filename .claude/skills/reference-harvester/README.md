# reference-harvester — setup & runtime notes

This skill harvests reference material (web pages, PDFs, search results) into
the local `references/` folder. It is **runtime-adaptive**: it works with
whatever you already have installed and never installs anything itself.

## The template ships no runtime

Nothing here needs to be installed for the template to *work*. The skill probes
your machine and uses the best path available, degrading to a basic `curl`
fetch if nothing else is present. The recommendations below are **optional** —
they improve quality (real JavaScript rendering), they are not requirements.

You run any install command yourself. The skill will never run an installer for
you; if a better path needs something, it tells you and stops.

## Capability by runtime

| You have… | Capability | JS-rendered pages |
|-----------|------------|-------------------|
| Python 3 + Playwright | Best — full headless Chromium | Yes |
| Node.js + Playwright/Puppeteer | Full headless Chromium | Yes |
| Windows PowerShell + Microsoft Edge | Headless Edge (Edge ships with Windows 11) | Yes |
| Only `curl` / `wget` | Static HTML + direct PDF download only | No |

## Optional install recommendations

Pick **one** path. The first gives the best results.

### Python + Playwright (recommended)

```sh
# 1. Install Python 3 from https://www.python.org/downloads/ if you don't have it.
# 2. Then:
python -m pip install playwright
python -m playwright install chromium
```

### Node.js + Playwright

```sh
# Install Node.js from https://nodejs.org/ if you don't have it. Then, in this repo:
npm install playwright
npx playwright install chromium
```

### Windows: nothing to install

Windows 11 already includes Microsoft Edge and PowerShell. The PowerShell path
(`scripts/harvest.ps1`) runs Edge in headless mode — no install needed.

## Verifying

```sh
sh .claude/skills/reference-harvester/scripts/detect-runtime.sh
```

This prints exactly what was detected and which harvest path will be used.

## Security

- Harvested files are treated as **data only** — never executed.
- Output goes to `references/`, which is git-ignored, so reference material is
  never accidentally published.
- The skill asks before saving any file that is itself a script or executable.
