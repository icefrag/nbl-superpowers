---
name: nbl.finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice (merge if selected) → Clean up.

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

**If parallel mode detected:** Execute Step 2A (detect only, no auto-merge).

### Step 2A: Detect Parallel Mode (No Auto-Merge)

**Parallel mode detected when merge worktree exists (`feature/{name}-merge` branch at `.worktrees/{name}-merge/`).**

The merge worktree contains all accumulated changes from all parallel tasks. **Do NOT merge automatically.** The merge will be performed after user selection in Step 5. Continue directly to Step 3.

### Step 3: Determine Base Branch

```bash
# Get the primary worktree's current branch (first entry in git worktree list)
# This is the branch we created the current worktree from — the correct merge target
PRIMARY_WORKTREE=$(git worktree list | head -1)
BASE_BRANCH=$(echo "$PRIMARY_WORKTREE" | sed -n 's/.*\[\(.*\)\]$/\1/p')

# Fallback if branch name could not be extracted
if [[ -z "$BASE_BRANCH" ]]; then
  if git show-ref --verify --quiet refs/heads/main; then
    BASE_BRANCH="main"
  else
    BASE_BRANCH="master"
  fi
fi
```

**Logic:**
1. `git worktree list` first entry is always the primary worktree — the branch it's on is where this worktree was created from
2. Extract branch name from `[...]` at end of line
3. Fallback to `main`/`master` only if extraction fails
4. Ask user to confirm: "This branch split from `<base-branch>` - is that correct?"

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

**Parallel mode only:** First merge merge branch to development branch:
```bash
# Switch to development branch (base branch in parallel mode)
git checkout <development-branch>

# Merge the completed merge branch
git merge --ff-only feature/<name>-merge

# Verify tests on merged result
<test command>
```

**If tests fail:** Stop and fix before proceeding.

If tests pass: Continue with merge to base branch:
```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge development branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

#### Option 2: Push and Create PR

**Parallel mode only:** First merge merge branch to development branch:
```bash
# Switch to development branch
git checkout <development-branch>

# Merge the completed merge branch
git merge --ff-only feature/<name>-merge

# Verify tests on merged result
<test command>
```

**If tests fail:** Stop and fix before proceeding.

If tests pass: Continue with push:
```bash
# Push branch
git push -u origin <feature-branch>

# Create PR/MR body template
PR_BODY=$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)

# Create PR/MR - auto-detect GitHub/GitLab
if command -v gh >/dev/null 2>&1; then
  # GitHub CLI
  gh pr create --title "<title>" --body "$PR_BODY"
elif command -v glab >/dev/null 2>&1; then
  # GitLab CLI
  glab mr create --title "<title>" --description "$PR_BODY"
else
  echo "No GitHub CLI (gh) or GitLab CLI (glab) found."
  echo "Branch pushed to <feature-branch>, please create your PR/MR manually."
fi
```

Then: Cleanup worktree (Step 6)

#### Option 3: Keep As-Is

**Parallel mode:** Do NOT merge merge branch to development branch. Do NOT cleanup merge worktree.

Report: "Keeping branch <name>. Merge worktree preserved at `.worktrees/{name}-merge/`. You can finish the merge later."

**Don't cleanup any worktree.**

**Serial/Inline mode:** Same as before - keep worktree as-is.

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits in merge branch: <commit-list>
- Merge worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
# Parallel mode: Delete merge branch directly, do not merge
git checkout <base-branch>
git branch -D feature/<name>-merge
```

Then: Cleanup merge worktree (Step 6)

### Step 6: Cleanup Worktree

**NON-NEGOTIABLE: All cleanup MUST be performed via `nbl.using-git-worktrees` skill.** The skill provides proper safety checks and handles platform detection.

**For Options 1, 2, 4:**

Invoke `nbl.using-git-worktrees` cleanup:

```
Invoke via: /nbl.using-git-worktrees cleanup <base_name> [--force]
```

**Parallel mode additional cleanup:**

After cleaning up the main worktree, also clean up the merge worktree:

```
Invoke via: /nbl.using-git-worktrees cleanup <name>-merge --force
```

**For Option 3:** Keep worktree.

## Quick Reference

| Option | Auto-merge<br/>Merge WT → Dev | Merge<br/>Dev → Base | Push | Keep Worktree | Cleanup Branch | Cleanup Merge WT |
|--------|-------------------------------|----------------------|------|---------------|----------------|------------------|
| 1. Merge locally | ✓ | ✓ | - | - | ✓ | ✓ (parallel only) |
| 2. Create PR | ✓ | - | ✓ | - | - | ✓ (parallel only) |
| 3. Keep as-is | ✗ | - | - | ✓ | - | - (keep) |
| 4. Discard | ✗ (no merge) | - | - | - | ✓ (force) | ✓ (parallel only) |

**Key change (parallel mode):** Merge from merge worktree to development branch only happens after user selects Option 1 or 2. Option 3 keeps everything as-is for later completion.

## Mode-Specific Behavior

### Inline Mode (executing-plans)

- No worktree cleanup needed (working directly on dev branch)
- Just present options for the dev branch

### Serial Mode (subagent-driven-development)

- One worktree to clean up: `.worktrees/{name}/`
- Use `cleanup-worktree` script with base_name

### Parallel Mode (parallel-subagent-driven-development)

- Merge worktree: `.worktrees/{name}-merge/` — **NOT merged automatically**
- Task worktrees already cleaned up during execution (by `sub-to-sub-merge` script)
- Merge to development branch only happens when user selects Option 1 or 2
- Option 3 keeps merge worktree for later completion
- Cleanup only happens after user selection, never automatically

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
- **Fix:** Option 1/2 triggers merge to dev branch then cleanup; Option 3 preserves for later

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
