---
name: orchestrate
description: >
  多代理工作流的顺序和 tmux/worktree 编排指南。
  触发条件：复杂多步骤任务、需要多代理协作、用户请求编排。
---

# Orchestrate Skill

用于复杂任务的顺序 agent 工作流。

## 激活时机

- 复杂多步骤任务
- 需要多代理协作
- 用户请求编排

## 使用方法

`/orchestrate [工作流类型] [任务描述]`

## 工作流类型

### feature
完整功能实现工作流：
```
planner -> tdd-guide -> code-reviewer -> security-reviewer
```

### bugfix
Bug 调查和修复工作流：
```
planner -> tdd-guide -> code-reviewer
```

### refactor
安全重构工作流：
```
architect -> code-reviewer -> tdd-guide
```

### security
安全专注审查：
```
security-reviewer -> code-reviewer -> architect
```

## 执行模式

对于工作流中的每个代理：

1. **调用代理**，传入前一代理的上下文
2. **收集输出**为结构化交接文档
3. **传递给下一个代理**
4. **汇总结果**到最终报告

## 交接文档格式

代理之间创建交接文档：

```markdown
## HANDOFF: [前一代理] -> [下一代理]

### 上下文
[已完成工作的摘要]

### 发现
[关键发现或决策]

### 已修改文件
[涉及的文件列表]

### 待解决问题
[留给下一代理的未决项]

### 建议
[建议的后续步骤]
```

## 示例：功能工作流

```
/orchestrate feature "添加用户认证"
```

执行流程：

1. **Planner 代理**
   - 分析需求
   - 创建实现计划
   - 识别依赖
   - 输出：`HANDOFF: planner -> tdd-guide`

2. **TDD Guide 代理**
   - 读取 planner 交接文档
   - 先编写测试
   - 实现以通过测试
   - 输出：`HANDOFF: tdd-guide -> code-reviewer`

3. **Code Reviewer 代理**
   - 审查实现
   - 检查问题
   - 提出改进建议
   - 输出：`HANDOFF: code-reviewer -> security-reviewer`

4. **Security Reviewer 代理**
   - 安全审计
   - 漏洞检查
   - 最终审批
   - 输出：最终报告

## 最终报告格式

```
ORCHESTRATION REPORT
====================
Workflow: feature
Task: 添加用户认证
Agents: planner -> tdd-guide -> code-reviewer -> security-reviewer

SUMMARY
-------
[一段话摘要]

AGENT OUTPUTS
-------------
Planner: [摘要]
TDD Guide: [摘要]
Code Reviewer: [摘要]
Security Reviewer: [摘要]

FILES CHANGED
-------------
[所有已修改文件列表]

TEST RESULTS
------------
[测试通过/失败摘要]

SECURITY STATUS
---------------
[安全发现]

RECOMMENDATION
--------------
[可发布 / 需要修改 / 阻塞]
```

## 并行执行

对于独立检查，可并行运行代理：

```markdown
### 并行阶段
同时运行：
- code-reviewer（质量）
- security-reviewer（安全）
- architect（设计）

### 合并结果
将输出合并为单一报告
```

## 参数

$ARGUMENTS:
- `feature <描述>` - 完整功能工作流
- `bugfix <描述>` - Bug 修复工作流
- `refactor <描述>` - 重构工作流
- `security <描述>` - 安全审查工作流
- `custom <代理列表> <描述>` - 自定义代理序列

## 自定义工作流示例

```
/orchestrate custom "architect,tdd-guide,code-reviewer" "重新设计缓存层"
```

## 提示

1. **复杂功能从 planner 开始**
2. **合并前务必包含 code-reviewer**
3. **涉及认证/支付/PII 时使用 security-reviewer**
4. **保持交接文档简洁** - 聚焦下一代理所需内容
5. **如需要在代理间运行验证**
