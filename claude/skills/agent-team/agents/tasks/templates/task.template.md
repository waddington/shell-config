# General-Purpose Task Template

This is the canonical task template. Every task in the system -- regardless of type -- MUST conform to this structure. Type-specific templates (review, PR, bugfix, spike) inherit all fields defined here and add their own.

---

## Required Fields

### Task ID
- Format: `TASK-NNNN` (zero-padded four-digit number, e.g., `TASK-0042`)
- Assigned by the Lead upon task acceptance. Proposers use `TASK-DRAFT` until a real ID is assigned.
- Must be unique across all tasks in the system. Reuse of IDs from DONE, REJECTED, or CANCELLED tasks is forbidden.

### Title
- A concise, imperative-verb phrase describing what must be done.
- Maximum 80 characters.
- Good: "Add rate limiting to payment endpoint"
- Bad: "Payment endpoint" (no verb, vague), "We should probably look into maybe adding some kind of rate limiting to the payment endpoint because it might be getting too many requests" (too long, hedging)

### Type
- One of: `feature`, `enhancement`, `refactor`, `chore`
- `feature`: Net-new functionality that did not exist before.
- `enhancement`: Improvement to existing functionality (performance, UX, etc.).
- `refactor`: Internal restructuring with no user-visible behavior change.
- `chore`: Maintenance work (dependency updates, CI changes, config adjustments).

### Priority
- One of: `P0`, `P1`, `P2`, `P3`
- `P0` -- Critical. Production is broken, security vulnerability, data loss risk. Must be addressed immediately. All other work is paused.
- `P1` -- High. Significant impact on users or development velocity. Should be addressed within the current iteration.
- `P2` -- Medium. Important but not urgent. Planned for the current or next iteration.
- `P3` -- Low. Nice-to-have. Addressed when capacity allows.

### Status
- One of the lifecycle states: `PROPOSED`, `ACCEPTED`, `ASSIGNED`, `IN_PROGRESS`, `IN_REVIEW`, `CHANGES_REQUESTED`, `APPROVED`, `DONE`, `REJECTED`, `BLOCKED`, `CANCELLED`
- See `agents/tasks/definitions/task.lifecycle.md` for valid transitions and entry conditions.

### Assigned To
- Role identifier of the agent responsible for executing this task (e.g., `implementer.backend`, `implementer.frontend`).
- Blank until the task reaches ASSIGNED status.
- Only the Lead may set or change this field.

### Created By
- Role identifier of the agent who proposed or created this task (e.g., `lead`, `reviewer.code`).
- Set at creation time. Immutable.

### Created At
- ISO 8601 timestamp of when the task was created (e.g., `2026-03-03T14:30:00Z`).
- Set at creation time. Immutable.

### Iteration
- Identifier of the iteration this task belongs to (e.g., `iteration-3`).
- Set by the Lead upon acceptance. May be changed if a task is deferred.

### Dependencies
- List of `TASK-NNNN` identifiers that this task is blocked by.
- This task cannot enter IN_PROGRESS until all listed dependencies are in DONE status.
- Empty list if no dependencies exist.
- See `agents/tasks/definitions/dependencies.md` for dependency rules.

### Blocks
- List of `TASK-NNNN` identifiers that are waiting on this task to complete.
- Informational -- used by the Lead for scheduling. Updated when downstream tasks declare dependencies.

### Labels
- List of labels classifying the task. Every task MUST have at least: one type label (`feature`, `enhancement`, `refactor`, `chore`), one priority label (`P0`–`P3`), and one area label (e.g. `backend`, `api`, `frontend`, `platform`, `security`, `testing`, `docs`).
- Every task MUST have at least: one type label, one priority label, and one area label.
- Additional labels (size, risk, status) are added as appropriate.

---

## Required Sections

### Description
Detailed description of what must be done. Must be specific enough that the assigned agent can begin work without further clarification. Include:
- What the change is
- Where it applies (which files, modules, endpoints)
- Any constraints or boundaries

Bad: "Fix the bug." (Which bug? Where? What behavior is expected?)
Good: "The `/api/v1/cards` endpoint returns a 500 error when the `lastFourDigits` field is null. Modify the serializer in `CardSerializer.scala` to handle null values by returning an empty string."

### Context
Why this work is needed. Background information that helps the assignee understand the motivation:
- What triggered this task (user report, monitoring alert, roadmap item)
- What happens if this is not done
- Related previous tasks or decisions

### Acceptance Criteria
Numbered list of testable, unambiguous criteria. Each criterion must be independently verifiable.

Rules for good acceptance criteria:
1. Each criterion uses "Given / When / Then" or a clear conditional statement.
2. No subjective language ("should be fast", "looks good", "works properly").
3. Each criterion is independently testable -- you can write a test for it.
4. Criteria are exhaustive -- if all are met, the task is complete.

Good examples:
1. Given a card with `lastFourDigits = null`, when the card is serialized, then the response contains `"lastFourDigits": ""` instead of a 500 error.
2. Given a request rate exceeding 100 req/s from a single client, when the 101st request arrives, then the endpoint returns HTTP 429 with a `Retry-After` header.

Bad examples:
1. "It works." (Not testable, not specific)
2. "Performance is improved." (No measurable threshold)
3. "The code is clean." (Subjective)

### Required Review Gates
List of reviewer roles that must approve this task before it can reach APPROVED status. Determined by the change type:
- Code changes: `reviewer.code` (always required)
- Security-sensitive changes: `reviewer.security`
- Performance-sensitive changes: `reviewer.performance`
- Architecture changes: `reviewer.architecture`
- Test-only changes: `reviewer.test`

The Lead sets this field based on the task type and labels. Reviewers are notified via `REVIEW_REQUEST` messages.

### Definition of Done Checklist
Standard checklist that must be completed before the task can transition to DONE. Copied from `agents/tasks/definitions/definition-of-done.md`:

- [ ] All acceptance criteria are met
- [ ] All required review gates have been passed (verdict: APPROVED)
- [ ] All MUST_FIX findings from reviews have been resolved
- [ ] All tests pass (unit, integration, and any applicable end-to-end)
- [ ] Test coverage meets or exceeds project thresholds
- [ ] Logging and metrics are instrumented for new/changed functionality
- [ ] Documentation is updated (API docs, runbooks, inline comments as needed)
- [ ] Lead has confirmed the Definition of Done is fully met

### Artifacts
List of artifacts produced during execution of this task. Updated as work progresses:
- File paths (relative to repo root)
- Commit SHAs
- PR numbers
- Any other references

Empty until work begins.

### Message Log
Ordered list of `message_id` values (UUID v4) for all messages related to this task. Provides an audit trail:
- `TASK_PROPOSAL` / `TASK_ASSIGNMENT` that created the task
- `STATUS_UPDATE` messages during execution
- `REVIEW_REQUEST` and `REVIEW_RESULT` messages
- `TASK_DONE` message upon completion
- `APPROVAL` message from Lead

### Notes
Additional context, decisions, constraints, or information that does not fit in the above sections. This is a free-form section. Examples:
- "This task was split from TASK-0038 because it exceeded XL sizing."
- "The approach was discussed in TASK-0035 spike. See spike outcome for rationale."
- "Constraint: must not introduce new library dependencies without Lead approval."

---

## Field Validation Rules

A task is **well-formed** when:
1. All required fields are present and non-empty.
2. `Task ID` matches the `TASK-NNNN` format (or `TASK-DRAFT` for proposals).
3. `Type` is one of the allowed values.
4. `Priority` is one of `P0`, `P1`, `P2`, `P3`.
5. `Status` is a valid lifecycle state.
6. `Created At` is a valid ISO 8601 timestamp.
7. `Dependencies` contains only valid `TASK-NNNN` identifiers (not self-referencing).
8. `Labels` contains at least one type label, one priority label, and one area label.
9. `Acceptance Criteria` contains at least one criterion.
10. `Required Review Gates` contains at least one reviewer role.

A task is **malformed** when any of the above conditions are violated. Malformed tasks must not be accepted by the Lead. The proposing agent must correct the task before resubmission.

---

## Blank Template

```
Task ID: TASK-DRAFT
Title: [Imperative verb phrase, max 80 characters]
Type: [feature | enhancement | refactor | chore]
Priority: [P0 | P1 | P2 | P3]
Status: PROPOSED
Assigned To: [blank until assigned]
Created By: [your role identifier]
Created At: [ISO 8601 timestamp]
Iteration: [blank until accepted]
Dependencies: [list of TASK-NNNN or empty]
Blocks: [list of TASK-NNNN or empty]
Labels: [type label, priority label, area label, plus any additional]

## Description
[Detailed description of what must be done]

## Context
[Why this work is needed]

## Acceptance Criteria
1. [Testable criterion]
2. [Testable criterion]

## Required Review Gates
- [reviewer role]

## Definition of Done Checklist
- [ ] All acceptance criteria are met
- [ ] All required review gates have been passed
- [ ] All MUST_FIX findings from reviews have been resolved
- [ ] All tests pass
- [ ] Test coverage meets or exceeds thresholds
- [ ] Logging and metrics are instrumented
- [ ] Documentation is updated
- [ ] Lead has confirmed Definition of Done is fully met

## Artifacts
[empty]

## Message Log
[empty]

## Notes
[any additional context]
```
