# 项目配置

此文件定义项目的开发规范和依赖关系。

## Commands

| 命令 | 描述 | 依赖Agent | 依赖Skill | 依赖Rule |
|------|------|----------|----------|---------|
| `/plan` | 需求规划和实现计划 | planner | - | architecture, naming |
| `/tdd` | 测试驱动开发 | tdd-guide | springboot-tdd | architecture, naming, coding-conventions |
| `/code-review` | 代码审查 | code-reviewer | springboot-patterns | architecture, naming, coding-conventions |
| `/build-fix` | 构建错误修复 | build-error-resolver | springboot-patterns | architecture, naming, coding-conventions |
| `/refactor-clean` | 死代码清理 | refactor-cleaner | - | - |
| `/test-coverage` | 测试覆盖率分析 | - | springboot-tdd | architecture, naming, coding-conventions |
| `/orchestrate` | 多代理编排 | planner, tdd-guide, code-reviewer, security-reviewer | springboot-* | - |
| `/update-codemaps` | 更新代码地图 | - | - | - |
| `/prompt-optimize` | Prompt优化 | - | prompt-optimizer | - |
| `/update-rules` | 规则文件更新 | code-reviewer | - | - |
| `/tech-design` | 技术设计文档生成 | - | tech-design | architecture, naming, coding-conventions |

## Agents

| Agent | 描述 | 依赖Skill | 依赖Rule | 模型 |
|-------|------|----------|---------|------|
| **planner** | 复杂功能和重构规划 | - | architecture, naming | opus |
| **architect** | 系统设计和架构决策 | - | architecture, naming | opus |
| **tdd-guide** | 测试驱动开发 | springboot-tdd | architecture, naming, coding-conventions | sonnet |
| **code-reviewer** | Java/Spring Boot代码审查 | springboot-patterns | architecture, naming, coding-conventions | sonnet |
| **security-reviewer** | 安全漏洞检测与修复 | springboot-security | coding-conventions | sonnet |
| **build-error-resolver** | 构建错误修复 | springboot-patterns | architecture, naming, coding-conventions | sonnet |
| **refactor-cleaner** | 死代码清理 | - | - | sonnet |

## Skills

### Java/Spring Boot

| Skill | 描述 |
|-------|------|
| **springboot-patterns** | Spring Boot架构模式、REST API设计 |
| **springboot-security** | Spring Security最佳实践 |
| **springboot-tdd** | 测试驱动开发工作流 |
| **springboot-verification** | Spring Boot验证模式 |
| **java-coding-standards** | Java编码标准 |
| **jpa-patterns** | JPA持久化模式 |

### Python

| Skill | 描述 |
|-------|------|
| **python-patterns** | Python设计模式和最佳实践 |
| **python-testing** | Python测试工作流 |

### 通用/语言无关

| Skill | 描述 |
|-------|------|
| **api-design** | REST API设计规范 |
| **backend-patterns** | 后端架构模式 |
| **coding-standards** | 通用编码标准 |
| **tdd-workflow** | 测试驱动开发工作流 |
| **security-scan** | 安全扫描和检查 |
| **docker-patterns** | Docker容器化模式 |
| **deployment-patterns** | 部署模式和策略 |
| **database-migrations** | 数据库迁移模式 |
| **mcp-server-patterns** | MCP服务器模式 |
| **e2e-testing** | 端到端测试 |
| **blueprint** | 多会话工程项目规划 |
| **prompt-optimizer** | Prompt优化分析 |
| **tech-design** | 技术设计文档生成 |

### AI/代理相关

| Skill | 描述 |
|-------|------|
| **agentic-engineering** | 代理工程模式 |
| **agent-harness-construction** | 代理框架构建 |
| **continuous-learning** | 持续学习机制 |
| **continuous-learning-v2** | 持续学习v2 |
| **continuous-agent-loop** | 持续代理循环 |
| **autonomous-loops** | 自主循环模式 |
| **ai-first-engineering** | AI优先工程 |
| **ai-regression-testing** | AI回归测试 |
| **claude-api** | Claude API集成 |
| **claude-devfleet** | Claude代理舰队 |
| **enterprise-agent-ops** | 企业级代理运维 |
| **eval-harness** | 评估框架 |

### 工具/实用程序

| Skill | 描述 |
|-------|------|
| **documentation-lookup** | 文档查找 |
| **deep-research** | 深度研究 |
| **exa-search** | Exa搜索集成 |
| **search-first** | 搜索优先模式 |
| **data-scraper-agent** | 数据抓取代理 |
| **verification-loop** | 验证循环 |
| **strategic-compact** | 战略精简 |
| **dmux-workflows** | dmux工作流 |
| **plankton-code-quality** | 代码质量检查 |
| **configure-ecc** | ECC配置 |

## Rules

| Rule文件 | 描述 | 被谁使用 |
|---------|------|---------|
| **architecture.md** | 分层架构、模块化设计、包结构、URI规范 | planner, architect, tdd-guide, code-reviewer, build-error-resolver, tech-design |
| **naming.md** | Entity/Service/枚举/参数命名规范 | planner, architect, tdd-guide, code-reviewer, build-error-resolver, tech-design |
| **coding-conventions.md** | Spring注入、数据持久化、工具类使用等开发规范 | tdd-guide, code-reviewer, security-reviewer, build-error-resolver, tech-design |

## 工作流依赖图

```
设计阶段:
  /tech-design ───> tech-design ──────> architecture.md + naming.md + coding-conventions.md
       │
       ▼
  /plan ──────────> planner ──────────> architecture.md + naming.md
                                            │
                                            ▼
开发阶段:
  /tdd ───────────> tdd-guide ────────> springboot-tdd ──> all rules
                        │
                        ▼
  /build-fix ─────> build-error-resolver > springboot-patterns ──> all rules
                        │
                        ▼
审查阶段:
  /code-review ───> code-reviewer ─────> springboot-patterns ──> all rules
                        │
                        ▼
  /orchestrate ───> security-reviewer ─> springboot-security ──> coding-conventions.md
```

## 规则使用场景

| 场景 | 推荐Rule | 说明 |
|------|---------|------|
| 技术设计文档 | architecture + naming + coding-conventions | 架构图、API设计、数据库模型设计 |
| 新功能设计 | architecture + naming | 确定包结构、类命名、接口设计 |
| 编码实现 | all rules | 完整的开发规范 |
| 代码审查 | all rules | 检查是否符合规范 |
| Bug修复 | coding-conventions | 主要关注数据持久化和异常处理规范 |
| 安全审计 | coding-conventions | 主要关注异常处理、JSON操作等规范 |

## Rule文件内容概览

### rules/common/architecture.md
- 分层架构原则 (Controller/Service/Manager/Mapper)
- 模块化设计原则 (app/api/config/assembly)
- 层间调用规范
- URI命名规范
- 包结构规范

### rules/common/naming.md
- Entity命名规范
- Service接口命名规范
- 枚举类命名规范
- 操作人参数命名规范
- 事件对象命名规范
- 分页参数命名规范

### rules/common/coding-conventions.md
- Spring依赖注入规范
- Lombok @Builder使用规范
- 数据持久化规范 (ID生成/表设计/更新/查询)
- JSON操作规范 (JsonUtil)
- 枚举工具类规范 (EnumUtil)
- 异常处理规范
- Controller返回值规范
- FeignClient接口规范
- 日期时间格式规范
- Swagger注解规范

## 注意事项 (NON-NEGOTIABLE)

### 规则文件路径区分

修改 rules 目录下的文件时，**必须**使用项目相对路径，**禁止**使用全局路径：

| 路径类型 | 路径 | 用途 |
|---------|------|------|
| ✅ 项目规则 | `rules/common/xxx.md` | 本项目专用规则 |
| ❌ 全局规则 | `~/.claude/rules/common/xxx.md` | 所有项目共享规则 |

**项目规则目录完整路径**：`D:\workspace\guozhi-claude-code\rules\common\`
**全局规则目录完整路径**：`C:\Users\icefr\.claude\rules\common\`
