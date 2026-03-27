---
name: nbl.finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

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

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Present Options

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

### Step 4: Execute Choice

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

Then: Cleanup worktree (Step 5)

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

Then: Cleanup worktree (Step 5)

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

Then: Cleanup worktree (Step 5)

### Step 5: Cleanup Worktree

**For Options 1, 2, 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

### Step 6: Batch Cleanup Parallel Worktrees

After all parallel tasks are merged to base branch, clean up any remaining parallel worktrees (some may have been cleaned up by parallel-subagent-driven-development after each task merge):

```bash
# Check if .worktrees directory exists
if [ -d ".worktrees" ] && [ "$(ls -A .worktrees)" ]; then
    echo "Cleaning up parallel task worktrees..."

    # Get the base branch (the branch we merged into)
    base_branch=$(git branch --show-current)

    # For each worktree under .worktrees/
    for wt_path in .worktrees/*/; do
        # Skip if not a directory (already removed)
        [ -d "$wt_path" ] || continue

        # Get the branch name for this worktree
        worktree_branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)

        if [ -n "$worktree_branch" ]; then
            # Check if branch is merged to base branch
            if git merge-base --is-ancestor "$worktree_branch" "$base_branch" 2>/dev/null; then
                # Check if worktree still exists (may have been cleaned up already)
                if [ -d "$wt_path" ]; then
                    echo "Removing merged worktree: $wt_path (branch: $worktree_branch)"
                    git worktree remove "$wt_path" 2>/dev/null || true
                else
                    echo "Worktree already cleaned: $wt_path"
                fi
                # Try to delete the branch (use -D if already deleted via worktree remove)
                git branch -d "$worktree_branch" 2>/dev/null || git branch -D "$worktree_branch" 2>/dev/null || true
            else
                echo "Skipping: $worktree_branch not yet merged to $base_branch"
            fi
        fi
    done
fi
```

**Note:**
- In parallel mode, `parallel-subagent-driven-development` cleans up worktree immediately after each task merge
- This step only cleans up any worktrees that were skipped due to cleanup failures
- Only worktrees in `.worktrees/` directory are cleaned up (parallel task convention)
- Other worktrees outside `.worktrees/` are preserved

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill

**Note:** In parallel mode, `subagent-driven-development` does NOT cleanup worktrees after each task. All parallel worktrees are cleaned up here in Step 6 after all tasks are merged.
