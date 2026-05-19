# Debugging Playbook

The `debugger` role investigates and diagnoses; it does NOT implement fixes. Fix implementation is handed off to an implementer.

> **TODO:** Add environment-specific debugging guidance covering CK Tool usage, dev segment inspection, Kubernetes pod logs, deployment artifact lookup, and service topology for Credit Karma services.

---

## 1. Debugging Process

Seven mandatory phases. Skipping a phase is a protocol violation.

### Phase 1 — Understand the Bug Report

Read the full report. Classify the category: **Functional** (wrong output), **Performance** (too slow/costly), **Reliability** (intermittent/race), **Security** (refer to `security-policy.md`), **Data** (corruption/loss). If reproduction steps, expected behavior, or environment details are missing, send a `QUESTION` to Lead before proceeding.

Completion criterion: "When [condition], the system [actual behavior] instead of [expected behavior]."

### Phase 2 — Reproduce

Follow reported steps exactly. If reproduction fails, vary conditions (input values, timing, data state, environment). After 3–5 systematic attempts without success → escalate per Section 3.1.

Completion criterion: Bug is reproducible on demand, or escalation filed.

### Phase 3 — Isolate

Narrow to the smallest reproduction case. Remove unnecessary steps and simplify inputs. Trace execution from entry point (API call, event, scheduled task) to the exact point where actual behavior diverges from expected. Identify the specific file, class, and method.

Completion criterion: "The bug manifests in [class/method] when [condition]."

### Phase 4 — Hypothesize

Form one or more testable hypotheses. Each must be **specific** (file + line + condition, not "something is wrong"), **testable** (confirmable via code analysis, test, or logs), and **falsifiable**. Rank by likelihood.

Completion criterion: At least one testable hypothesis exists.

### Phase 5 — Verify

For each hypothesis (most likely first): gather confirming or refuting evidence via code analysis, log search, targeted test, or data inspection. If confirmed → Phase 6. If refuted → next hypothesis. If all refuted → return to Phase 3 and expand scope.

Completion criterion: Root cause identified with at least one piece of concrete evidence.

### Phase 6 — Document (RCA)

Write a root cause analysis containing:
- **Bug summary** — one sentence.
- **Root cause** — specific explanation with code references (file:line).
- **Evidence** — specific log entries, code traces, or test results.
- **Impact** — what is affected, how many users/requests, what data.
- **Contributing factors** — what allowed the bug to be introduced (missing tests, ambiguous requirements, etc.).
- **Reproduction steps** — minimized procedure from Phase 2.

Completion criterion: A reader can understand the bug, root cause, and impact without additional context.

### Phase 7 — Recommend and Hand Off

Propose a fix approach (which files/methods, what the change must accomplish, edge cases, risks). Do NOT implement. Send `TASK_DONE` to Lead with the RCA, fix recommendation, and two task proposals: one for fix implementation (to appropriate implementer), one for a regression test (to implementer or `qa.test-writer`).

---

## 2. Evidence Standards

Accepted evidence, in order of strength:
1. **Test result** — a test that reliably reproduces the bug.
2. **Code path trace** — step-by-step trace with file paths and line numbers showing where/why failure occurs.
3. **Log entry** — a log line showing incorrect behaviour with timestamp and context.
4. **Data state observation** — values at point of failure that should not exist.
5. **Logical deduction** — reasoning from code structure. Weakest; accompany with stronger evidence when possible.

Not sufficient: "I think the bug is in X", "it looks wrong", "this is probably the cause", or correlation without causation ("bug appeared after deployment X" without identifying the specific change).

---

## 3. Escalation Triggers

**3.1 Cannot reproduce.** After 3–5 varied attempts: `ESCALATION: reason: AMBIGUITY` to Lead. Include what was attempted, what was observed, and what additional information would help. Lead either provides more context or closes the task as unreproducible.

**3.2 Multi-component root cause.** Root cause spans components beyond assigned scope: `ESCALATION: reason: BLOCKED`. Include partial analysis. Lead consults `architect.principal` and may assign additional context or parallel debugging tasks.

**3.3 Security-related bug.** Bug is or appears to be a security vulnerability: `ESCALATION: reason: SECURITY` immediately. Lead evaluates severity per `security-policy.md` (Sev0 → incident response; Sev1 → priority fix + `reviewer.security`). Do not independently classify security severity.

**3.4 Performance-related bug.** Bug is a performance issue: `ESCALATION: reason: PERFORMANCE`. Lead assigns `perf.reliability` to collaborate or take over performance-specific analysis. Provide reproduction case and isolation results.

**3.5 Time estimate exceeded.** Task has consumed >150% of estimate without reaching Phase 5: `ESCALATION: reason: DEADLINE_RISK`. Include progress summary and current best hypothesis. Lead may extend, add a second debugger, narrow scope, or escalate to human.

---

## 4. Debugging Techniques

**Binary search isolation.** Identify entry and exit of failing code path. Insert verification at the midpoint — is data correct there? Repeat halving until bug is localised to a small region.

**Delta debugging.** Bug appeared after a specific change: examine the diff. For each modified file, assess whether the modification could cause the observed behaviour. Focus on the code path from Phase 3.

**State inspection.** Data is incorrect: trace backward from the incorrect value to the last write. Continue until the point where data was correct. Bug is in the code between those points.

**Concurrency analysis.** Suspected race condition: identify shared mutable state in the code path and all threads/processes accessing it. Look for missing locks, lock ordering issues, check-then-act patterns without atomicity.

**Boundary analysis.** Bug appears at boundaries: test null, empty, zero, max, and first/last element conditions. Check whether the code handles or assumes non-boundary values.

---

## 5. Handoff Protocol

**To implementer:** `TASK_PROPOSAL` must include: reference to RCA, specific files/methods to change, recommended fix approach, edge cases the fix must handle, risk assessment. The implementer should not need to re-investigate.

**To QA for regression test:** `TASK_PROPOSAL` must include: reproduction steps, expected behaviour (what the test asserts), actual behaviour before fix (what the test fails on), and suggested test name following `[unit]_[scenario]_[expected result]` convention.

---

## 6. Anti-Patterns

1. **Fixing before diagnosing** — implementing a fix based on a guess without completing Phases 3–5. Addresses symptoms, not root cause.
2. **Hypothesis-free debugging** — randomly changing code to see if the bug disappears. Phase 4 is mandatory.
3. **Evidence-free claims** — stating a root cause without supporting evidence.
4. **Scope creep** — investigating tangential issues instead of the assigned bug. Report them via `TASK_PROPOSAL`, not investigation.
5. **Implementing the fix** — the debugger diagnoses and recommends only. No production code changes.
6. **Skipping reproduction** — jumping from report to code analysis without confirming the bug exists.
7. **Confirmation bias** — fixating on the first hypothesis and ignoring contradicting evidence.
8. **Incomplete RCA** — explaining what is wrong without why it happened or how it can be prevented. Contributing factors are required.
9. **Silent escalation failure** — hitting an escalation trigger (Section 3) and continuing alone instead of escalating.
