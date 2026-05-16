---
description: |-
  UX, design, and world-class quality audit for the current index.html.
  Inventories which features are used, assesses whether the visual design and
  theme suit the subject matter, searches the web for best-in-class documentation
  design, and — if other AI CLIs are available — offers a cross-model UX review.
  Produces a prioritised enhancement report (quick wins → structural → aspirational)
  and offers to apply quick wins immediately.
argument-hint: [optional: focus area — "design", "ux", "content", "features"]
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "WebSearch", "AskUserQuestion"]
---

# /enhance-document — UX, design, and world-class quality audit

Argument: `$ARGUMENTS` (optional focus area — `design`, `ux`, `content`, or `features`;
if empty, audit everything).

This command asks: *what would make this document truly world-class?* It looks beyond
accuracy (that is `/check`'s job) and focuses on presentation, usability, visual
design appropriateness, and feature utilisation.

Work through the steps in order.

---

## Step 1 — Detect available AI CLIs

Probe silently for peer AI CLIs:

```sh
command -v gemini 2>/dev/null && echo "gemini"
command -v llm    2>/dev/null && echo "llm"
command -v ollama 2>/dev/null && echo "ollama"
gh copilot --version 2>/dev/null && echo "gh-copilot"
```

```powershell
foreach ($cmd in @("gemini","llm","ollama")) {
  if (Get-Command $cmd -ErrorAction SilentlyContinue) { Write-Output $cmd }
}
try { gh copilot --version 2>$null; Write-Output "gh-copilot" } catch {}
```

If two or more AI CLIs are detected (including the current Claude session):
ask the user (AskUserQuestion):

> "I found [list] alongside Claude. A cross-model UX review sends the same
> design questions to each — different models have different aesthetic sensibilities
> and will catch different things. Run a cross-model review?"

Options: **Yes — cross-model** / **No — Claude only**

---

## Step 2 — Read and inventory the document

Read `index.html` in full. Record:

**Subject and audience**
- Document title, subject, and description (from `AI:FIELD` markers or JSON-LD).
- Intended audience (infer from the disclaimers and content tone if not explicit).
- Layout mode: `single` or `canvas` (from `body[data-layout]`).

**Feature inventory** — check whether each feature is actively used or absent:

| Feature | Used? | Notes |
|---------|-------|-------|
| Mermaid diagrams | | Count, assess quality |
| Dual-view (exec/tech) | | How many sections have exec variants? |
| Callout boxes | | Types used (info / warn / disclaimer) |
| Checklists (`input[type=checkbox]`) | | Present? |
| Paragraph bookmarks (`.anchored[id]`) | | Used? |
| AI-coach prompts | | Still the generic defaults or customised? |
| Minimap (canvas layout) | | Applicable and enabled? |
| Search | | Will it work well given the content? |
| In-text citations | | Citation density per section |
| Comparison tables | | Used where appropriate? |

**Section inventory**
- List each section: id, title, approximate word count (rough estimate), number of
  diagrams, number of citations.
- Flag any section that is a thin placeholder (< 150 words, no citations).

---

## Step 3 — Assess design appropriateness

Evaluate whether the current visual design — colour palette, typography, tone —
suits the subject matter. Consider:

- **Security / risk documents** → should feel authoritative, use amber/red for
  warnings, have severity indicators, clear visual hierarchy for critical points.
- **Financial / cost documents** → data-dense tables, positive/negative colour
  semantics (green/red), clear metric callouts.
- **Reference / cheat-sheet documents** → maximum information density, quick-scan
  layouts, minimal prose, strong heading hierarchy.
- **Migration / how-to guides** → numbered steps, before/after comparisons, clear
  progress signposting, warning callouts for gotchas.
- **Architectural / design documents** → diagram-heavy, spatial layout (canvas
  mode), concept maps, relationship diagrams.
- **Strategic / executive documents** → large typography, ample whitespace, strong
  BLUF, executive-view toggle prominent.

Rate each dimension: Well-matched / Adequate / Needs attention.

---

## Step 4 — Web search for inspiration and benchmarks

Run targeted web searches:

- `"world class technical documentation design examples [current year]"`
- `"best [subject-type] documentation UX design"`  ← substitute the document's type
- `"documentation site design awards winners"`
- `"[subject] reference guide best practices layout"`

Note specific design patterns, features, or approaches from the results that would
improve this document. Cite the source in the report.

---

## Step 5 — Evaluate against world-class design principles

Assess the document on each dimension. Score: ★★★ excellent / ★★☆ adequate / ★☆☆ needs work.

**Information architecture**
- Is the section order logical and progressive?
- Does the sidebar TOC give a clear mental model of the document?
- Are the most important sections the most prominent?

**Visual hierarchy**
- Can a reader skim and know where to look in < 10 seconds?
- Are headings, callouts, and diagrams doing their jobs?
- Is there enough contrast between different content types?

**Reading rhythm**
- Does prose vary in density (long explanation → short callout → diagram)?
- Are paragraphs appropriately short for the web reading context?
- Is whitespace used to create breathing room?

**Feature utilisation**
- Are the template's interactive features (dual-view, search, deep links,
  AI-coach) serving the reader, or are they underused?
- Are diagrams explanatory or decorative?
- Are callout boxes highlighting the right things?

**First-impression quality**
- Would a senior UX designer consider this document professional and polished?
- Does it look purpose-built for this subject, or generic?
- Is the hero section compelling? Does it answer "why should I read this?"

---

## Step 6 — Cross-model UX review (if approved in Step 1)

Build a UX critique prompt from the document's subject, section structure, and
key design characteristics. Send to each available CLI:

```
You are a senior UX designer reviewing a technical documentation site.
The document is about: [subject]
The audience is: [audience]
Current features used: [feature inventory summary]
Layout: [single/canvas]

Please answer these questions:
1. What is the single most impactful UX improvement this document needs?
2. Does the current design suit the subject matter? What would make it more appropriate?
3. Which sections feel weak or underdeveloped from a reader experience perspective?
4. What one feature is this document missing that would make it truly world-class?
5. What would you change about the information architecture?
```

Invoke each CLI:

| CLI | Invocation |
|-----|-----------|
| `llm` | `llm "prompt"` |
| `gemini` | `gemini -p "prompt"` (try `--prompt` if `-p` fails) |
| `ollama` | `ollama run llama3 "prompt"` (substitute installed model) |

Capture and note where models agree (strong signal) and where they diverge
(worth exploring both perspectives).

---

## Step 7 — Produce the enhancement report

Write the report to `references/enhancement-[YYYY-MM-DD].md` (git-ignored).

```markdown
# Enhancement Report — [document title]

**Date:** [today]
**Reviewed by:** Claude[, + other models if cross-review ran]
**Focus:** [all | design | ux | content | features]

---

## Executive Summary

[2–3 sentences: overall quality level, most impactful gap, and one headline
recommendation.]

---

## Feature Utilisation Score

| Feature | Status | Recommendation |
|---------|--------|----------------|
| Mermaid diagrams | ★★☆ | Add diagrams to sections X and Y |
| Dual-view | ★☆☆ | No exec variants — add to top 3 sections |
| ... | | |

---

## Design Appropriateness

[Rating and specific observations per dimension from Step 3.]

---

## Quick Wins  ← apply now, high impact, low effort

| # | Enhancement | Where | Effort |
|---|------------|-------|--------|
| 1 | ... | ... | 15 min |
| 2 | ... | ... | 30 min |

---

## Structural Improvements  ← higher effort, significant impact

[Reorganisation suggestions, new sections, section splits or merges.]

---

## Design & Theme Recommendations

[Specific colour, typography, or layout changes to better match subject matter.]

---

## World-Class Aspirational List

[3–5 features or design choices that would genuinely distinguish this document
from typical AI-generated docs — even if they require significant effort.]

---

## Cross-Model Findings  ← if cross-review ran

[Areas of agreement across models (high confidence); divergences worth exploring.]

---

## Inspiration Sources

[Specific examples or patterns found in web searches, with URLs.]
```

---

## Step 8 — Offer to apply quick wins

For each Quick Win in the report, ask the user (AskUserQuestion):

> "I found [N] quick wins. Shall I apply them now? (You can review the full
> report at `references/enhancement-[date].md` first.)"

Options: **Yes — apply all quick wins** / **Let me review the report first** /
**Pick specific ones**

If applying:
- Make each change as a targeted `Edit` to `index.html`.
- After applying, tell the user which quick wins were applied and what changed.
- Remind them to commit and push when they are happy with the result.
