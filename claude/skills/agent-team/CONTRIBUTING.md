# Contributing to agent-team

This document explains the structure of the `agent-team` directory and the update rules that apply when adding, modifying, or removing any file. Follow these rules precisely — the system has intentional cross-references that must stay consistent. Missing one breaks the chain.

---

## Directory Structure

```
agent-team/
├── SKILL.md                           # Boot-loader — loaded on skill invocation, Lead's startup script
├── prime-directive.md                 # Governance constitution — loaded by every agent on startup
├── README.md                          # Human-readable directory guide
├── QUICKSTART.md                      # Installation and first-use guide
├── CONTRIBUTING.md                    # This file
├── config/
│   └── team.defaults.json             # Concurrency limits, spawn policy, review policy, severity config
└── agents/
    ├── index.md                       # Single source of truth — registry of all roles, files, change types
    ├── skills-mapping.md              # Maps .claude/skills/ to agent roles with portability classification
    ├── playbooks/                     # Operational procedures for specific scenarios
    ├── roles/                         # One file per agent role
    ├── standards/                     # Engineering quality standards referenced by roles
    └── tasks/
        ├── definitions/               # Task lifecycle, Definition of Done, dependencies
        └── templates/                 # Reusable task templates (task, review, PR, bugfix, spike)
```

---

## The Reference Chain

Before making any change, understand which files form the reference chain. The chain flows top-down:

```
prime-directive.md
  └── agents/index.md          ← master registry
        ├── agents/roles/*.md             ← one per agent
        ├── agents/playbooks/*.md         ← operational procedures
        ├── agents/standards/*.md         ← quality rules
        └── agents/tasks/**               ← lifecycle + templates
```

`index.md` is the hub. Everything else is a spoke. When you add a spoke, you update the hub. When you remove a spoke, you update the hub. The hub's Appendix B is intended to enumerate every file in the system — keep it accurate.

---

## Rules by Change Type

### Adding a New Role

Roles live in `agents/roles/`. The filename is the role identifier (e.g. `docs.writer.md`).

When you add a role file, update **all** of the following:

| File | Section | What to add |
|------|---------|-------------|
| `agents/index.md` | Section 1 — Complete Role List | New numbered table row: `\| N \| \`role.id\` \| mission statement \| spawn priority \|` |
| `agents/index.md` | Section 2 — Role-to-File Mapping | New row: `\| \`role.id\` \| \`agents/roles/role.id.md\` \|` |
| `agents/index.md` | Section 3.2 — Role-Specific Required Files | New row listing which standards and playbook files this role must read on startup |
| `agents/index.md` | Section 9.2 — Roles NOT Authorised to Approve PRs | Add identifier to the list if the role is not a reviewer |
| `agents/index.md` | Section 11 — Concurrency Limits | New row: `\| Category \| \`role.id\` \| max \| rationale \|` |
| `agents/index.md` | Appendix A — Quick Reference Role Categories | Add identifier under the correct category, or create a new category |
| `agents/index.md` | Appendix B — File Inventory (role files list) | Add file path |
| `README.md` | `roles/` section, correct sub-heading | Add bullet: `- \`role.id.md\` — one-line purpose` |
| `agents/roles/lead.md` | Interaction Patterns | Add `### With \`role.id\`` sub-section describing what Lead sends/receives |
| `agents/roles/lead.md` | Onboarding Checklist | Add numbered item: `N. \`agents/roles/role.id.md\` -- why Lead must read it` |

If the new role introduces a new **change type** for review (e.g. the new role produces a new kind of artifact), also follow the "Adding a New Change Type" rules below.

---

### Removing a Role

The inverse of adding. Remove the role file and reverse every update listed in the "Adding a New Role" table above. Additionally:

- Search all other role files for references to the removed role identifier (in `Interaction Patterns`, `Non-Responsibilities`, and `Onboarding Checklist` sections) and remove or update those references.
- Check `team.defaults.json` — if the role appears in `concurrency_limits` or `spawn_policy.minimum_viable_team`, remove or replace it.

---

### Modifying a Role

If you change a role's **identifier** (filename), treat it as a remove + add.

If you change a role's **responsibilities or scope** in a way that affects other roles (e.g. it now produces a new artifact type, or it gains/loses authority over something), check:

- Other role files whose `Interaction Patterns` describe the modified role — update the `Pattern:` description if the dynamic has changed.
- `lead.md` Interaction Patterns sub-section for this role.
- `index.md` Section 1 mission statement if it has changed.
- `code-review-policy.md` Section 3.1 if it is a reviewer role and its lens has changed.

---

### Adding a New Playbook

Playbooks live in `agents/playbooks/`.

| File | Section | What to add |
|------|---------|-------------|
| `agents/index.md` | Section 3.2 — Role-Specific Required Files | Update rows for any roles that must read this playbook |
| `agents/index.md` | Appendix B — File Inventory (playbook files list) | Add file path |
| `README.md` | `playbooks/` section | Add bullet: `- \`playbook-name.md\` — one-line purpose` |
| `agents/playbooks/lead.orchestration.md` | Section 2.2 or relevant procedural section | Reference the playbook if Lead must invoke it in a specific scenario |
| Relevant role files | Onboarding Checklist | Add a checklist item if roles must read this playbook on startup |

---

### Removing a Playbook

Reverse the "Adding a New Playbook" steps. Search all role files for references to the playbook name and remove them. Check `prime-directive.md` Section 20 File Reference Map — if the playbook is listed there, remove it.

---

### Adding a New Standards File

Standards live in `agents/standards/`.

| File | Section | What to add |
|------|---------|-------------|
| `agents/index.md` | Section 3.2 — Role-Specific Required Files | Update rows for any roles that must comply with this standard |
| `agents/index.md` | Appendix B — File Inventory (standards files list) | Add file path |
| `README.md` | `standards/` section | Add bullet: `- \`standard-name.md\` — one-line purpose` |
| `agents/playbooks/code-review-policy.md` | Section 3.1 Standards Lens | If `reviewer.standards` must enforce this standard, add a reference in the lens definition |
| `prime-directive.md` | Section 7 Definition of Done or Section 14/15 | If the standard introduces a new DoD requirement (e.g. observability, performance), add a reference |
| `prime-directive.md` | Section 20 File Reference Map | Add a row if this is a canonically important file |
| Relevant role files | Onboarding Checklist | Add a checklist item for any role that must read this standard |

---

### Adding a New Change Type

Change types appear in three files simultaneously and must be kept in sync. Updating one without the others creates an inconsistency.

**All three must be updated together:**

| File | Section | What to add |
|------|---------|-------------|
| `agents/index.md` | Section 6 — Required Review Lenses Per Change Type | New table row: `\| Change Type \| required reviewers \| notes \|` |
| `prime-directive.md` | Section 6 — Review Gate Policy table | New table row matching `index.md` Section 6 |
| `agents/playbooks/code-review-policy.md` | Section 1.1 — Change Type Identification | New bullet in the classification list |


---

### Adding a New Task Template

Task templates live in `agents/tasks/templates/`.

| File | Section | What to add |
|------|---------|-------------|
| `agents/index.md` | Appendix B — File Inventory (task template files list) | Add file path |
| `agents/playbooks/lead.orchestration.md` | Section 2.2 — Creating Tasks | Add bullet referencing when this template is used |

---


---

### Modifying `team.defaults.json`

The config file at `config/team.defaults.json` governs concurrency limits, spawn policy, review policy, messaging constraints, and severity response rules. Its structure is referenced in:

- `prime-directive.md` Section 11 (spawn policy, `team.defaults.json` path)
- `agents/index.md` Section 11 (concurrency limits — must match `concurrency_limits` block)
- Role files' Onboarding Checklists (instruct agents to read this file)

If you add or change a key in `team.defaults.json`, check whether any of the above files reference that key by name and update their descriptions accordingly.

---

### Modifying `prime-directive.md`

`prime-directive.md` is the prime directive. Treat changes to it with the same weight as changes to a constitution. It is referenced by:

- Every role file's Onboarding Checklist (step 1 is always "read prime-directive.md")
- `QUICKSTART.md`
- `README.md`

The Section 20 File Reference Map inside `prime-directive.md` itself must be updated whenever a canonical file is added or renamed anywhere in the system.

---

---

## Consistency Checks

After making any change, run this mental checklist:

- [ ] Does `index.md` Appendix B list every file that now exists?
- [ ] Does `index.md` Section 1 have a row for every role in `roles/`?
- [ ] Does `README.md` have a bullet for every file in `roles/`, `playbooks/`, and `standards/`?
- [ ] Does `lead.md` Onboarding Checklist have an item for every role file?
- [ ] Does `lead.md` Interaction Patterns have a sub-section for every role?
- [ ] Are the change type lists in `index.md` Section 6, `prime-directive.md` Section 6, and `code-review-policy.md` Section 1.1 identical?
- [ ] Does `team.defaults.json` `concurrency_limits` match `index.md` Section 11?
- [ ] Are there any broken markdown links (links to files that no longer exist)?
- [ ] Are there any orphaned files (files not linked from any index or README)?

The fastest way to check for orphans and broken links is to run the Python reference-map script documented in the session that produced this file, or repeat the analysis manually using grep across the directory.

---

## The Worked Example: Adding `docs.writer`

The `docs.writer` role was added to illustrate exactly what "adding a new role" involves. The changes required were:

**New file created:**
- `agents/roles/docs.writer.md`

**Files updated:**
- `agents/index.md` — 7 separate locations (Section 1 table, Section 2 table, Section 3.2 table, Section 6 change type table, Section 9.2 non-approvers list, Section 11 concurrency table, Appendix A categories, Appendix B file list)
- `README.md` — Specialist bullet added under `roles/` section
- `agents/roles/lead.md` — New `### With \`docs.writer\`` sub-section in Interaction Patterns; new item 24 in Onboarding Checklist
- `agents/playbooks/lead.orchestration.md` — New decision tree branch in Section 1.1
- `agents/playbooks/code-review-policy.md` — New `Documentation` change type bullet in Section 1.1

That is **13 distinct edits across 5 files** for a single new role. This is not exceptional — it is the expected cost of maintaining a consistent, self-referential system. The update rules above exist precisely to ensure nothing is missed.
