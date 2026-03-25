---
name: resume-session
description: >
  Load the most recent session file from ~/.claude/sessions/
  and resume work with full context from where the last session ended.
---

# Resume Session Skill

加载上次保存的会话状态，在任何工作之前完全定位。

## 激活时机

- 开始新会话以继续前一天的工作
- 由于上下文限制而启动新会话后
- 当从其他来源传递会话文件时（只需提供文件路径）
- 任何有会话文件并希望 Claude 在继续之前完全吸收它的时候

## 使用方法

```
/resume-session                                                      # 加载 ~/.claude/sessions/ 中最近的文件
/resume-session 2024-01-15                                           # 加载该日期最近的会话
/resume-session ~/.claude/sessions/2024-01-15-session.tmp           # 加载特定的旧格式文件
/resume-session ~/.claude/sessions/2024-01-15-abc123de-session.tmp  # 加载当前的 short-id 格式文件
```

## 执行流程

### 步骤1：查找会话文件

如未提供参数：

1. 检查 `~/.claude/sessions/`
2. 选择最近修改的 `*-session.tmp` 文件
3. 如果文件夹不存在或没有匹配文件，告诉用户：
   ```
   No session files found in ~/.claude/sessions/
   Run /save-session at the end of a session to create one.
   ```
   然后停止。

如提供参数：

- 如果看起来像日期（`YYYY-MM-DD`），搜索 `~/.claude/sessions/` 中匹配
  `YYYY-MM-DD-session.tmp`（旧格式）或 `YYYY-MM-DD-<shortid>-session.tmp`（当前格式）的文件
  并加载该日期最近修改的变体
- 如果看起来像文件路径，直接读取该文件
- 如未找到，清晰报告并停止

### 步骤2：读取整个会话文件

读取完整文件。暂不总结。

### 步骤3：确认理解

以此确切格式响应：

```
SESSION LOADED: [文件的实际解析路径]
════════════════════════════════════════════════

PROJECT: [文件中的项目名称/主题]

WHAT WE'RE BUILDING:
[用2-3句话以自己的话总结]

CURRENT STATE:
✅ Working: [数量] 项已确认
🔄 In Progress: [列出进行中的文件]
🗒️ Not Started: [列出已计划但未触及的]

WHAT NOT TO RETRY:
[列出每个失败的方法及其原因——这很关键]

OPEN QUESTIONS / BLOCKERS:
[列出任何阻塞项或未回答的问题]

NEXT STEP:
[如文件中定义的确切下一步]
[如未定义："未定义下一步——建议在开始前一起查看'未尝试'部分"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### 步骤4：等待用户

**不要**自动开始工作。**不要**触碰任何文件。等待用户告诉下一步做什么。

如果会话文件中明确定义了下一步且用户说"continue"或"yes"或类似的——执行那个确切的下一步。

如果未定义下一步——询问用户从哪里开始，并可选地从"未尝试"部分建议一个方法。

---

## 边缘情况

**同一日期有多个会话**（`2024-01-15-session.tmp`、`2024-01-15-abc123de-session.tmp`）：
加载该日期最近修改的匹配文件，无论它使用旧的无 id 格式还是当前的 short-id 格式。

**会话文件引用不再存在的文件：**
在简报中注明——"⚠️ `path/to/file.ts` 在会话中引用但磁盘上未找到。"

**会话文件超过7天：**
注明间隔——"⚠️ 此会话来自 N 天前（阈值：7天）。情况可能已改变。"——然后正常继续。

**用户直接提供文件路径（例如，从队友转发）：**
读取它并遵循相同的简报流程——无论来源如何，格式都是相同的。

**会话文件为空或格式错误：**
报告："找到会话文件但似乎为空或不可读。可能需要使用 /save-session 创建新的。"

---

## 示例输出

```
SESSION LOADED: /Users/you/.claude/sessions/2024-01-15-abc123de-session.tmp
════════════════════════════════════════════════

PROJECT: my-app — JWT Authentication

WHAT WE'RE BUILDING:
User authentication with JWT tokens stored in httpOnly cookies.
Register and login endpoints are partially done. Route protection
via middleware hasn't been started yet.

CURRENT STATE:
✅ Working: 3 items (register endpoint, JWT generation, password hashing)
🔄 In Progress: app/api/auth/login/route.ts (token works, cookie not set yet)
🗒️ Not Started: middleware.ts, app/login/page.tsx

WHAT NOT TO RETRY:
❌ Next-Auth — conflicts with custom Prisma adapter, threw adapter error on every request
❌ localStorage for JWT — causes SSR hydration mismatch, incompatible with Next.js

OPEN QUESTIONS / BLOCKERS:
- Does cookies().set() work inside a Route Handler or only Server Actions?

NEXT STEP:
In app/api/auth/login/route.ts — set the JWT as an httpOnly cookie using
cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })
then test with Postman for a Set-Cookie header in the response.

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

---

## 注意事项

- 加载时从不修改会话文件——它是只读的历史记录
- 简报格式是固定的——即使为空也不要跳过部分
- "什么不要重试"必须始终显示，即使只说"无"——它太重要了不能错过
- 恢复后，用户可能希望在新会话结束时再次运行 `/save-session` 以创建新的日期文件
