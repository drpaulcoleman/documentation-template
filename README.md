# Documentation Template

A reusable **GitHub template** for building standalone, single-page documentation
sites — one self-contained `index.html`, hosted free on GitHub Pages, with
built-in navigation, search, deep linking, citations, diagrams, and AI build
tooling. Create a repository from this template, open it with an AI assistant
(Claude Code), run one command, and you have a polished reference document.

It is built for **AI-savvy non-developers** — analysts, solution engineers,
architects — not just programmers. The AI does the building; the guardrails keep
it safe and consistent.

**Live demo / published shell:** <https://drpaulcoleman.github.io/documentation-template/>
&nbsp;·&nbsp; **Source:** <https://github.com/drpaulcoleman/documentation-template>

---

## How to use this template

> **The mental model:** you are the subject-matter expert and reviewer; Claude
> Code is the author and builder. You do not edit HTML by hand — every section,
> citation, and diagram is generated through conversation.

1. **Create your repository.** On GitHub, click **Use this template → Create a
   new repository**. Clone it to your machine.

2. **Open the repo with Claude Code.** You can use any of these:
   - **VS Code / Cursor / JetBrains** — install the Claude Code extension and open
     the repo folder; the assistant is available in the sidebar.
   - **Terminal** — install the CLI (`npm install -g @anthropic/claude-code`) then
     run `claude` from inside the cloned repo.
   - **Desktop app** — open [claude.ai/code](https://claude.ai/code) and point it
     at your local repo folder.

3. **Run `/plan <your subject>`.** This is the setup and planning command. It will:
   - offer to download reference material first (by URL or by subject search);
   - ask which **layout** you want — `single` (one reading column) or `canvas`
     (wide, pannable, with a minimap);
   - collect your title, author, version, and disclaimers;
   - rewrite the `index.html` shell and generate a subject-specific `README.md`;
   - enable the security commit gate;
   - research the subject and propose a section outline for your approval;
   - save the approved outline to `references/CONTENT-PLAN.md`.

4. **Gather more sources** any time with `/download <url>` or `/download <subject>`
   — material lands in `references/` where Claude reads it as context.
   Run as many times as you like; more sources mean richer content.

   ```
   /download https://example.com/the-definitive-guide-to-my-topic
   /download "my topic" research papers
   ```

5. **Run `/write`** to generate the document. Claude reads the approved plan and
   all downloaded references, then authors full sections — synthesised prose,
   Mermaid diagrams, APA citations. Pass a section id to rebuild just one section:

   ```
   /write
   /write cost-model
   ```

   Iterate conversationally for revisions — see the
   [prompting guide](https://drpaulcoleman.github.io/documentation-template/#prompting-guide)
   for copy-paste examples. You never need to touch the HTML directly.

6. **Run `/check`** for an accuracy and coverage audit, and **`/enhance-document`**
   for UX and design improvements. Both produce reports in `references/` and offer
   to apply fixes immediately.

7. **Commit and push.** GitHub Pages publishes automatically (see
   [GitHub Pages](#github-pages) below). Your document goes live.

> First time? Steps 1–3 give you a working document shell immediately. Steps 4–6
> are where you turn it into real, polished content.

## Examples built with this template

| Document | Subject |
|----------|---------|
| [Agentforce Mythos & Hardening](https://drpaulcoleman.github.io/agentforce-mythos-hardening/) | Salesforce Agentforce security analysis and hardening patterns · [repo](https://github.com/drpaulcoleman/agentforce-mythos-hardening) |
| [Agentforce Cost Gateway](https://drpaulcoleman.github.io/agentforce-cost-gateway/) | Cost management and gateway architecture for Agentforce deployments · [repo](https://github.com/drpaulcoleman/agentforce-cost-gateway) |
| [Salesforce LDV Cheat Sheet](https://drpaulcoleman.github.io/salesforce-ldv-cheatsheet/) | Large Data Volumes patterns, limits, and best practices for Salesforce · [repo](https://github.com/drpaulcoleman/salesforce-ldv-cheatsheet) |
| [Heroku Migration Guide](https://drpaulcoleman.github.io/heroku-migration/) | Patterns and considerations for migrating applications off Heroku · [repo](https://github.com/drpaulcoleman/heroku-migration) |

## What you get

A finished `index.html` includes, with no build step:

- Sidebar **table of contents** with scroll-spy.
- **Full-text search** (`/` to focus, `Enter`/`Shift+Enter` to cycle).
- **Deep linking & browser history** — every section and bookmarked paragraph is
  addressable; back/forward retrace the reading trail.
- **Dual reading modes** — an executive summary view and a full-detail view.
- **Mermaid diagrams**, **syntax-highlighted code**, **persistent checklists**.
- An **APA-style references section** with in-text `[N]` citation markers.
- An **AI-coach** widget that builds context-grounded prompts for readers.
- Dark/light themes, print styles, responsive layout.
- A non-visible **AI-consumption layer** (JSON-LD, content map, `llms.txt`) so
  other AI systems can reference your document accurately.

## Repository structure

```
.
├── index.html              The documentation site (a working demo until you initialise)
├── README.md               This file
├── CLAUDE.md               Durable rulebook the AI follows — survives rebuilds
├── llms.txt                Plain-text summary for AI/LLM crawlers
├── docs/                   Optional: files you want committed & published
├── references/             Local-only reference material (git-ignored)
├── .github/workflows/      GitHub Pages deploy workflow
├── .githooks/pre-commit    Security commit gate (secret & artifact scanner)
└── .claude/                AI tooling — skills, commands, hooks, settings
```

## AI tooling

### Commands

| Command | What it does |
|---------|--------------|
| `/plan [subject]` | Sets up the project (layout, metadata, git hooks, README), optionally downloads references, then researches the subject and produces an approved section outline in `references/CONTENT-PLAN.md`. Re-run any time to restructure without overwriting content. |
| `/download [url \| subject]` | Harvests web pages, PDFs, or search results into `references/` for AI context. Prefers a linked PDF over crawling many pages; always includes Google Scholar for subject searches. |
| `/write [section]` | Generates full prose, Mermaid diagrams, and APA citations from the plan and downloaded references. Omit the argument to write everything; pass a section id to rebuild one section. Updates nav, ai-content-map, and llms.txt. |
| `/check [section \| topic]` | Verifies factual claims, checks for dead or stale citations, finds post-publication developments, and flags coverage gaps. Offers a cross-model fact-check if other AI CLIs (Gemini, `llm`, Ollama…) are installed. |
| `/enhance-document [focus]` | Audits UX, design, and world-class quality — feature utilisation, theme appropriateness for the subject, information architecture, and actionable "what would make this outstanding?" recommendations. Offers a cross-model design review and applies quick wins immediately. |

### Skills (`.claude/skills/`)

| Skill | What it does |
|-------|--------------|
| `reference-harvester` | Runtime-adaptive headless-browser harvester. Detects Python / Node.js / PowerShell / plain shell and uses the best available path to fetch JavaScript-rendered content. |
| `skill-creator` | Create, improve, and evaluate additional skills for your project. |

### Hooks (`.claude/hooks/` and `.githooks/`)

| Hook | When it runs | What it does |
|------|--------------|--------------|
| `.githooks/pre-commit` | On `git commit` | Security commit gate — scans staged files for secrets and unsafe artifacts (see below). |
| `commit-guard.sh` | Before the AI runs a Bash command | Blocks attempts to bypass the commit gate (`--no-verify`, `core.hooksPath` changes). |
| `bump-last-modified.sh` | After `index.html` is edited | Updates the "last modified" date everywhere it appears in `index.html`. |
| `readme-sync-prompt.sh` | When the AI finishes a turn | If `index.html` changed but `README.md` did not, prompts a quick README review so the two stay in sync. |

## Security protections

This template includes a **commit gate** to keep secrets and dangerous files out
of your repository — defence against accidental credential leaks and
supply-chain attacks. It is designed for non-developers: plain-language messages
that tell you exactly what to fix.

- **`.githooks/pre-commit`** scans every staged change and **blocks the commit**
  if it finds: private keys, API tokens, AWS/GitHub/Google/Slack credentials, or
  generic password/secret assignments; executable files or script-droppers
  (`.exe`, `.dll`, `.scr`, `.vbs`, …); unexpected binary files; or
  download-and-run supply-chain patterns (`curl … | sh`).
- **`commit-guard.sh`** stops the AI assistant from bypassing that gate.
- Enable the gate once per clone — `/plan` does it for you, or run:
  ```sh
  git config core.hooksPath .githooks
  ```
- A human who has reviewed a finding and is certain it is safe can override with
  `git commit --no-verify` from their own terminal. The AI cannot.

Patterns and the `.gitignore` / `.gitattributes` policy follow current
supply-chain-security practice.

## Runtime dependencies

**The template bundles no runtime and works out of the box.** All hooks are
written in POSIX shell and run via the shell that already ships with Git — no
Python or Node.js required for any built-in feature.

On **Windows**, the Claude Code hooks (registered in `.claude/settings.json`)
invoke `bash`. Git for Windows provides `bash.exe` and normally adds it to
`PATH` during installation — if the hooks fire silently with no effect, confirm
`bash` is reachable: `where bash` should return a path inside your Git
installation.

The only component that benefits from extra software is the `reference-harvester`
skill, and it is **runtime-adaptive**: it detects what you have and uses the best
available path, falling back to a basic `curl` fetch if nothing else is present.
It will **never install anything for you** — it tells you what is missing and
shows the command.

Optional, for the best web harvesting (real JavaScript rendering):

| Option | Install (run it yourself) |
|--------|---------------------------|
| Python + Playwright *(recommended)* | `python -m pip install playwright` then `python -m playwright install chromium` |
| Node.js + Playwright | `npm install playwright` then `npx playwright install chromium` |
| Windows | Nothing — Microsoft Edge (included with Windows 11) is used in headless mode |

See [.claude/skills/reference-harvester/README.md](.claude/skills/reference-harvester/README.md)
for details.

## GitHub Pages

The workflow at `.github/workflows/deploy-pages.yml` publishes the site on every
push to `main`. It uses `actions/configure-pages` with `enablement: true`, which
turns Pages on automatically the first time it runs — so a repo created from this
template usually needs no manual setup.

**To verify or enable Pages manually on your repo:**

1. Go to your repository on GitHub.
2. Click **Settings** (top navigation bar).
3. In the left sidebar, click **Pages**.
4. Under **Build and deployment**, set **Source** to **GitHub Actions**.
5. Push any change to `main` (or re-run the workflow under **Actions**) to trigger
   the first deployment.
6. GitHub will display the published URL at the top of the Pages settings page —
   it will be `https://<your-username>.github.io/<your-repo-name>/`.

If your organisation blocks API enablement, the manual steps above are required.
If the workflow still fails after enabling, check **Actions → deploy-pages** for
error details — the most common cause is that Pages is set to **Deploy from a
branch** instead of **GitHub Actions**.

## Disclaimers

Documents built with this template express **their author's own analysis** — they
are not official documentation for any vendor. The template's `index.html`
includes a Disclaimers section for the author's-opinion notice, employment
disclosure, and trademark attribution; keep it accurate. Reference material must
be cited, not copied — see the attribution rules in [CLAUDE.md](CLAUDE.md).

## License

See [LICENSE](LICENSE) (Mozilla Public License 2.0).
