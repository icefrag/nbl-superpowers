---
description: 强制执行测试驱动开发工作流。搭建接口，首先生成测试，然后实现最小程序使测试通过。确保80%以上覆盖率。
---

# TDD命令

此命令调用 **tdd-guide agent** 强制执行测试驱动开发。

## 触发方式

```
/tdd 我需要一个计算订单折扣的方法
/tdd 修复用户登录失败的bug
```

## TDD循环

```
RED → GREEN → REFACTOR → REPEAT

RED:      编写失败的测试
GREEN:    编写最小代码使其通过
REFACTOR: 改进代码，保持测试通过
REPEAT:   下一个功能/场景
```

## 何时使用

- 实现新功能
- 修复Bug（先编写重现Bug的测试）
- 重构现有代码
- 构建核心业务逻辑

## 与其他命令的集成

```
/plan → /tdd → /build-fix → /code-review → /test-coverage
```

## 相关文件

- Agent: `agents/tdd-guide.md`
