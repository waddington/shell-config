# Quickstart Guide — Multi-Agent Orchestration System

This guide explains how to get started with the `agent-team` framework. It covers installation, first use, customisation, and how to give the team work.

---

## What Is This?

The `agent-team` skill activates a **Lead agent** that orchestrates a team of 20 specialist AI agents on your behalf. You describe what you want in plain language. The Lead decomposes the goal, spawns the right specialists (implementers, reviewers, QA, security, docs, etc.), manages the full task lifecycle, and reports results back to you.

You talk to one agent. It runs the team.

---

## Prerequisites

### 1. Claude Code version

Agent teams require Claude Code **2.1.68 or later**. Update to the latest version:

```bash
claude update
```

Check your current version:

```bash
claude --version
```

### 2. Enable the agent teams feature flag

Agent teams are an experimental feature and must be explicitly enabled. Add the following to your Claude Code settings:

**Global** (`~/.claude/settings.json`):
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or **project-level** (`.claude/settings.json` in your repo root) if you only want it active for specific projects.

If the file doesn't exist yet, create it with just those contents.

---

## Installation

### Option A: Use within this repo (no install needed)

If you have cloned the `intl_maples` repo, the skill is already at `.claude/skills/agent-team/` and active in any Claude Code session opened in this directory.

Invoke it:
- Type `/agent-team`, or
- Describe a multi-agent task — Claude will suggest the skill automatically.

### Option B: Install globally (available in every project)

Run the install script from the repo root:

```bash
./install-claude-skills.sh
```

This copies `.claude/skills/agent-team/` (and all other skills) to `~/.claude/skills/`. After installation, `/agent-team` is available in every Claude Code session on your machine, regardless of which project you're working in.

### Option C: Manual install

```bash
cp -r .claude/skills/agent-team ~/.claude/skills/
```

---

## First Use

Invoke the skill:

```
/agent-team
```

Or just describe what you need:

> "I need to implement a new API endpoint and make sure it's properly reviewed and tested."

You can also steer the team composition directly in your request:

> "Build me a user notification preferences screen — and make sure the architect signs off on the data model before anything gets built, have the product manager write the acceptance criteria first, and get the test designers involved early."

The Lead will respect those instructions and adjust the spawn order accordingly — `architect.principal` and `product.pm` first, `qa.test-designer` before implementation begins, implementers after the design is settled.

The Lead will:
1. Greet you with the full list of available specialist roles and a summary of other installed skills.
2. Ask what you'd like to work on.
3. Once you describe the goal, decompose it into tasks and propose a team composition.
4. Spawn agents and begin working, reporting progress at natural checkpoints.

---

## Example: Building Space Invaders from scratch

This shows what a full agent-team session looks like on a greenfield project.

**You type:**
```
/agent-team — build me a browser-based Space Invaders game. Classic arcade feel,
keyboard controls, increasing difficulty per wave, high score tracking in localStorage.
Make it good enough to show someone.
Consult with the architect, product manager, and test designer.
```

**What the Lead does:**

1. **Decomposes the goal** into a task list:
   - Game loop and rendering engine (HTML5 Canvas)
   - Player ship: movement, shooting, lives
   - Alien grid: formation movement, descent, shooting back
   - Collision detection
   - Wave progression and difficulty scaling
   - Score system with localStorage persistence
   - UI: start screen, HUD, game over screen
   - Visual polish: pixel-art styling, sound effects (Web Audio API)

2. **Proposes the team** and waits for your go-ahead:
   - `architect.principal` — designs the component architecture and game loop pattern before a line is written
   - `implementer.frontend` — builds the game (Canvas rendering, game state, input handling)
   - `qa.test-designer` — defines what "good enough to show someone" means in testable terms
   - `reviewer.correctness` — checks game logic (collision math, wave spawning, edge cases)
   - `reviewer.quality` — ensures the code is readable and maintainable, not just functional
   - `reviewer.tests` — validates test coverage against the QA plan

3. **Runs in parallel where possible:**
   - While `architect.principal` produces the design spec, `qa.test-designer` drafts the test plan
   - Once the spec is approved, `implementer.frontend` builds all components concurrently with independent modules
   - Reviewers are dispatched the moment each component is ready — they don't wait for the full game to be complete

4. **Manages the review cycle:**
   - Collision detection flags a `SHOULD_FIX` on boundary rounding — routed back to implementer, fixed, re-reviewed in one cycle
   - `reviewer.quality` notes the game loop is readable but the alien AI could be extracted — filed as a NITPICK, accepted, not blocking
   - All `MUST_FIX` items resolved before `APPROVED`

5. **Reports back to you:**

> "Space Invaders is complete. Open `index.html` in any browser — no server needed.
>
> What's in it: Canvas-based renderer at 60fps, 11×5 alien grid with authentic left-right-descend movement, player laser and alien bombs with pixel-perfect collision, 3 lives, wave counter with speed scaling every clear, high score persisted to localStorage, Web Audio API sound effects (shoot, explosion, game over), and a start/game-over screen.
>
> 4 tasks completed, 2 review cycles total, no outstanding findings. Ready to show."

**Total agents active at peak:** 4. **Your interactions during the session:** 2 (approve the team, review the final report).

---

---

## Giving the Team Work

### Simple task

> "Add an endpoint that returns whether a card has been activated."

The Lead will create a task, spawn an `implementer.backend`, assign appropriate reviewers (`reviewer.correctness`, `reviewer.tests`), and manage the full review cycle.

### Multi-component work

> "We need to add a new feature: users can opt into push notifications for spending alerts. This involves backend API changes, a frontend toggle, and we'll need a security review of the notification token handling."

The Lead will decompose this into multiple tasks, spawn backend and frontend implementers in parallel, involve `reviewer.security` for the token handling, and coordinate the full workflow.

### Exploratory / analysis tasks

> "Review our logging coverage and flag any observability gaps."

The Lead will spawn `observability` and report findings without requiring you to specify which agent to use.

### Documentation

> "Update the README for the payment-service to reflect the new webhook endpoints we added."

The Lead will spawn `docs.writer`, pass the relevant diff, and have it discover what changed and update the docs accordingly.

---

## Available Specialist Roles

| Role | What it does |
|------|-------------|
| `prioritiser` | Maintains prioritised backlog, resolves ordering conflicts |
| `product.pm` | Translates intent into structured requirements and acceptance criteria |
| `architect.principal` | Holds architectural authority; approves/rejects structural changes |
| `implementer.backend` | Backend code (service logic, data access, integrations) |
| `implementer.frontend` | Frontend code (templates, client-side logic, UI components) |
| `implementer.platform` | Infrastructure-as-code, CI/CD, deployment configs |
| `reviewer.security` | Auth, injection, secrets handling, cryptographic correctness |
| `reviewer.correctness` | Logic, edge cases, data integrity, contract adherence |
| `reviewer.tests` | Test coverage, test quality, assertion completeness |
| `reviewer.quality` | Readability, maintainability, naming, idiomatic style |
| `reviewer.standards` | Project standards, API guidelines, PR conventions |
| `reviewer.logic` | Mechanical defects: off-by-ones, inverted operators, typos, dead code |
| `qa.test-designer` | Test strategy, test plans, coverage requirements |
| `qa.test-writer` | Automated test implementation (unit, integration, e2e) |
| `security.threat-modeler` | STRIDE threat modeling, threat registers, mitigation plans |
| `security.appsec-analyst` | Dependency auditing, vulnerability assessment |
| `debugger` | Root cause analysis, failure investigation, diagnostic reports |
| `perf.reliability` | Latency, throughput, resource consumption, resilience |
| `observability` | Logging, metrics, tracing, alerting, dashboard coverage |
| `docs.writer` | READMEs, architecture overviews, contributing guides |

The Lead spawns only what the work requires. You do not need to specify roles — the Lead decides.

---

## Customisation

### Change the team name and concurrency limits

Edit `config/team.defaults.json` (inside the skill directory):

```json
{
  "team_name": "your-team-name",
  "agents": {
    "total_max_agents": 25,
    "concurrency_limits": {
      "implementer.backend": 3,
      "implementer.frontend": 2,
      ...
    }
  }
}
```

### Adjust performance / coverage thresholds

Also in `config/team.defaults.json` under `coverage_thresholds` and `performance_budgets`. Defaults are set for a general-purpose backend service.

### Update the skills-to-roles mapping

If your team uses different tools, update `agents/skills-mapping.md` to reflect which skills are relevant to which roles. This informs the Lead which skills to mention when assigning tasks.

### CK-specific skills

Several skills in the framework are specific to Credit Karma's infrastructure (JIRA at `jira.creditkarma.com`, Kubernetes via the `ck` CLI, Slack at `intuit.enterprise.slack.com`, etc.). See `agents/skills-mapping.md` for the full portability classification and what to change to use the framework outside of CK.

---

## Adding New Roles

See `CONTRIBUTING.md` in the skill root. Adding a new role requires updating 5 files and following 13 specific edits. CONTRIBUTING.md lists every file and precisely what to change.

---

## Framework File Map

| File / Directory | Purpose |
|-----------------|---------|
| `SKILL.md` | Boot-loader: Lead identity, startup sequence, companion file routing |
| `prime-directive.md` | Governance constitution: rule precedence, review gates, spawn policy |
| `README.md` | Directory guide and role catalog |
| `CONTRIBUTING.md` | How to add/remove/modify framework files while keeping cross-references in sync |
| `config/team.defaults.json` | Team name, concurrency limits, coverage thresholds, performance budgets |
| `agents/index.md` | Master registry: all roles, routing rules, escalation matrix, PR approval rights |
| `agents/roles/` | 22 role specifications (250–600 lines each) |
| `agents/playbooks/` | 10 operational playbooks (debugging, QA, security, orchestration, etc.) |
| `agents/standards/` | 7 engineering standards (coding, architecture, API, testing, security, logging, PR) |
| `agents/tasks/` | Task lifecycle definitions, dependency rules, task templates |
| `agents/skills-mapping.md` | Maps `.claude/skills/` to agent roles with portability classification |

---

## Troubleshooting

**The skill isn't triggering automatically**
> Say `/agent-team` explicitly, or phrase your request as "I want to orchestrate a team of agents to...".

**An agent is behaving unexpectedly**
> Ask the Lead to check which role file the agent loaded. Every agent's behaviour is defined by its role file in `agents/roles/`. If something is wrong, the role file is the source of truth.

**A review is blocking progress indefinitely**
> The Lead escalates to you after 3 review cycles without `APPROVED`. If you see this, the Lead will present the recurring findings and ask how to proceed (redesign, descope, or accept risk).

**I want to use this framework outside of Credit Karma**
> Review `agents/skills-mapping.md` for the list of CK-specific skills and what to replace. The role files, standards, playbooks, and protocol are all generic and work in any codebase.
