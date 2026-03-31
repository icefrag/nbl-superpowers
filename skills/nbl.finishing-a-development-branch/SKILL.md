---
name: nbl.finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to cleanup worktrees - completes development work with unified automatic flow
---

# Finishing a Development Branch

## Overview

Guide completion of development work by following the unified automatic flow:
**Core principle:** Verify tests → Cleanup. All done automatically.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before cleanup, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with cleanup until tests pass.
```

Stop. Don't proceed to cleanup.

**If tests pass:** Continue to Step 2.

### Step 2: Get Base Branch

```bash
# Base branch is current branch (we are already here)
base_branch=$(git branch --show-current)
```

### Step 3: Cleanup Worktrees

#### Single worktree cleanup (for serial mode)

If there is a top-level worktree in `.worktrees/`:
```bash
# Get the worktree path and branch name
worktree_path=$(find .worktrees -type d | head -1)
feature_branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -n "$feature_branch" ]; then
  # Strip feature/ prefix to get base_name (cleanup-script adds prefix again)
  base_name=$(echo "$feature_branch" | sed 's/^feature\///')
  # Cleanup using existing script
  if [[ "$OSTYPE" == "win32" ]] || [[ -n "${PSModulePath:-}" ]]; then
    ./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.ps1 "$base_name" --force
  else
    ./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.sh "$base_name" --force
  fi

  # Delete feature branch if it was created from main/master and already merged
  if [[ "$base_branch" == "main" || "$base_branch" == "master" ]]; then
    git branch -d "$feature_branch" 2>/dev/null || git branch -D "$feature_branch" 2>/dev/null || true
  fi
fi
```

#### Batch cleanup for parallel tasks

Cleanup any residual parallel task worktrees in `.worktrees/`:

```bash
if [ -d ".worktrees" ] && [ "$(ls -A .worktrees)" ]; then
  echo "Cleaning up parallel task worktrees..."
  for wt_path in .worktrees/*/; do
    [ -d "$wt_path" ] || continue
    # Get base_name from directory name
    base_name=$(basename "$wt_path")
    # Check if it's a parallel task (has -taskN suffix)
    if [[ "$base_name" =~ -task[0-9]+$ ]]; then
      # Extract task_id from name (everything after last -task)
      task_id=$(echo "$base_name" | sed -E 's/.*-task//')
      # Use cleanup script for consistent behavior
      if [[ "$OSTYPE" == "win32" ]] || [[ -n "${PSModulePath:-}" ]]; then
        ./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.ps1 "$base_name" "$task_id" --force
      else
        ./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.sh "$base_name" "$task_id" --force
      fi
    fi
  done
fi
```

### Step 4: Report Completion

```
✓ Development complete! All changes are on '$base_branch'.
Worktrees cleaned up.
```

## Common Mistakes

**Skipping test verification**
- **Problem:** Cleanup with failing tests leaves broken code merged
- **Fix:** Always verify tests before cleanup

**Redundant worktree cleanup**
- **Problem:** Trying to clean up worktree that was already removed
- **Fix:** Always check existence before cleanup, ignore cleanup failures

## Red Flags

**Never:**
- Proceed with failing tests
- Cleanup before merge is complete

**Always:**
- Verify tests before cleanup
- Cleanup any worktree that has been merged

## Integration

**Called by:**
- **subagent-driven-development** - After all tasks complete and merged
- **parallel-subagent-driven-development** - After all tasks complete and merged
- **executing-plans** - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Creates worktrees before development
