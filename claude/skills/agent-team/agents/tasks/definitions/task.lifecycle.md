# Task Lifecycle

This document defines every state a task can occupy, the valid transitions between states, who may trigger each transition, and what conditions must be met. All agents and the Lead must adhere to these rules. No exceptions.

---

## State Diagram

```
                         +-----------+
                         | REJECTED  |  (terminal)
                         +-----------+
                              ^
                              | (Lead rejects)
                              |
+----------+   Lead    +----------+   Lead    +----------+
| PROPOSED | --------> | ACCEPTED | --------> | ASSIGNED |
+----------+  accepts  +----------+  assigns  +----------+
                                                    |
                                                    | Agent begins work
                                                    v
+-----------+          +-------------+         +-------------+
| CANCELLED | <------- | IN_PROGRESS | ------> |  IN_REVIEW  |
+-----------+  Lead    +-------------+  Agent  +-------------+
 (terminal)   cancels     ^      ^     submits     |      |
                          |      |      work       |      |
                          |      +--------+        |      |
                          |               |        v      |
                          |    +-----------------+ |      |
                          +--- | CHANGES_REQ'D  | |      |
                           Agent +-----------+---+ |      |
                           addresses         |     |      |
                           findings          |     v      |
                                             |  +----------+
                                             |  | APPROVED |
                                             |  +----------+
                                             |       |
                                             |       | Lead confirms DoD
                                             |       v
                    +----------+             |  +------+
                    | BLOCKED  | <-----------+  | DONE |  (terminal)
                    +----------+  (from any     +------+
                         |         active state)
                         |
                         v
                   (Lead resolves,
                    returns to previous
                    active state)
```

---

## State Definitions

### PROPOSED
- **Definition**: A task has been suggested but not yet evaluated by the Lead.
- **Who can enter it**: Any agent may propose a task by sending a `TASK_PROPOSAL` message to the Lead.
- **Entry conditions**: The task must be well-formed per `task.template.md`. All required fields must be present. The proposal must include a rationale explaining why the task is needed.
- **Required actions**: The Lead must evaluate the proposal and either accept it (transition to ACCEPTED) or reject it (transition to REJECTED). The Lead communicates the decision via a `TASK_PROPOSAL_RESPONSE` message.
- **Expected duration**: Proposals should be evaluated within a reasonable timeframe. P0 proposals must be evaluated immediately.

### ACCEPTED
- **Definition**: The Lead has approved the proposal. The task enters the work queue but has not yet been assigned to a specific agent.
- **Who can enter it**: Only the Lead, by accepting a PROPOSED task.
- **Entry conditions**: The Lead has reviewed the proposal, confirmed it is well-formed, and determined it is worth doing. The Lead assigns a `TASK-NNNN` identifier, sets the iteration, and validates that the task does not create circular dependencies.
- **Required actions**: The Lead must assign the task to an agent (transition to ASSIGNED) or defer it to a future iteration.

### ASSIGNED
- **Definition**: The Lead has assigned the task to a specific agent. The agent has been notified and is expected to begin work.
- **Who can enter it**: Only the Lead, by assigning an ACCEPTED task to an agent.
- **Entry conditions**: The task is in ACCEPTED state. An appropriate agent is available. All dependencies listed in the task are in DONE state (or the task has no dependencies). The agent is notified via a `TASK_ASSIGNMENT` message.
- **Required actions**: The assigned agent must acknowledge receipt and begin work (transition to IN_PROGRESS). If the agent identifies blockers before starting, the agent must transition the task to BLOCKED.

### IN_PROGRESS
- **Definition**: The assigned agent is actively working on the task.
- **Who can enter it**: The assigned agent, by beginning work on an ASSIGNED task. Also entered when returning from CHANGES_REQUESTED (after addressing review findings) or BLOCKED (after the blocker is resolved).
- **Entry conditions**: The task was in ASSIGNED, CHANGES_REQUESTED, or BLOCKED state. For CHANGES_REQUESTED, the agent must have addressed all MUST_FIX findings before returning to IN_PROGRESS.
- **Required actions**: The agent must send `STATUS_UPDATE` messages at meaningful milestones (not time-based, but progress-based). When work is complete, the agent sends a `TASK_DONE` message and a `REVIEW_REQUEST` message, transitioning the task to IN_REVIEW.

### IN_REVIEW
- **Definition**: The agent has submitted completed work and is awaiting reviewer verdicts.
- **Who can enter it**: The assigned agent, by submitting work for review from IN_PROGRESS.
- **Entry conditions**: The agent has sent a `TASK_DONE` message with `tests_passing: true` and a `REVIEW_REQUEST` message listing the artifacts to review. All acceptance criteria should be met from the agent's perspective.
- **Required actions**: Each required reviewer must complete their review and send a `REVIEW_RESULT` message. If all reviewers approve, the task transitions to APPROVED. If any reviewer issues CHANGES_REQUESTED, the task transitions to CHANGES_REQUESTED. If any reviewer issues BLOCKED, the Lead is notified via ESCALATION.

### CHANGES_REQUESTED
- **Definition**: At least one reviewer has found MUST_FIX issues that the implementer must address before the task can be approved.
- **Who can enter it**: Triggered automatically when a reviewer sends a `REVIEW_RESULT` with verdict `CHANGES_REQUESTED`.
- **Entry conditions**: The task was in IN_REVIEW state. At least one `REVIEW_RESULT` message has verdict `CHANGES_REQUESTED` with one or more `MUST_FIX` findings.
- **Required actions**: The assigned agent must address all MUST_FIX findings. SHOULD_FIX findings should be addressed but do not block. NITPICK findings are at the agent's discretion. Once findings are addressed, the agent transitions back to IN_PROGRESS and then to IN_REVIEW with a new `REVIEW_REQUEST`.

### APPROVED
- **Definition**: All required reviewers have approved the task. No open MUST_FIX findings remain.
- **Who can enter it**: Triggered automatically when the last required reviewer sends a `REVIEW_RESULT` with verdict `APPROVED` and no other reviewer has an outstanding `CHANGES_REQUESTED` or `BLOCKED` verdict.
- **Entry conditions**: Every reviewer listed in Required Review Gates has issued an `APPROVED` verdict. The Lead has confirmed all required reviewers have approved.
- **Required actions**: The Lead must verify the Definition of Done checklist. If DoD is fully met, the Lead transitions the task to DONE. If DoD is partially met, the Lead identifies specific gaps and the task remains in APPROVED until gaps are closed.

### DONE
- **Definition**: The task is complete. The Lead has confirmed that the Definition of Done is fully met.
- **Who can enter it**: Only the Lead, after verifying DoD.
- **Entry conditions**: The task is in APPROVED state. All DoD checklist items are verified by the Lead. The Lead sends an `APPROVAL` message with scope `TASK`.
- **Required actions**: None. This is a terminal state. The task record is preserved for audit.
- **Terminal**: No transitions out of DONE are permitted.

### REJECTED
- **Definition**: The Lead has rejected the task proposal. The task will not be done.
- **Who can enter it**: Only the Lead, from PROPOSED state.
- **Entry conditions**: The Lead has evaluated the proposal and determined it should not be done. The Lead provides a reason in the `TASK_PROPOSAL_RESPONSE` message.
- **Required actions**: None. This is a terminal state. The proposing agent may submit a revised proposal as a new task if appropriate.
- **Terminal**: No transitions out of REJECTED are permitted.

### BLOCKED
- **Definition**: The assigned agent cannot proceed due to an external dependency or unresolved issue.
- **Who can enter it**: The assigned agent, from any active state (ASSIGNED, IN_PROGRESS, IN_REVIEW, CHANGES_REQUESTED).
- **Entry conditions**: The agent has identified a specific blocker and sends a `BLOCKED` message specifying `blocked_by` (a task ID or description) and `impact`.
- **Required actions**: The Lead must resolve the blocker -- by completing the blocking task, reassigning work, removing the dependency, or providing the needed information. Once resolved, the Lead sends an `UNBLOCKED` message and the task returns to its previous active state.

### CANCELLED
- **Definition**: The Lead has cancelled the task. It will not be completed.
- **Who can enter it**: Only the Lead, from any non-terminal state.
- **Entry conditions**: The Lead determines the task is no longer needed (e.g., requirements changed, duplicate of another task, superseded by a different approach). The Lead provides a reason.
- **Required actions**: If the task had work in progress, any partial artifacts should be documented in the Notes section for future reference. If other tasks depended on this one, those dependencies must be re-evaluated.
- **Terminal**: No transitions out of CANCELLED are permitted.

---

## Valid Transitions Table

| From | To | Triggered By | Condition |
|---|---|---|---|
| PROPOSED | ACCEPTED | Lead | Proposal is well-formed and approved |
| PROPOSED | REJECTED | Lead | Proposal is rejected with reason |
| ACCEPTED | ASSIGNED | Lead | Agent identified and available, dependencies met |
| ASSIGNED | IN_PROGRESS | Assigned agent | Agent begins work |
| ASSIGNED | BLOCKED | Assigned agent | Blocker identified before work starts |
| IN_PROGRESS | IN_REVIEW | Assigned agent | Work complete, TASK_DONE and REVIEW_REQUEST sent |
| IN_PROGRESS | BLOCKED | Assigned agent | Blocker identified during work |
| IN_REVIEW | APPROVED | Reviewers (all) | All required reviewers approve |
| IN_REVIEW | CHANGES_REQUESTED | Reviewer (any) | At least one reviewer issues CHANGES_REQUESTED |
| IN_REVIEW | BLOCKED | Assigned agent | Blocker identified during review |
| CHANGES_REQUESTED | IN_PROGRESS | Assigned agent | Agent addresses findings, resumes work |
| CHANGES_REQUESTED | BLOCKED | Assigned agent | Blocker identified while addressing findings |
| APPROVED | DONE | Lead | DoD verified by Lead |
| BLOCKED | (previous state) | Lead | Blocker resolved, UNBLOCKED sent |
| Any non-terminal | CANCELLED | Lead | Task no longer needed |

---

## Invalid Transitions (Explicitly Forbidden)

The following transitions are never permitted. Any agent or process attempting these transitions must be rejected:

1. **PROPOSED -> IN_PROGRESS**: A task cannot skip acceptance and assignment. It must go through ACCEPTED and ASSIGNED first. This ensures the Lead has vetted the work and assigned it deliberately.

2. **PROPOSED -> ASSIGNED**: A task cannot be assigned without being accepted first. Acceptance is a deliberate decision that the work is worth doing.

3. **IN_PROGRESS -> DONE**: A task cannot skip review. All tasks must go through IN_REVIEW and APPROVED before reaching DONE. This ensures quality gates are enforced.

4. **IN_PROGRESS -> APPROVED**: A task cannot be approved without going through IN_REVIEW. Reviewers must explicitly evaluate the work.

5. **APPROVED -> IN_PROGRESS**: Once all reviewers have approved, the task cannot go back to IN_PROGRESS. If new issues are found after approval, a new task must be created. The CHANGES_REQUESTED state exists specifically for the review cycle.

6. **DONE -> (any state)**: DONE is terminal. Completed tasks are immutable. If follow-up work is needed, create a new task.

7. **REJECTED -> (any state)**: REJECTED is terminal. If the proposer wants to resubmit, they create a new task with a new proposal.

8. **CANCELLED -> (any state)**: CANCELLED is terminal. If the work becomes needed again, create a new task.

9. **REJECTED -> ACCEPTED**: A rejected proposal cannot be retroactively accepted. Submit a new proposal.

10. **IN_REVIEW -> IN_PROGRESS**: The implementer cannot pull a task back from review unilaterally. The reviewer must issue a verdict. If the implementer realizes a problem during review, they should communicate via a `STATUS_UPDATE` message and let the reviewer issue CHANGES_REQUESTED.

---

## Loop Limits

### Review Cycle Limit
The cycle IN_PROGRESS -> IN_REVIEW -> CHANGES_REQUESTED may repeat a maximum of **3 times**. This is tracked by the `Review Cycle Count` field in review tasks.

- **Cycle 1**: Initial review. Normal process.
- **Cycle 2**: Re-review after first round of changes. Expected for complex tasks.
- **Cycle 3**: Second re-review. If this cycle still results in CHANGES_REQUESTED, the reviewer must escalate.

**After 3 cycles**: The reviewer sends an `ESCALATION` message to the Lead with reason `CONFLICT`. The Lead must take one of the following actions:
- Reassign the task to a different implementer.
- Redefine the task with clearer requirements.
- Intervene directly (e.g., pair the implementer and reviewer to resolve disagreements).
- Cancel the task if it is no longer viable.

The 3-cycle limit exists to prevent infinite review loops and to surface fundamental misalignments between the implementer and reviewer early.

