
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

## Git workflow

When working in a git repository, read `~/.claude/git-workflow.md` and follow it. It covers worktrees, PRs (default for repos with a GitHub remote; solo repos opt out in their project `CLAUDE.md`), merge style, push cadence, Conventional Commits, cleanup, and commit discipline.

Project-level `CLAUDE.md` files may override specific rules from that doc; where they do, the project rule wins.
