# Bug Fix Task Template

This template is used for all bug fix tasks. It inherits every field from the general-purpose task template (`task.template.md`) and adds bug-specific fields that ensure thorough diagnosis, reproducible verification, and regression prevention.

---

## Inherited Fields

All fields from `task.template.md` are required. The following values are pre-set for bugfix tasks:

- **Type**: Always `bugfix` (overrides the general template's type options for this template).
- **Title**: Format: "Fix [concise description of the bug]" (e.g., "Fix null pointer in card serialization when lastFourDigits is missing")
- **Labels**: Must include `bugfix` type label and the appropriate severity label (`Sev0`, `Sev1`, `Sev2`, or `Sev3`).

---

## Additional Required Fields

### Bug Severity
Classification of the bug's impact. One of:

- `Sev0` -- Critical. Production is down, data loss is occurring, or a security breach is active. Requires immediate response. All other work stops. A rollback plan is mandatory.
- `Sev1` -- Major. Significant functionality is broken for a large number of users, but a workaround may exist. Must be fixed within the current iteration. A rollback plan is mandatory.
- `Sev2` -- Moderate. Functionality is degraded but usable. Affects a subset of users or a non-critical path. Planned for current or next iteration.
- `Sev3` -- Minor. Cosmetic issue, minor inconvenience, or edge case with negligible impact. Fixed when capacity allows.

Bug Severity and Priority are related but distinct. A Sev0 bug is always P0. A Sev3 bug might be P2 if it affects a high-visibility area, or P3 if it is truly insignificant.

### Reproduction Steps
Numbered, deterministic steps that reliably reproduce the bug. Any agent following these steps must be able to observe the same defective behavior.

Rules:
1. Steps must be specific and complete -- no assumed context.
2. Include exact inputs, parameters, and preconditions.
3. State which environment the reproduction was performed in.
4. If the bug is intermittent, note the observed reproduction rate (e.g., "reproduces approximately 3 out of 10 attempts").

Example:
```
1. Start the application with default configuration.
2. Send a POST request to /api/v1/cards with the following body:
   {"cardNumber": "4111111111111111", "lastFourDigits": null}
3. Observe the response.
```

Bad example:
```
1. Send a request to the cards endpoint.
2. It crashes.
```
(Missing: which endpoint method, what payload, what "crashes" means)

### Expected Behavior
A precise statement of what SHOULD happen when the reproduction steps are followed. Must be specific and measurable.

Example: "The endpoint returns HTTP 200 with a JSON body containing `\"lastFourDigits\": \"\"` (empty string)."

Bad example: "It should work." (Not specific)

### Actual Behavior
A precise statement of what DOES happen when the reproduction steps are followed. Include:
- Error messages (exact text)
- HTTP status codes
- Stack traces (relevant portions)
- Log output (relevant lines)

Example: "The endpoint returns HTTP 500 with body `{\"error\": \"Internal Server Error\"}`. The application log shows: `NullPointerException at CardSerializer.scala:42 -- Cannot invoke method on null reference`."

### Environment
Where the bug was observed. Include all relevant environment details:
- Environment name (production, staging, local development)
- Application version or commit SHA
- JVM version (if applicable)
- Operating system (if relevant)
- Configuration differences from default (if any)

Example: "Production, version 1.10.212, JVM 17.0.2, default configuration."

### Root Cause
The underlying cause of the bug. This field is blank when the task is created and filled by the debugger or implementer during investigation.

Must explain WHY the bug occurs, not just WHAT happens. Reference specific code locations.

Example: "The `CardSerializer.serialize()` method at line 42 calls `lastFourDigits.substring(0, 4)` without a null check. When the card is created via the legacy import path, `lastFourDigits` is not populated and remains null."

Bad example: "There's a null pointer exception." (This is the symptom, not the cause.)

### Regression Test Requirement
**Mandatory for all bug fixes.** Every bug fix MUST include a test that:
1. **Fails before the fix is applied** -- proving the test catches the bug.
2. **Passes after the fix is applied** -- proving the fix resolves the bug.

The test must be specific to the bug scenario, not a generic test that happens to pass. Document the test location and what it verifies:

```
Test file: test/services/CardSerializerSpec.scala
Test name: "serialize should return empty string when lastFourDigits is null"
Verification: Creates a Card with lastFourDigits=null, serializes it, asserts the output contains "lastFourDigits": "" and no exception is thrown.
```

If a regression test is not feasible (extremely rare), the implementer must explain why in the Notes section and the Lead must explicitly approve the exception.

### Fix Verification Steps
Steps to verify the fix works correctly. These are distinct from the regression test -- they describe manual or integration-level verification that the bug is resolved in context.

1. Apply the fix.
2. Follow the original reproduction steps.
3. Verify the expected behavior now occurs.
4. Verify no regressions in related functionality (list specific checks).

Example:
```
1. Apply the fix in CardSerializer.scala.
2. Repeat reproduction steps: POST to /api/v1/cards with {"cardNumber": "4111111111111111", "lastFourDigits": null}.
3. Verify response is HTTP 200 with body containing "lastFourDigits": "".
4. Verify POST with a non-null lastFourDigits (e.g., "1234") still returns "lastFourDigits": "1234".
5. Verify GET /api/v1/cards returns cards with null lastFourDigits without error.
```

### Rollback Plan
**Required for Sev0 and Sev1 bugs.** A concrete plan for reverting the fix if it introduces new issues. Must include:
- How to revert (specific commit to revert, feature flag to disable, etc.)
- Who is responsible for executing the rollback
- What monitoring to watch after rollback
- Any data implications of rollback

Example:
```
1. Revert commit [SHA] using git revert [SHA].
2. Deploy the revert to production via the standard pipeline.
3. Monitor /api/v1/cards error rate for 15 minutes.
4. No data implications -- the fix is purely in serialization logic.
Responsible: implementer.backend, with Lead approval.
```

For Sev2 and Sev3 bugs, this field may be left as "Standard revert process applies" unless the fix involves data migrations or other non-trivially-reversible changes.

---

## Blank Template

```
[All fields from task.template.md, plus:]

Bug Severity: [Sev0 | Sev1 | Sev2 | Sev3]
Reproduction Steps:
  1. [step]
  2. [step]
  3. [step]
Expected Behavior: [precise statement]
Actual Behavior: [precise statement with error details]
Environment: [environment details]
Root Cause: [blank until investigated]
Regression Test Requirement:
  Test file: [path]
  Test name: [name]
  Verification: [what the test proves]
Fix Verification Steps:
  1. [step]
  2. [step]
Rollback Plan: [required for Sev0/Sev1, otherwise "Standard revert process applies"]
```
