# 项目配置

此文件定义项目的开发规范和依赖关系。

## Skills

### Orchestrate 工作流 (开发工作流入口)

| Skill | 描述 | 阶段 |
|-------|------|------|
| **orchestrate** | 统一工作流入口点 | 入口 |
| **brainstorming** | 需求澄清和规格文档 | 需求 |
| **writing-plans** | 大需求详细计划 | 规划 |
| **plan** | 小需求轻量计划 | 规划 |
| **using-git-worktrees** | 隔离工作区 | 准备 |
| **subagent-driven-development** | 子代理执行任务 | 执行 |
| **test-driven-development** | TDD开发 | 执行 |
| **dispatching-parallel-agents** | 并行任务调度 | 执行 |
| **requesting-code-review** | 请求代码审查 | 审查 |
| **receiving-code-review** | 处理CR反馈 | 审查 |
| **finishing-a-development-branch** | 完成开发分支 | 收尾 |

### 独立工具 Skills

| Skill | 描述 | 触发场景 |
|-------|------|---------|
| **refactor-clean** | 死代码清理 | 清理未使用代码 |
| **test-coverage** | 测试覆盖率分析 | 分析测试缺口 |
| **tech-design** | 技术设计文档 | 生成技术方案 |
| **deep-research** | 深度研究 | 网络调研 |
| **update-codemaps** | 更新CLAUDE.md | 项目结构变化 |
| **update-rules** | 规则文件更新 | 修改编码规范 |
| **writing-skills** | 编写新skill | 创建/修改skill |
| **prompt-optimizer** | Prompt优化 | 优化用户prompt |

## Rules

| Rule文件 | 描述 |
|---------|------|
| **architecture.md** | 分层架构、模块化设计、包结构、URI规范 |
| **naming.md** | Entity/Service/枚举/参数命名规范 |
| **coding-conventions.md** | Spring注入、数据持久化、工具类使用等开发规范 |

## 工作流

```
/orchestrate feature "描述"  →  brainstorming → writing-plans/plan →
                                   subagent-driven-development → code-review → finish

/orchestrate bugfix "描述"   →  TDD修复 → code-review → commit

/orchestrate refactor "描述" →  TDD基线 → refactor → code-review → finish
```

## Skills 目录结构

```
skills/
├── orchestrate/                 # 统一工作流入口
├── brainstorming/              # 需求澄清
├── writing-plans/              # 详细计划
├── plan/                       # 轻量计划
├── using-git-worktrees/        # 隔离工作区
├── subagent-driven-development/# 子代理执行
├── test-driven-development/    # TDD
├── dispatching-parallel-agents/# 并行调度
├── requesting-code-review/     # 请求CR
├── receiving-code-review/      # 处理CR
├── finishing-a-development-branch/ # 完成分支
├── refactor-clean/             # 死代码清理
├── test-coverage/              # 测试覆盖率
├── tech-design/                # 技术设计
├── deep-research/              # 深度研究
├── update-codemaps/            # 更新代码地图
├── update-rules/               # 规则更新
├── writing-skills/             # 编写skill
└── prompt-optimizer/           # Prompt优化
```

## 注意事项 (NON-NEGOTIABLE)

### 规则文件路径区分

修改 rules 目录下的文件时，**必须**使用项目相对路径，**禁止**使用全局路径：

| 路径类型 | 路径 | 用途 |
|---------|------|------|
| ✅ 项目规则 | `rules/common/xxx.md` | 本项目专用规则 |
| ❌ 全局规则 | `~/.claude/rules/common/xxx.md` | 所有项目共享规则 |
