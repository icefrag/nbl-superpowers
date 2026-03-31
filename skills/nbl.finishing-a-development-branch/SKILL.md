---
name: nbl.finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Merge worktree to dev branch (if parallel mode) → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

**NON-NEGOTIABLE:** All worktree operations MUST use scripts from `nbl.using-git-worktrees` skill. Never use raw `git worktree` commands directly.

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Execution Mode

Check which mode produced this branch:

```bash
# Check if a merge worktree exists (parallel mode indicator)
ls .worktrees/*-merge 2>/dev/null
```

| Mode | Detection | Worktree Layout |
|------|-----------|-----------------|
| **Inline** | No worktree, on dev branch directly | Working on dev branch itself |
| **Serial** | Single worktree from dev branch | `.worktrees/{name}/` |
| **Parallel** | Merge worktree exists | `.worktrees/{name}-merge/` + (task worktrees already cleaned) |

**If parallel mode detected:** Execute Step 2A first.

### Step 2A: Merge Worktree → Dev Branch (Parallel Mode Only)

**This step MUST execute before presenting options when parallel mode is detected.**

The merge worktree contains all accumulated changes from all parallel tasks. Merge it back to the development branch:

```bash
# Determine names from merge worktree
# merge worktree branch pattern: feature/{name}-merge
MERGE_BRANCH=$(git branch --show-current)  # or infer from worktree list

# Switch to development branch (in main workspace, not in worktree)
git checkout <development-branch>

# Merge the merge branch
git merge --ff-only feature/<name>-merge

# Verify tests on merged result
<test command>
```

**If tests fail:** Stop and fix before proceeding.

**If tests pass:** Development branch now contains all changes. Continue to Step 3.

### Step 3: Determine Base Branch

```bash
# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# If current branch is already a feature/dev branch (not main/master), check what it split from
# Common case: development from feature-xxx to feature-xxx-taskxxx
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
  # Try to find the nearest ancestor branch that exists locally
  for target_branch in $(git branch --format="%(refname:short)"); do
    if [[ "$target_branch" != "$CURRENT_BRANCH" && "$target_branch" != "main" && "$target_branch" != "master" ]]; then
      if git merge-base --is-ancestor $(git merge-base HEAD "$target_branch") HEAD; then
        FOUND_BASE=$target_branch
        break
      fi
    fi
  done
  if [[ -n "$FOUND_BASE" ]]; then
    BASE_BRANCH=$FOUND_BASE
  else
    BASE_BRANCH=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
    if [[ -n "$BASE_BRANCH" ]]; then
      BASE_BRANCH="main"
    else
      BASE_BRANCH="master"
    fi
  fi
else
  BASE_BRANCH=$CURRENT_BRANCH
fi
```

**Logic:**
1. If current branch is already a feature branch (not main/master) → try to find the nearest ancestor feature branch as base
2. Falls back to main/master if no ancestor found
3. Ask user to confirm: "This branch split from `<base-branch>` - is that correct?"

### Step 4: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then: Cleanup worktree (Step 6)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 6)

### Step 6: Cleanup Worktree

**NON-NEGOTIABLE: All cleanup MUST be performed via `nbl.using-git-worktrees` skill.** The skill provides proper safety checks and handles platform detection.

**For Options 1, 2, 4:**

Invoke `nbl.using-git-worktrees` cleanup:

```
Invoke the skill with: /nbl.superpowers:nbl.using-git-worktrees cleanup <base_name> [--force]
```

**Parallel mode additional cleanup:**

After cleaning up the main worktree, also clean up the merge worktree:

```
Invoke the skill with: /nbl.superpowers:nbl.using-git-worktrees cleanup <name>-merge --force
```

**For Option 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch | Cleanup Merge WT |
|--------|-------|------|---------------|----------------|------------------|
| 1. Merge locally | ✓ | - | - | ✓ | ✓ (parallel only) |
| 2. Create PR | - | ✓ | - | - | ✓ (parallel only) |
| 3. Keep as-is | - | - | ✓ | - | - |
| 4. Discard | - | - | - | ✓ (force) | ✓ (parallel only) |

## Mode-Specific Behavior

### Inline Mode (executing-plans)

- No worktree cleanup needed (working directly on dev branch)
- Just present options for the dev branch

### Serial Mode (subagent-driven-development)

- One worktree to clean up: `.worktrees/{name}/`
- Use `cleanup-worktree` script with base_name

### Parallel Mode (parallel-subagent-driven-development)

- Merge worktree: `.worktrees/{name}-merge/` — merged to dev branch in Step 2A
- Task worktrees already cleaned up during execution (by `sub-to-sub-merge` script)
- After Step 2A: clean up merge worktree using `cleanup-worktree` script

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Using raw git commands for worktree cleanup**
- **Problem:** Bypasses safety checks (unmerged commit detection, branch validation)
- **Fix:** Always invoke `nbl.using-git-worktrees` skill for cleanup

**Forgetting merge worktree in parallel mode**
- **Problem:** Merge worktree left dangling after parallel tasks
- **Fix:** Step 2A merges to dev branch, Step 6 cleans up merge worktree

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Use raw `git worktree` commands — always invoke `nbl.using-git-worktrees` skill

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Invoke `nbl.using-git-worktrees` skill for all worktree cleanup operations
- Clean up merge worktree in parallel mode

## Integration

**Called by:**
- **nbl.subagent-driven-development** - After all tasks complete
- **nbl.executing-plans** - After all batches complete
- **nbl.parallel-subagent-driven-development** - After all tasks complete

**Pairs with:**
- **nbl.using-git-worktrees** - REQUIRED for all worktree cleanup operations. Use its scripts exclusively.
