# 开发工作流

> 本文件扩展了 [common/git-workflow.md](./git-workflow.md)，描述git操作之前的完整功能开发流程。

## 统一入口

所有开发工作通过 `/nbl.orchestrate` 入口：

```
/nbl.orchestrate feature "<描述>"   # 新功能开发
/nbl.orchestrate bugfix "<描述>"    # Bug修复
/nbl.orchestrate refactor "<描述>"  # 代码重构
```

## 功能实现工作流

1. **研究与复用** _(任何新实现前必须执行)_
   - 在编写任何新代码之前，搜索现有的实现、模板和模式
   - 优先采用或移植已验证的方法，而非编写全新代码

2. **需求澄清** (通过 `/nbl.orchestrate feature`)
   - 使用 **nbl.brainstorming** skill 澄清需求
   - 大需求输出设计文档到 `docs/superpowers/specs/`
   - 小需求跳过此步骤

3. **规划**
   - 大需求: 使用 **nbl.writing-plans** skill 生成详细计划
   - 小需求: 使用 **nbl.plan** skill 生成轻量计划

4. **TDD实现** (子代理执行)
   - 使用 **nbl.test-driven-development** skill
   - 先写测试（RED）
   - 实现以通过测试（GREEN）
   - 重构（IMPROVE）

5. **代码审查**
   - 使用 **nbl.requesting-code-review** skill
   - 使用 **nbl.receiving-code-review** skill 处理反馈

6. **提交与推送**
   - 使用 **nbl.finishing-a-development-branch** skill
   - 详细的提交消息，遵循约定式提交格式
