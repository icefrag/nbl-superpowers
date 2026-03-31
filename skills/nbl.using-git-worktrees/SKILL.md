---
name: nbl.using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Scripts handle all worktree operations reliably.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Branch Naming Convention

### Name Source Priority

1. **Explicit parameter** - Caller provides `branch_name`
2. **Plan file inference** - Extract from `docs/nbl/plans/YYYY-MM-DD-{name}.md`
3. **Feature description** - Convert to kebab-case (e.g., "User Auth" → `user-auth`)

### Naming Formats

| Mode | Branch Name | Worktree Path |
|------|-------------|---------------|
| Single | `feature/{name}` | `.worktrees/{name}` |
| **Merge** | `feature/{name}-merge` | `.worktrees/{name}-merge` |
| Parallel Task | `feature/{name}-task{id}` | `.worktrees/{name}-task{id}` |

## Usage

### Single Worktree (Sequential Mode)

```bash
# Detect platform and run appropriate script
if [[ -n "${COMSPEC:-}" ]]; then
    # PowerShell (Windows native)
    ./skills/nbl.using-git-worktrees/scripts/create-worktree.ps1 <base_name>
else
    # Bash (Linux/macOS/Git-Bash)
    ./skills/nbl.using-git-worktrees/scripts/create-worktree.sh <base_name>
fi
```

### Merge Worktree (Parallel Mode Intermediate Buffer)

**Same usage as Single Worktree** - just use base name ending with `-merge`. Existing scripts already support this pattern, no changes needed.

```bash
# For merge worktree in parallel mode
if [[ -n "${COMSPEC:-}" ]]; then
    ./skills/nbl.using-git-worktrees/scripts/create-worktree.ps1 "<name>-merge"
else
    ./skills/nbl.using-git-worktrees/scripts/create-worktree.sh "<name>-merge"
fi
```

### Parallel Worktree (Parallel Mode Tasks)

```bash
# Create multiple worktrees for parallel tasks
for task_id in 1 2 3; do
    ./skills/nbl.using-git-worktrees/scripts/create-worktree.sh <base_name> $task_id
done
```

## Cleanup

### Single Worktree

```bash
# Check for unmerged commits first
./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.sh <base_name>

# Force delete if needed
./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.sh <base_name> --force
```

### Parallel Worktrees

```bash
# Cleanup each task's worktree
for task_id in 1 2 3; do
    ./skills/nbl.using-git-worktrees/scripts/cleanup-worktree.sh <base_name> $task_id [--force]
done
```

## Script Reference

| Script | Purpose | Key Features |
|--------|---------|--------------|
| `scripts/create-worktree.sh/ps1` | Create/reuse worktree | Auto git init, gitignore check, smart recovery |
| `scripts/cleanup-worktree.sh/ps1` | Remove worktree | Unmerged commit check, --force option |
| `scripts/lib/common.sh/ps1` | Shared utilities | JSON output, naming helpers |

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
