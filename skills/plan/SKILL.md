---
name: plan
description: >
  重述需求、评估风险并创建分步实现计划。在修改任何代码之前等待用户确认。
  触发条件：用户请求规划、需要设计方案、开始新功能开发。
rules:
  - rules/common/architecture.md
  - rules/common/naming.md
---

# Plan Skill

此 skill 调用 **planner** 代理，在编写任何代码之前创建全面的实现计划。

## 激活时机

- 开始新功能开发
- 进行重大架构变更
- 进行复杂重构
- 将影响多个文件/组件
- 需求不清晰或有歧义

## 工作原理

planner 代理将：

1. **分析请求** 并用清晰的语言重述需求
2. **分解为阶段** 包含具体、可执行的步骤
3. **识别依赖** 组件之间的关系
4. **评估风险** 和潜在阻塞点
5. **估算复杂度**（高/中/低）
6. **展示计划** 并等待您的明确确认

## 使用示例

```
User: /plan 我需要添加市场结算时的实时通知功能

Agent (planner):
# 实现计划：实时市场结算通知

## 需求重述
- 当用户关注的市场结算时发送通知
- 支持多种通知渠道（应用内、邮件、webhook）
- 确保通知可靠送达
- 包含市场结果和用户的仓位结果

## 实现阶段

### 阶段1：数据库Schema
- 添加notifications表，列：id, user_id, market_id, type, status, created_at
- 添加user_notification_preferences表用于渠道偏好设置
- 在user_id和market_id上创建索引以优化性能

### 阶段2：通知服务
- 在lib/notifications.ts中创建通知服务
- 使用BullMQ/Redis实现通知队列
- 添加失败投递的重试逻辑
- 创建通知模板

### 阶段3：集成点
- 接入市场结算逻辑（当状态变为"resolved"时）
- 查询所有在市场中有仓位的用户
- 为每个用户入队通知

### 阶段4：前端组件
- 在头部创建NotificationBell组件
- 添加NotificationList弹窗
- 通过Supabase subscriptions实现实时更新
- 添加通知偏好设置页面

## 依赖
- Redis（用于队列）
- 邮件服务（SendGrid/Resend）
- Supabase实时订阅

## 风险
- 高：邮件送达率（需要SPF/DKIM）
- 中：单个市场1000+用户时的性能
- 中：市场频繁结算时的通知轰炸
- 低：实时订阅开销

## 估算复杂度：中等
- 后端：4-6小时
- 前端：3-4小时
- 测试：2-3小时
- 总计：9-13小时

**等待确认**：是否按此计划执行？（yes/no/modify）
```

## 重要说明

**关键**：planner agent在您明确确认计划之前**不会**编写任何代码。确认方式为"yes"或"proceed"等肯定回复。

如果您想要修改，请回复：
- "modify: [您的修改建议]"
- "different approach: [替代方案]"
- "跳过阶段2，先做阶段3"

## 与其他 skill 的集成

规划完成后：
- 使用 `springboot-tdd` skill 通过测试驱动开发实现
- 使用 `build-fix` skill 修复构建错误
- 使用 `code-review` skill 进行审查

## 相关代理

此 skill 调用 `planner` 代理（`agents/planner.md`）。
