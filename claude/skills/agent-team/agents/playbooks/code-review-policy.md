# Code Review Policy

## 0. Pre-Review — JIRA Context Fetch (GitHub PRs)

When the review target is a GitHub PR link, **before assigning reviewers**:

1. Fetch the PR title and description using `gh pr view <number> --json title,body`.
2. Scan the title and body for JIRA ticket references — these may appear as:
   - A ticket number pattern (e.g. `IPE-1234`, `CC-567`, `MPS-89`)
   - A full JIRA URL (e.g. `https://jira.corp.creditkarma.com/browse/IPE-1234`)
3. If one or more JIRA tickets are found, invoke the `/ck-jira` skill to fetch each ticket's details (summary, description, acceptance criteria, linked tickets).
4. Include the fetched JIRA context in every reviewer's spawn prompt under a **"JIRA Context"** section so reviewers can evaluate the change against the stated requirements and acceptance criteria.
5. If no JIRA reference is found, log a `STATUS_UPDATE` noting the absence and proceed without it.

This step is **mandatory** when reviewing a GitHub PR. Do not skip it or defer it — reviewers without JIRA context may miss requirement-level issues.

---

## 0.5. Pre-Review — Clone the PR to `/tmp` (GitHub PRs)

When the review target is a GitHub PR, **before assigning reviewers**, the Lead clones the PR into a fresh disposable directory under `/tmp` and points every reviewer at that path.

1. Pick a unique directory name (e.g. `/tmp/pr<number>-review/repo`) — never reuse an existing path. If the parent (e.g. `/tmp/pr<number>-review`) exists from a prior session, rename or remove it first.
2. Clone the PR's head branch shallowly: `gh repo clone <owner>/<repo> /tmp/pr<number>-review/repo -- --depth 50 --branch <head-ref>`.
3. Fetch `main` (or the PR's base ref) into the clone so reviewers can diff against it: `git -C /tmp/pr<number>-review/repo fetch origin <base-ref>:<base-ref>`.
4. Pass the absolute clone path to every reviewer's spawn prompt under a **"Cloned PR location"** section. Reviewers MUST read from this path, not from the user's working copy.
5. **After all reviews complete and the synthesis is delivered to the human**, the Lead removes the clone: `rm -rf /tmp/pr<number>-review`. Cleanup is part of the Lead's workflow, not optional.

*Why:* the user's working copy may be on a different branch, mid-edit, or in a worktree the reviewers shouldn't touch. A throwaway clone gives every reviewer the same authoritative tree to read against, isolates the review from the user's in-flight work, and the `/tmp` location makes the disposability obvious. Per-session `/tmp` directories also avoid clobbering parallel review jobs.

*Skip conditions:* the target is a local branch / worktree (not a GitHub PR URL), OR the user explicitly specifies a different review root.

---

## 1. Review Assignment

Determine required reviewers from the change type matrix in `index.md §5`. Union reviewers when a change matches multiple types. Assign all reviewers simultaneously — reviews run in parallel.

Workload limit: max 5 active review tasks per reviewer. If at 5, defer unless the new review is P0/P1.

## 2. Review Flow

1. Implementer sends `TASK_DONE` → Lead creates review tasks → reviewers work in parallel.
2. Fan-in: Lead collects all `REVIEW_RESULT` messages.
   - All `APPROVED` → task moves to `APPROVED`.
   - Any `BLOCKED` → escalate immediately.
   - Any `CHANGES_REQUESTED` → compile ALL findings into one consolidated message to the implementer.
3. Implementer addresses findings → sends `TASK_DONE` again → new review cycle begins.
4. **Max 3 review cycles.** After the third, Lead MUST intervene: diagnose the disconnect (partial fixes? new findings each cycle? fundamental disagreement?), then: reassign, split the task, invoke conflict resolution, or escalate to human.

## 3. Lens Definitions

Each reviewer covers ONLY their assigned lens. Out-of-lens observations go to Lead via STATUS_UPDATE, not into REVIEW_RESULT.

**`reviewer.security`** — Auth/authz, injection (XSS, CSRF, SSRF, SQLi, path traversal), PII in logs, secrets in code, cryptographic correctness, input validation, dependency CVEs.
NOT in scope: business logic, test coverage, readability.

**`reviewer.correctness`** — Business logic vs. requirements, edge cases (null, empty, boundaries, concurrency), error handling, data integrity, contract adherence.
NOT in scope: security, test existence, style.

**`reviewer.logic`** — Logical bugs (off-by-one, wrong operator, inverted condition, missing branch), typos in code (variable names, string literals, comments, log messages), copy-paste errors, dead code from unfinished edits.
NOT in scope: security, business requirements, style, test coverage.

**`reviewer.tests`** — Test existence (every public method/branch/error path), test quality (meaningful assertions, behavior not implementation), isolation, naming convention (`[unit]_[scenario]_[result]`), coverage thresholds (80% line general, 90% branch critical paths, 100% branch auth logic), regression tests for bug fixes.
NOT in scope: security, business logic, readability.

**`reviewer.quality`** — Readability, maintainability, naming, structure, cyclomatic complexity, duplication.
NOT in scope: security, business logic, test coverage, standards compliance.

**`reviewer.standards`** — Compliance with discovered repo/company patterns and any documented standards (`coding-standards.md`, `api-guidelines.md`, `pr-guidelines.md`, `architecture-standards.md`). Documentation present and complete. Formatting.
NOT in scope: security, business logic, test coverage, subjective quality.

**`reviewer.risk`** — Risk scoring and deployment recommendation. Scores each dimension A-F (Correctness, Security, Test Coverage, Code Quality, Maintainability, Observability), calculates total issue points (Critical=10, High=7, Medium=4, Low=2), assesses blast radius and reversibility, assigns complexity 1-5, and issues a deployment recommendation. Synthesises findings from other reviewers where available. `REVIEW_RESULT` goes to Lead (not implementer). Never issues `CHANGES_REQUESTED` except for unmitigated Critical risks with no safety net.
NOT in scope: line-level defect finding — synthesises from other reviewers.

**`reviewer.pr-description`** — Generates a Conventional Commits PR title and structured description (Changes, Impact, Breaking Changes, Testing). Always issues `APPROVED` — generative, not gating. `REVIEW_RESULT` goes to Lead.
NOT in scope: code quality, correctness, security, standards compliance.

**`observability`** (as reviewer) — When included in review gates, assesses whether the change has adequate logging (structured, appropriate levels, no PII), metrics (counters/latency for significant operations), and context propagation. Issues `REVIEW_RESULT` to implementer like other reviewers.
NOT in scope: business logic, security, code style.

**`reviewer.observability`** — Thin review-gate wrapper that applies `observability` expertise within the standard reviewer protocol. Automatically invoked by the change-type matrix for backend logic, infrastructure, and new module/service changes. Read `agents/roles/observability.md` for full lens specification.
NOT in scope: business logic, broad security, performance budgets, operational alerting setup.

**`reviewer.appsec`** — Dependency and supply chain security review: CVE scanning (NVD, GitHub Advisory, OSV), version downgrade detection, lockfile consistency, typosquatting, abandoned packages, license compliance, overly broad version ranges. Thin wrapper applying `security.appsec-analyst` expertise within the reviewer protocol. Automatically invoked for dependency updates and new module/service changes. Read `agents/roles/security.appsec-analyst.md` for full methodology.
NOT in scope: code-level vulnerabilities (→ `reviewer.security`), business logic, style.

## 4. Finding Severity

| Severity | Blocks Approval? | Definition |
|----------|-----------------|------------|
| `MUST_FIX` | Yes | Causes bugs, security vulnerabilities, data loss, or violates a hard standard. Reviewer MUST provide a concrete fix suggestion. |
| `SHOULD_FIX` | No | Degrades quality/robustness but no immediate bug. Implementer should address or defer with written justification. |
| `NITPICK` | No | Minor style preference. No response required. Mark clearly to avoid confusion with higher severity. |
| `PRAISE` | No | Good practice worth reinforcing. Be specific about what is good and why. |

If any `MUST_FIX` exists, verdict is `CHANGES_REQUESTED`. `SHOULD_FIX` alone allows `APPROVED`.

## 5. Re-Review Rules

- Only reviewers who issued `CHANGES_REQUESTED` re-review.
- Reviewers who approved do NOT re-review unless the implementer's changes touched their lens scope.
- Re-review is scoped to addressed findings — not a full re-review from scratch.
- New findings may only be raised if the implementer's changes introduced new issues.
- All `MUST_FIX` addressed → `APPROVED`. `SHOULD_FIX` deferred with justification → `APPROVED`. `SHOULD_FIX` ignored without justification → reviewer may upgrade to `MUST_FIX`.

## 6. Special Scenarios

**Hotfix (P0):** Minimum required reviewers: `reviewer.correctness` only. Focus: "will this fix without regressions?" Other lenses deferred to a follow-up task. `reviewer.risk` advisory (non-blocking).

**Dependency-only changes:** `reviewer.security` + `reviewer.correctness` + `reviewer.appsec`. `reviewer.appsec` performs deep CVE scanning, supply chain risk assessment (version downgrades, typosquatting, lockfile consistency), and license compliance. `reviewer.tests` only if test infrastructure is affected. `reviewer.risk` for deployment recommendation.

**Config-only changes:** `reviewer.security` + `reviewer.standards` only. `reviewer.risk` advisory.

**All changes (standard):** `reviewer.risk` and `reviewer.pr-description` run in parallel with lens reviewers on every review. `reviewer.risk` produces the scored assessment and deployment recommendation. `reviewer.pr-description` generates the PR title and description.

**Multi-part changes:** Each PR reviewed independently. Assign the same reviewer instances across parts (context continuity). Final PR gets consolidated review of cumulative impact.

## 7. Anti-Patterns

- **Lens creep:** Raising findings outside your assigned lens.
- **Review gatekeeping:** Using `SHOULD_FIX` as a de facto blocker.
- **Rubber-stamp:** `APPROVED` with no findings. Rare; should be scrutinised.
- **Re-review scope creep:** Using re-review to raise new unrelated findings.
- **Finding inflation/deflation:** Misclassifying severity as leverage or to avoid blocking.
- **Review ping-pong:** Extended cycles without convergence. Lead must intervene at cycle 3.
- **Unconstructive findings:** "This is wrong" without a fix suggestion. Always include a concrete suggestion.
- **Ignoring SHOULD_FIX:** Must provide written justification for deferral.
