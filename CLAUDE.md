# CLAUDE.md — operating rules for this documentation project

This repository was created from the **documentation-template**. It produces a
single-page documentation website (`index.html`) published with GitHub Pages.

This file is the **durable rulebook**. `index.html` and `README.md` get rewritten
for each project's subject — when that happens, the build instructions embedded
in those files are lost. The rules below are NOT lost: keep them here and follow
them on every session, even after `index.html` and `README.md` have been
replaced with subject-specific content.

---

## 1. What you are building

A standalone `index.html` — one self-contained file (inline CSS/JS, CDN libraries
only) — that renders as a navigable reference document and is hosted on GitHub
Pages. A primary goal is that the **published content can be referenced by other
AI systems**, so machine-readable structure matters as much as the visible page.

## 2. Workflow & tooling

**Your role in this project is content author, not placeholder replacer.** When
a user asks you to "build the content," "write a section," or "fill in the
document," they mean: read the material in `references/` (and any other context
available), synthesise it into original prose, and generate complete sections —
including prose, diagrams, citations, and the AI-consumption layer. The user
supplies the subject-matter direction and reviews the result; you produce the
document. The user does not edit HTML by hand.

The typical session flow is:

1. User runs `/plan <subject>` — you set up the project, optionally download
   references, research the subject, and produce an approved section outline
   saved to `references/CONTENT-PLAN.md`. **No content is written yet.**
2. User runs `/download <url or topic>` one or more times — source material
   accumulates in `references/`.
3. User runs `/write` — you read the plan and references and author the full
   document: prose, diagrams, citations, nav, and AI-consumption layer.
4. User reviews in the browser, asks for revisions conversationally, or runs
   `/write [section-id]` to rebuild a specific section.
5. User runs `/check` for accuracy and coverage, `/enhance-document` for UX
   and design improvements.
6. User commits and pushes; GitHub Pages publishes.

**Commands (`.claude/commands/`):**

- **`/plan [subject]`** — sets up the project and produces the content outline.
  Re-run at any time to restructure without overwriting content.
- **`/download [url | subject]`** — harvests reference material into
  `references/` using the `reference-harvester` skill.
- **`/write [section]`** — generates or regenerates content from the plan and
  references. Pass a section id to rebuild one section; omit for all.
- **`/check [section | topic]`** — accuracy, citation, and coverage audit with
  optional cross-model fact-check.
- **`/enhance-document [focus]`** — UX, design, and world-class quality audit
  with optional cross-model review; applies quick wins on approval.

**Skills** (`.claude/skills/`): `reference-harvester` (runtime-adaptive web/PDF
harvester) and `skill-creator` (for building more skills).

**Hooks** (`.claude/hooks/`): `commit-guard.sh` (blocks commit-gate bypass),
`bump-last-modified.sh` (auto-dates `index.html` on edit), `readme-sync-prompt.sh`
(prompts a README review when `index.html` changes).

## 3. index.html build conventions

`index.html` is marker-driven so any AI can build it precisely:

- **`<!-- AI:FIELD NAME -->`** — marks a single replaceable value (title, author,
  date, URLs, disclaimers). Wrapped form: `<!-- AI:FIELD NAME -->value<!-- /AI:FIELD NAME -->`.
  For `<title>`/`<meta>` the marker sits on the line above. Keep markers in place
  so the document stays re-buildable.
- **`<!-- AI-TEMPLATE:name ... AI-TEMPLATE:END -->`** — a commented skeleton for
  a repeatable block (content section, appendix, reference entry, TOC link,
  diagram). Copy the markup out of the comment, fill it in, leave the skeleton.
- **`<script id="ai-template-manifest">`** — the authoritative JSON list of every
  field and repeatable block. Consult it before editing.
- Section ids are short, lowercase, hyphenated. Every content section needs a
  matching sidebar nav link (and a TOC entry if it is major).
- Layout is `body[data-layout]`: `single` (one column) or `canvas` (wide
  pannable + minimap). `/initialize-project` sets it and prunes the unused mode.

## 4. AI-consumption layer — keep it in sync

The finished document must be reliably consumable by other AIs. Three
non-visible structures provide that; update them whenever sections change:

- **JSON-LD** (`<script type="application/ld+json">` in `<head>`) — schema.org
  `TechArticle` metadata: headline, author, `datePublished`, `dateModified`, url.
- **`<script id="ai-content-map">`** — a section-by-section index with a one-line
  authoritative summary of each section. Add/maintain one entry per section.
- **`llms.txt`** (repo root) — a short, link-rich plain-text summary for LLM
  crawlers. Regenerate when the section list changes.

## 5. Attribution & anti-plagiarism — non-negotiable

- The document is the **author's own analysis**. It is NOT official documentation
  for any vendor. The Disclaimers section must say so and must disclose any
  employment/commercial relationship between the author and a vendor discussed.
- **Never paste large passages** of someone else's content. Synthesise in your
  own words.
- Any **direct quote** must be short, wrapped in quotation marks or a
  `<blockquote>`, and carry an in-text citation marker linking to the References
  section: `<sup><a href="#ref-N" class="cite">[N]</a></sup>`.
- Every external source gets an **APA-style entry** in the References section
  **with a "Retrieved [date]" marker** — the retrieval date is recorded in each
  `references/**/meta.json` by the harvester.
- Acknowledge trademarks and product names as the property of their owners.

## 6. Diagramming rules

- Diagrams use **Mermaid**; put the source in `<pre class="mermaid">`.
- Define a `classDef` colour palette and reuse the same class names across
  diagrams for visual consistency.
- To make a node jump to a section: `click NODEID call diagramNav('SECTION_ID')`.
- Keep node labels short; add a `<div class="diagram-caption">Figure N — …</div>`.

## 7. References folder

`references/` is **git-ignored, local-only** — never committed, never published.
It holds harvested reference material and the local `PROJECT-PLAN.md`. Use it for
context and citation; do not copy from it. Only `references/README.md` is tracked.

## 8. Security commit gate — do not weaken it

- A `pre-commit` hook (`.githooks/pre-commit`, pure POSIX shell) blocks commits
  containing secrets (keys, tokens, passwords) or unsafe artifacts (executables,
  script-droppers, unexpected binaries) — a defence against credential leaks and
  supply-chain attacks.
- Enable it once per clone: `git config core.hooksPath .githooks`
  (`/initialize-project` does this).
- **Never bypass the gate.** Do not use `git commit --no-verify`/`-n`, do not
  re-point `core.hooksPath`, do not delete or weaken `.githooks/`. A human may
  override deliberately from their own terminal; you may not. The
  `commit-guard.sh` hook enforces this.
- If the gate blocks a commit, fix the flagged content — do not work around it.

## 9. Runtime adaptivity

The template assumes no scripting runtime. All hooks are POSIX shell. The
`reference-harvester` skill detects what is installed (Python / Node.js /
PowerShell / plain shell) and adapts. **Never auto-install** a runtime or library
and never execute downloaded content — surface install instructions and let the
user decide.

## 10. README & links

- Keep `README.md` in sync with the document. When `index.html` changes
  materially, review `README.md` (the readme-sync hook will prompt you).
- Bidirectional links: `README.md` links to the published `index.html` via the
  GitHub Pages URL; `index.html` links back to the **repository root** (not the
  README file), so all repo contents stay discoverable.

## 11. Local project plan

`references/PROJECT-PLAN.md` (git-ignored) tracks build/refinement tasks by ID
(T1, T2, …). Refinement requests may reference those IDs — consult and update it.
