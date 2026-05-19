# Dependencies

This document defines how task dependencies are declared, managed, and resolved. Dependencies create ordering constraints between tasks -- a task with dependencies cannot begin until its dependencies are satisfied. Proper dependency management prevents wasted work, conflicts, and deadlocks.

---

## Dependency Types

### blocks / blocked-by
The primary dependency relationship. This is a hard constraint.

- **blocks**: "TASK-0042 blocks TASK-0045" means TASK-0045 cannot enter IN_PROGRESS until TASK-0042 is DONE.
- **blocked-by**: The inverse. "TASK-0045 is blocked-by TASK-0042" means the same thing.

Both sides of the relationship must be recorded:
- The blocking task (TASK-0042) lists TASK-0045 in its `Blocks` field.
- The blocked task (TASK-0045) lists TASK-0042 in its `Dependencies` field.

The Lead is responsible for ensuring both sides are consistent. If an agent declares a dependency, the Lead updates the corresponding `Blocks` field on the other task.

When to use: When one task produces an artifact, interface, or state that another task requires to begin. Example: "Implement CardService interface" must be DONE before "Implement CardController using CardService" can begin.

### requires-review-from
A soft dependency indicating that a specific reviewer should review this task, but the task is not blocked by another task.

This is tracked in the `Required Review Gates` field, not in the `Dependencies` field. It does not prevent the task from entering IN_PROGRESS -- it prevents the task from reaching APPROVED without the specified reviewer's approval.

When to use: When a change touches a domain that requires specific expertise (security, performance, architecture).

### informs
An informational relationship. The outcome of one task provides useful context for another, but does not block it.

This is tracked in the task Notes, not in the `Dependencies` field. The informed task may begin without waiting for the informing task.

When to use: When a spike produces findings that would be useful for an implementation task, but the implementation could proceed with assumptions. Example: "Spike: Evaluate caching options" informs "Implement caching for CardService" -- but the implementation team could start with a default approach while the spike is in progress.

### follows
A sequencing preference (not a hard block). One task should ideally be done after another, but it is not strictly blocked.

This is tracked in the task Notes, not in the `Dependencies` field. The Lead uses this information for scheduling but may reorder if priorities demand it.

When to use: When a particular ordering makes work cleaner or reduces merge conflicts but is not strictly required. Example: "Refactor CardService to use new pattern" follows "Add new utility module" -- the refactor could technically proceed without the utility, but it would be cleaner to wait.

---

## How to Declare Dependencies

Dependencies are declared in the task template's `Dependencies` field as a list of `TASK-NNNN` identifiers.

In the task template:
```
Dependencies: [TASK-0042, TASK-0043]
Blocks: [TASK-0050]
```

When proposing a new task via `TASK_PROPOSAL`, the proposer should include known dependencies. The Lead validates and adjusts dependencies during acceptance.

Rules:
1. Dependencies must reference valid `TASK-NNNN` identifiers. You cannot depend on a task that does not exist.
2. A task cannot depend on itself (`TASK-0042` cannot list `TASK-0042` in its Dependencies).
3. Dependencies must be on tasks in a non-terminal state. You cannot depend on a task that is REJECTED or CANCELLED (since it will never be DONE). Depending on a DONE task is permitted but unnecessary (the dependency is already satisfied).
4. When a dependency is added after task creation, the Lead must communicate the change via `STATUS_UPDATE`.

---

## Circular Dependency Detection

Circular dependencies are forbidden. A circular dependency exists when Task A depends on Task B, which depends on Task C, which depends on Task A (or any longer cycle).

### Detection Process
Before assigning a task, the Lead must verify that no circular dependency exists. The check is:

1. Start with the task being assigned.
2. Follow its `Dependencies` list to each dependency.
3. For each dependency, follow that task's `Dependencies` list.
4. Continue recursively until either:
   - All paths terminate at tasks with no dependencies (or tasks already DONE). Result: no cycle.
   - A path reaches the original task. Result: circular dependency detected.

### Resolution
If a circular dependency is detected, the Lead must resolve it before any of the involved tasks can be assigned:

1. **Re-evaluate the dependency.** Often, one of the dependencies is not truly blocking -- it may be an `informs` or `follows` relationship that was incorrectly declared as `blocked-by`. Downgrade it.
2. **Split a task.** If Task A truly depends on part of Task B, and Task B depends on part of Task A, extract the independent parts into separate tasks to break the cycle.
3. **Merge tasks.** If two tasks are so tightly coupled that they cannot be done independently, merge them into a single task.
4. **Introduce an interface.** Define an agreed-upon interface contract so both tasks can proceed independently against the contract.

---

## Dependency Resolution

### Blocked task cannot start
A task with unmet dependencies remains in ACCEPTED state. The Lead must not assign it until all dependencies are DONE.

If a dependency is taking longer than expected and the blocked task is high-priority:
1. The Lead evaluates whether the dependency is truly blocking or can be relaxed.
2. If the dependency cannot be relaxed, the Lead may reprioritize the blocking task to accelerate it.
3. If the blocking task is itself blocked, the Lead traces the dependency chain to find the root blocker and addresses it.

### Lead must resolve or reorder
The Lead is responsible for ensuring that the dependency graph is acyclic and that work can proceed. This includes:
- Regularly reviewing the dependency graph for bottlenecks.
- Proactively resolving blockers before they cause idle agents.
- Communicating dependency status changes to affected agents.

When a blocking task reaches DONE, the Lead must:
1. Identify all tasks that were waiting on it (from its `Blocks` field).
2. Check if those tasks have any remaining unmet dependencies.
3. If all dependencies are now met, transition the previously blocked task from ACCEPTED to ASSIGNED (or from BLOCKED to its previous state).
4. Notify the assigned agent via `UNBLOCKED` message.

---

## Cross-Iteration Dependencies

Dependencies between tasks in different iterations are **explicitly discouraged**. They create scheduling risk because the blocking task's iteration may slip, cascading delays to the dependent task's iteration.

### When cross-iteration dependencies are acceptable
- The blocking task is in an earlier iteration and is expected to be DONE before the dependent task's iteration begins.
- The Lead has explicitly approved the cross-iteration dependency and documented the risk.

### When cross-iteration dependencies must be eliminated
- The blocking task is in the same iteration as the dependent task but in a later phase. This indicates a sequencing problem within the iteration.
- The dependent task is in a high-priority iteration and the blocking task is in a lower-priority iteration. The blocking task should be pulled into the earlier iteration or the dependency should be restructured.

### Documentation
Cross-iteration dependencies must be documented in the task Notes with:
- The iteration of the blocking task
- The iteration of the dependent task
- Justification for why the cross-iteration dependency exists
- Risk assessment (what happens if the blocking task slips)

---

## External Dependencies

Not all dependencies are on tasks within the system. External dependencies include:
- Waiting for a third-party API to be available
- Waiting for an infrastructure change managed by another team
- Waiting for a design decision from stakeholders
- Waiting for a security review from an external team

### Declaration
External dependencies are NOT declared in the `Dependencies` field (which takes `TASK-NNNN` identifiers only). Instead, they are documented in the task Notes with:
- A description of the external dependency
- Who/what the dependency is on
- Expected resolution date (if known)
- Impact if the dependency is not resolved

If a task is blocked by an external dependency, it transitions to BLOCKED with the `blocked_by` field in the `BLOCKED` message containing a description (not a task ID).

### Tracking
The Lead tracks external dependencies separately and follows up with the external party. The Lead may create a placeholder chore task to represent the external dependency for visibility.

---

## Dependency Visualization

The Lead should maintain a mental model (or documented model) of the current dependency graph. This includes:
- Which tasks are currently blocked and by what
- Critical path: the longest chain of dependencies that determines the minimum time to complete the iteration
- Bottleneck tasks: tasks that appear in the `Dependencies` list of many other tasks

The dependency graph should be reviewed at the start of each iteration and whenever a significant change occurs (task cancelled, new high-priority task added, dependency added or removed).

---

## Anti-Patterns

### Undeclared dependencies
When Task B actually requires Task A's output but does not list it in Dependencies. This causes Task B to start, discover it cannot proceed, and transition to BLOCKED -- wasting time. All known dependencies must be declared upfront.

### Circular chains
As described above, circular dependencies create deadlocks. The Lead must detect and resolve them before assignment.

### Depending on tasks in REJECTED state
A REJECTED task will never be DONE. A dependency on a REJECTED task means the dependent task can never start. The Lead must either remove the dependency, find an alternative approach, or cancel the dependent task.

### Depending on tasks in CANCELLED state
Same as REJECTED -- a CANCELLED task will never be DONE. The dependency must be removed or the dependent task cancelled.

### Hidden dependencies via shared state
When two tasks modify the same code or data without a declared dependency, they create implicit ordering constraints that can cause merge conflicts or inconsistent state. If two tasks will modify the same files, declare an explicit dependency or coordinate via the Lead.

### Over-declaring dependencies
Declaring a dependency when none truly exists creates artificial sequencing constraints and reduces parallelism. Only declare `blocked-by` dependencies when the blocking task genuinely must be DONE first. Use `informs` or `follows` for softer relationships.
