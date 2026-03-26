---
name: orchestrate
description: >
  Unified workflow orchestration entry point for all development work (feature, bugfix, refactor).
  This is the ONLY entry point for development workflows. All implementation happens in subagents.
  Trigger: User starts any development work, complex tasks, multi-agent coordination.
---

# Orchestrate Skill

Unified workflow orchestration entry point. All implementation happens in subagents. Main window handles orchestration and user interaction only.

**Core principle:** One entry point, all execution in subagents.

## Entry Points

```
/orchestrate feature "<description>"  - Feature development workflow
/orchestrate bugfix "<description>"   - Bug fix workflow
/orchestrate refactor "<description>" - Refactoring workflow
```

## Complete Feature Workflow

```dot
digraph orchestrate_feature_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. User starts /orchestrate feature\n[Main Window - Orchestration]" [shape=doublecircle fillcolor=lightblue];

    "2. brainstorming skill\n[Main Window - Requirements Clarification]" [fillcolor=lightgreen];
    "3. Output: docs/superpowers/specs/\n<date>-<topic>-design.md" [shape=note fillcolor=lightgray];

    "4. Assess requirement size" [shape=diamond];
    "4a. Large requirement\n(multi-subsystem/complex)" [fillcolor=lightyellow];
    "4b. Small requirement\n(simple/quick)" [fillcolor=lightyellow];

    "5a. writing-plans skill\n[Subagent - Generate detailed plan]" [fillcolor=lightpink];
    "5a. Output: docs/superpowers/plans/\n<date>-<feature>.md" [shape=note fillcolor=lightgray];
    "5a. plan review loop\n(plan-document-reviewer)" [fillcolor=lightpink];

    "5b. plan skill\n[Current project - Lightweight plan]" [fillcolor=lightpink];

    "6. using-git-worktrees\n[Subagent - Create isolated workspace]" [fillcolor=lightpink];

    "7. Task execution mode" [shape=diamond];
    "7a. Parallel tasks\n(dispatching-parallel-agents)" [fillcolor=lightpink];
    "7b. Sequential tasks\n(Sequential execution)" [fillcolor=lightpink];

    "7c. subagent-driven-development\n[Subagent per task execution]" [fillcolor=lightpink];
    "7c. Each task:\n- TDD (RED-GREEN-REFACTOR)\n- spec review\n- code quality review" [fillcolor=lightpink];

    "8. requesting-code-review\n[Subagent - Code Review]" [fillcolor=lightpink];
    "8b. receiving-code-review\n[Handle CR feedback]" [fillcolor=lightpink];

    "9. finishing-a-development-branch\n[Complete branch]" [fillcolor=lightpink];

    "10. Return to main window" [shape=doublecircle fillcolor=lightblue];

    "1. User starts /orchestrate feature" -> "2. brainstorming skill";
    "2. brainstorming skill" -> "3. Output: docs/superpowers/specs/<date>-<topic>-design.md";
    "3. Output: docs/superpowers/specs/<date>-<topic>-design.md" -> "4. Assess requirement size";
    "4. Assess requirement size" -> "4a. Large requirement" [label="Large"];
    "4. Assess requirement size" -> "4b. Small requirement" [label="Small"];
    "4a. Large requirement" -> "5a. writing-plans skill";
    "4b. Small requirement" -> "5b. plan skill";
    "5a. writing-plans skill" -> "5a. Output: docs/superpowers/plans/<date>-<feature>.md";
    "5a. Output: docs/superpowers/plans/<date>-<feature>.md" -> "5a. plan review loop";
    "5a. plan review loop" -> "6. using-git-worktrees";
    "5b. plan skill" -> "6. using-git-worktrees";
    "6. using-git-worktrees" -> "7. Task execution mode";
    "7. Task execution mode" -> "7a. Parallel tasks" [label="Parallel"];
    "7. Task execution mode" -> "7b. Sequential tasks" [label="Sequential"];
    "7. Task execution mode" -> "7c. subagent-driven-development" [label="Subagent-driven"];
    "7a. Parallel tasks" -> "7c. subagent-driven-development";
    "7b. Sequential tasks" -> "7c. subagent-driven-development";
    "7c. subagent-driven-development" -> "8. requesting-code-review";
    "8. requesting-code-review" -> "8b. receiving-code-review";
    "8b. receiving-code-review" -> "9. finishing-a-development-branch" [label="CR Passed"];
    "8b. receiving-code-review" -> "7c. subagent-driven-development" [label="CR Issues → Fix"];
    "9. finishing-a-development-branch" -> "10. Return to main window";
}
```

## Bugfix Workflow

```dot
digraph orchestrate_bugfix_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. User starts /orchestrate bugfix\n[Main Window - Orchestration]" [shape=doublecircle fillcolor=lightblue];

    "2. Quick bug reproduction\n[Main window or subagent]" [fillcolor=lightgreen];

    "3. Fix using TDD\n(test-driven-development)" [fillcolor=lightpink];
    "3. Each fix:\n- Write failing test\n- Verify RED\n- Minimal implementation\n- Verify GREEN\n- Refactor" [fillcolor=lightpink];

    "4. requesting-code-review\n[Subagent - Code Review]" [fillcolor=lightpink];
    "4b. receiving-code-review\n[Handle CR feedback]" [fillcolor=lightpink];

    "5. Commit fix\n[Main Window]" [fillcolor=lightblue];

    "1. User starts /orchestrate bugfix" -> "2. Quick bug reproduction";
    "2. Quick bug reproduction" -> "3. Fix using TDD";
    "3. Fix using TDD" -> "4. requesting-code-review";
    "4. requesting-code-review" -> "4b. receiving-code-review";
    "4b. receiving-code-review" -> "5. Commit fix" [label="CR Passed"];
    "4b. receiving-code-review" -> "3. Fix using TDD" [label="CR Issues → Fix"];
}
```

## Refactor Workflow

```dot
digraph orchestrate_refactor_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. User starts /orchestrate refactor\n[Main Window - Orchestration]" [shape=doublecircle fillcolor=lightblue];

    "2. Define refactor scope\n[Main Window - Clarify with user]" [fillcolor=lightgreen];

    "3. using-git-worktrees\n[Subagent - Create isolated workspace]" [fillcolor=lightpink];

    "4. TDD baseline\n(test-driven-development)" [fillcolor=lightpink];
    "4. Ensure tests exist\nbefore refactoring" [fillcolor=lightpink];

    "5. Refactor\n[Subagent per area]" [fillcolor=lightpink];

    "6. requesting-code-review\n[Subagent - Code Review]" [fillcolor=lightpink];

    "7. finishing-a-development-branch\n[Complete branch]" [fillcolor=lightpink];

    "1. User starts /orchestrate refactor" -> "2. Define refactor scope";
    "2. Define refactor scope" -> "3. using-git-worktrees";
    "3. using-git-worktrees" -> "4. TDD baseline";
    "4. TDD baseline" -> "5. Refactor";
    "5. Refactor" -> "6. requesting-code-review";
    "6. requesting-code-review" -> "7. finishing-a-development-branch";
}
```

## Skill Dependencies

| Skill | Execution | Purpose |
|-------|-----------|---------|
| **orchestrate** | Main window | Unified entry point |
| **brainstorming** | Main window | Requirements clarification |
| **writing-plans** | Subagent | Detailed plan for large requirements |
| **plan** | Subagent | Lightweight plan for small requirements |
| **using-git-worktrees** | Subagent | Isolated workspace setup |
| **subagent-driven-development** | Subagent | Per-task execution |
| **test-driven-development** | Subagent | TDD cycle |
| **dispatching-parallel-agents** | Subagent | Parallel task execution |
| **requesting-code-review** | Subagent | Code review |
| **receiving-code-review** | Subagent | Handle CR feedback |
| **finishing-a-development-branch** | Subagent | Complete branch |

## When to Use

| Scenario | Workflow | Plan Type |
|----------|----------|-----------|
| New feature (complex) | feature | writing-plans → file output |
| New feature (simple) | feature | plan → in-memory |
| Bug fix | bugfix | TDD → subagent |
| Safe refactoring | refactor | TDD baseline → subagent |
| Multi-subsystem project | feature (decomposed) | Separate plan per subsystem |

## Decision Logic

```
Is this a creative/implementation task?
  └── YES → Use brainstorming first (main window)
       └── After brainstorming:
            ├── Large requirement? → writing-plans (subagent, file output)
            └── Small requirement? → plan (subagent, in-memory)
  └── NO (simple/known) → Skip brainstorming
       └── Direct to appropriate workflow
```

## Subagent Templates

See `subagent-templates.md` for subagent dispatch templates.

## Red Flags

**Never:**
- Implement in main window (all work in subagents)
- Skip brainstorming for creative tasks
- Skip TDD for bug fixes
- Skip code review
- Skip CR feedback handling

**Always:**
- Use orchestrate as single entry point
- Dispatch subagents for all implementation
- Handle CR feedback before proceeding
