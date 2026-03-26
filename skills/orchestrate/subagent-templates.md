# Orchestrate Subagent Templates

## Implementer Subagent Template

See `../subagent-driven-development/implementer-prompt.md` for full template.

## Spec Reviewer Subagent Template

See `../subagent-driven-development/spec-reviewer-prompt.md` for full template.

## Code Quality Reviewer Subagent Template

See `../subagent-driven-development/code-quality-reviewer-prompt.md` for full template.

## Plan Document Reviewer Template

See `../writing-plans/plan-document-reviewer-prompt.md` for full template.

## Dispatch Pattern

```bash
# 1. Dispatch implementer subagent
Agent tool:
  description: "Implement Task N: <task name>"
  prompt: |
    # Copy full implementer prompt template here
    # Include full task text from plan
    # Include context and dependencies

# 2. After implementer completes, dispatch spec reviewer
Agent tool:
  description: "Review spec compliance for Task N"
  prompt: |
    # Copy spec reviewer template here
    # Include task requirements
    # Include implementer report

# 3. After spec passes, dispatch code quality reviewer
Agent tool:
  description: "Review code quality for Task N"
  prompt: |
    # Copy code quality reviewer template here
    # Include git SHAs for diff
```

## Status Handling

| Status | Action |
|--------|--------|
| DONE | Proceed to next review |
| DONE_WITH_CONCERNS | Read concerns, proceed or address |
| NEEDS_CONTEXT | Provide context, re-dispatch |
| BLOCKED | Assess blocker, fix and re-dispatch |

## Review Loop

```
Implementer → Spec Reviewer → (Issues?) → Fix → Re-review
                ↓ (Pass)
         Code Quality Reviewer → (Issues?) → Fix → Re-review
                ↓ (Pass)
           Mark task complete
```
