# Pull Request Task Template

This template is used for tasks that track a pull request through creation, review, and merge. It inherits every field from the general-purpose task template (`task.template.md`) and adds PR-specific fields and sections.

A PR task is created when an implementer has completed work on a branch and is ready to merge into a target branch. The PR task tracks reviewer assignments, review statuses, merge readiness, and post-merge actions.

---

## Inherited Fields

All fields from `task.template.md` are required. The following values are pre-set for PR tasks:

- **Type**: Matches the type of the parent implementation task (`feature`, `enhancement`, `refactor`, or `chore`).
- **Title**: Format: "PR: [brief description of changes]"
- **Labels**: Must include the same labels as the parent implementation task, plus `needs-review` until all reviews are complete.

---

## Additional Required Fields

### PR Number
- The pull request number as assigned by the repository hosting platform (e.g., `#3608`).
- Set when the PR is created. Immutable after creation.

### Branch Name
- The source branch containing the changes (e.g., `feature/TASK-0042-rate-limiting`).
- Branch naming convention: `[type]/[TASK-ID]-[kebab-case-description]`
  - `feature/TASK-0042-add-rate-limiting`
  - `bugfix/TASK-0055-fix-null-serialization`
  - `refactor/TASK-0061-extract-card-service`
  - `chore/TASK-0070-update-dependencies`

### Base Branch
- The target branch the PR will be merged into (e.g., `develop`, `main`).
- Typically `develop` for this project.
- Must not be changed after review has begun without Lead approval and re-review of all reviewers.

### Changed Files
List of all files included in the PR, each annotated with its change type. This list is used to determine required reviewers.

Format:
```
- [added | modified | deleted] path/to/file
```

Example:
```
- added    app/services/RateLimiter.scala
- modified app/controllers/CardController.scala
- modified app/routes/Routes.scala
- added    test/services/RateLimiterSpec.scala
- deleted  app/services/OldThrottler.scala
```

### Required Reviewers
List of reviewer roles required for this PR, determined by the change type matrix:

| Change Area | Required Reviewers |
|---|---|
| Any code change | `reviewer.code` |
| Security-sensitive files (auth, crypto, secrets) | `reviewer.code` + `reviewer.security` |
| Performance-sensitive files (queries, caching, hot paths) | `reviewer.code` + `reviewer.performance` |
| Architecture changes (new modules, API contracts, dependency direction) | `reviewer.code` + `reviewer.architecture` |
| Test-only changes | `reviewer.test` |
| Configuration-only changes (CI, build, deploy) | `reviewer.code` |

The Lead determines the required reviewers based on the changed files and assigns them. Each required reviewer receives a `REVIEW_REQUEST` message.

### Review Status per Reviewer
Tracks the current review status for each assigned reviewer:

Format:
```
- [reviewer role]: [pending | approved | changes_requested | blocked]
```

Example:
```
- reviewer.code: approved
- reviewer.security: changes_requested
```

Updated as `REVIEW_RESULT` messages are received.

### Merge Readiness Checklist
All items must be checked before the PR can be merged. The Lead is responsible for verifying this checklist.

- [ ] All required reviewers have issued a verdict of `APPROVED`
- [ ] No reviewer has issued a verdict of `BLOCKED`
- [ ] All MUST_FIX findings have been resolved and verified in re-review
- [ ] All tests pass (CI pipeline green)
- [ ] No Sev0 or Sev1 issues remain open against the changed code
- [ ] Definition of Done is met for the parent implementation task
- [ ] Branch is up-to-date with the base branch (no merge conflicts)
- [ ] Commit history is clean (meaningful commit messages, no "fix typo" chains)

### Merge Blockers
List of unresolved items preventing merge. Each blocker must reference a specific issue:

Format:
```
- [BLOCKER-TYPE]: [description] (ref: [TASK-NNNN or finding reference])
```

Blocker types:
- `REVIEW`: A reviewer has not yet approved or has requested changes.
- `TEST`: Tests are failing.
- `CONFLICT`: Merge conflicts with the base branch.
- `FINDING`: An unresolved MUST_FIX finding.
- `DEPENDENCY`: A blocking dependency has not been merged yet.

Example:
```
- REVIEW: reviewer.security has requested changes (ref: TASK-0043)
- FINDING: Unresolved MUST_FIX in CardController.scala line 87 (ref: TASK-0043, finding #2)
```

Empty list when the PR is ready to merge.

### Post-Merge Actions
Required follow-up actions after the PR is merged. These are communicated to the Lead and tracked:

- Documentation updates that must be published
- Monitoring or alerting changes to apply
- Feature flags to enable
- Downstream services to notify
- Database migrations to run
- Cache invalidation steps

Each action should specify who is responsible and any ordering constraints.

Example:
```
1. [lead] Verify deployment pipeline triggers successfully
2. [implementer.backend] Monitor error rates for /api/v1/cards for 30 minutes post-deploy
3. [lead] Update API documentation in Confluence
```

Empty list if no post-merge actions are required.

---

## Blank Template

```
[All fields from task.template.md, plus:]

PR Number: [#NNNN]
Branch Name: [type/TASK-NNNN-description]
Base Branch: [develop | main]
Changed Files:
  - [added | modified | deleted] [file path]
Required Reviewers:
  - [reviewer role]
Review Status per Reviewer:
  - [reviewer role]: pending
Merge Readiness Checklist:
  - [ ] All required reviewers have approved
  - [ ] No reviewer has issued BLOCKED
  - [ ] All MUST_FIX findings resolved
  - [ ] All tests pass
  - [ ] No Sev0/Sev1 open issues
  - [ ] Definition of Done met
  - [ ] Branch is up-to-date with base branch
  - [ ] Commit history is clean
Merge Blockers:
  [list of blockers or empty]
Post-Merge Actions:
  [list of actions or empty]
```
