---
description: |-
  Plan a documentation project from scratch. On a fresh clone, sets up the
  project (layout, metadata, git hooks, README) then researches the subject and
  produces an approved content outline saved to references/CONTENT-PLAN.md.
  On an already-initialised project, skips setup and goes straight to
  re-planning — useful when restructuring or adding major new sections.
  Run /write after this to generate the actual content.
argument-hint: [subject of the documentation]
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebSearch", "Skill", "AskUserQuestion"]
---

# /plan — plan the document structure before writing

Subject argument: `$ARGUMENTS` (if empty, ask the user what the document is about).

This command has two phases: **Setup** (one-time scaffolding) and **Planning**
(researching the subject and designing the section structure). On a fresh clone,
both phases run. On a re-plan, only the Planning phase runs.

The output of this command is a saved content plan — NOT content in `index.html`.
Content is written by `/write`.

---

## Detect: fresh clone or existing project?

Check whether the project has already been initialised:

```sh
grep -q "AI:FIELD DOC_TITLE" index.html && echo "fresh" || echo "existing"
```

- **Fresh** (placeholder markers still present): run Setup Phase then Planning Phase.
- **Existing** (markers already replaced): skip to Planning Phase.

---

# SETUP PHASE — run once on a fresh clone

## Setup Step 1 — Gather reference material first

Ask the user (AskUserQuestion) whether they want to download reference material
now before planning. Good references make the plan far more targeted.

- **Yes, by URL** → ask for URLs, then invoke the **reference-harvester** skill.
- **Yes, by subject search** → invoke the skill with the subject as a search term.
- **No, continue** → proceed; they can run `/download` before or after planning.

After any downloads, read the `references/` folder so the planning step is
informed by the actual source material.

## Setup Step 2 — Choose the layout

Ask the user (AskUserQuestion) which layout suits the document:

- **single** — one centered reading column, no minimap. Best for linear,
  text-led documents (guides, analyses, reports).
- **canvas** — wide pannable canvas with minimap. Best for diagram-heavy,
  spatial, or reference documents.

Set `<body data-layout="...">` in `index.html` accordingly. Then prune the
unused layout: if `single`, remove `#minimap`, its CSS, the minimap JS, and
the drag-to-pan JS; if `canvas`, the minimap stays.

## Setup Step 3 — Collect project facts

Ask the user (AskUserQuestion) for anything not already provided:

- Document title, short title, one-line subject, description (~155 chars for SEO).
- Author name; copyright year; starting version (`1.0.0`); today's date.
- **Employment disclosure**: does the author work for a vendor discussed in the
  document? The disclaimer must be accurate — do not leave it generic.

Derive URLs from git — do not guess:

```sh
git remote get-url origin
```

Derive:
- `REPO_URL`  = `https://github.com/<owner>/<repo>`
- `PAGES_URL` = `https://<owner>.github.io/<repo>/`

## Setup Step 4 — Rewrite the template shell

Consult the `ai-template-manifest` script in `index.html` for the full field
list. Replace every `<!-- AI:FIELD NAME -->` value: `DOC_TITLE`, `SHORT_TITLE`,
`SUBJECT`, `DESCRIPTION`, `AUTHOR`, `BUILD_VERSION`, `LAST_MODIFIED`,
`COPYRIGHT_YEAR`, `REPO_URL`, `PAGES_URL`, and the three `DISCLAIMER_*` fields.
Keep all comment markers in place.

Update the AI-consumption layer:
- JSON-LD `<script type="application/ld+json">` (headline, author, dates, url).
- `ai-content-map` — update summaries to reflect the new subject.
- `llms.txt` — update title, description, and section list.

**Do not write content sections yet** — that is the job of `/write`.

## Setup Step 5 — Generate a subject-specific README.md

Replace the template `README.md` with a project-specific one. Include:

- A description of the document's subject.
- A link to the published site at `PAGES_URL`.
- A removable **"Built with documentation-template"** section linking back to
  `https://github.com/drpaulcoleman/documentation-template` — so the how-to
  context stays reachable. Tell the user they can delete it once no longer needed.

Bidi-link rule: README → `PAGES_URL`; `index.html` → `REPO_URL` (repo root).

## Setup Step 6 — Snapshot and enable gate

Snapshot the originals (git-ignored):
```
references/_template-snapshot/README.md
references/_template-snapshot/index.html
```

Enable the security commit gate:
```sh
git config core.hooksPath .githooks
```
On macOS/Linux: `chmod +x .githooks/pre-commit .claude/hooks/*.sh`

Confirm: `git config core.hooksPath` should print `.githooks`.

---

# PLANNING PHASE — runs on every /plan call

## Plan Step 1 — Research the subject

Read everything available:

1. All files in `references/` (every `page.md`, `page.html`, `meta.json`).
2. Current `index.html` section structure (if re-planning).

Then run web searches to understand what a comprehensive treatment of this subject
should cover:

- `"[subject] overview key topics"`
- `"[subject] comprehensive guide structure"`
- `"[subject] what should I know"`

Note: the goal is to understand the *shape* of the subject — what major themes,
concepts, and sub-topics exist — not to write content yet.

## Plan Step 2 — Propose a section structure

Design a section outline suited to the subject and chosen layout. For each
proposed section include:

- **id** — short, lowercase, hyphenated (e.g. `cost-model`, `security-architecture`)
- **title** — clear, descriptive heading
- **type** — `content` / `appendix` / `reference`
- **scope** — one sentence: what this section covers and what the reader learns
- **key sources** — which downloaded references or web sources inform this section
- **suggested features** — diagram? checklist? callout? comparison table? exec toggle?

Also recommend:
- Which section should be the BLUF (bottom-line-up-front summary)?
- Which sections warrant an executive dual-view variant?
- Should any sections be combined or split?

## Plan Step 3 — Present and confirm the plan

Show the proposed structure to the user. Be explicit:

> "Here is the proposed section structure for **[title]**.
> This plan will be saved and used by `/write` to generate the content.
> Please review — you can ask me to add, remove, rename, reorder, or scope sections differently."

Wait for the user's response. Incorporate any feedback and show the revised
structure. Repeat until the user confirms.

## Plan Step 4 — Save the approved plan

Write `references/CONTENT-PLAN.md` (git-ignored). Structure:

```markdown
# Content Plan — [document title]

Generated: [date]
Subject: [subject]
Layout: [single | canvas]
References available: [list of references/ subfolders]

---

## Section Structure

### [section-id]: [Title]
- **Type:** content | appendix | reference
- **Scope:** [one-sentence description]
- **Key sources:** [list]
- **Suggested features:** [diagram, callout, table, exec-toggle, checklist…]
- **Key points to cover:**
  - [bullet]
  - [bullet]

### [next section…]

---

## Build notes
[Any special instructions for /write: tone, depth, audience level, formatting preferences]
```

## Plan Step 5 — Hand off to /write

Tell the user:

> "Your content plan is saved at `references/CONTENT-PLAN.md`.
>
> **Next step:** run `/write` to generate the document content from this plan and
> your downloaded references.
>
> You can run `/download [url or topic]` first if you want more source material
> before writing. You can also re-run `/plan` at any time to restructure — it
> will not overwrite content, only the plan file."
