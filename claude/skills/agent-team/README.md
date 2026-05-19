# Multi-Agent Orchestration System

## Overview

This directory contains the complete operational framework for a multi-agent software engineering team running on Claude Code Agent Teams. It is not documentation in the traditional sense — it is an **operating system** that defines how autonomous agents coordinate, communicate, review, and deliver production-grade software.

Every file in this system is **enforceable**. Agents are bound by these rules. Violations are protocol failures, not suggestions to reconsider.

---

## How This System Works

A team of specialized AI agents collaborates on software engineering tasks under the coordination of a single **Lead** agent. The Lead is the only agent that communicates with the human user. All other agents communicate exclusively through structured messages routed according to the protocol defined here.

### Core Principles

1. **Single point of contact.** The human talks to the Lead. The Lead talks to the team. No exceptions.
2. **Structured communication.** All inter-agent messages follow a strict format. Free-form text between agents is prohibited.
3. **Review gates.** No code merges without passing all required review lenses for the change type.
4. **Explicit lifecycle.** Every task passes through defined states with validated transitions.
5. **Controlled spawning.** Only the Lead spawns agents. Spawning is bounded by concurrency limits.
6. **Security first.** Security findings block merges. Security cannot be overridden without documented justification and security reviewer consent.
7. **Test first.** No implementation is complete without tests. Bug fixes require regression tests.
8. **Observable by default.** New behavior requires logging, metrics, and monitoring instrumentation.
9. **Fail explicitly.** Errors are not swallowed. Ambiguity is escalated. Silence is not compliance.
10. **Iterate with control.** Agents may propose new work, but only the Lead accepts it. Iteration has explicit stopping conditions.

---

## Directory Structure

```
agent-team/
├── SKILL.md                           # Boot-loader: Lead identity, startup sequence, companion file routing
├── prime-directive.md                 # Governance constitution: rule precedence, review gates, spawn policy
├── README.md                          # This file
├── QUICKSTART.md                      # Installation and first-use guide
├── CONTRIBUTING.md                    # How to add/remove/modify framework files
├── config/
│   └── team.defaults.json             # Concurrency limits, coverage thresholds, performance budgets
└── agents/
    ├── index.md                       # Master registry: all roles, routing rules, escalation matrix
    ├── skills-mapping.md              # Maps .claude/skills/ to agent roles with portability classification
    ├── roles/                         # One file per agent role (22 roles)
    ├── playbooks/                     # Operational procedures for specific workflows
    ├── standards/                     # Engineering quality standards enforced by reviewers
    └── tasks/
        ├── definitions/               # Task lifecycle state machine, Definition of Done, dependencies
        └── templates/                 # Reusable task templates (general, review, PR, bugfix, spike)
```

---

## Key Files

### `SKILL.md`

The entry point loaded when the skill is invoked. Contains the Lead's full boot sequence: startup steps, role catalog, companion file routing table, spawn instructions, and the 5 condensed critical rules. Agents do not need to read this — it is the Lead's initialization script.

### `prime-directive.md`

The governance constitution. Every agent reads this on startup. It establishes rule precedence, review gate policy, Definition of Done, messaging requirements, spawn policy, security-first and test-first requirements, and the full file reference map. This file overrides all other files.

### `agents/index.md`

The single source of truth for the team. Defines every role, its file location, startup requirements, routing rules, escalation matrix, review lens assignments, PR approval rights, concurrency limits, and spawn recommendations. When `index.md` conflicts with a role file, `index.md` wins.

### `config/team.defaults.json`

Runtime configuration: concurrency limits per role, iteration bounds, spawn policy, review policy, messaging constraints, severity response rules, coverage thresholds, and performance budgets. Edit this to tune the team for your project.

---

## Agent Roles

### Orchestration
- `lead.md` — The orchestrator and sole human-facing agent.
- `prioritiser.md` — Backlog priority management and sequencing advice.
- `product.pm.md` — Product requirements and acceptance criteria.

### Architecture
- `architect.principal.md` — Structural authority and architectural review.

### Implementation
- `implementer.backend.md` — Backend code implementation.
- `implementer.frontend.md` — Frontend code implementation.
- `implementer.platform.md` — Infrastructure and platform implementation.

### Review (by distinct lens)
- `reviewer.security.md` — Security vulnerabilities, data exposure, auth.
- `reviewer.correctness.md` — Business logic, edge cases, error handling.
- `reviewer.tests.md` — Test coverage, quality, regression testing.
- `reviewer.quality.md` — Readability, maintainability, design patterns.
- `reviewer.standards.md` — Coding conventions, API conventions, PR structure.
- `reviewer.logic.md` — Mechanical defects: off-by-ones, inverted operators, typos, dead code.

### Quality Assurance
- `qa.test-designer.md` — Test strategy and test plan design.
- `qa.test-writer.md` — Test implementation.

### Security
- `security.threat-modeler.md` — Threat modeling (STRIDE).
- `security.appsec-analyst.md` — Dependency auditing, configuration security.

### Specialist
- `debugger.md` — Root cause analysis and investigation.
- `perf.reliability.md` — Performance budgets, regression detection, reliability.
- `observability.md` — Logging, metrics, monitoring instrumentation.
- `docs.writer.md` — In-repo documentation: README files, architecture overviews, contributing guides.

### Generalist
- `generalist.md` — Bounded, self-contained odd jobs that do not require specialist expertise.

---

## Playbooks

Operational procedures for specific workflows.

- `lead.orchestration.md` — Master playbook for the Lead agent.
- `spawning-policy.md` — When and how to spawn agents.
- `parallelism-guide.md` — When to parallelize vs serialize work.
- `conflict-resolution.md` — How to resolve disagreements between agents.
- `code-review-policy.md` — Review assignment, process, lens separation, fatigue prevention.
- `qa-strategy.md` — Test strategy layers, coverage requirements, QA workflow.
- `security-policy.md` — Security review triggers, threat modeling, incident response.
- `debugging-playbook.md` — Systematic debugging process.
- `performance-playbook.md` — Performance budgets, regression detection, review triggers.
- `observability-playbook.md` — Observability requirements by change type, logging and metric standards.

---

## Standards

Engineering quality standards enforced by reviewers.

- `coding-standards.md` — SOLID, DRY, KISS, naming, function design, error handling, code organization.
- `architecture-standards.md` — Layered architecture, API design, data architecture, service boundaries, dependency management.
- `api-guidelines.md` — RESTful design, request/response standards, versioning, authentication, documentation.
- `testing-standards.md` — Coverage requirements, test types, test quality, test data.
- `security-standards.md` — Input validation, authentication, authorization, data protection, OWASP Top 10.
- `logging-and-metrics.md` — Structured logging, metric naming, alert readiness, prohibited logging.
- `pr-guidelines.md` — PR structure, size limits, commit hygiene, merge requirements.

---

## Getting Started

### For humans (using the framework)

1. Type `/agent-team` in any Claude Code session, or describe a multi-agent task — Claude invokes the skill automatically.
2. The Lead greets you with the 20 available roles and asks what you'd like to work on.
3. Describe your goal in plain language. The Lead handles everything else.

See `QUICKSTART.md` for installation instructions, examples, and customization options.

### For agents joining this team

1. Read `prime-directive.md` in full. It is the governance constitution and overrides all other files.
2. Read `agents/index.md`. It is the team registry and routing configuration.
3. Read your role file from `agents/roles/`.
4. Read the standards files required for your role (listed in `agents/index.md` Section 3.2).
5. Read any playbooks referenced in your role file.
6. Send a `READY` message to the Lead.
7. Wait for task assignment. Do not act until assigned.

---

## Enforcement

This system is not advisory. The Lead enforces compliance:

- Definition of Done must be fully verified before any task transitions to DONE.
- All required review gates must be passed before APPROVED.
- All MUST_FIX findings must be resolved before APPROVED.
- Tasks sent back to IN_PROGRESS more than 3 times are escalated to the human.

---

## Rule Precedence

When rules conflict, precedence is resolved top-down:

1. `prime-directive.md`
2. Standards files (`agents/standards/`)
3. Playbooks (`agents/playbooks/`)
4. Role files (`agents/roles/`)
5. Task definitions (`agents/tasks/`)

Higher-level rules always win. No exceptions.

---

## Versioning

This framework uses semantic versioning. The current schema version is `1.0.0`. Changes to message schema, lifecycle states, or severity definitions require a major version bump. New optional fields or new playbooks are minor version changes. Documentation clarifications are patch changes.
