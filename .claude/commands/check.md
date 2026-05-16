---
description: |-
  Accuracy, completeness, and citation audit for the current index.html.
  Verifies factual claims against references and web search, checks for dead or
  stale citations, finds post-publication developments, and flags serious coverage
  gaps. If other AI CLIs are available, offers a cross-model fact-check. Saves a
  structured remedies report to references/.
argument-hint: [optional: section id or topic to focus on]
allowed-tools: ["Bash", "Read", "Write", "Glob", "Grep", "WebSearch", "WebFetch", "AskUserQuestion"]
---

# /check — accuracy, citations, and coverage audit

Argument: `$ARGUMENTS` (optional — a section `id` or keyword to focus the audit;
if empty, audit the whole document).

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

If two or more AI CLIs are found (including Claude): ask the user (AskUserQuestion)
whether to run a cross-model fact-check. A cross-model scan catches blind spots that
any single model would miss.

Options: **Yes — cross-model** / **No — Claude only**

---

## Step 2 — Read the document

Read `index.html`. Extract:

- Document subject, author, version, and `LAST_MODIFIED` date.
- All section headings and `id` attributes.
- All **factual claims** — statistics, version numbers, product names, dated
  statements, attributed quotes, comparative assertions.
- All **citation markers** (`[N]`) and their matching References entries (title,
  URL, "Retrieved" date).
- All **external URLs** anywhere in the document.

If `$ARGUMENTS` names a section or keyword, narrow to that scope and note it.

---

## Step 3 — Reference freshness and link health

For each References entry:

1. Check `references/` for a matching folder; read `meta.json` for retrieval date
   and calculate age in days.
2. Flag references **older than 180 days** as potentially stale.
3. Probe each URL with a single HEAD request:

```sh
curl -sILo /dev/null -w "%{http_code}" --max-time 10 "URL"
```

```powershell
try { (Invoke-WebRequest -Uri "URL" -Method Head -TimeoutSec 10 -UseBasicParsing).StatusCode }
catch { "unreachable" }
```

Flag 4xx / 5xx / timeout as **dead or unreachable**.

---

## Step 4 — Web search: current state of the subject

- Search `"[subject] latest [current year]"` — look for new releases, deprecated
  features, changed behaviour, or superseded guidance.
- Search `"[subject] common misconceptions"` — a proxy for claims that are
  frequently stated incorrectly.
- For each stale reference, search its title or topic for updated versions.

Note developments that **post-date the document's `LAST_MODIFIED`** date.

---

## Step 5 — Claim verification

For each factual claim:

1. If it carries a citation already, mark it `cited`.
2. For uncited claims, run a targeted web search.
3. Classify: **Supported** / **Unverified** / **Disputed** / **Overstated**.

---

## Step 6 — Coverage gap analysis

Search for what authoritative sources consider essential topics for this subject:

- `"[subject] overview key concepts"`
- `"[subject] best practices guide"`

Compare results against the document's section structure. List significant topics
that are **absent or barely covered** — weight by importance to the reader.

---

## Step 7 — Cross-model fact-check (if approved)

Build a prompt with the 10–15 most important factual claims. Invoke each CLI:

| CLI | Invocation |
|-----|-----------|
| `llm` | `llm "Fact-check these claims about [subject]: [claims]. Flag anything incorrect, outdated, or unverifiable and explain why."` |
| `gemini` | `gemini -p "..."` (try `--prompt` if `-p` fails) |
| `ollama` | `ollama run llama3 "..."` (substitute installed model) |

Note claims flagged by a second model but not Claude — and vice versa. Multi-model
agreement is a high-confidence finding.

---

## Step 8 — Write the remedies report

Save to `references/check-[YYYY-MM-DD].md` (git-ignored).

```markdown
# Accuracy Check — [document title]

**Date:** [today] | **Models:** Claude[, others] | **Scope:** [whole doc / section]

## Executive Summary
[2–4 sentences on overall accuracy, reference health, and coverage quality.]

## 1. Accuracy Issues
| Claim | Section | Classification | Finding | Remedy |
|---|---|---|---|---|

## 2. Reference Health
| Ref # | Title | Age | HTTP | Action |
|---|---|---|---|---|

## 3. Post-Publication Developments
[Bullet list of changes since LAST_MODIFIED that affect accuracy.]

## 4. Coverage Gaps
| Missing Topic | Importance | Suggested Action |
|---|---|---|

## 5. Cross-Model Findings
[Divergences and high-confidence multi-model findings, or "Single-model only."]
```

---

## Step 9 — Report to the user

- Count of issues by classification.
- Any dead links to fix.
- Serious coverage gaps that warrant a new section — name them.
- Suggest `/download [topic]` for stale references with known updates, then
  `/write [section]` to rebuild affected sections.
