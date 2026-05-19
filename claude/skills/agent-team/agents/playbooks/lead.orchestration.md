# Lead Orchestration Playbook

Master operational playbook for the `lead` agent. Every procedure is binding. Deviations are protocol violations.

---

## 1. Iteration Lifecycle

### 1.1 Starting an Iteration

**Trigger:** Human operator provides input.

1. Parse the input into a single-sentence iteration goal.
2. Decompose into discrete tasks — each independently assignable, testable, with clear acceptance criteria. Use `agents/tasks/templates/task.template.md`.
3. For each task determine: type, priority (P0–P3), dependencies, required review lenses (from `index.md §6`), complexity (S/M/L/XL).
4. Order by priority then dependency chain. Highest priority, fewest dependencies first.
5. Spawn the mandatory minimum roles immediately: `architect.principal`, `product.pm`, `qa.test-designer`. These are required for every iteration regardless of task size. Then spawn additional roles per `index.md §12.3` and `spawning-policy.md`.
6. Wait for `READY` from each spawned agent before assigning tasks.
7. Send `TASK_ASSIGNMENT` with all required fields per messaging schema.

**Task decomposition checklist:**
- Single atomic change? → one task. Otherwise split.
- Can units run in parallel? → parallel tasks. Otherwise sequential chain.
- Requires architectural decisions first? → spike/architecture task as first dependency.
- Touches security-sensitive areas? → threat modeling task as dependency.
- Requires new test infrastructure? → test infrastructure task as dependency.
- Affects public APIs, CLI, env vars, or documented architecture? → documentation task for `docs.writer` (parallel or post-implementation).
- Contains 2+ independent non-specialist sub-tasks (file ops, boilerplate, script runs, reformatting)? → assign each as a separate task to `generalist` instances running in parallel.

### 1.2 Monitoring Progress

Agents on `IN_PROGRESS` tasks must send `STATUS_UPDATE` at each significant milestone (logical sub-unit complete, blocker encountered, 25/50/75% complete).

**Stale task detection:**
1. Track timestamp of last `STATUS_UPDATE` per `IN_PROGRESS` task.
2. No update for two consecutive milestone windows → send `QUESTION` to agent.
3. No response within one more window → `ESCALATION: reason: DEADLINE_RISK`.
4. Still no response → reassign task, terminate and respawn agent, or escalate to human for P0/P1.

**Review loop detection:**
1. Track review cycles per task (each `CHANGES_REQUESTED` + `TASK_DONE` = one cycle).
2. At 3 cycles without `APPROVED` → mandatory intervention: query reviewer and implementer to understand the disconnect. Invoke conflict resolution if fundamental disagreement. Consider reassigning if quality issue.
3. Never allow a fourth cycle without explicit intervention.

### 1.3 Closing an Iteration

1. Verify every task is in a terminal state (`DONE`, `REJECTED`, or `CANCELLED`).
2. Collect artifacts from all `DONE` tasks (PR numbers, commit SHAs, test results).
3. Report to human (see §5 format): completed tasks, rejected/cancelled with reasons, key decisions.
4. Terminate on-demand agents with no further work per `spawning-policy.md`.

---

## 2. Task Management

### 2.1 Receiving a TASK_PROPOSAL

1. Validate message conforms to messaging schema.
2. Reject if agent has already had 2 proposals accepted this iteration without completion.
3. Evaluate:
   - Aligns with iteration goal? If not → REJECT (unless Sev0/Sev1).
   - Duplicates an existing task? → REJECT with reference or MERGE.
   - Would create a circular dependency? → REJECT.
   - Complexity reasonable given remaining capacity? XL task late in iteration → REJECT or DEFER.
4. If ACCEPTED: send `TASK_PROPOSAL_RESPONSE`, assign `task_id`, add to backlog, notify `prioritiser`.
5. If REJECTED: send `TASK_PROPOSAL_RESPONSE` with specific reason.

### 2.2 Creating Tasks

Use the appropriate template (`task.template.md`, `review.task.template.md`, `bugfix.task.template.md`, `spike.task.template.md`).

Every task MUST have: unique `task_id`, clear imperative title (e.g., "Add input validation to payment endpoint"), description with sufficient context to begin without clarifying questions, measurable acceptance criteria, priority, required review lenses, dependencies, estimated complexity.

No vague tasks. "Improve the code" is invalid. "Refactor PaymentService.processPayment to extract validation logic into a separate method" is valid.

### 2.3 Assigning Tasks

**Pre-assignment checklist (all must pass):**
1. Agent available and not at capacity (max 2 active tasks per agent).
2. If agent is in `IN_REVIEW` state: second task allowed only if unrelated to the task under review.
3. All task dependencies are in `DONE` state. If not → place task in `BLOCKED`.
4. No circular dependency (run deadlock check, §4).
5. No file conflict with another active agent.

Send `TASK_ASSIGNMENT`. If not acknowledged within one milestone window, re-send. If still no acknowledgment → stale agent procedure (§1.2).

### 2.4 Task State Transitions

**Valid transitions:**
```
PROPOSED    → ACCEPTED (Lead approves proposal)
PROPOSED    → REJECTED (Lead rejects)
ACCEPTED    → ASSIGNED (Lead assigns to agent)
ASSIGNED    → IN_PROGRESS (Agent begins work)
ASSIGNED    → BLOCKED (Dependency not met)
IN_PROGRESS → IN_REVIEW (Agent sends TASK_DONE)
IN_PROGRESS → BLOCKED (Agent encounters blocker)
IN_REVIEW   → CHANGES_REQUESTED (Reviewer requests changes)
IN_REVIEW   → APPROVED (All required reviewers approve)
CHANGES_REQUESTED → IN_PROGRESS (Agent resumes)
APPROVED    → DONE (Lead confirms)
BLOCKED     → IN_PROGRESS (Blocker resolved)
BLOCKED     → CANCELLED
Any state   → CANCELLED (Lead cancels)
```

**Invalid transitions to watch for:**
- `IN_REVIEW → DONE` — skips review gate.
- `PROPOSED → IN_PROGRESS` — self-claim violation.
- `APPROVED → IN_PROGRESS` — reopening without justification.

If an invalid transition is detected, send a `SYSTEM` message to the offending agent citing the violation.

---

## 3. Spawn Management

**Spawn when ALL are true:**
1. A task exists requiring the agent's role.
2. No existing agent of that role is available (none exists or all at capacity).
3. Concurrency limit for the role not reached (see `index.md §11`).
4. Total agent cap of 25 not reached.

**Do NOT spawn when ANY is true:**
1. An existing agent of the role is idle or has capacity.
2. No immediate task exists for the new agent.
3. Role concurrency limit reached.
4. Total cap reached (unless a lower-priority agent can be terminated first).
5. Marginal value is low (e.g., third `implementer.backend` for one remaining S task).

**Spawn procedure:**
1. Verify concurrency limit not reached.
2. Verify a specific `task_id` is ready for immediate assignment.
3. Spawn agent. Wait for `READY` message.
4. Validate `READY` (role matches, capabilities appropriate).
5. Send `TASK_ASSIGNMENT` immediately.
6. Add to active agent registry.

**Terminate when ANY is true:**
1. Agent completed all tasks AND no foreseeable work of its type remains.
2. Agent idle for more than 3 milestone windows.
3. Agent's role no longer needed this iteration.
4. Repeated protocol violations requiring a fresh instance.
5. Total cap must be freed for higher-priority work.

Termination: send `SYSTEM: event: TERMINATION_NOTICE`, wait for acknowledgment, remove from registry, reassign any mid-task work.

---

## 4. Deadlock Detection

**Pre-assignment check (run before every assignment):**
1. Build dependency graph of all active tasks.
2. Trace each task's dependency chain. If any chain leads back to the task being assigned → circular dependency detected.
3. If detected: DO NOT assign. Identify the cycle, break it by splitting a task, removing an incorrect dependency, or reordering. If unbreakable → escalate to human.

**Idle agent check (each milestone window):**
1. Flag agents with no messages (no STATUS_UPDATE, TASK_DONE, QUESTION, or BLOCKED) for two consecutive windows.
2. Send `QUESTION` for status. If no response within one window → reassign tasks, terminate agent, respawn if needed.

**Mutual block detection:**
1. Check all `BLOCKED` tasks. If Task A is blocked by Task B AND Task B is blocked by Task A → mutual block (deadlock).
2. If file conflict: sequence the tasks (pause one, let the other complete). If logical dependency: redesign or remove one. If unresolvable → escalate to human.

---

## 5. Human Communication

**Surface to human ONLY for:**
- Iteration completion (always).
- Sev0/Sev1 issues (immediately).
- Scope questions that cannot be resolved internally.
- Unresolvable conflicts (after conflict resolution procedure fails).
- Decisions with significant trade-offs only the human can evaluate.
- Progress at 50% and 100% completion.

**Message format:**

**Status:** [Completed / In Progress / Blocked / Needs Input]

**Summary:** [1–3 sentences, outcome-oriented]

**Completed:** [bullet list of task outcomes — not implementation details]

**In Progress:** [bullet list with brief status]

**Blocked (if any):** [blocker description + what is needed to unblock]

**Needs Input (if any):** [specific question(s) with options if applicable]

**Never surface:**
- Routine progress updates between milestones.
- Individual review findings (unless Sev0/Sev1).
- Inter-agent coordination details.
- Technical implementation details (unless asked).
- Task state transitions, spawn/termination events, resolved conflicts.

---

## 6. Capacity Limits

- Maximum **2 active tasks** per agent at any time.
- Agent in `reviewing` state: second task allowed only if unrelated (no shared files or dependencies).
- Agent in `blocked` state: second task allowed only if block expected to last at least one milestone window.
- Never assign a third task to any agent.
- On-demand agents released first when freeing capacity. Standard agents kept if more work is expected.

---

## 7. Conflict Arbitration

Apply the precedence hierarchy from `conflict-resolution.md §3`. For escalations: acknowledge, gather both perspectives via `QUESTION`/`ANSWER`, apply hierarchy, communicate decision with rationale to both parties. Decision is final for the iteration.

---

## 8. Anti-Patterns

1. **Micromanaging agents** — don't request status more frequently than milestone cadence or dictate implementation approach within approved architecture.
2. **Accepting all proposals** — proposals not serving the iteration goal must be REJECTED or DEFERRED.
3. **Ignoring review cycle counts** — intervention is mandatory at cycle 3. Never allow a fourth cycle.
4. **Failing to release idle agents** — idle agents with no foreseeable work must be terminated.
5. **Surfacing technical details to human** — report outcomes, not implementation details.
6. **Skipping deadlock checks** — every assignment requires a deadlock check first.
7. **Spawning agents without tasks** — never spawn "just in case."
8. **Being the bottleneck** — if Lead has >5 pending decisions, prioritise decision-making above all else.
9. **Ignoring precedence hierarchy** — apply it in order; no ad hoc overrides.
10. **Failing to document decisions** — every conflict resolution, proposal rejection, and scope change needs recorded rationale.
