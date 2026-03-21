# Git工作流

## 提交消息格式
```
<type>: <description>

<optional body>
```

类型：feat, fix, refactor, docs, test, chore, perf, ci

注意：署名已通过 ~/.claude/settings.json 全局禁用。

## Pull Request工作流

创建PR时：
1. 分析完整的提交历史（不仅是最新提交）
2. 使用 `git diff [base-branch]...HEAD` 查看所有更改
3. 起草全面的PR摘要
4. 包含带TODO的测试计划
5. 如果是新分支，使用 `-u` 标志推送

> 完整的开发流程（规划、TDD、代码审查）在git操作之前，
> 见 [development-workflow.md](./development-workflow.md)。
