# Orchestrate Skill 重构设计方案

> **日期:** 2026-03-26
> **目标:** 重构 Claude Code 项目，实现 superpowers 风格的工作流编排

## 背景

当前项目存在以下问题：
- `orchestrate` skill 定义不清晰，与其他 skills 关系模糊
- agents 目录独立存在，增加了系统复杂度
- 缺少 superpowers 中经过验证的工作流模式
- 主窗口承担了过多实现工作，应该专注于编排

## 设计目标

1. **统一入口**: `orchestrate` 成为所有开发工作流的唯一入口
2. **子代理执行**: 所有实现工作通过子代理执行，主窗口仅做编排和用户交互
3. **skill 整合**: 吸收 superpowers 中的精华 skills
4. **文件输出**: 大需求输出设计文档和执行计划到 `docs/superpowers/`

## 工作流设计

### 完整 Feature 开发流程

```dot
digraph orchestrate_feature_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. 用户启动 /orchestrate feature\n[主窗口 - 编排]" [shape=doublecircle fillcolor=lightblue];

    "2. brainstorming skill\n[主窗口 - 需求澄清]" [fillcolor=lightgreen];
    "3. 输出: docs/superpowers/specs/\n<date>-<topic>-design.md" [shape=note fillcolor=lightgray];

    "4. 评估需求大小" [shape=diamond];
    "4a. 大需求\n(多子系统/复杂)" [fillcolor=lightyellow];
    "4b. 小需求\n(简单/快速)" [fillcolor=lightyellow];

    "5a. writing-plans skill\n[子代理 - 生成详细计划]" [fillcolor=lightpink];
    "5a. 输出: docs/superpowers/plans/\n<date>-<feature>.md" [shape=note fillcolor=lightgray];
    "5a. plan review 循环\n(plan-document-reviewer)" [fillcolor=lightpink];

    "5b. plan skill\n[当前项目 - 轻量计划]" [fillcolor=lightpink];

    "6. using-git-worktrees\n[子代理 - 创建隔离工作区]" [fillcolor=lightpink];

    "7. 任务执行模式" [shape=diamond];
    "7a. 可并行任务\n(dispatching-parallel-agents)" [fillcolor=lightpink];
    "7b. 顺序任务\n(顺序执行)" [fillcolor=lightpink];

    "7c. subagent-driven-development\n[子代理逐任务执行]" [fillcolor=lightpink];
    "7c. 每个任务:\n- TDD (RED-GREEN-REFACTOR)\n- spec review\n- code quality review" [fillcolor=lightpink];

    "8. requesting-code-review\n[子代理 - 代码审查]" [fillcolor=lightpink];
    "8b. receiving-code-review\n[处理 CR 反馈]" [fillcolor=lightpink];

    "9. finishing-a-development-branch\n[完成分支]" [fillcolor=lightpink];

    "10. 返回主窗口" [shape=doublecircle fillcolor=lightblue];

    "1. 用户启动 /orchestrate feature" -> "2. brainstorming skill";
    "2. brainstorming skill" -> "3. 输出: docs/superpowers/specs/<date>-<topic>-design.md";
    "3. 输出: docs/superpowers/specs/<date>-<topic>-design.md" -> "4. 评估需求大小";
    "4. 评估需求大小" -> "4a. 大需求" [label="大"];
    "4. 评估需求大小" -> "4b. 小需求" [label="小"];
    "4a. 大需求" -> "5a. writing-plans skill";
    "4b. 小需求" -> "5b. plan skill";
    "5a. writing-plans skill" -> "5a. 输出: docs/superpowers/plans/<date>-<feature>.md";
    "5a. 输出: docs/superpowers/plans/<date>-<feature>.md" -> "5a. plan review 循环";
    "5a. plan review 循环" -> "6. using-git-worktrees";
    "5b. plan skill" -> "6. using-git-worktrees";
    "6. using-git-worktrees" -> "7. 任务执行模式";
    "7. 任务执行模式" -> "7a. 可并行任务" [label="可并行"];
    "7. 任务执行模式" -> "7b. 顺序任务" [label="顺序"];
    "7. 任务执行模式" -> "7c. subagent-driven-development" [label="子代理驱动"];
    "7a. 可并行任务" -> "7c. subagent-driven-development";
    "7b. 顺序任务" -> "7c. subagent-driven-development";
    "7c. subagent-driven-development" -> "8. requesting-code-review";
    "8. requesting-code-review" -> "8b. receiving-code-review";
    "8b. receiving-code-review" -> "9. finishing-a-development-branch" [label="CR 通过"];
    "8b. receiving-code-review" -> "7c. subagent-driven-development" [label="CR 问题 → 修复"];
    "9. finishing-a-development-branch" -> "10. 返回主窗口";
}
```

### Bugfix 工作流

```dot
digraph orchestrate_bugfix_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. 用户启动 /orchestrate bugfix\n[主窗口 - 编排]" [shape=doublecircle fillcolor=lightblue];

    "2. 快速复现 bug\n[主窗口或子代理]" [fillcolor=lightgreen];

    "3. 使用 TDD 修复\n(test-driven-development)" [fillcolor=lightpink];
    "3. 每个修复:\n- 写失败测试\n- 验证 RED\n- 最小实现\n- 验证 GREEN\n- 重构" [fillcolor=lightpink];

    "4. requesting-code-review\n[子代理 - 代码审查]" [fillcolor=lightpink];
    "4b. receiving-code-review\n[处理 CR 反馈]" [fillcolor=lightpink];

    "5. 提交修复\n[主窗口]" [fillcolor=lightblue];

    "1. 用户启动 /orchestrate bugfix" -> "2. 快速复现 bug";
    "2. 快速复现 bug" -> "3. 使用 TDD 修复";
    "3. 使用 TDD 修复" -> "4. requesting-code-review";
    "4. requesting-code-review" -> "4b. receiving-code-review";
    "4b. receiving-code-review" -> "5. 提交修复" [label="CR 通过"];
    "4b. receiving-code-review" -> "3. 使用 TDD 修复" [label="CR 问题 → 修复"];
}
```

## Skills 目录结构

```
skills/
├── orchestrate/                    # ⭐ 统一工作流入口
│   ├── SKILL.md                   # 主编排文件 (重新设计)
│   ├── workflow-graphs.dot        # DOT 工作流图
│   └── subagent-templates.md      # 子代理模板
│
├── brainstorming/                 # ⭐ 从 superpowers 复制
│   ├── SKILL.md
│   └── visual-companion.md
│
├── writing-plans/                  # ⭐ 从 superpowers 复制
│   ├── SKILL.md
│   └── plan-document-reviewer-prompt.md
│
├── subagent-driven-development/    # ⭐ 从 superpowers 复制
│   ├── SKILL.md
│   ├── implementer-prompt.md
│   ├── spec-reviewer-prompt.md
│   └── code-quality-reviewer-prompt.md
│
├── test-driven-development/        # ⭐ 从 superpowers 复制
│   └── SKILL.md
│
├── using-git-worktrees/            # ⭐ 从 superpowers 复制
│   └── SKILL.md
│
├── requesting-code-review/          # ⭐ 从 superpowers 复制
│   ├── SKILL.md
│   └── code-reviewer.md
│
├── receiving-code-review/          # ⭐ 从 superpowers 复制
│   └── SKILL.md
│
├── dispatching-parallel-agents/    # ⭐ 从 superpowers 复制
│   └── SKILL.md
│
├── finishing-a-development-branch/ # ⭐ 从 superpowers 复制
│   └── SKILL.md
│
├── plan/                           # 保留 (小需求轻量计划)
│   └── SKILL.md
│
├── code-review/                    # 整合 (superpowers + 当前项目)
│   └── SKILL.md
│
├── update-codemaps/                # 保留
│   └── SKILL.md
│
└── [其他现有 skills]              # 保留
```

## 执行职责分配

| 执行位置 | Skills | 说明 |
|---------|--------|------|
| **主窗口** | orchestrate, brainstorming | 工作流编排、需求澄清 |
| **子代理** | writing-plans, plan, subagent-driven-development, test-driven-development, using-git-worktrees, requesting-code-review, receiving-code-review, dispatching-parallel-agents, finishing-a-development-branch | 所有实现工作 |

## 文件输出位置

| 文件类型 | 路径 |
|---------|------|
| **设计文档** (大需求) | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` |
| **执行计划** (大需求) | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` |
| **代码** | `skills/` 目录 |

## 待删除

- `agents/` 整个目录 (所有 agents 替换为子代理 skill 执行)

## 迁移策略

1. **逐个复制**: 从 superpowers 逐个复制 skills，保持英文原文
2. **路径调整**: 内部引用路径从 `superpowers:xxx` 调整为 `xxx`
3. **整合**: `code-review` skill 整合 superpowers + 当前项目
4. **重新设计**: `orchestrate` 重新设计为统一入口

## 注意事项

- 所有 skills 保持英文原文，确保功能准确性
- 路径引用使用相对路径
- DOT 图使用标准的 graphviz 语法
- 子代理模板使用 Markdown 格式
