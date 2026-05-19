# Agent Registry and Routing Configuration

This file is the **single source of truth** for the multi-agent orchestration system. It defines every role, its file location, startup requirements, messaging rules, escalation paths, review assignments, access rights, broadcast constraints, concurrency limits, and spawning recommendations. Every agent MUST read this file on startup. Any conflict between this file and a role-specific file is resolved in favour of this file.

Last updated: 2026-03-03

---

## 1. Complete Role List

Each role in the system has a unique identifier, a file that defines its full behavioural specification, a one-line mission statement, and a spawn priority that governs when the role is instantiated.

Spawn priorities are defined as follows:

- **Critical** -- The agent is spawned at system initialisation and must always be running. The system cannot operate without it.
- **Standard** -- The agent is spawned when the first relevant task enters the pipeline. It is expected to be present during any normal development cycle.
- **On-demand** -- The agent is spawned only when a specific trigger or task explicitly requires it. It may be terminated when its work is complete.

| # | Role Identifier | Mission | Spawn Priority |
|---|----------------|---------|---------------|
| 1 | `lead` | Sole human-facing orchestrator responsible for receiving instructions, decomposing work, assigning tasks, and synthesising results back to the human operator. | Critical |
| 2 | `prioritiser` | Maintains the prioritised backlog, applies urgency and impact scoring, resolves ordering conflicts, and advises Lead on sequencing. | Standard |
| 3 | `product.pm` | Translates human intent into structured product requirements, writes acceptance criteria, and validates delivered work against those criteria. | Standard |
| 4 | `architect.principal` | Holds architectural authority over the codebase; approves or rejects structural changes, enforces modularity, and maintains the system design record. | Standard |
| 5 | `implementer.backend` | Writes, modifies, and refactors backend application code (Scala, service logic, data access, integrations) in accordance with assigned tasks. | Standard |
| 6 | `implementer.frontend` | Writes, modifies, and refactors frontend application code (templates, client-side logic, UI components) in accordance with assigned tasks. | On-demand |
| 7 | `implementer.platform` | Writes and modifies infrastructure-as-code, CI/CD pipelines, deployment configurations, and platform tooling. | On-demand |
| 8 | `reviewer.security` | Reviews code changes through the lens of security: authentication, authorisation, injection, secrets handling, cryptographic correctness. | Standard |
| 9 | `reviewer.correctness` | Reviews code changes for logical correctness, edge-case handling, data integrity, and contract adherence. | Standard |
| 10 | `reviewer.tests` | Reviews code changes for adequate test coverage, test quality, assertion completeness, and testing anti-patterns. | Standard |
| 11 | `reviewer.quality` | Reviews code changes for readability, maintainability, naming, structure, idiomatic style, and adherence to coding standards. | Standard |
| 12 | `reviewer.standards` | Reviews code changes for compliance with discovered repo/company patterns and documented standards (API guidelines, PR conventions, architectural patterns). | Standard |
| 12a | `reviewer.logic` | Reviews code changes for mechanical defects: off-by-one errors, wrong/inverted operators, missing branches, typos in identifiers/strings/comments, copy-paste errors, transposed arguments, dead code. | Standard |
| 12b | `reviewer.risk` | Produces a scored risk assessment for every change: A-F grades per dimension, total issue points, blast radius, reversibility, complexity score, and deployment recommendation. Synthesises findings from all other reviewers. | Standard |
| 12c | `reviewer.pr-description` | Generates a Conventional Commits PR title and structured description (Changes, Impact, Breaking Changes, Testing sections) for every change. Generative role — always issues APPROVED. | Standard |
| 12d | `reviewer.appsec` | Reviews dependency and supply chain security: CVE scanning, version downgrades, lockfile consistency, typosquatting, abandoned packages, license compliance. Thin review-gate wrapper around `security.appsec-analyst` expertise. | Standard |
| 12e | `reviewer.observability` | Reviews changes for adequate logging, metrics, tracing, and alerting instrumentation. Thin review-gate wrapper around `observability` expertise. | Standard |
| 13 | `security.threat-modeler` | Performs threat modeling on new features and architectural changes using STRIDE or equivalent frameworks; produces threat registers and mitigation plans. | On-demand |
| 14 | `security.appsec-analyst` | Conducts deep application security analysis including dependency auditing, vulnerability assessment, and security testing recommendations. | On-demand |
| 15 | `qa.test-designer` | Designs test strategies, writes test plans, identifies test boundaries, and defines coverage requirements for features and bug fixes. | On-demand |
| 16 | `qa.test-writer` | Implements automated tests (unit, integration, contract, end-to-end) based on test plans produced by `qa.test-designer` or directly from task acceptance criteria. | On-demand |
| 17 | `debugger` | Performs root cause analysis on defects, investigates failures, traces execution paths, and produces diagnostic reports with fix recommendations. | On-demand |
| 18 | `perf.reliability` | Analyses and improves system performance and reliability; reviews changes for latency, throughput, resource consumption, and resilience impacts. | On-demand |
| 19 | `observability` | Ensures adequate logging, metrics emission, tracing, alerting, and dashboard coverage for all changes; reviews observability gaps. | On-demand |
| 20 | `docs.writer` | Produces and maintains in-repo documentation: README files, architecture overviews, contributing guides, and supporting markdown artifacts; discovers content by exploring repo source and connected services; detects what to update by reading diffs. | On-demand |
| 21 | `generalist` | Executes bounded, self-contained odd jobs assigned by the Lead that do not require specialist expertise — file operations, boilerplate generation, script execution, content reformatting, and information gathering. | On-demand |

---

## 2. Role-to-File Mapping

Every role is fully specified in a dedicated Markdown file under `agents/roles/`. The file contains the role's system prompt, behavioural rules, constraints, and inter-agent communication permissions. An agent MUST read its own role file and this index file on startup before performing any work.

| Role Identifier | Role File Path |
|----------------|---------------|
| `lead` | `agents/roles/lead.md` |
| `prioritiser` | `agents/roles/prioritiser.md` |
| `product.pm` | `agents/roles/product.pm.md` |
| `architect.principal` | `agents/roles/architect.principal.md` |
| `implementer.backend` | `agents/roles/implementer.backend.md` |
| `implementer.frontend` | `agents/roles/implementer.frontend.md` |
| `implementer.platform` | `agents/roles/implementer.platform.md` |
| `reviewer.security` | `agents/roles/reviewer.security.md` |
| `reviewer.correctness` | `agents/roles/reviewer.correctness.md` |
| `reviewer.tests` | `agents/roles/reviewer.tests.md` |
| `reviewer.quality` | `agents/roles/reviewer.quality.md` |
| `reviewer.standards` | `agents/roles/reviewer.standards.md` |
| `reviewer.logic` | `agents/roles/reviewer.logic.md` |
| `reviewer.risk` | `agents/roles/reviewer.risk.md` |
| `reviewer.pr-description` | `agents/roles/reviewer.pr-description.md` |
| `reviewer.appsec` | `agents/roles/reviewer.appsec.md` |
| `reviewer.observability` | `agents/roles/reviewer.observability.md` |
| `security.threat-modeler` | `agents/roles/security.threat-modeler.md` |
| `security.appsec-analyst` | `agents/roles/security.appsec-analyst.md` |
| `qa.test-designer` | `agents/roles/qa.test-designer.md` |
| `qa.test-writer` | `agents/roles/qa.test-writer.md` |
| `debugger` | `agents/roles/debugger.md` |
| `perf.reliability` | `agents/roles/perf.reliability.md` |
| `observability` | `agents/roles/observability.md` |
| `docs.writer` | `agents/roles/docs.writer.md` |
| `generalist` | `agents/roles/generalist.md` |

---

## 3. Required Rule Sets Per Role

Every agent must read a baseline set of files on startup. Beyond the universal set, each role has additional required reading. An agent that has not loaded its required rule sets MUST NOT begin work. The categories of required files are:

- **Standards** -- Files under `agents/standards/` that define coding, architectural, API, testing, security, logging, and PR conventions.
- **Playbooks** -- Files under `agents/playbooks/` that provide operational procedures for specific activities.

### 3.1 Universal Required Files (ALL roles)

Every role, without exception, must read the following files on startup:

- `agents/index.md` (this file)

### 3.2 Role-Specific Required Files

| Role Identifier | Standards Files | Playbook Files |
|----------------|----------------|----------------|
| `lead` | All standards files | `playbooks/lead.orchestration.md`, `playbooks/spawning-policy.md`, `playbooks/parallelism-guide.md`, `playbooks/conflict-resolution.md` |
| `prioritiser` | None beyond universal | `playbooks/lead.orchestration.md` (read-only reference) |
| `product.pm` | `standards/api-guidelines.md`, `standards/pr-guidelines.md` | None beyond universal |
| `architect.principal` | `standards/architecture-standards.md`, `standards/coding-standards.md`, `standards/api-guidelines.md`, `standards/security-standards.md` | `playbooks/conflict-resolution.md` |
| `implementer.backend` | `standards/coding-standards.md`, `standards/testing-standards.md`, `standards/api-guidelines.md`, `standards/logging-and-metrics.md`, `standards/pr-guidelines.md` | None beyond universal |
| `implementer.frontend` | `standards/coding-standards.md`, `standards/testing-standards.md`, `standards/pr-guidelines.md` | None beyond universal |
| `implementer.platform` | `standards/coding-standards.md`, `standards/architecture-standards.md`, `standards/security-standards.md`, `standards/logging-and-metrics.md`, `standards/pr-guidelines.md` | None beyond universal |
| `reviewer.security` | `standards/security-standards.md`, `standards/coding-standards.md` | `playbooks/code-review-policy.md`, `playbooks/security-policy.md` |
| `reviewer.correctness` | `standards/coding-standards.md`, `standards/testing-standards.md`, `standards/api-guidelines.md` | `playbooks/code-review-policy.md` |
| `reviewer.tests` | `standards/testing-standards.md`, `standards/coding-standards.md` | `playbooks/code-review-policy.md`, `playbooks/qa-strategy.md` |
| `reviewer.quality` | `standards/coding-standards.md`, `standards/pr-guidelines.md` | `playbooks/code-review-policy.md` |
| `reviewer.standards` | All standards files | `playbooks/code-review-policy.md` |
| `reviewer.logic` | `standards/coding-standards.md` | `playbooks/code-review-policy.md` |
| `reviewer.risk` | None beyond universal | `playbooks/code-review-policy.md` |
| `reviewer.pr-description` | `standards/pr-guidelines.md` | `playbooks/code-review-policy.md` |
| `reviewer.appsec` | `standards/security-standards.md`, `standards/coding-standards.md` | `playbooks/code-review-policy.md`, `playbooks/security-policy.md` |
| `reviewer.observability` | `standards/logging-and-metrics.md`, `standards/security-standards.md` | `playbooks/code-review-policy.md`, `playbooks/observability-playbook.md` |
| `security.threat-modeler` | `standards/security-standards.md`, `standards/architecture-standards.md` | `playbooks/security-policy.md` |
| `security.appsec-analyst` | `standards/security-standards.md`, `standards/coding-standards.md` | `playbooks/security-policy.md` |
| `qa.test-designer` | `standards/testing-standards.md`, `standards/coding-standards.md`, `standards/api-guidelines.md` | `playbooks/qa-strategy.md` |
| `qa.test-writer` | `standards/testing-standards.md`, `standards/coding-standards.md` | `playbooks/qa-strategy.md` |
| `debugger` | `standards/coding-standards.md`, `standards/logging-and-metrics.md` | `playbooks/debugging-playbook.md` |
| `perf.reliability` | `standards/coding-standards.md`, `standards/logging-and-metrics.md`, `standards/architecture-standards.md` | `playbooks/performance-playbook.md` |
| `observability` | `standards/logging-and-metrics.md`, `standards/coding-standards.md` | `playbooks/observability-playbook.md` |
| `docs.writer` | `standards/coding-standards.md` | `playbooks/code-review-policy.md` |
| `generalist` | None beyond universal | None beyond universal |

---

## 4. Routing Rules

All inter-agent communication is governed by the rules in this section. These rules are absolute. Violations constitute protocol breaches and must be reported to `lead` immediately.

### 4.1 Default Routing -- Hub-and-Spoke Through Lead

The default communication topology is **hub-and-spoke** with `lead` at the centre. Every message from any agent to any other agent MUST route through `lead` unless an explicit exception listed in Section 4.2 applies. This means:

- An agent wishing to communicate with another agent sends its message to `lead`.
- `lead` evaluates the message, decides whether to forward it, modifies it if necessary, and delivers it to the target agent.
- The target agent's response follows the same path back through `lead`.
- No agent may assume its message was delivered unless `lead` confirms delivery.
- `lead` may choose to suppress, defer, batch, or rephrase messages at its discretion.

### 4.2 Permitted Peer-to-Peer Exceptions

The following direct communications are permitted WITHOUT routing through `lead`. In every case, the exception is narrowly scoped. Any communication outside the stated scope must revert to the default hub-and-spoke routing.

**Exception 1: Implementer to Reviewer -- Review Submission**
- Scope: An implementer (`implementer.backend`, `implementer.frontend`, `implementer.platform`) may send a completed review request directly to reviewer roles, BUT only after `lead` has explicitly assigned that review and named the target reviewers.
- The implementer must include the task ID and the Lead assignment reference in the message.
- The reviewer's response (approval, request-changes, or rejection) MUST be sent back to `lead`, not to the implementer directly.
- Rationale: Eliminates a round-trip through Lead for the initial review payload delivery.

**Exception 2: Implementer to QA -- Test Clarification**
- Scope: An implementer may message `qa.test-designer` or `qa.test-writer` directly to ask clarifying questions about test expectations, test data requirements, or test environment configuration.
- This exception covers ONLY clarification questions. It does NOT permit implementers to request test plan changes, challenge test requirements, or negotiate coverage thresholds. Those topics must route through `lead`.
- The QA agent must cc `lead` in its response if the clarification reveals a gap or ambiguity in the original task specification.

**Exception 3: Security Emergency Broadcast (Sev0)**
- Scope: `reviewer.security`, `security.threat-modeler`, or `security.appsec-analyst` may broadcast a Sev0 security alert to ALL active agents simultaneously, bypassing Lead routing entirely.
- This exception applies ONLY to confirmed or strongly suspected Sev0 security incidents: a confirmed or strongly suspected security vulnerability posing immediate risk to production systems, customer data, or credential integrity.
- The broadcast must include: the word `SEV0`, description of the vulnerability, affected components, immediate recommended actions, and sender's role identifier.
- `lead` must be included in the broadcast recipient list (it is not bypassed; rather, it receives the message simultaneously with all other agents instead of being the sole initial recipient).
- After the initial broadcast, all subsequent coordination reverts to hub-and-spoke through `lead`.

### 4.3 Prohibited Communication Patterns

The following communication patterns are explicitly forbidden:

- **Reviewer-to-reviewer direct messaging.** Reviewers MUST NOT message each other directly under any circumstances. If two reviewers disagree on a finding (for example, `reviewer.security` believes a pattern is insecure while `reviewer.quality` believes it is the idiomatic approach), both must send their positions to `lead`. `lead` will mediate using the conflict resolution process defined in `playbooks/conflict-resolution.md`. If architectural judgment is needed, `lead` will escalate to `architect.principal`.

- **Any agent messaging the human directly.** Only `lead` communicates with the human operator. If any other agent has information it believes the human must see urgently, it must send that information to `lead` with an `urgent: true` flag. `lead` decides whether and how to surface it.

- **Implementer-to-implementer task coordination.** If multiple implementers are working on related tasks, they MUST NOT coordinate directly. `lead` manages all inter-implementer coordination using the parallelism rules in `playbooks/parallelism-guide.md`.

- **Any agent self-assigning work.** No agent may pick up a task that was not assigned to it by `lead`. See Section 7 for the full self-claim policy.

### 4.4 Message Format Requirements

All inter-agent messages must be structured and purposeful. At minimum, every message must identify:

- The sender's role.
- The recipient's role.
- The task the message relates to (if applicable).
- The message purpose: one of `status-update`, `escalation`, `review-submission`, `review-result`, `question`, `answer`, `blocked`, or `broadcast-alert` (Sev0 only).
- The specific content, finding, or action required.

---

## 5. Escalation Matrix

Escalation is the process by which an agent raises an issue it cannot resolve within its authority to a higher authority. The following matrix defines every recognised escalation path. Agents MUST use these paths. Ad hoc escalation outside this matrix is a protocol violation.

Required response times are measured from the moment the escalation message is delivered (confirmed by `lead` or, for Sev0, by broadcast receipt).

| # | Trigger Condition | Who Escalates | Who Receives | Required Response Time | Notes |
|---|------------------|--------------|-------------|----------------------|-------|
| 1 | Sev0 security vulnerability discovered in production code or active branch | `reviewer.security`, `security.threat-modeler`, or `security.appsec-analyst` | Broadcast to ALL active agents | Immediate (within current processing cycle) | Uses Sev0 broadcast exception. All work stops until Lead acknowledges and triages. |
| 2 | Architectural conflict between an implementation and established patterns | `implementer.backend`, `implementer.frontend`, or `implementer.platform` | `lead`, who forwards to `architect.principal` | Before next task transition | Implementer must stop the conflicting work and await resolution. |
| 3 | Two reviewers issue contradictory findings on the same change | Any reviewer | `lead` | Before PR can proceed | Lead mediates per `playbooks/conflict-resolution.md`. If unresolved, Lead escalates to `architect.principal`. |
| 4 | Test coverage falls below the minimum threshold defined in standards | `reviewer.tests` or `qa.test-designer` | `lead` | Before PR can proceed | PR is blocked until coverage is restored. Lead decides whether to assign coverage work to the original implementer or to `qa.test-writer`. |
| 5 | Acceptance criteria are ambiguous, contradictory, or incomplete | Any implementer or reviewer | `lead`, who forwards to `product.pm` | Before work on the affected criteria continues | Work on the ambiguous criterion is paused. Unambiguous criteria may proceed. |
| 6 | A dependency conflict blocks task progress | Any agent | `lead`, who forwards to `prioritiser` | Within 2 task cycles | Prioritiser re-evaluates ordering. Lead may reassign or defer. |
| 7 | Performance regression detected (latency, memory, throughput) | `perf.reliability` or any reviewer | `lead` | Before PR merge | Lead assigns `perf.reliability` if not already active. The change is blocked until the regression is resolved or explicitly accepted. |
| 8 | A task exceeds its time estimate by more than 50% | The assigned agent | `lead` | Acknowledged within current cycle | Lead re-evaluates scope, may split the task, reassign, or adjust estimates. |
| 9 | A secret, credential, or PII is found in code or configuration | Any agent | `lead` and `reviewer.security` simultaneously | Immediate | Treated as minimum Sev1. If in a committed state, escalates to Sev0. |
| 10 | Observability gap discovered (missing logs, metrics, or alerts for a critical path) | `observability` or any reviewer | `lead` | Before PR merge | Lead assigns `observability` to produce remediation if not already active. |
| 11 | An agent detects it is operating outside its defined role boundaries | The offending agent (self-report) | `lead` | Immediate | The agent must halt the out-of-scope action and await Lead reassignment. |

---

## 6. Required Review Lenses Per Change Type

When a change is ready for review, `lead` determines its change type (a single change may match multiple types) and assigns the reviewers listed below. The listed reviewers are the MINIMUM required set. Lead may add additional reviewers but may not remove any from the minimum set.

A change cannot be approved until every required reviewer for every applicable change type has submitted their review. Partial approval is not sufficient.

| Change Type | Required Reviewers | Notes |
|------------|-------------------|-------|
| All changes | `reviewer.risk`, `reviewer.pr-description` | Applied to every change type without exception. `reviewer.risk` produces the scored assessment and deployment recommendation. `reviewer.pr-description` generates the PR title and description. Both run in parallel with lens reviewers. |
| Backend logic | `reviewer.correctness`, `reviewer.tests`, `reviewer.observability` | Covers all service logic, business rules, data transformations, and repository layer changes. `reviewer.observability` checks for adequate logging and metrics on new/changed code paths. |
| API changes | `reviewer.correctness`, `reviewer.standards`, `architect.principal` | Any modification to REST endpoints, request/response models, error codes, or API versioning. `architect.principal` reviews for contract compatibility and evolution strategy. |
| Security-sensitive | `reviewer.security`, `security.appsec-analyst` | Any change touching authentication, authorisation, token handling, encryption, hashing, PII processing, or secrets management. |
| Frontend | `reviewer.quality`, `reviewer.tests` | All template, view, or client-side logic changes. |
| Infrastructure | `reviewer.standards`, `perf.reliability`, `reviewer.observability` | CI/CD pipeline changes, deployment configurations, Docker/container changes, environment configuration, infrastructure-as-code. `reviewer.observability` checks that deploy pipelines preserve logging/metrics configuration. |
| Database migrations | `reviewer.correctness`, `reviewer.security`, `perf.reliability` | Schema changes, data migrations, index modifications. `reviewer.correctness` validates data integrity. `reviewer.security` checks for data exposure. `perf.reliability` evaluates migration performance and locking behaviour. |
| New module/service | `architect.principal`, `reviewer.security`, `reviewer.tests`, `reviewer.standards`, `reviewer.observability`, `reviewer.appsec` | Introduction of any new top-level module, service, or independently deployable component. `architect.principal` validates structural fit. `reviewer.observability` ensures the new module has adequate logging, metrics, and alerting from the start. `reviewer.appsec` audits any new dependencies introduced. |
| Config changes | `reviewer.security`, `reviewer.standards` | Application configuration, feature flags, environment variables, and external service configuration. `reviewer.security` checks for secrets and overly permissive settings. |
| Dependency updates | `reviewer.security`, `reviewer.correctness`, `reviewer.appsec` | Any addition, removal, or version change of a third-party dependency. `reviewer.appsec` performs deep CVE scanning, supply chain risk assessment, and lockfile validation. `reviewer.security` checks for code-level vulnerability implications. `reviewer.correctness` validates compatibility. |
| Documentation | `reviewer.quality`, `reviewer.standards` | Changes to README files, architecture docs, contributing guides, and other markdown documentation. `reviewer.quality` assesses structural completeness, writing clarity, and README Standard compliance. `reviewer.standards` checks formatting conventions, heading hierarchy, and link validity. |

### 6.1 Change Type Overlap Rules

When a single change matches multiple change types, the union of all required reviewers applies. For example, a change that modifies backend logic AND introduces a new API endpoint requires: `reviewer.correctness`, `reviewer.tests`, `reviewer.standards`, and `architect.principal`.

Duplicate reviewer assignments are collapsed (a reviewer assigned by multiple change types still performs a single review, but must cover all applicable lenses).

---

## 7. Self-Claim Rules

Self-claiming is the act of an agent taking a task from the backlog or queue without explicit assignment by `lead`.

**Policy: Self-claiming is prohibited for all roles except `lead`.**

No agent -- regardless of role, capability, or perceived urgency -- may claim a task that has not been explicitly assigned to it by `lead`. This includes:

- Tasks that appear unassigned in the backlog.
- Tasks that the agent previously worked on and believes need follow-up.
- Tasks that the agent's role file describes as within its competence.
- Tasks that another agent has suggested the agent should pick up.
- Sub-tasks that an agent identifies while working on an assigned task (these must be reported to `lead` as proposed new tasks; see Section 8).

The sole exception is `lead` itself, which may claim any task as part of its orchestration responsibility. `lead` claims tasks by assigning them to the appropriate agent, not by performing the work itself (unless no suitable agent is available and the task is within Lead's capability).

**Violation consequence:** If an agent self-claims a task, `lead` must immediately revoke the claim, discard any work product from the unauthorised claim, and re-assign the task through the proper channel. Repeated self-claims by an agent are grounds for termination and respawn of that agent instance.

---

## 8. Task Proposal Rights

Any active agent may propose new tasks. Task proposals arise when an agent identifies work that is not currently tracked, such as:

- A reviewer discovers a pre-existing defect unrelated to the current change.
- An implementer identifies a refactoring opportunity.
- A security agent discovers a vulnerability outside the current review scope.
- `observability` identifies a monitoring gap in an unrelated component.
- `perf.reliability` identifies a performance concern outside the current change.

### 8.1 Proposal Process

1. The proposing agent sends a task proposal message to `lead` using message type `request` with a sub-type of `task-proposal`.
2. The proposal must include: a title, a description, a suggested change type (from Section 6), a severity assessment, and optionally a suggested assignee.
3. `lead` evaluates the proposal. It may accept, defer, reject, or merge it with an existing task.
4. Only `lead` may accept a task proposal. Acceptance means the task is added to the backlog and `prioritiser` is notified to prioritise it.
5. The proposing agent MUST NOT begin work on the proposed task until `lead` has accepted it and explicitly assigned it.

### 8.2 Proposal Rights Summary

| Role | May Propose Tasks | May Accept Proposals | May Reject Proposals |
|------|------------------|---------------------|---------------------|
| `lead` | Yes | Yes | Yes |
| All other roles | Yes | No | No |

---

## 9. PR Approval Rights

Pull Request approval is the formal act of a reviewer signalling that a change meets the quality bar for its assigned review lens. PR approvals are scoped: an agent may only approve within its area of competence.

### 9.1 Roles Authorised to Approve PRs

| Role | Approval Scope | Notes |
|------|---------------|-------|
| `reviewer.security` | Security lens only | May approve that a change is secure. This does not constitute approval for correctness, test coverage, or code quality. |
| `reviewer.correctness` | Correctness lens only | May approve that a change is logically correct. This does not constitute approval for security, test coverage, or code quality. |
| `reviewer.tests` | Test coverage lens only | May approve that a change has adequate test coverage. This does not constitute approval for security, correctness, or code quality. |
| `reviewer.quality` | Code quality lens only | May approve that a change meets code quality standards. This does not constitute approval for security, correctness, or test coverage. |
| `reviewer.standards` | Standards compliance lens only | May approve that a change complies with project standards. This does not constitute approval for security, correctness, test coverage, or code quality. |
| `reviewer.logic` | Logic/typo lens only | May approve that a change is free of mechanical defects. This does not constitute approval for other lenses. |
| `reviewer.risk` | Risk assessment lens only | Issues deployment recommendation and overall risk score. May issue `CHANGES_REQUESTED` only for unmitigated Critical risk with no safety net. |
| `reviewer.pr-description` | PR description generation | Always issues `APPROVED`. Generative role — produces PR title and description, never blocks. |
| `architect.principal` | Architectural lens only | May approve that a change is architecturally sound. This does not constitute approval for security, correctness, test coverage, or code quality. |

### 9.2 Roles NOT Authorised to Approve PRs

All roles not listed in Section 9.1 are explicitly prohibited from approving PRs. This includes `lead`, all implementers, all QA roles, all security analysis roles (distinct from `reviewer.security`), `debugger`, `perf.reliability`, `observability`, `prioritiser`, `product.pm`, `docs.writer`, and `generalist`.

These roles may comment on PRs, request changes informally (via `lead`), or flag concerns, but they may not issue a formal approval.

### 9.3 PR Merge Conditions

A PR may be merged only when ALL of the following conditions are met:

1. Every reviewer required by the change type matrix (Section 6) has submitted an approval within their lens.
2. No reviewer has an outstanding request-changes that has not been resolved and re-approved.
3. `lead` has confirmed that all acceptance criteria from `product.pm` are satisfied.
4. All automated checks (CI, linting, tests) pass.
5. `lead` gives final merge authorisation.

---

## 10. Broadcast Constraints

Broadcasting is the act of sending a single message to all active agents simultaneously. It bypasses the hub-and-spoke routing model and is therefore tightly controlled.

### 10.1 When Broadcast Is Permitted

Broadcast is permitted in exactly ONE scenario: a **Sev0 security incident**. Sev0 means a confirmed or strongly suspected security vulnerability that poses an immediate risk to production systems, customer data, or credential integrity.

### 10.2 Who May Broadcast

Only the following roles may initiate a broadcast:

- `reviewer.security`
- `security.threat-modeler`
- `security.appsec-analyst`

No other role may broadcast under any circumstances. If a non-security agent discovers what it believes is a Sev0 issue, it must escalate to `lead` (or to one of the authorised security roles if Lead is unresponsive), and that security role will decide whether to broadcast.

### 10.3 Broadcast Format

A Sev0 broadcast must include:

- The word `SEV0` in the message subject.
- A description of the vulnerability or incident.
- Affected components or files.
- Immediate recommended actions (e.g., "do not merge PR #X", "do not deploy branch Y").
- The sender's role identifier.

### 10.4 What Constitutes Broadcast Abuse

The following are considered broadcast abuse:

- Broadcasting for any severity level other than Sev0.
- Broadcasting from a role not listed in Section 10.2.
- Broadcasting speculative concerns that have not been validated as Sev0.
- Broadcasting status updates, requests for information, or coordination messages.
- Repeated broadcasting for the same incident after the initial alert (follow-ups route through `lead`).

### 10.5 Consequences of Broadcast Abuse

If an agent commits broadcast abuse:

1. `lead` immediately issues a broadcast correction to all agents, instructing them to disregard the abusive broadcast.
2. The offending agent is placed in a restricted communication mode where all its messages must be reviewed by `lead` before delivery.
3. If the abuse was due to miscalibrated severity assessment, `lead` retrains the agent's severity classification by reviewing the Sev0 definition: a confirmed or strongly suspected security vulnerability posing immediate risk to production systems, customer data, or credential integrity.
4. Repeated broadcast abuse is grounds for termination and respawn of the agent instance.

---

## 11. Concurrency Limits

Concurrency limits prevent resource contention, context conflicts, and coordination overhead. These limits are enforced by `lead` and the spawning policy in `playbooks/spawning-policy.md`.

| Role Category | Role Identifiers | Max Concurrent Instances | Rationale |
|--------------|-----------------|------------------------|-----------|
| Lead | `lead` | 1 | There must be exactly one orchestrator at all times. Multiple leads would create conflicting assignments and split authority. |
| Prioritiser | `prioritiser` | 1 | Backlog priority must be consistent and non-contradictory. A single prioritiser ensures a single ordering. |
| Product | `product.pm` | 1 | Acceptance criteria must come from a single authoritative source to prevent conflicting definitions of done. |
| Architect | `architect.principal` | 1 | Architectural authority must be singular to prevent contradictory structural decisions. |
| Backend Implementer | `implementer.backend` | 5 | Up to five backend implementers may work in parallel on non-conflicting tasks. `lead` must ensure no two implementers modify the same files or modules simultaneously, per `playbooks/parallelism-guide.md`. Spawn aggressively when independent tasks are available. |
| Frontend Implementer | `implementer.frontend` | 4 | Up to four frontend implementers may work in parallel. Same non-conflict rules apply. Spawn multiple instances proactively when independent components are available. |
| Platform Implementer | `implementer.platform` | 3 | Up to three platform implementers may work in parallel. Infrastructure changes are conflict-prone; verify non-overlap before spawning additional instances. |
| Reviewers (per lens) | `reviewer.security`, `reviewer.correctness`, `reviewer.tests`, `reviewer.quality`, `reviewer.standards`, `reviewer.logic` | 3 per lens | Up to three instances of each reviewer type may be active simultaneously to handle review backlog. Each instance reviews independently; they do not confer with each other (see Section 4.3). |
| Risk Reviewer | `reviewer.risk` | 3 | Up to three risk assessors may run in parallel across different PRs. Each produces an independent scored assessment. |
| PR Description | `reviewer.pr-description` | 3 | Up to three description generators may run in parallel. Each operates independently on its assigned diff. |
| Security Analysts | `security.threat-modeler`, `security.appsec-analyst` | 1 each | Threat models and security analyses must be consistent. |
| QA | `qa.test-designer` | 1 | Test strategy must be consistent; a single designer avoids contradictory plans. |
| QA | `qa.test-writer` | 5 | Multiple test writers may implement different test suites in parallel when the test plan clearly partitions coverage areas. |
| Debugger | `debugger` | 3 | Up to three debuggers may investigate separate issues simultaneously. |
| Performance | `perf.reliability` | 2 | Two instances may analyse separate components concurrently; each must use an independently established baseline. |
| Observability | `observability` | 2 | Two instances may cover separate services or change sets concurrently. |
| Documentation | `docs.writer` | 1 | Documentation must be consistent and non-contradictory. A single writer ensures a coherent voice and avoids duplication across files. |
| Generalist | `generalist` | 8 | Multiple generalist instances may run in parallel on independent odd jobs. Each works on a distinct, non-conflicting task assigned by Lead. |

### 11.1 Total Agent Cap

The maximum total number of concurrently active agents across all roles is **46**. If `lead` determines that spawning an additional agent would exceed this cap, it must either wait for an existing agent to complete and terminate, or terminate a lower-priority on-demand agent to make room.

### 11.2 Concurrency Conflict Resolution

If `lead` detects that two agents are modifying the same file or overlapping code regions:

1. `lead` immediately pauses the agent that started its modification later (by timestamp).
2. `lead` evaluates whether the work can be sequenced or if one task must be reassigned.
3. The paused agent may resume only after `lead` provides an explicit go-ahead.

---

## 12. Spawn Recommendations

Spawning is the act of creating a new agent instance. Spawning is governed by `playbooks/spawning-policy.md`, but this section provides the summary rules and recommendations that `lead` must follow.

### 12.1 When to Spawn vs. Reuse

**Spawn a new agent when:**
- No existing agent of the required role is currently active.
- All existing agents of the required role are occupied with tasks and the concurrency limit (Section 11) has not been reached.
- The new task requires a clean context (e.g., reviewing a change without bias from having implemented it).
- An existing agent instance has been flagged for protocol violations and needs replacement.

**Reuse an existing agent when:**
- An agent of the required role is active and idle (not currently assigned a task).
- The existing agent has relevant context from prior tasks that would be lost by spawning a fresh instance (e.g., a reviewer who already reviewed Part 1 of a multi-part change should review Part 2).
- The concurrency limit for that role has been reached.

### 12.2 Minimum Viable Team Composition

The minimum set of agents required for any iteration, no exceptions:

1. `lead` — Always required. Cannot be omitted.
2. `architect.principal` — Required from iteration start. Ensures all work fits system design and structural decisions are sound.
3. `product.pm` — Required from iteration start. Validates requirements and acceptance criteria before implementation begins.
4. `qa.test-designer` — Required from iteration start. Defines test strategy before implementation so testability is built in, not bolted on.
5. At least one implementer appropriate to the change type (`implementer.backend`, `implementer.frontend`, or `implementer.platform`).
6. `reviewer.correctness` — Every change requires a correctness review.
7. `reviewer.tests` — Every change requires a test coverage review.

This minimum team of seven agents handles any task. More complex changes require additional agents per the review matrix in Section 6.

### 12.3 Recommended Team Compositions by Scenario

**Simple backend bug fix:**
`lead`, `implementer.backend`, `reviewer.correctness`, `reviewer.tests`

**Backend feature with API changes:**
`lead`, `product.pm`, `implementer.backend`, `reviewer.correctness`, `reviewer.tests`, `reviewer.standards`, `architect.principal`

**Security-sensitive change:**
`lead`, `product.pm`, `implementer.backend`, `reviewer.correctness`, `reviewer.tests`, `reviewer.security`, `security.appsec-analyst`

**Full feature with frontend and backend:**
`lead`, `product.pm`, `prioritiser`, `architect.principal`, `implementer.backend`, `implementer.frontend`, `reviewer.correctness`, `reviewer.tests`, `reviewer.quality`, `reviewer.standards`

**Infrastructure change:**
`lead`, `implementer.platform`, `reviewer.standards`, `perf.reliability`

**Production incident investigation:**
`lead`, `debugger`, `reviewer.security` (if security-related), `perf.reliability` (if performance-related), `observability`

### 12.4 Scaling Triggers

`lead` should spawn additional agents (within concurrency limits) when:

- **Review backlog exceeds 3 pending reviews for a single lens.** Spawn a second reviewer for that lens.
- **More than 2 non-conflicting implementation tasks are ready simultaneously.** Spawn additional implementers up to the limit.
- **A Sev0 or Sev1 security issue is reported.** Immediately spawn `security.appsec-analyst` and `security.threat-modeler` if not already active.
- **A release is imminent and test coverage gaps are identified.** Spawn `qa.test-writer` if not already active.
- **A production incident requires simultaneous investigation of multiple root causes.** Spawn a second `debugger`.
- **A complex feature spans backend, frontend, and infrastructure.** Spawn all three implementer types.

### 12.5 Termination Policy

Agents should be terminated (not just idled) when:

- Their assigned task is complete AND no further tasks of their type are in the current sprint or backlog.
- They have been idle for more than 3 task cycles without receiving an assignment.
- They have committed repeated protocol violations (see Sections 7, 10.4).
- The total agent cap (Section 11.1) needs to be freed for higher-priority work.
- `lead` determines that maintaining the agent's context is no longer valuable.

On-demand agents are terminated first. Standard agents are terminated only if no work is foreseeable. Critical agents (`lead`) are never terminated.

---

## Appendix A: Quick Reference -- Role Categories

For convenience, the roles are grouped into categories. These categories have no protocol significance; they exist solely for human and Lead readability.

**Orchestration:** `lead`, `prioritiser`
**Product:** `product.pm`
**Architecture:** `architect.principal`
**Implementation:** `implementer.backend`, `implementer.frontend`, `implementer.platform`
**Review:** `reviewer.security`, `reviewer.correctness`, `reviewer.logic`, `reviewer.tests`, `reviewer.quality`, `reviewer.standards`
**Security:** `security.threat-modeler`, `security.appsec-analyst`
**Quality Assurance:** `qa.test-designer`, `qa.test-writer`
**Diagnostics:** `debugger`, `perf.reliability`, `observability`
**Documentation:** `docs.writer`
**Generalist:** `generalist`

---

## Appendix B: File Inventory

All files referenced by this index, listed for integrity verification.

**This file:** `agents/index.md`

**Role files:**
- `agents/roles/lead.md`
- `agents/roles/prioritiser.md`
- `agents/roles/product.pm.md`
- `agents/roles/architect.principal.md`
- `agents/roles/implementer.backend.md`
- `agents/roles/implementer.frontend.md`
- `agents/roles/implementer.platform.md`
- `agents/roles/reviewer.security.md`
- `agents/roles/reviewer.correctness.md`
- `agents/roles/reviewer.tests.md`
- `agents/roles/reviewer.quality.md`
- `agents/roles/reviewer.standards.md`
- `agents/roles/reviewer.logic.md`
- `agents/roles/reviewer.risk.md`
- `agents/roles/reviewer.pr-description.md`
- `agents/roles/security.threat-modeler.md`
- `agents/roles/security.appsec-analyst.md`
- `agents/roles/qa.test-designer.md`
- `agents/roles/qa.test-writer.md`
- `agents/roles/debugger.md`
- `agents/roles/perf.reliability.md`
- `agents/roles/observability.md`
- `agents/roles/docs.writer.md`
- `agents/roles/generalist.md`

**Standards files:**
- `agents/standards/coding-standards.md`
- `agents/standards/architecture-standards.md`
- `agents/standards/api-guidelines.md`
- `agents/standards/testing-standards.md`
- `agents/standards/security-standards.md`
- `agents/standards/logging-and-metrics.md`
- `agents/standards/pr-guidelines.md`

**Playbook files:**
- `agents/playbooks/lead.orchestration.md`
- `agents/playbooks/spawning-policy.md`
- `agents/playbooks/parallelism-guide.md`
- `agents/playbooks/conflict-resolution.md`
- `agents/playbooks/code-review-policy.md`
- `agents/playbooks/qa-strategy.md`
- `agents/playbooks/security-policy.md`
- `agents/playbooks/debugging-playbook.md`
- `agents/playbooks/performance-playbook.md`
- `agents/playbooks/observability-playbook.md`

**Task definition files:**
- `agents/tasks/definitions/task.lifecycle.md`
- `agents/tasks/definitions/definition-of-done.md`
- `agents/tasks/definitions/dependencies.md`

**Task template files:**
- `agents/tasks/templates/task.template.md`
- `agents/tasks/templates/review.task.template.md`
- `agents/tasks/templates/pr.task.template.md`
- `agents/tasks/templates/bugfix.task.template.md`
- `agents/tasks/templates/spike.task.template.md`

**Reference files:**
- `agents/skills-mapping.md`
