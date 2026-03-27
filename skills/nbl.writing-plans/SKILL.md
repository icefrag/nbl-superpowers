---
name: nbl.writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/nbl/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use nbl.subagent-driven-development (recommended) or nbl.executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Dependencies

Each task MUST include dependency information for parallel execution planning:

### Required Fields

**Dependencies:** `None` | `Task 1, Task 2, ...`
- List task numbers this task depends on
- Use `None` if task has no dependencies

**Parallelizable:** `Yes` | `No (reason)`
- `Yes` - Task can run in parallel with other independent tasks
- `No (reason)` - Task must wait for dependencies, explain why

### Task Granularity Rules (NON-NEGOTIABLE)

**Rule:** One task = one independently testable feature unit

| Type | Example | Allowed |
|------|---------|---------|
| ✅ Feature module | "User authentication module" | Yes |
| ✅ Independent subsystem | "Logging service" | Yes |
| ❌ By code layer | "Auth API" + "Auth Service" + "Auth Mapper" | No |
| ❌ Too granular | "Add field X" + "Add field Y" | No |

**Why:** Tasks split by code layer create artificial dependencies and merge conflicts. Split by feature boundaries instead.

## Task Structure

````markdown
### Task N: [Component Name]

**Dependencies:** None | Task 1, Task 2
**Parallelizable:** Yes | No (reason if No)

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Mode Analysis

After writing and self-reviewing the plan, analyze task dependencies to determine the execution mode.

### Analysis Rules

| Condition | Execution Mode |
|-----------|---------------|
| Single task with `Dependencies: None` | `inline` |
| All tasks form a chain (each depends on previous) | `serial` |
| Multiple tasks with `Dependencies: None`, or tasks at same level can run together | `parallel` |

### Decision Logic

```python
# Pseudocode
def determine_execution_mode(plan):
    if len(plan.tasks) == 1:
        return "inline"  # Single task, main agent can handle directly

    # Analyze dependency levels
    levels = analyze_dependency_levels(plan.tasks)

    if all(level has 1 task for level in levels):
        return "serial"  # Pure chain dependency
    else:
        return "parallel"  # Has parallelizable tasks
```

### Examples

**Inline (single task):**
```
Task 1: Add config field
  Dependencies: None
```

**Serial (chain):**
```
Task 1: Define entity
  Dependencies: None
Task 2: Create mapper
  Dependencies: Task 1
Task 3: Implement service
  Dependencies: Task 2
```

**Parallel (multiple independent):**
```
Task 1: User module
  Dependencies: None
Task 2: Order module
  Dependencies: None
Task 3: Payment module
  Dependencies: None
Task 4: Integration
  Dependencies: Task 1, Task 2, Task 3
```

### Output Format

Add to plan document footer:

```markdown
---
**Execution Mode:** inline | serial | parallel
```

## Execution Handoff

After saving and self-reviewing the plan, analyze task dependencies to determine execution mode and automatically invoke the corresponding skill.

### Mode Decision

| Mode | Condition | Skill |
|------|-----------|-------|
| `inline` | Single task | `nbl.executing-plans` |
| `serial` | Tasks form a chain (each depends on previous) | `nbl.subagent-driven-development` |
| `parallel` | Multiple independent tasks exist | `nbl.parallel-subagent-driven-development` |

### Handoff Actions

**Inline mode:**
- Invoke `nbl.executing-plans` skill
- Execute single task in current session

**Serial mode:**
- Invoke `nbl.subagent-driven-development` skill
- Fresh subagent per task with reviews between tasks

**Parallel mode:**
- Invoke `nbl.parallel-subagent-driven-development` skill
- Parallel task execution based on dependency levels

### Announcement Format

After determining the mode:

> "Plan complete and saved to `docs/nbl/plans/<filename>.md`.
>
> **Execution Mode:** inline | serial | parallel
>
> Invoking `<skill-name>` to execute the plan."
