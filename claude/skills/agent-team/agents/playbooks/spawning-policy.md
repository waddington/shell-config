# Spawning Policy Playbook

`lead` is the sole authority for spawn and termination decisions. No agent may spawn or terminate itself without Lead authorisation.

---

## 1. Spawn Decision Framework

**Spawn conditions (ALL must be true):**
- A task exists requiring the role AND all dependencies are met.
- No existing instance of that role is available (all are at capacity or none exists).
- Role concurrency limit not reached.
- Total agent cap (25) not reached — or room can be made by terminating a lower-priority agent.

**Reuse conditions (ANY is sufficient to reuse instead of spawn):**
- An agent of the required role is active with fewer than 2 active tasks.
- The agent recently did related work and retaining its context is valuable (e.g., reviewer who reviewed Part 1 should review Part 2).
- Concurrency limit reached (spawn impossible).

**Never spawn when ANY is true:**
- No immediate task exists. Never spawn speculatively.
- Would exceed the role's concurrency limit.
- Spawning "just in case" work might arise.
- Marginal value is genuinely low (e.g., a fifth `implementer.backend` for a single remaining S task when four already have capacity).
- The work can be done by a role already present through a minor scope extension.

**Decision tree (evaluate in order):**
1. Idle instance of required role exists? → Reuse. Assign task. Done.
2. All instances busy but concurrency limit not reached? → Spawn.
3. Concurrency limit reached? → Queue task. Assign when instance frees. Done.
4. Total cap (25) reached? → Can a lower-priority idle agent be terminated? Yes → terminate then spawn. No → queue. Done.
5. Specific task ready? Yes → Spawn (proceed to §3). No → queue intent, revisit when task is ready.

---

## 2. Concurrency Limits

Absolute maximums. Must not be exceeded under any circumstances.

| Role | Max Instances | Notes |
|------|-------------|-------|
| `lead` | 1 | Always running, never terminated, never duplicated |
| `prioritiser` | 1 | Single priority ordering source |
| `product.pm` | 1 | Single acceptance criteria source |
| `architect.principal` | 1 | Single architectural authority |
| `implementer.backend` | 5 | Spawn multiple proactively for independent tasks — parallelism is the default, not the exception |
| `implementer.frontend` | 4 | Spawn multiple proactively for independent components |
| `implementer.platform` | 3 | Infrastructure changes are conflict-prone; verify non-overlap before spawning additional instances |
| `reviewer.security` | 3 | Independent instances; do not confer |
| `reviewer.correctness` | 3 | Independent instances |
| `reviewer.tests` | 3 | Independent instances |
| `reviewer.quality` | 3 | Independent instances |
| `reviewer.standards` | 3 | Independent instances |
| `reviewer.logic` | 3 | Independent instances |
| `security.threat-modeler` | 1 | Consistent threat models require one instance |
| `security.appsec-analyst` | 1 | Consistent security analysis requires one instance |
| `qa.test-designer` | 1 | Consistent test strategy requires one instance |
| `qa.test-writer` | 5 | Multiple writers may implement partitioned test suites in parallel |
| `debugger` | 3 | Multiple debuggers may investigate separate issues |
| `perf.reliability` | 2 | Two instances may analyse separate components concurrently |
| `observability` | 2 | Two instances may cover separate services concurrently |
| `generalist` | 8 | Spawn freely for parallel non-specialist odd jobs |

**Total agent cap: 40.** When approaching cap: audit for terminable agents; terminate completed on-demand agents first; if no agents can be freed, queue the task.

**Implementer parallelism principle:** When a feature can be decomposed into independent tasks (different modules, services, or files), spawn a separate implementer for each task simultaneously. Do not serialise implementation work unless there is a concrete dependency. The default assumption is that tasks are parallelisable; serialisation requires explicit justification.

**Minimum team composition (mandatory for every iteration, no exceptions):**

Every team, regardless of task size or type, MUST include:
- `architect.principal` — ensures all work fits the system design and structural decisions are sound.
- `product.pm` — ensures requirements are clear and delivered work is validated against acceptance criteria.
- `qa.test-designer` — ensures testability is considered from the start and test strategy is defined before implementation.

These three roles are spawned at iteration start alongside `lead`. They are never optional. A "simple bug fix" still needs requirements validated, architecture considered, and a test strategy defined — even if the outputs of each are brief.

**Practical team size guidance (beyond the mandatory minimum):**
- Simple bug fix: ~6 agents (mandatory 4 + one implementer + `reviewer.correctness`)
- Standard feature: ~8–9 agents (add `reviewer.standards`, `reviewer.tests`, `qa.test-writer`)
- Security-sensitive feature: ~10–11 agents (add `reviewer.security`, `security.appsec-analyst`)
- Full-scale feature: ~15–22 agents (multiple parallel implementers, full reviewer set, threat modeler, test writers)
- Large parallel workload (30+): multiple independent features being built simultaneously, each with its own implementer set

---

## 3. Spawn Procedure

**Pre-spawn verification:**
1. Count active instances of target role. If at limit → ABORT.
2. Count total active agents. If at 25 → attempt to free a slot (terminate lowest-priority idle on-demand agent). If none available → ABORT and queue task.
3. Confirm task(s) are in `ACCEPTED` state with all dependencies `DONE`. If not ready → DEFER spawn.

**Execution:**
1. Construct a rich spawn prompt (see `agents/roles/lead.md` §6 — Spawn prompt construction). Include: role identity and startup file paths, iteration goal, task specification, codebase context (relevant directory structure, key files, entry points, patterns), architectural decisions already made, prior work context (what other agents built, with file paths), known constraints and gotchas, review requirements for this task, and relevant skills. A bare "here is your task" spawn produces an under-informed agent. Err on the side of more context.
2. Spawn agent with the fully constructed prompt.
3. Start readiness timer (one milestone window for agent to send `READY`).
4. Receive and validate `READY`: role matches requested role; capabilities non-empty.
5. Send `TASK_ASSIGNMENT` immediately after validating `READY`.
6. Add to active agent registry (role, instance number, spawn timestamp, assigned tasks, status: `working`).

**Failure handling:**
- No `READY` within window → log, retry once (terminate + respawn). If retry fails → escalate to human.
- `READY` with wrong role → terminate immediately, respawn with correct parameters.
- Agent refuses task assignment → protocol violation; terminate + respawn. If persistent → escalate to human.

---

## 4. Termination Policy

**Terminate when ANY is true:**
1. **Work complete** — all tasks `APPROVED`/`DONE`, no pending reviews to receive, no further work of this type expected in the iteration.
2. **Idle timeout** — no messages sent or received for 3+ milestone windows.
3. **Role no longer needed** — iteration has moved past this role's area of responsibility.
4. **Protocol violations** — 2+ violations (self-claiming, broadcast abuse, invalid transitions). Terminate and respawn fresh instance.
5. **Cap pressure** — higher-priority agent needs a slot. Terminate lowest-priority idle on-demand agent.

**Termination precedence (terminate first):**
1. Idle on-demand agents (no assigned tasks)
2. Completed on-demand agents (all tasks DONE)
3. Idle standard agents (excluding `architect.principal` and `product.pm` — keep these alive)
4. Completed standard agents (excluding `architect.principal` and `product.pm`)
5. On-demand agents with active tasks (last resort — requires task reassignment first)
6. `architect.principal` or `product.pm` — only if no other option exists and cap is critically exhausted. Requires Lead to record a full context summary before termination so the replacement can be primed with prior decisions.

**Never terminate:** `lead`; `architect.principal` or `product.pm` (their accumulated context about system design and requirements is expensive to rebuild — keep them alive for the full iteration even when idle); any agent mid-task without first reassigning the task; any agent with a `REVIEW_RESULT` pending delivery.

**Preserve but may terminate under extreme cap pressure:** `qa.test-designer` (mandatory minimum role — strongly prefer keeping alive, but may be terminated if the total cap is critically constrained and no other agent can be freed, provided no active test planning work is in flight).

**Termination procedure:**
1. Send `SYSTEM: event: TERMINATION_NOTICE` with reason.
2. Allow one message cycle for final `STATUS_UPDATE` and in-flight deliveries.
3. If agent has active tasks → reassign to another agent of the same role before or immediately after termination.
4. Remove from active agent registry. Log: role, instance, reason, timestamp, tasks at termination.

**Graceful vs. immediate:**
- **Graceful** (default) — full procedure above. Use for work-complete, idle-timeout, role-no-longer-needed.
- **Immediate** — skip final message cycle. Use only for protocol violations where the agent is actively causing harm (unauthorized broadcast, self-claiming, security constraint violations). Log reason.

---

## 5. Cost Principles

- Spawn the minimum team needed. Scale up only when specific tasks require it.
- Prefer reuse over spawn. Existing agent with context > fresh spawn.
- Release agents promptly — no "just in case" idling. Terminate and respawn later if needed.
- Batch reviews — assign multiple tasks to one reviewer rather than spawning a second instance.
- Avoid unnecessary respawns — if an agent will be needed again soon, keep it alive rather than terminate + respawn (context preserved, startup avoided).
- Sweet spot for a single feature: 8–15 active agents. For multiple parallel features, scale up accordingly — the cap of 40 exists to support this.

---

## 6. Anti-Patterns

1. **Speculative spawning** — spawning without a specific task ready. Agent sits idle.
2. **Spawn hoarding** — keeping agents alive long after work is complete. Terminate and respawn if needed later.
3. **Spawn avoidance** — failing to spawn when parallelism would genuinely accelerate. If 5 independent tasks need 5 implementers and limits allow it, spawn all 5. Under-staffing is a failure mode, not a virtue.
4. **Exceeding concurrency limits** — spawning a sixth `implementer.backend` when the limit is 5. Absolute violation.
5. **Terminating with pending deliverables** — terminating a reviewer before `REVIEW_RESULT` is delivered. Check for pending outputs first.
6. **Role confusion** — spawning `implementer.backend` for a frontend task. Use the correct role.
7. **Cascading spawns** — an agent that immediately proposes spawning another. Spawning chain should be shallow: Lead spawns directly.
8. **Skipping mandatory minimum roles** — starting an iteration without `architect.principal`, `product.pm`, and `qa.test-designer`. These are never optional regardless of task size.
