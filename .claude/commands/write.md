---
description: |-
  Generate or regenerate content in index.html from the approved plan and
  downloaded references. Writes full prose, Mermaid diagrams, and APA citations
  for every section (or a single named section). Updates the sidebar nav,
  ai-content-map, JSON-LD, and llms.txt to match. Run after /plan and /download;
  re-run any time to expand, rewrite, or add sections.
argument-hint: [section-id | "all" (default)]
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebSearch", "AskUserQuestion"]
---

# /write — generate document content from plan and references

Argument: `$ARGUMENTS` (a section `id` to rebuild just that section, or empty / "all"
to write every planned section).

Work through the steps in order. Write content that reflects the author's own
analysis — never paste large passages from references; synthesise in your own words
and cite every factual claim.

---

## Step 1 — Load the plan

Check for `references/CONTENT-PLAN.md`:

**If it exists:** read it. It is the authoritative section blueprint — use it for
every content decision (section IDs, titles, scope, sources, key points).

**If it does not exist:** do not invent one silently. Instead:
1. Read `index.html` to see which sections already exist and what they contain.
2. Read everything in `references/` to understand the available source material.
3. Present a proposed section structure (IDs, titles, one-line scope for each).
4. Ask the user (AskUserQuestion) to confirm or adjust it before proceeding.
5. Write the confirmed plan to `references/CONTENT-PLAN.md`.

---

## Step 2 — Load all reference material

Glob `references/**/` and read every `page.md`, `page.html`, and `meta.json` that
exists. Note each source's URL and retrieval date from its `meta.json` — you will
need these for APA citations.

If references are sparse for a topic you need to cover, run a targeted web search
to fill the gap. Flag any sections where you had to rely entirely on web search
rather than downloaded references — the user may want to `/download` more.

---

## Step 3 — Determine scope

- If `$ARGUMENTS` is empty or "all": write every section in the plan.
- If `$ARGUMENTS` is a section `id`: write only that section. Leave all other
  sections untouched.

---

## Step 4 — Write each section

For each section in scope, follow these rules:

### Content rules
- Open with the point, not the wind-up. Lead with the most important insight.
- Write in the author's voice — analytical, direct, confident.
- Every factual claim needs a citation: `<sup><a href="#ref-N" class="cite">[N]</a></sup>`.
- Synthesise across multiple sources rather than summarising one at a time.
- Include concrete examples wherever the plan calls for them.
- Executive dual-view: if the section warrants it, wrap the full-detail paragraphs
  in `<p data-view-only="tech">` and add a concise `<p data-view-only="exec">` lead.

### Diagram rules (when plan specifies one)
- Use `<pre class="mermaid">` with a consistent `classDef` palette.
- Add `click NODEID call diagramNav('SECTION_ID')` on at least one node.
- Follow with `<div class="diagram-caption">Figure N — …</div>`.

### Callout rules
- Use `<div class="callout">` for key takeaways, warnings, or action prompts.
- Use `<div class="callout warn">` for warnings or gotchas.
- Use `<div class="callout disclaimer">` for notices.

### Section HTML structure
```html
<section class="card" id="SECTION_ID">
  <div class="eyebrow">Section N</div>
  <h2>SECTION TITLE</h2>
  <!-- content here -->
</section>
```

Replace any existing placeholder content for that section. Keep the `AI-TEMPLATE`
skeleton comments in place — do not delete them.

---

## Step 5 — Update the References section

Add or update APA-style `<li>` entries in `#ref-list` for every source cited.
Format: `Author, A. A. (Year). *Title*. Publisher. Retrieved Month D, Year, from URL`

Number citations in the order they first appear in the document. Update all
in-text `[N]` markers to match the final numbering.

---

## Step 6 — Update the sidebar nav

Ensure `#sidebar nav` has exactly one `<a href="#SECTION_ID">` for every section
in the plan. Add any missing links; remove links for sections that no longer exist.
Group them under `<div class="nav-group">` labels that reflect the document
structure.

---

## Step 7 — Update the AI-consumption layer

- **JSON-LD** `<script type="application/ld+json">` — update `headline`, `dateModified`.
- **`ai-content-map`** — add or update one entry per section with an accurate
  one-sentence `summary`. Remove entries for deleted sections.
- **`llms.txt`** — regenerate the Sections list to match the current section set.

---

## Step 8 — Report to the user

Tell the user:
- Which sections were written or updated.
- How many citations were added and how many unique sources were used.
- Any sections where source material was thin (and suggest `/download [topic]`).
- Remind them to run `/check` for an accuracy and coverage audit, and
  `/enhance-document` for UX and design improvements.
