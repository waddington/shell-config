# Parallelism Guide

Lead uses this playbook to maximise throughput while preventing conflicts, redundancy, and coordination failures.

**Parallelism is the default goal.** When a task feels hard to parallelise, the first instinct should be to redesign the work — not to serialize it. Involve `architect.principal` early to decompose features into independently implementable units. Temporary architectural seams (interfaces, stubs, clearly bounded modules) enable parallel implementation even when the final design will recombine those units. After parallel implementation completes, `architect.principal` reviews the combined result and refines the design — merging, simplifying, or adjusting boundaries to achieve the best architectural outcome. The cost of a post-integration design pass is almost always lower than the cost of serial implementation.

---

## 1. When to Parallelize

Two tasks are genuinely independent when ALL of the following are true:
- Neither depends on the output of the other.
- They do not modify the same files or overlapping code regions.
- They do not require the same singleton resource (e.g., both needing `architect.principal` for a blocking decision).
- They can be reviewed independently.

**If tasks seem hard to parallelise, try first to:** define a clear interface or contract between them so implementers can work against a stub; split at a module or service boundary; use feature flags to let parallel work coexist without conflict. Engage `architect.principal` to design the split. Serialize only when none of these approaches is feasible.

**Safe parallelism scenarios:**
- Independent feature tasks touching different modules or services.
- Multi-lens review — all required reviewers review the same PR simultaneously.
- Test writing for Feature A while implementing Feature B (no shared test infrastructure).
- Security analysis and correctness review running concurrently.
- Documentation for a completed feature while implementing a different one.
- Two `debugger` instances investigating bugs in unrelated components.
- Threat modeling for Feature A while implementing non-security-sensitive Feature B.

**Parallel readiness checklist:**
- [ ] Dependency graph shows no path between the parallel tasks.
- [ ] No overlapping file modifications.
- [ ] No shared singleton resource bottleneck.
- [ ] Agents available for both tasks.
- [ ] Reviews for both tasks can proceed independently.
- [ ] Combined output will not create merge conflicts.

---

## 2. When to Serialize

**Mandatory serialization (parallelizing these is a protocol violation):**

1. **Explicit dependency** — Task B has `blocked_by: [task_A_id]`. No exceptions.
2. **Implementation before review** — reviewers cannot review incomplete work.
3. **Architectural decisions before implementation** — `architect.principal` must approve design before implementation begins.
4. **Threat modeling before security-sensitive implementation** — threat model produces mitigations that become acceptance criteria.
5. **Test plan before test writing** — `qa.test-designer` must complete before `qa.test-writer` begins.
6. **Schema migration before dependent code changes** — migration must be applied and verified first.
7. **Dependency updates before code using new APIs** — dependency must merge first.

**Serialization decision tree:**
1. Does Task B reference any output of Task A (file, API, schema, decision)? YES → serialize.
2. Do both tasks modify the same file? YES → serialize (or redesign).
3. Does Task B's acceptance criteria depend on a decision Task A produces? YES → serialize.
4. Would a merge conflict result from concurrent execution? YES → serialize. Otherwise → parallelize.

---

## 3. Parallelism Patterns

### 3.1 Fan-Out

Multiple independent tasks assigned to multiple agents simultaneously.

1. Identify all ready tasks (no unmet dependencies).
2. Check each pair for file-level conflicts.
3. Assign all conflict-free tasks. Send `TASK_ASSIGNMENT` messages in rapid succession — no need to wait for acknowledgment before sending the next.
4. Track each task independently.

If one task fails or blocks: others continue unaffected. If a file conflict emerges during execution, immediately pause the later-starting agent per `index.md §11.2`.

### 3.2 Fan-In

Multiple agents produce outputs that must be collected before the next step (e.g., multi-lens review).

1. Assign all fan-out tasks simultaneously.
2. Maintain a checklist of all expected results.
3. As each result arrives, mark it off.
4. When ALL results collected, synthesize:
   - All `APPROVED` → task moves to `APPROVED`.
   - Any `CHANGES_REQUESTED` → compile all findings into a single consolidated message to the implementer.
   - Any `BLOCKED` → escalate immediately.
5. Never forward individual reviewer results — always send one consolidated message.

If a reviewer is unresponsive: query, then spawn a replacement. If the missing lens is non-critical (e.g., `reviewer.quality` on a hotfix), proceed. If critical (`reviewer.security` on security-sensitive change), escalate to human.

### 3.3 Pipeline

Work flows through sequential stages with parallelism within stages.

| Stage | Who | Parallelism |
|-------|-----|-------------|
| Design | `product.pm`, `architect.principal`, `security.threat-modeler` | Parallel if covering different aspects; threat model may depend on arch design |
| Implementation | Implementers | Up to 3 backend in parallel on non-overlapping work |
| Review | All required reviewers | All review in parallel — most common scenario |
| QA | `qa.test-designer` → `qa.test-writer` | Sequential (plan before writing) |
| Release | Lead | Typically sequential |

### 3.4 Divide-and-Merge

A large task decomposed into sub-tasks for parallel agents, results merged.

1. Lead decomposes into per-module sub-tasks.
2. Assigns each to a separate implementer.
3. Implementers work independently and send `TASK_DONE`.
4. Lead creates a merge task: combine all outputs into a single PR.
5. Merged result reviewed as a unit.

Risk: merge conflicts at step 4. Mitigate by ensuring sub-tasks are truly non-overlapping at the file level.

---

## 4. Preventing Context Thrash

Context thrash occurs when an agent switches between unrelated tasks, losing focus and increasing error rate.

**Rules:**
1. **One task at a time** — this is the default. Two tasks is the exception.
2. **Second task only while waiting** — allowed when agent is in `IN_REVIEW` state IF: the second task is unrelated (no shared files, dependencies, or domain concepts), and Lead explicitly determines the wait time justifies the switch.
3. **Never more than 2 tasks** — absolute maximum.
4. **No mid-task reassignment** — do not reassign an `IN_PROGRESS` task unless the agent is unresponsive (3+ missed milestone windows), terminated for violations, or a Sev0 incident requires role reallocation.
5. **No rapid switching** — don't pull an agent off Task B to handle Task A's review feedback unless P0/P1.

**Context thrash signals:** agent references wrong task in STATUS_UPDATE, work quality declines (more MUST_FIX findings), agent asks for context already provided, task completion time increases vs. prior similar tasks. If detected → reduce to 1 active task.

---

## 5. Preventing Redundant Work

**Pre-assignment overlap check:**
1. Check task descriptions for overlap (same files, methods, business logic).
2. Check file targets against all active `IN_PROGRESS` tasks. If overlap: defer, redesign to avoid overlap, or combine into one task.
3. Before accepting a `TASK_PROPOSAL`, search backlog for similar titles, descriptions, or file targets.

**Review deduplication:** Each reviewer reviews ONLY through their assigned lens. Out-of-lens observations go to Lead via `STATUS_UPDATE`, never into `REVIEW_RESULT`. If two reviewers flag the same issue from different lenses, Lead consolidates into a single finding.

**Proposal deduplication:**
- >50% scope overlap with existing task → REJECT, reference existing task.
- Partial overlap (<50%) → consider MERGING into existing task.
- Subset of existing task → REJECT.

---

## 6. File-Level Conflict Management

**Before assigning a task:**
1. Identify files the task is likely to modify.
2. Check all active `IN_PROGRESS` tasks for their target files.
3. If overlap found:
   - Same file, clearly separated sections → parallel allowed but risky.
   - Same file, same section → serialize.
   - Same file, unknown sections → treat as conflict, serialize.

**If conflict detected during execution:**
1. Immediately pause the agent that started on the conflicting file later (by timestamp).
2. Send `SYSTEM` message to the paused agent explaining the pause.
3. Let the first agent complete their modifications.
4. Once first agent's task reaches `IN_REVIEW` or `DONE`, send `UNBLOCKED` to paused agent.
5. Paused agent must rebase/update to account for first agent's changes.

---

## 7. Anti-Patterns

1. **Premature parallelization** — tasks with unresolved dependencies run concurrently, causing rework.
2. **Over-parallelization** — coordination overhead exceeds throughput benefit.
3. **Under-parallelization** — serializing tasks that could safely run in parallel wastes time. If tasks seem inseparable, treat that as a design problem: engage `architect.principal` to create boundaries that enable parallel work.
4. **Ignoring file conflicts** — parallel tasks without conflict checks leads to merge conflicts.
5. **Fan-in without tracking** — starting multi-lens review without a checklist of expected results leads to lost reviews.
6. **Context switching as a feature** — two active tasks should be exceptional, not routine.
7. **Redundant review findings** — reviewers duplicating findings across lenses. Stick to assigned lens.
8. **Serial bottleneck on Lead** — Lead sequentially processing assignments that could be batched simultaneously.
