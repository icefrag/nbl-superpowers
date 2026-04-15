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

| Mode | Branch Name | Worktree Path | Base Branch |
|------|-------------|---------------|-------------|
| **Work (Serial)** | `feature/{name}-work` | `.worktrees/{name}-work` | `feature/{name}` |
| **Merge** | `feature/{name}-merge` | `.worktrees/{name}-merge` | `feature/{name}` |
| Parallel Task | `feature/{name}-task{id}` | `.worktrees/{name}-task{id}` | `feature/{name}-merge` |

## Usage

### Work Worktree (Serial Mode)

基于主开发分支创建工作 worktree：

```bash
./skills/nbl.using-git-worktrees/scripts/create-worktree.sh "<name>-work" --parent "feature/<name>"
```

### Merge Worktree (Parallel Mode Intermediate Buffer)

基于主开发分支创建 merge worktree：

```bash
./skills/nbl.using-git-worktrees/scripts/create-worktree.sh "<name>-merge" --parent "feature/<name>"
```

### Parallel Worktree (Parallel Mode Tasks)

基于 merge 分支创建 task worktree：

```bash
# Create multiple worktrees for parallel tasks
for task_id in 1 2 3; do
    ./skills/nbl.using-git-worktrees/scripts/create-worktree.sh <base_name> --parent "feature/<base_name>-merge" $task_id
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

**可从任何位置执行** - 脚本自动检测并跳转到主仓库根目录，通过 `git -C` 在正确的 worktree 中执行命令。

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

## Windows Git Bash 兼容性

在 Windows 平台上使用 Git Bash 时，skill 脚本的完整路径由 Claude Code 以 Windows 格式给出（`C:\Users\...`），**必须**转换为 Git Bash 格式后再调用：

### 转换规则
1. **驱动器号转换**: `C:\` → `/c/` (盘符小写)
2. **分隔符转换**: **所有**反斜杠 `\` → 正斜杠 `/`，**禁止混合**
3. **引号包裹**: 始终用双引号包裹整个路径

### 常见错误案例

❌ **错误 1 - 混合斜杠**（前半反斜杠，后半正斜杠）：
```bash
bash C:\Users\icefr\.claude\plugins\marketplaces\nbl-dev\skills\nbl.using-git-worktrees/scripts/create-worktree.sh log-analyzer-merge
```
反斜杠被 Bash 当作转义符逐个吃掉，路径完全损坏。**这是最常见的错误**。

❌ **错误 2 - 无引号全反斜杠**：
```bash
bash C:\Users\icefr\.claude\plugins\marketplaces\nbl-dev\skills\nbl.using-git-worktrees\scripts\create-worktree.sh log-analyzer-merge
```
即使全部反斜杠，不加引号时所有反斜杠依然会被 Bash 转义吃掉。

✅ **正确调用**（全正斜杠 + 引号）：
```bash
bash "/c/Users/icefr/.claude/plugins/marketplaces/nbl-dev/skills/nbl.using-git-worktrees/scripts/create-worktree.sh" log-analyzer-merge
```

### 判断逻辑
- 如果 Base directory 以 `C:\` / `D:\` 等 Windows 盘符开头 → 需要完整转换
- 如果 Base directory 以 `/` 开头 → macOS/Linux，直接调用，仍需加引号

所有脚本调用都必须遵守此规则，避免路径转义错误。
