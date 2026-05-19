# Testing Standards

**Enforced by:** `reviewer.tests`
**Severity model:** Sev0-Sev3. Findings: MUST_FIX, SHOULD_FIX, NITPICK, PRAISE.
**Scope:** All test code and test coverage requirements for this repository.

> **TODO:** These standards are a starting point and require significant refinement. A human must review and rewrite them based on actual CK testing conventions, internal QA guidelines, CI configuration, and patterns from CK repos and engineering guidelines. Coverage thresholds, test type ownership, and tooling should all be updated to reflect CK practices. Additionally, define a strategy for combining/consolidating test types (e.g., when unit vs. integration tests are preferred, how to avoid redundant coverage across layers). Do not treat these as authoritative without that review.

---

## 1. Coverage Requirements

### 1.1 New Code Coverage

All new code must meet the project's minimum line coverage threshold. Coverage is measured per PR. A PR that adds production code must include tests covering it. Coverage below threshold: MUST_FIX unless the uncovered code is genuinely untestable (e.g., framework boilerplate, main method) — justify in PR description.

### 1.2 Critical Path Coverage

Code in critical paths requires higher branch coverage. Critical paths include:
- Authentication and authorization logic
- Payment processing and financial calculations
- Card token provisioning and lifecycle management
- Data mutation operations (create, update, delete)
- Encryption and decryption logic
- PII handling

Finding for insufficient critical path coverage: MUST_FIX.

### 1.3 Bug Fix Regression Tests

Every bug fix must include a regression test that:
1. Fails against the code before the fix.
2. Passes against the code after the fix.

Test name must reference the bug ticket: `testCardTokenRefresh_IPE12345_expiredTokenReturnsRefreshedToken`. Finding for bug fix without regression test: MUST_FIX.

### 1.4 Refactoring Coverage

Refactoring PRs must not decrease test coverage. Deleted or modified tests must be replaced with tests covering at least the same behaviors. Finding: MUST_FIX.

---

## 2. Test Types and Ownership

### 2.1 Unit Tests

**Owner:** Implementer. **Scope:** Single class, function, or module in isolation. All external dependencies mocked or stubbed. Each test under 100ms. Co-located with source or in a parallel test directory.

### 2.2 Integration Tests

**Owner:** Implementer or `qa.test-writer`. **Scope:** Interaction between two or more components. May use test databases, test queues, or test instances of external services — never production systems. Each test under 5 seconds.

### 2.3 End-to-End Tests

**Owner:** `qa.test-writer`. **Scope:** Full user flows from API entry point to database and back. Full test environment required. Full E2E suite must complete within CI timeout.

### 2.4 Performance Tests

**Owner:** Implementer or `qa.test-writer` with `perf.reliability` guidance. **When required:** New endpoints, significant changes to existing endpoints, changes to data access or caching patterns.

### 2.5 Security Tests

**Owner:** Implementer writes; `security.appsec-analyst` provides requirements. **Scope:** Auth bypass attempts, authorization boundary testing, input validation (injection, XSS), sensitive data exposure. **When required:** Changes to auth flows, new endpoints, input handling, or data exposure.

---

## 3. Test Quality Standards

### 3.1 Deterministic

Tests must produce the same result every time regardless of environment, time, or execution order. Use fixed timestamps, seeded random generators, and mocked external calls. Finding for flaky/non-deterministic test: MUST_FIX.

### 3.2 Isolated

Tests must not depend on other tests. Each test sets up its own preconditions and cleans up after itself. Shared mutable state between tests is prohibited. Finding: MUST_FIX.

### 3.3 Fast

Unit tests under 100ms. Integration tests under 5 seconds. Tests exceeding these limits must justify the duration. Finding for unjustified slow tests: SHOULD_FIX.

### 3.4 Meaningful Assertions

Assert on observable behavior, not implementation details. Assert on return values, state changes via public APIs, and side effects. Do not assert on private field values or method call counts unless the call is the behavior under test. Finding: SHOULD_FIX.

### 3.5 Clear Naming

Pattern: `[unitUnderTest]_[scenario]_[expectedBehavior]`. Finding for unclear test names: SHOULD_FIX.

### 3.6 Arrange-Act-Assert

Every test follows Arrange-Act-Assert (Given-When-Then). The three phases must be visually distinct (blank lines or comments). Finding for mixed phases: NITPICK.

### 3.7 One Logical Assertion Per Test

Each test verifies one logical behavior. Multiple `assert` statements are acceptable when collectively verifying one behavior. Multiple unrelated assertions must be split. Finding: SHOULD_FIX.

---

## 4. What Tests Must NOT Do

- **Test private methods** — test the public API. If private logic needs testing, extract it. Finding: SHOULD_FIX.
- **Use sleep for synchronization** — use `await`, latches, or condition variables instead. Finding: MUST_FIX.
- **Depend on execution order** — tests must pass individually, in any order, and in parallel. Finding: MUST_FIX.
- **Share mutable state** — no shared variables, database rows, files, or external resources between tests. Finding: MUST_FIX.
- **Mock everything in integration tests** — integration tests must test real (test) integrations. Finding: SHOULD_FIX.
- **Assert on exact error messages** — assert on error types, codes, or categories. Finding: SHOULD_FIX.

---

## 5. Test Data

### 5.1 Factories and Builders

Use factory functions or builder patterns to construct test data. Do not use raw hardcoded object literals scattered across test files. Finding: SHOULD_FIX.

### 5.2 Self-Contained Tests

All data a test needs must be created within the test or its setup method. No dependency on pre-existing data in test databases or shared fixtures. Finding: MUST_FIX.

### 5.3 No Production Data

Tests must never use real production data, production databases, production API keys, or real customer information. Finding: MUST_FIX.

### 5.4 Synthetic Sensitive Data

Test data representing sensitive information (card numbers, SSNs, tokens) must use obviously synthetic values (e.g., `4111111111111111`, `000-00-0000`, `test-token-abc123`). Finding for ambiguous sensitive test data: SHOULD_FIX.

---

## 6. Test Maintenance

### 6.1 Delete Obsolete Tests

When functionality is removed, its tests are removed in the same PR. Finding for orphaned tests: SHOULD_FIX.

### 6.2 Fix Flaky Tests Immediately

A flaky test is a bug. Fix the root cause, or delete and file a ticket to rewrite. Skipping/disabling without a ticket: SHOULD_FIX.

### 6.3 Test Code Quality

Test code follows the same coding standards as production code: meaningful names, no duplication, clear structure, no commented-out code. Finding: NITPICK.
