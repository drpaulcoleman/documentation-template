---
description: |-
  Download reference material into the local references/ folder for AI context.
  Accepts one or more URLs, or a subject/topic to search for. Renders JavaScript
  so modern doc sites come back complete, prefers a linked PDF over crawling many
  HTML pages, and (for subjects) searches DuckDuckGo / Google / Yahoo and always
  Google Scholar. Use before or during an index.html build to gather sources.
argument-hint: [url(s) | subject to search]
allowed-tools: ["Bash", "Read", "Write", "Glob", "Skill", "AskUserQuestion"]
---

# /download — harvest reference material

Bring reference material into `references/` (git-ignored, local-only) so it can
inform and be cited by the `index.html` build.

Arguments: `$ARGUMENTS`

## Step 1 — Use the reference-harvester skill

Invoke the **reference-harvester** skill. It is runtime-adaptive — follow its
`SKILL.md`: first run `detect-runtime.sh`, then pick the matching harvest script.
Do **not** install runtimes or libraries automatically; if a better path needs
something, tell the user and show the install command from the skill's README.

## Step 2 — Decide: URL(s) or a subject?

- **`$ARGUMENTS` contains one or more URLs** → harvest each one. For each URL,
  apply the PDF-preference rule: if the URL is a PDF, or the page links a
  consolidated PDF edition (common on documentation portals such as
  `developer.salesforce.com/docs/atlas...`), download the **PDF** rather than
  crawling the HTML pages.

- **`$ARGUMENTS` is a subject/topic** (no URL) → run a search first:
  `harvest.py --search "<subject>"`. This queries DuckDuckGo and records the
  Google, Yahoo, and **Google Scholar** query links. Always include Google
  Scholar. Open the resulting `_search/*.md`, show the user the candidate
  links, and ask which to harvest before downloading them.

- **`$ARGUMENTS` is empty** → ask the user for a URL or a subject.

## Step 3 — Confirm and report

- If a target resolves to a script or executable file (not a document/PDF), ask
  the user before saving it. Never execute downloaded content.
- After harvesting, report what landed in `references/`: each item's folder,
  whether HTML or PDF was saved, and the retrieval date (captured in `meta.json`
  for later APA citation).
- If a search engine or site blocked automated access, say so plainly and
  suggest the user save the page from their own browser into `references/`.

## Step 4 — Note for citations

Remind the user: material in `references/` is for context and citation, not
copying. When its content is used in `index.html`, it must be cited in the
References section with a "Retrieved [date]" marker.
