---
name: nbl.subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration

## ⛔ STOP: Read Before ANY Action

```
┌─────────────────────────────────────────────────────────────────┐
│  BEFORE reading plan, BEFORE creating tasks, BEFORE anything:   │
│                                                                 │
│  1. Are you on main/master branch? → MUST call worktree skill   │
│  2. Already in a worktree? → Skip to "Read Plan" section        │
│                                                                 │
│  NEVER dispatch implementer on main/master without worktree     │
└─────────────────────────────────────────────────────────────────┘
```

## NON-NEGOTIABLE Requirements (Read BEFORE Starting)

**You MUST complete these checks before dispatching ANY implementer subagent:**

<NON_NEGOTIABLE>

### 1. Worktree Setup (MANDATORY)

```
Before first task:
├── Isolated workspace? → Call nbl.using-git-worktrees
│   ├── Sequential mode → Single worktree
│   └── Parallel mode → Batch worktrees (max 5)
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

### 3. Two-Stage Review (MANDATORY)

```
After implementer completes:
├── Stage 1: Spec compliance review
│   ├── Invoke nbl.requesting-code-review skill
│   ├── Use spec-reviewer-prompt.md template
│   ├── ❌ Issues? → Implementer fixes → Re-review
│   └── ✅ Pass → Proceed to Stage 2
├── Stage 2: Code quality review
│   ├── Invoke nbl.requesting-code-review skill
│   ├── Use code-quality-reviewer-prompt.md template
│   ├── ❌ Issues? → Implementer fixes → Re-review
│   └── ✅ Pass → Task complete
└── Never skip either stage
```

**Never:**
- Let implementer self-review replace actual review
- Skip spec compliance review
- Skip code quality review
- Proceed to next task with open review issues

</NON_NEGOTIABLE>

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
}
```

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Two-stage review after each task: spec compliance first, then code quality
- Faster iteration (no human-in-loop between tasks)

## Execution Mode

After reading the plan, analyze task dependencies to determine execution mode.

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

### Level-Based Execution

```
Level 0 (parallel): Task 1, Task 3      # No dependencies
        ↓
Level 1 (parallel): Task 2, Task 4      # Depends on Level 0
        ↓
Level 2: ...                            # Depends on Level 1
```

**Rule:** All tasks in a level must complete before Level+1 starts.

### Mode Selection

```dot
digraph mode_selection {
    "Read plan" [shape=box];
    "Build dependency graph" [shape=box];
    "Current level has multiple tasks?" [shape=diamond];
    "Sequential mode\n(existing flow)" [shape=box];
    "Parallel mode\n(new flow)" [shape=box];

    "Read plan" -> "Build dependency graph";
    "Build dependency graph" -> "Current level has multiple tasks?";
    "Current level has multiple tasks?" -> "Sequential mode\n(existing flow)" [label="no"];
    "Current level has multiple tasks?" -> "Parallel mode\n(new flow)" [label="yes"];
}
```

## Parallel Execution Mode

When a level has multiple independent tasks:

### Parallel Limit

**MAX_PARALLEL_AGENTS = 5**

If level has more than 5 tasks, split into batches.

### Execution Flow

```dot
digraph parallel_flow {
    rankdir=TB;

    "Create worktrees (max 5)" [shape=box];
    "Dispatch agents in parallel" [shape=box];
    "Wait for any completion" [shape=box];
    "Stage 1: Spec Review" [shape=diamond];
    "Fix spec issues" [shape=box];
    "Stage 2: Code Quality Review" [shape=diamond];
    "Fix quality issues" [shape=box];
    "Rebase to main" [shape=box];
    "Merge to main" [shape=box];
    "Cleanup worktree" [shape=box];
    "More agents pending?" [shape=diamond];
    "Level complete" [shape=box];

    "Create worktrees (max 5)" -> "Dispatch agents in parallel";
    "Dispatch agents in parallel" -> "Wait for any completion";
    "Wait for any completion" -> "Stage 1: Spec Review";
    "Stage 1: Spec Review" -> "Fix spec issues" [label="issues found"];
    "Fix spec issues" -> "Stage 1: Spec Review";
    "Stage 1: Spec Review" -> "Stage 2: Code Quality Review" [label="passed"];
    "Stage 2: Code Quality Review" -> "Fix quality issues" [label="issues found"];
    "Fix quality issues" -> "Stage 2: Code Quality Review";
    "Stage 2: Code Quality Review" -> "Rebase to main" [label="passed"];
    "Rebase to main" -> "Merge to main";
    "Merge to main" -> "Cleanup worktree";
    "Cleanup worktree" -> "More agents pending?";
    "More agents pending?" -> "Wait for any completion" [label="yes"];
    "More agents pending?" -> "Level complete" [label="no"];
}
```

### Rebase + Merge Process

For each completed agent:

1. **Stage 1: Spec Review** - Verify implementation matches spec
2. **Stage 2: Code Quality Review** - Verify code quality
3. **Fix Issues** - If either stage fails, implementer fixes and re-reviews
4. **Rebase** - `git rebase main` (handle conflicts if any)
5. **Merge** - `git merge --ff-only` into main
6. **Cleanup** - Remove worktree and branch

### Error Handling

| Scenario | Action |
|----------|--------|
| Spec review fails | Implementer fixes spec gaps, re-review |
| Code quality review fails | Implementer fixes quality issues, re-review |
| Agent blocked | Main agent provides context or re-dispatches |
| Rebase conflict | Main agent resolves |
| Merge fails | Rollback, fix, retry |

**Rule:** One agent failure does not block other parallel agents from executing, but blocks that agent's subsequent merges until fixed.

## The Process (WITH NON-NEGOTIABLE GATES)

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_setup {
        label="Setup Phase (NON-NEGOTIABLE)";
        style=filled fillcolor=lightyellow;
        "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
        "Call nbl.using-git-worktrees" [shape=box style=filled fillcolor=lightpink];
        "Sequential: single worktree OR Parallel: batch worktrees (max 5)" [shape=diamond];
    }

    subgraph cluster_per_task {
        label="Per Task (TDD Required)";
        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer: invoke nbl.test-driven-development, commits" [shape=box style=filled fillcolor=lightblue];
        "Implementer reports DONE?" [shape=diamond];
        "Get missing context, re-dispatch" [shape=box];
    }

    subgraph cluster_review {
        label="Two-Stage Review (NON-NEGOTIABLE)";
        style=filled fillcolor=lightgreen;
        "Invoke nbl.requesting-code-review (spec-reviewer)" [shape=box];
        "Spec reviewer confirms ✅?" [shape=diamond];
        "Implementer fixes spec gaps" [shape=box];
        "Invoke nbl.requesting-code-review (code-quality)" [shape=box];
        "Code quality reviewer approves ✅?" [shape=diamond];
        "Implementer fixes quality issues" [shape=box];
        "Mark task complete in TodoWrite" [shape=box];
    }

    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Call nbl.using-git-worktrees";
    "Call nbl.using-git-worktrees" -> "Sequential: single worktree OR Parallel: batch worktrees (max 5)";
    "Sequential: single worktree OR Parallel: batch worktrees (max 5)" -> "Dispatch implementer subagent (./implementer-prompt.md)";

    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer: invoke nbl.test-driven-development, commits" [label="no"];
    "Implementer: invoke nbl.test-driven-development, commits" -> "Implementer reports DONE?";
    "Implementer reports DONE?" -> "Get missing context, re-dispatch" [label="no - BLOCKED/NEEDS_CONTEXT"];
    "Implementer reports DONE?" -> "Invoke nbl.requesting-code-review (spec-reviewer)" [label="yes"];

    "Invoke nbl.requesting-code-review (spec-reviewer)" -> "Spec reviewer confirms ✅?";
    "Spec reviewer confirms ✅?" -> "Implementer fixes spec gaps" [label="no - issues found"];
    "Implementer fixes spec gaps" -> "Invoke nbl.requesting-code-review (spec-reviewer)" [label="re-review"];
    "Spec reviewer confirms ✅?" -> "Invoke nbl.requesting-code-review (code-quality)" [label="yes"];
    "Invoke nbl.requesting-code-review (code-quality)" -> "Code quality reviewer approves ✅?";
    "Code quality reviewer approves ✅?" -> "Implementer fixes quality issues" [label="no - issues found"];
    "Implementer fixes quality issues" -> "Invoke nbl.requesting-code-review (code-quality)" [label="re-review"];
    "Code quality reviewer approves ✅?" -> "Mark task complete in TodoWrite" [label="yes"];
    "Mark task complete in TodoWrite" -> "More tasks remain?";
    "More tasks remain?" [shape=diamond];
    "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
    "Dispatch final code reviewer subagent for entire implementation" -> "Use nbl.finishing-a-development-branch";
    "Use nbl.finishing-a-development-branch" [shape=doublecircle style=filled fillcolor=lightgreen];
}
```

### Process Gates Summary

| Gate | Location | Requirement |
|------|----------|-------------|
| **GATE 1: Worktree** | Before first task | MUST call `nbl.using-git-worktrees` |
| **GATE 2: TDD** | Implementer phase | MUST invoke `nbl.test-driven-development` skill |
| **GATE 3: Spec Review** | After implementer | MUST invoke `nbl.requesting-code-review` with spec-reviewer template |
| **GATE 4: Quality Review** | After spec review | MUST invoke `nbl.requesting-code-review` with code-quality template |

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

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/nbl/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[Create TodoWrite with all tasks]

Task 1: Hook installation script

[Get Task 1 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/nbl/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

[Dispatch spec compliance reviewer]
Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra

[Get git SHAs, dispatch code quality reviewer]
Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.

[Mark Task 1 complete]

Task 2: Recovery modes

[Get Task 2 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

[Dispatch spec compliance reviewer]
Spec reviewer: ❌ Issues:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)

[Implementer fixes issues]
Implementer: Removed --json flag, added progress reporting

[Spec reviewer reviews again]
Spec reviewer: ✅ Spec compliant now

[Dispatch code quality reviewer]
Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)

[Implementer fixes]
Implementer: Extracted PROGRESS_INTERVAL constant

[Code reviewer reviews again]
Code reviewer: ✅ Approved

[Mark Task 2 complete]

...

[After all tasks]
[Dispatch final code-reviewer]
Final reviewer: All requirements met, ready to merge

Done!
```

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Efficiency gains:**
- No file reading overhead (controller provides full text)
- Controller curates exactly what context is needed
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + 2 reviewers per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Dispatch an implementer without worktree isolation (MUST call `nbl.using-git-worktrees` first, always required regardless of current branch)
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- **Start code quality review before spec compliance is ✅** (wrong order)
- Move to next task while either review has open issues
- Dispatch more than 5 agents simultaneously
- Skip CR before merge
- Merge without rebasing first
- Proceed to next level with failed agents
- Ignore rebase conflicts
- In sequential mode (single worktree): dispatch multiple implementation subagents in parallel (conflicts)

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **nbl.using-git-worktrees** - REQUIRED: Set up isolated workspace before starting (single or batch mode)
- **nbl.writing-plans** - Creates the plan this skill executes (with task dependencies)
- **nbl.requesting-code-review** - Code review template for reviewer subagents
- **nbl.finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **nbl.test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **nbl.executing-plans** - Use for parallel session instead of same-session execution

**Parallel mode integration:**
- Creates batch worktrees for parallel tasks (max 5)
- Uses rebase + merge for each completed task
- Main agent handles rebase conflicts
