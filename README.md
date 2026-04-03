# nbl.superpowers - Claude Code 扩展技能集

基于官方 [superpowers](https://github.com/obra/superpowers) 技能体系的扩展，重点增强了**多代理并行开发**和**隔离工作区**能力。
同时整合了 [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 项目中精选的实用技能，如 `/refactor-clean` 死代码清理、`/test-coverage` 测试覆盖率分析

---

### 完整开发生命周期

```
需求澄清(nbl.brainstorming)
  → 输出设计文档
  → 详细计划(nbl.writing-plans)
  → 创建隔离工作区(nbl.using-git-worktrees)

if 任务存在依赖关系:
  → subAgent 顺序执行(nbl.subagent-driven-development)
else:
  → 多 subAgent 并行执行(nbl.parallel-subagent-driven-development)

  → 代码审查(nbl.requesting-code-review)
  → 处理反馈(nbl.receiving-code-review)
  → 人工审核确认
  → 合并到主分支
  → 清理 worktree(nbl.finishing-a-development-branch)
```

---

## 📥 安装

在 Claude Code 中执行以下命令安装此插件：

```bash
# 添加插件市场
/plugin marketplace add https://github.com/icefrag/nbl-superpowers

# 安装插件
/plugin install nbl.superpowers@nbl.superpowers
```

---

## 🔄 更新方式

<img width="300" height="150" alt="image" src="https://github.com/user-attachments/assets/8ae38a00-d2de-4d16-a9ef-ca16cadf5548" />
<img width="300" height="150" alt="image" src="https://github.com/user-attachments/assets/23c7597b-fd15-4ff6-b729-ea4a0354c328" />
<img width="300" height="150" alt="image" src="https://github.com/user-attachments/assets/bc13ca8f-8c07-4c78-8415-ef539d14f6f7" />
<img width="300" height="150" alt="image" src="https://github.com/user-attachments/assets/98ed4f12-6f67-4364-afae-fe028cf06ff3" />
<img width="300" height="150" alt="image" src="https://github.com/user-attachments/assets/a66194de-570e-415d-9cd0-6d1060db49f7" />

---

## 🧩 Skills

### 开发工作流

按开发阶段排列：

| Skill | 描述 | 阶段 |
|-------|------|------|
| **nbl.brainstorming** | 需求澄清和设计文档生成 | 📝 需求 |
| **nbl.writing-plans** | 分解任务生成详细执行计划 | 📋 规划 |
| **nbl.using-git-worktrees** | 创建 Git worktree 隔离工作区 | ⚙️ 准备 |
| **nbl.executing-plans** | 主 Agent 直接执行简单任务 | ▶️ 执行 |
| **nbl.subagent-driven-development** | SubAgent 串行执行任务 | ▶️ 执行 |
| **nbl.parallel-subagent-driven-development** | SubAgent 并行执行多个任务 | ▶️ 执行 |
| **nbl.requesting-code-review** | 请求代码审查 | 🔍 审查 |
| **nbl.receiving-code-review** | 处理代码审查反馈 | 🔍 审查 |
| **nbl.finishing-a-development-branch** | 合并清理，完成开发分支 | 🎬 收尾 |

### 独立工具 Skills

这些是可独立使用的工具技能：

| Skill | 描述 | 触发场景 |
|-------|------|---------|
| **nbl.refactor-clean** | Java Web 死代码清理和重构专家 | 清理未使用代码、重构优化 |
| **nbl.test-coverage** | 测试覆盖率分析，生成缺失测试 | 提升测试覆盖率 |
| **nbl.tech-design** | 根据需求生成技术设计文档 | 技术方案、API 设计、数据库设计 |
| **nbl.deep-research** | 多源深度网络研究 | 需要调研收集信息 |
| **nbl.status-line** | 自定义 Claude Code 状态栏 | 安装显示模型 / Git / 上下文 / 成本 / worktree 信息 |
| **nbl.update-rules** | 管理更新 `rules/common/` 规则文件 | 修改编码规范 |
| **nbl.writing-skills** | 辅助创建和修改新技能 | 开发自定义 skill |
| **nbl.test-driven-development** | 测试驱动开发工作流 | 新功能开发、Bug 修复 |

---

## 📊 nbl.status-line 效果展示

**nbl.status-line** 是一个自定义状态栏脚本，安装后会在 Claude Code 每次响应前显示：

```
[Haiku 4.5] 📁 nbl.superpowers | 🌿 main clean
██░░░░░░░░ 15% | $0.12 | ⏱️ 0m 50s
 Worktrees:
   1. feature-auth → fix-login +2~1?3
   2. feature-api → main clean
```

显示内容：模型名称、项目名、Git 分支及状态（+staged ~modified ?untracked）、上下文使用率进度条、费用累计、会话耗时，以及所有 worktree 列表。

---

## 📁 目录结构

```
skills/
├── nbl.brainstorming/               # 需求澄清和设计
├── nbl.writing-plans/               # 详细执行计划
├── nbl.using-git-worktrees/         # Git worktree 隔离工作区
├── nbl.executing-plans/             # 主 Agent 直接执行
├── nbl.subagent-driven-development/ # SubAgent 串行执行
├── nbl.parallel-subagent-driven-development/ # SubAgent 并行执行
├── nbl.requesting-code-review/      # 请求代码审查
├── nbl.receiving-code-review/       # 处理代码审查反馈
├── nbl.finishing-a-development-branch/ # 完成开发分支
├── nbl.refactor-clean/              # Java Web 死代码清理
├── nbl.test-coverage/               # 测试覆盖率分析
├── nbl.tech-design/                 # 技术设计文档生成
├── nbl.deep-research/               # 多源深度研究
├── nbl.status-line/                 # 自定义状态栏
├── nbl.update-rules/                # 规则文件管理
├── nbl.writing-skills/              # 技能开发工具
└── nbl.test-driven-development/     # 测试驱动开发

rules/
└── common/                          # 开发规范规则集（示例管理，需手动拷贝到 ~/.claude/rules/ 生效）
```

---

## 💡 核心优势

| 特性 | 说明 |
|------|------|
| **物理隔离** | Git worktree 级别的隔离，多个任务完全不干扰 |
| **并行开发** | 多 subAgent 同时执行多个独立任务，充分利用 Claude Code 能力 |
| **安全审核** | 代码在 worktree 开发完成，人工审核后才合并到主分支 |
| **多会话支持** | 支持同时打开多个 Claude Code 会话并行处理多个需求 |
| **兼容官方** | 所有技能遵循官方 superpowers 设计原则，学习成本低 |
| **生态整合** | 整合了 [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 项目中精选的实用技能，如 `nbl.refactor-clean` 死代码清理、`nbl.tech-design` 技术文档生成、`nbl.test-coverage` 测试覆盖率分析等 |

---

## 📄 许可证

遵循原项目许可证，扩展部分遵循相同协议。
