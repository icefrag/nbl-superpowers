---
name: nbl.parallel-subagent-driven-development
description: Use when executing implementation plans with parallelizable tasks - analyzes dependencies, groups by level, executes independent tasks concurrently
---

# Parallel Subagent-Driven Development

Execute plan by dispatching fresh subagent per task. Each implementer performs built-in two-stage self-review (spec compliance + code quality) before reporting done. After all tasks complete in all levels, perform global two-stage review on all merged code.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task with built-in two-stage self-review + global review after all tasks = high quality, fast iteration

**Parallel execution:** Analyzes task dependencies, groups tasks by level, and executes independent tasks in parallel within each level.

## ⛔ STOP: Read Before ANY Action

```
┌─────────────────────────────────────────────────────────────────┐
│  BEFORE reading plan, BEFORE creating tasks, BEFORE anything:   │
│                                                                 │
│  1. On main/master branch → AUTO-create feature/bugfix branch  │
│  2. Each task creates its own isolated worktree when dispatched │
│                                                                 │
│  No top-level worktree needed before starting                   │
└─────────────────────────────────────────────────────────────────┘
```

**Key difference from serial mode:** Parallel mode creates a separate worktree for **each task** individually. No need to create a top-level worktree before starting. If starting from main/master, a development branch is auto-created based on the plan name.

## NON-NEGOTIABLE Requirements (Read BEFORE Starting)

**You MUST complete these checks before dispatching ANY implementer subagent:**

<NON_NEGOTIABLE>

### 1. Worktree Setup (MANDATORY)

```
Before each level:
├── Isolated workspace? → Call nbl.using-git-worktrees
│   ├── Single task in level → Single worktree
│   └── Multiple tasks in level → Batch worktrees (max 5)
└── Verify: git worktree list shows your worktree(s)
```

**Never:** Dispatch implementer on main/master branch without worktree isolation

### 2. TDD Required (MANDATORY)

```
Every implementation task MUST:
├── Invoke nbl.test-driven-development skill FIRST
├── Skill guides RED→GREEN→REFACTOR cycle
└── Never write implementation before tests
```

**Never:** Skip TDD skill, write implementation before tests

### 3. Built-In Two-Stage Self-Review (MANDATORY)

```
Each implementer MUST complete this before reporting DONE:
├── Stage 1: Spec compliance self-review
│   ├── Check all requirements line-by-line
│   ├── ❌ Issues? → Implementer fixes immediately
│   └── ✅ Pass → Proceed to Stage 2
├── Stage 2: Code quality self-review
│   ├── Check code quality, naming, conventions
│   ├── ❌ Issues? → Implementer fixes immediately
│   └── ✅ Pass → Report DONE
└── Never report DONE until both stages pass with NO issues
```

**Never:**
- Skip either stage of self-review
- Report DONE with unfixed issues
- Proceed to merge with open issues

**This is NON-NEGOTIABLE.** Each task must pass both stages of self-review before it can be merged.

</NON_NEGOTIABLE>

## Level-Based Execution

### Dependency Graph Analysis

```python
# Pseudocode
def analyze_plan(plan):
    for task in plan.tasks:
        if task.dependencies == None:
            task.level = 0
        else:
            task.level = max(dep.level for dep in task.dependencies) + 1

    levels = group_by_level(tasks)
    return levels
```

### Level Semantics

```
Level 0: Task 1, Task 3      # No dependencies
        ↓
Level 1: Task 2, Task 4      # Depends on Level 0
        ↓
Level 2: ...                  # Depends on Level 1
```

**Key insight:** Level describes **dependency constraints**. All tasks in a level must complete before Level+1 starts.

### Pipeline Execution Pattern

```
For each level:
    ├── Create worktrees for tasks in this level (max 5 per batch)
    ├── Dispatch agents in parallel
    ├── Wait all tasks complete (implementer does built-in two-stage self-review)
    ├── Rebase each task branch to base branch
    ├── Merge all task branches to base branch
    ├── Mark all completed tasks as done in TodoWrite and plan file
    └── Proceed to next level
```

### Level Completion Criteria

**All tasks must complete ALL steps before next level:**

| Step | Description | Must Pass? |
|------|-------------|------------|
| 1 | Implementer reports DONE (with built-in self-review passed) | ✅ |
| 2 | Rebase to base | ✅ |
| 3 | Merge to base | ✅ |
| 4 | Mark task statuses complete in plan file | ✅ |

**Key rule:** Level completion = ALL tasks passed ALL steps.

### Failure Handling

If any task fails at any step:
1. **Level is blocked** — do NOT proceed to next level
2. **Fix the failing task** — implementer fixes, re-review if needed
3. **Resume once all tasks pass** — then proceed to next level

## Pipeline Execution

This section documents the detailed flow for multi-task levels. See "The Process" diagram above for the unified view.

### Pipeline Flow

```dot
digraph pipeline_flow {
    rankdir=TB;

    subgraph cluster_dispatch {
        label="Parallel Dispatch";
        style=filled fillcolor=lightblue;
        "Create worktrees (max 5 per batch)" [shape=box];
        "Dispatch N implementers (each with built-in two-stage review)" [shape=box];
    }

    subgraph cluster_process {
        label="Process Each Completion (Sequential)";
        style=filled fillcolor=lightyellow;
        "Wait for ANY agent to complete" [shape=diamond];
        "Implementer reports DONE (self-review passed)" [shape=box];
        "Rebase to base" [shape=box];
        "Merge to base" [shape=box];
        "Cleanup worktree" [shape=box];
    }

    subgraph cluster_loop {
        label="Completion Loop";
        "More agents pending?" [shape=diamond];
        "Level complete" [shape=box];
    }

    "Create worktrees (max 5 per batch)" -> "Dispatch N implementers (each with built-in two-stage review)";
    "Dispatch N implementers (each with built-in two-stage review)" -> "Wait for ANY agent to complete";
    "Wait for ANY agent to complete" -> "Implementer reports DONE (self-review passed)";
    "Implementer reports DONE (self-review passed)" -> "Rebase to base";
    "Rebase to base" -> "Merge to base";
    "Merge to base" -> "Cleanup worktree";
    "Cleanup worktree" -> "More agents pending?";
    "More agents pending?" -> "Wait for ANY agent to complete" [label="yes"];
    "More agents pending?" -> "Level complete" [label="no"];
}
```

### Per-Task Rebase + Merge Process

For each completed agent:

1. **Implementer completes:** implement → spec self-check → fix → quality self-check → fix → DONE
2. **Rebase** (in task worktree, on task branch) - `git rebase $base_branch` (handle conflicts if any)
   - `$base_branch` is the branch we created worktrees from (e.g., main, dev, master)
3. **Merge** (in main workspace, on base branch) - `git checkout $base_branch && git merge --ff-only $task_branch`
   - `$task_branch` is the branch for this task (e.g., `feature/{base_name}-task{task_id}`)
4. **Cleanup worktree** - Remove the task worktree immediately (non-blocking)
   ```bash
   # Cleanup worktree - failure does not block the pipeline
   if [ -d "$worktree_path" ]; then
       if git worktree remove --force "$worktree_path" 2>/dev/null; then
           echo "✅ Worktree cleaned: $worktree_path"
       else
           echo "⚠️ Warning: Failed to remove worktree $worktree_path - skipping, manual cleanup may be needed"
       fi
   end
   ```
5. **Keep branch** - Branch deletion is handled by `finishing-a-development-branch` after all tasks complete

### Error Handling

| Scenario | Action |
|----------|--------|
| Implementer cannot complete (BLOCKED/NEEDS_CONTEXT) | Main agent provides context or re-dispatches |
| Rebase conflict | Follow "Rebase Conflict Resolution" section below |
| Merge fails | Rollback, fix, retry |
| **Any task in level fails** | **Whole level blocked — do NOT proceed to next level** |

**Rule:** One agent failure does not block other parallel agents from executing, but blocks that agent's subsequent merges until fixed. Any failure at the level level blocks the entire level from completing.

## Rebase Conflict Resolution

When `git rebase $base_branch` encounters conflicts, use the following process:

### Why LLM for Conflicts?

Large language models excel at resolving Git conflicts because they understand semantics:
- Can analyze what changed in base vs what the subagent changed
- Can intelligently merge non-conflicting parts
- Can resolve most simple conflicts automatically (70-80%)
- Only complex semantic conflicts require human judgment

### Resolution Flow

```
1. git rebase $base_branch
2. If conflict:
   a. Get conflict status: git status
   b. Get conflict details: git diff (shows base vs subagent changes)
   c. LLM analyzes → generates merged code
   d. Write merged files
   e. git add <conflict-files>
   f. git rebase --continue
3. If auto-resolution succeeds → continue normal flow
```

### Escalation: When Auto-Resolution Fails

If the conflict is too complex for automatic resolution:

1. `git rebase --abort` — rollback to state before rebase attempt
2. Present conflict details to user
3. Explain why automatic resolution failed
4. User makes decision:
   - Manually resolve themselves
   - Provide additional context for retry
   - Other approach

### Key Principle

**Main agent coordinates; user decides on complex conflicts; LLM executes.**

| Conflict Type | Action |
|--------------|--------|
| Simple (localized, obvious merge) | LLM auto-resolve |
| Complex (semantic ambiguity) | Escalate to user |

## The Process (WITH NON-NEGOTIABLE GATES)

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_setup {
        label="Setup Phase";
        style=filled fillcolor=lightyellow;
        "⛔ GATE 1: Check current branch" [shape=box style=filled fillcolor=yellow];
        "On main/master?" [shape=diamond style=filled fillcolor=yellow];
        "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
        "Analyze dependencies → Build levels" [shape=box];
    }

    subgraph cluster_level_loop {
        label="For Each Level (Sequential)";
        style=filled fillcolor=lightyellow;
        "Create worktrees for tasks in this level (max 5)" [shape=box style=filled fillcolor=lightpink];
        "Dispatch N implementers (each with built-in two-stage review)" [shape=box style=filled fillcolor=lightblue];
    }

    // Pre-execution flow
    "⛔ GATE 1: Check current branch" -> "On main/master?";
    "On main/master?" -> "Read plan, extract all tasks with full text, note context, create TodoWrite" [label="no - ok, each task creates its own worktree"];
    "On main/master?" -> "Auto-create dev branch from plan name" [label="yes"];
    "Auto-create dev branch from plan name" -> "Checkout new branch (feature/bugfix)" -> "Read plan, extract all tasks...";

    subgraph cluster_pipeline {
        label="Pipeline Processing";
        style=filled fillcolor=lightblue;
        "Wait for ANY completion" [shape=diamond];
        "Implementer reports DONE (built-in self-review passed)" [shape=box];
        "Rebase to base" [shape=box];
        "Merge to base" [shape=box];
        "Cleanup worktree" [shape=box];
        "More agents pending?" [shape=diamond];
        "Level complete" [shape=box];
    }

    subgraph cluster_cleanup {
        label="After Level Complete";
        "Mark level tasks complete (TodoWrite + Plan file)" [shape=box];
        "More levels?" [shape=diamond];
    }

    subgraph cluster_finish {
        label="All Levels Complete";
        "Global Stage 1: Spec review (all changes)" [shape=box];
        "Global Stage 2: Code quality review (all changes)" [shape=box];
        "Fix any issues found" [shape=box];
        "Use nbl.finishing-a-development-branch with mode=parallel" [shape=doublecircle style=filled fillcolor=lightgreen];
    }

    // Setup flow
    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Analyze dependencies → Build levels";
    "Analyze dependencies → Build levels" -> "Create worktrees for tasks in this level (max 5)";
    "Create worktrees for tasks in this level (max 5)" -> "Dispatch N implementers (each with built-in two-stage review)";

    // Pipeline processing
    "Dispatch N implementers (each with built-in two-stage review)" -> "Wait for ANY completion";
    "Wait for ANY completion" -> "Implementer reports DONE (built-in self-review passed)";
    "Implementer reports DONE (built-in self-review passed)" -> "Rebase to base";
    "Rebase to base" -> "Merge to base";
    "Merge to base" -> "Cleanup worktree";
    "Cleanup worktree" -> "More agents pending?";
    "More agents pending?" -> "Wait for ANY completion" [label="yes - continue"];
    "More agents pending?" -> "Level complete" [label="no"];

    // Cleanup flow
    "Level complete" -> "Mark level tasks complete (TodoWrite + Plan file)";
    "Mark level tasks complete (TodoWrite + Plan file)" -> "More levels?";
    "More levels?" -> "Create worktrees for tasks in this level (max 5)" [label="yes - next level"];
    "More levels?" -> "Global Stage 1: Spec review (all changes)" [label="no"];
    "Global Stage 1: Spec review (all changes)" -> "Global Stage 2: Code quality review (all changes)" [label="passed"];
    "Global Stage 2: Code quality review (all changes)" -> "Fix any issues found" [label="issues found"];
    "Fix any issues found" -> "Global Stage 1: Spec review (all changes)";
    "Global Stage 2: Code quality review (all changes)" -> "Use nbl.finishing-a-development-branch with mode=parallel" [label="passed"];
}
```

### Batch Handling for 6+ Tasks

| Tasks in Level | Approach |
|----------------|----------|
| **2-5 tasks** | Single batch, all agents in parallel |
| **6+ tasks** | Split into batches of 5, process batch by batch |

### Process Gates Summary

| Gate | Location | Requirement |
|------|----------|-------------|
| **GATE 1: Branch Check** | BEFORE reading plan | If on main/master → **auto-create development branch** (feature/bugfix based on plan name). All tasks merge back to this dev branch. |
| **GATE 2: TDD** | Implementer phase | MUST invoke `nbl.test-driven-development` skill |
| **GATE 3: Built-In Self-Review** | Implementer phase | Each implementer MUST perform two-stage self-review before reporting DONE |
| **GATE 4: Global Spec Review** | After all levels complete | MUST invoke spec reviewer on all merged changes |
| **GATE 5: Global Quality Review** | After global spec review | MUST invoke code quality reviewer on all merged changes |

**Note:** Each task creates its own isolated worktree when dispatched. No top-level worktree is created at startup. After all tasks complete, everything is merged to the development branch (auto-created if starting from main). User manually merges dev branch to main when ready.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture, design, and review tasks**: use the most capable available model.

**Task complexity signals:**
- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Implementer completed the work **and** passed built-in two-stage self-review with all issues fixed. Mark task complete and proceed to rebase/merge.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before merging. If they're observations (e.g., "this file is getting large"), note them and proceed.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Prompt Templates

Prompt templates are shared with serial subagent-driven-development:
- `../nbl.subagent-driven-development/implementer-prompt.md` - Dispatch implementer subagent
- `../nbl.subagent-driven-development/spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
- `../nbl.subagent-driven-development/code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans (main agent):**
- Subagents execute (isolated context)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Efficiency gains:**
- No file reading overhead (controller provides full text)
- Controller curates exactly what context is needed
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)
- Parallel tasks complete faster

**Quality gates:**
- Implementer finds and fixes issues before returning to main agent
- Two-stage review still happens (just inside the implementer)
- Final global review ensures quality across all changes
- Same quality guarantees with fewer coordination steps

**Efficiency:**
- One subagent invocation per task (with built-in two-stage review)
- Fewer round-trips between main agent and subagents
- Faster overall execution because implementer fixes issues before returning
- Catches issues early (cheaper than debugging later)

## Red Flags

**Never (NON-NEGOTIABLE):**
- **Execute on main/master branch without explicit user consent**
- **Dispatch an implementer without worktree isolation** (each task MUST have its own worktree, created via `nbl.using-git-worktrees` with taskId when dispatching)
- **Accept DONE before built-in two-stage review completes** - MUST verify implementer performed both stages
- **Skip TDD** - "implement first, test later" is forbidden

**Never:**
- Proceed with unfixed issues from self-review
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Dispatch more than 5 agents simultaneously
- Skip CR before merge
- Merge without rebasing first
- Proceed to next level with failed agents
- Ignore rebase conflicts
- Skip the final global two-stage review after all levels complete

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation
- **Parallel mode:** One question at a time to the user - other agents keep running while waiting

**If global reviewer finds issues after all tasks complete:**
- Dispatch fix subagent with specific instructions
- Fix issues found by reviewers
- Re-review after fixes
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **nbl.using-git-worktrees** - REQUIRED: Set up isolated worktrees before each level
- **nbl.writing-plans** - Creates the plan this skill executes (with task dependencies)
- **nbl.requesting-code-review** - Code review template for reviewer subagents
- **nbl.finishing-a-development-branch** - Complete development after all tasks are merged with mode=parallel

**Subagents should use:**
- **nbl.test-driven-development** - Subagents follow TDD for each task
