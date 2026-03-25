---
name: code-review
description: >
  Java和Spring Boot代码审查专家，精通分层架构、JPA模式、安全性和并发性。
  触发条件：编写代码后、提交PR前、用户请求代码审查。
rules:
  - rules/common/architecture.md
  - rules/common/naming.md
  - rules/common/coding-conventions.md
---

# Code Review Skill

代码安全与质量综合审查。

## 激活时机

- 编写代码后
- 提交 PR 前
- 用户请求代码审查

## 执行步骤

1. 获取变更文件: `git diff --name-only HEAD`

2. 对每个变更文件检查：

### 安全问题 (CRITICAL)
- 硬编码凭证、API密钥、令牌
- SQL注入漏洞
- XSS漏洞
- 缺少输入验证
- 不安全的依赖
- 路径遍历风险

### 代码质量 (HIGH)
- 函数超过50行
- 文件超过800行
- 嵌套深度超过4层
- 缺少错误处理
- console.log 语句
- TODO/FIXME 注释
- 公共 API 缺少 JSDoc

### 最佳实践 (MEDIUM)
- 可变模式（应使用不可变模式）
- 代码/注释中使用 Emoji
- 新代码缺少测试
- 无障碍访问问题 (a11y)

3. 生成报告包含：
   - 严重程度: CRITICAL, HIGH, MEDIUM, LOW
   - 文件位置和行号
   - 问题描述
   - 建议修复

4. 如发现 CRITICAL 或 HIGH 问题，阻止提交

## Java/Spring Boot 特定检查

### 分层架构验证

| 检查项 | 规则 |
|--------|------|
| Controller → Service | ✅ 允许 |
| Controller → Mapper | ❌ 禁止 |
| Service → Manager | ✅ 允许 |
| Service → Mapper | ✅ 允许 |

### 命名规范检查

| 类型 | 规则 |
|------|------|
| Entity | PascalCase，无后缀 |
| Service | XxxService |
| Controller | XxxController |
| DTO | XxxDTO |

### 数据持久化检查

- [ ] ID 使用 `IdWorker.getId()` 生成
- [ ] Entity 继承 `BaseEntity`
- [ ] 更新操作使用 `updateById()`
- [ ] 查询使用 Mapper 层封装方法

## 报告格式

```
代码审查报告
════════════════════════════════════════════════
严重程度: [PASS/FAIL]

安全 (CRITICAL):
  [OK/X 问题]

质量 (HIGH):
  [OK/X 问题]

最佳实践 (MEDIUM):
  [OK/X 建议]

详细问题:
────────────────────────────────────────────────
[文件:行号] [严重程度] 问题描述
  建议修复: [修复建议]
────────────────────────────────────────────────

是否可提交: [YES/NO]
```

## 核心规则

**永远不要批准有安全漏洞的代码！**
