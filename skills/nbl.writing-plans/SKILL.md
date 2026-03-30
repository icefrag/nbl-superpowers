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

## Task Structure

````markdown
### Task N: [Component Name]

**状态**
- [ ] 任务完成

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

After writing and self-reviewing the plan, first assess task complexity to determine if inline mode is appropriate. If not, analyze task dependencies to determine the execution mode.

### Inline Mode Selection

**Use inline mode (main agent executes directly) ONLY when the task is unambiguously and definitely simple.** Subagents handle complex work that benefits from context isolation. When in doubt, prefer subagents.

**Inline 判定：ALL of the following must be true**

1. **Mechanical change only**: All changes are mechanical, no complex business logic understanding required
   - Fixing typos/spelling mistakes
   - Modifying configuration values (changing a number/string)
   - Adjusting UI text, colors, or CSS styles
   - Removing dead code, unused imports, or unused files
   - Single-point bug fix in one clearly-scoped function

2. **No exploration needed**: You already know exactly where and how to change when writing the plan, no need to read existing code to understand context

3. **Small scope**: Total change touches 1-2 files, <100 lines of code total

4. **Short chain**: If there are multiple tasks, the longest dependency chain has ≤3 tasks

**Guidelines:**
- Only use `inline` when **all four conditions above are true**
- If any condition isn't met → skip inline, go to serial/parallel
- When in doubt → don't use inline (err on the side of subagents)
- The LLM makes the final call — these are just clear signals for when inline is definitely safe

### Decision Logic

```python
# Pseudocode
def determine_execution_mode(plan):
    # Step 1: Only use inline if ALL conditions are met
    if (plan.is_mechanical_change
        and not plan.requires_code_exploration
        and plan.total_files_touched <= 2
        and plan.total_lines_changed < 100
        and max_dependency_chain_length(plan.tasks) <= 3):
        return "inline"  # Definitely simple, main agent handles directly

    # Step 2: All other cases → analyze dependencies for serial/parallel
    levels = analyze_dependency_levels(plan.tasks)
    if all(len(level) == 1 for level in levels):
        return "serial"  # Pure chain dependency, sequential subagent execution
    else:
        return "parallel"  # Has parallelizable tasks, parallel subagent execution
```

### Examples

**✅ Inline (all conditions met):**
```
Task 1: Fix typo in error message
→ All conditions satisfied → inline
```
```
Task 1: Remove unused import in UserController
Task 2: Delete unused UserService.getOldMethod()
→ All conditions satisfied → inline
```

**❌ Not inline (any condition fails):**
```
Task 1: Refactor authentication flow
→ Not mechanical change → skip inline
```
```
Task 1: Fix bug in caching logic
→ Requires exploration → skip inline
```
```
Task 1: Add config → Task 2: Update doc → Task 3: Add test → Task 4: Update integration
→ Chain length 4 (>3) → skip inline
```

**Serial (chain dependency, complex):**
```
Task 1: Define User entity model
Task 2: Create UserRepository with JPA queries
Task 3: Implement UserService with business logic
→ Not all inline conditions → serial
```

**Parallel (multiple independent tasks, complex):**
```
Task 1: Implement User authentication module
Task 2: Implement Order management module
Task 3: Implement Payment processing module
Task 4: Integration testing
→ Multiple independent complex tasks → parallel
```

### Output Format

Add to plan document footer:

```markdown
---
**Execution Mode:** inline | serial | parallel
```

## Execution Handoff

After saving and self-reviewing the plan, assess complexity then analyze task dependencies to determine execution mode and automatically invoke the corresponding skill.

### Mode Decision

| Mode | Condition | Skill |
|------|-----------|-------|
| `inline` | Low complexity (small change, clear scope, no exploration needed) | `nbl.executing-plans` |
| `serial` | Tasks form a chain (each depends on previous), complex work | `nbl.subagent-driven-development` |
| `parallel` | Multiple independent tasks exist, complex work | `nbl.parallel-subagent-driven-development` |

### Handoff Actions

**Inline mode:**
- Invoke `nbl.executing-plans` skill
- Execute tasks in current session (main agent handles directly)

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

Invoke the corresponding execution skill immediately.
