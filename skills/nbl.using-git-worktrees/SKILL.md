---
name: nbl.using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Scripts handle all worktree operations reliably.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Invocation

Invoke via skill command:

| Operation | Command |
|-----------|---------|
| Create | `/nbl.superpowers:nbl.using-git-worktrees create <base_name> [task_id]` |
| Cleanup | `/nbl.superpowers:nbl.using-git-worktrees cleanup <base_name> [task_id] [--force]` |
| Sub-to-sub Merge (parallel mode) | `/nbl.superpowers:nbl.using-git-worktrees merge-sub <base_name> <task_id>` |

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
./skills/nbl.using-git-worktrees/scripts/create-worktree.sh <base_name>
```

### Merge Worktree (Parallel Mode Intermediate Buffer)

**Same usage as Single Worktree** - just use base name ending with `-merge`.

```bash
./skills/nbl.using-git-worktrees/scripts/create-worktree.sh "<name>-merge"
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

## Sub-to-Sub Merge (Parallel Mode)

**用于并行模式下任务完成后将任务分支合并回merge工作树**：

```bash
# All-in-one: rebase task -> merge to merge branch -> cleanup task worktree
./skills/nbl.using-git-worktrees/scripts/sub-to-sub-merge.sh <base_name> <task_id>
```

**必须在merge工作树中执行** - merge分支已经在此检出，不能在主工作区执行。

## Script Reference

| Script | Purpose | Key Features |
|--------|---------|--------------|
| `scripts/create-worktree.sh` | Create/reuse worktree | Auto git init, gitignore check, smart recovery |
| `scripts/cleanup-worktree.sh` | Remove worktree | Unmerged commit check, --force option |
| `scripts/sub-to-sub-merge.sh` | Sub-to-sub merge | Rebase + merge + cleanup in one step |
| `scripts/lib/common.sh` | Shared utilities | JSON output, naming helpers |

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
