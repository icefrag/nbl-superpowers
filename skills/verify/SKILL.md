---
name: verify
description: >
  综合验证系统，用于检查代码库的构建、类型、测试和安全性。
  触发条件：提交前验证、PR准备检查、用户请求验证。
---

# Verification Skill

对当前代码库状态运行综合验证。

## 激活时机

- 提交前验证
- PR 准备检查
- 用户请求验证

## 执行顺序

### 1. Build Check
- 运行项目的构建命令
- 如失败，报告错误并停止

### 2. Type Check
- 运行 TypeScript/类型检查器
- 报告所有错误（文件:行）

### 3. Lint Check
- 运行 linter
- 报告警告和错误

### 4. Test Suite
- 运行所有测试
- 报告通过/失败数量
- 报告覆盖率百分比

### 5. Console.log Audit
- 在源文件中搜索 console.log
- 报告位置

### 6. Git Status
- 显示未提交的更改
- 显示自上次提交以来修改的文件

## 输出格式

生成简洁的验证报告：

```
VERIFICATION: [PASS/FAIL]

Build:    [OK/FAIL]
Types:    [OK/X errors]
Lint:     [OK/X issues]
Tests:    [X/Y passed, Z% coverage]
Secrets:  [OK/X found]
Logs:     [OK/X console.logs]

Ready for PR: [YES/NO]
```

如有严重问题，列出问题及修复建议。

## 参数模式

$ARGUMENTS 可以是：
- `quick` - 仅构建 + 类型检查
- `full` - 所有检查（默认）
- `pre-commit` - 与提交相关的检查
- `pre-pr` - 完整检查加安全扫描

## Java/Spring Boot 验证

```bash
# 编译检查
mvn compile

# 测试检查
mvn test

# 覆盖率报告
mvn test jacoco:report

# 依赖检查
mvn dependency:analyze

# 安全扫描
mvn dependency-check:check
```

## 验证报告示例

```
════════════════════════════════════════════════
VERIFICATION: FAIL
════════════════════════════════════════════════

Build:    OK
Types:    OK
Lint:     3 issues
Tests:    45/47 passed, 82% coverage
Secrets:  OK
Logs:     2 console.logs

Issues:
────────────────────────────────────────────────
[HIGH] src/service/UserService.java:45
  Method exceeds 50 lines (72 lines)
  Fix: Extract helper methods for validation

[MEDIUM] src/controller/UserController.java:12
  console.log found
  Fix: Remove or replace with logger

[LOW] src/utils/DateUtils.java:8
  Missing JSDoc for public method
────────────────────────────────────────────────

Ready for PR: NO
Fix HIGH issues before committing.
```
