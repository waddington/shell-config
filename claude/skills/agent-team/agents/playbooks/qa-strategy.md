# QA Strategy Playbook

Authoritative reference for `qa.test-designer`, `qa.test-writer`, `reviewer.tests`, and all implementers.

---

## 1. Test Layers

| Layer | Scope | Owner | When Required |
|-------|-------|-------|--------------|
| **Unit** | Individual methods/classes in isolation (mocked deps) | Implementers | Every implementation task. No exceptions. Unit tests are an acceptance criterion, not a separate task. |
| **Integration** | Component interactions within the app (real DB, no external services) | Implementers + `qa.test-writer` | Any change modifying component interactions (service↔repo, service↔service, controller↔service). |
| **E2E** | Full system behavior from the user's perspective | `qa.test-writer` | New features, critical bug fixes, any change to user-facing behavior. Not required for internal refactors with no external behavior change. |
| **Security** | Auth, authz, input validation, data protection — positive and negative cases | `qa.test-writer` (guided by `security.appsec-analyst`) | Any change to auth/authz/input validation, new endpoints, any code processing user input. |
| **Performance** | Latency, throughput, memory — compared against budgets | `qa.test-writer` or implementer (guided by `perf.reliability`) | New endpoints, new DB queries, batch operations, hot path changes. Not required for every change. |

Unit test characteristics: milliseconds to run, no external dependencies, deterministic, fully isolated.
E2E tests: few in number (critical paths only), more expensive to maintain — use sparingly.

---

## 2. QA Workflow

### 2.1 Standard Flow (M/L/XL complexity)

1. **Test planning** — Lead assigns test planning to `qa.test-designer`. Input: implementation task acceptance criteria + change type. Output: test plan covering what to test, edge cases, negative cases, risk areas, coverage targets, and test data requirements.
2. **Implementation with tests** — Implementer writes unit and integration tests alongside implementation code, using the test plan as a guide. `TASK_DONE` must include `tests_passing: true` and `coverage_delta`.
3. **E2E test writing** — Lead assigns to `qa.test-writer` after implementer's `TASK_DONE`. Input: test plan + completed implementation. Output: E2E test code covering scenarios not already covered by unit/integration tests.
4. **Test review** — Lead assigns to `reviewer.tests`. Reviews all tests (unit, integration, E2E) for quality and coverage. Output: `REVIEW_RESULT`.
5. **Verification** — All tests pass in CI, coverage meets thresholds → task moves to `DONE`.

### 2.2 Abbreviated Flow (S complexity)

Skip test planning. Implementer uses acceptance criteria directly. Unit tests as part of implementation. E2E only if change affects user-facing behavior. Test review by `reviewer.tests` still required.

### 2.3 Bug Fix Flow

1. Write a test that **reproduces the bug** before fixing it. This test must FAIL before the fix.
2. Implement the fix.
3. Verify the reproduction test now PASSES. Run full suite to confirm no regressions.
4. `TASK_DONE` notes must state: "Regression test [name] reproduces the original bug and passes with the fix."

If the bug cannot be reproduced in a test (race condition, environment-specific): document why in notes and describe manual verification performed.

---

## 3. Coverage Requirements

Thresholds apply to new and modified code only. Unmodified existing code is excluded.

| Code Category | Min Line Coverage | Min Branch Coverage |
|--------------|------------------|---------------------|
| New code (general) | 80% | — |
| Bug fix (fixed path) | 100% | 100% |
| Critical business logic | 80% | 90% |
| Auth/authz logic | 100% | 100% (both positive and negative cases) |
| Error handling | 80% | 80% |
| Utility functions | 80% | — |

**Enforcement:** `reviewer.tests` raises `MUST_FIX` if thresholds are not met. CI must report coverage metrics; task cannot reach `APPROVED` if coverage checks fail.

**Exceptions (must be documented in `TASK_DONE` notes):**
- Generated code (test the generation mechanism, not the output).
- Configuration classes with no logic.
- Legacy code with minimal modification (a 1-line fix in a 500-line untested file does not require testing the other 499 lines).

---

## 4. Test Quality Standards

Violations are raised by `reviewer.tests` per the severity guide in `code-review-policy.md`.

**Determinism** (`MUST_FIX` if violated) — Tests must produce the same result every run regardless of execution order, time, or environment. Violations: system clock dependence (use injectable time provider), unseeded random data, external service calls without mocking, file system state without setup/teardown.

**Isolation** (`MUST_FIX` if violated) — Each test must be independent. No test may depend on another's outcome or side effects. Violations: shared mutable state without reset, ordered test dependencies, reading data written by another test, global state mutation without cleanup.

**Behavior testing** (`SHOULD_FIX` if violated) — Tests must verify observable behavior (outputs, side effects, state changes), not implementation details. Violations: asserting private method was called, asserting internal data structure layout, tests that break on refactor without behavior change.

**Meaningful assertions** (`MUST_FIX` if violated) — Every test must have at least one assertion verifying a meaningful condition. "Runs without exception" is not sufficient unless specifically testing that no exception is thrown. Violations: no assertions, `assertTrue(true)`, null checks without content verification, caught and ignored exceptions.

**Naming convention** (`SHOULD_FIX` if violated) — Pattern: `[unit]_[scenario]_[expectedResult]`
- Correct: `processPayment_expiredCard_returnsValidationError`
- Incorrect: `testProcessPayment`, `test1`, `shouldWork`

**Test size** (`NITPICK` if violated) — Unit tests: one scenario per test method, ≤3 assertions before considering a split. Integration tests may be longer but assertions should focus on one interaction. E2E tests may cover complete flows with assertions at each critical step.

---

## 5. Test Failure Handling

**Flaky tests** — A test that passes sometimes and fails sometimes without code changes. When detected:
1. Immediately quarantine (mark flaky, exclude from blocking CI).
2. Create `TASK_PROPOSAL` to fix it (typically P2).
3. Must be fixed or removed within the current iteration — flaky tests do not persist.

**CI failure on TASK_DONE submission** — Task cannot move to `APPROVED`. Implementer must fix failing tests before re-submitting. If failures are pre-existing (not introduced by current change): Lead decides whether to fix as part of current task (if quick) or create a separate task with a documented exception.

**Coverage regression** — Drop below required thresholds → `MUST_FIX` from `reviewer.tests`. Drop but remains above thresholds → `SHOULD_FIX`. Acceptable reasons for reduction: removal of dead code, consolidation of duplicated code. Unacceptable: adding new code without corresponding tests.

---

## 6. Anti-Patterns

1. **Testing after implementation** — writing all tests after code is complete. Leads to tests mirroring implementation rather than specifying behavior.
2. **Mocking everything** — over-mocking verifies the mock framework, not the code. Mock at system boundaries; use real objects internally.
3. **Testing implementation details** — asserting internal state or private method calls. These break on every refactor.
4. **Copy-paste tests** — duplicating test code with minor variations. Parameterize instead.
5. **Ignoring edge cases** — testing only the happy path. Null, empty, boundary values, concurrent access are where bugs hide.
6. **Testing the framework** — verifying that Spring injects a bean, etc. Test your code, not the framework.
7. **Unrealistic test data** — test data that doesn't resemble production data. Tests pass but production breaks.
8. **Slow unit tests** — unit tests > 100ms each belong in the integration suite.
9. **No regression test for bug fixes** — fixing a bug without a test that would catch it if reintroduced.
10. **Coverage gaming** — executing code without asserting anything meaningful to inflate coverage numbers.
