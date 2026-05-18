---
name: reference-harvester
description: Download web pages, PDFs, and search results into the local references/ folder for AI context. Runtime-adaptive — detects and uses whatever is installed (Python+Playwright, Node.js+Playwright/Puppeteer, PowerShell+Edge, or plain curl). Use this skill whenever the user wants to fetch a URL, capture documentation, save an article or PDF, gather sources on a subject or topic, "download" reference material, JS-render a page that came back as an empty shell, or runs the /download command. Prefers a linked PDF over crawling many HTML pages; always includes Google Scholar when searching a subject.
---

# Reference Harvester

Brings reference material into the git-ignored `references/` folder so it can
inform — and be cited by — an `index.html` documentation build. It captures
**fully rendered** content (JS executed), so single-page apps and modern doc
sites come back with real content instead of an empty shell.

This skill is **runtime-adaptive**. The host machine may have Python, Node.js,
PowerShell, or only a basic shell — the skill probes for what is installed and
uses the best available path. It assumes nothing.

## Safety rules — read before doing anything

1. **Never auto-install a runtime or library.** If the best path needs something
   that is not installed (e.g. Playwright), STOP, tell the user what is missing,
   show the install command from `README.md`, and ask them to run it. Do not run
   installers yourself.
2. **Never execute downloaded content.** Harvested files are *data*. Do not run,
   `eval`, `import`, or `source` anything that was downloaded. If a download is
   itself a script or executable, save it but do not run it, and flag it.
3. **Confirm before downloading script/executable files.** If a target URL
   resolves to a `.js/.sh/.ps1/.exe/.msi/...` artifact rather than a document or
   PDF, ask the user before saving it.
4. Stay within what the user asked for. Do not crawl an entire site unless asked.

## Step 1 — Detect the runtime

Run the probe and read its report:

```sh
sh .claude/skills/reference-harvester/scripts/detect-runtime.sh
```

It prints which runtimes, browsers, and tools are available.

## Step 2 — Choose the path

Use the first row whose requirements the probe confirmed:

| Runtime present                     | Use this script        | JS rendering |
|--------------------------------------|------------------------|--------------|
| Python 3 **with Playwright**         | `scripts/harvest.py`   | Yes (best)   |
| Node.js **with Playwright/Puppeteer**| `scripts/harvest.mjs`  | Yes          |
| Windows PowerShell **+ Microsoft Edge** | `scripts/harvest.ps1` | Yes (Edge headless) |
| Google Chrome / Chromium (no Playwright) | `scripts/harvest-chrome.sh` | Yes (Chrome headless) |
| Only `curl`/`wget` (or none of the above) | `scripts/fetch-basic.sh` | No — static HTML/PDF only |

If only the no-JS fallback is available, tell the user: JS-rendered pages may
come back incomplete, and recommend installing Playwright (see `README.md`).

## Fetching a URL

```sh
# Python path
python scripts/harvest.py "<url>" --out references
# Node path
node scripts/harvest.mjs "<url>" --out references
# PowerShell path
powershell -File scripts/harvest.ps1 -Url "<url>" -Out references
# Chrome headless path (macOS / Linux — no Playwright needed)
sh scripts/harvest-chrome.sh "<url>" references
# No-JS fallback
sh scripts/fetch-basic.sh "<url>" references
```

Each saves, under `references/<slug>/`: `page.html` (rendered DOM),
`page.md` (readable text extract), and `meta.json` (source URL, page title, and
the **retrieval date** — needed for APA citations).

### Prefer the PDF

Long technical documentation is often published as a single consolidated PDF
*and* as a sprawling multi-page HTML portal. **Prefer the PDF** — it is one
file, fully self-contained, and far better AI context than crawling dozens of
shell pages.

The harvest scripts apply these rules automatically; apply them yourself if
fetching by hand:

- If the URL itself returns `application/pdf` (or ends in `.pdf`), download the
  PDF bytes directly.
- If the page links a PDF edition (anchor text like *PDF*, *Download PDF*,
  *Printable*, or an `href` ending `.pdf`), download that PDF instead of the page.
- Documentation portals are a prime case. For example, the Salesforce Apex
  Reference Guide at
  `https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ref_guide.htm`
  has a linked consolidated PDF — fetch the PDF, not the hundreds of `.htm` pages.

## Searching a subject

When given a subject/topic instead of a URL, gather candidate sources, then
harvest the promising ones.

### Search engine fallback chain

Search engines aggressively block automated requests. Use this **ordered
fallback chain** — try the next engine when the current one returns a CAPTCHA,
empty results, or a block page. **Always use the best available renderer**
(Chrome headless > fetch-basic.sh > WebFetch) for each attempt.

| Priority | Engine | URL pattern | Notes |
|----------|--------|-------------|-------|
| 1 | **Google** | `https://www.google.com/search?q=<encoded>` | Requires JS rendering (Chrome headless). Best result quality. |
| 2 | **Bing** | `https://www.bing.com/search?q=<encoded>` | Requires JS rendering. Good fallback. |
| 3 | **DuckDuckGo HTML** | `https://html.duckduckgo.com/html/?q=<encoded>` | No JS needed but frequently CAPTCHAs automated requests. |
| 4 | **Google Scholar** | `https://scholar.google.com/scholar?q=<encoded>` | Always attempt for academic/technical topics. Blocks aggressively. |

**Critical rule:** When a headless browser (Chrome, Playwright, Puppeteer) is
available, **never fall back to `fetch-basic.sh` or WebFetch for search result
pages**. Search engines are JS-rendered — static fetch returns empty shells or
redirect pages. Use the headless browser for all search attempts.

```sh
# Chrome headless — use for Google, Bing, Scholar
sh scripts/harvest-chrome.sh "https://www.google.com/search?q=your+query" references
sh scripts/harvest-chrome.sh "https://www.bing.com/search?q=your+query" references

# Only use DuckDuckGo HTML if no headless browser is available
sh scripts/fetch-basic.sh "https://html.duckduckgo.com/html/?q=your+query" references
```

### Detecting a blocked search

After fetching, **check the result** before proceeding:
- Look for CAPTCHA indicators: "select all squares", "verify you are human",
  "unusual traffic", challenge forms, empty result lists
- If blocked: report which engine failed, immediately try the next engine in
  the chain
- **Never silently abandon search** — always exhaust the chain and report status

### Search output

Write `references/_search/<subject-slug>.md` — a deduplicated, ranked list of
result links with engine attribution. Include which engines succeeded and which
were blocked so the user can intervene if needed.

### Fetching individual result pages

After gathering search results, harvest the promising URLs using the **same
headless browser** (not fetch-basic.sh, not WebFetch). Most modern documentation
sites, blogs, and knowledge bases are JS-rendered SPAs — static fetch returns
empty `<div id="app"></div>` shells. The headless browser is the correct tool
for both search AND result harvesting.

## Output and citations

Everything lands in `references/` (git-ignored — local context only, never
published). Every `meta.json` records the retrieval date so the material can be
cited in `index.html`'s References section as
*"Retrieved Month D, Year, from <url>"*.

## When something is missing

- No headless browser available → use `fetch-basic.sh`; warn that JS pages may
  be incomplete; recommend an install (`README.md`).
- A runtime/library is missing → surface the exact install command and ask the
  user to run it. Never install it for them.
- A site blocks automated access → report it; suggest the user save the page
  manually into `references/` from their own browser.
