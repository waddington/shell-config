
# User-level instructions

## Default to the `agent-team` skill

I have a user-level skill installed at `~/.claude/skills/agent-team/` that defines a 20-role multi-agent engineering team (implementers, reviewers, QA, security, architecture, docs, orchestration playbooks, task templates, standards).

**Lean on this skill heavily.** For most non-trivial software tasks — implementation, review, debugging, planning, refactoring, QA, security analysis — invoke the `agent-team` skill and use its roles, playbooks, and task templates rather than answering ad-hoc. Read `~/.claude/skills/agent-team/SKILL.md` for how to route work into the right role(s).

Specifically:

- **Implementation work** → use the relevant implementer role (backend / frontend / platform) and follow `agents/standards/` + `agents/tasks/templates/`.

- **Code review** → use the reviewer roles (correctness, logic, security, tests, standards, quality, risk, observability, PR-description) per `agents/playbooks/code-review-policy.md`.

- **Planning / architecture** → use `architect.principal` or `lead` per `agents/playbooks/lead.orchestration.md`.

- **Debugging** → `agents/playbooks/debugging-playbook.md`.

- **QA / tests** → `qa.test-designer` and `qa.test-writer` per `agents/playbooks/qa-strategy.md`.

- **Security** → `security.threat-modeler` / `security.appsec-analyst` per `agents/playbooks/security-policy.md`.

- **Spawning / parallel work** → `agents/playbooks/spawning-policy.md` and `parallelism-guide.md`.

**When to skip it:** trivial one-liners, pure Q&A, file lookups, or tasks the user explicitly scopes outside the team frame. If in doubt, default to using it.

When a task spans multiple roles, follow `agents/playbooks/lead.orchestration.md` to coordinate them rather than picking one role arbitrarily.

## Git: commit frequently, small logical units

When working in a git repo, commit early and often. Each commit should be one logical change — small enough to describe in a single sentence without "and".

**Commit when:**
- A discrete piece of work is complete and the tree is in a coherent state (tests pass, file compiles, doc section is finished) — don't wait for the whole task.
- You're about to switch contexts (different file area, different concern, refactor → feature, code → docs).
- Before starting a risky or speculative change, so there's a clean point to return to.
- After deleting or moving files, as its own commit — keep renames/deletions separate from edits so diffs stay readable.

**Don't:**
- Batch unrelated changes into one commit ("fix X and also Y and update Z").
- Hold work uncommitted across multiple turns waiting for "the right moment" — the right moment is now.
- Amend or force-push to share history without explicit ask.

Default to asking only if a commit would mix concerns or the boundary is unclear; otherwise just commit.
