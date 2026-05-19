# Git workflow

Rules for working in any git repository. Loaded from `~/.claude/git-workflow.md` and referenced from `~/.claude/CLAUDE.md`. Project-level `CLAUDE.md` files may override specific rules; where they do, the project rule wins.

---

## 1. All work happens in a git worktree, branched from latest `main`

Use `EnterWorktree` (the Claude Code tool) or `git worktree add` for every change set, no matter how small. The main working copy stays clean — no edits to tracked files there.

**Worktrees live at `<repo>/.claude/worktrees/<name>`.** That's where `EnterWorktree` puts them by default — if you're using `git worktree add` manually, pass the same path (e.g. `git worktree add .claude/worktrees/my-change -b worktree-my-change origin/main`). Don't create sibling-directory worktrees (`../foo`) — they clutter the parent directory and break the convention other tooling relies on. Make sure `.claude/worktrees/` is in `.gitignore` (or covered by `.claude/`).

**Branch the worktree from latest `main`, not stale local `main`.** Either use the harness's `fresh` base ref (Claude Code's `worktree.baseRef: fresh` default branches from `origin/<default-branch>` directly) OR run `git fetch origin && git checkout main && git pull --ff-only` before creating the worktree manually. A worktree branched from out-of-date `main` will need rebasing or merging before it can fast-forward, which is avoidable work.

*Why:* worktrees isolate parallel work (multiple agents, multiple feature threads), keep `main` always-clean, and the cost of creating one is near zero. Branching from a stale `main` produces conflicts against work that landed in the meantime.

*How to apply:* if you're about to edit a tracked file in the main working copy, stop and enter a worktree first. The only exception is read-only investigation (grep, read, `git log`) — that's fine in main.

## 2. Always use a worktree, even for trivial changes

No exception for "single-line fix" or "typo." Worktrees are cheap enough that the rule stays uniform — and a "trivial" change frequently turns out to want a follow-up edit, at which point being already in a worktree is the right state.

*Why:* a uniform rule has no judgement edge to litigate. The cost of always-worktree is ~5 seconds per change; the cost of "is this trivial enough to skip the worktree?" is the cognitive load of asking the question every time.

## 3. PRs by default for repos with a GitHub remote; solo opt-out

If the repo has a GitHub remote (i.e. `git remote get-url origin` returns a `github.com` URL), every change to `main` lands via a pull request. No `git commit` directly on `main`; no `git push origin main` from a local checkout.

**Solo opt-out:** a personal repo with no review process (configs, dotfiles, scratch experiments) can opt out by declaring so in its project `CLAUDE.md` — e.g. *"solo repo: commits land directly on `main`, no PR workflow."* In the absence of such an override, assume PRs apply.

*Why:* PR review is the audit trail for what changed, when, and why. Direct pushes bypass the review history surface and lose the PR description (which is often more useful than the commit messages for understanding intent). The opt-out exists because forcing PR ceremony on a one-person config repo is friction without payoff.

*How to apply:* if you find yourself on `main` with uncommitted changes in a PR-workflow repo, stash them, enter a worktree, restore the stash there. Never commit on `main` in those repos.

## 4. Use the worktree's auto-created branch as the PR branch

`EnterWorktree` creates a branch named `worktree-<name>`. Push that branch to origin and open the PR from it. Do NOT create a second branch (`feat/...`, `fix/...`, etc.) just for the PR — that's redundant.

*Why:* one branch per work-unit is enough. Branch names are less load-bearing than commit messages and merge-commit messages — those are where the work's intent gets recorded.

*How to apply:* `git push -u origin worktree-<name>` from inside the worktree, then `gh pr create --head worktree-<name>`.

## 5. PR merge style: merge commit (not squash, not rebase)

Always merge PRs with `--merge` (creates a merge commit). Never `--squash` or `--rebase` unless the user explicitly asks otherwise for a specific PR.

*Why:* merge commits preserve the per-commit narrative inside a branch (each per-decision commit retains its own commit message, which is often where reasoning lives). Squash collapses that history; rebase loses the "these N commits were one logical change" framing. Merge commits also keep the parallel-branches shape visible in `git log --graph` which matches how worktree-based work actually happens.

*How to apply:* `gh pr merge <N> --merge --delete-branch`.

## 6. Push when on a branch

Once you're on a non-`main` branch and have committed work, push regularly — at minimum before opening the PR, ideally after each per-decision commit. Don't accumulate unpushed commits.

*Why:* unpushed work is invisible to PR review, to collaborators, and to recovery if the local checkout goes wrong. Push is cheap.

*How to apply:* `git push -u origin <branch>` first time; plain `git push` subsequently.

## 7. PR description shape: Summary + Test plan

Every PR carries two sections at minimum:
- **Summary** — 1-3 bullets describing what changed and why. The reviewer should be able to understand the intent without reading the diff.
- **Test plan** — a markdown checkbox list of what to check before merge (build runs, doc links resolve, no regressions in X, etc.). Even for docs-only PRs.

Use a HEREDOC with `gh pr create --body` to preserve formatting.

*Why:* Summary is the elevator pitch; Test plan is the verification surface. Together they make the PR auditable months later when nobody remembers what `PR #47` was about.

## 8. Worktree + branch cleanup after merge

After a PR merges:
1. `git checkout main && git pull --ff-only` — sync local main with the merge.
2. `git worktree remove <path>` — remove the worktree directory (the local branch is gone with the worktree).
3. `git fetch --prune` — clean up the local cache of the now-deleted remote ref.

GitHub deletes the remote branch automatically when the PR is merged with `--delete-branch` (Rule 5) — we don't need to. The local cleanup is what matters.

*Why:* leaving merged worktrees around accumulates clutter and makes `git worktree list` noisy.

*How to apply:* the `ExitWorktree` tool handles the worktree-directory side; finish with `git fetch --prune` for the remote-ref cleanup.

## 9. Conventional Commits

Every commit message follows [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <subject>` + optional body + optional footer.

Types in use: `feat` / `fix` / `docs` / `chore` / `refactor` / `test` / `style` / `perf` / `build` / `ci` / `revert`.

Scopes are project-area names — match what's already in the repo's git log. If the repo has no established scope vocabulary, omit the scope (`feat: …`) rather than inventing one.

*Why:* uniform commit-message structure makes `git log` greppable, makes change classification trivial, and is the conventional substrate for changelog generation later.

*How to apply:* `git log --oneline -20` shows the established style; mirror it. If the change spans multiple types, pick the dominant one and call out the others in the body.

## 10. Commit frequently, small logical units

Commit early and often. Each commit should be one logical change — small enough to describe in a single sentence without "and".

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

## 11. Destructive operations require explicit ask

Force-push, `git reset --hard`, branch deletion of un-merged work, `git checkout .` discarding local changes — these need explicit user instruction. Never reach for them as a shortcut to clear an obstacle; investigate the obstacle first.

*Why:* destructive operations are how work gets lost. The cost of asking is low; the cost of an unwanted `--force` is the user's afternoon.
