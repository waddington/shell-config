# Definition of Done

This document defines the complete set of criteria that must be satisfied before any task can be marked as DONE. The Definition of Done (DoD) is not a suggestion -- it is a hard gate verified by the Lead on the transition from APPROVED to DONE. The Lead is responsible for verifying every item.

---

## Universal DoD Checklist

The following checklist applies to ALL task types (feature, enhancement, refactor, chore, bugfix). Every item must be checked and verified. There are no optional items.

### 1. Acceptance Criteria
- [ ] Every acceptance criterion listed in the task is met.
- [ ] Each criterion has been independently verified (not just "it seems to work").
- [ ] No acceptance criterion has been modified after work began without Lead approval and documentation in the task Notes.

### 2. Review Gates
- [ ] All required review gates have been passed. Every reviewer listed in Required Review Gates has issued a verdict of `APPROVED`.
- [ ] No reviewer has an outstanding `CHANGES_REQUESTED` or `BLOCKED` verdict.
- [ ] Lead has confirmed all required reviewers have approved.

### 3. Findings Resolution
- [ ] All `MUST_FIX` findings from all review cycles have been resolved.
- [ ] Resolution of each MUST_FIX finding has been verified by the reviewer who raised it (via re-review).
- [ ] `SHOULD_FIX` findings have been addressed or explicitly deferred with justification in Notes.
- [ ] `NITPICK` findings have been considered (addressing is at the implementer's discretion).

### 4. Tests
- [ ] All existing tests pass. No previously passing test has been broken.
- [ ] New tests have been written for new or changed functionality.
- [ ] Tests cover both happy path and error/edge cases.
- [ ] No flaky tests have been introduced (tests are deterministic).
- [ ] The `tests_passing` field in the `TASK_DONE` message is `true`.

### 5. Test Coverage
- [ ] Test coverage meets or exceeds the project's configured thresholds.
- [ ] The `coverage_delta` in the `TASK_DONE` message is non-negative (coverage has not decreased).
- [ ] If coverage decreased, a justification is provided and the Lead has approved the exception.

### 6. Logging and Metrics
- [ ] New or changed functionality has appropriate logging at the correct levels (DEBUG for flow tracing, INFO for business events, WARN for recoverable issues, ERROR for failures).
- [ ] No sensitive data (PII, credentials, card numbers) is included in log output.
- [ ] Metrics are instrumented for new endpoints, operations, or business events (request count, latency, error rate at minimum).
- [ ] Existing logging and metrics have not been inadvertently removed or degraded.

### 7. Documentation
- [ ] API documentation is updated for any changed endpoints, request/response schemas, or error codes.
- [ ] Inline code comments are present for non-obvious logic.
- [ ] Runbooks or operational documentation are updated if the change affects operational procedures.
- [ ] The task's Artifacts section lists all produced artifacts (file paths, commit SHAs, PR numbers).

### 8. Lead Confirmation
- [ ] The Lead has reviewed the completed DoD checklist.
- [ ] The Lead has confirmed that all items are satisfied.
- [ ] The Lead has sent an `APPROVAL` message with scope `TASK`.

---

## Type-Specific Additions

In addition to the universal checklist above, the following items are required for specific task types.

### Feature Tasks
- [ ] The feature is behind a feature flag if it is being deployed incrementally (or explicitly documented as not requiring one).
- [ ] The feature has been tested in an environment that mirrors production (staging or equivalent).
- [ ] Backward compatibility is maintained (or breaking changes are documented and the Lead has approved them).
- [ ] Any new configuration parameters have sensible defaults and are documented.

### Bugfix Tasks
- [ ] A regression test exists that fails before the fix and passes after the fix.
- [ ] The root cause has been identified and documented in the Root Cause field.
- [ ] Fix verification steps have been followed and the expected behavior is confirmed.
- [ ] For Sev0/Sev1 bugs: a rollback plan is documented and reviewed.
- [ ] Related code paths have been checked for similar bugs (the fix is not just a point fix if the pattern exists elsewhere).

### Refactor Tasks
- [ ] No user-visible behavior has changed (verified by existing tests passing without modification).
- [ ] The refactoring achieves its stated goal (e.g., reduced duplication, improved structure, better naming).
- [ ] No new functionality was introduced (refactors are structural changes only; new functionality requires a separate feature task).

### Spike Tasks
- [ ] The spike goal question has been answered (or the time box has expired and the outcome documents what is known and unknown).
- [ ] A spike outcome document exists with findings, recommendation, confidence level, and open questions.
- [ ] Expected deliverables have been produced.
- [ ] Follow-up tasks have been proposed via `TASK_PROPOSAL` messages (if the spike identified work to be done).
- [ ] No production code was merged (spike prototypes remain on throwaway branches).

---

## How the Lead Verifies DoD

The Lead follows this process when verifying the Definition of Done:

1. **Receive TASK_DONE message.** Confirm `tests_passing` is `true` and `coverage_delta` is acceptable.
2. **Check review gate status.** Verify all required reviewers have issued `APPROVED` verdicts. Confirm no reviewer has an outstanding `CHANGES_REQUESTED` or `BLOCKED` verdict.
3. **Review findings resolution.** Confirm all MUST_FIX findings are resolved. Check that re-reviews have occurred where needed.
4. **Walk the acceptance criteria.** For each acceptance criterion, confirm there is evidence it is met (test output, artifact, or direct verification).
5. **Check type-specific items.** Apply the relevant type-specific additions from the list above.
6. **Issue APPROVAL or identify gaps.** If all items pass, send an `APPROVAL` message with scope `TASK` and transition the task to DONE. If any items fail, document the specific gaps and return the task to the assigned agent for remediation. The task remains in its current state (APPROVED) until gaps are closed.

---

## Partially Met DoD

When the DoD is partially met, the following rules apply:

- The task does NOT transition to DONE. It remains in its current state (typically APPROVED).
- The Lead must identify the specific DoD items that are not satisfied and communicate them clearly to the assigned agent.
- The agent addresses the gaps and notifies the Lead when they believe the DoD is now fully met.
- The Lead re-verifies. This is not a new review cycle (it does not count toward the 3-cycle review limit) -- it is a DoD verification step.
- If the gaps involve code changes, those changes may require a new review cycle (which DOES count toward the limit).

---

## Anti-Patterns

The following behaviors are explicitly forbidden. Any agent exhibiting these patterns must be corrected.

### Marking DONE when tests are failing
- Tests MUST pass before a task can be DONE. There are no exceptions.
- "The tests were passing on my machine" is not sufficient. Tests must pass in the CI environment.
- If a test is flaky and unrelated to the task, the flaky test must be addressed (by fixing it or quarantining it with Lead approval) before the task is DONE.

### Marking DONE without review
- Every task (except spikes) must go through the review process. A task cannot go from IN_PROGRESS to DONE.
- Even if the change is "trivial" or "just a config change," it must be reviewed. Trivial changes go through the same gates.
- The only exception is spike tasks, which are reviewed by the Lead directly (not through the code review process).

### Marking DONE with open MUST_FIX findings
- All MUST_FIX findings must be resolved and verified by the reviewer who raised them.
- "I addressed it but the reviewer hasn't re-reviewed yet" means the task is not DONE. It is in CHANGES_REQUESTED or IN_REVIEW.
- The implementer cannot self-verify their resolution of MUST_FIX findings. The original reviewer must confirm.

### Marking DONE without Lead confirmation
- Only the Lead can transition a task to DONE. No agent may self-declare their task as DONE.
- The Lead must explicitly verify the DoD checklist and send an `APPROVAL` message.
- If the Lead is unavailable, the task remains in APPROVED until the Lead can verify. Tasks do not auto-complete.

### Skipping the DoD for "urgent" work
- P0 tasks still require the full DoD. Urgency does not exempt a task from quality gates.
- If a temporary fix must be deployed before the full DoD can be met, the temporary fix is tracked as a separate task, and the original task remains open until the proper fix with full DoD is completed.
