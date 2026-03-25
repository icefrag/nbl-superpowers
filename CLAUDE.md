# 项目配置

此文件定义项目的开发规范和依赖关系。

## Skills

### 开发工作流

| Skill | 描述 | 依赖Agent | 依赖Rule |
|-------|------|----------|---------|
| **plan** | 需求规划和实现计划 | planner | architecture, naming |
| **springboot-tdd** | 测试驱动开发 | tdd-guide | architecture, naming, coding-conventions |
| **code-review** | 代码审查 | code-reviewer | architecture, naming, coding-conventions |
| **build-fix** | 构建错误修复 | build-error-resolver | architecture, naming, coding-conventions |
| **verify** | 综合验证系统 | - | all rules |
| **refactor-clean** | 死代码清理 | refactor-cleaner | - |
| **test-coverage** | 测试覆盖率分析 | - | architecture, naming, coding-conventions |

### 会话管理

| Skill | 描述 |
|-------|------|
| **save-session** | 保存会话状态以便恢复 |
| **resume-session** | 从保存的会话恢复工作 |

### 多代理编排

| Skill | 描述 | 依赖Agent |
|-------|------|----------|
| **orchestrate** | 多代理工作流编排 | planner, tdd-guide, code-reviewer, security-reviewer |
| **devfleet** | DevFleet 并行多代理系统 | - |

### 文档与规则

| Skill | 描述 | 依赖Agent |
|-------|------|----------|
| **update-codemaps** | 更新代码地图 | doc-updater |
| **update-docs** | 更新文档 | doc-updater |
| **update-rules** | 规则文件更新 | code-reviewer |

### Java/Spring Boot

| Skill | 描述 |
|-------|------|
| **springboot-patterns** | Spring Boot架构模式、REST API设计 |
| **springboot-security** | Spring Security最佳实践 |
| **springboot-verification** | Spring Boot验证模式 |
| **java-coding-standards** | Java编码标准 |
| **jpa-patterns** | JPA持久化模式 |

### 通用/语言无关

| Skill | 描述 |
|-------|------|
| **blueprint** | 多会话工程项目规划 |
| **prompt-optimizer** | Prompt优化分析 |
| **tech-design** | 技术设计文档生成 |
| **coding-standards** | 通用编码标准 |

### AI/代理相关

| Skill | 描述 |
|-------|------|
| **continuous-learning** | 持续学习机制 |
| **continuous-agent-loop** | 持续代理循环 |
| **autonomous-loops** | 自主循环模式 |
| **eval-harness** | 评估框架 |

### 工具/实用程序

| Skill | 描述 |
|-------|------|
| **deep-research** | 深度研究 |
| **search-first** | 搜索优先模式 |
| **verification-loop** | 验证循环 |
| **strategic-compact** | 战略精简 |
| **plankton-code-quality** | 代码质量检查 |
| **iterative-retrieval** | 迭代检索 |

## Agents

| Agent | 描述 | 依赖Skill | 依赖Rule |
|-------|------|----------|---------|
| **planner** | 复杂功能和重构规划 | plan | architecture, naming |
| **architect** | 系统设计和架构决策 | - | architecture, naming |
| **tdd-guide** | 测试驱动开发 | springboot-tdd | architecture, naming, coding-conventions |
| **code-reviewer** | Java/Spring Boot代码审查 | springboot-patterns | architecture, naming, coding-conventions |
| **security-reviewer** | 安全漏洞检测与修复 | springboot-security | coding-conventions |
| **build-error-resolver** | 构建错误修复 | springboot-patterns | architecture, naming, coding-conventions |
| **refactor-cleaner** | 死代码清理 | - | - |
| **doc-updater** | 文档和代码地图更新 | - | - |

## Rules

| Rule文件 | 描述 | 被谁使用 |
|---------|------|---------|
| **architecture.md** | 分层架构、模块化设计、包结构、URI规范 | planner, architect, tdd-guide, code-reviewer, build-error-resolver, tech-design |
| **naming.md** | Entity/Service/枚举/参数命名规范 | planner, architect, tdd-guide, code-reviewer, build-error-resolver, tech-design |
| **coding-conventions.md** | Spring注入、数据持久化、工具类使用等开发规范 | tdd-guide, code-reviewer, security-reviewer, build-error-resolver, tech-design |

## 工作流依赖图

```
设计阶段:
  /tech-design ───> tech-design skill ──────> architecture.md + naming.md + coding-conventions.md
       │
       ▼
  /plan ──────────> planner ────────────────> architecture.md + naming.md
       │                   │
       │                   ▼
开发阶段:                   │
  /tdd ───────────> tdd-guide ──────────────> springboot-tdd ──> all rules
       │                   │
       │                   ▼
  /build-fix ─────> build-error-resolver ───> springboot-patterns ──> all rules
       │                   │
       │                   ▼
审查阶段:                   │
  /code-review ───> code-reviewer ──────────> springboot-patterns ──> all rules
       │                   │
       │                   ▼
  /orchestrate ───> security-reviewer ──────> springboot-security ──> coding-conventions.md
```

## 规则使用场景

| 场景 | 推荐Skill | 推荐Agent | 推荐Rule | 说明 |
|------|---------|----------|---------|------|
| 技术设计文档 | tech-design | - | architecture + naming + coding-conventions | 架构图、API设计、数据库模型设计 |
| 新功能设计 | plan | planner | architecture + naming | 确定包结构、类命名、接口设计 |
| 编码实现 | springboot-tdd | tdd-guide | all rules | 完整的开发规范 |
| 代码审查 | code-review | code-reviewer | all rules | 检查是否符合规范 |
| Bug修复 | build-fix | build-error-resolver | coding-conventions | 主要关注数据持久化和异常处理规范 |
| 安全审计 | springboot-security | security-reviewer | coding-conventions | 主要关注异常处理、JSON操作等规范 |

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

## Skills 目录

项目所有 skill 位于 `skills/` 目录，每个 skill 是一个独立文件夹，包含 `SKILL.md` 定义文件。

### Skill 目录结构

```
skills/
├── plan/                    # 需求规划和实现计划
├── code-review/             # Java/Spring Boot 代码审查
├── build-fix/               # 构建错误修复
├── verify/                  # 综合验证系统
├── orchestrate/              # 多代理工作流编排
├── refactor-clean/          # 死代码清理
├── test-coverage/           # 测试覆盖率分析
├── save-session/            # 保存会话状态
├── resume-session/          # 恢复会话
├── update-codemaps/         # 更新代码地图
├── update-docs/             # 更新文档
├── update-rules/            # 规则文件更新
├── tech-design/             # 技术设计文档生成
├── prompt-optimizer/        # Prompt 优化分析
├── springboot-tdd/          # 测试驱动开发
├── springboot-patterns/     # Spring Boot 架构模式
├── springboot-security/     # Spring Security 最佳实践
├── springboot-verification/  # Spring Boot 验证模式
├── java-coding-standards/   # Java 编码标准
├── jpa-patterns/            # JPA 持久化模式
├── coding-standards/        # 通用编码标准
├── blueprint/               # 多会话工程项目规划
├── verification-loop/       # 验证循环
├── search-first/            # 搜索优先模式
├── deep-research/           # 深度研究
├── continuous-learning/     # 持续学习机制
├── continuous-agent-loop/   # 持续代理循环
├── autonomous-loops/        # 自主循环模式
├── eval-harness/           # 评估框架
├── strategic-compact/       # 战略精简
├── plankton-code-quality/   # 代码质量检查
└── iterative-retrieval/    # 迭代检索
```

### 调用方式

所有 skills 都可以通过 `/skill-name` 方式调用，例如：
- `/plan` - 需求规划
- `/code-review` - 代码审查
- `/verify` - 综合验证
