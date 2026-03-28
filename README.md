# nbl.superpowers - Claude Code 扩展技能集

基于 Anthropic 官方 [superpowers](https://github.com/anthropics/claude-code/tree/main/plugins/superpowers) 技能体系的扩展。

## 项目核心

本项目在官方 superpowers 基础上，重点扩展了 **多 sub agent 并行执行任务** 的能力：

| 特性 | 说明 |
|------|------|
| **nbl.parallel-subagent-driven-development** | 支持多个独立任务同时分派给多个子代理并行执行，充分利用 Claude Code 的多代理能力，大幅提升复杂任务完成效率 |
| **nbl.subagent-driven-development** | 子代理串行执行，适用于任务有依赖关系的场景 |
| 完整工作流 | 保留从需求澄清 → 规划 → 执行 → 代码审查 → 收尾的完整流程 |

所有其他 `nbl.*` skill 都是对官方 superpowers 对应 skill 的适配和增强，遵循官方 superpowers 的核心设计原则。

---

## 安装

在 Claude Code 中执行以下命令安装此插件：

```bash
# 添加插件市场
/plugin marketplace add https://github.com/icefrag/nbl-superpowers

# 安装插件
/plugin install nbl@nbl-dev
```

---

## Skills

### 开发工作流

| Skill | 描述 | 阶段 |
|-------|------|------|
| **nbl.brainstorming** | 需求澄清和规格文档 | 需求 |
| **nbl.writing-plans** | 详细计划 | 规划 |
| **nbl.using-git-worktrees** | 隔离工作区 | 准备 |
| **nbl.executing-plans** | 主 agent 直接执行 | 执行 |
| **nbl.subagent-driven-development** | 子代理串行执行任务 | 执行 |
| **nbl.parallel-subagent-driven-development** | 子代理并行执行任务 | 执行 |
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
| **nbl.test-driven-development** | 测试驱动开发 | 新功能、bugfix |

## Agents

| Agent | 描述 | 调用方式 |
|-------|------|---------|
| **nbl:code-reviewer** | 代码审查，检查实现是否符合计划和规范 | Agent tool |

## 工作流

直接使用所需 skill：

```
brainstorming → design.md
    ↓
writing-plans → plan.md
    ↓
[执行模式选择]
    ├── parallel-subagent-driven-development (多任务并行)
    ├── subagent-driven-development (任务串行)
    └── executing-plans (简单任务/无子代理支持)
    ↓
code-review → finish
```

## 目录结构

```
agents/
└── code-reviewer.md          # 代码审查 agent

skills/
├── nbl.brainstorming/               # 需求澄清
├── nbl.writing-plans/               # 详细计划
├── nbl.using-git-worktrees/         # 隔离工作区
├── nbl.executing-plans/             # 主 agent 执行
├── nbl.subagent-driven-development/ # 子代理串行执行
├── nbl.parallel-subagent-driven-development/ # 子代理并行执行
├── nbl.requesting-code-review/      # 请求CR
├── nbl.receiving-code-review/       # 处理CR
├── nbl.finishing-a-development-branch/ # 完成分支
├── nbl.refactor-clean/              # 死代码清理
├── nbl.test-coverage/               # 测试覆盖率
├── nbl.tech-design/                 # 技术设计
├── nbl.deep-research/               # 深度研究
├── nbl.update-codemaps/             # 更新代码地图
├── nbl.update-rules/                # 规则更新
└── nbl.writing-skills/              # 编写skill
```
