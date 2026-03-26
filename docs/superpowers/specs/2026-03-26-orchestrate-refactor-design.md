# Orchestrate Skill 重构设计方案

> **日期:** 2026-03-26
> **目标:** 重构 Claude Code 项目，实现 superpowers 风格的工作流编排
> **状态:** ✅ 已完成 (2026-03-26)

## 背景

当前项目存在以下问题：
- `nbl.orchestrate` skill 定义不清晰，与其他 skills 关系模糊
- agents 目录独立存在，增加了系统复杂度
- 缺少 superpowers 中经过验证的工作流模式
- 主窗口承担了过多实现工作，应该专注于编排

## 设计目标

1. **统一入口**: `nbl.orchestrate` 成为所有开发工作流的唯一入口
2. **子代理执行**: 所有实现工作通过子代理执行，主窗口仅做编排和用户交互
3. **skill 整合**: 吸收 superpowers 中的精华 skills
4. **文件输出**: 大需求输出设计文档和执行计划到 `docs/superpowers/`

## 工作流设计

### 完整 Feature 开发流程

```dot
digraph orchestrate_feature_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. 用户启动 /nbl.orchestrate feature\n[主窗口 - 编排]" [shape=doublecircle fillcolor=lightblue];

    "2. nbl.brainstorming skill\n[主窗口 - 需求澄清]" [fillcolor=lightgreen];
    "3. 输出: docs/superpowers/specs/\n<date>-<topic>-design.md" [shape=note fillcolor=lightgray];

    "4. 评估需求大小" [shape=diamond];
    "4a. 大需求\n(多子系统/复杂)" [fillcolor=lightyellow];
    "4b. 小需求\n(简单/快速)" [fillcolor=lightyellow];

    "5a. nbl.writing-plans skill\n[子代理 - 生成详细计划]" [fillcolor=lightpink];
    "5a. 输出: docs/superpowers/plans/\n<date>-<feature>.md" [shape=note fillcolor=lightgray];
    "5a. plan review 循环\n(plan-document-reviewer)" [fillcolor=lightpink];

    "5b. nbl.plan skill\n[当前项目 - 轻量计划]" [fillcolor=lightpink];

    "6. nbl.using-git-worktrees\n[子代理 - 创建隔离工作区]" [fillcolor=lightpink];

    "7. 任务执行模式" [shape=diamond];
    "7a. 可并行任务\n(nbl.dispatching-parallel-agents)" [fillcolor=lightpink];
    "7b. 顺序任务\n(顺序执行)" [fillcolor=lightpink];

    "7c. nbl.subagent-driven-development\n[子代理逐任务执行]" [fillcolor=lightpink];
    "7c. 每个任务:\n- TDD (RED-GREEN-REFACTOR)\n- spec review\n- code quality review" [fillcolor=lightpink];

    "8. nbl.requesting-code-review\n[子代理 - 代码审查]" [fillcolor=lightpink];
    "8b. nbl.receiving-code-review\n[处理 CR 反馈]" [fillcolor=lightpink];

    "9. nbl.finishing-a-development-branch\n[完成分支]" [fillcolor=lightpink];

    "10. 返回主窗口" [shape=doublecircle fillcolor=lightblue];

    "1. 用户启动 /nbl.orchestrate feature" -> "2. nbl.brainstorming skill";
    "2. nbl.brainstorming skill" -> "3. 输出: docs/superpowers/specs/<date>-<topic>-design.md";
    "3. 输出: docs/superpowers/specs/<date>-<topic>-design.md" -> "4. 评估需求大小";
    "4. 评估需求大小" -> "4a. 大需求" [label="大"];
    "4. 评估需求大小" -> "4b. 小需求" [label="小"];
    "4a. 大需求" -> "5a. nbl.writing-plans skill";
    "4b. 小需求" -> "5b. nbl.plan skill";
    "5a. nbl.writing-plans skill" -> "5a. 输出: docs/superpowers/plans/<date>-<feature>.md";
    "5a. 输出: docs/superpowers/plans/<date>-<feature>.md" -> "5a. plan review 循环";
    "5a. plan review 循环" -> "6. nbl.using-git-worktrees";
    "5b. nbl.plan skill" -> "6. nbl.using-git-worktrees";
    "6. nbl.using-git-worktrees" -> "7. 任务执行模式";
    "7. 任务执行模式" -> "7a. 可并行任务" [label="可并行"];
    "7. 任务执行模式" -> "7b. 顺序任务" [label="顺序"];
    "7. 任务执行模式" -> "7c. nbl.subagent-driven-development" [label="子代理驱动"];
    "7a. 可并行任务" -> "7c. nbl.subagent-driven-development";
    "7b. 顺序任务" -> "7c. nbl.subagent-driven-development";
    "7c. nbl.subagent-driven-development" -> "8. nbl.requesting-code-review";
    "8. nbl.requesting-code-review" -> "8b. nbl.receiving-code-review";
    "8b. nbl.receiving-code-review" -> "9. nbl.finishing-a-development-branch" [label="CR 通过"];
    "8b. nbl.receiving-code-review" -> "7c. nbl.subagent-driven-development" [label="CR 问题 → 修复"];
    "9. nbl.finishing-a-development-branch" -> "10. 返回主窗口";
}
```

### Bugfix 工作流

```dot
digraph orchestrate_bugfix_workflow {
    rankdir=TB;
    node [shape=box style=filled fillcolor=lightyellow];

    "1. 用户启动 /nbl.orchestrate bugfix\n[主窗口 - 编排]" [shape=doublecircle fillcolor=lightblue];

    "2. 快速复现 bug\n[主窗口或子代理]" [fillcolor=lightgreen];

    "3. 使用 TDD 修复\n(nbl.test-driven-development)" [fillcolor=lightpink];
    "3. 每个修复:\n- 写失败测试\n- 验证 RED\n- 最小实现\n- 验证 GREEN\n- 重构" [fillcolor=lightpink];

    "4. nbl.requesting-code-review\n[子代理 - 代码审查]" [fillcolor=lightpink];
    "4b. nbl.receiving-code-review\n[处理 CR 反馈]" [fillcolor=lightpink];

    "5. 提交修复\n[主窗口]" [fillcolor=lightblue];

    "1. 用户启动 /nbl.orchestrate bugfix" -> "2. 快速复现 bug";
    "2. 快速复现 bug" -> "3. 使用 TDD 修复";
    "3. 使用 TDD 修复" -> "4. nbl.requesting-code-review";
    "4. nbl.requesting-code-review" -> "4b. nbl.receiving-code-review";
    "4b. nbl.receiving-code-review" -> "5. 提交修复" [label="CR 通过"];
    "4b. nbl.receiving-code-review" -> "3. 使用 TDD 修复" [label="CR 问题 → 修复"];
}
```

## Skills 目录结构

```
skills/
├── nbl.orchestrate/                # ⭐ 统一工作流入口
│   ├── SKILL.md                    # 主编排文件
│   ├── workflow-graphs.dot         # DOT 工作流图
│   └── subagent-templates.md       # 子代理模板
│
├── nbl.brainstorming/              # ⭐ 需求澄清
│   ├── SKILL.md
│   └── visual-companion.md
│
├── nbl.writing-plans/              # ⭐ 详细计划
│   ├── SKILL.md
│   └── plan-document-reviewer-prompt.md
│
├── nbl.subagent-driven-development/# ⭐ 子代理执行
│   ├── SKILL.md
│   ├── implementer-prompt.md
│   ├── spec-reviewer-prompt.md
│   └── code-quality-reviewer-prompt.md
│
├── nbl.test-driven-development/    # ⭐ TDD
│   └── SKILL.md
│
├── nbl.using-git-worktrees/        # ⭐ 隔离工作区
│   └── SKILL.md
│
├── nbl.requesting-code-review/     # ⭐ 请求CR
│   ├── SKILL.md
│   └── code-reviewer.md
│
├── nbl.receiving-code-review/      # ⭐ 处理CR
│   └── SKILL.md
│
├── nbl.dispatching-parallel-agents/# ⭐ 并行调度
│   └── SKILL.md
│
├── nbl.finishing-a-development-branch/ # ⭐ 完成分支
│   └── SKILL.md
│
├── nbl.plan/                       # 轻量计划
│   └── SKILL.md
│
├── nbl.update-codemaps/            # 更新代码地图
│   └── SKILL.md
│
└── [其他 skills]
```

## 执行职责分配

| 执行位置 | Skills | 说明 |
|---------|--------|------|
| **主窗口** | nbl.orchestrate, nbl.brainstorming | 工作流编排、需求澄清 |
| **子代理** | nbl.writing-plans, nbl.plan, nbl.subagent-driven-development, nbl.test-driven-development, nbl.using-git-worktrees, nbl.requesting-code-review, nbl.receiving-code-review, nbl.dispatching-parallel-agents, nbl.finishing-a-development-branch | 所有实现工作 |

## 文件输出位置

| 文件类型 | 路径 |
|---------|------|
| **设计文档** (大需求) | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` |
| **执行计划** (大需求) | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` |
| **代码** | `skills/` 目录 |

## 已删除

- `agents/` 目录 (所有 agents 替换为子代理 skill 执行)

## 注意事项

- 所有 skills 使用 `nbl.xxx` 命名规范
- 路径引用使用相对路径
- DOT 图使用标准的 graphviz 语法
- 子代理模板使用 Markdown 格式

## 实施结果

### 已完成迁移的 Skills

| Skill | 描述 |
|-------|------|
| **nbl.brainstorming** | 需求澄清和规格文档生成 |
| **nbl.writing-plans** | 详细实现计划生成 |
| **nbl.subagent-driven-development** | 子代理驱动开发模式 |
| **nbl.dispatching-parallel-agents** | 并行代理调度 |
| **nbl.requesting-code-review** | 请求代码审查 |
| **nbl.receiving-code-review** | 处理代码审查反馈 |
| **nbl.finishing-a-development-branch** | 完成开发分支 |
| **nbl.orchestrate** | 统一工作流入口点 |

### 提交

- `e599d19` - refactor(skills): 统一命名规范为 nbl.xxx 格式
- `886f548` - feat(skills): 迁移 superpowers skills 到本地 skills 目录
