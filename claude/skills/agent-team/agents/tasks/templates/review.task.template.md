# Review Task Template

This template is used for all review tasks. It inherits every field from the general-purpose task template (`task.template.md`) and adds review-specific fields and sections.

A review task is created when an implementer sends a `REVIEW_REQUEST` message and the Lead assigns a reviewer. The reviewer must complete their review checklist, record findings, and issue a verdict.

---

## Inherited Fields

All fields from `task.template.md` are required. The following values are pre-set for review tasks:

- **Type**: Always `chore` (reviews are operational work, not feature development).
- **Title**: Format: "Review [TASK-NNNN]: [brief description of what is being reviewed]"
- **Labels**: Must include `needs-review` status label in addition to the standard required labels.

---

## Additional Required Fields

### Review Lens
The perspective from which this review is conducted. One of:
- `CODE` -- General code quality, correctness, maintainability, adherence to project standards.
- `SECURITY` -- Security vulnerabilities, authentication/authorization issues, input validation, secret handling.
- `PERFORMANCE` -- Performance regressions, inefficient algorithms, resource leaks, N+1 queries.
- `ARCHITECTURE` -- Structural soundness, separation of concerns, API design, backward compatibility.
- `TEST` -- Test quality, coverage gaps, test reliability, assertion strength.

The review lens determines which checklist the reviewer must complete. A single task may require multiple review tasks with different lenses, each assigned to the appropriate reviewer role.

### Artifacts Under Review
Specific references to what is being reviewed. Must include at least one of:
- File paths (relative to repo root) of changed files
- PR number (e.g., `#3607`)
- Commit SHAs (full 40-character hashes)
- Branch name

These are listed in the `artifacts` field of the `REVIEW_REQUEST` message.

### Review Checklist
A lens-specific checklist the reviewer must complete. The reviewer checks each item and records pass/fail/not-applicable. Items cannot be left unchecked -- every item must have a determination.

#### CODE Lens Checklist
- [ ] Code compiles and builds without errors or new warnings
- [ ] Logic is correct and handles edge cases
- [ ] Error handling is comprehensive (no swallowed exceptions, appropriate error types)
- [ ] Naming is clear, consistent, and follows project conventions
- [ ] No dead code, commented-out code, or debug statements
- [ ] No code duplication that should be extracted
- [ ] Functions and methods have appropriate scope and responsibility
- [ ] Public APIs have documentation
- [ ] Changes are backward-compatible (or breaking changes are documented and approved)

#### SECURITY Lens Checklist
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input validation is present for all external inputs
- [ ] Authentication and authorization checks are correctly applied
- [ ] SQL/NoSQL injection vectors are prevented (parameterized queries)
- [ ] Sensitive data is not logged or exposed in error responses
- [ ] Dependencies do not introduce known vulnerabilities (CVE check)
- [ ] CORS, CSP, and other security headers are correctly configured (if applicable)
- [ ] Cryptographic operations use approved algorithms and libraries

#### PERFORMANCE Lens Checklist
- [ ] No N+1 query patterns introduced
- [ ] Database queries are indexed appropriately
- [ ] No unbounded collections loaded into memory
- [ ] Resource cleanup is handled (connections, streams, file handles)
- [ ] Caching is used where appropriate and invalidation is correct
- [ ] No blocking operations on critical paths
- [ ] Payload sizes are reasonable (no over-fetching)

#### ARCHITECTURE Lens Checklist
- [ ] Changes align with the established architecture and patterns
- [ ] Separation of concerns is maintained
- [ ] Dependencies flow in the correct direction
- [ ] New abstractions are justified and well-defined
- [ ] API contracts are stable and versioned
- [ ] Configuration is externalized appropriately
- [ ] Changes do not create circular dependencies

#### TEST Lens Checklist
- [ ] Tests cover the stated acceptance criteria
- [ ] Tests cover edge cases and error paths
- [ ] Tests are deterministic (no flaky tests introduced)
- [ ] Test names clearly describe what is being tested
- [ ] Assertions are specific (not just "no exception thrown")
- [ ] Test data is isolated (no shared mutable state between tests)
- [ ] Integration tests clean up after themselves
- [ ] Coverage delta is non-negative

### Findings
Structured list of issues, suggestions, and praise discovered during the review. Each finding has the following fields, matching the `findings` array in the `REVIEW_RESULT` message payload:

- **Severity**: One of `MUST_FIX`, `SHOULD_FIX`, `NITPICK`, `PRAISE`
  - `MUST_FIX`: Blocks approval. The implementer MUST address this before the task can proceed. Examples: bugs, security vulnerabilities, data loss risks.
  - `SHOULD_FIX`: Does not block approval but strongly recommended. Examples: suboptimal patterns, missing edge case handling that is unlikely but possible.
  - `NITPICK`: Minor style or preference issue. Does not block approval. Examples: naming preferences, formatting.
  - `PRAISE`: Something done well. Reinforces good practices.
- **File**: File path relative to repo root.
- **Line**: Line number where the finding applies.
- **Description**: Factual description of the finding. No subjective language.
- **Suggestion**: Concrete suggestion for how to address the finding. Required for `MUST_FIX` and `SHOULD_FIX`. Empty string for `PRAISE`.

Example finding:
```
Severity: MUST_FIX
File: app/services/CardService.scala
Line: 142
Description: The findCard method catches all exceptions with a bare catch { case _ => }, which silently swallows errors including OutOfMemoryError and InterruptedException.
Suggestion: Catch only NonFatal exceptions using scala.util.control.NonFatal and allow fatal exceptions to propagate.
```

### Verdict
The overall outcome of the review. One of:
- `APPROVED` -- All checklist items pass. No MUST_FIX findings. The task may proceed.
- `CHANGES_REQUESTED` -- One or more MUST_FIX findings exist. The implementer must address them and request re-review.
- `BLOCKED` -- A fundamental issue prevents approval regardless of changes (e.g., wrong architectural approach, requires redesign). The Lead must be notified via an `ESCALATION` message.

The verdict is communicated via a `REVIEW_RESULT` message to Lead.

### Re-review Required
- Boolean: `true` or `false`
- Set to `true` when the implementer has addressed findings from a previous review cycle and the reviewer must re-examine the changes.
- Set to `false` on initial review and after re-review is complete.

### Previous Review IDs
List of `TASK-NNNN` identifiers for previous review tasks on the same parent task. Provides history of the review cycle.
- Empty on first review.
- Each subsequent review cycle creates a new review task that references all prior review task IDs.

### Review Cycle Count
Integer tracking how many review cycles have occurred for the parent task.
- Starts at 1 for the initial review.
- Incremented each time the task goes through IN_REVIEW -> CHANGES_REQUESTED -> IN_PROGRESS -> IN_REVIEW.
- **Must not exceed 3 without Lead escalation.** If a third review cycle still results in CHANGES_REQUESTED, the reviewer must send an `ESCALATION` message (reason: `CONFLICT`) to the Lead. The Lead decides whether to reassign, redefine the task, or intervene directly.

---

## Blank Template

```
[All fields from task.template.md, plus:]

Review Lens: [CODE | SECURITY | PERFORMANCE | ARCHITECTURE | TEST]
Artifacts Under Review:
  - [file path, PR number, commit SHA, or branch name]
Review Checklist:
  [lens-specific checklist -- see above]
Findings:
  [structured findings list -- see format above]
Verdict: [APPROVED | CHANGES_REQUESTED | BLOCKED]
Re-review Required: [true | false]
Previous Review IDs: [list of TASK-NNNN or empty]
Review Cycle Count: [integer, starting at 1]
```
