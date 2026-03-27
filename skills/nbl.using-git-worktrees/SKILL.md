---
name: nbl.using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

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
| Parallel | `feature/{name}-task{id}` | `.worktrees/{name}-task{id}` |

### Examples

```
Plan file: docs/nbl/plans/2026-03-27-user-authentication.md
  → Base name: user-authentication
  → Single worktree:  .worktrees/user-authentication
  → Parallel task 1:  .worktrees/user-authentication-task1
  → Parallel task 3:  .worktrees/user-authentication-task3
```

## Directory Selection Process

Always use `.worktrees/` (project-local, hidden). This is the preferred convention.

### 1. Check Existing Directory

```bash
# Check if .worktrees exists
ls -d .worktrees 2>/dev/null
```

**If found:** Use that directory.

**If NOT found:** Create `.worktrees/` directory.

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

Per Jesse's rule "Fix broken things immediately":
1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents to repository.

### For Global Directory (~/.config/nbl/worktrees)

No .gitignore verification needed - outside project entirely.

## Creation Steps

### 1. Determine Branch Name

```
# Priority: explicit param > plan file > description

IF caller provides branch_name:
    base_name = branch_name
ELSE IF plan file exists (docs/nbl/plans/*.md):
    base_name = extract name from filename (YYYY-MM-DD-{name}.md)
ELSE:
    base_name = kebab-case(feature description)
```

### 2. Create Worktree (Single Mode)

```bash
# Single worktree for sequential execution
branch_name="feature/${base_name}"
worktree_path=".worktrees/${base_name}"

git worktree add "$worktree_path" -b "$branch_name"
cd "$worktree_path"
```

### 3. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi

# Java (Maven)
if [ -f pom.xml ]; then mvn dependency:go-offline -B; fi

# Java (Gradle)
if [ -f build.gradle ] || [ -f build.gradle.kts ]; then gradle dependencies; fi
```

### 4. Verify Clean Baseline

Run tests to ensure worktree starts clean:

```bash
# Examples - use project-appropriate command
npm test
cargo test
pytest
go test ./...
mvn test
gradle test
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### 5. Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Batch Operations (Parallel Mode)

When executing parallel tasks, create and manage multiple worktrees.

### Create Multiple Worktrees

```bash
# For parallel tasks in a level
# base_name determined from plan file or description

for task_id in 1 3 5; do
    branch_name="feature/${base_name}-task${task_id}"
    worktree_path=".worktrees/${base_name}-task${task_id}"

    git worktree add "$worktree_path" -b "$branch_name"
done
```

### Cleanup Worktree After Merge

After a task is merged to base branch (note: for parallel mode, cleanup happens in finishing-a-development-branch):

```bash
# Remove worktree
git worktree remove ".worktrees/${base_name}-task${task_id}"
# Delete branch
git branch -d "feature/${base_name}-task${task_id}"
```

### Directory Structure Example

```
.worktrees/
├── user-authentication-task1/      # Task 1 worktree
├── user-authentication-task3/      # Task 3 worktree
├── user-authentication-task4/      # Task 4 worktree
└── user-authentication/            # Single mode (optional)
```

### Parallel Mode Integration

- **subagent-driven-development (parallel mode)** - Creates batch worktrees for parallel tasks
- Maximum 5 parallel worktrees at a time
- Each worktree is cleaned up after its task is merged

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `.worktrees/` does not exist | Create `.worktrees/` directory |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Auto-detect from project files (package.json, etc.)

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Plan file: docs/nbl/plans/2026-03-27-user-auth.md]
[Extract base_name: user-auth]
[Check .worktrees/ - exists]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[Create worktree: git worktree add .worktrees/user-auth -b feature/user-auth]
[Run npm install]
[Run npm test - 47 passing]

Worktree ready at /Users/jesse/myproject/.worktrees/user-auth
Branch: feature/user-auth
Tests passing (47 tests, 0 failures)
Ready to implement user-auth feature
```

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Use `.worktrees/` directory
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
