# Pull Request Guidelines

**Enforced by:** `reviewer.standards`
**Scope:** All pull requests in this repository. No exceptions.

> **TODO:** These guidelines are a starting point and require significant refinement. A human must review and rewrite them based on actual CK PR conventions, internal engineering guidelines, repository hook configurations, and patterns from CK repos. Do not treat these as authoritative without that review.

Non-compliant PRs: `SHOULD_FIX`. PRs without a task ID or description: `MUST_FIX`.

---

## PR Title Format

Pattern: `type(scope): description`

| Type | Use When |
|---|---|
| `feat` | Adding new functionality. |
| `fix` | Correcting a defect. |
| `refactor` | Restructuring code without changing behavior. |
| `chore` | Build, tooling, or dependency changes. |
| `docs` | Documentation-only changes. |
| `test` | Adding or updating tests without changing production code. |
| `perf` | Performance improvements. |
| `security` | Security fixes or hardening. |

**Scope:** The module or area affected (e.g., `auth`, `api`, `payments`, `ci`).

**Description:** Imperative mood, lowercase, no period at the end.

**Bad examples (each is a `SHOULD_FIX`):**
- `Updated stuff` — no type, no scope, vague.
- `WIP` — work in progress should not be submitted for review.
- `fix` — no scope, no description.
- `feat(auth): Add Token Refresh Endpoint.` — not lowercase, has a period.

---

## PR Description — Required Sections

Missing any section: `MUST_FIX`.

**What changed:** Concise summary (2–4 sentences) of what the code does differently after merge.

**Why it changed:** Motivation for the change. Reference the ticket or task. Include enough business context for a reviewer to understand the purpose without reading the ticket.

**How to test:** Step-by-step instructions to verify the change. Include setup, input data, expected output, and edge cases. If covered entirely by automated tests, state that and reference the test class or file.

**Breaking changes:** Explicitly call out any breaking changes. If none, state "None." If any, document the migration path: what consumers must change, what configuration needs updating, rollback procedure.

**Task ID:** The identifier for the task that authorized this work. Every PR MUST be linked to a task.

**Changed files rationale:** Brief note on why each significant file was modified. Trivial changes (import reordering, formatting) do not need justification.

---

## PR Size Limits

| Lines Changed | Requirement |
|---|---|
| Under 400 | Target size. No justification needed. |
| 400–800 | PR description MUST explain why it cannot be split. |
| Over 800 | Lead approval required BEFORE review begins. |

Line counts exclude generated files (protobuf, OpenAPI codegen, IDE config) and test files. Only production code counts.

---

## Commit Hygiene

**Atomic commits:** Each commit MUST be a complete, working change. The codebase must compile and pass tests at every commit. A commit that breaks the build and is fixed by the next commit is not atomic.

**Commit message format:**
- First line: `type(scope): imperative description` — maximum 72 characters.
- Body (optional): Explain WHY, not WHAT. The diff shows the what. Wrap at 80 characters.

**Clean history before review:**
- No WIP commits. Squash or rebase before creating the PR.
- No merge commits in feature branches. Rebase on the base branch for linear history.
- Each commit must pass tests independently.

---

## Review Readiness Checklist

Complete all of the following BEFORE requesting review. Submitting a PR that fails this checklist: `SHOULD_FIX`.

- [ ] All tests pass locally.
- [ ] No linting errors.
- [ ] Self-reviewed the diff.
- [ ] PR description complete with all required sections.
- [ ] Task ID linked.
- [ ] Breaking changes documented (or explicitly "None").
- [ ] Documentation updated if change alters observable behavior, API contracts, or configuration.
- [ ] No TODOs without ticket references. Format: `TODO(IPE-12345): description`.
- [ ] No commented-out code.
- [ ] No debug logging left in production code paths.

---

## Merge Requirements

All MUST be satisfied before merge:

- All required reviewers approved per the change type review matrix.
- All `MUST_FIX` findings resolved. No `MUST_FIX` may be deferred.
- All CI checks pass — no failing tests, linting errors, or security scan failures.
- No merge conflicts. Author is responsible for resolving conflicts.
- Branch is up to date with the base branch.
- Squash merge preferred for feature branches. Squash commit message MUST follow PR title format.

---

## Branch Naming

Pattern: `type/task-id/short-description`

Examples: `feat/TASK-0042/card-activation-endpoint`, `fix/TASK-0099/null-status-handling`

**Prohibited:**
- Personal branches: `kyle/stuff`, `dev-kyle`. Branches belong to tasks, not people.
- Generic names: `dev`, `test`, `temp`, `wip`. These convey no information.
- Missing task ID: `feat/card-activation`. Every branch MUST reference a task ID.

---

## Post-Merge Responsibilities

- **Delete the feature branch.**
- **Verify CI passes on the base branch.** If it fails after your merge, fix it immediately.
- **Update the task status** to reflect the code has been merged.
- **Notify Lead** if post-merge actions exist (config changes, feature flags, data migrations).

---

## Anti-Patterns

**`MUST_FIX`:**
- PR without a task ID.
- PR without a description.

**`SHOULD_FIX`:**
- Unrelated changes bundled in one PR. Each PR should have a single purpose.
- Refactoring mixed with feature work. Different risk profiles; review separately.
- Failing tests at review time.
- Force-pushing after review has started without notifying reviewers.
- Self-approval (also blocked by repository hooks).
