---
name: nbl.orchestrate
description: >
  Unified workflow orchestration entry point for all development work (feature, bugfix).
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
```

## Complete Feature Workflow

```dot
digraph orchestrate_feature_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. User starts /orchestrate feature" [shape=doublecircle fillcolor=lightblue];

    "2. brainstorming skill\n[Main Window]" [fillcolor=lightgreen];
    "3. Output: docs/nbl/specs/\n<date>-<topic>-design.md" [shape=note fillcolor=lightgray];

    "4. writing-plans skill\n[Main Window]" [fillcolor=lightgreen];
    "5. Output: docs/nbl/plans/\n<date>-<feature>.md" [shape=note fillcolor=lightgray];

    "6. Choose execution mode" [shape=diamond fillcolor=lightyellow];

    "7a. subagent-driven-development\n(per-task: implementer → spec review → quality review)" [fillcolor=lightpink];
    "7b. parallel-subagent-driven-development\n(per-task: implementer → spec review → quality review → rebase → merge)" [fillcolor=lightpink];
    "7c. executing-plans\n(no built-in review)" [fillcolor=lightpink];

    "8. All tasks complete?" [shape=diamond fillcolor=lightyellow];
    "9. Final global code review\n(requesting-code-review)" [fillcolor=lightpink];
    "10. receiving-code-review" [shape=diamond fillcolor=lightyellow];
    "11. finishing-a-development-branch" [fillcolor=lightpink];
    "12. Return to main window" [shape=doublecircle fillcolor=lightblue];

    "1. User starts /orchestrate feature" -> "2. brainstorming skill\n[Main Window]";
    "2. brainstorming skill\n[Main Window]" -> "3. Output: docs/nbl/specs/\n<date>-<topic>-design.md";
    "3. Output: docs/nbl/specs/\n<date>-<topic>-design.md" -> "4. writing-plans skill\n[Main Window]";

    "4. writing-plans skill\n[Main Window]" -> "5. Output: docs/nbl/plans/\n<date>-<feature>.md";
    "5. Output: docs/nbl/plans/\n<date>-<feature>.md" -> "6. Choose execution mode";

    "6. Choose execution mode" -> "7a. subagent-driven-development\n(per-task: implementer → spec review → quality review)" [label="subagents + tightly coupled"];
    "6. Choose execution mode" -> "7b. parallel-subagent-driven-development\n(per-task: implementer → spec review → quality review → rebase → merge)" [label="subagents + independent tasks"];
    "6. Choose execution mode" -> "7c. executing-plans\n(no built-in review)" [label="no subagent support"];

    "7a. subagent-driven-development\n(per-task: implementer → spec review → quality review)" -> "8. All tasks complete?";
    "7b. parallel-subagent-driven-development\n(per-task: implementer → spec review → quality review → rebase → merge)" -> "8. All tasks complete?";
    "7c. executing-plans\n(no built-in review)" -> "8. All tasks complete?";

    "8. All tasks complete?" -> "6. Choose execution mode" [label="no - issues"];
    "8. All tasks complete?" -> "9. Final global code review\n(requesting-code-review)" [label="yes"];

    "9. Final global code review\n(requesting-code-review)" -> "10. receiving-code-review";
    "10. receiving-code-review" -> "7a. subagent-driven-development\n(per-task: implementer → spec review → quality review)" [label="issues → fix"];
    "10. receiving-code-review" -> "11. finishing-a-development-branch" [label="passed"];

    "11. finishing-a-development-branch" -> "12. Return to main window";
}
```

### Code Review 出现在两个层级

| 层级 | 时机 | 内容 | 处理方式 |
|------|------|------|---------|
| **任务级**（内置在 7a/7b 中） | 每个任务完成后 | Stage 1: Spec Review → Stage 2: Quality Review | 实现子代理修复 → 重新审查 → 循环直到通过 |
| **全局级**（步骤 9-10） | 所有任务完成后 | 整体代码审查 | receiving-code-review 处理反馈 → 有问题则返回修复 → 通过则继续 |

**注意：** executing-plans（7c）没有内置任务级审查，因此全局审查（步骤 9）是其唯一的代码质量保障。

## Bugfix Workflow

```dot
digraph orchestrate_bugfix_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. /orchestrate bugfix" [shape=doublecircle fillcolor=lightblue];

    "2. brainstorming skill\n[Main Window]" [fillcolor=lightgreen];
    "3. Output: docs/nbl/specs/\n<date>-bugfix-<topic>-design.md" [shape=note fillcolor=lightgray];

    "4. writing-plans skill\n[Main Window]" [fillcolor=lightgreen];
    "5. Output: docs/nbl/plans/\n<date>-bugfix-<topic>.md" [shape=note fillcolor=lightgray];

    "6. executing-plans\n[Subagent - Sequential execution]" [fillcolor=lightpink];

    "7. requesting-code-review\n[Subagent]" [fillcolor=lightpink];
    "8. receiving-code-review" [shape=diamond fillcolor=lightyellow];
    "9. finishing-a-development-branch" [fillcolor=lightpink];
    "10. Return to main window" [shape=doublecircle fillcolor=lightblue];

    "1. /orchestrate bugfix" -> "2. brainstorming skill\n[Main Window]";
    "2. brainstorming skill\n[Main Window]" -> "3. Output: docs/nbl/specs/\n<date>-bugfix-<topic>-design.md";
    "3. Output: docs/nbl/specs/\n<date>-bugfix-<topic>-design.md" -> "4. writing-plans skill\n[Main Window]";
    "4. writing-plans skill\n[Main Window]" -> "5. Output: docs/nbl/plans/\n<date>-bugfix-<topic>.md";
    "5. Output: docs/nbl/plans/\n<date>-bugfix-<topic>.md" -> "6. executing-plans\n[Subagent - Sequential execution]";
    "6. executing-plans\n[Subagent - Sequential execution]" -> "7. requesting-code-review\n[Subagent]";
    "7. requesting-code-review\n[Subagent]" -> "8. receiving-code-review";
    "8. receiving-code-review" -> "6. executing-plans\n[Subagent - Sequential execution]" [label="issues → fix"];
    "8. receiving-code-review" -> "9. finishing-a-development-branch" [label="passed"];
    "9. finishing-a-development-branch" -> "10. Return to main window";
}
```

## Skill Dependencies

| Skill | Execution | Purpose |
|-------|-----------|---------|
| **orchestrate** | Main window | Unified entry point |
| **brainstorming** | Main window | Requirements clarification |
| **writing-plans** | Main window | Detailed plan with task dependencies |
| **using-git-worktrees** | Subagent | Isolated workspace (single or batch mode) |
| **subagent-driven-development** | Subagent | Sequential task execution in same session |
| **parallel-subagent-driven-development** | Subagent | Parallel task execution (max 5) in same session |
| **executing-plans** | Parallel session | Sequential execution without subagent support |
| **test-driven-development** | Subagent | TDD cycle |
| **requesting-code-review** | Subagent | Code review |
| **receiving-code-review** | Subagent | Handle CR feedback |
| **finishing-a-development-branch** | Subagent | Complete branch |

## When to Use

| Scenario | Workflow | Execution Mode |
|----------|----------|----------------|
| New feature (complex) | feature | writing-plans → parallel-subagent-driven-development |
| New feature (simple) | feature | writing-plans → subagent-driven-development |
| Bug fix | bugfix | brainstorming → writing-plans → executing-plans |
| Multi-subsystem project | feature (decomposed) | Separate plan per subsystem |
| No subagent support | any | executing-plans |

## Decision Logic

```
All tasks follow the same flow:
  1. brainstorming (main window) → design.md
  2. writing-plans (main window) → plan.md
  3. Choose execution mode (see Complete Feature Workflow diagram)
```

## Red Flags

**Never:**
- Skip brainstorming
- Skip code review
- Skip CR feedback handling
- Start implementation on main/master branch without worktree isolation

**Always:**
- Use orchestrate as single entry point
- Dispatch subagents for all implementation
- Handle CR feedback before proceeding
- Use worktree isolation before implementation
