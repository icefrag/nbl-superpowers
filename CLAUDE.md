# Claude Code Skills 开发项目

## 项目概述

本项目是 Claude Code Skills 的设计与开发仓库，用于创建和维护服务于研发开发流程的 Claude Code Skills。

### 项目目标

- **标准化开发流程**：通过 Skills 定义规范的开发工作流，涵盖需求澄清、规划、开发、测试、代码审查等全流程
- **提升研发效率**：自动化重复性工作，减少人工决策成本
- **保证代码质量**：内置代码审查、测试驱动开发等质量保障机制

### 核心内容

| 类型 | 数量 | 说明 |
|------|------|------|
| Skills | 18+ | 覆盖完整开发生命周期的技能 |
| Rules | 12 | 编码规范、架构规范、命名规范等 |
| Agents | 1 | 代码审查代理 |

---

# 项目配置

此文件定义项目的开发规范和依赖关系。

## Skills

### Orchestrate 工作流 (开发工作流入口)

| Skill | 描述 | 阶段 |
|-------|------|------|
| **nbl.orchestrate** | 统一工作流入口点 | 入口 |
| **nbl.brainstorming** | 需求澄清和规格文档 | 需求 |
| **nbl.writing-plans** | 详细计划 | 规划 |
| **nbl.using-git-worktrees** | 隔离工作区 | 准备 |
| **nbl.subagent-driven-development** | 子代理执行任务 | 执行 |
| **nbl.test-driven-development** | TDD开发 | 执行 |
| **nbl.dispatching-parallel-agents** | 并行任务调度 | 执行 |
| **nbl.requesting-code-review** | 请求代码审查 | 审查 |
| **nbl.receiving-code-review** | 处理CR反馈 | 审查 |
| **nbl.finishing-a-development-branch** | 完成开发分支 | 收尾 |

### 独立工具 Skills

| Skill | 描述 | 触发场景 |
|-------|------|---------|
| **nbl.refactor-clean** | 死代码清理 | 清理未使用代码 |
| **nbl.test-coverage** | 测试覆盖率分析 | 分析测试缺口 |
| **nbl.tech-design** | 技术设计文档 | 生成技术方案 |
| **nbl.deep-research** | 深度研究 | 网络调研 |
| **nbl.update-codemaps** | 更新CLAUDE.md | 项目结构变化 |
| **nbl.update-rules** | 规则文件更新 | 修改编码规范 |
| **nbl.writing-skills** | 编写新skill | 创建/修改skill |

## Rules

| Rule文件 | 描述 |
|---------|------|
| **architecture.md** | 分层架构、模块化设计、包结构、URI规范 |
| **naming.md** | Entity/Service/枚举/参数命名规范 |
| **coding-conventions.md** | Spring注入、数据持久化、工具类使用等开发规范 |

## 工作流

```
/nbl.orchestrate feature "描述"  →  nbl.brainstorming → nbl.writing-plans →
                                          nbl.subagent-driven-development → code-review → finish

/nbl.orchestrate bugfix "描述"   →  TDD修复 → code-review → commit

/nbl.orchestrate refactor "描述" →  TDD基线 → refactor → code-review → finish
```

## Skills 目录结构

```
skills/
├── nbl.orchestrate/                 # 统一工作流入口
├── nbl.brainstorming/              # 需求澄清
├── nbl.writing-plans/              # 详细计划
├── nbl.using-git-worktrees/        # 隔离工作区
├── nbl.subagent-driven-development/# 子代理执行
├── nbl.test-driven-development/    # TDD
├── nbl.dispatching-parallel-agents/# 并行调度
├── nbl.requesting-code-review/     # 请求CR
├── nbl.receiving-code-review/      # 处理CR
├── nbl.finishing-a-development-branch/ # 完成分支
├── nbl.refactor-clean/             # 死代码清理
├── nbl.test-coverage/              # 测试覆盖率
├── nbl.tech-design/                # 技术设计
├── nbl.deep-research/              # 深度研究
├── nbl.update-codemaps/            # 更新代码地图
├── nbl.update-rules/               # 规则更新
└── nbl.writing-skills/             # 编写skill
```

## 注意事项 (NON-NEGOTIABLE)

### Skill 修改审批规则

修改 `skills/` 目录下的任何文件时，**必须**满足以下条件：

| 要求 | 说明 |
|------|------|
| **阐述修改优点** | 详细说明此次修改带来的具体价值，包括解决的问题、提升的效果、避免的风险 |
| **说明修改必要性** | 解释为什么现有实现无法满足需求，为什么必须通过修改 skill 来解决 |
| **评估影响范围** | 列出修改可能影响的其他 skills、agents 或工作流程 |
| **提供测试验证** | 如适用，说明如何验证修改后的 skill 仍然按预期工作 |

**禁止的修改理由：**

| ❌ 无效理由 | 原因 |
|------------|------|
| "这样看起来更简洁" | 简洁不等于更好，可能丢失关键信息 |
| "我觉得可以优化" | 优化需要具体目标和可衡量的改进 |
| "这是小改动" | skill 文档的小改动可能导致 agent 行为的重大变化 |
| "与其他地方保持一致" | 一致性本身不是目的，需要证明一致性带来的价值 |

**只有当修改能够带来明确、可阐述的优点时，才允许进行修改。** 没有足够优点的修改将被拒绝。

### 规则文件路径区分

修改 rules 目录下的文件时，**必须**使用项目相对路径，**禁止**使用全局路径：

| 路径类型 | 路径 | 用途 |
|---------|------|------|
| ✅ 项目规则 | `rules/common/xxx.md` | 本项目专用规则 |
| ❌ 全局规则 | `~/.claude/rules/common/xxx.md` | 所有项目共享规则 |

### Skill 命名规范

本项目所有 skill 都必须使用 **`nbl.` 前缀**，保持命名一致性：

| 命名方式 | 示例 | 是否允许 |
|---------|------|---------|
| ✅ 正确 | `nbl.executing-plans`, `nbl.brainstorming` | 允许 |
| ❌ 错误 | `executing-plans`, `superpowers:executing-plans` | 禁止 |

所有 skill 内部引用其他 skill 时，也必须使用 `nbl.xxx` 格式，不能使用 `superpowers:xxx` 格式。
